#!/usr/bin/env bash

# Shared Git branch and history helpers.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

# Summary of script behavior:
# - Provides shared Git helper functions for branch lookup, status checks, and
#   history operations.
# - Encapsulates repeated Git command patterns used by scripts/bin workflows.
# - Standardizes error handling and output for Git-related helper calls.

bt_get_current_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null
}

bt_resolve_target_branch_from_fork_point() {
  local current_branch="$1"
  local fallback_branch="${2:-main}"

  local merge_base
  merge_base=$(git merge-base --fork-point origin/main "$current_branch" 2>/dev/null || true)
  if [[ -z "$merge_base" ]]; then
    return 1
  fi

  local target_branch
  target_branch=$(git branch -r --contains "$merge_base" | grep -v HEAD | grep -v "origin/$current_branch" | head -1 | sed 's|origin/||' | xargs)

  if [[ -z "$target_branch" ]]; then
    target_branch="$fallback_branch"
  fi

  echo "$target_branch"
}
