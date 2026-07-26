#!/usr/bin/env bash

# test_fixremote.sh - smoke tests for scripts/bin/fixremote
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXREMOTE_SRC="$REPO_ROOT/scripts/bin/fixremote"
COMMON_HELPER_SRC="$REPO_ROOT/scripts/helpers/common.sh"
GIT_HELPER_SRC="$REPO_ROOT/scripts/helpers/git_helpers.sh"
REPORT_HELPER_SRC="$REPO_ROOT/scripts/helpers/report_helpers.sh"
HEALTH_REPORT_HELPER_SRC="$REPO_ROOT/scripts/helpers/health_report.sh"
CKROLE_HELPER_SRC="$REPO_ROOT/scripts/helpers/ckrole.sh"
HEALTH_REPORT_HELPER_SRC="$REPO_ROOT/scripts/helpers/health_report.sh"

pass() {
  echo "PASS: $1"
}

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

run_capture() {
  local outfile="$1"
  shift
  set +e
  "$@" >"$outfile" 2>&1
  local rc=$?
  set -e
  echo "$rc"
}

assert_contains() {
  local text="$1"
  local file="$2"
  grep -Fq -- "$text" "$file" || fail "expected '$text' in $file"
}

make_runner_repo() {
  local root="$1"
  mkdir -p "$root/scripts/bin" "$root/scripts/helpers" "$root/config" "$root/reports/repository"

  cp "$FIXREMOTE_SRC" "$root/scripts/bin/fixremote"
  cp "$COMMON_HELPER_SRC" "$root/scripts/helpers/common.sh"
  cp "$GIT_HELPER_SRC" "$root/scripts/helpers/git_helpers.sh"
  cp "$REPORT_HELPER_SRC" "$root/scripts/helpers/report_helpers.sh"
  cp "$HEALTH_REPORT_HELPER_SRC" "$root/scripts/helpers/health_report.sh"
  cp "$CKROLE_HELPER_SRC" "$root/scripts/helpers/ckrole.sh"
  cp "$HEALTH_REPORT_HELPER_SRC" "$root/scripts/helpers/health_report.sh"
  chmod +x "$root/scripts/bin/fixremote"

  cat > "$root/config/contributors.md" <<'EOF'
# Contributors

- paulsinclair51, A
EOF

  cat > "$root/reports/repository/README.md" <<'EOF'
# Repository Reports
EOF
}

latest_recovery_report() {
  local repo="$1"
  find "$repo/reports/repository" -maxdepth 1 -type f -name 'recovery-*.md' | sort | tail -n 1
}

for dep in bash find git grep mktemp; do
  command -v "$dep" >/dev/null 2>&1 || fail "missing required command: $dep"
done

TMPDIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

ORIGIN="$TMPDIR/origin.git"
RUNNER="$TMPDIR/runner"
SOURCE_CLONE="$TMPDIR/source-clone"
OTHER_CLONE="$TMPDIR/other-clone"

# Prepare bare origin and seed commit.
git init --bare -q "$ORIGIN"
git clone -q "$ORIGIN" "$SOURCE_CLONE"
git -C "$SOURCE_CLONE" config user.name "paulsinclair51"
git -C "$SOURCE_CLONE" config user.email "test@example.com"
echo "seed" > "$SOURCE_CLONE/README.md"
git -C "$SOURCE_CLONE" add README.md
git -C "$SOURCE_CLONE" commit -q -m "seed"
git -C "$SOURCE_CLONE" push -q origin main

# A second clone to verify push synchronization later.
git clone -q "$ORIGIN" "$OTHER_CLONE"
git -C "$OTHER_CLONE" config user.name "paulsinclair51"
git -C "$OTHER_CLONE" config user.email "test@example.com"

# Prepare runner repo containing fixremote and helpers.
mkdir -p "$RUNNER"
make_runner_repo "$RUNNER"
git -C "$RUNNER" init -q
git -C "$RUNNER" config user.name "paulsinclair51"
git -C "$RUNNER" config user.email "test@example.com"
git -C "$RUNNER" remote add origin "$ORIGIN"
git -C "$RUNNER" fetch -q origin main

