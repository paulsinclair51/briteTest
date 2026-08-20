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
assert_contains "Report the current local branch's remote state" "$TMPDIR/help.out"
assert_contains "TYPE may appear before or after options" "$TMPDIR/help.out"
if grep -Fq "Required history" "$TMPDIR/help.out"; then
  fail "help should not claim that missing history can be detected"
fi
pass "help output"

# 2) Invalid -l should fail with usage message
rc=$(run_capture "$TMPDIR/invalid-limit.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report -l nope")
[[ "$rc" -eq 1 ]] || fail "report -l nope should exit 1 (got $rc)"
assert_contains "N for -l must be an integer >= 0" "$TMPDIR/invalid-limit.out"
pass "invalid limit rejection"

rc=$(run_capture "$TMPDIR/branch-timeout-without-remote.out" bash -lc \
  "cd '$WORK' && bash ./scripts/bin/report branch -t 2")
[[ "$rc" -eq 1 ]] || fail "branch -t without -r should exit 1 (got $rc)"
assert_contains "Option -t requires -r for TYPE branch" \
  "$TMPDIR/branch-timeout-without-remote.out"
rc=$(run_capture "$TMPDIR/invalid-remote-timeout.out" bash -lc \
  "cd '$WORK' && bash ./scripts/bin/report branch -r -t 0")
[[ "$rc" -eq 1 ]] || fail "branch -r -t 0 should exit 1 (got $rc)"
assert_contains "SEC for -t must be an integer > 0" \
  "$TMPDIR/invalid-remote-timeout.out"
pass "branch remote timeout validation"

# 3) Default type all should write one newest activity
rc=$(run_capture "$TMPDIR/default.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report")
[[ "$rc" -eq 0 ]] || fail "default report should exit 0 (got $rc)"
default_rel="$(report_path_from_output "$TMPDIR/default.out")"
[[ -n "$default_rel" && -f "$WORK/$default_rel" ]] || fail "default report file was not created"
assert_contains '**Type:** `all`' "$WORK/$default_rel"
assert_contains "retarget activity" "$WORK/$default_rel"
[[ "$(grep -c '^## ' "$WORK/$default_rel")" -eq 1 ]] || fail "default limit should be one activity"
pass "default all report"

# 4) Verbose mode should report progress while details remain in the file
rc=$(run_capture "$TMPDIR/verbose.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report -v -l 10")
[[ "$rc" -eq 0 ]] || fail "verbose report should exit 0 (got $rc)"
assert_contains "matching activities" "$TMPDIR/verbose.out"
verbose_rel="$(report_path_from_output "$TMPDIR/verbose.out")"
assert_contains "### Details" "$WORK/$verbose_rel"
pass "verbose progress output"

# 5) Branch type with no limit should include generic commits and workflow activity
rc=$(run_capture "$TMPDIR/type-all.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report branch -l 0")
[[ "$rc" -eq 0 ]] || fail "report branch should exit 0 (got $rc)"
all_rel="$(report_path_from_output "$TMPDIR/type-all.out")"
assert_contains "seed repo" "$WORK/$all_rel"
assert_contains "pull activity" "$WORK/$all_rel"
pass "branch report includes every activity once"

# 6) TYPE may appear before or after options
rc=$(run_capture "$TMPDIR/type-before.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report branch -q 'pull activity' -l 1")
[[ "$rc" -eq 0 ]] || fail "TYPE before options should exit 0 (got $rc)"
before_rel="$(report_path_from_output "$TMPDIR/type-before.out")"
assert_contains "pull activity" "$WORK/$before_rel"
assert_contains '**Command:** `pull -v`' "$WORK/$before_rel"
assert_contains "recorded pull details" "$WORK/$before_rel"
rc=$(run_capture "$TMPDIR/type-after.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report -q 'pull activity' -l 1 branch")
[[ "$rc" -eq 0 ]] || fail "TYPE after options should exit 0 (got $rc)"
after_rel="$(report_path_from_output "$TMPDIR/type-after.out")"
assert_contains "pull activity" "$WORK/$after_rel"
pass "positional type placement"

# 7) Merge-down reports should render durable workflow details
rc=$(run_capture "$TMPDIR/mrgdown.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report branch -q 'mrgdown activity'")
[[ "$rc" -eq 0 ]] || fail "mrgdown report should exit 0 (got $rc)"
mrgdown_rel="$(report_path_from_output "$TMPDIR/mrgdown.out")"
assert_contains "mrgdown activity" "$WORK/$mrgdown_rel"
assert_contains '**Command:** `mrgdown -f`' "$WORK/$mrgdown_rel"
assert_contains "Source-Branch: v1.0.0" "$WORK/$mrgdown_rel"
assert_contains "Target-Branch: dev/report-tests-v1.0.0" "$WORK/$mrgdown_rel"
assert_contains "Parent-Commits-Integrated: 2" "$WORK/$mrgdown_rel"
assert_contains "Files-Modified: 1" "$WORK/$mrgdown_rel"
assert_contains "Status: Parent branch merged into current branch" "$WORK/$mrgdown_rel"
assert_contains "Method: Merge commit (--no-ff) created by mrgdown" "$WORK/$mrgdown_rel"
pass "mrgdown report details"

