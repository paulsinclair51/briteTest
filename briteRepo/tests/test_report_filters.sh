#!/usr/bin/env bash

# test_report_filters.sh - filter and ref smoke tests for briteRepo/bin/report.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=test_report_lib.sh
source "$SCRIPT_DIR/test_report_lib.sh"

report_test_init

# 1) User substring filter should match author/login text in commit records
rc=$(run_capture "$TMPDIR/user-filter.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/report branch -u testuser -q 'committed by contributor' -l 10")
[[ "$rc" -eq 0 ]] || fail "user filter should exit 0 (got $rc)"
user_rel="$(report_path_from_output "$TMPDIR/user-filter.out")"
assert_contains "committed by contributor testuser" "$WORK/$user_rel"
assert_contains '**Command:** `commit -c' "$WORK/$user_rel"
if grep -Fq '\\ ' "$WORK/$user_rel"; then
	fail "user comment should not contain shell-escape backslashes"
fi
rc=$(run_capture "$TMPDIR/user-filter-false-positive.out" bash -lc \
	"cd '$WORK' && bash ./briteRepo/bin/report branch -u 'pushup activity' -l 0")
[[ "$rc" -eq 6 ]] || \
	fail "user filter should not match activity text (got $rc)"
assert_contains "No matching activity was found" \
	"$TMPDIR/user-filter-false-positive.out"
pass "user literal filtering"

# 2) Literal filter should handle regex-like text safely
rc=$(run_capture "$TMPDIR/literal.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/report -q '['")
[[ "$rc" -eq 6 ]] || fail "literal regex-like filter should exit 6 when unmatched (got $rc)"
assert_contains "No matching activity was found" "$TMPDIR/literal.out"
pass "literal text filter robustness"

# 3) Text filter should match summary or details
rc=$(run_capture "$TMPDIR/text-filter.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/report branch -q 'first line'")
[[ "$rc" -eq 0 ]] || fail "detail text filter should exit 0 (got $rc)"
text_rel="$(report_path_from_output "$TMPDIR/text-filter.out")"
if grep -Fq "## Commit Metadata" "$WORK/$text_rel"; then
	fail "branch report should not render the commit metadata section"
fi
if grep -Fq "**Summary:**" "$WORK/$text_rel"; then
	fail "branch report should not render action summary line"
fi
if [[ "$(grep -Fc 'committed by contributor testuser' "$WORK/$text_rel")" -gt 1 ]]; then
	fail "branch report should not duplicate the commit summary sentence"
fi
assert_contains "<summary>Files</summary>" "$WORK/$text_rel"
if grep -Fq "### Directories" "$WORK/$text_rel"; then
	fail "directory action section should be omitted when no directory add/delete/rename occurred"
fi
pass "summary and detail filtering"

