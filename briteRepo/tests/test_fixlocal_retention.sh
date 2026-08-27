#!/usr/bin/env bash

# test_fixlocal_retention.sh - report retention policy tests for fixlocal.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=test_fixlocal_lib.sh
source "$SCRIPT_DIR/test_fixlocal_lib.sh"

fixlocal_test_init

# 1) Dry-run must delete older dry-run reports but keep non-dry reports
RETENTION_DRY_REPO="$(make_fixture_repo retentiondry plain)"
attach_reachable_origin "$RETENTION_DRY_REPO" retentiondry
old_dry_report="$RETENTION_DRY_REPO/reports/repository-d-20000101-000000+0000-111.md"
old_non_dry_report="$RETENTION_DRY_REPO/reports/repository-20000101-000000+0000-222.md"
echo "old dry" > "$old_dry_report"
echo "old non-dry" > "$old_non_dry_report"
touch -d '40 days ago' "$old_dry_report" "$old_non_dry_report"

rc=$(run_capture "$TMPDIR/retention-dry.out" bash "$RETENTION_DRY_REPO/briteRepo/bin/fixlocal" -d -t 5)
[[ "$rc" -eq 0 ]] || [[ "$rc" -eq 7 ]] || fail "fixlocal -d should complete for retention test (got $rc)"
[[ ! -e "$old_dry_report" ]] || fail "older dry-run report should be deleted on new dry-run report"
[[ -e "$old_non_dry_report" ]] || fail "non-dry report should be retained on dry-run report generation"
pass "dry-run retention policy"

# 2) Non-dry run must delete older dry-run and old non-dry reports, keep recent non-dry
RETENTION_NON_DRY_REPO="$(make_fixture_repo retentionnondry plain)"
attach_reachable_origin "$RETENTION_NON_DRY_REPO" retentionnondry
old_dry_report_nd="$RETENTION_NON_DRY_REPO/reports/repository-d-20000101-000000+0000-311.md"
old_non_dry_report_nd="$RETENTION_NON_DRY_REPO/reports/repository-20000101-000000+0000-322.md"
recent_non_dry_report_nd="$RETENTION_NON_DRY_REPO/reports/repository-20990101-000000+0000-333.md"
echo "old dry" > "$old_dry_report_nd"
echo "old non-dry" > "$old_non_dry_report_nd"
echo "recent non-dry" > "$recent_non_dry_report_nd"
touch -d '40 days ago' "$old_dry_report_nd" "$old_non_dry_report_nd"
touch "$recent_non_dry_report_nd"

rc=$(run_capture "$TMPDIR/retention-nondry.out" bash "$RETENTION_NON_DRY_REPO/briteRepo/bin/fixlocal" -t 5)
[[ "$rc" -eq 0 ]] || fail "fixlocal non-dry retention test should exit 0 (got $rc)"
[[ ! -e "$old_dry_report_nd" ]] || fail "older dry-run report should be deleted on non-dry report generation"
[[ ! -e "$old_non_dry_report_nd" ]] || fail "old non-dry report should be deleted on non-dry report generation"
[[ -e "$recent_non_dry_report_nd" ]] || fail "recent non-dry report should be retained"
pass "non-dry retention policy"

echo "All fixlocal retention smoke tests passed."
