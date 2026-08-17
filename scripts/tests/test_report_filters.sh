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
rc=$(run_capture "$TMPDIR/user-filter.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report commit -u testuser -l 10")
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
rc=$(run_capture "$TMPDIR/text-filter.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report commit -q 'Files-Modified: 1'")
[[ "$rc" -eq 0 ]] || fail "detail text filter should exit 0 (got $rc)"
text_rel="$(report_path_from_output "$TMPDIR/text-filter.out")"
assert_contains "committed by contributor testuser" "$WORK/$text_rel"
pass "summary and detail filtering"

# 4) Reverse should reorder only the newest N selected activities
rc=$(run_capture "$TMPDIR/reverse.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report commit -l 2 -r")
[[ "$rc" -eq 0 ]] || fail "reverse report should exit 0 (got $rc)"
reverse_rel="$(report_path_from_output "$TMPDIR/reverse.out")"
older_line="$(grep -n 'mrgup activity' "$WORK/$reverse_rel" | head -n 1 | cut -d: -f1 || true)"
newer_line="$(grep -n 'copyfix activity' "$WORK/$reverse_rel" | head -n 1 | cut -d: -f1 || true)"
[[ -n "$older_line" && -n "$newer_line" && "$older_line" -lt "$newer_line" ]] || \
	fail "reverse should write the selected activities oldest first"
pass "limit before reverse ordering"

# 5) A remote snapshot should resolve its branch and push history
(
	cd "$WORK"
	git update-ref refs/remotes/origin/alias-report-tests \
		refs/remotes/origin/dev/report-tests-v1.0.0
	git config --local chbranch.lastBranch dev/report-tests-v1.0.0
)
rc=$(run_capture "$TMPDIR/remote-push.out" bash -lc "cd '$WORK' && git switch --detach origin/dev/report-tests-v1.0.0 >/dev/null 2>&1 && bash ./scripts/bin/report push")
[[ "$rc" -eq 0 ]] || fail "remote snapshot push report should exit 0 (got $rc)"
remote_push_rel="$(report_path_from_output "$TMPDIR/remote-push.out")"
assert_contains '**Branch:** `dev/report-tests-v1.0.0`' "$WORK/$remote_push_rel"
assert_contains "Pushed 1 commit(s) to origin/dev/report-tests-v1.0.0" \
	"$WORK/$remote_push_rel"
assert_contains '**Command:** `push -t 5`' "$WORK/$remote_push_rel"
assert_contains "Previous-Remote-Tip:" "$WORK/$remote_push_rel"
assert_contains "Pushed-Tip:" "$WORK/$remote_push_rel"
assert_contains "Commits: 1" "$WORK/$remote_push_rel"
assert_contains "Files: 1 modified, 0 added, 0 deleted" "$WORK/$remote_push_rel"
pass "remote snapshot push report"

echo "All report filter smoke tests passed."
