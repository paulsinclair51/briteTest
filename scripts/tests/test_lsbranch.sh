#!/usr/bin/env bash

# test_lsbranch.sh - basic smoke tests for scripts/lsbranch

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LSBRANCH="$SCRIPT_DIR/../lsbranch"

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

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# 1) Help output
rc=$(run_capture "$TMPDIR/help.out" "$LSBRANCH" -h)
[[ "$rc" -eq 0 ]] || fail "lsbranch -h should exit 0"
grep -q '^Usage:' "$TMPDIR/help.out" || fail "lsbranch -h should print Usage"
pass "help output"

# 2) Combined local+remote listing
rc=$(run_capture "$TMPDIR/all.out" "$LSBRANCH" -a)
[[ "$rc" -eq 0 ]] || fail "lsbranch -a should exit 0"
grep -q '\[local\]' "$TMPDIR/all.out" || fail "lsbranch -a should include [local]"
grep -q '\[remote\]' "$TMPDIR/all.out" || fail "lsbranch -a should include [remote]"
pass "-a listing"

# 3) Invalid-only mode should not fail on empty results
rc=$(run_capture "$TMPDIR/invalid.out" "$LSBRANCH" -I)
[[ "$rc" -eq 0 ]] || fail "lsbranch -I should exit 0"
pass "-I empty/success behavior"

# 4) Unknown option handling
rc=$(run_capture "$TMPDIR/unknown.out" "$LSBRANCH" -q)
[[ "$rc" -eq 1 ]] || fail "lsbranch -q should exit 1"
grep -q 'Unknown option: -q\.' "$TMPDIR/unknown.out" || fail "unknown option message missing"
grep -q 'For usage, enter lsbranch -h\.' "$TMPDIR/unknown.out" || fail "usage hint missing for code 1"
pass "unknown option handling"

# 5) Invalid type handling
rc=$(run_capture "$TMPDIR/type.out" "$LSBRANCH" badtype)
[[ "$rc" -eq 2 ]] || fail "lsbranch badtype should exit 2"
grep -q "Invalid type 'badtype'" "$TMPDIR/type.out" || fail "invalid type message missing"
grep -q 'For usage, enter lsbranch -h\.' "$TMPDIR/type.out" || fail "usage hint missing for code 2"
pass "invalid type handling"

echo "All lsbranch smoke tests passed."