echo "runner" > "$RUNNER/README.md"
git -C "$RUNNER" add .
git -C "$RUNNER" commit -q -m "runner setup"

# 1) Help output
rc=$(run_capture "$TMPDIR/help.out" bash "$RUNNER/scripts/bin/fixremote" -h)
[[ "$rc" -eq 0 ]] || fail "fixremote -h should exit 0"
assert_contains "Usage:" "$TMPDIR/help.out"
assert_contains "fixremote -x /path/to/clean-clone" "$TMPDIR/help.out"
pass "help output"

# 2) Missing clone path should fail
rc=$(run_capture "$TMPDIR/missing.out" bash "$RUNNER/scripts/bin/fixremote")
[[ "$rc" -eq 1 ]] || fail "fixremote without clone-path should exit 1 (got $rc)"
assert_contains "Exactly one clone-path argument is required" "$TMPDIR/missing.out"
pass "missing clone-path handling"

# 3) Preflight mode should pass on healthy clone
rc=$(run_capture "$TMPDIR/preflight.out" env GITHUB_ACTOR="paulsinclair51" bash "$RUNNER/scripts/bin/fixremote" "$SOURCE_CLONE")
[[ "$rc" -eq 0 ]] || fail "fixremote preflight should exit 0 (got $rc)"
report="$(latest_recovery_report "$RUNNER")"
[[ -f "$report" ]] || fail "expected recovery report for preflight run"
assert_contains "Preflight-only mode" "$report"
pass "preflight mode"

# 4) Unauthorized user should be blocked
rc=$(run_capture "$TMPDIR/unauth.out" env GITHUB_ACTOR="randomuser" bash "$RUNNER/scripts/bin/fixremote" "$SOURCE_CLONE")
[[ "$rc" -eq 2 ]] || fail "fixremote unauthorized run should exit 2 (got $rc)"
assert_contains "not authorized to run fixremote" "$TMPDIR/unauth.out"
pass "authorization enforcement"

# 5) -x with -r 0 should block recovery and report issue
rc=$(run_capture "$TMPDIR/r0.out" env GITHUB_ACTOR="paulsinclair51" bash "$RUNNER/scripts/bin/fixremote" -x -r 0 "$SOURCE_CLONE")
[[ "$rc" -eq 3 ]] || fail "fixremote -x -r 0 should exit 3 (got $rc)"
report_r0="$(latest_recovery_report "$RUNNER")"
[[ -f "$report_r0" ]] || fail "expected recovery report for -x -r 0 run"
assert_contains "Cannot execute recovery with -r 0" "$report_r0"
pass "execution blocked with disabled reachability"

# 6) Execute recovery should push source clone refs to origin and verify parity

echo "new data" >> "$SOURCE_CLONE/README.md"
git -C "$SOURCE_CLONE" add README.md
git -C "$SOURCE_CLONE" commit -q -m "source update"

rc=$(run_capture "$TMPDIR/execute.out" env GITHUB_ACTOR="paulsinclair51" bash "$RUNNER/scripts/bin/fixremote" -x "$SOURCE_CLONE")
[[ "$rc" -eq 0 ]] || fail "fixremote -x should succeed on healthy setup (got $rc)"
execute_report="$(latest_recovery_report "$RUNNER")"
[[ -f "$execute_report" ]] || fail "expected recovery report for execute run"
assert_contains "Post-Recovery Main Branch Parity" "$execute_report"
assert_contains "[FIXED]" "$execute_report"

# Confirm origin received the new source commit.
git -C "$OTHER_CLONE" fetch -q origin main
source_main="$(git -C "$SOURCE_CLONE" rev-parse main)"
origin_main="$(git -C "$OTHER_CLONE" rev-parse origin/main)"
[[ "$source_main" == "$origin_main" ]] || fail "origin/main should match source clone main after recovery"
pass "execute recovery path"

echo "All fixremote smoke tests passed."
