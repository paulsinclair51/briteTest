#!/usr/bin/env bash

# test_commit_reports.sh - report retention/permission smoke tests for scripts/bin/commit.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=commit_test_lib.sh
source "$SCRIPT_DIR/commit_test_lib.sh"

commit_test_init

# Seed old failed and dry-run reports in the active branch report directory.
old_failed="$WORK/reports/branch/commit-f-20000101-000000.md"
old_dry="$WORK/reports/branch/commit-d-20000101-000000.md"
old_success="$WORK/reports/branch/commit-20000101-000000-12345.md"
printf 'old failed\n' > "$old_failed"
printf 'old dry\n' > "$old_dry"
printf 'old success\n' > "$old_success"
chmod 0444 "$old_failed" "$old_dry" "$old_success"

# 1) New dry-run should prune old failed/dry-run reports but keep success reports.
printf '\nretention trigger\n' >> "$WORK/README.md"
rc=$(run_capture "$TMPDIR/retention.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/commit -d -c 'retention cleanup test'")
[[ "$rc" -eq 0 ]] || fail "commit -d retention scenario should exit 0 (got $rc)"
[[ ! -e "$old_failed" ]] || fail "old failed report should be pruned"
[[ ! -e "$old_dry" ]] || fail "old dry-run report should be pruned"
[[ -e "$old_success" ]] || fail "old success report should be retained"
new_report="$(latest_report "$WORK")"
[[ -f "$new_report" ]] || fail "expected new dry-run report"
pass "report retention policy"

# 2) Report files should be read-only after generation.
perm_octal="$(stat -c '%a' "$new_report")"
owner_digit="${perm_octal: -3:1}"
group_digit="${perm_octal: -2:1}"
other_digit="${perm_octal: -1:1}"
(( (owner_digit & 2) == 0 )) || fail "report owner write bit should be cleared"
(( (group_digit & 2) == 0 )) || fail "report group write bit should be cleared"
(( (other_digit & 2) == 0 )) || fail "report other write bit should be cleared"
pass "report read-only permissions"

echo "All commit report smoke tests passed."