# 8) Merge-up reports should render durable workflow details
rc=$(run_capture "$TMPDIR/mrgup.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report branch -q 'mrgup activity'")
[[ "$rc" -eq 0 ]] || fail "mrgup report should exit 0 (got $rc)"
mrgup_rel="$(report_path_from_output "$TMPDIR/mrgup.out")"
assert_contains "mrgup activity" "$WORK/$mrgup_rel"
assert_contains '**Command:** `mrgup -o`' "$WORK/$mrgup_rel"
assert_contains "Source-Branch: dev/source-v1.0.0" "$WORK/$mrgup_rel"
assert_contains "Target-Branch: v1.0.0" "$WORK/$mrgup_rel"
assert_contains "PR: 42" "$WORK/$mrgup_rel"
assert_contains "Status: Current branch merged into parent branch" "$WORK/$mrgup_rel"
assert_contains "Method: Squash merge created by mrgup" "$WORK/$mrgup_rel"
assert_contains "CI-CD: ci build SUCCESS" "$WORK/$mrgup_rel"
pass "mrgup report details"

# 9) Copyfix reports should render durable workflow details
rc=$(run_capture "$TMPDIR/copyfix.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report branch -q 'copyfix activity'")
[[ "$rc" -eq 0 ]] || fail "copyfix report should exit 0 (got $rc)"
copyfix_rel="$(report_path_from_output "$TMPDIR/copyfix.out")"
assert_contains "copyfix activity" "$WORK/$copyfix_rel"
assert_contains '**Command:** `copyfix fix/source-v1.0.0`' "$WORK/$copyfix_rel"
assert_contains "Source-Branch: fix/source-v1.0.0" "$WORK/$copyfix_rel"
assert_contains "Target-Branch: dev/report-tests-v1.0.0" "$WORK/$copyfix_rel"
assert_contains "Commits-Copied: 2" "$WORK/$copyfix_rel"
assert_contains "Files-Modified: 1" "$WORK/$copyfix_rel"
assert_contains "Status: Fix commits copied to target branch" "$WORK/$copyfix_rel"
assert_contains "Method: Cherry-pick created by copyfix" "$WORK/$copyfix_rel"
pass "copyfix report details"

# 10) Retarget reports should render durable workflow details
rc=$(run_capture "$TMPDIR/retarget.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report branch -q 'retarget activity'")
[[ "$rc" -eq 0 ]] || fail "retarget report should exit 0 (got $rc)"
retarget_rel="$(report_path_from_output "$TMPDIR/retarget.out")"
assert_contains "retarget activity" "$WORK/$retarget_rel"
assert_contains '**Command:** `retarget -c move\ branch dev/report-tests-v1.0.0 v1.1.0`' \
  "$WORK/$retarget_rel"
assert_contains "Old-Parent: v1.0.0" "$WORK/$retarget_rel"
assert_contains "New-Parent: v1.1.0" "$WORK/$retarget_rel"
assert_contains "Retargeted-Tip:" "$WORK/$retarget_rel"
assert_contains "Comment: move branch" "$WORK/$retarget_rel"
pass "retarget report details"

# 11) TYPE may be specified only once
rc=$(run_capture "$TMPDIR/duplicate-type.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report branch repo")
[[ "$rc" -eq 1 ]] || fail "duplicate TYPE should exit 1 (got $rc)"
assert_contains "TYPE may be specified only once" "$TMPDIR/duplicate-type.out"
pass "duplicate type rejection"

# 12) Help overrides other arguments
rc=$(run_capture "$TMPDIR/help-overrides.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report unknown -h --bad")
[[ "$rc" -eq 0 ]] || fail "help should ignore other arguments (got $rc)"
assert_contains "Usage:" "$TMPDIR/help-overrides.out"
pass "help overrides arguments"

# 13) Repo reports include repository health and delegated branch status
rc=$(run_capture "$TMPDIR/repo.out" bash -lc "cd '$WORK' && bash ./scripts/bin/report repo -t 2")
[[ "$rc" -eq 0 ]] || fail "repo report should exit 0 (got $rc)"
repo_rel="$(sed -n 's/^See \(reports\/repo-[^ ]*\.md\) for details\.$/\1/p' \
  "$TMPDIR/repo.out" | tail -n 1)"
[[ -n "$repo_rel" && -f "$WORK/$repo_rel" ]] || fail "repo report file was not created"
assert_contains "## Health" "$WORK/$repo_rel"
assert_contains "## Branch Status" "$WORK/$repo_rel"
pass "repository report dispatch"

# 14) Style options and files are forwarded to ckstyle
rc=$(run_capture "$TMPDIR/style.out" bash -lc \
  "cd '$WORK' && bash ./scripts/bin/report -m -f README.md -v style")
[[ "$rc" -eq 0 ]] || fail "style report should exit 0 (got $rc)"
assert_contains "-m" "$WORK/style-args.txt"
assert_contains "README.md" "$WORK/style-args.txt"
assert_contains "-v" "$WORK/style-args.txt"
pass "style report dispatch"

echo "All report core smoke tests passed."
