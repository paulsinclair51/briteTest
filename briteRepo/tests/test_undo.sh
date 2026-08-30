#!/usr/bin/env bash

# test_undo.sh - smoke tests for briteRepo/bin/undo
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common_test_helpers.sh
source "$SCRIPT_DIR/common_test_helpers.sh"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
UNDO_SRC="$REPO_ROOT/briteRepo/bin/undo"
COMMON_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/common.sh"
GIT_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/git_helpers.sh"
HISTORY_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/history_log.sh"
REPORT_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/report_helpers.sh"
VALIDATION_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/validation_helpers.sh"
COMMON_UTILS_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/common_utils.sh"

for dep in bash git grep mktemp; do
  command -v "$dep" >/dev/null 2>&1 || fail "missing required command: $dep"
done

[[ -f "$UNDO_SRC" ]] || fail "missing script: $UNDO_SRC"
[[ -f "$COMMON_HELPER_SRC" ]] || fail "missing helper: $COMMON_HELPER_SRC"
[[ -f "$GIT_HELPER_SRC" ]] || fail "missing helper: $GIT_HELPER_SRC"
[[ -f "$HISTORY_HELPER_SRC" ]] || fail "missing helper: $HISTORY_HELPER_SRC"
[[ -f "$REPORT_HELPER_SRC" ]] || fail "missing helper: $REPORT_HELPER_SRC"
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
cp "$REPORT_HELPER_SRC" "$WORK/briteRepo/helpers/report_helpers.sh"
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
  printf 'reports/*.md\n' > .gitignore
  git add README.md .gitignore briteRepo config logs
  git commit -m "seed repo" >/dev/null 2>&1
  git branch -M main
  git push -u origin main >/dev/null 2>&1
)

# 1) Help output
rc=$(run_capture "$TMPDIR/help.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/undo -h")
[[ "$rc" -eq 0 ]] || fail "undo -h should exit 0 (got $rc)"
assert_contains "Usage:" "$TMPDIR/help.out"
assert_contains "-d" "$TMPDIR/help.out"
assert_contains "-e" "$TMPDIR/help.out"
assert_contains "-v" "$TMPDIR/help.out"
assert_contains "pushup operations cannot be undone by undo" \
  "$TMPDIR/help.out"
assert_contains "Except for uncommitted working tree changes" \
  "$TMPDIR/help.out"
assert_contains "records, workflow state, and referenced Git tips" \
  "$TMPDIR/help.out"
assert_contains "recover them manually" "$TMPDIR/help.out"
assert_contains "Related recovery:" "$TMPDIR/help.out"
pass "help output"

# 2) Default type should be uncommitted and remove tracked/untracked changes.
echo "dirty" >> "$WORK/README.md"
echo "temp" > "$WORK/TEMP.txt"
rc=$(run_capture "$TMPDIR/default-uncommitted.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && printf 'UNDO\n' | bash ./briteRepo/bin/undo -c 'discard scratch files'")
[[ "$rc" -eq 0 ]] || fail "undo default uncommitted should exit 0 (got $rc)"
assert_contains "Undo operation: uncommitted" \
  "$TMPDIR/default-uncommitted.out"
assert_contains "Safety: Tracked changes and untracked files will be permanently discarded." \
  "$TMPDIR/default-uncommitted.out"
assert_contains "Type UNDO to confirm:" "$TMPDIR/default-uncommitted.out"
[[ ! -e "$WORK/TEMP.txt" ]] || fail "expected untracked TEMP.txt to be removed"
if [[ -n "$(cd "$WORK" && git status --porcelain)" ]]; then
  fail "expected clean worktree after undo default uncommitted"
fi
uncommitted_note="$(git -C "$WORK" notes --ref=briteRepo-workflow show HEAD \
  2>/dev/null || true)"
[[ "$uncommitted_note" == *"Workflow-Type: undo"* ]] || \
  fail "uncommitted undo should record an undo event"
[[ "$uncommitted_note" == *"Comment: discard scratch files"* ]] || \
  fail "uncommitted undo should retain its comment"
success_report="$(find "$WORK/reports" -maxdepth 1 -type f \
  -name 'undo-uncommitted-*.md' -print -quit)"
