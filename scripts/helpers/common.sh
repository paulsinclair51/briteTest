#!/usr/bin/env bash

# Shared text output and branch-detection helpers.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

# High-Level Flow:
# - Provides shared output helpers for info/success/warn messaging.
# - Provides a common error-exit helper and branch-detection utility.
# - Provides shared GitHub login resolution helpers for role-gated scripts.
# - Maintains consistent lightweight shell behavior across scripts/bin tools.

bt_info() {
  echo "$1"
}

bt_success() {
  echo "$1"
}

bt_warn() {
  echo "$1"
}

bt_error_exit() {
  local code="$1"
  local message="$2"

  echo "Error: $message" >&2
  exit "$code"
}

bt_get_current_branch_or_empty() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null || true
}

bt_normalize_login() {
  local login="$1"

  login="${login#@}"
  login="$(printf '%s' "$login" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
  printf '%s' "$login"
}

bt_resolve_login_or_empty() {
  local login=""

  if [[ -n "${GITHUB_ACTOR:-}" ]]; then
    login="$GITHUB_ACTOR"
  fi

  if [[ -z "$login" ]] && command -v gh >/dev/null 2>&1; then
    login="$(gh api user --jq '.login' 2>/dev/null || true)"
  fi

  if [[ -z "$login" ]]; then
    login="$(git config user.name 2>/dev/null || true)"
  fi

  if [[ -z "$login" && -n "${USER:-}" ]]; then
    login="$USER"
  fi

  login="$(bt_normalize_login "$login")"
  if [[ -z "$login" ]]; then
    printf ''
    return 0
  fi

  # GitHub login format check: 1-39 chars, lowercase alnum and hyphen,
  # cannot start or end with hyphen.
  if [[ ! "$login" =~ ^([a-z0-9]|[a-z0-9][a-z0-9-]{0,37}[a-z0-9])$ ]]; then
    printf ''
    return 0
  fi

  printf '%s' "$login"
}

bt_require_login() {
  local login

  login="$(bt_resolve_login_or_empty)"
  if [[ -n "$login" ]]; then
    printf '%s\n' "$login"
    return 0
  fi

  echo "Error: unable to determine GitHub login identity." >&2
  echo "Set GITHUB_ACTOR, or run 'gh auth login', or set git user.name to your GitHub login." >&2
  return 1
}
