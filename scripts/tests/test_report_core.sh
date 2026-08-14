#!/usr/bin/env bash

# test_report_core.sh - core smoke tests for scripts/bin/report.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=test_report_lib.sh
source "$SCRIPT_DIR/test_report_lib.sh"

report_test_init

# 1) Help output
rc=$(run_capture "$TMPDIR/help.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report -h")
[[ "$rc" -eq 0 ]] || fail "report -h should exit 0"
assert_contains "Usage:" "$TMPDIR/help.out"
assert_contains "-q TEXT" "$TMPDIR/help.out"
pass "help output"

# 2) Invalid -l should fail with usage message
rc=$(run_capture "$TMPDIR/invalid-limit.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report -l nope")
[[ "$rc" -eq 1 ]] || fail "report -l nope should exit 1 (got $rc)"
assert_contains "N for -l must be an integer >= 0" "$TMPDIR/invalid-limit.out"
pass "invalid limit rejection"

# 3) Default report type should return standardized commit entries only
rc=$(run_capture "$TMPDIR/default.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report -l 10")
[[ "$rc" -eq 0 ]] || fail "default report should exit 0 (got $rc)"
assert_contains "committed by contributor testuser" "$TMPDIR/default.out"
if grep -Fq "seed repo" "$TMPDIR/default.out"; then
  fail "default report should not include non-standardized seed commits"
fi
pass "default commit type filtering"

# 4) Verbose mode should parse metadata trailers
rc=$(run_capture "$TMPDIR/verbose.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report -v -l 10")
[[ "$rc" -eq 0 ]] || fail "verbose report should exit 0 (got $rc)"
assert_contains "Files: modified=1, added=0, deleted=0" "$TMPDIR/verbose.out"
assert_contains "Lines: added=3, deleted=1" "$TMPDIR/verbose.out"
assert_contains "Command line: commit -c <user-comment>" "$TMPDIR/verbose.out"
assert_contains "PR: 123" "$TMPDIR/verbose.out"
pass "verbose trailer parsing"

# 5) Type all should include non-standardized commits
rc=$(run_capture "$TMPDIR/type-all.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report -T all -l 20")
[[ "$rc" -eq 0 ]] || fail "report -T all should exit 0 (got $rc)"
assert_contains "seed repo" "$TMPDIR/type-all.out"
pass "type all includes generic commits"

# 6) Single-commit verbose mode should emit legacy commit report file format
rc=$(run_capture "$TMPDIR/single-legacy.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report -l 1 -v")
[[ "$rc" -eq 0 ]] || fail "single-commit verbose report should exit 0 (got $rc)"
legacy_rel="$(sed -n 's/^Results written to \(reports\/branch\/commit-[0-9]\{8\}-[0-9]\{6\}-[0-9a-f]\{7,40\}\.md\)$/\1/p' "$TMPDIR/single-legacy.out" | head -n 1)"
[[ -n "$legacy_rel" ]] || fail "expected legacy commit report path in output"
legacy_abs="$WORK/$legacy_rel"
[[ -f "$legacy_abs" ]] || fail "expected generated legacy report file"
assert_contains "# Commit Report" "$legacy_abs"
assert_contains "**Commit:** " "$legacy_abs"
assert_contains '**Branch:** `dev/report-tests-v1.0.0` (local)' "$legacy_abs"
assert_contains '**Command:** `commit -c first line\nFiles-Modified: 999`' "$legacy_abs"
assert_contains '**Files:** 1 modified, 0 added, 0 deleted, and 1 total.' "$legacy_abs"
assert_contains "## Commit" "$legacy_abs"
assert_contains "| **File** | **Added** | **Deleted** | **Net** | **Total** | **Notes** |" "$legacy_abs"
pass "single commit legacy report file"

# 7) Single-push verbose mode should emit legacy push report file format
rc=$(run_capture "$TMPDIR/push-legacy.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report -T push -l 1 -v")
[[ "$rc" -eq 0 ]] || fail "single-push verbose report should exit 0 (got $rc)"
push_rel="$(sed -n 's/^Results written to \(reports\/branch\/push-[0-9]\{8\}-[0-9]\{6\}-[0-9a-f]\{7,40\}\.md\)$/\1/p' "$TMPDIR/push-legacy.out" | head -n 1)"
[[ -n "$push_rel" ]] || fail "expected legacy push report path in output"
push_abs="$WORK/$push_rel"
[[ -f "$push_abs" ]] || fail "expected generated push report file"
assert_contains "# Push Report" "$push_abs"
assert_contains "**Push Tip:** " "$push_abs"
assert_contains "**Command:** \`push\`" "$push_abs"
assert_contains '**Branch:** `dev/report-tests-v1.0.0`' "$push_abs"
assert_contains "**Files:** " "$push_abs"
assert_contains "<summary><strong>Commits</strong></summary>" "$push_abs"
assert_contains "## Commits" "$push_abs"
assert_contains "| Commit Hash | DateTime | Comment |" "$push_abs"
assert_contains "<summary><strong>Files</strong></summary>" "$push_abs"
assert_contains "## Files" "$push_abs"
assert_contains "| File | Commit | Added | Deleted | Net | Total Lines |" "$push_abs"
pass "single push legacy report file"

# 8) Commit table should escape multiline content and pipe characters
(
  cd "$WORK"
  echo "more payload" >> payload.txt
  git add payload.txt
  git commit -m "push multiline comment" -m $'## User Comment\n\n> line one\n> line two\n> pipe | here\n\n## Summary' >/dev/null 2>&1
  git push origin dev/report-tests-v1.0.0 >/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/push-escaped.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report -T push -l 1 -v")
[[ "$rc" -eq 0 ]] || fail "push report with escaped comments should exit 0 (got $rc)"
push_rel="$(sed -n 's/^Results written to \(reports\/branch\/push-[0-9]\{8\}-[0-9]\{6\}-[0-9a-f]\{7,40\}\.md\)$/\1/p' "$TMPDIR/push-escaped.out" | head -n 1)"
[[ -n "$push_rel" ]] || fail "expected push report path in escaped comment test"
push_abs="$WORK/$push_rel"
[[ -f "$push_abs" ]] || fail "expected generated push report file for escaped comment test"
assert_contains "pipe \\| here" "$push_abs"
pass "commit table escapes markdown-sensitive content"

echo "All report core smoke tests passed."
