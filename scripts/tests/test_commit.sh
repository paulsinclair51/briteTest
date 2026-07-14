#!/usr/bin/env bash

# test_commit.sh - smoke tests for scripts/bin/commit
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMMIT_SRC="$REPO_ROOT/scripts/bin/commit"
COMMON_HELPER_SRC="$REPO_ROOT/scripts/helpers/common.sh"
GIT_HELPER_SRC="$REPO_ROOT/scripts/helpers/git_helpers.sh"

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

latest_report() {
  local repo="$1"
  find "$repo/reports/branch" -maxdepth 1 -type f -name 'commit*.md' | sort | tail -n 1
}

for dep in bash find git grep mktemp; do
  command -v "$dep" >/dev/null 2>&1 || fail "missing required command: $dep"
done

[[ -f "$COMMIT_SRC" ]] || fail "missing script: $COMMIT_SRC"
[[ -f "$COMMON_HELPER_SRC" ]] || fail "missing helper: $COMMON_HELPER_SRC"
[[ -f "$GIT_HELPER_SRC" ]] || fail "missing helper: $GIT_HELPER_SRC"

TMPDIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

ORIGIN="$TMPDIR/origin.git"
WORK="$TMPDIR/work"

git init --bare "$ORIGIN" >/dev/null 2>&1
git clone "$ORIGIN" "$WORK" >/dev/null 2>&1

mkdir -p "$WORK/scripts/bin" "$WORK/scripts/helpers" "$WORK/config" "$WORK/reports/branch"
cp "$COMMIT_SRC" "$WORK/scripts/bin/commit"
cp "$COMMON_HELPER_SRC" "$WORK/scripts/helpers/common.sh"
cp "$GIT_HELPER_SRC" "$WORK/scripts/helpers/git_helpers.sh"
chmod +x "$WORK/scripts/bin/commit"

cat > "$WORK/config/contributors.md" <<'EOF'
testuser,C,test@example.com
EOF

(
  cd "$WORK"
  git config user.name "testuser"
  git config user.email "test@example.com"

  echo "seed" > README.md
  git add README.md scripts config reports
  git commit -m "seed repo" >/dev/null 2>&1
  git branch -M main
  git push -u origin main >/dev/null 2>&1

  git checkout -b dev/commit-tests-v1.0.0 >/dev/null 2>&1
  git push -u origin dev/commit-tests-v1.0.0 >/dev/null 2>&1
)

# 1) Help output
rc=$(run_capture "$TMPDIR/help.out" bash -lc "cd '$WORK' && bash ./scripts/bin/commit -h")
[[ "$rc" -eq 0 ]] || fail "commit -h should exit 0"
assert_contains "Usage:" "$TMPDIR/help.out"
pass "help output"

# 2) Unauthorized user should be blocked with exit 8
printf '\nunauthorized role test\n' >> "$WORK/README.md"
(
  cd "$WORK"
  git config user.email "outsider@example.com"
)
rc=$(run_capture "$TMPDIR/unauth.out" env GITHUB_ACTOR=outsider bash -lc "cd '$WORK' && bash ./scripts/bin/commit -d -m 'test unauthorized'")
[[ "$rc" -eq 8 ]] || fail "unauthorized user should exit 8 (got $rc)"
assert_contains "is not authorized to run commit" "$TMPDIR/unauth.out"
(
  cd "$WORK"
  git config user.email "test@example.com"
)
pass "role validation"

# 3) Dry-run commit should succeed for contributor and generate report
rc=$(run_capture "$TMPDIR/dry.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/commit -d -m 'dry run commit'")
[[ "$rc" -eq 0 ]] || fail "dry-run commit should exit 0 (got $rc)"
dry_report="$(latest_report "$WORK")"
[[ -f "$dry_report" ]] || fail "expected dry-run commit report"
assert_contains "Report generated:" "$TMPDIR/dry.out"
pass "dry-run commit"

# 4) Missing message when changes exist should fail with exit 4
printf '\nmessage required test\n' >> "$WORK/README.md"
rc=$(run_capture "$TMPDIR/missing-message.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/commit")
[[ "$rc" -eq 4 ]] || fail "missing message should exit 4 (got $rc)"
assert_contains "Commit message is required" "$TMPDIR/missing-message.out"
pass "missing message handling"

# 5) Push requested with disconnected remote should exit 5 and report deferred push
(
  cd "$WORK"
  git remote remove origin
)
rc=$(run_capture "$TMPDIR/disconnected.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/commit -d -p -m 'defer push'")
[[ "$rc" -eq 5 ]] || fail "remote disconnected push should exit 5 (got $rc)"
assert_contains "Push deferred (remote disconnected)" "$TMPDIR/disconnected.out"
pass "remote disconnected push handling"

echo "All commit smoke tests passed."
