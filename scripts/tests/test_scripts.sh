#!/usr/bin/env bash

# test_scripts.sh - Run all script smoke tests in scripts/tests.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  test_scripts.sh [OPTIONS]
  test_scripts.sh {-h | --help}

Run all script smoke tests in scripts/tests matching test_*.sh
(excluding this runner itself).

When present, test_chbranch.sh is prioritized to run first.

Options:
  -h, --help           Output this help to stdout and exit.
  -v, --verbose        Show per-test execution details.
  -c, --continue       Continue running remaining tests after failures.

Exit codes:
  0   All tests passed
  1   Argument or validation error
  2   A test failed (stop-on-failure mode)
  5   One or more tests failed (--continue mode)
EOF
}

VERBOSE=false
STOP_ON_FAIL=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -c|--continue)
      STOP_ON_FAIL=false
      shift
      ;;
    *)
      echo "Error: Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fail_count=0

mapfile -t test_files < <(
  find "$SCRIPT_DIR" -maxdepth 1 -type f -name 'test_*.sh' ! -name 'test_scripts.sh' | sort
)

# Prioritize chbranch regression tests when present.
chbranch_test="$SCRIPT_DIR/test_chbranch.sh"
if [[ -f "$chbranch_test" ]]; then
  filtered=()
  for test_file in "${test_files[@]}"; do
    if [[ "$test_file" != "$chbranch_test" ]]; then
      filtered+=("$test_file")
    fi
  done
  test_files=("$chbranch_test" "${filtered[@]}")
fi

if [[ "${#test_files[@]}" -eq 0 ]]; then
  echo "Error: No test_*.sh files found in $SCRIPT_DIR" >&2
  exit 1
fi

for test_file in "${test_files[@]}"; do
  if [[ "$VERBOSE" == true ]]; then
    echo "Running: $(basename "$test_file")"
  fi

  set +e
  bash "$test_file"
  rc=$?
  set -e

  if [[ "$rc" -ne 0 ]]; then
    fail_count=$((fail_count + 1))
    echo "FAIL: $(basename "$test_file") (exit $rc)" >&2
    if [[ "$STOP_ON_FAIL" == true ]]; then
      exit 2
    fi
  elif [[ "$VERBOSE" == true ]]; then
    echo "PASS: $(basename "$test_file")"
  fi
done

if [[ "$fail_count" -gt 0 ]]; then
  echo "Completed with $fail_count failing test script(s)." >&2
  exit 5
fi

echo "All script smoke tests passed."
exit 0
