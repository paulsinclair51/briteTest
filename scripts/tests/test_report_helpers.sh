#!/usr/bin/env bash

# test_report_helpers.sh - focused tests for shared report lifecycle helpers.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPORT_HELPER_SRC="$REPO_ROOT/scripts/helpers/report_helpers.sh"

pass() {
  echo "PASS: $1"
}

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

run_capture() {
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

for dep in bash git grep mktemp; do
  command -v "$dep" >/dev/null 2>&1 || fail "missing required command: $dep"
done

[[ -f "$REPORT_HELPER_SRC" ]] || fail "missing helper: $REPORT_HELPER_SRC"

# shellcheck source=scripts/helpers/common.sh
source "$REPO_ROOT/scripts/helpers/common.sh"
# shellcheck source=scripts/helpers/report_helpers.sh
source "$REPORT_HELPER_SRC"

TMPDIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

seed_repo() {
  local repo="$1"

  git init "$repo" >/dev/null 2>&1
  (
    cd "$repo"
    git config user.name "testuser"
    git config user.email "test@example.com"
    mkdir -p reports/branch
    echo "seed" > README.md
    git add README.md reports
    git commit -m "seed repo" >/dev/null 2>&1
  )
}

# 1) Deletion tracking should record the exact relative path.
DELETE_REPO="$TMPDIR/delete-repo"
seed_repo "$DELETE_REPO"
echo "obsolete report" > "$DELETE_REPO/reports/branch/old-report.md"
deleted_reports=()
bt_report_remove_and_record \
  "$DELETE_REPO" deleted_reports \
  "$DELETE_REPO/reports/branch/old-report.md" "test report"
[[ ! -e "$DELETE_REPO/reports/branch/old-report.md" ]] || \
  fail "old report should be deleted"
[[ "${#deleted_reports[@]}" -eq 1 ]] || \
  fail "expected one deleted report path to be recorded"
[[ "${deleted_reports[0]}" == "reports/branch/old-report.md" ]] || \
  fail "expected recorded deleted report path to be relative"
pass "delete-and-record helper"

# 2) Shared formatting helpers should behave consistently.
[[ "$(bt_ensure_trailing_period "Hello")" == "Hello." ]] || \
  fail "expected trailing period helper to append a period"
[[ "$(bt_ensure_trailing_period "Hello.")" == "Hello." ]] || \
  fail "expected trailing period helper to preserve an existing period"
[[ "$(bt_format_command_line "mrgdown" "-v" "two words")" == "mrgdown -v two\ words" ]] || \
  fail "expected command-line formatter to shell-escape arguments"
[[ "$(bt_trim_whitespace "  keep this  ")" == "keep this" ]] || \
  fail "expected whitespace trimming helper to normalize surrounding whitespace"

# 3) Shared transient report cleanup should remove only matching branch reports.
cleanup_repo="$TMPDIR/cleanup-repo"
seed_repo "$cleanup_repo"
mkdir -p "$cleanup_repo/reports/branch"
cat > "$cleanup_repo/reports/branch/keep.md" <<'EOF'
# Keep Report

**Branch:** `feature/other`
EOF
cat > "$cleanup_repo/reports/branch/remove.md" <<'EOF'
# Remove Report

**Branch:** `feature/current`
EOF
cat > "$cleanup_repo/reports/branch/source-remove.md" <<'EOF'
# Remove Report

**Source Branch:** `feature/current`
EOF
bt_report_cleanup_transient_reports \
  "$cleanup_repo/reports/branch" \
  "feature/current" \
  "$cleanup_repo/reports/branch/keep.md" \
  "remove.md" "source-remove.md"
[[ -f "$cleanup_repo/reports/branch/keep.md" ]] || fail "expected non-matching report to remain"
[[ -f "$cleanup_repo/reports/branch/remove.md" ]] && fail "expected branch-matching report to be removed"
[[ -f "$cleanup_repo/reports/branch/source-remove.md" ]] && fail "expected source-branch-matching report to be removed"

# 4) Shared report names include process identity, and locks serialize writers.
unique_path="$(bt_report_unique_path "/tmp/reports" "push-d" "20260802-120000" "12345")"
[[ "$unique_path" == "/tmp/reports/push-d-20260802-120000-12345.md" ]] || \
  fail "unexpected unique report path: $unique_path"

lock_fd=""
bt_report_acquire_lock "$DELETE_REPO" "test" 2 lock_fd || \
  fail "expected first report lock acquisition to succeed"
set +e
(
  # shellcheck disable=SC2034  # Populated through nameref.
  competing_fd=""
  bt_report_acquire_lock "$DELETE_REPO" "test" 1 competing_fd
) >/dev/null 2>&1
lock_rc=$?
set -e
[[ "$lock_rc" -eq 1 ]] || fail "expected competing report lock to time out"
bt_report_release_lock "$lock_fd"
pass "shared report naming and locking"

echo "All report helper tests passed."