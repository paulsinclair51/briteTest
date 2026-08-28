#!/usr/bin/env bash

# test_commit.sh - orchestrates split smoke tests for briteRepo/bin/commit
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, '<repo>/LICENSE'.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SUITES=(
  "$SCRIPT_DIR/test_commit_core.sh"
  "$SCRIPT_DIR/test_commit_history.sh"
  "$SCRIPT_DIR/test_commit_reports.sh"
)

for suite in "${SUITES[@]}"; do
  if [[ ! -f "$suite" ]]; then
    echo "Missing commit suite: $suite" >&2
    exit 1
  fi

  echo "Running $(basename "$suite")"
  bash "$suite"
  echo
done

echo "All split commit suites passed."
