#!/usr/bin/env bash

# test_copyfix.sh - smoke tests for scripts/bin/copyfix.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COPYFIX_SRC="$REPO_ROOT/scripts/bin/copyfix"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

latest_report() {
  local pattern="$1"
  find "$WORK/reports/branch" -maxdepth 1 -type f -name "$pattern" \
    -printf '%T@ %p\n' | sort -n | tail -n 1 | cut -d' ' -f2-
}

for dep in bash find git grep mktemp; do
  command -v "$dep" >/dev/null 2>&1 || fail "missing required command: $dep"
done

TMPDIR="$(mktemp -d)"
cleanup() {
  chmod -R u+w "$TMPDIR" 2>/dev/null || true
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

ORIGIN="$TMPDIR/origin.git"
WORK="$TMPDIR/work"

git init --bare "$ORIGIN" >/dev/null 2>&1
git clone "file://$ORIGIN" "$WORK" >/dev/null 2>&1
mkdir -p "$WORK/scripts/bin" "$WORK/scripts/helpers" "$WORK/reports/branch"
cp "$COPYFIX_SRC" "$WORK/scripts/bin/copyfix"
for helper in common.sh git_helpers.sh history_log.sh report_helpers.sh; do
  cp "$REPO_ROOT/scripts/helpers/$helper" "$WORK/scripts/helpers/$helper"
done
chmod +x "$WORK/scripts/bin/copyfix"

(
  cd "$WORK"
  git config user.name "testuser"
  git config user.email "test@example.com"
  echo "seed" > README.md
  git add README.md scripts reports
  git commit -m "seed repo" >/dev/null 2>&1
  git branch -M main
  git push -u origin main >/dev/null 2>&1
  git branch dev/target-v1.0.0
  git push -u origin dev/target-v1.0.0 >/dev/null 2>&1
  git branch dev/token-target-v1.0.0
  git checkout dev/target-v1.0.0 >/dev/null 2>&1
  git checkout -b fix/source-v1.0.0 >/dev/null 2>&1
  git checkout dev/target-v1.0.0 >/dev/null 2>&1
)

cat > "$WORK/reports/branch/copyfix-d-20000101-000000.md" <<'EOF'
**Branch:** `dev/target-v1.0.0`
EOF
cat > "$WORK/reports/branch/copyfix-e-20000101-000001.md" <<'EOF'
**Branch:** `dev/target-v1.0.0`
EOF
chmod a-w "$WORK/reports/branch/copyfix-d-20000101-000000.md" \
  "$WORK/reports/branch/copyfix-e-20000101-000001.md"

set +e
(
  cd "$WORK"
  bash ./scripts/bin/copyfix fix/source-v1.0.0
) >"$TMPDIR/noop.out" 2>&1
rc=$?
set -e

[[ "$rc" -eq 4 ]] || fail "no-work copyfix should exit 4 (got $rc)"
grep -Fq "has no new commits to copy" "$TMPDIR/noop.out" || \
  fail "expected no-work copyfix prerequisite"
[[ "$(git -C "$WORK" branch --show-current)" == "dev/target-v1.0.0" ]] || \
  fail "no-op copyfix should remain on the target branch"
[[ -f "$WORK/reports/branch/copyfix-d-20000101-000000.md" ]] || \
  fail "copyfix prerequisite failure should preserve stale dry-run report"
[[ -f "$WORK/reports/branch/copyfix-e-20000101-000001.md" ]] || \
  fail "copyfix prerequisite failure should preserve stale error report"

echo "PASS: no-work copyfix prerequisite"

set +e
(
  cd "$WORK"
  bash ./scripts/bin/copyfix -m "obsolete" fix/source-v1.0.0
) >"$TMPDIR/obsolete-message.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 1 ]] || fail "obsolete -m option should exit 1 (got $rc)"
grep -Fq "Unknown option: -m" "$TMPDIR/obsolete-message.out" || \
  fail "expected obsolete -m option rejection"
echo "PASS: obsolete message option rejected"

set +e
(
  cd "$WORK"
  bash ./scripts/bin/copyfix -c "   " fix/source-v1.0.0
) >"$TMPDIR/empty-comment.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 1 ]] || fail "empty comment should exit 1 (got $rc)"
grep -Fq "must include at least one non-whitespace character" \
  "$TMPDIR/empty-comment.out" || fail "expected empty comment rejection"
echo "PASS: empty comment rejected"

set +e
(
  cd "$WORK"
  bash ./scripts/bin/copyfix dev/token-target-v1.0.0
) >"$TMPDIR/non-fix-source.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 2 ]] || fail "non-fix source should exit 2 (got $rc)"
grep -Fq "SOURCE_BRANCH must match fix/<description>-v<M>.<m>.0" \
  "$TMPDIR/non-fix-source.out" || fail "expected fix source validation"
echo "PASS: source argument must be a fix branch"

set +e
(
  cd "$WORK"
  bash ./scripts/bin/copyfix fix/missing-v1.0.0
) >"$TMPDIR/missing-source.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 3 ]] || fail "missing local source should exit 3 (got $rc)"
grep -Fq "Source branch not found locally: fix/missing-v1.0.0" \
  "$TMPDIR/missing-source.out" || fail "expected missing local source rejection"
[[ "$(git -C "$WORK" branch --show-current)" == "dev/target-v1.0.0" ]] || \
  fail "missing source failure should remain on the target branch"
echo "PASS: source must exist locally"

set +e
(
  cd "$WORK"
  git checkout main >/dev/null 2>&1
  bash ./scripts/bin/copyfix fix/source-v1.0.0
) >"$TMPDIR/read-only-target.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 2 ]] || fail "read-only target should exit 2 (got $rc)"
grep -Fq "Current target branch is read-only for copyfix: main" \
  "$TMPDIR/read-only-target.out" || fail "expected read-only target rejection"
[[ "$(git -C "$WORK" branch --show-current)" == "main" ]] || \
  fail "read-only target failure should remain on the target branch"
echo "PASS: current target branch must be writable"

set +e
(
  cd "$WORK"
  git checkout -b topic-branch >/dev/null 2>&1
  bash ./scripts/bin/copyfix fix/source-v1.0.0
) >"$TMPDIR/non-targeted-target.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 2 ]] || fail "non-targeted current branch should exit 2 (got $rc)"
grep -Fq "Current target branch must match <type>/<description>-v<M>.<m>.0" \
  "$TMPDIR/non-targeted-target.out" || fail "expected targeted branch validation"
[[ "$(git -C "$WORK" branch --show-current)" == "topic-branch" ]] || \
  fail "non-targeted target failure should remain on the current branch"
echo "PASS: current target branch must be targeted"

(
  cd "$WORK"
  git checkout fix/source-v1.0.0 >/dev/null 2>&1
  echo "copied fix" > copied-fix.txt
  git add copied-fix.txt
  git commit -m "original fix comment" >/dev/null 2>&1
  git checkout dev/target-v1.0.0 >/dev/null 2>&1
)

target_tip_before="$(git -C "$WORK" rev-parse dev/target-v1.0.0)"
set +e
(
  cd "$WORK"
  bash ./scripts/bin/copyfix -d fix/source-v1.0.0
) >"$TMPDIR/dry-run.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "copyfix dry-run should exit 0 (got $rc)"
[[ "$(git -C "$WORK" rev-parse dev/target-v1.0.0)" == "$target_tip_before" ]] || \
  fail "copyfix dry-run should not update the target"
grep -Fq "0 modified, 1 added, and 0 deleted files to be copied." "$TMPDIR/dry-run.out" || \
  fail "dry-run output should include file summary"
dry_report="$(latest_report 'copyfix-d-*.md')"
[[ -f "$dry_report" ]] || fail "copyfix dry-run should create a report"
grep -Fq "**Branch:** \`dev/target-v1.0.0\`" "$dry_report" || \
  fail "dry-run report should belong to the target branch"
grep -Fq "**Target Branch:** \`dev/target-v1.0.0\`" "$dry_report" || \
  fail "dry-run report should identify the target branch"
grep -Fq '**Summary:** 0 modified, 1 added, and 0 deleted files to be copied.' "$dry_report" || \
  fail "dry-run report should include file summary"
echo "PASS: dry-run report belongs to target branch"

set +e
(
  cd "$WORK"
  bash ./scripts/bin/copyfix fix/source-v1.0.0 -- Backport copied fix
) >"$TMPDIR/custom-comment.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "copyfix with -- comment should exit 0 (got $rc)"
[[ "$(git -C "$WORK" log -1 --format=%s fix/source-v1.0.0)" == "original fix comment" ]] || \
  fail "source branch should retain its original latest commit"
[[ "$(git -C "$WORK" log -1 --format=%s dev/target-v1.0.0)" == \
  "Backport copied fix" ]] || fail "expected target commit to use the -- comment"
copy_body="$(git -C "$WORK" log -1 --format=%B dev/target-v1.0.0)"
if grep -Fq "Command-Line: copyfix" <<< "$copy_body"; then
  fail "copied commit should not duplicate workflow history metadata"
fi
copy_note="$(git -C "$WORK" notes --ref=briteTest-workflow show \
  dev/target-v1.0.0)"
[[ "$(grep -c '^--- briteTest workflow ---$' <<< "$copy_note")" -eq 1 ]] || \
  fail "copyfix should record exactly one workflow event"
[[ "$copy_note" == *'Command-Line: copyfix fix/source-v1.0.0 -- Backport copied fix'* ]] || \
  fail "copyfix event should record its command line"
[[ "$copy_note" == *"from fix/source-v1.0.0 to dev/target-v1.0.0"* ]] || \
  fail "copyfix event should record its branches"
[[ "$(git -C "$WORK" branch --show-current)" == "dev/target-v1.0.0" ]] || \
  fail "copyfix should remain on the target branch"
grep -Fq "0 modified, 1 added, and 0 deleted files copied." "$TMPDIR/custom-comment.out" || \
  fail "copy output should include file summary"
grep -Fq "Run report for details." "$TMPDIR/custom-comment.out" || \
  fail "successful copyfix should defer details to report"
if find "$WORK/reports/branch" -maxdepth 1 -type f \
  -name 'copyfix-[0-9]*.md' -print -quit | grep -q .; then
  fail "successful copyfix should not create an immediate report"
fi
[[ "$copy_note" == *"Commits-Copied: 1"* ]] || \
  fail "copyfix event should record copied commit count"
[[ "$copy_note" == *"Files-Modified: 0"* ]] || \
  fail "copyfix event should record modified file count"
[[ "$copy_note" == *"Files-Added: 1"* ]] || \
  fail "copyfix event should record added file count"
[[ "$copy_note" == *"Files-Deleted: 0"* ]] || \
  fail "copyfix event should record deleted file count"
[[ "$copy_note" == *"Status: Fix commits copied to target branch"* ]] || \
  fail "copyfix event should record copy status"
[[ "$copy_note" == *"Method: Cherry-pick created by copyfix"* ]] || \
  fail "copyfix event should record copy method"
[[ ! -e "$dry_report" ]] || fail "success should remove stale source dry-run report"
if git -C "$WORK" show-ref --verify --quiet refs/remotes/origin/fix/source-v1.0.0; then
  fail "copyfix source should not require a remote branch"
fi
echo "PASS: -- comment is applied to copied fix commit"

(
  cd "$WORK"
  git checkout dev/token-target-v1.0.0 >/dev/null 2>&1
)
set +e
(
  cd "$WORK"
  bash ./scripts/bin/copyfix -c Backport fix/source-v1.0.0
) >"$TMPDIR/token-comment.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "copyfix with -c TOKEN should exit 0 (got $rc)"
[[ "$(git -C "$WORK" log -1 --format=%s dev/token-target-v1.0.0)" == "Backport" ]] || \
  fail "expected copied commit to use the -c token"
[[ "$(git -C "$WORK" branch --show-current)" == "dev/token-target-v1.0.0" ]] || \
  fail "copyfix with -c should remain on the target branch"
echo "PASS: -c token is applied to copied fix commit"

set +e
(
  cd "$WORK"
  git checkout dev/target-v1.0.0 >/dev/null 2>&1
  printf 'target file\n' > copied-fix.txt
  git add copied-fix.txt
  git commit -m "target file" >/dev/null 2>&1
  git checkout -b fix/rename-v1.0.0 >/dev/null 2>&1
  git mv copied-fix.txt renamed-fix.txt
  git commit -m "rename copied fix" >/dev/null 2>&1
  git checkout dev/target-v1.0.0 >/dev/null 2>&1
  bash ./scripts/bin/copyfix fix/rename-v1.0.0 >"$TMPDIR/rename.out" 2>&1
) >"$TMPDIR/rename-run.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "rename copyfix should exit 0 (got $rc)"
[[ "$(git -C "$WORK" branch --show-current)" == "dev/target-v1.0.0" ]] || \
  fail "rename copyfix should remain on the target branch"
grep -Fq "1 modified, 0 added, and 0 deleted files copied." "$TMPDIR/rename.out" || \
  fail "rename copy should count rename as modified"
echo "PASS: rename-based copy summary is counted correctly"

set +e
(
  cd "$WORK"
  git checkout dev/target-v1.0.0 >/dev/null 2>&1
  git checkout -b fix/lock-v1.0.0 >/dev/null 2>&1
  printf 'lock\n' > lock.txt
  git add lock.txt
  git commit -m 'lock commit' >/dev/null 2>&1
  git checkout dev/target-v1.0.0 >/dev/null 2>&1
  git reset --hard HEAD >/dev/null 2>&1
  mkdir -p bin
  cat > bin/git <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "fetch" ]]; then
  sleep 5
