#!/usr/bin/env bash

# test_report_core.sh - core smoke tests for briteRepo/bin/report.
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
rc=$(run_capture "$TMPDIR/help.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/report -h")
[[ "$rc" -eq 0 ]] || fail "report -h should exit 0"
assert_contains "Usage:" "$TMPDIR/help.out"
assert_contains "-q TEXT" "$TMPDIR/help.out"
assert_contains "If the current branch is a remote copy" "$TMPDIR/help.out"
assert_contains "-p" "$TMPDIR/help.out"
assert_contains "Combine with -r for the remote parent" "$TMPDIR/help.out"
assert_contains "TYPE may appear before or after options" "$TMPDIR/help.out"
assert_contains "Additional options only for a style report:" \
  "$TMPDIR/help.out"
if grep -Fq "Required history" "$TMPDIR/help.out"; then
  fail "help should not claim that missing history can be detected"
fi
pass "help output"

# 2) Invalid -l should fail with usage message
rc=$(run_capture "$TMPDIR/invalid-limit.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/report -l nope")
[[ "$rc" -eq 1 ]] || fail "report -l nope should exit 1 (got $rc)"
assert_contains "N for -l must be an integer >= 0" "$TMPDIR/invalid-limit.out"
pass "invalid limit rejection"

rc=$(run_capture "$TMPDIR/repo-parent.out" bash -lc \
  "cd '$WORK' && bash ./briteRepo/bin/report repo -p")
[[ "$rc" -eq 1 ]] || fail "report repo -p should exit 1 (got $rc)"
assert_contains "Option -p requires TYPE branch" "$TMPDIR/repo-parent.out"
rc=$(run_capture "$TMPDIR/style-parent.out" bash -lc \
  "cd '$WORK' && bash ./briteRepo/bin/report style -p")
[[ "$rc" -eq 1 ]] || fail "report style -p should exit 1 (got $rc)"
assert_contains "Option -p requires TYPE branch" "$TMPDIR/style-parent.out"
pass "parent option type validation"

rc=$(run_capture "$TMPDIR/branch-timeout-without-remote.out" bash -lc \
  "cd '$WORK' && bash ./briteRepo/bin/report branch -t 2")
[[ "$rc" -eq 1 ]] || fail "branch -t without -r should exit 1 (got $rc)"
assert_contains "Option -t requires -r for TYPE branch" \
  "$TMPDIR/branch-timeout-without-remote.out"
rc=$(run_capture "$TMPDIR/invalid-remote-timeout.out" bash -lc \
  "cd '$WORK' && bash ./briteRepo/bin/report branch -r -t 0")
[[ "$rc" -eq 1 ]] || fail "branch -r -t 0 should exit 1 (got $rc)"
assert_contains "SEC for -t must be an integer > 0" \
  "$TMPDIR/invalid-remote-timeout.out"
pass "branch remote timeout validation"

# 3) Default type all should write one newest activity
printf 'current branch worktree change\n' > "$WORK/current-only-uncommitted.txt"
rc=$(run_capture "$TMPDIR/default.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/report")
[[ "$rc" -eq 0 ]] || fail "default report should exit 0 (got $rc)"
default_rel="$(report_path_from_output "$TMPDIR/default.out")"
[[ -n "$default_rel" && -f "$WORK/$default_rel" ]] || fail "default report file was not created"
if grep -Fq '**Type:**' "$WORK/$default_rel"; then
  fail "report should not include redundant Type metadata"
fi
assert_contains '**Branch:** `dev/report-tests-v1.0.0`' "$WORK/$default_rel"
assert_contains '**Status:** [uncommitted] [local]' "$WORK/$default_rel"
if grep -Fq '[current]' "$WORK/$default_rel"; then
  fail "branch report should not include the current tag"
fi
assert_contains '**Command:** `report`' "$WORK/$default_rel"
assert_contains '**User:** testuser (contributor)' "$WORK/$default_rel"
assert_contains "retarget activity" "$WORK/$default_rel"
default_commit_hash="$(git -C "$WORK" rev-parse HEAD)"
assert_contains "**Commit:** \`$default_commit_hash\`" "$WORK/$default_rel"
[[ "$(grep -c '^## ' "$WORK/$default_rel")" -eq 1 ]] || fail "default limit should be one activity"
if grep -Fq '**Summary:**' "$WORK/$default_rel"; then
  fail "action summary line should be omitted"
fi
if [[ "$(tail -c 1 "$WORK/$default_rel" | od -An -t x1 | tr -d ' \n')" != "0a" ]] || \
  [[ "$(tail -c 2 "$WORK/$default_rel" | od -An -t x1 | tr -d ' \n')" == "0a0a" ]]; then
  fail "branch report should end with exactly one newline"
