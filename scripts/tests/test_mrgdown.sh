#!/usr/bin/env bash

# test_mrgdown.sh - smoke tests for scripts/bin/mrgdown
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MRGDOWN_SRC="$REPO_ROOT/scripts/bin/mrgdown"
COMMON_HELPER_SRC="$REPO_ROOT/scripts/helpers/common.sh"
GIT_HELPER_SRC="$REPO_ROOT/scripts/helpers/git_helpers.sh"
HISTORY_HELPER_SRC="$REPO_ROOT/scripts/helpers/history_log.sh"
REPORT_HELPER_SRC="$REPO_ROOT/scripts/helpers/report_helpers.sh"
REPORT_SYNC_HELPER_SRC="$REPO_ROOT/scripts/helpers/report_sync.sh"

pass() {
  echo "PASS: $1"
}

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

run_capture() {
  # Usage: run_capture <outfile> <command...>
  local outfile="$1"
  shift
  set +e
  "$@" >"$outfile" 2>&1
  local rc=$?
  set -e
  echo "$rc"
}

assert_contains() {
  local text="$1"
  local file="$2"
  grep -Fq -- "$text" "$file" || fail "expected '$text' in $file"
}

latest_report() {
  local repo_root="$1"
  find "$repo_root/reports/branch" -maxdepth 1 -type f -name 'mrgdown-*.md' -printf '%T@ %p\n' | sort -n | tail -n 1 | cut -d' ' -f2-
}

report_path_from_output() {
  local out_file="$1"
  local rel

  rel="$(grep -Eo 'reports/branch/mrgdown-[0-9]{8}-[0-9]{6}(-[0-9]+)?\.md' "$out_file" | tail -n 1 || true)"
  [[ -n "$rel" ]] || return 1
  printf '%s\n' "$rel"
}

for dep in bash find git grep mktemp; do
  command -v "$dep" >/dev/null 2>&1 || fail "missing required command: $dep"
done

[[ -f "$MRGDOWN_SRC" ]] || fail "missing script: $MRGDOWN_SRC"
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
mkdir -p "$ORIGIN/reports/branch"

git clone "file://$ORIGIN" "$WORK" >/dev/null 2>&1
git clone "file://$ORIGIN" "$PEER" >/dev/null 2>&1

mkdir -p "$WORK/scripts/bin" "$WORK/scripts/helpers" "$WORK/reports/branch"
cp "$MRGDOWN_SRC" "$WORK/scripts/bin/mrgdown"
cp "$COMMON_HELPER_SRC" "$WORK/scripts/helpers/common.sh"
cp "$GIT_HELPER_SRC" "$WORK/scripts/helpers/git_helpers.sh"
cp "$HISTORY_HELPER_SRC" "$WORK/scripts/helpers/history_log.sh"
cp "$REPORT_HELPER_SRC" "$WORK/scripts/helpers/report_helpers.sh"
cp "$REPORT_SYNC_HELPER_SRC" "$WORK/scripts/helpers/report_sync.sh"
chmod +x "$WORK/scripts/bin/mrgdown"

