#!/usr/bin/env bash

# install-git-hooks.sh - Configure Git to use hooks from scripts/helpers/.githooks/
#
# Sets core.hooksPath to point to the versioned hooks directory, allowing Git
# to automatically find and execute hooks without copying them to .git/hooks/.
#
# Usage:
#   bash scripts/helpers/install-git-hooks.sh [--silent]
#
# Options:
#   --silent  Suppress output (for use in automated workflows)
#
# Exit codes:
#   0  Git hooks configured successfully
#   1  Could not determine repository root
#   2  .git directory not found
#   3  .githooks directory not found
#   4  Failed to set core.hooksPath
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT

set -euo pipefail

SILENT=false

# Parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --silent)
      SILENT=true
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# Determine repository root
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  [[ "$SILENT" != true ]] && echo "Error: Could not determine repository root" >&2
  exit 1
}

GITHOOKS_DIR="$REPO_ROOT/scripts/helpers/.githooks"

# Verify directories exist
if [[ ! -d "$REPO_ROOT/.git" ]]; then
  [[ "$SILENT" != true ]] && echo "Error: .git directory not found" >&2
  exit 2
fi

if [[ ! -d "$GITHOOKS_DIR" ]]; then
  [[ "$SILENT" != true ]] && echo "Error: .githooks directory not found at $GITHOOKS_DIR" >&2
  exit 3
fi

# Configure core.hooksPath to point to the versioned hooks directory
if ! git config core.hooksPath scripts/helpers/.githooks >/dev/null 2>&1; then
  [[ "$SILENT" != true ]] && echo "Failed to set core.hooksPath" >&2
  exit 4
fi

# Ensure all hooks are executable
chmod +x "$GITHOOKS_DIR"/* 2>/dev/null || true

[[ "$SILENT" != true ]] && echo "All hooks configured successfully"
exit 0

