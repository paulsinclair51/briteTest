#!/usr/bin/env bash

# test_commit_reports.sh - report retention/permission smoke tests for briteRepo/bin/commit.
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
old_dry="$WORK/reports/commit-d-20000101-000000.md"
old_error="$WORK/reports/commit-e-20000101-000000.md"
old_legacy_failed="$WORK/reports/commit-f-20000101-000000.md"
old_success="$WORK/reports/commit-20000101-000000-12345.md"
printf 'old dry\n' > "$old_dry"
printf 'old error\n' > "$old_error"
printf 'old legacy failed\n' > "$old_legacy_failed"
printf 'old success\n' > "$old_success"
chmod 0444 "$old_dry" "$old_error" "$old_legacy_failed" "$old_success"

# 1) New dry-run should prune stale dry-run/error reports while keeping
# legacy failed and success reports under the current usage contract.
printf '\nretention trigger\n' >> "$WORK/README.md"
rc=$(run_capture "$TMPDIR/retention.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/commit -d -c 'retention cleanup test'")
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

# 3) A new directory should appear in the Directories section.
mkdir -p "$WORK/examples/demo"
printf 'demo\n' > "$WORK/examples/demo/demo.txt"
rc=$(run_capture "$TMPDIR/directories.out" env GITHUB_ACTOR=testuser bash -lc \
  "cd '$WORK' && bash ./briteRepo/bin/commit -d -c 'directory section test'")
[[ "$rc" -eq 0 ]] || fail "commit -d directory scenario should exit 0 (got $rc)"
dir_report="$(latest_report "$WORK")"
grep -Fq "| **Directory** | **Action** |" "$dir_report" || \
  fail "expected Directories table in the dry-run report"
grep -Fq "| \`examples/demo\` | Added |" "$dir_report" || \
  fail "expected the added directory row in the dry-run report"
grep -Fq "**Directories:** 2 added" "$dir_report" || \
  fail "expected the Directories summary line"
grep -Fq "**Files:** 1 modified and 1 added; 2 total." "$dir_report" || \
  fail "expected the Files summary line"
directories_line="$(grep -n '<summary>Directories</summary>' "$dir_report" |
  head -n 1 | cut -d: -f1)"
files_section_line="$(grep -n '<summary>Files</summary>' "$dir_report" |
  head -n 1 | cut -d: -f1)"
[[ "$directories_line" -lt "$files_section_line" ]] || \
  fail "expected Directories before Files"
grep -Fq "| **Lines** | **Action** |" "$dir_report" || \
  fail "expected the Lines and Action columns in the Files table"
pass "directories section and Lines column"

echo "All commit report smoke tests passed."