elif [[ "$1" == "cherry-pick" ]]; then
  sleep 5
fi
exec /usr/bin/git "$@"
EOF
  chmod +x bin/git
  PATH="$WORK/bin:$PATH" bash ./scripts/bin/copyfix fix/lock-v1.0.0 >"$TMPDIR/lock-primary.out" 2>&1 &
  primary_pid=$!
  sleep 1
  set +e
  PATH="$WORK/bin:$PATH" bash ./scripts/bin/copyfix fix/lock-v1.0.0 >"$TMPDIR/lock-secondary.out" 2>&1
  secondary_rc=$?
  set -e
  wait "$primary_pid"
  primary_rc=$?
  printf '%s\n' "$secondary_rc" >"$TMPDIR/lock-secondary-rc"
  printf '%s\n' "$primary_rc" >"$TMPDIR/lock-primary-rc"
) >"$TMPDIR/lock-run.out" 2>&1
rc=$?
set -e
secondary_rc="$(cat "$TMPDIR/lock-secondary-rc")"
primary_rc="$(cat "$TMPDIR/lock-primary-rc")"
[[ "${secondary_rc:-0}" -eq 2 ]] || fail "concurrent copyfix should exit 2 (got ${secondary_rc:-0})"
grep -Fq "Another copyfix operation is active" "$TMPDIR/lock-secondary.out" || \
  fail "concurrent copyfix should report the active-operation lock"
