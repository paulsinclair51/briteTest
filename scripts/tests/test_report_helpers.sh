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

for dep in bash git grep mktemp chmod; do
  command -v "$dep" >/dev/null 2>&1 || fail "missing required command: $dep"
done

[[ -f "$REPORT_HELPER_SRC" ]] || fail "missing helper: $REPORT_HELPER_SRC"

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

# 2) Read-only helper should remove write permissions from the generated report.
READONLY_REPORT="$TMPDIR/readonly-report.md"
echo "report body" > "$READONLY_REPORT"
bt_report_mark_read_only "$READONLY_REPORT" 99
[[ ! -w "$READONLY_REPORT" ]] || fail "report should be marked read-only"
pass "mark report read-only"

# 3) Persist helper should commit only the target report and exact deleted paths.
PERSIST_REPO="$TMPDIR/persist-repo"
seed_repo "$PERSIST_REPO"
(
  cd "$PERSIST_REPO"
  mkdir -p reports/branch
  echo "stale" > reports/branch/stale.md
  echo "keep me" > reports/branch/unrelated.md
  git add reports/branch/stale.md reports/branch/unrelated.md
  git commit -m "seed reports" >/dev/null 2>&1

  rm -f reports/branch/stale.md
  echo "current report" > reports/branch/current.md
  echo "manual unrelated edit" >> reports/branch/unrelated.md

  deleted_reports=("reports/branch/stale.md")
  bt_report_persist_changes \
    "$PERSIST_REPO" "$PERSIST_REPO/reports/branch/current.md" \
    deleted_reports "test: persist exact paths" 99 false

  git show --pretty='' --name-only HEAD > "$TMPDIR/persist-head-files.out"
  git diff --name-only > "$TMPDIR/persist-worktree-files.out"
)
assert_contains "reports/branch/current.md" "$TMPDIR/persist-head-files.out"
assert_contains "reports/branch/stale.md" "$TMPDIR/persist-head-files.out"
if grep -Fq -- "reports/branch/unrelated.md" "$TMPDIR/persist-head-files.out"; then
  fail "persist helper should not commit unrelated modified report files"
fi
assert_contains "reports/branch/unrelated.md" "$TMPDIR/persist-worktree-files.out"
pass "persist exact report paths"

# 4) Persist helper should fall back to local-only commit when remote is unreachable.
FALLBACK_REPO="$TMPDIR/fallback-repo"
seed_repo "$FALLBACK_REPO"
(
  cd "$FALLBACK_REPO"
  git remote add origin "$TMPDIR/does-not-exist.git"
  mkdir -p reports/branch
  echo "fallback report" > reports/branch/fallback.md
)
export REPORT_HELPER_SRC FALLBACK_REPO
# shellcheck disable=SC2016  # Exported variables are expanded in the child shell.
rc=$(run_capture "$TMPDIR/fallback.out" bash -c '
  set -euo pipefail
  source "$REPORT_HELPER_SRC"
  deleted_reports=()
  cd "$FALLBACK_REPO"
  bt_report_persist_changes \
    "$FALLBACK_REPO" "$FALLBACK_REPO/reports/branch/fallback.md" \
    deleted_reports "test: unreachable remote fallback" 99 false
')
[[ "$rc" -eq 0 ]] || fail "persist helper should succeed when remote is unreachable"
assert_contains "Cannot connect to remote repository" "$TMPDIR/fallback.out"
assert_contains "Report fallback.md committed." "$TMPDIR/fallback.out"
(
  cd "$FALLBACK_REPO"
  git log --pretty=%s -1 | grep -Fx "test: unreachable remote fallback" >/dev/null || \
    fail "fallback helper should create a local commit"
)
pass "unreachable remote fallback"

echo "All report helper tests passed."