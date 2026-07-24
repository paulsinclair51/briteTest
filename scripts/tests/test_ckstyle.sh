#!/usr/bin/env bash

# test_ckstyle.sh - smoke tests for scripts/bin/ckstyle
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CKSTYLE_SRC="$REPO_ROOT/scripts/bin/ckstyle"
RELEASE_DOC_SRC="$REPO_ROOT/docs/md/Release-v1.0.0.md"
RELEASE_BANNER_SRC="$REPO_ROOT/docs/branding/Release-v1.0.0.svg"
TEST_GUIDE_BANNER_SRC="$REPO_ROOT/docs/branding/Test_Guide.svg"
RUNNER_HEADER_SRC="$REPO_ROOT/include/runnerapi.h"
RUNNER_SOURCE_SRC="$REPO_ROOT/src/runnerapi.c"

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

latest_report() {
  local repo="$1"

  find "$repo/reports/guidelines" -maxdepth 1 -type f -name 'ckstyle-*.md' \
    -printf '%T@ %p\n' | sort -n | tail -n 1 | cut -d' ' -f2-
}

reset_report_dir() {
  local repo="$1"

  rm -rf "$repo/reports/guidelines"
  mkdir -p "$repo/reports/guidelines"
}

make_fixture_repo() {
  local name="$1"
  local repo="$TMPDIR/$name"

  mkdir -p "$repo/scripts/bin" "$repo/docs/md" "$repo/docs/branding" \
    "$repo/include" "$repo/src"

  cp "$CKSTYLE_SRC" "$repo/scripts/bin/ckstyle"
  cp "$RELEASE_DOC_SRC" "$repo/docs/md/Release-v1.0.0.md"
  cp "$RELEASE_BANNER_SRC" "$repo/docs/branding/Release-v1.0.0.svg"
  cp "$TEST_GUIDE_BANNER_SRC" "$repo/docs/branding/Test_Guide.svg"
  cp "$RUNNER_HEADER_SRC" "$repo/include/runnerapi.h"
  cp "$RUNNER_SOURCE_SRC" "$repo/src/runnerapi.c"
  chmod +x "$repo/scripts/bin/ckstyle"

  git -C "$repo" init -q
  git -C "$repo" config user.name "testuser"
  git -C "$repo" config user.email "test@example.com"
  git -C "$repo" branch -M main
  git -C "$repo" add \
    docs/md/Release-v1.0.0.md \
    docs/branding/Release-v1.0.0.svg \
    include/runnerapi.h \
    src/runnerapi.c
  git -C "$repo" commit -q -m "seed ckstyle fixture"

  printf '%s\n' "$repo"
}

for dep in bash find git grep mktemp sort tail cut; do
  command -v "$dep" >/dev/null 2>&1 || fail "missing required command: $dep"
done

[[ -f "$CKSTYLE_SRC" ]] || fail "missing script: $CKSTYLE_SRC"
[[ -f "$RELEASE_DOC_SRC" ]] || fail "missing fixture source: $RELEASE_DOC_SRC"
[[ -f "$RELEASE_BANNER_SRC" ]] || fail "missing fixture source: $RELEASE_BANNER_SRC"
[[ -f "$TEST_GUIDE_BANNER_SRC" ]] || fail "missing fixture source: $TEST_GUIDE_BANNER_SRC"
[[ -f "$RUNNER_HEADER_SRC" ]] || fail "missing fixture source: $RUNNER_HEADER_SRC"
[[ -f "$RUNNER_SOURCE_SRC" ]] || fail "missing fixture source: $RUNNER_SOURCE_SRC"

TMPDIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

WORK="$(make_fixture_repo work)"

# Coverage note: this smoke test checks the main CLI/report paths, a single
# validation failure, and basename selection. It does not try to cover every
# individual ckstyle rule; those are exercised by the repository fixtures.

# 1) Help output.
rc=$(run_capture "$TMPDIR/help.out" bash -lc "cd '$WORK' && bash ./scripts/bin/ckstyle -h")
[[ "$rc" -eq 0 ]] || fail "ckstyle -h should exit 0"
assert_contains "Usage:" "$TMPDIR/help.out"
assert_contains "-v          Enable verbose diagnostics to stderr." "$TMPDIR/help.out"
pass "help output"

