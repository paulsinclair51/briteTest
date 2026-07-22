#!/usr/bin/env bash

# test_mrgbranch.sh - smoke tests for scripts/bin/mrgbranch
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MRGBRANCH_SRC="$REPO_ROOT/scripts/bin/mrgbranch"
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
  # Usage: run_capture <outfile> <command...>
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
  local repo_root="$1"
  ls -1t "$repo_root"/reports/branch/mrgbranch-*.md 2>/dev/null | head -n1
}

for dep in bash git grep mktemp; do
  command -v "$dep" >/dev/null 2>&1 || fail "missing required command: $dep"
done

[[ -f "$MRGBRANCH_SRC" ]] || fail "missing script: $MRGBRANCH_SRC"
[[ -f "$COMMON_HELPER_SRC" ]] || fail "missing helper: $COMMON_HELPER_SRC"
[[ -f "$GIT_HELPER_SRC" ]] || fail "missing helper: $GIT_HELPER_SRC"
[[ -f "$HISTORY_HELPER_SRC" ]] || fail "missing helper: $HISTORY_HELPER_SRC"
[[ -f "$REPORT_HELPER_SRC" ]] || fail "missing helper: $REPORT_HELPER_SRC"
[[ -f "$REPORT_SYNC_HELPER_SRC" ]] || fail "missing helper: $REPORT_SYNC_HELPER_SRC"

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
cp "$MRGBRANCH_SRC" "$WORK/scripts/bin/mrgbranch"
cp "$COMMON_HELPER_SRC" "$WORK/scripts/helpers/common.sh"
cp "$GIT_HELPER_SRC" "$WORK/scripts/helpers/git_helpers.sh"
cp "$HISTORY_HELPER_SRC" "$WORK/scripts/helpers/history_log.sh"
cp "$REPORT_HELPER_SRC" "$WORK/scripts/helpers/report_helpers.sh"
cp "$REPORT_SYNC_HELPER_SRC" "$WORK/scripts/helpers/report_sync.sh"
chmod +x "$WORK/scripts/bin/mrgbranch"

(
  cd "$WORK"
  git config user.name "testuser"
  git config user.email "test@example.com"

  echo "seed" > README.md
  mkdir -p reports/branch
  cat > .gitignore <<'GITIGNORE'
reports/branch/branch-*.md
reports/branch/mrgbranch-*.md
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

# 1) Help output
rc=$(run_capture "$TMPDIR/help.out" bash "$WORK/scripts/bin/mrgbranch" -h)
[[ "$rc" -eq 0 ]] || fail "mrgbranch -h should exit 0"
assert_contains "Usage:" "$TMPDIR/help.out"
pass "help output"

# 2) Positional branch argument should be rejected
rc=$(run_capture "$TMPDIR/arg-reject.out" bash -lc "cd '$WORK' && bash ./scripts/bin/mrgbranch dev/current-v1.0.0")
[[ "$rc" -eq 1 ]] || fail "positional branch argument should exit 1 (got $rc)"
assert_contains "Unexpected argument: dev/current-v1.0.0" "$TMPDIR/arg-reject.out"
pass "positional argument rejected"

# 3) Divergence should auto-resolve safely when possible
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
rc=$(run_capture "$TMPDIR/diverge-safe.out" bash -lc "cd '$WORK' && bash ./scripts/bin/mrgbranch")
[[ "$rc" -eq 0 ]] || fail "safe divergence should auto-resolve (got $rc)"
assert_contains "auto-resolved divergence" "$TMPDIR/diverge-safe.out"
[[ -f "$WORK/local-current.txt" ]] || fail "expected local-current.txt after auto-resolution"
[[ -f "$WORK/peer-current.txt" ]] || fail "expected peer-current.txt after auto-resolution"
pass "safe divergence auto-resolution"

# 4) Divergence with conflicts should pause rebase and report guidance
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
rc=$(run_capture "$TMPDIR/diverge-conflict.out" bash -lc "cd '$WORK' && bash ./scripts/bin/mrgbranch")
[[ "$rc" -eq 4 ]] || fail "conflicting divergence should require manual resolution (got $rc)"
assert_contains "requires manual conflict resolution" "$TMPDIR/diverge-conflict.out"
[[ -d "$WORK/.git/rebase-merge" || -d "$WORK/.git/rebase-apply" ]] || fail "expected rebase to remain in progress"
pass "conflicting divergence pauses for manual resolution"

# 5) Manual conflict resolution followed by rerun should complete rebase
(
  cd "$WORK"
  printf 'peer\nlocal\n' > conflict.txt
  git add conflict.txt
)
rc=$(run_capture "$TMPDIR/rebase-rerun.out" bash -lc "cd '$WORK' && bash ./scripts/bin/mrgbranch")
[[ "$rc" -eq 0 ]] || fail "rerun after manual conflict resolution should complete sync (got $rc)"
assert_contains "Completed in-progress rebase" "$TMPDIR/rebase-rerun.out"
[[ ! -d "$WORK/.git/rebase-merge" && ! -d "$WORK/.git/rebase-apply" ]] || fail "expected rebase to be completed"
pass "rerun completes paused rebase"

# 6) Dirty current branch gates synchronization
(
  cd "$WORK"
  git reset --hard >/dev/null 2>&1
  git clean -fd >/dev/null 2>&1
  git checkout dev/current-v1.0.0 >/dev/null 2>&1
  echo "dirty" >> README.md
)
rc=$(run_capture "$TMPDIR/dirty-current.out" bash -lc "cd '$WORK' && bash ./scripts/bin/mrgbranch")
[[ "$rc" -eq 4 ]] || fail "dirty current branch should result in no-sync exit 4 (got $rc)"
assert_contains "current branch 'dev/current-v1.0.0' has uncommitted or untracked changes" "$TMPDIR/dirty-current.out"
pass "dirty current branch gate"

# 7) Current branch without corresponding remote gates synchronization
(
  cd "$WORK"
  git checkout dev/current-v1.0.0 >/dev/null 2>&1
  git reset --hard >/dev/null 2>&1
  git clean -fd >/dev/null 2>&1
  git checkout -b local-only-current >/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/no-remote-gate.out" bash -lc "cd '$WORK' && bash ./scripts/bin/mrgbranch")
[[ "$rc" -eq 4 ]] || fail "current branch without remote should result in no-sync exit 4 (got $rc)"
assert_contains "current branch 'local-only-current' has no corresponding remote branch" "$TMPDIR/no-remote-gate.out"
pass "current branch remote gate"

echo "All mrgbranch smoke tests passed."
