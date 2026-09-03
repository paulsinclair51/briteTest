#!/usr/bin/env bash

# Shared GitHub CLI helpers.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

# Internal library: must be sourced by a briteRepo command or helper. Direct
# execution by a user is not supported.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "github_helpers.sh is a briteRepo internal library and must be sourced." >&2
  exit 1
fi

# High-Level Flow:
# - Provides shared GitHub CLI helper functions for PR/repository interactions.
# - Encapsulates repeated gh command patterns and argument validation.
# - Standardizes error handling and output for GitHub-related helper calls.

bt_gh_find_pr_number_for_branch() {
  local branch="$1"
  local state="${2:-all}"

  bt_run_remote_command gh pr list --head "$branch" --state "$state" --json number \
    --jq '.[0].number' 2>/dev/null || echo ""
}

bt_gh_run_or_exit() {
  local timeout_exit_code="$1"
  local api_exit_code="$2"
  local message="$3"
  shift 3

  local rc=0
  bt_run_remote_command "$@" >/dev/null 2>&1 || rc=$?
  if [[ "$rc" -eq 0 ]]; then
    return 0
  fi

  if [[ "$rc" -eq 124 ]]; then
    bt_error_exit "$timeout_exit_code" "$message (timed out or remote unreachable)"
  fi

  bt_error_exit "$api_exit_code" "$message"
}

bt_gh_capture_or_exit() {
  local __result_var="$1"
  local timeout_exit_code="$2"
  local api_exit_code="$3"
  local message="$4"
  shift 4

  local output
  local rc=0
  output="$(bt_run_remote_command "$@" 2>/dev/null)" || rc=$?
  if [[ "$rc" -ne 0 ]]; then
    if [[ "$rc" -eq 124 ]]; then
      bt_error_exit "$timeout_exit_code" "$message (timed out or remote unreachable)"
    fi
    bt_error_exit "$api_exit_code" "$message"
  fi

  printf -v "$__result_var" '%s' "$output"
}
