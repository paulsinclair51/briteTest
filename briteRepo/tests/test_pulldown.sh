#!/usr/bin/env bash

# test_pulldown.sh - smoke tests for briteRepo/bin/pulldown
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common_test_helpers.sh
source "$SCRIPT_DIR/common_test_helpers.sh"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PULLDOWN_SRC="$REPO_ROOT/briteRepo/bin/pulldown"
COMMON_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/common.sh"
GIT_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/git_helpers.sh"
HISTORY_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/history_log.sh"
REPORT_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/report_helpers.sh"
REPORT_SYNC_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/report_sync.sh"

latest_report() {
  local repo_root="$1"
  find "$repo_root/reports" -maxdepth 1 -type f -name 'pulldown-*.md' -printf '%T@ %p\n' | sort -n | tail -n 1 | cut -d' ' -f2-
}

report_path_from_output() {
  local out_file="$1"
  local rel

  rel="$(grep -Eo 'reports/pulldown-[0-9]{8}-[0-9]{6}[+-][0-9]{4}(-[0-9]+)?\.md' "$out_file" | tail -n 1 || true)"
  [[ -n "$rel" ]] || return 1
  printf '%s\n' "$rel"
}

for dep in bash find git grep mktemp; do
  command -v "$dep" >/dev/null 2>&1 || fail "missing required command: $dep"
done

[[ -f "$PULLDOWN_SRC" ]] || fail "missing script: $PULLDOWN_SRC"
[[ -f "$COMMON_HELPER_SRC" ]] || fail "missing helper: $COMMON_HELPER_SRC"
[[ -f "$GIT_HELPER_SRC" ]] || fail "missing helper: $GIT_HELPER_SRC"
[[ -f "$HISTORY_HELPER_SRC" ]] || fail "missing helper: $HISTORY_HELPER_SRC"
[[ -f "$REPORT_HELPER_SRC" ]] || fail "missing helper: $REPORT_HELPER_SRC"
[[ -f "$REPORT_SYNC_HELPER_SRC" ]] || fail "missing helper: $REPORT_SYNC_HELPER_SRC"

