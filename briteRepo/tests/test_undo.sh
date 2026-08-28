#!/usr/bin/env bash

# test_undo.sh - smoke tests for briteRepo/bin/undo
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
UNDO_SRC="$REPO_ROOT/briteRepo/bin/undo"
COMMON_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/common.sh"
GIT_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/git_helpers.sh"
HISTORY_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/history_log.sh"
VALIDATION_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/validation_helpers.sh"
COMMON_UTILS_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/common_utils.sh"

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

[[ -f "$UNDO_SRC" ]] || fail "missing script: $UNDO_SRC"
[[ -f "$COMMON_HELPER_SRC" ]] || fail "missing helper: $COMMON_HELPER_SRC"
[[ -f "$GIT_HELPER_SRC" ]] || fail "missing helper: $GIT_HELPER_SRC"
[[ -f "$HISTORY_HELPER_SRC" ]] || fail "missing helper: $HISTORY_HELPER_SRC"
[[ -f "$VALIDATION_HELPER_SRC" ]] || fail "missing helper: $VALIDATION_HELPER_SRC"
[[ -f "$COMMON_UTILS_HELPER_SRC" ]] || fail "missing helper: $COMMON_UTILS_HELPER_SRC"

TMPDIR="$(mktemp -d)"
cleanup() {
  if [[ "${KEEP_TMPDIR:-0}" == "1" ]]; then
    echo "KEEP_TMPDIR=1 preserving test artifacts at: $TMPDIR" >&2
    return 0
  fi
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

ORIGIN="$TMPDIR/origin.git"
WORK="$TMPDIR/work"

git init --bare "$ORIGIN" >/dev/null 2>&1
git clone "$ORIGIN" "$WORK" >/dev/null 2>&1

mkdir -p "$WORK/briteRepo/bin" "$WORK/briteRepo/helpers" "$WORK/config" "$WORK/logs"
cp "$UNDO_SRC" "$WORK/briteRepo/bin/undo"
cp "$COMMON_HELPER_SRC" "$WORK/briteRepo/helpers/common.sh"
cp "$GIT_HELPER_SRC" "$WORK/briteRepo/helpers/git_helpers.sh"
cp "$HISTORY_HELPER_SRC" "$WORK/briteRepo/helpers/history_log.sh"
cp "$VALIDATION_HELPER_SRC" "$WORK/briteRepo/helpers/validation_helpers.sh"
cp "$COMMON_UTILS_HELPER_SRC" "$WORK/briteRepo/helpers/common_utils.sh"
chmod +x "$WORK/briteRepo/bin/undo"

cat > "$WORK/config/contributors.md" <<'EOF'
- testuser, A
EOF

(
  cd "$WORK"
  git config user.name "testuser"
  git config user.email "test@example.com"

  echo "seed" > README.md
  echo "# history" > logs/repository_history.md
  git add README.md briteRepo config logs
  git commit -m "seed repo" >/dev/null 2>&1
  git branch -M main
  git push -u origin main >/dev/null 2>&1
)

# 1) Help output
rc=$(run_capture "$TMPDIR/help.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/undo -h")
[[ "$rc" -eq 0 ]] || fail "undo -h should exit 0 (got $rc)"
assert_contains "Usage:" "$TMPDIR/help.out"
pass "help output"

# 2) Default type should be uncommitted and remove tracked/untracked changes.
echo "dirty" >> "$WORK/README.md"
echo "temp" > "$WORK/TEMP.txt"
rc=$(run_capture "$TMPDIR/default-uncommitted.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && printf 'y\n' | bash ./briteRepo/bin/undo")
[[ "$rc" -eq 0 ]] || fail "undo default uncommitted should exit 0 (got $rc)"
[[ ! -e "$WORK/TEMP.txt" ]] || fail "expected untracked TEMP.txt to be removed"
if [[ -n "$(cd "$WORK" && git status --porcelain)" ]]; then
  fail "expected clean worktree after undo default uncommitted"
fi
pass "default uncommitted behavior"

# 3) No uncommitted changes should return documented code 3.
rc=$(run_capture "$TMPDIR/no-uncommitted.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/undo")
[[ "$rc" -eq 3 ]] || fail "undo with no changes should exit 3 (got $rc)"
assert_contains "No uncommitted changes to undo" "$TMPDIR/no-uncommitted.out"
pass "no-uncommitted exit code"

# 4) Invalid branch names should still allow undo uncommitted.
(
  cd "$WORK"
  git checkout -b BadBranch >/dev/null 2>&1
)
echo "invalid branch dirty" >> "$WORK/README.md"
rc=$(run_capture "$TMPDIR/invalid-branch-uncommitted.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && printf 'y\n' | bash ./briteRepo/bin/undo")
[[ "$rc" -eq 0 ]] || fail "undo uncommitted should work on invalid branch name (got $rc)"
if [[ -n "$(cd "$WORK" && git status --porcelain)" ]]; then
  fail "expected clean worktree after invalid-branch uncommitted undo"
fi
pass "invalid branch allowed for uncommitted"

# 5) -c and -d should be accepted and dry-run should not change commit history.
(
  cd "$WORK"
  git checkout main >/dev/null 2>&1
  echo "new line" >> README.md
  git add README.md
  git commit -m "change for commit dry run" >/dev/null 2>&1
)
before_hash="$(cd "$WORK" && git rev-parse HEAD)"
rc=$(run_capture "$TMPDIR/commit-dry-run.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/undo -d commit -c 'test comment'")
[[ "$rc" -eq 0 ]] || fail "undo -d commit -c should exit 0 (got $rc)"
assert_contains "Dry-run: would soft reset HEAD~1" "$TMPDIR/commit-dry-run.out"
after_hash="$(cd "$WORK" && git rev-parse HEAD)"
[[ "$before_hash" == "$after_hash" ]] || fail "dry-run should not change HEAD"
pass "dry-run and -c option handling"

# 5b) Non-dry commit undo records workflow metadata instead of branch log files.
rc=$(run_capture "$TMPDIR/commit-undo.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && printf 'y\n' | bash ./briteRepo/bin/undo commit -c 'metadata check'")
[[ "$rc" -eq 0 ]] || fail "undo commit should exit 0 (got $rc)"
note="$(git -C "$WORK" notes --ref=briteRepo-workflow show HEAD 2>/dev/null || true)"
[[ "$note" == *"Workflow-Type: undo"* ]] || \
  fail "undo should record workflow metadata"
[[ "$note" == *"Undo-Type: commit"* ]] || \
  fail "undo metadata should record the undo type"
if find "$WORK/logs" -maxdepth 1 -type f -name '*_history.md' ! -name 'repository_history.md' -print -quit | grep -q .; then
  fail "undo should not create branch history log files"
fi
pass "undo workflow metadata"

# 6) pulldown should be accepted as a valid type.
(
  cd "$WORK"
  git checkout -b dev/topic-v1.0.0 >/dev/null 2>&1
  echo "topic" > topic.txt
  git add topic.txt
  git commit -m "topic commit" >/dev/null 2>&1
  git checkout main >/dev/null 2>&1
  git merge --no-ff dev/topic-v1.0.0 -m "Merge branch 'dev/topic-v1.0.0'" >/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/pulldown-dry-run.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/undo -d pulldown")
[[ "$rc" -eq 0 ]] || fail "undo -d pulldown should exit 0 (got $rc)"
assert_contains "Dry-run: would revert merge commit" "$TMPDIR/pulldown-dry-run.out"
pass "pulldown type support"

echo "All undo smoke tests passed."
