#!/usr/bin/env bash

# test_commit_core.sh - core smoke tests for briteRepo/bin/commit.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=test_commit_lib.sh
source "$SCRIPT_DIR/test_commit_lib.sh"

commit_test_init

# 1) Help output
rc=$(run_capture "$TMPDIR/help.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/commit -h")
[[ "$rc" -eq 0 ]] || fail "commit -h should exit 0"
assert_contains "Usage:" "$TMPDIR/help.out"
assert_contains "-d" "$TMPDIR/help.out"
pass "help output"

copyfix_state_root="$(git -C "$WORK" rev-parse \
  --path-format=absolute --git-common-dir)/briteRepo-copyfix-state"
mkdir -p "$copyfix_state_root/dev/commit-tests-v1.0.0"
rc=$(run_capture "$TMPDIR/copyfix-active.out" env GITHUB_ACTOR=testuser \
  bash -lc "cd '$WORK' && bash ./briteRepo/bin/commit")
[[ "$rc" -eq 8 ]] || fail "unfinished copyfix should block commit (got $rc)"
assert_contains "has an unfinished copyfix operation" \
  "$TMPDIR/copyfix-active.out"
rm -rf "$copyfix_state_root"
pass "unfinished copyfix blocks commit"

rebase_dir="$(git -C "$WORK" rev-parse --path-format=absolute \
  --git-path rebase-merge)"
mkdir -p "$rebase_dir"
touch "$rebase_dir/git-rebase-todo"
rc=$(run_capture "$TMPDIR/rebase-active.out" env GITHUB_ACTOR=testuser \
  bash -lc "cd '$WORK' && bash ./briteRepo/bin/commit")
[[ "$rc" -eq 9 ]] || fail "active pull rebase should block commit (got $rc)"
assert_contains "A pull operation is in progress" "$TMPDIR/rebase-active.out"
assert_contains "Guidance: resolve conflicts and rerun pull." \
  "$TMPDIR/rebase-active.out"
rm -rf "$rebase_dir"
pass "active pull rebase blocks commit"

echo "stale dry-run" > "$WORK/reports/commit-d-20000101-000000+0000.md"
echo "stale error" > "$WORK/reports/commit-e-20000101-000001+0000.md"
chmod a-w "$WORK/reports/commit-d-20000101-000000+0000.md" \
  "$WORK/reports/commit-e-20000101-000001+0000.md"
rc=$(run_capture "$TMPDIR/noop.out" env GITHUB_ACTOR=testuser \
  bash -lc "cd '$WORK' && bash ./briteRepo/bin/commit")
[[ "$rc" -eq 7 ]] || fail "no-work commit should exit 7 (got $rc)"
assert_contains "no changes to commit" "$TMPDIR/noop.out"
assert_contains "Guidance: make changes before rerunning commit." "$TMPDIR/noop.out"
[[ -f "$WORK/reports/commit-d-20000101-000000+0000.md" ]] || \
  fail "commit prerequisite failure should preserve stale dry-run reports"
[[ -f "$WORK/reports/commit-e-20000101-000001+0000.md" ]] || \
  fail "commit prerequisite failure should preserve stale error reports"
pass "no-work commit prerequisite"

# Internal remote snapshot branches use their source name in commit errors.
git -C "$WORK" branch "r-dev/commit-tests-v1.0.0" \
  "dev/commit-tests-v1.0.0" >/dev/null 2>&1
git -C "$WORK" switch "r-dev/commit-tests-v1.0.0" >/dev/null 2>&1
rc=$(run_capture "$TMPDIR/remote-snapshot.out" env GITHUB_ACTOR=testuser \
  bash -lc "cd '$WORK' && bash ./briteRepo/bin/commit -d -c 'snapshot test'")
[[ "$rc" -eq 5 ]] || \
  fail "remote snapshot commit should exit 5 (got $rc)"
assert_contains "local 'dev/commit-tests-v1.0.0'" \
  "$TMPDIR/remote-snapshot.out"
if grep -Fq "r-dev/commit-tests-v1.0.0" "$TMPDIR/remote-snapshot.out"; then
  fail "commit error should not expose internal r- branch"
fi
git -C "$WORK" switch dev/commit-tests-v1.0.0 >/dev/null 2>&1
git -C "$WORK" branch -D r-dev/commit-tests-v1.0.0 >/dev/null 2>&1
pass "remote snapshot branch name normalization"

rc=$(run_capture "$TMPDIR/invalid-timeout.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/commit -t nope -d -c 'invalid timeout'")
[[ "$rc" -eq 1 ]] || fail "unsupported -t should exit 1 (got $rc)"
assert_contains "Unknown option: -t" "$TMPDIR/invalid-timeout.out"
pass "unsupported -t rejection"