[[ "$primary_rc" -eq 0 ]] || fail "primary copyfix should exit 0 (got $primary_rc)"
state_dir="$(git -C "$WORK" rev-parse --path-format=absolute --git-common-dir)/briteTest-copyfix-state"
[[ ! -e "$state_dir" ]] || fail "copyfix should remove saved state after completion"
[[ ! -e "$state_dir.lock" ]] || fail "copyfix should release lock file after completion"
echo "PASS: copyfix locking prevents concurrent operations"

(
  cd "$WORK"
  git checkout main >/dev/null 2>&1
  git checkout -b dev/conflict-target-v1.0.0 >/dev/null 2>&1
  printf 'target conflict\n' > README.md
  git add README.md
  git commit -m "target conflict" >/dev/null 2>&1
  git checkout main >/dev/null 2>&1
  git checkout -b fix/conflict-v1.0.0 >/dev/null 2>&1
  printf 'source conflict\n' > README.md
  git add README.md
  git commit -m "source conflict" >/dev/null 2>&1
  git checkout dev/conflict-target-v1.0.0 >/dev/null 2>&1
)
set +e
(
  cd "$WORK"
  bash ./scripts/bin/copyfix fix/conflict-v1.0.0
) >"$TMPDIR/conflict.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 5 ]] || fail "conflicting copyfix should exit 5 (got $rc)"
[[ "$(git -C "$WORK" branch --show-current)" == "dev/conflict-target-v1.0.0" ]] || \
  fail "conflicting copyfix should remain on the target branch"