fi
pass "default all report"

# 3b) Parent reports do not change the current branch
rc=$(run_capture "$TMPDIR/local-parent.out" bash -lc \
  "cd '$WORK' && bash ./briteRepo/bin/report -p")
[[ "$rc" -eq 0 ]] || fail "local parent report should exit 0 (got $rc)"
local_parent_rel="$(report_path_from_output "$TMPDIR/local-parent.out")"
[[ "$local_parent_rel" == reports/p-local-*.md ]] || \
  fail "local parent report should use the p-local prefix"
assert_contains '**Branch:** `v1.0.0`' "$WORK/$local_parent_rel"
assert_matches '^\*\*Status:\*\* .*\[local\]' "$WORK/$local_parent_rel"
if grep -Fq '[uncommitted]' "$WORK/$local_parent_rel"; then
  fail "local parent report should not inherit current branch uncommitted status"
fi
[[ "$(git -C "$WORK" branch --show-current)" == "dev/report-tests-v1.0.0" ]] || \
  fail "local parent report should not change the current branch"

rc=$(run_capture "$TMPDIR/remote-parent.out" bash -lc \
  "cd '$WORK' && bash ./briteRepo/bin/report -p -r")
[[ "$rc" -eq 0 ]] || fail "remote parent report should exit 0 (got $rc)"
remote_parent_rel="$(report_path_from_output "$TMPDIR/remote-parent.out")"
[[ "$remote_parent_rel" == reports/p-remote-*.md ]] || \
  fail "remote parent report should use the p-remote prefix"
assert_contains '**Branch:** `v1.0.0`' "$WORK/$remote_parent_rel"
assert_matches '^\*\*Status:\*\* .*\[remote\]' "$WORK/$remote_parent_rel"
[[ "$(git -C "$WORK" branch --show-current)" == "dev/report-tests-v1.0.0" ]] || \
  fail "remote parent report should not change the current branch"
rm -f "$WORK/current-only-uncommitted.txt"
pass "local and remote parent reports"

# 4) Verbose mode should report progress while details remain in the file
rc=$(run_capture "$TMPDIR/verbose.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/report -v -l 10")
[[ "$rc" -eq 0 ]] || fail "verbose report should exit 0 (got $rc)"
assert_contains "matching activities" "$TMPDIR/verbose.out"
verbose_rel="$(report_path_from_output "$TMPDIR/verbose.out")"
[[ -f "$WORK/$verbose_rel" ]] || fail "verbose report file was not created"
pass "verbose progress output"

# 5) Branch type with no limit should include generic commits and workflow activity
rc=$(run_capture "$TMPDIR/type-all.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/report branch -l 0")
[[ "$rc" -eq 0 ]] || fail "report branch should exit 0 (got $rc)"
all_rel="$(report_path_from_output "$TMPDIR/type-all.out")"
assert_contains "seed repo" "$WORK/$all_rel"
assert_contains "pull activity" "$WORK/$all_rel"
pass "branch report includes every activity once"

# 6) TYPE may appear before or after options
rc=$(run_capture "$TMPDIR/type-before.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/report branch -q 'pull activity' -l 1")
[[ "$rc" -eq 0 ]] || fail "TYPE before options should exit 0 (got $rc)"
before_rel="$(report_path_from_output "$TMPDIR/type-before.out")"
assert_contains "pull activity" "$WORK/$before_rel"
assert_contains '**Command:** `pull -v`' "$WORK/$before_rel"
assert_contains "recorded pull details" "$WORK/$before_rel"
before_command_line="$(grep -n '\*\*Command:\*\* `pull -v`' "$WORK/$before_rel" | head -n 1 | cut -d: -f1 || true)"
before_user_line="$(grep -n '\*\*User:\*\* testuser (contributor)' "$WORK/$before_rel" | head -n 1 | cut -d: -f1 || true)"
[[ -n "$before_command_line" && -n "$before_user_line" && "$before_command_line" -lt "$before_user_line" ]] || \
  fail "action command line should appear before action user line"
rc=$(run_capture "$TMPDIR/type-after.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/report -q 'pull activity' -l 1 branch")
[[ "$rc" -eq 0 ]] || fail "TYPE after options should exit 0 (got $rc)"
after_rel="$(report_path_from_output "$TMPDIR/type-after.out")"
assert_contains "pull activity" "$WORK/$after_rel"
pass "positional type placement"