before_commits="$(cd "$WORK" && git rev-list --count HEAD)"
rc=$(run_capture "$TMPDIR/conflicting-modes.out" env GITHUB_ACTOR=testuser \
  bash -lc "cd '$WORK' && bash ./briteRepo/bin/commit -e -d -- commit.")
[[ "$rc" -eq 1 ]] || fail "conflicting -e/-d usage should exit 1 (got $rc)"
assert_contains "Cannot use both -d and -e." "$TMPDIR/conflicting-modes.out"
after_commits="$(cd "$WORK" && git rev-list --count HEAD)"
[[ "$after_commits" -eq "$before_commits" ]] || \
  fail "conflicting -e/-d usage should not create a commit"
pass "conflicting -e/-d mode handling"

# 2) Unauthorized user should be blocked with exit 3
printf '\nunauthorized role test\n' >> "$WORK/README.md"
(
  cd "$WORK"
  git config user.email "outsider@example.com"
)
rc=$(run_capture "$TMPDIR/unauth.out" env GITHUB_ACTOR=outsider bash -lc "cd '$WORK' && bash ./briteRepo/bin/commit -d -c 'test unauthorized'")
[[ "$rc" -eq 3 ]] || fail "unauthorized user should exit 3 (got $rc)"
assert_contains "Error: User 'outsider' is not authorized to run commit (requires contributor role or higher)" "$TMPDIR/unauth.out"
assert_contains "Guidance: use an account and merge path authorized by repository policy, then rerun commit." "$TMPDIR/unauth.out"
(
  cd "$WORK"
  git config user.email "test@example.com"
)
pass "role validation"

# 3) Dry-run commit should succeed for contributor and generate report
rc=$(run_capture "$TMPDIR/dry.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/commit -d -c 'dry run commit'")
[[ "$rc" -eq 0 ]] || fail "dry-run commit should exit 0 (got $rc)"
dry_report="$(latest_report "$WORK")"
[[ -f "$dry_report" ]] || fail "expected dry-run commit report"
assert_contains "Dry-run:" "$TMPDIR/dry.out"
assert_contains "See reports/commit-d-" "$TMPDIR/dry.out"
assert_contains "for details." "$TMPDIR/dry.out"
[[ "$(basename "$dry_report")" == commit-d-* ]] || fail "expected dry-run report filename"
assert_contains "# Dry-Run Commit Report" "$dry_report"
assert_contains '**Commit:** `To be determined`' "$dry_report"
assert_contains '**Branch:** `dev/commit-tests-v1.0.0`' "$dry_report"
assert_contains "**Status:** " "$dry_report"
assert_contains "## 1. commit: " "$dry_report"
assert_contains "**User:** " "$dry_report"
assert_contains "**Files:** " "$dry_report"
if grep -Fq "**Directories:** " "$dry_report"; then
  fail "unexpected Directories line in file-only report"
fi
assert_contains '**Command:** `commit -d -c "dry run commit"`' "$dry_report"
assert_contains "**Lines:** " "$dry_report"
commit_line="$(grep -n '^\*\*Commit:\*\*' "$dry_report" | head -n 1 | cut -d: -f1)"
command_line="$(grep -n '^\*\*Command:\*\*' "$dry_report" | head -n 1 | cut -d: -f1)"
user_line="$(grep -n '^\*\*User:\*\*' "$dry_report" | head -n 1 | cut -d: -f1)"
files_line="$(grep -n '^\*\*Files:\*\*' "$dry_report" | head -n 1 | cut -d: -f1)"
lines_line="$(grep -n '^\*\*Lines:\*\*' "$dry_report" | head -n 1 | cut -d: -f1)"
[[ -n "$commit_line" && -n "$command_line" && -n "$user_line" && -n "$files_line" ]] || \
  fail "expected Commit/Command/User/Files metadata lines"
[[ $((command_line - commit_line)) -eq 1 ]] || fail "expected Command line immediately after Commit line"
[[ $((user_line - command_line)) -eq 1 ]] || fail "expected User line immediately after Command line"
[[ $((files_line - user_line)) -eq 1 ]] || fail "expected Files line immediately after User line"
[[ $((lines_line - files_line)) -eq 1 ]] || fail "expected Lines line immediately after Files line"
assert_contains "<summary>Files</summary>" "$dry_report"
assert_contains "| **File** | **Added** | **Deleted** | **Net** | **Lines** | **Action** |" "$dry_report"
assert_contains "| **Total** | " "$dry_report"
assert_contains "</details>" "$dry_report"
pass "dry-run commit"

