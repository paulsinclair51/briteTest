#!/usr/bin/env bash

# test_rebrand.sh - smoke tests for briteRepo/bin/rebrand.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

TMPDIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

OUTFILE="$TMPDIR/rebrand.out"
set +e
bash "$REPO_ROOT/briteRepo/bin/rebrand" --bogus >"$OUTFILE" 2>&1
rc=$?
set -e

[[ "$rc" -eq 1 ]] || fail "invalid rebrand option should exit 1 (got $rc)"
grep -Fq "Error:" "$OUTFILE" || fail "expected an Error prefix in rebrand output"
grep -Fq "See usage above for details." "$OUTFILE" || fail "expected usage guidance in rebrand output"

set +e
bash "$REPO_ROOT/briteRepo/bin/rebrand" -h >"$TMPDIR/help.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "rebrand -h should exit 0 (got $rc)"
grep -Fq "Generate an error report for the rebrand workflow" "$TMPDIR/help.out" || \
  fail "expected -e option in rebrand usage"
grep -Fq "reports/rebrand-e-<datetime>.md" "$TMPDIR/help.out" || \
  fail "expected error report path in rebrand usage"

set +e
bash "$REPO_ROOT/briteRepo/bin/rebrand" -d -e >"$TMPDIR/de.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 1 ]] || fail "rebrand -d -e should exit 1 (got $rc)"
grep -Fq "Cannot use both -d and -e" "$TMPDIR/de.out" || \
  fail "expected mutual-exclusion error for rebrand -d -e"

echo "All rebrand smoke tests passed."
