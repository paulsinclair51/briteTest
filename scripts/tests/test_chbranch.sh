#!/usr/bin/env bash

# test_chbranch.sh - smoke tests for scripts/bin/chbranch
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CHBRANCH_SRC="$REPO_ROOT/scripts/bin/chbranch"
COMMON_HELPER_SRC="$REPO_ROOT/scripts/helpers/common.sh"
GIT_HELPER_SRC="$REPO_ROOT/scripts/helpers/git_helpers.sh"
HISTORY_HELPER_SRC="$REPO_ROOT/scripts/helpers/history_log.sh"

pass() {
  echo "PASS: $1"
}

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

run_in_work_capture() {
  # Usage: run_in_work_capture <outfile> <args...>
  local outfile="$1"
  shift
  set +e
  (
    cd "$WORK"
    bash "$WORK/scripts/bin/chbranch" "$@"
  ) >"$outfile" 2>&1
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

[[ -f "$CHBRANCH_SRC" ]] || fail "missing script: $CHBRANCH_SRC"
[[ -f "$COMMON_HELPER_SRC" ]] || fail "missing helper: $COMMON_HELPER_SRC"
[[ -f "$GIT_HELPER_SRC" ]] || fail "missing helper: $GIT_HELPER_SRC"
[[ -f "$HISTORY_HELPER_SRC" ]] || fail "missing helper: $HISTORY_HELPER_SRC"

TMPDIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

ORIGIN="$TMPDIR/origin.git"
WORK="$TMPDIR/work"

git init --bare "$ORIGIN" >/dev/null 2>&1
git clone "$ORIGIN" "$WORK" >/dev/null 2>&1

mkdir -p "$WORK/scripts/bin" "$WORK/scripts/helpers"
cp "$CHBRANCH_SRC" "$WORK/scripts/bin/chbranch"
cp "$COMMON_HELPER_SRC" "$WORK/scripts/helpers/common.sh"
cp "$GIT_HELPER_SRC" "$WORK/scripts/helpers/git_helpers.sh"
cp "$HISTORY_HELPER_SRC" "$WORK/scripts/helpers/history_log.sh"
chmod +x "$WORK/scripts/bin/chbranch"

(
  cd "$WORK"
  git config user.name "testuser"
  git config user.email "test@example.com"

  echo "seed" > README.md
  git add README.md scripts
  git commit -m "seed repo" >/dev/null 2>&1
  git branch -M main
  git push -u origin main >/dev/null 2>&1

  git checkout -b dev/local-only main >/dev/null 2>&1
  git checkout main >/dev/null 2>&1

  git checkout -b dev/target main >/dev/null 2>&1
  git push -u origin dev/target >/dev/null 2>&1
  git checkout dev/local-only >/dev/null 2>&1
)

# 1) Help output
rc=$(run_in_work_capture "$TMPDIR/help.out" -h)
[[ "$rc" -eq 0 ]] || fail "chbranch -h should exit 0"
assert_contains "Usage:" "$TMPDIR/help.out"
pass "help output"

# 2) Unknown option -> exit 1
rc=$(run_in_work_capture "$TMPDIR/unknown.out" --badopt)
[[ "$rc" -eq 1 ]] || fail "unknown option should exit 1 (got $rc)"
assert_contains "Unknown option" "$TMPDIR/unknown.out"
pass "unknown option exit code"

# 3) Already current local branch -> exit 2
rc=$(run_in_work_capture "$TMPDIR/no-change.out" dev/local-only)
[[ "$rc" -eq 2 ]] || fail "no-change local should exit 2 (got $rc)"
assert_contains "no change needed" "$TMPDIR/no-change.out"
pass "no-change local exit code"

# 4) Missing local and remote branch -> exit 3
rc=$(run_in_work_capture "$TMPDIR/missing-both.out" zz-missing-branch)
[[ "$rc" -eq 3 ]] || fail "missing branch should exit 3 (got $rc)"
assert_contains "does not exist and was not found on origin" "$TMPDIR/missing-both.out"
pass "missing branch exit code"

# 5) -r with local-only branch -> exit 4
rc=$(run_in_work_capture "$TMPDIR/remote-missing.out" -r dev/local-only)
[[ "$rc" -eq 4 ]] || fail "remote missing with -r should exit 4 (got $rc)"
assert_contains "Remote branch 'origin/dev/local-only' does not exist" \
  "$TMPDIR/remote-missing.out"
pass "remote missing exit code"

# 6) Dirty worktree without -f -> exit 6
(
  cd "$WORK"
  echo "dirty" >> README.md
)
rc=$(run_in_work_capture "$TMPDIR/dirty.out" dev/target)
[[ "$rc" -eq 6 ]] || fail "dirty worktree should exit 6 (got $rc)"
assert_contains "has uncommitted changes" "$TMPDIR/dirty.out"
(
  cd "$WORK"
  git restore README.md
)
pass "dirty worktree exit code"

# 7) -f successful local change discards uncommitted changes and switches branch
(
  cd "$WORK"
  echo "dirty force" >> README.md
)
rc=$(run_in_work_capture "$TMPDIR/force-local-success.out" -f dev/target)
[[ "$rc" -eq 0 ]] || fail "-f local success should exit 0 (got $rc)"
(
  cd "$WORK"
  current_local="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
  [[ "$current_local" == "dev/target" ]] || \
    fail "expected current local branch dev/target, got '$current_local'"
  git status --porcelain > "$TMPDIR/status-after-force-local.txt"
)
[[ ! -s "$TMPDIR/status-after-force-local.txt" ]] || \
  fail "expected clean worktree after -f local change"
assert_contains "Current branch is now local 'dev/target'" \
  "$TMPDIR/force-local-success.out"
pass "-f local change discards and switches"

# 8) -r successful remote change switches to remote branch
rc=$(run_in_work_capture "$TMPDIR/remote-success.out" -r dev/target)
[[ "$rc" -eq 0 ]] || fail "-r remote success should exit 0 (got $rc)"
(
  cd "$WORK"
  current_local="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
  [[ -z "$current_local" ]] || \
    fail "expected remote mode (no local symbolic ref), got '$current_local'"
  head_sha="$(git rev-parse --verify HEAD 2>/dev/null || true)"
  remote_sha="$(git rev-parse --verify refs/remotes/origin/dev/target \
    2>/dev/null || true)"
  [[ -n "$head_sha" && "$head_sha" == "$remote_sha" ]] || \
    fail "expected HEAD to match refs/remotes/origin/dev/target"
)
assert_contains "Current branch is now remote 'origin/dev/target'" \
  "$TMPDIR/remote-success.out"
pass "-r remote change success"

# 9) -f with -r and missing remote preserves uncommitted changes (still exit 4)
(
  cd "$WORK"
  echo "dirty again" >> README.md
)
rc=$(run_in_work_capture "$TMPDIR/f-r-preserve.out" -f -r dev/local-only)
[[ "$rc" -eq 4 ]] || fail "-f -r remote missing should exit 4 (got $rc)"
(
  cd "$WORK"
  git status --porcelain > "$TMPDIR/status-after-fr.txt"
)
assert_contains "README.md" "$TMPDIR/status-after-fr.txt"
(
  cd "$WORK"
  git restore README.md
)
pass "-f -r preserves changes when remote missing"

# 10) Remote unreachable/not configured -> exit 7
(
  cd "$WORK"
  git remote remove origin
)
rc=$(run_in_work_capture "$TMPDIR/remote-unreachable.out" -r dev/target)
[[ "$rc" -eq 7 ]] || fail "remote unreachable should exit 7 (got $rc)"
assert_contains "Remote branch is not connected/reachable" \
  "$TMPDIR/remote-unreachable.out"
pass "remote unreachable exit code"

echo "All chbranch smoke tests passed."