# 7) Merge-down reports should render durable workflow details
rc=$(run_capture "$TMPDIR/pulldown.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/report branch -q 'pulldown activity'")
[[ "$rc" -eq 0 ]] || fail "pulldown report should exit 0 (got $rc)"
pulldown_rel="$(report_path_from_output "$TMPDIR/pulldown.out")"
assert_contains "pulldown activity" "$WORK/$pulldown_rel"
assert_contains '**Command:** `pulldown -f`' "$WORK/$pulldown_rel"
if grep -Fq '## Workflow Metadata' "$WORK/$pulldown_rel"; then
  fail "pulldown report should omit Workflow Metadata"
fi
if grep -Fq '<summary>Files</summary>' "$WORK/$pulldown_rel"; then
  fail "content-neutral pulldown report should omit the Files section"
fi
pass "pulldown report details"

# 8) Merge-up reports should render durable workflow details
rc=$(run_capture "$TMPDIR/pushup.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/report branch -q 'pushup activity'")
[[ "$rc" -eq 0 ]] || fail "pushup report should exit 0 (got $rc)"
pushup_rel="$(report_path_from_output "$TMPDIR/pushup.out")"
assert_contains "pushup activity" "$WORK/$pushup_rel"
assert_contains '**Command:** `pushup -o`' "$WORK/$pushup_rel"
assert_matches \
  '^\*\*Source Branch:\*\* dev/report-tests-v1\.0\.0 \([0-9a-f]{40}\)  $' \
  "$WORK/$pushup_rel"
if grep -Eq '^Source-Tip:' "$WORK/$pushup_rel"; then
  fail "pushup report should combine Source-Tip with Source-Branch"
fi
assert_contains "**Target Branch:** v1.0.0" "$WORK/$pushup_rel"
assert_contains "**PR:** 42" "$WORK/$pushup_rel"
assert_contains "**Status:** Current branch merged into parent branch" "$WORK/$pushup_rel"
assert_contains "**Method:** Squash merge created by pushup" "$WORK/$pushup_rel"
assert_contains "**CI CD:** ci build SUCCESS" "$WORK/$pushup_rel"
pass "pushup report details"

# 8b) Other metadata-only workflow actions should render durable details.
rc=$(run_capture "$TMPDIR/mkbranch.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/report branch -q 'mkbranch activity'")
[[ "$rc" -eq 0 ]] || fail "mkbranch report should exit 0 (got $rc)"
mkbranch_rel="$(report_path_from_output "$TMPDIR/mkbranch.out")"
assert_contains "mkbranch activity" "$WORK/$mkbranch_rel"
assert_contains '**Command:** `mkbranch dev/report-tests-v1.0.0 v1.0.0`' "$WORK/$mkbranch_rel"
assert_contains "**New Branch:** dev/report-tests-v1.0.0" "$WORK/$mkbranch_rel"
assert_contains "**Parent Branch:** v1.0.0" "$WORK/$mkbranch_rel"

rc=$(run_capture "$TMPDIR/release.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/report branch -q 'release activity'")
[[ "$rc" -eq 0 ]] || fail "release report should exit 0 (got $rc)"
release_rel="$(report_path_from_output "$TMPDIR/release.out")"
assert_contains "release activity" "$WORK/$release_rel"
assert_contains '**Command:** `release v1.2.0`' "$WORK/$release_rel"
assert_contains "**Version:** v1.2.0" "$WORK/$release_rel"

rc=$(run_capture "$TMPDIR/undo.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/report branch -q 'undo activity'")
[[ "$rc" -eq 0 ]] || fail "undo report should exit 0 (got $rc)"
undo_rel="$(report_path_from_output "$TMPDIR/undo.out")"
assert_contains "undo activity" "$WORK/$undo_rel"
assert_contains '**Command:** `undo commit`' "$WORK/$undo_rel"
assert_contains "**Undo Type:** commit" "$WORK/$undo_rel"
pass "metadata action report details"

# 9) Copyfix reports should render durable workflow details
rc=$(run_capture "$TMPDIR/copyfix.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/report branch -q 'copyfix activity'")
[[ "$rc" -eq 0 ]] || fail "copyfix report should exit 0 (got $rc)"
copyfix_rel="$(report_path_from_output "$TMPDIR/copyfix.out")"
assert_contains "copyfix activity" "$WORK/$copyfix_rel"
assert_contains '**Command:** `copyfix fix/source-v1.0.0`' "$WORK/$copyfix_rel"
assert_contains "**Source Branch:** fix/source-v1.0.0" "$WORK/$copyfix_rel"
assert_contains "**Target Branch:** dev/report-tests-v1.0.0" "$WORK/$copyfix_rel"
assert_contains "**Commits Copied:** 2" "$WORK/$copyfix_rel"
assert_contains "**Files Modified:** 1" "$WORK/$copyfix_rel"
assert_contains "**Status:** Fix commits copied to target branch" "$WORK/$copyfix_rel"
assert_contains "**Method:** Cherry-pick created by copyfix" "$WORK/$copyfix_rel"
pass "copyfix report details"