TMPDIR="$(mktemp -d)"
cleanup() {
  if [[ "${KEEP_TMPDIR:-0}" == "1" ]]; then
    echo "KEEP_TMPDIR=1 preserving test artifacts at: $TMPDIR" >&2
    return 0
  fi
  chmod -R u+w "$TMPDIR" 2>/dev/null || true
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

ORIGIN="$TMPDIR/origin.git"
WORK="$TMPDIR/work"
PEER="$TMPDIR/peer"

git init --bare "$ORIGIN" >/dev/null 2>&1
mkdir -p "$ORIGIN/reports"

git clone "file://$ORIGIN" "$WORK" >/dev/null 2>&1
git clone "file://$ORIGIN" "$PEER" >/dev/null 2>&1

mkdir -p "$WORK/briteRepo/bin" "$WORK/briteRepo/helpers" "$WORK/reports"
cp "$PULLDOWN_SRC" "$WORK/briteRepo/bin/pulldown"
cp "$COMMON_HELPER_SRC" "$WORK/briteRepo/helpers/common.sh"
cp "$GIT_HELPER_SRC" "$WORK/briteRepo/helpers/git_helpers.sh"
cp "$HISTORY_HELPER_SRC" "$WORK/briteRepo/helpers/history_log.sh"
cp "$REPORT_HELPER_SRC" "$WORK/briteRepo/helpers/report_helpers.sh"
cp "$REPORT_SYNC_HELPER_SRC" "$WORK/briteRepo/helpers/report_sync.sh"
chmod +x "$WORK/briteRepo/bin/pulldown"

(
  cd "$WORK"
  git config user.name "testuser"
  git config user.email "test@example.com"

  echo "seed" > README.md
  cat > .gitignore <<'GITIGNORE'
reports/branch-*.md
reports/commit-*.md
reports/pulldown-*.md
reports/mrgbranch-*.md
GITIGNORE
  git add README.md briteRepo reports .gitignore
  git commit -m "seed repo" >/dev/null 2>&1
  git branch -M main
  git push -u origin main >/dev/null 2>&1

  git checkout -b v1.0.0 >/dev/null 2>&1
  git commit --allow-empty -m "create version branch" >/dev/null 2>&1
  git push -u origin v1.0.0 >/dev/null 2>&1

  git checkout -b dev/current-v1.0.0 >/dev/null 2>&1
  git commit --allow-empty -m "create dev branch" >/dev/null 2>&1
  git push -u origin dev/current-v1.0.0 >/dev/null 2>&1
)

(
  cd "$PEER"
  git config user.name "peeruser"
  git config user.email "peer@example.com"
  git fetch origin >/dev/null 2>&1
  git checkout v1.0.0 >/dev/null 2>&1
)

# 1) Help output
rc=$(run_capture "$TMPDIR/help.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/pulldown -h")
[[ "$rc" -eq 0 ]] || fail "pulldown -h should exit 0"
assert_contains "Usage:" "$TMPDIR/help.out"
assert_contains "-e" "$TMPDIR/help.out"
pass "help output"

copyfix_state_root="$(git -C "$WORK" rev-parse \
  --path-format=absolute --git-common-dir)/briteRepo-copyfix-state"
mkdir -p "$copyfix_state_root/dev/current-v1.0.0"
rc=$(run_capture "$TMPDIR/copyfix-active.out" \
  bash -lc "cd '$WORK' && git checkout dev/current-v1.0.0 >/dev/null 2>&1 && bash ./briteRepo/bin/pulldown -f")
[[ "$rc" -eq 3 ]] || fail "unfinished copyfix should block pulldown (got $rc)"
assert_contains "has an unfinished copyfix operation" \
  "$TMPDIR/copyfix-active.out"
rm -rf "$copyfix_state_root"
pass "unfinished copyfix blocks pulldown"

# 2) Skip mode should emit an error report and summary line.
rc=$(run_capture "$TMPDIR/skip-e.out" bash -lc "cd '$WORK' && git checkout dev/current-v1.0.0 >/dev/null 2>&1 && bash ./briteRepo/bin/pulldown -e")
[[ "$rc" -eq 6 ]] || fail "pulldown -e should exit 6 (got $rc)"
assert_contains "Error: Merge down skipped due to -e option." "$TMPDIR/skip-e.out"
assert_contains "Guidance: Run without -e option." "$TMPDIR/skip-e.out"
assert_contains "See reports/pulldown-e-" "$TMPDIR/skip-e.out"
skip_report="$(latest_report "$WORK")"
[[ -f "$skip_report" ]] || fail "expected pulldown skip report"
assert_contains "**Error:** Merge down skipped due to -e option." "$skip_report"
assert_contains "## Guidance" "$skip_report"
assert_contains "- Run without -e option." "$skip_report"
pass "skip mode"

# 3) Positional argument should be rejected
rc=$(run_capture "$TMPDIR/arg-reject.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/pulldown unexpected")
[[ "$rc" -eq 1 ]] || fail "positional argument should exit 1 (got $rc)"
assert_contains "Unknown argument: unexpected" "$TMPDIR/arg-reject.out"
pass "positional argument rejected"

# Nothing to merge down should not create a report.
cat > "$WORK/reports/pulldown-d-20000101-000000+0000.md" <<'EOF'
# Stale Merge-Down Report

**Branch:** `dev/current-v1.0.0`
EOF
cat > "$WORK/reports/pulldown-e-20000101-000001+0000.md" <<'EOF'
# Stale Merge-Down Error Report

**Branch:** `dev/current-v1.0.0`
EOF
chmod a-w "$WORK/reports/pulldown-d-20000101-000000+0000.md" \
  "$WORK/reports/pulldown-e-20000101-000001+0000.md"
rc=$(run_capture "$TMPDIR/noop.out" \
  bash -lc "cd '$WORK' && git checkout dev/current-v1.0.0 >/dev/null 2>&1 && bash ./briteRepo/bin/pulldown -f")
[[ "$rc" -eq 5 ]] || fail "no-work pulldown should exit 5 (got $rc)"
assert_contains "no changes to merge" "$TMPDIR/noop.out"
[[ -f "$WORK/reports/pulldown-d-20000101-000000+0000.md" ]] || \
  fail "pulldown prerequisite failure should preserve stale dry-run report"
[[ -f "$WORK/reports/pulldown-e-20000101-000001+0000.md" ]] || \
  fail "pulldown prerequisite failure should preserve stale error report"
pass "no-work pulldown prerequisite"

# 3) Dry-run output stays compact and reports the merge preview
(
  cd "$PEER"
  git checkout v1.0.0 >/dev/null 2>&1
  git pull --ff-only origin v1.0.0 >/dev/null 2>&1
  echo "parent change dry" > parent-change-dry.txt
  git add parent-change-dry.txt
  git commit -m "parent change dry" >/dev/null 2>&1
  git push origin v1.0.0 >/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/dryrun.out" bash -lc "cd '$WORK' && git checkout dev/current-v1.0.0 >/dev/null 2>&1 && bash ./briteRepo/bin/pulldown -d")
[[ "$rc" -eq 0 ]] || fail "dry-run pulldown should exit 0 (got $rc)"
assert_contains "Dry-run: merge v1.0.0 -> dev/current-v1.0.0" "$TMPDIR/dryrun.out"
assert_contains "See reports/pulldown-d-" "$TMPDIR/dryrun.out"
pass "dry-run output stays compact"

# 4) Protected branch is blocked
rc=$(run_capture "$TMPDIR/protected.out" bash -lc "cd '$WORK' && git checkout main >/dev/null 2>&1 && bash ./briteRepo/bin/pulldown -f")
[[ "$rc" -eq 4 ]] || fail "protected branch should exit 4 (got $rc)"
assert_contains "Error: Cannot sync up on protected branch 'main'" "$TMPDIR/protected.out"
assert_contains "Guidance: use pushup to merge changes to this branch." "$TMPDIR/protected.out"
pass "protected branch gate"

# pushup alone may merge a published parent into its protected source branch.
rc=$(run_capture "$TMPDIR/protected-pushup.out" bash -lc "cd '$WORK' && git checkout v1.0.0 >/dev/null 2>&1 && bash ./briteRepo/bin/pulldown --pushup -f")
[[ "$rc" -eq 4 ]] || fail "unvalidated pushup mode should remain blocked (got $rc)"
(
  cd "$PEER"
  git checkout main >/dev/null 2>&1
  echo "parent change for protected source" > parent-protected-source.txt
  git add parent-protected-source.txt
  git commit -m "parent change for protected source" >/dev/null 2>&1
  git push origin main >/dev/null 2>&1
)
(
  cd "$WORK"
  git checkout v1.0.0 >/dev/null 2>&1
  mkdir -p .git/briteRepo
  git config --file .git/briteRepo/pushup.state pushup.version 1
  git config --file .git/briteRepo/pushup.state pushup.source v1.0.0
  git config --file .git/briteRepo/pushup.state pushup.parent main
  git config --file .git/briteRepo/pushup.state pushup.phase source-selected
)
rc=$(run_capture "$TMPDIR/protected-pushup-sync.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/pulldown --pushup -f")
[[ "$rc" -eq 0 ]] || fail "validated pushup source sync should succeed (got $rc)"
rm -f "$WORK/.git/briteRepo/pushup.state"
pass "pushup can synchronize protected source branch"

# 5) Force merge records report history without creating an immediate report
remote_report_count_before="$(find "$ORIGIN/reports" -maxdepth 1 -type f -name 'commit-*.md' | wc -l | tr -d ' ')"
(
  cd "$PEER"
  git checkout v1.0.0 >/dev/null 2>&1
  git pull --ff-only origin v1.0.0 >/dev/null 2>&1
  echo "parent change 1" > parent-change-1.txt
  git add parent-change-1.txt
  git commit -m "parent change one" >/dev/null 2>&1
  git push origin v1.0.0 >/dev/null 2>&1
)

reports_before="$(find "$WORK/reports" -maxdepth 1 -type f \
  -name 'pulldown-[0-9]*.md' -print | sort)"
rc=$(run_capture "$TMPDIR/merge-push.out" bash -lc "cd '$WORK' && git checkout dev/current-v1.0.0 >/dev/null 2>&1 && bash ./briteRepo/bin/pulldown -f -c 'sync parent one'")
[[ "$rc" -eq 0 ]] || fail "forced merge/push should exit 0 (got $rc)"
assert_contains "Merged parent 'v1.0.0' into 'dev/current-v1.0.0'" \
  "$TMPDIR/merge-push.out"
assert_contains "Run report for details." "$TMPDIR/merge-push.out"
if grep -Eq 'Create merge commit|Merge successful|Merge down complete' \
  "$TMPDIR/merge-push.out"; then
  fail "normal pulldown output should be concise and non-interactive"
fi
reports_after="$(find "$WORK/reports" -maxdepth 1 -type f \
  -name 'pulldown-[0-9]*.md' -print | sort)"
[[ "$reports_after" == "$reports_before" ]] || \
  fail "successful merge-down should not add an immediate report"
merge_body="$(git -C "$WORK" log -1 --format=%B dev/current-v1.0.0)"
[[ "$merge_body" == *'Command-Line: pulldown -f -c sync\ parent\ one'* ]] || \
  fail "merge-down commit should record its command line"
[[ "$merge_body" == *"Source-Branch: v1.0.0"* ]] || \
  fail "merge-down commit should record its source branch"
[[ "$merge_body" == *"Target-Branch: dev/current-v1.0.0"* ]] || \
  fail "merge-down commit should record its target branch"
if ! grep -Eq '^Parent-Commits-Integrated: [1-9][0-9]*$' <<< "$merge_body"; then
  fail "merge-down commit should record a positive integrated commit count"
fi
for count_field in Files-Modified Files-Added Files-Deleted; do
  if ! grep -Eq "^${count_field}: [0-9]+$" <<< "$merge_body"; then
    fail "merge-down commit should record numeric $count_field"
  fi
done
if grep -Eq '^Files-(Modified|Added|Deleted): [1-9][0-9]*$' \
  <<< "$merge_body"; then
  :
else
  fail "merge-down commit should record at least one changed file"
fi
[[ "$merge_body" == *"Status: Parent branch merged into current branch"* ]] || \
  fail "merge-down commit should record merge status"
[[ "$merge_body" == *"Method: Merge commit (--no-ff) created by pulldown"* ]] || \
  fail "merge-down commit should record merge method"

remote_report_count="$(find "$ORIGIN/reports" -maxdepth 1 -type f -name 'commit-*.md' | wc -l | tr -d ' ')"
[[ "$remote_report_count" -eq "$remote_report_count_before" ]] || fail "expected no remote report copy"
pass "force merge records report history"

# 6) A second merge also defers reporting.
(
  cd "$PEER"
  git checkout v1.0.0 >/dev/null 2>&1
  git pull --ff-only origin v1.0.0 >/dev/null 2>&1
  echo "parent change 2" > parent-change-2.txt
  git add parent-change-2.txt
  git commit -m "parent change two" >/dev/null 2>&1
  git push origin v1.0.0 >/dev/null 2>&1
)

reports_before="$(find "$WORK/reports" -maxdepth 1 -type f \
  -name 'pulldown-[0-9]*.md' -print | sort)"
rc=$(run_capture "$TMPDIR/merge-skip-push.out" bash -lc "cd '$WORK' && git checkout dev/current-v1.0.0 >/dev/null 2>&1 && bash ./briteRepo/bin/pulldown -c 'sync parent two'")
[[ "$rc" -eq 0 ]] || fail "merge with push skipped should exit 0 (got $rc)"
assert_contains "Merged parent 'v1.0.0' into 'dev/current-v1.0.0'" \
  "$TMPDIR/merge-skip-push.out"
assert_contains "Run report for details." "$TMPDIR/merge-skip-push.out"
reports_after="$(find "$WORK/reports" -maxdepth 1 -type f \
  -name 'pulldown-[0-9]*.md' -print | sort)"
[[ "$reports_after" == "$reports_before" ]] || \
  fail "second merge-down should not add an immediate report"
pass "merge reporting is deferred"

# 7) Whitespace-only comments should be rejected.
rc=$(run_capture "$TMPDIR/empty-comment.out" bash -lc "cd '$WORK' && git checkout dev/current-v1.0.0 >/dev/null 2>&1 && bash ./briteRepo/bin/pulldown -c '   '")
[[ "$rc" -eq 1 ]] || fail "whitespace-only comment should exit 1 (got $rc)"
assert_contains "Commit comment must include at least one non-whitespace character" "$TMPDIR/empty-comment.out"
pass "whitespace-only merge comments are rejected"

echo "All pulldown smoke tests passed."