(
  cd "$WORK"
  git config user.name "testuser"
  git config user.email "test@example.com"

  echo "seed" > README.md
  cat > .gitignore <<'GITIGNORE'
reports/branch/branch-*.md
reports/branch/commit-*.md
reports/branch/mrgdown-*.md
reports/branch/mrgbranch-*.md
GITIGNORE
  git add README.md scripts reports .gitignore
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
rc=$(run_capture "$TMPDIR/help.out" bash -lc "cd '$WORK' && bash ./scripts/bin/mrgdown -h")
[[ "$rc" -eq 0 ]] || fail "mrgdown -h should exit 0"
assert_contains "Usage:" "$TMPDIR/help.out"
pass "help output"

# 2) Skip mode should emit an error report and summary line.
rc=$(run_capture "$TMPDIR/skip-e.out" bash -lc "cd '$WORK' && git checkout dev/current-v1.0.0 >/dev/null 2>&1 && bash ./scripts/bin/mrgdown -e")
[[ "$rc" -eq 6 ]] || fail "mrgdown -e should exit 6 (got $rc)"
assert_contains "Error: Merge down skipped due to -e option." "$TMPDIR/skip-e.out"
assert_contains "Guidance: Run without -e option." "$TMPDIR/skip-e.out"
assert_contains "See reports/branch/mrgdown-e-" "$TMPDIR/skip-e.out"
skip_report="$(latest_report "$WORK")"
[[ -f "$skip_report" ]] || fail "expected mrgdown skip report"
assert_contains "**Error:** Merge down skipped due to -e option." "$skip_report"
assert_contains "## Guidance" "$skip_report"
assert_contains "- Run without -e option." "$skip_report"
pass "skip mode"

# 3) Positional argument should be rejected
rc=$(run_capture "$TMPDIR/arg-reject.out" bash -lc "cd '$WORK' && bash ./scripts/bin/mrgdown unexpected")
[[ "$rc" -eq 1 ]] || fail "positional argument should exit 1 (got $rc)"
assert_contains "Unknown argument: unexpected" "$TMPDIR/arg-reject.out"
pass "positional argument rejected"

# Nothing to merge down should not create a report.
cat > "$WORK/reports/branch/mrgdown-d-20000101-000000.md" <<'EOF'
# Stale Merge-Down Report

**Branch:** `dev/current-v1.0.0`
EOF
cat > "$WORK/reports/branch/mrgdown-e-20000101-000001.md" <<'EOF'
# Stale Merge-Down Error Report

**Branch:** `dev/current-v1.0.0`
EOF
chmod a-w "$WORK/reports/branch/mrgdown-d-20000101-000000.md" \
  "$WORK/reports/branch/mrgdown-e-20000101-000001.md"
rc=$(run_capture "$TMPDIR/noop.out" \
  bash -lc "cd '$WORK' && git checkout dev/current-v1.0.0 >/dev/null 2>&1 && bash ./scripts/bin/mrgdown -f")
[[ "$rc" -eq 0 ]] || fail "no-op mrgdown should exit 0 (got $rc)"
assert_contains "no changes to merge" "$TMPDIR/noop.out"
[[ -z "$(find "$WORK/reports/branch" -maxdepth 1 -type f -name 'mrgdown-*.md' -print -quit)" ]] || \
  fail "no-op mrgdown should not create a report"
pass "no-op mrgdown cleans transient reports and creates no report"

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
rc=$(run_capture "$TMPDIR/dryrun.out" bash -lc "cd '$WORK' && git checkout dev/current-v1.0.0 >/dev/null 2>&1 && bash ./scripts/bin/mrgdown -d")
[[ "$rc" -eq 0 ]] || fail "dry-run mrgdown should exit 0 (got $rc)"
assert_contains "Dry-run: merge v1.0.0 -> dev/current-v1.0.0" "$TMPDIR/dryrun.out"
assert_contains "See reports/branch/mrgdown-d-" "$TMPDIR/dryrun.out"
pass "dry-run output stays compact"

# 4) Protected branch is blocked
rc=$(run_capture "$TMPDIR/protected.out" bash -lc "cd '$WORK' && git checkout main >/dev/null 2>&1 && bash ./scripts/bin/mrgdown -f")
[[ "$rc" -eq 4 ]] || fail "protected branch should exit 4 (got $rc)"
assert_contains "Error: Cannot sync up on protected branch 'main'" "$TMPDIR/protected.out"
assert_contains "Guidance: use mrgup to merge changes to this branch." "$TMPDIR/protected.out"
pass "protected branch gate"

# 5) Force merge creates a local report
remote_report_count_before="$(find "$ORIGIN/reports/branch" -maxdepth 1 -type f -name 'commit-*.md' | wc -l | tr -d ' ')"
(
  cd "$PEER"
  git checkout v1.0.0 >/dev/null 2>&1
  git pull --ff-only origin v1.0.0 >/dev/null 2>&1
  echo "parent change 1" > parent-change-1.txt
  git add parent-change-1.txt
  git commit -m "parent change one" >/dev/null 2>&1
  git push origin v1.0.0 >/dev/null 2>&1
)

rc=$(run_capture "$TMPDIR/merge-push.out" bash -lc "cd '$WORK' && git checkout dev/current-v1.0.0 >/dev/null 2>&1 && bash ./scripts/bin/mrgdown -f -c 'sync parent one'")
[[ "$rc" -eq 0 ]] || fail "forced merge/push should exit 0 (got $rc)"
assert_contains "Merge successful" "$TMPDIR/merge-push.out"
assert_contains "Merge down complete" "$TMPDIR/merge-push.out"
report_rel="$(report_path_from_output "$TMPDIR/merge-push.out")"
[[ -n "$report_rel" ]] || fail "expected report path in output"
report_path="$WORK/$report_rel"
[[ -f "$report_path" ]] || fail "expected report file: $report_path"
assert_contains "# Merge Report" "$report_path"
assert_contains "**Merge Comment:** sync parent one" "$report_path"
assert_contains "**Merge Commit Hash:**" "$report_path"
assert_contains "| dev/current-v1.0.0 | v1.0.0 |" "$report_path"
[[ -w "$report_path" ]] || fail "expected report to remain writable"

remote_report_count="$(find "$ORIGIN/reports/branch" -maxdepth 1 -type f -name 'commit-*.md' | wc -l | tr -d ' ')"
[[ "$remote_report_count" -eq "$remote_report_count_before" ]] || fail "expected no remote report copy"
pass "force merge report stays local"

# 6) Merge still creates a uniquely named report on a second run.
(
  cd "$PEER"
  git checkout v1.0.0 >/dev/null 2>&1
  git pull --ff-only origin v1.0.0 >/dev/null 2>&1
  echo "parent change 2" > parent-change-2.txt
  git add parent-change-2.txt
  git commit -m "parent change two" >/dev/null 2>&1
  git push origin v1.0.0 >/dev/null 2>&1
)

rc=$(run_capture "$TMPDIR/merge-skip-push.out" bash -lc "cd '$WORK' && git checkout dev/current-v1.0.0 >/dev/null 2>&1 && printf 'y\nn\n' | bash ./scripts/bin/mrgdown -c 'sync parent two'")
[[ "$rc" -eq 0 ]] || fail "merge with push skipped should exit 0 (got $rc)"
assert_contains "Merge successful" "$TMPDIR/merge-skip-push.out"
report_rel="$(report_path_from_output "$TMPDIR/merge-skip-push.out")"
[[ -n "$report_rel" ]] || fail "expected report path in output when push is skipped"
report_path="$WORK/$report_rel"
[[ -f "$report_path" ]] || fail "expected report file when push skipped: $report_path"
assert_contains "# Merge Report" "$report_path"
assert_contains "**Merge Comment:** sync parent two" "$report_path"
assert_contains "**Merge Commit Hash:**" "$report_path"
if grep -q '^\*\*Commit Comment:\*\*' "$report_path"; then
  fail "merge report should not use commit-comment label"
fi
[[ -w "$report_path" ]] || fail "expected push-skipped report to remain writable"
pass "merge report semantics"

# 7) Whitespace-only comments should be rejected.
rc=$(run_capture "$TMPDIR/empty-comment.out" bash -lc "cd '$WORK' && git checkout dev/current-v1.0.0 >/dev/null 2>&1 && bash ./scripts/bin/mrgdown -c '   '")
[[ "$rc" -eq 1 ]] || fail "whitespace-only comment should exit 1 (got $rc)"
assert_contains "Commit comment must include at least one non-whitespace character" "$TMPDIR/empty-comment.out"
pass "whitespace-only merge comments are rejected"

echo "All mrgdown smoke tests passed."