# 3b) Directory action section should list only added/deleted/renamed directories
(
	cd "$WORK"
	mkdir -p dir-rename dir-delete
	echo "before" > dir-rename/file.txt
	echo "remove" > dir-delete/old.txt
	git add dir-rename/file.txt dir-delete/old.txt
	git commit -m "directory action seed" >/dev/null 2>&1
	git mv dir-rename dir-renamed
	mkdir -p dir-added
	echo "new" > dir-added/new.txt
	git add dir-added/new.txt
	git rm -r dir-delete >/dev/null 2>&1
	git commit -m "directory action fixture" >/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/directory-actions.out" bash -lc \
	"cd '$WORK' && bash ./briteRepo/bin/report branch -q 'directory action fixture' -l 1")
[[ "$rc" -eq 0 ]] || fail "directory action report should exit 0 (got $rc)"
directory_rel="$(report_path_from_output "$TMPDIR/directory-actions.out")"
assert_contains "**Directories:**" "$WORK/$directory_rel"
assert_contains "**Files:**" "$WORK/$directory_rel"
assert_contains "**Lines:**" "$WORK/$directory_rel"
assert_contains "<summary>Directories</summary>" "$WORK/$directory_rel"
assert_contains "| **Directory** | **Action** |" "$WORK/$directory_rel"
assert_contains '| `dir-renamed` | Renamed (was dir-rename) |' "$WORK/$directory_rel"
assert_contains '| `dir-added` | Added |' "$WORK/$directory_rel"
assert_contains '| `dir-delete` | Deleted |' "$WORK/$directory_rel"
pass "directory action rendering"

# 3c) Empty file summaries should not render Files/Lines summary fields.
(
	cd "$WORK"
	git commit --allow-empty \
		-m "empty summary fixture" \
		-m $'## Summary\n- Directories: none\n- Files: none\n- Lines: 0 added and 0 deleted.\n\n## Commit Metadata\n\nCommand-Line: commit -c empty summary fixture' \
		>/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/empty-summary.out" bash -lc \
	"cd '$WORK' && bash ./briteRepo/bin/report branch -q 'empty summary fixture' -l 1")
[[ "$rc" -eq 0 ]] || fail "empty summary report should exit 0 (got $rc)"
empty_summary_rel="$(report_path_from_output "$TMPDIR/empty-summary.out")"
if grep -Fq '**Directories:**' "$WORK/$empty_summary_rel"; then
	fail "empty summary report should omit Directories"
fi
if grep -Fq '**Files:**' "$WORK/$empty_summary_rel"; then
	fail "empty summary report should omit Files"
fi
if grep -Fq '**Lines:**' "$WORK/$empty_summary_rel"; then
	fail "empty summary report should omit Lines"
fi
pass "empty summary omission"

# 4) Multiple appended records should render independently, and delimiter-like
# text inside a detail value must not split a record.
rc=$(run_capture "$TMPDIR/multiple-records.out" bash -lc \
	"cd '$WORK' && bash ./briteRepo/bin/report branch -q 'Record-Group: appended pair' -l 0")
[[ "$rc" -eq 0 ]] || fail "multiple-record report should exit 0 (got $rc)"
multiple_rel="$(report_path_from_output "$TMPDIR/multiple-records.out")"
assert_contains "pull activity" "$WORK/$multiple_rel"
assert_contains "retarget activity" "$WORK/$multiple_rel"
assert_contains "**Record Group:** appended pair" "$WORK/$multiple_rel"
[[ "$(grep -c '^## ' "$WORK/$multiple_rel")" -eq 2 ]] || \
	fail "multiple appended records should render as two activities"
if ! grep -Eq '^## 1\. ' "$WORK/$multiple_rel" || \
	! grep -Eq '^## 2\. ' "$WORK/$multiple_rel"; then
	fail "filtered activities should start at one and increment by one"
fi
if grep -Eq '^## 3\. ' "$WORK/$multiple_rel"; then
	fail "filtered activities should be numbered consecutively"
fi
rc=$(run_capture "$TMPDIR/delimiter-detail.out" bash -lc \
	"cd '$WORK' && bash ./briteRepo/bin/report branch -q '--- briteRepo workflow --- marker'")
[[ "$rc" -eq 0 ]] || fail "delimiter-like detail report should exit 0 (got $rc)"
delimiter_rel="$(report_path_from_output "$TMPDIR/delimiter-detail.out")"
assert_contains "recorded pull details with --- briteRepo workflow --- marker" \
	"$WORK/$delimiter_rel"
pass "multiple workflow records and delimiter-like details"

# 5) Malformed workflow records should be skipped and diagnosed only in
# verbose mode without hiding valid records attached to the same commit.
rc=$(run_capture "$TMPDIR/malformed-quiet.out" bash -lc \
	"cd '$WORK' && bash ./briteRepo/bin/report branch -q 'retarget activity'")
[[ "$rc" -eq 0 ]] || fail "quiet malformed-note report should exit 0 (got $rc)"
if grep -Fq "Skipping malformed workflow record" "$TMPDIR/malformed-quiet.out"; then
	fail "malformed workflow warning should require verbose mode"
fi
rc=$(run_capture "$TMPDIR/malformed-verbose.out" bash -lc \
	"cd '$WORK' && bash ./briteRepo/bin/report branch -v -q 'retarget activity'")
[[ "$rc" -eq 0 ]] || fail "verbose malformed-note report should exit 0 (got $rc)"
assert_contains "Skipping malformed workflow record" \
	"$TMPDIR/malformed-verbose.out"
assert_contains "missing: Summary" "$TMPDIR/malformed-verbose.out"
malformed_rel="$(report_path_from_output "$TMPDIR/malformed-verbose.out")"
assert_contains "retarget activity" "$WORK/$malformed_rel"
pass "malformed workflow record handling"

# 6) Branch reports should always list the newest selected activity first
rc=$(run_capture "$TMPDIR/newest-first.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/report branch -q 'directory action' -l 2")
[[ "$rc" -eq 0 ]] || fail "newest-first report should exit 0 (got $rc)"
newest_first_rel="$(report_path_from_output "$TMPDIR/newest-first.out")"
newer_line="$(grep -n 'directory action fixture' "$WORK/$newest_first_rel" | head -n 1 | cut -d: -f1 || true)"
older_line="$(grep -n 'directory action seed' "$WORK/$newest_first_rel" | head -n 1 | cut -d: -f1 || true)"
[[ -n "$newer_line" && -n "$older_line" && "$newer_line" -lt "$older_line" ]] || \
	fail "branch report should write selected activities newest first"
pass "newest-first branch ordering"

# 7) -r should report the current branch's remote without changing HEAD
branch_before="$(git -C "$WORK" symbolic-ref --short HEAD)"
head_before="$(git -C "$WORK" rev-parse HEAD)"
rc=$(run_capture "$TMPDIR/branch-r.out" bash -lc \
	"cd '$WORK' && bash ./briteRepo/bin/report -t 2 -r branch -q 'Pushed 1 commit'")
[[ "$rc" -eq 0 ]] || fail "remote branch report should exit 0 (got $rc)"
branch_r_rel="$(report_path_from_output "$TMPDIR/branch-r.out")"
[[ "$branch_r_rel" == reports/remote-*.md ]] || \
	fail "branch -r should write a remote report"
assert_contains '**Commits:** 1' "$WORK/$branch_r_rel"
[[ "$(git -C "$WORK" symbolic-ref --short HEAD)" == "$branch_before" ]] || \
	fail "branch -r should not change the checked-out branch"
[[ "$(git -C "$WORK" rev-parse HEAD)" == "$head_before" ]] || \
	fail "branch -r should not change HEAD"
pass "direct remote branch report"

# 8) -r should fail clearly when the current branch has no remote
(
	cd "$WORK"
	git switch -c dev/local-only-v1.0.0 >/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/branch-r-missing.out" bash -lc \
	"cd '$WORK' && bash ./briteRepo/bin/report branch -r")
[[ "$rc" -eq 1 ]] || fail "missing remote branch report should exit 1 (got $rc)"
assert_contains "Remote branch 'origin/dev/local-only-v1.0.0' is not available" \
	"$TMPDIR/branch-r-missing.out"
[[ "$(git -C "$WORK" symbolic-ref --short HEAD)" == \
	"dev/local-only-v1.0.0" ]] || \
	fail "missing remote branch report should not change the checked-out branch"
git -C "$WORK" switch dev/report-tests-v1.0.0 >/dev/null 2>&1
pass "missing direct remote branch"

# 9) A remote snapshot should resolve its branch and push history
local_report="$(find "$WORK/reports" -maxdepth 1 -type f \
	-name 'local-*.md' -print -quit)"
[[ -n "$local_report" ]] || fail "expected local report before remote snapshot"
printf 'stale remote report\n' > "$WORK/reports/remote-20000101-000000+0000.md"
(
	cd "$WORK"
	git update-ref refs/remotes/origin/alias-report-tests \
		refs/remotes/origin/dev/report-tests-v1.0.0
	git config --local chbranch.lastBranch dev/report-tests-v1.0.0
)
rc=$(run_capture "$TMPDIR/remote-push.out" bash -lc "cd '$WORK' && git switch --detach origin/dev/report-tests-v1.0.0 >/dev/null 2>&1 && bash ./briteRepo/bin/report branch -q 'Pushed 1 commit'")
[[ "$rc" -eq 0 ]] || fail "remote snapshot push report should exit 0 (got $rc)"
remote_push_rel="$(report_path_from_output "$TMPDIR/remote-push.out")"
[[ "$remote_push_rel" == reports/remote-*.md ]] || \
	fail "remote snapshot should write a remote report"
[[ -f "$local_report" ]] || fail "remote report should preserve the local report"
[[ ! -e "$WORK/reports/remote-20000101-000000+0000.md" ]] || \
	fail "remote report should replace the prior remote report"
[[ "$(find "$WORK/reports" -maxdepth 1 -type f -name 'remote-*.md' | wc -l | tr -d ' ')" -eq 1 ]] || \
	fail "only one remote report should remain"
assert_contains '**Branch:** `dev/report-tests-v1.0.0`' "$WORK/$remote_push_rel"
assert_contains '**Status:** [remote]' "$WORK/$remote_push_rel"
assert_contains '**Command:** `push -t 5`' "$WORK/$remote_push_rel"
assert_contains '## 1. push: 2026-08-16 11:59:59+00:00' "$WORK/$remote_push_rel"
assert_contains '**Pushed-Tip:** `' "$WORK/$remote_push_rel"
if ! grep -Eq '^\*\*Pushed-Tip:\*\* `[0-9a-f]{40}`' \
	"$WORK/$remote_push_rel"; then
	fail "remote push Pushed-Tip should be a full commit hash"
fi
assert_contains '**Commits:** 1' "$WORK/$remote_push_rel"
if grep -Fq '**Directories:**' "$WORK/$remote_push_rel"; then
	fail "remote push report should omit Directories when no directories changed"
fi
if grep -Fq '<summary>Directories</summary>' "$WORK/$remote_push_rel"; then
	fail "remote push report should omit the Directories table when no directories changed"
fi
assert_contains '**Files:** 1 modified.' "$WORK/$remote_push_rel"
if grep -Fq '**Changes:**' "$WORK/$remote_push_rel"; then
	fail "remote push report should not include the legacy combined Changes line"
fi
assert_contains '**Lines:** 1 added and 0 deleted.' "$WORK/$remote_push_rel"
assert_contains '<summary>Commits</summary>' "$WORK/$remote_push_rel"
assert_contains '| **Commit** | **Date Time** | **Comment** |' "$WORK/$remote_push_rel"
assert_matches "| \`[0-9a-f]{40}\` \| [0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]][0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{2}:[0-9]{2} \|" "$WORK/$remote_push_rel"
assert_contains '<summary>Files</summary>' "$WORK/$remote_push_rel"
assert_contains '| **File** | **Commit** | **Added** | **Deleted** | **Net** | **Lines** | **Action** |' "$WORK/$remote_push_rel"
[[ "$(grep -c '^## ' "$WORK/$remote_push_rel")" -eq 1 ]] || \
	fail "push commits should not be counted as top-level actions"
pass "remote snapshot push report"

rc=$(run_capture "$TMPDIR/remote-empty-push.out" bash -lc \
	"cd '$WORK' && git switch --detach origin/dev/report-tests-v1.0.0 >/dev/null 2>&1 && bash ./briteRepo/bin/report branch -q 'Pushed 1 empty commit'")
[[ "$rc" -eq 0 ]] || fail "remote empty push report should exit 0 (got $rc)"
remote_empty_rel="$(report_path_from_output "$TMPDIR/remote-empty-push.out")"
assert_contains 'empty push metadata only' "$WORK/$remote_empty_rel"
if grep -Fq '**Directories:**' "$WORK/$remote_empty_rel"; then
	fail "remote empty push report should omit Directories"
fi
if grep -Fq '<summary>Directories</summary>' "$WORK/$remote_empty_rel"; then
	fail "remote empty push report should omit the Directories table"
fi
if grep -Fq '**Files:**' "$WORK/$remote_empty_rel"; then
	fail "remote empty push report should omit Files"
fi
if grep -Fq '**Lines:**' "$WORK/$remote_empty_rel"; then
	fail "remote empty push report should omit Lines"
fi
if grep -Fq '<summary>Files</summary>' "$WORK/$remote_empty_rel"; then
	fail "remote empty push report should omit the Files table"
fi
pass "remote empty push summary omission"

# 10) -r from a remote snapshot should report the current remote, not the
# commit at which HEAD remains detached.
snapshot_head="$(git -C "$WORK" rev-parse HEAD)"
UPDATE_WORK="$TMPDIR/remote-update"
git clone "$TMPDIR/origin.git" "$UPDATE_WORK" >/dev/null 2>&1
(
	cd "$UPDATE_WORK"
	git config user.name "remote-user"
	git config user.email "remote@example.com"
	git checkout dev/report-tests-v1.0.0 >/dev/null 2>&1
	echo "advanced" > remote-state.txt
	git add remote-state.txt
	git commit -m "remote state after snapshot" >/dev/null 2>&1
	git push origin dev/report-tests-v1.0.0 >/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/snapshot-current-remote.out" bash -lc \
	"cd '$WORK' && bash ./briteRepo/bin/report branch -r -t 2 -q 'remote state after snapshot'")
[[ "$rc" -eq 0 ]] || \
	fail "snapshot current-remote report should exit 0 (got $rc)"
snapshot_remote_rel="$(report_path_from_output \
	"$TMPDIR/snapshot-current-remote.out")"
assert_contains "remote state after snapshot" "$WORK/$snapshot_remote_rel"
[[ "$(git -C "$WORK" rev-parse HEAD)" == "$snapshot_head" ]] || \
	fail "snapshot -r report should not move detached HEAD"
[[ -z "$(git -C "$WORK" symbolic-ref -q --short HEAD || true)" ]] || \
	fail "snapshot -r report should leave HEAD detached"
pass "current remote report from snapshot"

# 11) A new local report should replace only the previous local report
remote_report="$WORK/$snapshot_remote_rel"
printf 'stale local report\n' > "$WORK/reports/local-20000101-000000+0000.md"
rc=$(run_capture "$TMPDIR/local-again.out" bash -lc \
	"cd '$WORK' && git switch dev/report-tests-v1.0.0 >/dev/null 2>&1 && bash ./briteRepo/bin/report branch -q 'retarget activity'")
[[ "$rc" -eq 0 ]] || fail "replacement local report should exit 0 (got $rc)"
local_again_rel="$(report_path_from_output "$TMPDIR/local-again.out")"
[[ "$local_again_rel" == reports/local-*.md ]] || \
	fail "local branch should write a local report"
[[ -f "$remote_report" ]] || fail "local report should preserve the remote report"
[[ ! -e "$WORK/reports/local-20000101-000000+0000.md" ]] || \
	fail "local report should replace the prior local report"
[[ "$(find "$WORK/reports" -maxdepth 1 -type f -name 'local-*.md' | wc -l | tr -d ' ')" -eq 1 ]] || \
	fail "only one local report should remain"
pass "independent local report retention"

# 12) Cleanup should preserve tracked reports when invoked from a subdirectory.
tracked_report="$WORK/reports/local-20000101-000002+0000.md"
printf 'tracked local report\n' > "$tracked_report"
git -C "$WORK" add reports/local-20000101-000002+0000.md
git -C "$WORK" commit -m "track report fixture" >/dev/null 2>&1
mkdir -p "$WORK/nested/report-test"
rc=$(run_capture "$TMPDIR/subdirectory.out" bash -lc \
	"cd '$WORK/nested/report-test' && bash ../../briteRepo/bin/report branch")
[[ "$rc" -eq 0 ]] || fail "subdirectory report should exit 0 (got $rc)"
[[ -f "$tracked_report" ]] || \
	fail "subdirectory report cleanup should preserve tracked reports"
pass "subdirectory tracked report preservation"

# 13) Concurrent branch reports should serialize write and cleanup, leaving one
# complete latest local report.
set +e
bash -c "cd '$WORK' && bash ./briteRepo/bin/report branch -l 2" \
	>"$TMPDIR/concurrent-1.out" 2>&1 &
report_pid_1=$!
bash -c "cd '$WORK' && bash ./briteRepo/bin/report branch -l 2" \
	>"$TMPDIR/concurrent-2.out" 2>&1 &
report_pid_2=$!
wait "$report_pid_1"; report_rc_1=$?
wait "$report_pid_2"; report_rc_2=$?
set -e
[[ "$report_rc_1" -eq 0 && "$report_rc_2" -eq 0 ]] || \
	fail "concurrent branch reports should both succeed"
concurrent_report_count="$(find "$WORK/reports" -maxdepth 1 -type f \
	-name 'local-*.md' ! -name 'local-20000101-000002+0000.md' | \
	wc -l | tr -d ' ')"
[[ "$concurrent_report_count" -eq 1 ]] || \
	fail "concurrent branch reports should leave one local report"
concurrent_report="$(find "$WORK/reports" -maxdepth 1 -type f \
	-name 'local-*.md' ! -name 'local-20000101-000002+0000.md' -print -quit)"
assert_contains "# Branch History Report" "$concurrent_report"
[[ "$(grep -c '^## ' "$concurrent_report")" -eq 2 ]] || \
	fail "concurrent branch report should contain two complete entries"
if ! awk '
	BEGIN { seen_first = 0; ok = 0 }
	/^## / {
		if (seen_first == 1 && prev_blank == 1) {
			ok = 1
			exit
		}
		seen_first = 1
	}
	{ prev_blank = ($0 ~ /^[[:space:]]*$/) }
	END { exit ok ? 0 : 1 }
' "$concurrent_report"; then
	fail "branch report should include a blank line before each activity section header"
fi
pass "concurrent branch report serialization"

echo "All report filter smoke tests passed."
