#!/usr/bin/env bash

# test_report_filters.sh - filter and ref smoke tests for scripts/bin/report.
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
rc=$(run_capture "$TMPDIR/user-filter.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report branch -u testuser -q 'committed by contributor' -l 10")
[[ "$rc" -eq 0 ]] || fail "user filter should exit 0 (got $rc)"
user_rel="$(report_path_from_output "$TMPDIR/user-filter.out")"
assert_contains "committed by contributor testuser" "$WORK/$user_rel"
pass "user literal filtering"

# 2) Literal filter should handle regex-like text safely
rc=$(run_capture "$TMPDIR/literal.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report -q '['")
[[ "$rc" -eq 3 ]] || fail "literal regex-like filter should exit 3 when unmatched (got $rc)"
assert_contains "No matching activity was found" "$TMPDIR/literal.out"
pass "literal text filter robustness"

# 3) Text filter should match summary or details
rc=$(run_capture "$TMPDIR/text-filter.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report branch -q 'Files-Modified: 1'")
[[ "$rc" -eq 0 ]] || fail "detail text filter should exit 0 (got $rc)"
text_rel="$(report_path_from_output "$TMPDIR/text-filter.out")"
assert_contains "Files-Modified: 1" "$WORK/$text_rel"
pass "summary and detail filtering"

# 4) Branch reports should always list the newest selected activity first
rc=$(run_capture "$TMPDIR/newest-first.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report branch -l 2")
[[ "$rc" -eq 0 ]] || fail "newest-first report should exit 0 (got $rc)"
newest_first_rel="$(report_path_from_output "$TMPDIR/newest-first.out")"
newer_line="$(grep -n 'retarget activity' "$WORK/$newest_first_rel" | head -n 1 | cut -d: -f1 || true)"
older_line="$(grep -n 'pull activity' "$WORK/$newest_first_rel" | head -n 1 | cut -d: -f1 || true)"
[[ -n "$newer_line" && -n "$older_line" && "$newer_line" -lt "$older_line" ]] || \
	fail "branch report should write selected activities newest first"
pass "newest-first branch ordering"

# 5) -r should report the current branch's remote without changing HEAD
branch_before="$(git -C "$WORK" symbolic-ref --short HEAD)"
head_before="$(git -C "$WORK" rev-parse HEAD)"
rc=$(run_capture "$TMPDIR/branch-r.out" bash -lc \
	"cd '$WORK' && bash ./scripts/bin/report -t 2 -r branch -q 'Pushed 1 commit'")
[[ "$rc" -eq 0 ]] || fail "remote branch report should exit 0 (got $rc)"
branch_r_rel="$(report_path_from_output "$TMPDIR/branch-r.out")"
[[ "$branch_r_rel" == reports/remote-*.md ]] || \
	fail "branch -r should write a remote report"
assert_contains "Pushed 1 commit(s) to origin/dev/report-tests-v1.0.0" \
	"$WORK/$branch_r_rel"
[[ "$(git -C "$WORK" symbolic-ref --short HEAD)" == "$branch_before" ]] || \
	fail "branch -r should not change the checked-out branch"
[[ "$(git -C "$WORK" rev-parse HEAD)" == "$head_before" ]] || \
	fail "branch -r should not change HEAD"
pass "direct remote branch report"

# 6) -r should fail clearly when the current branch has no remote
(
	cd "$WORK"
	git switch -c dev/local-only-v1.0.0 >/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/branch-r-missing.out" bash -lc \
	"cd '$WORK' && bash ./scripts/bin/report branch -r")
[[ "$rc" -eq 1 ]] || fail "missing remote branch report should exit 1 (got $rc)"
assert_contains "Remote branch 'origin/dev/local-only-v1.0.0' is not available" \
	"$TMPDIR/branch-r-missing.out"
[[ "$(git -C "$WORK" symbolic-ref --short HEAD)" == \
	"dev/local-only-v1.0.0" ]] || \
	fail "missing remote branch report should not change the checked-out branch"
git -C "$WORK" switch dev/report-tests-v1.0.0 >/dev/null 2>&1
pass "missing direct remote branch"

# 7) A remote snapshot should resolve its branch and push history
local_report="$(find "$WORK/reports" -maxdepth 1 -type f \
	-name 'local-*.md' -print -quit)"
[[ -n "$local_report" ]] || fail "expected local report before remote snapshot"
printf 'stale remote report\n' > "$WORK/reports/remote-20000101-000000.md"
(
	cd "$WORK"
	git update-ref refs/remotes/origin/alias-report-tests \
		refs/remotes/origin/dev/report-tests-v1.0.0
	git config --local chbranch.lastBranch dev/report-tests-v1.0.0
)
rc=$(run_capture "$TMPDIR/remote-push.out" bash -lc "cd '$WORK' && git switch --detach origin/dev/report-tests-v1.0.0 >/dev/null 2>&1 && bash ./scripts/bin/report branch -q 'Pushed 1 commit'")
[[ "$rc" -eq 0 ]] || fail "remote snapshot push report should exit 0 (got $rc)"
remote_push_rel="$(report_path_from_output "$TMPDIR/remote-push.out")"
[[ "$remote_push_rel" == reports/remote-*.md ]] || \
	fail "remote snapshot should write a remote report"
[[ -f "$local_report" ]] || fail "remote report should preserve the local report"
[[ ! -e "$WORK/reports/remote-20000101-000000.md" ]] || \
	fail "remote report should replace the prior remote report"
[[ "$(find "$WORK/reports" -maxdepth 1 -type f -name 'remote-*.md' | wc -l | tr -d ' ')" -eq 1 ]] || \
	fail "only one remote report should remain"
assert_contains '**Branch:** `dev/report-tests-v1.0.0`' "$WORK/$remote_push_rel"
assert_contains "Pushed 1 commit(s) to origin/dev/report-tests-v1.0.0" \
	"$WORK/$remote_push_rel"
assert_contains '**Command:** `push -t 5`' "$WORK/$remote_push_rel"
assert_contains "Previous-Remote-Tip:" "$WORK/$remote_push_rel"
assert_contains "Pushed-Tip:" "$WORK/$remote_push_rel"
assert_contains "Commits: 1" "$WORK/$remote_push_rel"
assert_contains "Files: 1 modified, 0 added, 0 deleted" "$WORK/$remote_push_rel"
pass "remote snapshot push report"

# 8) A new local report should replace only the previous local report
remote_report="$WORK/$remote_push_rel"
printf 'stale local report\n' > "$WORK/reports/local-20000101-000000.md"
rc=$(run_capture "$TMPDIR/local-again.out" bash -lc \
	"cd '$WORK' && git switch dev/report-tests-v1.0.0 >/dev/null 2>&1 && bash ./scripts/bin/report branch -q 'retarget activity'")
[[ "$rc" -eq 0 ]] || fail "replacement local report should exit 0 (got $rc)"
local_again_rel="$(report_path_from_output "$TMPDIR/local-again.out")"
[[ "$local_again_rel" == reports/local-*.md ]] || \
	fail "local branch should write a local report"
[[ -f "$remote_report" ]] || fail "local report should preserve the remote report"
[[ ! -e "$WORK/reports/local-20000101-000000.md" ]] || \
	fail "local report should replace the prior local report"
[[ "$(find "$WORK/reports" -maxdepth 1 -type f -name 'local-*.md' | wc -l | tr -d ' ')" -eq 1 ]] || \
	fail "only one local report should remain"
pass "independent local report retention"

echo "All report filter smoke tests passed."