# 2) Default run should pass cleanly and create a local report.
rc=$(run_capture "$TMPDIR/default.out" bash -lc "cd '$WORK' && bash ./scripts/bin/ckstyle")
[[ "$rc" -eq 0 ]] || fail "ckstyle should exit 0 on clean fixture (got $rc)"
assert_contains "INFO: all selected validations passed." "$TMPDIR/default.out"
assert_contains "<repo>/reports/guidelines/ckstyle-" "$TMPDIR/default.out"
assert_contains " created." "$TMPDIR/default.out"
default_report="$(latest_report "$WORK")"
[[ -f "$default_report" ]] || fail "expected ckstyle report to be created"
assert_contains "# ckstyle Validation Report" "$default_report"
assert_contains "No issues found." "$default_report"
pass "default validation run"

# 3) -v should emit verbose diagnostics to stderr.
rc=$(run_capture "$TMPDIR/verbose.out" bash -lc "cd '$WORK' && bash ./scripts/bin/ckstyle -v docs/md/Release-v1.0.0.md include/runnerapi.h src/runnerapi.c")
[[ "$rc" -eq 0 ]] || fail "ckstyle -v should exit 0 on clean selected files (got $rc)"
assert_contains "VERBOSE: selected files:" "$TMPDIR/verbose.out"
assert_contains "VERBOSE: running document checks" "$TMPDIR/verbose.out"
assert_contains "VERBOSE: running version consistency checks (enabled by -m)" "$TMPDIR/verbose.out"
pass "verbose diagnostics"

# 4) --verbose should be rejected now that only -v is supported.
rc=$(run_capture "$TMPDIR/long-verbose.out" bash -lc "cd '$WORK' && bash ./scripts/bin/ckstyle --verbose")
[[ "$rc" -eq 1 ]] || fail "ckstyle --verbose should exit 1 (got $rc)"
assert_contains "Unknown option: --verbose" "$TMPDIR/long-verbose.out"
pass "long option rejection"

# 5) Report I/O failures should use the dedicated exit code.
rm -rf "$WORK/reports/guidelines"
mkdir -p "$WORK/reports"
printf 'blocked by test\n' > "$WORK/reports/guidelines"
rc=$(run_capture "$TMPDIR/report-io.out" bash -lc "cd '$WORK' && bash ./scripts/bin/ckstyle -m docs/md/Release-v1.0.0.md")
[[ "$rc" -eq 200 ]] || fail "ckstyle report I/O failure should exit 200 (got $rc)"
assert_contains "unable to create report directory" "$TMPDIR/report-io.out"
pass "report I/O failure"

# 6) Bare filenames should select tracked files by basename.
reset_report_dir "$WORK"
rc=$(run_capture "$TMPDIR/basename.out" bash -lc "cd '$WORK' && bash ./scripts/bin/ckstyle Release-v1.0.0.md")
[[ "$rc" -eq 0 ]] || fail "ckstyle basename selection should exit 0 (got $rc)"
assert_contains "INFO: all selected validations passed." "$TMPDIR/basename.out"
basename_report="$(latest_report "$WORK")"
[[ -f "$basename_report" ]] || fail "expected ckstyle basename report to be created"
assert_contains "- Selected files: 1" "$basename_report"
pass "basename selection"

# 7) Bare filenames should also select tracked headers by basename.
reset_report_dir "$WORK"
rc=$(run_capture "$TMPDIR/header-basename.out" bash -lc "cd '$WORK' && bash ./scripts/bin/ckstyle runnerapi.h")
[[ "$rc" -eq 0 ]] || fail "ckstyle header basename selection should exit 0 (got $rc)"
assert_contains "INFO: all selected validations passed." "$TMPDIR/header-basename.out"
header_basename_report="$(latest_report "$WORK")"
[[ -f "$header_basename_report" ]] || fail "expected ckstyle header basename report to be created"
assert_contains "- Selected files: 1" "$header_basename_report"
pass "header basename selection"

# 8) A modified doc fixture should fail validation with exit 2.
sed -i 's/SPDX-License-Identifier: MIT/SPDX-License-Identifier: Apache-2.0/' \
  "$WORK/docs/md/Release-v1.0.0.md"
rc=$(run_capture "$TMPDIR/invalid-doc.out" bash -lc "cd '$WORK' && bash ./scripts/bin/ckstyle -m docs/md/Release-v1.0.0.md")
[[ "$rc" -eq 2 ]] || fail "ckstyle validation failure should exit 2 (got $rc)"
assert_contains "Validation found" "$TMPDIR/invalid-doc.out"
assert_contains "<repo>/reports/guidelines/ckstyle-" "$TMPDIR/invalid-doc.out"
assert_contains " created." "$TMPDIR/invalid-doc.out"
invalid_report="$(latest_report "$WORK")"
[[ -f "$invalid_report" ]] || fail "expected ckstyle failure report to be created"
assert_contains "missing SPDX identifier before Table of Contents" "$invalid_report"
pass "validation failure"

echo "All ckstyle tests passed."