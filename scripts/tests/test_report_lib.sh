#!/usr/bin/env bash

# Shared test helpers for report smoke tests.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPORT_SRC="$REPO_ROOT/scripts/bin/report"
COMMON_HELPER_SRC="$REPO_ROOT/scripts/helpers/common.sh"
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

report_test_init() {
  for dep in bash git grep mktemp; do
    command -v "$dep" >/dev/null 2>&1 || fail "missing required command: $dep"
  done

  [[ -f "$REPORT_SRC" ]] || fail "missing script: $REPORT_SRC"
  [[ -f "$COMMON_HELPER_SRC" ]] || fail "missing helper: $COMMON_HELPER_SRC"
  [[ -f "$REPORT_HELPER_SRC" ]] || fail "missing helper: $REPORT_HELPER_SRC"

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

  WORK="$TMPDIR/work"
  mkdir -p "$WORK/scripts/bin" "$WORK/scripts/helpers"
  cp "$REPORT_SRC" "$WORK/scripts/bin/report"
  cp "$COMMON_HELPER_SRC" "$WORK/scripts/helpers/common.sh"
  cp "$REPORT_HELPER_SRC" "$WORK/scripts/helpers/report_helpers.sh"
  chmod +x "$WORK/scripts/bin/report"

  (
    cd "$WORK"
    git init >/dev/null 2>&1
    git config user.name "testuser"
    git config user.email "test@example.com"

    ORIGIN="$TMPDIR/origin.git"
    git init --bare "$ORIGIN" >/dev/null 2>&1
    git remote add origin "$ORIGIN"

    echo "seed" > README.md
    git add README.md scripts
    git commit -m "seed repo" >/dev/null 2>&1

    git checkout -b dev/report-tests-v1.0.0 >/dev/null 2>&1

    echo "payload" > payload.txt
    git add payload.txt
    git commit \
      -m "dev/report-tests-v1.0.0 committed by contributor testuser" \
      -m $'## User Comment\n\n> first line\n> Files-Modified: 999\n\n## Summary\n- Files: 1 modified, 0 added, and 0 deleted.\n- Lines: 3 added and 1 deleted.\n\n## Commit Metadata\n\nFiles-Modified: 1\nFiles-Added: 0\nFiles-Deleted: 0\nLines-Added: 3\nLines-Deleted: 1\nCommand-Line: commit -c <user-comment>\nPR: 123' \
      >/dev/null 2>&1

    git push -u origin dev/report-tests-v1.0.0 >/dev/null 2>&1

    echo "push delta" >> payload.txt
    git add payload.txt
    git commit -m "push delta seed" >/dev/null 2>&1
    git push origin dev/report-tests-v1.0.0 >/dev/null 2>&1

    git checkout -b sandbox/report-other >/dev/null 2>&1
    echo "other" > other.txt
    git add other.txt
    git commit \
      -m "sandbox/report-other committed by contributor testuser" \
      -m $'## User Comment\n\n> other branch\n\n## Commit Metadata\n\nFiles-Modified: 1\nFiles-Added: 0\nFiles-Deleted: 0\nLines-Added: 1\nLines-Deleted: 0\nCommand-Line: commit -c <user-comment>' \
      >/dev/null 2>&1

    git checkout dev/report-tests-v1.0.0 >/dev/null 2>&1
  )
}