state_dir="$(git -C "$WORK" rev-parse --path-format=absolute --git-common-dir)/briteTest-copyfix-state"
[[ -d "$state_dir" ]] || fail "expected preserved copyfix state"
[[ -f "$state_dir/worktree" ]] || fail "expected preserved worktree path"
target_worktree="$(cat "$state_dir/worktree")"
[[ -d "$target_worktree" ]] || fail "expected preserved target worktree"
error_report="$(latest_report 'copyfix-e-*.md')"
[[ -f "$error_report" ]] || fail "conflicting copyfix should create an error report"
grep -Fq "**Branch:** \`dev/conflict-target-v1.0.0\`" "$error_report" || \
  fail "error report should belong to the current target branch"
grep -Fq '**Exit Code:** 5' "$error_report" || \
  fail "error report should include the conflict exit code"
printf 'resolved conflict\n' > "$target_worktree/README.md"
git -C "$target_worktree" add README.md
set +e
(
  cd "$WORK"
  bash ./scripts/bin/copyfix --continue fix/conflict-v1.0.0
) >"$TMPDIR/continue-with-arg.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 1 ]] || fail "copyfix --continue with source arg should exit 1 (got $rc)"
grep -Fq "Unexpected argument with --continue" "$TMPDIR/continue-with-arg.out" || \
  fail "continue mode should reject source argument"

