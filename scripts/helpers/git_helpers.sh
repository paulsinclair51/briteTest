#!/usr/bin/env bash

# Shared Git branch and history helpers.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

# High-Level Flow:
# - Provides shared Git helper functions for branch lookup, status checks, and
#   history operations.
# - Encapsulates repeated Git command patterns used by scripts/bin workflows.
# - Standardizes error handling and output for Git-related helper calls.

bt_get_current_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null
}

# bt_is_worktree_dirty
#
# Returns 0 (true) if the working tree has any uncommitted changes:
# staged changes, unstaged modifications to tracked files, or untracked files.
# Returns 1 (false) if the working tree is clean.
#
# Untracked files are intentionally included (--untracked-files=no is NOT used)
# so the definition of "dirty" is consistent across all scripts that gate
# operations on a clean working tree (rmbranch, chbranch, mkbranch, etc.).
#
# --no-optional-locks prevents git from opportunistically refreshing the index
# as a side effect of a read-only status check.
#
# stderr is suppressed; if git exits non-zero (e.g. called outside a work
# tree), the subshell produces no output and the function returns 1 (not
# dirty). Callers are expected to have already validated the git context.
# The || true prevents set -euo pipefail from aborting on a non-zero git exit.
bt_is_worktree_dirty() {
  [[ -n "$(git --no-optional-locks status --porcelain 2>/dev/null || true)" ]]
}

bt_is_version_branch() {
  local branch="$1"

  [[ "$branch" =~ ^v([1-9][0-9]?)\.(0|[1-9][0-9]?)\.(0|[1-9][0-9]?)$ ]]
}

bt_is_protected_branch() {
  local branch="$1"

  [[ "$branch" == "main" ]] || bt_is_version_branch "$branch"
}

bt_resolve_parent_branch() {
  local current_branch="$1"
  local fallback_branch="${2:-main}"

  if [[ "$current_branch" == "main" ]]; then
    echo ""
    return 0
  fi

  if bt_is_version_branch "$current_branch"; then
    echo "main"
    return 0
  fi

  if [[ "$current_branch" =~ ^(dev|fix)/.+-(v[1-9][0-9]?\.(0|[1-9][0-9]?)\.(0|[1-9][0-9]?))$ ]]; then
    echo "${BASH_REMATCH[2]}"
    return 0
  fi

  local branch_ref="$current_branch"
  if ! git show-ref --verify --quiet "refs/heads/$current_branch"; then
    if git show-ref --verify --quiet "refs/remotes/origin/$current_branch"; then
      branch_ref="origin/$current_branch"
    else
      echo "$fallback_branch"
      return 0
    fi
  fi

  local branch_tip
  branch_tip=$(git rev-parse "$branch_ref" 2>/dev/null || true)

  local best_parent=""
  local best_distance=""
  local ref

  while IFS= read -r ref; do
    [[ -n "$ref" ]] || continue
    [[ "$ref" == "origin/HEAD" ]] && continue
    [[ "$ref" == "$current_branch" ]] && continue
    [[ "$ref" == "origin/$current_branch" ]] && continue

    local candidate_ref="$ref"
    local candidate_display="$ref"
    if [[ "$ref" == origin/* ]]; then
      candidate_display="${ref#origin/}"
    fi
    [[ "$candidate_display" == "$current_branch" ]] && continue

    local candidate_tip
    candidate_tip=$(git rev-parse "$candidate_ref" 2>/dev/null || true)
    if [[ -n "$branch_tip" && -n "$candidate_tip" && "$candidate_tip" == "$branch_tip" ]]; then
      continue
    fi

    if ! git merge-base --is-ancestor "$candidate_ref" "$branch_ref" >/dev/null 2>&1; then
      continue
    fi

    local distance
    distance=$(git rev-list --count "$candidate_ref..$branch_ref" 2>/dev/null || echo "")
    [[ "$distance" =~ ^[0-9]+$ ]] || continue

    if [[ -z "$best_distance" || "$distance" -lt "$best_distance" ]]; then
      best_distance="$distance"
      best_parent="$candidate_display"
    fi
  done < <(
    {
      git for-each-ref --format='%(refname:short)' refs/heads
      git for-each-ref --format='%(refname:short)' refs/remotes/origin
    } | sort -u
  )

  if [[ -n "$best_parent" ]]; then
    echo "$best_parent"
  else
    echo "$fallback_branch"
  fi
}

bt_resolve_target_branch_from_fork_point() {
  local current_branch="$1"
  local fallback_branch="${2:-main}"

  bt_resolve_parent_branch "$current_branch" "$fallback_branch"
}