# 10) Retarget reports should render durable workflow details
rc=$(run_capture "$TMPDIR/retarget.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/report branch -q 'retarget activity'")
[[ "$rc" -eq 0 ]] || fail "retarget report should exit 0 (got $rc)"
retarget_rel="$(report_path_from_output "$TMPDIR/retarget.out")"
assert_contains "retarget activity" "$WORK/$retarget_rel"
assert_contains '**Command:** `retarget -c move\ branch v1.1.0`' \
  "$WORK/$retarget_rel"
assert_contains "**Old Parent:** v1.0.0" "$WORK/$retarget_rel"
assert_contains "**New Parent:** v1.1.0" "$WORK/$retarget_rel"
assert_contains "**Retargeted Tip:**" "$WORK/$retarget_rel"
assert_contains "**Comment:** move branch" "$WORK/$retarget_rel"
pass "retarget report details"

# 11) TYPE may be specified only once
rc=$(run_capture "$TMPDIR/duplicate-type.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/report branch repo")
[[ "$rc" -eq 1 ]] || fail "duplicate TYPE should exit 1 (got $rc)"
assert_contains "TYPE may be specified only once" "$TMPDIR/duplicate-type.out"
pass "duplicate type rejection"

# 12) Help overrides other arguments
rc=$(run_capture "$TMPDIR/help-overrides.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/report unknown -h --bad")
[[ "$rc" -eq 0 ]] || fail "help should ignore other arguments (got $rc)"
assert_contains "Usage:" "$TMPDIR/help-overrides.out"
pass "help overrides arguments"

mkdir -p "$TMPDIR/not-a-repo"
rc=$(run_capture "$TMPDIR/repo-outside.out" bash -lc \
  "cd '$TMPDIR/not-a-repo' && bash '$WORK/briteRepo/bin/report' repo")
[[ "$rc" -eq 5 ]] || fail "report repo outside git should exit 5 (got $rc)"
assert_contains "local branch or remote copy as the current branch" \
  "$TMPDIR/repo-outside.out"
rc=$(run_capture "$TMPDIR/branch-outside.out" bash -lc \
  "cd '$TMPDIR/not-a-repo' && bash '$WORK/briteRepo/bin/report' branch")
[[ "$rc" -eq 5 ]] || fail "report branch outside git should exit 5 (got $rc)"
assert_contains "local branch or remote copy as the current branch" \
  "$TMPDIR/branch-outside.out"
pass "outside repository exit"

# 13) Repo reports include repository health and delegated branch status
rc=$(run_capture "$TMPDIR/repo.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/report repo -t 2")
[[ "$rc" -eq 0 ]] || fail "repo report should exit 0 (got $rc)"
repo_rel="$(sed -n "s/^See '\(reports\/repo-[^ ]*\.md\)'\.$/\1/p" \
  "$TMPDIR/repo.out" | tail -n 1)"
[[ -n "$repo_rel" && -f "$WORK/$repo_rel" ]] || fail "repo report file was not created"
assert_contains "## Health" "$WORK/$repo_rel"
assert_contains "## Branch Status" "$WORK/$repo_rel"
pass "repository report dispatch"

# 13b) Repo reports accept filtered activity and render a repo activity section
rc=$(run_capture "$TMPDIR/repo-activity.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/report repo -q 'pull activity' -u testuser -l 1 -t 2")
[[ "$rc" -eq 0 ]] || fail "filtered repo report should exit 0 (got $rc)"
repo_activity_rel="$(sed -n "s/^See '\(reports\/repo-[^ ]*\.md\)'\.$/\1/p" \
  "$TMPDIR/repo-activity.out" | tail -n 1)"
[[ -n "$repo_activity_rel" && -f "$WORK/$repo_activity_rel" ]] || fail "filtered repo report file was not created"
assert_contains "## Repository Activity" "$WORK/$repo_activity_rel"
assert_contains "pull activity" "$WORK/$repo_activity_rel"
assert_contains "**User:** testuser" "$WORK/$repo_activity_rel"
pass "repository report activity filtering"

# 14) Style options and files are forwarded to ckstyle
rc=$(run_capture "$TMPDIR/style.out" bash -lc \
  "cd '$WORK' && bash ./briteRepo/bin/report -m -f README.md -v style")
[[ "$rc" -eq 0 ]] || fail "style report should exit 0 (got $rc)"
assert_contains "-m" "$WORK/style-args.txt"
assert_contains "README.md" "$WORK/style-args.txt"
assert_contains "-v" "$WORK/style-args.txt"
pass "style report dispatch"

echo "All report core smoke tests passed."