set +e
(
  cd "$WORK"
  bash ./scripts/bin/copyfix --continue -c retry
) >"$TMPDIR/continue-with-comment.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 1 ]] || fail "copyfix --continue with comment should exit 1 (got $rc)"
grep -Fq "Comment options are not allowed with --continue" "$TMPDIR/continue-with-comment.out" || \
  fail "continue mode should reject comment options"

set +e
(
  cd "$WORK"
  GIT_EDITOR=true bash ./scripts/bin/copyfix --continue
) >"$TMPDIR/continue.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "copyfix --continue should exit 0 (got $rc)"
[[ "$(git -C "$WORK" show dev/conflict-target-v1.0.0:README.md)" == \
  "resolved conflict" ]] || fail "continued copyfix should update the target branch"
grep -Eq "files copied\\." "$TMPDIR/continue.out" || \
  fail "continued copyfix should report the copied file summary"
grep -Fq "Run report for details." "$TMPDIR/continue.out" || \
  fail "continued copyfix should defer details to report"
[[ "$(git -C "$WORK" branch --show-current)" == "dev/conflict-target-v1.0.0" ]] || \
  fail "continued copyfix should remain on the target branch"
[[ ! -e "$state_dir" ]] || fail "continued copyfix should remove saved state"
[[ ! -e "$target_worktree" ]] || fail "continued copyfix should remove target worktree"
continue_body="$(git -C "$WORK" log -1 --format=%B dev/conflict-target-v1.0.0)"
if grep -Fq "Command-Line: copyfix" <<< "$continue_body"; then
  fail "continued copied commit should not contain workflow metadata"
fi
continue_note="$(git -C "$WORK" notes --ref=briteTest-workflow show \
  dev/conflict-target-v1.0.0)"
[[ "$(grep -c '^--- briteTest workflow ---$' <<< "$continue_note")" -eq 1 ]] || \
  fail "continued copyfix should record exactly one workflow event"
[[ "$continue_note" == *"Command-Line: copyfix --continue"* ]] || \
  fail "continued copyfix event should record its command line"
[[ "$continue_note" == *"Status: Fix commits copied to target branch"* ]] || \
  fail "continued copyfix event should record copy status"
[[ ! -e "$error_report" ]] || fail "continued success should remove source error report"
echo "PASS: conflict continuation preserves target checkout"

echo "All copyfix smoke tests passed."