[[ -f "$success_report" ]] || fail "expected successful undo report"
[[ "$(basename "$success_report")" =~ \
  ^undo-uncommitted-1-[0-9]{8}-[0-9]{6}[+-][0-9]{4}\.md$ ]] || \
  fail "first undo report should use sequence number 1"
assert_contains "**Status:** Completed" "$success_report"
assert_contains "**Strategy:** hard-reset-and-clean" "$success_report"
assert_contains "Undid uncommitted" "$TMPDIR/default-uncommitted.out"
if grep -Fq "Selected uncommitted operation" \
  "$TMPDIR/default-uncommitted.out"; then
  fail "non-verbose undo should omit progress output"
fi
pass "default uncommitted behavior"

# 3) No uncommitted changes should return documented code 3.
rc=$(run_capture "$TMPDIR/no-uncommitted.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/undo")
[[ "$rc" -eq 3 ]] || fail "undo with no changes should exit 3 (got $rc)"
assert_contains "No reversible modifying operation found" \
  "$TMPDIR/no-uncommitted.out"
pass "no-uncommitted exit code"

# 4) Invalid branch names should still allow undo uncommitted.
(
  cd "$WORK"
  git checkout -b BadBranch >/dev/null 2>&1
)
echo "invalid branch dirty" >> "$WORK/README.md"
rc=$(run_capture "$TMPDIR/invalid-branch-uncommitted.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && printf 'UNDO\n' | bash ./briteRepo/bin/undo")
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
before_commit="$(git -C "$WORK" rev-parse HEAD~1)"
(
  cd "$WORK"
  source briteRepo/helpers/history_log.sh
  bt_undo_record_operation commit main "$before_commit" "$before_hash" \
    soft-reset "change for commit dry run" >/dev/null
)
rc=$(run_capture "$TMPDIR/commit-dry-run.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/undo -d -c 'test comment'")
[[ "$rc" -eq 0 ]] || fail "undo -d -c should exit 0 (got $rc)"
assert_contains "Dry-run: would undo commit" "$TMPDIR/commit-dry-run.out"
dry_report="$(find "$WORK/reports" -maxdepth 1 -type f \
  -name 'undo-commit-d-*.md' -print -quit)"
[[ -f "$dry_report" ]] || fail "expected undo dry-run report"
assert_contains "**Mode:** dry-run" "$dry_report"
assert_contains "**Before Tip:** \`$before_commit\`" "$dry_report"
assert_contains "**After Tip:** \`$before_hash\`" "$dry_report"
after_hash="$(cd "$WORK" && git rev-parse HEAD)"
[[ "$before_hash" == "$after_hash" ]] || fail "dry-run should not change HEAD"
pass "dry-run and -c option handling"

rc=$(run_capture "$TMPDIR/mode-conflict.out" env GITHUB_ACTOR=testuser \
  bash -lc "cd '$WORK' && bash ./briteRepo/bin/undo -d -e")
[[ "$rc" -eq 1 ]] || fail "undo -d -e should exit 1 (got $rc)"
assert_contains "Options -d and -e are mutually exclusive" \
  "$TMPDIR/mode-conflict.out"
pass "dry-run and error-run conflict"

# 5a) -e writes an error report, removes the older report, and changes nothing.
rc=$(run_capture "$TMPDIR/commit-error-run.out" env GITHUB_ACTOR=testuser \
  bash -lc "cd '$WORK' && bash ./briteRepo/bin/undo -e")
[[ "$rc" -eq 10 ]] || fail "undo -e should exit 10 (got $rc)"
assert_contains "Undo skipped due to -e option" "$TMPDIR/commit-error-run.out"
error_report="$(find "$WORK/reports" -maxdepth 1 -type f \
  -name 'undo-commit-e-*.md' -print -quit)"
[[ -f "$error_report" ]] || fail "expected undo error-run report"
assert_contains "**Mode:** error" "$error_report"
[[ ! -e "$dry_report" ]] || fail "new undo report should remove older report"
[[ "$(git -C "$WORK" rev-parse HEAD)" == "$before_hash" ]] || \
  fail "error-run should not change HEAD"
pass "error-run report and cleanup"

# 5b) Verbose dry-run adds progress while normal output stays concise.
rc=$(run_capture "$TMPDIR/commit-verbose.out" env GITHUB_ACTOR=testuser \
  bash -lc "cd '$WORK' && bash ./briteRepo/bin/undo -d -v")
