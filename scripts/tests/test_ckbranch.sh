#!/usr/bin/env bash

# test_ckbranch.sh - smoke tests for scripts/bin/ckbranch
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CKBRANCH="$SCRIPT_DIR/../bin/ckbranch"

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

extract_report_path() {
  local infile="$1"
  awk -F': ' '/^Report generated: /{print $2}' "$infile" | tail -n 1
}

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# 1) Help output
rc=$(run_capture "$TMPDIR/help.out" "$CKBRANCH" -h)
[[ "$rc" -eq 0 ]] || fail "ckbranch -h should exit 0"
grep -q '^Usage:' "$TMPDIR/help.out" || fail "ckbranch -h should print Usage"
pass "help output"

# 2) -a -r should include remote view output and not claim no branches for "*"
rc=$(run_capture "$TMPDIR/remote.out" "$CKBRANCH" -a -r)
[[ "$rc" -eq 0 ]] || fail "ckbranch -a -r should exit 0"
if grep -q 'No branches found matching pattern: \*' "$TMPDIR/remote.out"; then
  fail "ckbranch -a -r should not report no branches for '*'"
fi
grep -q '\[remote\]' "$TMPDIR/remote.out" || fail "ckbranch -a -r should include [remote] output"

remote_only_branch=$(git branch -r | sed 's|^..origin/||' | grep -v ' -> ' | while IFS= read -r b; do
  [[ -n "$b" ]] || continue
  if [[ -z "$(git branch --list "$b")" ]]; then
    echo "$b"
    break
  fi
done)
if [[ -n "$remote_only_branch" ]]; then
  grep -Fx "$remote_only_branch [remote]" "$TMPDIR/remote.out" >/dev/null || fail "remote-only branch should be present in -a -r output"
fi
pass "-a -r includes remote rows"

# 3) -a -l should not print remote tags
rc=$(run_capture "$TMPDIR/local.out" "$CKBRANCH" -a -l)
[[ "$rc" -eq 0 ]] || fail "ckbranch -a -l should exit 0"
if grep -q '\[remote\]' "$TMPDIR/local.out"; then
  fail "ckbranch -a -l should not include [remote] output"
fi
grep -q '\[local\]' "$TMPDIR/local.out" || fail "ckbranch -a -l should include [local] output"
pass "-a -l local-only output"

# 4) Current branch marker should be a trailing * in the report (not malformed markdown)
rc=$(run_capture "$TMPDIR/default.out" "$CKBRANCH")
[[ "$rc" -eq 0 ]] || fail "ckbranch should exit 0"
report_rel=$(extract_report_path "$TMPDIR/default.out")
[[ -n "$report_rel" ]] || fail "ckbranch output should include generated report path"
report_path="$SCRIPT_DIR/../../$report_rel"
[[ -f "$report_path" ]] || fail "generated report file should exist"

current_branch=$(git rev-parse --abbrev-ref HEAD)
grep -E "\| ${current_branch}\* \| local \|" "$report_path" >/dev/null || fail "current branch should be marked with trailing * in local report row"
pass "current branch report marker"

# 5) Literal dots in pattern should be treated literally, not as regex wildcard
rc=$(run_capture "$TMPDIR/literal.out" "$CKBRANCH" "v1.0.0" -l)
[[ "$rc" -eq 0 ]] || fail "ckbranch 'v1.0.0' -l should exit 0"
grep -q '^v1.0.0 ' "$TMPDIR/literal.out" || fail "literal pattern should match branch v1.0.0"
pass "literal glob pattern behavior"

echo "All ckbranch smoke tests passed."
