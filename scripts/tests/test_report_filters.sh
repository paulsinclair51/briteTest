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

# 1) Branch filtering should surface latest commit on the requested ref
rc=$(run_capture "$TMPDIR/branch.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report -b sandbox/report-other -l 1")
[[ "$rc" -eq 0 ]] || fail "branch-filtered report should exit 0 (got $rc)"
assert_contains "sandbox/report-other committed by contributor testuser" "$TMPDIR/branch.out"
pass "branch ref filtering"

# 2) Literal filter should handle regex-like text safely
rc=$(run_capture "$TMPDIR/literal.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report -q '['")
[[ "$rc" -eq 3 ]] || fail "literal regex-like filter should exit 3 when unmatched (got $rc)"
assert_contains "No entries found matching criteria" "$TMPDIR/literal.out"
pass "literal text filter robustness"

# 3) Unknown ref should fail as argument validation
rc=$(run_capture "$TMPDIR/bad-ref.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report -b does-not-exist")
[[ "$rc" -eq 1 ]] || fail "unknown ref should exit 1 (got $rc)"
assert_contains "Git ref not found" "$TMPDIR/bad-ref.out"
pass "unknown ref validation"

# 4) User substring filter should match author/login text in commit record
rc=$(run_capture "$TMPDIR/user-filter.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report -u testuser -l 10")
[[ "$rc" -eq 0 ]] || fail "user filter should exit 0 (got $rc)"
assert_contains "committed by contributor testuser" "$TMPDIR/user-filter.out"
pass "user literal filtering"

echo "All report filter smoke tests passed."