[[ "$rc" -eq 0 ]] || fail "undo -d -v should exit 0 (got $rc)"
assert_contains "Selected recorded commit operation" "$TMPDIR/commit-verbose.out"
assert_contains "Validated current tip" "$TMPDIR/commit-verbose.out"
pass "verbose progress output"

# 5c) Non-dry commit undo records workflow metadata and a detailed report.
rc=$(run_capture "$TMPDIR/commit-undo.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && printf 'UNDO\n' | bash ./briteRepo/bin/undo -c 'metadata check'")
[[ "$rc" -eq 0 ]] || fail "undo commit should exit 0 (got $rc)"
note="$(git -C "$WORK" notes --ref=briteRepo-workflow show HEAD 2>/dev/null || true)"
[[ "$note" == *"Workflow-Type: undo"* ]] || \
  fail "undo should record workflow metadata"
[[ "$note" == *"Undo-Type: commit"* ]] || \
  fail "undo metadata should record the undo type"
commit_report="$(find "$WORK/reports" -maxdepth 1 -type f \
  -name 'undo-commit-*.md' ! -name 'undo-commit-d-*' \
  ! -name 'undo-commit-e-*' -print -quit)"
[[ -f "$commit_report" ]] || fail "expected commit undo success report"
[[ "$(basename "$commit_report")" =~ \
  ^undo-commit-1-[0-9]{8}-[0-9]{6}[+-][0-9]{4}\.md$ ]] || \
  fail "new undo sequence should restart at 1"
[[ ! -e "$success_report" ]] || \
  fail "new undo sequence should remove prior success reports"
assert_contains "**Summary:** change for commit dry run" "$commit_report"
assert_contains "**Strategy:** soft-reset" "$commit_report"
if [[ -d "$WORK/logs" ]] && \
  find "$WORK/logs" -maxdepth 1 -type f \
    -name '*_history.md' -print -quit | grep -q .; then
  fail "undo should not create branch history log files"
fi
pass "undo workflow metadata"

# Bare undo selects the latest recorded operation for the current branch.
(
  cd "$WORK"
  source briteRepo/helpers/history_log.sh
  before_tip="$(git rev-parse HEAD)"
  echo "first ledger change" >> README.md
  git add README.md
  git commit -m "first ledger change" >/dev/null 2>&1
  first_tip="$(git rev-parse HEAD)"
  printf '%s\n' "$first_tip" > "$TMPDIR/first-ledger-tip"
  bt_undo_record_operation commit main "$before_tip" "$first_tip" \
    soft-reset "first ledger change" >/dev/null
  echo "second ledger change" >> README.md
  git add README.md
  git commit -m "second ledger change" >/dev/null 2>&1
  second_tip="$(git rev-parse HEAD)"
  bt_undo_record_operation commit main "$first_tip" "$second_tip" \
    soft-reset "second ledger change" >/dev/null
)
first_tip="$(cat "$TMPDIR/first-ledger-tip")"
rc=$(run_capture "$TMPDIR/auto-latest.out" env GITHUB_ACTOR=testuser \
  bash -lc "cd '$WORK' && printf 'UNDO\n' | bash ./briteRepo/bin/undo")
[[ "$rc" -eq 0 ]] || fail "bare undo should select latest operation (got $rc)"
assert_contains "Target: second ledger change" "$TMPDIR/auto-latest.out"
[[ "$(git -C "$WORK" rev-parse HEAD)" == "$first_tip" ]] || \
  fail "bare undo should reset to the latest operation's before tip"
sequence_one_report="$(find "$WORK/reports" -maxdepth 1 -type f \
  -name 'undo-commit-1-*.md' -print -quit)"
[[ -f "$sequence_one_report" ]] || \
  fail "new recorded operation should start a new undo sequence"
rc=$(run_capture "$TMPDIR/auto-uncommitted.out" env GITHUB_ACTOR=testuser \
  bash -lc "cd '$WORK' && printf 'UNDO\n' | bash ./briteRepo/bin/undo")
[[ "$rc" -eq 0 ]] || fail "second undo should discard staged changes (got $rc)"
assert_contains "Undo operation: uncommitted" "$TMPDIR/auto-uncommitted.out"
sequence_two_report="$(find "$WORK/reports" -maxdepth 1 -type f \
  -name 'undo-uncommitted-2-*.md' -print -quit)"
