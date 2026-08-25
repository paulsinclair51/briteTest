#!/usr/bin/env bash

# test_replacetext.sh - smoke tests for briteRepo/bin/replacetext.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPLACETEXT_SRC="$REPO_ROOT/briteRepo/bin/replacetext"

pass() {
  echo "PASS: $1"
}

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

assert_contains() {
  local text="$1"
  local file="$2"
  grep -Fq -- "$text" "$file" || fail "expected '$text' in $file"
}

run_in_work_capture() {
  # Usage: run_in_work_capture <outfile> <args...>
  local outfile="$1"
  shift
  set +e
  (
    cd "$WORK"
    bash "$WORK/briteRepo/bin/replacetext" "$@"
  ) >"$outfile" 2>&1
  local rc=$?
  set -e
  echo "$rc"
}

for dep in bash grep mktemp perl find sort mv; do
  command -v "$dep" >/dev/null 2>&1 || fail "missing required command: $dep"
done

[[ -f "$REPLACETEXT_SRC" ]] || fail "missing script: $REPLACETEXT_SRC"

TMPDIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

WORK="$TMPDIR/work"
mkdir -p "$WORK/briteRepo/bin" "$WORK/briteRepo/helpers"
cp "$REPLACETEXT_SRC" "$WORK/briteRepo/bin/replacetext"
cp "$REPO_ROOT/briteRepo/helpers/git_helpers.sh" "$WORK/briteRepo/helpers/git_helpers.sh"

cat > "$WORK/README.md" <<'EOF'
This line includes -foo and plain text.
EOF

# 1) Dash-leading FIND token is accepted when provided after --.
rc=$(run_in_work_capture "$TMPDIR/with_dash_ok.out" -d -- -foo bar)
[[ "$rc" -eq 0 ]] || fail "expected '-d -- -foo bar' to exit 0 (got $rc)"
assert_contains "Loaded 1 direct replacement mapping(s) from arguments" "$TMPDIR/with_dash_ok.out"
pass "accepts dash-leading FIND with --"

# 2) Dash-leading FIND token is rejected without -- (treated as option).
rc=$(run_in_work_capture "$TMPDIR/without_dash_bad.out" -d -foo bar)
[[ "$rc" -eq 1 ]] || fail "expected '-d -foo bar' to exit 1 (got $rc)"
assert_contains "Unknown option: -foo" "$TMPDIR/without_dash_bad.out"
pass "rejects dash-leading FIND without --"

echo "All replacetext smoke tests passed."
