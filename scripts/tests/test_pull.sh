#!/usr/bin/env bash

# test_pull.sh - smoke tests for scripts/bin/pull
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PULL_SRC="$REPO_ROOT/scripts/bin/pull"
COMMON_HELPER_SRC="$REPO_ROOT/scripts/helpers/common.sh"
GIT_HELPER_SRC="$REPO_ROOT/scripts/helpers/git_helpers.sh"
HISTORY_HELPER_SRC="$REPO_ROOT/scripts/helpers/history_log.sh"
REPORT_HELPER_SRC="$REPO_ROOT/scripts/helpers/report_helpers.sh"
REPORT_SYNC_HELPER_SRC="$REPO_ROOT/scripts/helpers/report_sync.sh"

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

for dep in bash git grep mktemp; do
  command -v "$dep" >/dev/null 2>&1 || fail "missing required command: $dep"
done

[[ -f "$PULL_SRC" ]] || fail "missing script: $PULL_SRC"

TMPDIR="$(mktemp -d)"
cleanup() {
  chmod -R u+w "$TMPDIR" 2>/dev/null || true
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

ORIGIN="$TMPDIR/origin.git"
WORK="$TMPDIR/work"
PEER="$TMPDIR/peer"

git init --bare "$ORIGIN" >/dev/null 2>&1
git clone "$ORIGIN" "$WORK" >/dev/null 2>&1
git clone "$ORIGIN" "$PEER" >/dev/null 2>&1

mkdir -p "$WORK/scripts/bin" "$WORK/scripts/helpers" "$WORK/reports/branch"
cp "$PULL_SRC" "$WORK/scripts/bin/pull"
cp "$COMMON_HELPER_SRC" "$WORK/scripts/helpers/common.sh"
cp "$GIT_HELPER_SRC" "$WORK/scripts/helpers/git_helpers.sh"
cp "$HISTORY_HELPER_SRC" "$WORK/scripts/helpers/history_log.sh"
cp "$REPORT_HELPER_SRC" "$WORK/scripts/helpers/report_helpers.sh"
cp "$REPORT_SYNC_HELPER_SRC" "$WORK/scripts/helpers/report_sync.sh"
chmod +x "$WORK/scripts/bin/pull"

(
  cd "$WORK"
  git config user.name "testuser"
  git config user.email "test@example.com"
  echo "seed" > README.md
  mkdir -p reports/branch
  cat > .gitignore <<'GITIGNORE'
reports/branch/branch-*.md
reports/branch/pull-*.md
reports/branch/commit-*.md
GITIGNORE
  git add README.md scripts reports .gitignore
  git commit -m "seed repo" >/dev/null 2>&1
  git branch -M main
  git push -u origin main >/dev/null 2>&1
  git checkout -b dev/current-v1.0.0 >/dev/null 2>&1
  git commit --allow-empty -m "current branch" >/dev/null 2>&1
  git push -u origin dev/current-v1.0.0 >/dev/null 2>&1
)

(
  cd "$PEER"
  git config user.name "peeruser"
  git config user.email "peer@example.com"
  git fetch origin >/dev/null 2>&1
  git checkout -b dev/current-v1.0.0 origin/dev/current-v1.0.0 >/dev/null 2>&1
)

rc=$(run_capture "$TMPDIR/help.out" bash "$WORK/scripts/bin/pull" -h)
[[ "$rc" -eq 0 ]] || fail "pull -h should exit 0"
assert_contains "Usage:" "$TMPDIR/help.out"
pass "help output"

rc=$(run_capture "$TMPDIR/skip-e.out" bash -lc "cd '$WORK' && bash ./scripts/bin/pull -e")
[[ "$rc" -eq 6 ]] || fail "pull -e should exit 6 (got $rc)"
assert_contains "Error: Pull skipped due to -e option." "$TMPDIR/skip-e.out"
assert_contains "Guidance: Run without -e option." "$TMPDIR/skip-e.out"
assert_contains "See reports/branch/pull-e-" "$TMPDIR/skip-e.out"
skip_report="$(find "$WORK/reports/branch" -maxdepth 1 -type f -name 'pull-e-*.md' | sort | tail -n 1)"
[[ -f "$skip_report" ]] || fail "expected pull skip report"
assert_contains "**Error:** Pull skipped due to -e option." "$skip_report"
assert_contains "## Guidance" "$skip_report"
assert_contains "- Run without -e option." "$skip_report"
pass "skip mode"

rc=$(run_capture "$TMPDIR/arg-reject.out" bash -lc "cd '$WORK' && bash ./scripts/bin/pull dev/current-v1.0.0")
[[ "$rc" -eq 1 ]] || fail "positional branch argument should exit 1 (got $rc)"
assert_contains "Unexpected argument: dev/current-v1.0.0" "$TMPDIR/arg-reject.out"
pass "positional argument rejected"

cat > "$WORK/reports/branch/pull-d-20000101-000000.md" <<'EOF'
# Stale Pull Report

**Branch:** `dev/current-v1.0.0`
EOF
cat > "$WORK/reports/branch/pull-e-20000101-000001.md" <<'EOF'
# Stale Pull Error Report

**Branch:** `dev/current-v1.0.0`
EOF
chmod a-w "$WORK/reports/branch/pull-d-20000101-000000.md" \
  "$WORK/reports/branch/pull-e-20000101-000001.md"
rc=$(run_capture "$TMPDIR/noop.out" \
  bash -lc "cd '$WORK' && bash ./scripts/bin/pull")
[[ "$rc" -eq 0 ]] || fail "no-op pull should exit 0 (got $rc)"
assert_contains "no changes to pull" "$TMPDIR/noop.out"
[[ -z "$(find "$WORK/reports/branch" -maxdepth 1 -type f -name 'pull-*.md' -print -quit)" ]] || \
  fail "no-op pull should not create a report"
pass "no-op pull cleans transient reports and creates no report"

rc=$(run_capture "$TMPDIR/dryrun.out" bash -lc "cd '$WORK' && bash ./scripts/bin/pull -d")
[[ "$rc" -eq 0 ]] || fail "dry-run pull should exit 0 (got $rc)"
assert_contains "Dry-run: no fetch, pull, or branch updates will be performed." "$TMPDIR/dryrun.out"
pass "dry-run output uses Dry-run prefix"

(
  cd "$PEER"
  git checkout dev/current-v1.0.0 >/dev/null 2>&1
  git reset --hard origin/dev/current-v1.0.0 >/dev/null 2>&1
  echo "peer side change" > peer-current.txt
  git add peer-current.txt
  git commit -m "peer current update" >/dev/null 2>&1
  git push origin dev/current-v1.0.0 >/dev/null 2>&1
)
(
  cd "$WORK"
  git checkout dev/current-v1.0.0 >/dev/null 2>&1
  echo "local side change" > local-current.txt
  git add local-current.txt
  git commit -m "local current update" >/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/diverge-safe.out" bash -lc "cd '$WORK' && bash ./scripts/bin/pull")
[[ "$rc" -eq 0 ]] || fail "safe divergence should auto-resolve (got $rc)"
assert_contains "auto-resolved divergence" "$TMPDIR/diverge-safe.out"
assert_contains "See reports/branch/pull-" "$TMPDIR/diverge-safe.out"
[[ -f "$WORK/local-current.txt" ]] || fail "expected local-current.txt after auto-resolution"
[[ -f "$WORK/peer-current.txt" ]] || fail "expected peer-current.txt after auto-resolution"
pass "safe divergence auto-resolution"

(
  cd "$WORK"
  git reset --hard >/dev/null 2>&1
  git clean -fd >/dev/null 2>&1
  git checkout main >/dev/null 2>&1
  git checkout -b dev/conflict-v1.0.0 >/dev/null 2>&1
  printf 'base\n' > conflict.txt
  git add conflict.txt
  git commit -m "seed conflict branch" >/dev/null 2>&1
  git push -u origin dev/conflict-v1.0.0 >/dev/null 2>&1
)
(
  cd "$PEER"
  git fetch origin >/dev/null 2>&1
  git checkout -b dev/conflict-v1.0.0 origin/dev/conflict-v1.0.0 >/dev/null 2>&1
  printf 'peer\n' > conflict.txt
  git add conflict.txt
  git commit -m "peer conflict edit" >/dev/null 2>&1
  git push origin dev/conflict-v1.0.0 >/dev/null 2>&1
)
(
  cd "$WORK"
  git checkout dev/conflict-v1.0.0 >/dev/null 2>&1
  printf 'local\n' > conflict.txt
  git add conflict.txt
  git commit -m "local conflict edit" >/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/diverge-conflict.out" bash -lc "cd '$WORK' && bash ./scripts/bin/pull")
[[ "$rc" -eq 0 ]] || fail "conflicting divergence run should complete with a paused branch (got $rc)"
assert_contains "requires manual conflict resolution" "$TMPDIR/diverge-conflict.out"
[[ -d "$WORK/.git/rebase-merge" || -d "$WORK/.git/rebase-apply" ]] || fail "expected rebase to remain in progress"
pass "conflicting divergence pauses for manual resolution"

(
  cd "$WORK"
  printf 'peer\nlocal\n' > conflict.txt
  git add conflict.txt
)
rc=$(run_capture "$TMPDIR/rebase-rerun.out" bash -lc "cd '$WORK' && bash ./scripts/bin/pull")
[[ "$rc" -eq 0 ]] || fail "rerun after manual conflict resolution should complete sync (got $rc)"
assert_contains "Completed in-progress rebase" "$TMPDIR/rebase-rerun.out"
assert_contains "See reports/branch/pull-" "$TMPDIR/rebase-rerun.out"
[[ ! -d "$WORK/.git/rebase-merge" && ! -d "$WORK/.git/rebase-apply" ]] || fail "expected rebase to be completed"
pass "rerun completes paused rebase"

(
  cd "$WORK"
  git reset --hard >/dev/null 2>&1
  git clean -fd >/dev/null 2>&1
  git checkout dev/current-v1.0.0 >/dev/null 2>&1
  echo "dirty" >> README.md
)
rc=$(run_capture "$TMPDIR/dirty-current.out" bash -lc "cd '$WORK' && bash ./scripts/bin/pull")
[[ "$rc" -eq 0 ]] || fail "dirty current branch gate should complete with no changes (got $rc)"
assert_contains "Cannot proceed: current branch 'dev/current-v1.0.0' has uncommitted or untracked changes." "$TMPDIR/dirty-current.out"
assert_contains "Skipped 'dev/current-v1.0.0': current branch 'dev/current-v1.0.0' has uncommitted or untracked changes." "$TMPDIR/dirty-current.out"
pass "dirty current branch gate"

(
  cd "$WORK"
  git checkout dev/current-v1.0.0 >/dev/null 2>&1
  git reset --hard >/dev/null 2>&1
  git clean -fd >/dev/null 2>&1
  git checkout -b local-only-current >/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/no-remote-gate.out" bash -lc "cd '$WORK' && bash ./scripts/bin/pull")
[[ "$rc" -eq 0 ]] || fail "missing remote branch gate should complete with no changes (got $rc)"
assert_contains "current branch 'local-only-current' has no corresponding remote branch" "$TMPDIR/no-remote-gate.out"
pass "current branch remote gate"

echo "All pull smoke tests passed."