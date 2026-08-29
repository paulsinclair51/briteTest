#!/usr/bin/env bash

# githook_helper.sh - Common hook enforcement logic
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.
#
# This helper provides shared functionality for all Git hooks:
# - Bypasses enforcement when GIT_BYPASS_HOOKS=true (set by scripts)
# - Provides consistent error messages
# - Logs hook execution for audit trails
#
# Usage in hooks:
#   source "$(git rev-parse --git-dir)/hooks/githook_helper.sh"
#   check_bypass "git commit"

set -euo pipefail

normalize_login() {
  local login="$1"

  login="${login#@}"
  login="$(printf '%s' "$login" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
  printf '%s' "$login"
}

resolve_actor_login_or_empty() {
  local login=""

  if [[ -n "${GITHUB_ACTOR:-}" ]]; then
    login="$GITHUB_ACTOR"
  fi

  if [[ -z "$login" ]] && command -v gh >/dev/null 2>&1; then
    login="$(timeout "${BT_REMOTE_TIMEOUT_SECONDS:-10}s" \
      gh api user --jq '.login' 2>/dev/null || true)"
  fi

  if [[ -z "$login" ]]; then
    login="$(git config user.name 2>/dev/null || true)"
  fi

  if [[ -z "$login" && -n "${USER:-}" ]]; then
    login="$USER"
  fi

  normalize_login "$login"
}

resolve_repo_owner_login_or_empty() {
  local repo_slug="${GITHUB_REPOSITORY:-}"
  local remote_url=""
  local owner=""

  if [[ -n "$repo_slug" && "$repo_slug" == */* ]]; then
    owner="${repo_slug%%/*}"
  fi

  if [[ -z "$owner" ]]; then
    remote_url="$(git remote get-url origin 2>/dev/null || true)"
    if [[ "$remote_url" =~ ^git@github\.com:([^/]+)/([^/]+)(\.git)?$ ]]; then
      owner="${BASH_REMATCH[1]}"
    elif [[ "$remote_url" =~ ^https://github\.com/([^/]+)/([^/]+)(\.git)?$ ]]; then
      owner="${BASH_REMATCH[1]}"
    elif [[ "$remote_url" =~ ^ssh://git@github\.com/([^/]+)/([^/]+)(\.git)?$ ]]; then
      owner="${BASH_REMATCH[1]}"
    fi
  fi

  normalize_login "$owner"
}

owner_unrestricted_mode_active() {
  local owner_override=""
  local actor_lc=""
  local owner_lc=""

  owner_override="$(git config --local --get brite.ownerOverride 2>/dev/null || true)"
  owner_override="$(printf '%s' "$owner_override" | tr '[:upper:]' '[:lower:]')"
  if [[ "$owner_override" != "true" && "$owner_override" != "on" && "$owner_override" != "1" && "$owner_override" != "yes" ]]; then
    return 1
  fi

  actor_lc="$(resolve_actor_login_or_empty)"
  owner_lc="$(resolve_repo_owner_login_or_empty)"
  [[ -n "$actor_lc" && -n "$owner_lc" && "$actor_lc" == "$owner_lc" ]]
}

# Check if this operation is being performed by an authorized script
# Scripts set GIT_BYPASS_HOOKS=true when they perform git operations
check_bypass() {
  local operation="$1"
  local suggested_script="${2:-}"
  
  if [[ "${GIT_BYPASS_HOOKS:-false}" == "true" ]]; then
    return 0  # Operation allowed
  fi

  if owner_unrestricted_mode_active; then
    return 0  # Repository owner unrestricted mode is active in this clone
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
    echo "   Use the appropriate script instead." >&2
    echo "   For help, run: commit -h, merge -h, etc." >&2
  fi

  echo >&2
  echo "   Repository owner unrestricted mode (local clone only):" >&2
  echo "     override on" >&2
  echo "     override off" >&2
  
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
export -f normalize_login
export -f resolve_actor_login_or_empty
export -f resolve_repo_owner_login_or_empty
export -f owner_unrestricted_mode_active
