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
  find "$repo_root/reports/branch" -maxdepth 1 -type f -name 'commit-*.md' -printf '%T@ %p\n' | sort -n | tail -n 1 | cut -d' ' -f2-
}

report_path_from_output() {
  local out_file="$1"
  local rel

  rel="$(grep -Eo 'reports/branch/commit-[0-9]{8}-[0-9]{6}(-[0-9]+)?\.md' "$out_file" | tail -n 1 || true)"
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

# 2) Positional argument should be rejected
rc=$(run_capture "$TMPDIR/arg-reject.out" bash -lc "cd '$WORK' && bash ./scripts/bin/mrgdown unexpected")
[[ "$rc" -eq 1 ]] || fail "positional argument should exit 1 (got $rc)"
assert_contains "Unknown argument: unexpected" "$TMPDIR/arg-reject.out"
pass "positional argument rejected"

# 3) Protected branch is blocked
rc=$(run_capture "$TMPDIR/protected.out" bash -lc "cd '$WORK' && git checkout main >/dev/null 2>&1 && bash ./scripts/bin/mrgdown -f")
[[ "$rc" -eq 4 ]] || fail "protected branch should exit 4 (got $rc)"
assert_contains "Cannot sync up on protected branch 'main'" "$TMPDIR/protected.out"
pass "protected branch gate"

# 4) Force merge/push creates a commit report and copies it to remote
(
  cd "$PEER"
  git checkout v1.0.0 >/dev/null 2>&1
  git pull --ff-only origin v1.0.0 >/dev/null 2>&1
  echo "parent change 1" > parent-change-1.txt
  git add parent-change-1.txt
  git commit -m "parent change one" >/dev/null 2>&1
  git push origin v1.0.0 >/dev/null 2>&1
)

rc=$(run_capture "$TMPDIR/merge-push.out" bash -lc "cd '$WORK' && git checkout dev/current-v1.0.0 >/dev/null 2>&1 && bash ./scripts/bin/mrgdown -f -m 'sync parent one'")
[[ "$rc" -eq 0 ]] || fail "forced merge/push should exit 0 (got $rc)"
assert_contains "Merge successful" "$TMPDIR/merge-push.out"
assert_contains "Pushed merge commit" "$TMPDIR/merge-push.out"
report_rel="$(report_path_from_output "$TMPDIR/merge-push.out")"
[[ -n "$report_rel" ]] || fail "expected report path in output"
report_path="$WORK/$report_rel"
[[ -f "$report_path" ]] || fail "expected report file: $report_path"
assert_contains "# Commit Report" "$report_path"
assert_contains "**Commit Comment:** sync parent one" "$report_path"
assert_contains "**Pushed Commit Hash:**" "$report_path"
assert_contains "| dev/current-v1.0.0 | v1.0.0 |" "$report_path"
[[ ! -w "$report_path" ]] || fail "expected report to be read-only"

remote_report_count="$(find "$ORIGIN/reports/branch" -maxdepth 1 -type f -name 'commit-*.md' | wc -l | tr -d ' ')"
[[ "$remote_report_count" -ge 1 ]] || fail "expected commit report copied to remote reports/branch"
pass "force merge/push report + remote copy"

# 5) Merge with push skipped still creates report and marks as selected-for-push
# Ensure the next mrgdown run uses a distinct second-based report timestamp.
ts_before="$(date +%s)"
while [[ "$(date +%s)" == "$ts_before" ]]; do
  :
done

(
  cd "$PEER"
  git checkout v1.0.0 >/dev/null 2>&1
  git pull --ff-only origin v1.0.0 >/dev/null 2>&1
  echo "parent change 2" > parent-change-2.txt
  git add parent-change-2.txt
  git commit -m "parent change two" >/dev/null 2>&1
  git push origin v1.0.0 >/dev/null 2>&1
)

rc=$(run_capture "$TMPDIR/merge-skip-push.out" bash -lc "cd '$WORK' && git checkout dev/current-v1.0.0 >/dev/null 2>&1 && printf 'y\nn\n' | bash ./scripts/bin/mrgdown -m 'sync parent two'")
[[ "$rc" -eq 0 ]] || fail "merge with push skipped should exit 0 (got $rc)"
assert_contains "Push skipped - merge committed locally" "$TMPDIR/merge-skip-push.out"
report_rel="$(report_path_from_output "$TMPDIR/merge-skip-push.out")"
[[ -n "$report_rel" ]] || fail "expected report path in output when push is skipped"
report_path="$WORK/$report_rel"
[[ -f "$report_path" ]] || fail "expected report file when push skipped: $report_path"
assert_contains "**Commit Comment:** sync parent two" "$report_path"
assert_contains "**Commit Selected for Push Hash:**" "$report_path"
if grep -q '^\*\*Pushed Commit Hash:\*\*' "$report_path"; then
  fail "push-skipped report should not use pushed-commit label"
fi
[[ ! -w "$report_path" ]] || fail "expected push-skipped report to be read-only"
pass "merge with push skipped report semantics"

echo "All mrgdown smoke tests passed."
