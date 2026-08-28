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

echo "All rebrand smoke tests passed."