[[ -f "$sequence_one_report" && -f "$sequence_two_report" ]] || \
  fail "consecutive undo should preserve reports 1 and 2"
rc=$(run_capture "$TMPDIR/auto-previous.out" env GITHUB_ACTOR=testuser \
  bash -lc "cd '$WORK' && printf 'UNDO\n' | bash ./briteRepo/bin/undo")
[[ "$rc" -eq 0 ]] || fail "third undo should select preceding operation (got $rc)"
assert_contains "Target: first ledger change" "$TMPDIR/auto-previous.out"
sequence_three_report="$(find "$WORK/reports" -maxdepth 1 -type f \
  -name 'undo-commit-3-*.md' -print -quit)"
[[ -f "$sequence_one_report" && -f "$sequence_two_report" && \
  -f "$sequence_three_report" ]] || \
  fail "consecutive undo should preserve all three numbered reports"
pass "bare undo walks current-branch operation stack"

# A manual modification is a new sequence boundary even without an undo-stack
# record from another briteRepo command.
echo "manual sequence boundary" >> "$WORK/README.md"
rc=$(run_capture "$TMPDIR/manual-boundary.out" env GITHUB_ACTOR=testuser \
  bash -lc "cd '$WORK' && printf 'UNDO\n' | bash ./briteRepo/bin/undo")
[[ "$rc" -eq 0 ]] || fail "manual-boundary undo should exit 0 (got $rc)"
manual_report="$(find "$WORK/reports" -maxdepth 1 -type f \
  -name 'undo-uncommitted-1-*.md' -print -quit)"
[[ -f "$manual_report" ]] || \
  fail "manual modification should restart undo sequence at 1"
[[ ! -e "$sequence_one_report" && ! -e "$sequence_two_report" && \
  ! -e "$sequence_three_report" ]] || \
  fail "new manual sequence should remove prior success reports"
pass "manual modification starts new undo sequence"

# In-progress pull state is detected by its workflow marker and native rebase
# state; dry-run describes the exact abort without requiring confirmation.
(
  cd "$WORK"
  branch="$(git branch --show-current)"
  marker="$(git rev-parse --git-path briteRepo/pull.in-progress)"
  rebase_dir="$(git rev-parse --git-path rebase-merge)"
  mkdir -p "$(dirname "$marker")" "$rebase_dir"
  printf '%s\n' "$branch" > "$marker"
  touch "$rebase_dir/git-rebase-todo"
)
rc=$(run_capture "$TMPDIR/pull-progress-dry.out" env GITHUB_ACTOR=testuser \
  bash -lc "cd '$WORK' && bash ./briteRepo/bin/undo -d")
[[ "$rc" -eq 0 ]] || fail "in-progress pull dry-run should exit 0 (got $rc)"
assert_contains "would abort in-progress pull" "$TMPDIR/pull-progress-dry.out"
rm -f "$WORK/.git/briteRepo/pull.in-progress"
rm -rf "$WORK/.git/rebase-merge"
pass "in-progress pull undo detection"

# 6) pulldown should be accepted as a valid type.
(
  cd "$WORK"
  git checkout -b dev/topic-v1.0.0 >/dev/null 2>&1
  echo "topic" > topic.txt
  git add topic.txt
  git commit -m "topic commit" >/dev/null 2>&1
  git checkout main >/dev/null 2>&1
  git merge --no-ff dev/topic-v1.0.0 -m "Merge branch 'dev/topic-v1.0.0'" >/dev/null 2>&1
  source briteRepo/helpers/history_log.sh
  bt_undo_record_operation pulldown main "$(git rev-parse HEAD~1)" \
    "$(git rev-parse HEAD)" hard-reset \
    "Merge branch dev/topic-v1.0.0" >/dev/null
)
rc=$(run_capture "$TMPDIR/pulldown-dry-run.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/undo -d")
[[ "$rc" -eq 0 ]] || fail "automatic pulldown undo dry-run should exit 0 (got $rc)"
assert_contains "Dry-run: would undo pulldown" "$TMPDIR/pulldown-dry-run.out"
pass "pulldown automatic selection"

echo "All undo smoke tests passed."
