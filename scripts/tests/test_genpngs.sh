#!/usr/bin/env bash

# test_genpngs.sh - smoke tests for scripts/bin/genpngs
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GENPNGS_SRC="$REPO_ROOT/scripts/bin/genpngs"

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

assert_file_exists() {
  local file="$1"
  [[ -f "$file" ]] || fail "expected file to exist: $file"
}

make_fixture_repo() {
  local repo="$TMPDIR/repo"

  mkdir -p "$repo/scripts/bin" "$repo/docs/branding" "$repo/docs/md"
  cp "$GENPNGS_SRC" "$repo/scripts/bin/genpngs"
  chmod +x "$repo/scripts/bin/genpngs"

  cat > "$repo/docs/branding/Logo_with_Tagline.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="800" height="200" viewBox="0 0 800 200">
  <rect width="800" height="200" fill="#FCFCFD"/>
  <text x="20" y="90" font-family="Verdana, Geneva, sans-serif" font-size="52" fill="#1F2430">briteTest</text>
  <text x="20" y="150" font-family="Verdana, Geneva, sans-serif" font-size="34" fill="#1F2430">Catch it before it breaks.</text>
</svg>
EOF

  cat > "$repo/docs/branding/Monogram.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="240" height="240" viewBox="0 0 240 240">
  <rect x="20" y="20" width="200" height="200" rx="28" fill="#1F2430"/>
  <text x="72" y="148" font-family="Verdana, Geneva, sans-serif" font-size="88" fill="#FFEB66">bT</text>
</svg>
EOF

  cat > "$repo/docs/md/README.md" <<'EOF'
# docs/md
EOF

  cat > "$repo/docs/md/Release_v1.0.0.md" <<'EOF'
# Release v1.0.0
EOF

  cat > "$repo/docs/md/Guide.md" <<'EOF'
# Guide
EOF

  printf '%s\n' "$repo"
}

for dep in bash command grep mktemp rsvg-convert; do
  command -v "$dep" >/dev/null 2>&1 || fail "missing required command: $dep"
done

[[ -f "$GENPNGS_SRC" ]] || fail "missing script: $GENPNGS_SRC"

TMPDIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

WORK="$(make_fixture_repo)"

# 1) Initial run should create document-derived and source-derived PNG files.
rc=$(run_capture "$TMPDIR/first.out" bash -lc "cd '$WORK' && bash ./scripts/bin/genpngs")
[[ "$rc" -eq 0 ]] || fail "first genpngs run should exit 0 (got $rc)"
assert_contains "new and 0 changed PNG files." "$TMPDIR/first.out"
assert_file_exists "$WORK/docs/branding/Release_v1.0.0.png"
assert_file_exists "$WORK/docs/branding/Guide.png"
assert_file_exists "$WORK/docs/branding/Monogram.png"
pass "initial generation"

# 2) Second run must be repeatable with no additional PNG churn.
rc=$(run_capture "$TMPDIR/second.out" bash -lc "cd '$WORK' && bash ./scripts/bin/genpngs")
[[ "$rc" -eq 0 ]] || fail "second genpngs run should exit 0 (got $rc)"
assert_contains "0 new and 0 changed PNG files." "$TMPDIR/second.out"
pass "repeatability second-pass 0/0"

echo "All genpngs tests passed."
