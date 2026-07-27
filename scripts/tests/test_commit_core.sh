#!/usr/bin/env bash

# test_commit_core.sh - core smoke tests for scripts/bin/commit.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=commit_test_lib.sh
source "$SCRIPT_DIR/commit_test_lib.sh"

commit_test_init

# 1) Help output
rc=$(run_capture "$TMPDIR/help.out" bash -lc "cd '$WORK' && bash ./scripts/bin/commit -h")
[[ "$rc" -eq 0 ]] || fail "commit -h should exit 0"
assert_contains "Usage:" "$TMPDIR/help.out"
pass "help output"

# 2) Unauthorized user should be blocked with exit 2
printf '\nunauthorized role test\n' >> "$WORK/README.md"
(
  cd "$WORK"
  git config user.email "outsider@example.com"
)
rc=$(run_capture "$TMPDIR/unauth.out" env GITHUB_ACTOR=outsider bash -lc "cd '$WORK' && bash ./scripts/bin/commit -d -c 'test unauthorized'")
[[ "$rc" -eq 2 ]] || fail "unauthorized user should exit 2 (got $rc)"
assert_contains "is not authorized to run commit" "$TMPDIR/unauth.out"
(
  cd "$WORK"
  git config user.email "test@example.com"
)
pass "role validation"

# 3) Dry-run commit should succeed for contributor and generate report
rc=$(run_capture "$TMPDIR/dry.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/commit -d -c 'dry run commit'")
[[ "$rc" -eq 0 ]] || fail "dry-run commit should exit 0 (got $rc)"
dry_report="$(latest_report "$WORK")"
[[ -f "$dry_report" ]] || fail "expected dry-run commit report"
assert_contains "See reports/branch/commit-d-" "$TMPDIR/dry.out"
[[ "$(basename "$dry_report")" == commit-d-* ]] || fail "expected dry-run report filename"
assert_contains "**Commit Hash**" "$dry_report"
if grep -Fq -- "| n/a |" "$dry_report"; then
  fail "dry-run commit report should leave Commit Hash blank"
fi
pass "dry-run commit"

# 4) Missing message when changes exist should fail with exit 3
printf '\nmessage required test\n' >> "$WORK/README.md"
rc=$(run_capture "$TMPDIR/missing-message.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/commit")
[[ "$rc" -eq 3 ]] || fail "missing message should exit 3 (got $rc)"
assert_contains "Commit comment is required" "$TMPDIR/missing-message.out"
pass "missing message handling"

# 5) Empty message when changes exist should fail with exit 3
printf '\nempty message test\n' >> "$WORK/README.md"
rc=$(run_capture "$TMPDIR/empty-message.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/commit -c '   '")
[[ "$rc" -eq 3 ]] || fail "empty message should exit 3 (got $rc)"
assert_contains "must include at least one non-whitespace character" "$TMPDIR/empty-message.out"
pass "empty message handling"

# 6) -p should be rejected (auto-push is now implicit)
rc=$(run_capture "$TMPDIR/p_option.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/commit -d -p -c 'invalid option test'")
[[ "$rc" -eq 1 ]] || fail "commit -p should exit 1 (got $rc)"
assert_contains "Unknown option: -p" "$TMPDIR/p_option.out"
pass "-p option rejection"

# 7) Positional file arguments should be rejected
rc=$(run_capture "$TMPDIR/positional.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/commit README.md -c 'invalid positional arg test'")
[[ "$rc" -eq 1 ]] || fail "commit with positional file argument should exit 1 (got $rc)"
assert_contains "Unexpected argument: README.md" "$TMPDIR/positional.out"
pass "positional file argument rejection"

echo "All commit core smoke tests passed."
