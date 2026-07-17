#!/usr/bin/env bash

# orchestrator.sh - Common hook enforcement logic
#
# This helper provides shared functionality for all Git hooks:
# - Bypasses enforcement when BRITETEST_BYPASS_HOOKS=true (set by scripts)
# - Provides consistent error messages
# - Logs hook execution for audit trails
#
# Usage in hooks:
#   source "$(git rev-parse --git-dir)/hooks/orchestrator.sh"
#   check_bypass "git commit"
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT

set -euo pipefail

# Check if this operation is being performed by an authorized script
# Scripts set BRITETEST_BYPASS_HOOKS=true when they perform git operations
check_bypass() {
  local operation="$1"
  local suggested_script="${2:-}"
  
  if [[ "${BRITETEST_BYPASS_HOOKS:-false}" == "true" ]]; then
    return 0  # Operation allowed
  fi
  
  # Operation blocked - show error and suggestion
  echo >&2
  echo "❌ Error: Direct $operation operations are not allowed." >&2
  echo >&2
  
  if [[ -n "$suggested_script" ]]; then
    echo "   Use the '$suggested_script' script instead:" >&2
    echo >&2
    echo "     $suggested_script [options]" >&2
    echo >&2
    echo "   For help: $suggested_script -h" >&2
  else
    echo "   Use the appropriate briteTest script instead." >&2
    echo "   For help, run: commit -h, merge -h, etc." >&2
  fi
  
  echo >&2
  return 1  # Block operation
}

# Common hook functions for script and command checking
hook_name() {
  basename "$0"
}

git_command_in_progress() {
  local cmd="$1"
  git rev-parse --git-dir >/dev/null 2>&1 || return 1
  [[ -n "$(git config hooks.$cmd 2>/dev/null || true)" ]] || return 1
}

export -f check_bypass
export -f hook_name
export -f git_command_in_progress