# 4) Missing message when changes exist should fail with exit 3
printf '\nmessage required test\n' >> "$WORK/README.md"
rc=$(run_capture "$TMPDIR/missing-message.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/commit")
[[ "$rc" -eq 2 ]] || fail "missing message should exit 2 (got $rc)"
assert_contains "User comment is required" "$TMPDIR/missing-message.out"
[[ -z "$(find "$WORK/reports" -maxdepth 1 -type f \
  -name 'commit-e-*.md' -print -quit)" ]] || \
  fail "prerequisite failure should not create an error report"
pass "missing message handling"

# 5) Empty message when changes exist should fail with exit 3
printf '\nempty message test\n' >> "$WORK/README.md"
rc=$(run_capture "$TMPDIR/empty-message.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/commit -c '   '")
[[ "$rc" -eq 2 ]] || fail "empty message should exit 2 (got $rc)"
assert_contains "User comment must include at least one non-whitespace character" "$TMPDIR/empty-message.out"
pass "empty message handling"

# 5b) Escaped newline-only message should fail as effectively empty
printf '\nescaped newline message test\n' >> "$WORK/README.md"
rc=$(run_capture "$TMPDIR/escaped-newline-message.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/commit -c '\\n'")
[[ "$rc" -eq 2 ]] || fail "escaped newline-only message should exit 2 (got $rc)"
assert_contains "User comment must include at least one non-whitespace character" "$TMPDIR/escaped-newline-message.out"
pass "escaped newline-only message handling"

# 6) -p should be rejected (auto-push is now implicit)
rc=$(run_capture "$TMPDIR/p_option.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/commit -d -p -c 'invalid option test'")
[[ "$rc" -eq 1 ]] || fail "commit -p should exit 1 (got $rc)"
assert_contains "Unknown option: -p" "$TMPDIR/p_option.out"
pass "-p option rejection"

# 7) Positional file arguments should be rejected
rc=$(run_capture "$TMPDIR/positional.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/commit README.md -c 'invalid positional arg test'")
[[ "$rc" -eq 1 ]] || fail "commit with positional file argument should exit 1 (got $rc)"
assert_contains "Unexpected argument: README.md" "$TMPDIR/positional.out"
pass "positional file argument rejection"

# 8) -e should skip the commit workflow with exit 6 and write an error report.
printf '\n-e skip test\n' >> "$WORK/README.md"
rc=$(run_capture "$TMPDIR/e-option.out" env GITHUB_ACTOR=testuser \
  bash -lc "cd '$WORK' && bash ./briteRepo/bin/commit -e -c 'skip via -e test'")
[[ "$rc" -eq 6 ]] || fail "commit -e should exit 6 (got $rc)"
assert_contains "Error: Commit skipped due to -e option." "$TMPDIR/e-option.out"
assert_contains "Guidance: Run without -e option." "$TMPDIR/e-option.out"
error_report="$(find "$WORK/reports" -maxdepth 1 -type f -name 'commit-e-*.md' -print -quit)"
[[ -f "$error_report" ]] || fail "commit -e should create an error report"
assert_contains "**Error:** Commit skipped due to -e option." "$error_report"
assert_contains "**Guidance:** Run without -e option." "$error_report"
pass "-e option skip behavior"

# 8b) The '--' comment form should also skip without creating a commit.
printf '\n-- skip test\n' >> "$WORK/README.md"
commit_count_before="$(cd "$WORK" && git rev-list --count HEAD)"
rc=$(run_capture "$TMPDIR/e-double-dash.out" env GITHUB_ACTOR=testuser \
  bash -lc "cd '$WORK' && bash ./briteRepo/bin/commit -e -- commit.")
[[ "$rc" -eq 6 ]] || fail "commit -e -- should exit 6 (got $rc)"
assert_contains "Error: Commit skipped due to -e option." "$TMPDIR/e-double-dash.out"
commit_count_after="$(cd "$WORK" && git rev-list --count HEAD)"
[[ "$commit_count_after" -eq "$commit_count_before" ]] || \
  fail "commit -e -- should not create a commit"
pass "commit -e -- skip behavior"

# 9) A failed non-dry commit should automatically write an error report.
cat > "$WORK/.git/hooks/pre-commit" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
chmod +x "$WORK/.git/hooks/pre-commit"
printf '\nautomatic error report test\n' >> "$WORK/README.md"
rc=$(run_capture "$TMPDIR/commit-failure.out" env GITHUB_ACTOR=testuser \
  bash -lc "cd '$WORK' && bash ./briteRepo/bin/commit -c 'automatic error report test'")
[[ "$rc" -eq 200 ]] || fail "failed commit should exit 200 (got $rc)"
error_report="$(find "$WORK/reports" -maxdepth 1 -type f \
  -name 'commit-e-*.md' -print -quit)"
[[ -f "$error_report" ]] || fail "failed commit should create an error report"
assert_contains "Failed to commit" "$error_report"
pass "failed commit automatically writes error report"

echo "All commit core smoke tests passed."
