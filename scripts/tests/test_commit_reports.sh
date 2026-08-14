#!/usr/bin/env bash

# test_commit_reports.sh - report retention/permission smoke tests for scripts/bin/commit.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=test_commit_lib.sh
source "$SCRIPT_DIR/test_commit_lib.sh"

commit_test_init

# Seed stale dry-run, stale error, legacy failed, and success reports.
old_dry="$WORK/reports/branch/commit-d-20000101-000000.md"
old_error="$WORK/reports/branch/commit-e-20000101-000000.md"
old_legacy_failed="$WORK/reports/branch/commit-f-20000101-000000.md"
old_success="$WORK/reports/branch/commit-20000101-000000-12345.md"
printf 'old dry\n' > "$old_dry"
printf 'old error\n' > "$old_error"
printf 'old legacy failed\n' > "$old_legacy_failed"
printf 'old success\n' > "$old_success"
chmod 0444 "$old_dry" "$old_error" "$old_legacy_failed" "$old_success"

# 1) New dry-run should prune stale dry-run/error reports while keeping
# legacy failed and success reports under the current usage contract.
printf '\nretention trigger\n' >> "$WORK/README.md"
rc=$(run_capture "$TMPDIR/retention.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/commit -d -c 'retention cleanup test'")
[[ "$rc" -eq 0 ]] || fail "commit -d retention scenario should exit 0 (got $rc)"
[[ ! -e "$old_dry" ]] || fail "old dry-run report should be pruned"
[[ ! -e "$old_error" ]] || fail "old error report should be pruned"
[[ -e "$old_legacy_failed" ]] || fail "legacy failed report should be retained under current usage"
[[ -e "$old_success" ]] || fail "old success report should be retained"
new_report="$(latest_report "$WORK")"
[[ -f "$new_report" ]] || fail "expected new dry-run report"
pass "report retention policy"

# 2) Report files should remain writable.
[[ -w "$new_report" ]] || fail "report should remain writable"
pass "report writable permissions"

echo "All commit report smoke tests passed."
