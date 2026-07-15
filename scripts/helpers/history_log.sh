#!/usr/bin/env bash

# Shared helpers for writing branch history markdown logs.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

# High-Level Flow:
# - Provides shared functions to append and format branch history markdown logs.
# - Ensures consistent row formatting and timestamp handling across scripts.
# - Centralizes history-log write operations for workflow scripts.

bt_init_history_log() {
  local log_file="$1"

  mkdir -p "$(dirname "$log_file")"

  if [[ ! -f "$log_file" ]]; then
    cat > "$log_file" <<'HEADER'
# Branch History Log

HEADER
  fi
}

# Convert a branch name to its history file path.
# '/' in the branch name is replaced with '.' in the filename.
# Example: dev/release-v1.0.0 -> logs/dev.release-v1.0.0_history.md
bt_branch_to_history_file() {
  local branch="$1"
  local slug="${branch//\//.}"
  echo "logs/${slug}_history.md"
}

bt_append_history_log() {
  local log_file="$1"
  local message="$2"
  local comment="${3:-}"
  local timestamp

  bt_init_history_log "$log_file"

  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

  if [[ -n "$comment" ]]; then
    cat >> "$log_file" <<EOF

**$timestamp**: $message
  $comment
EOF
  else
    cat >> "$log_file" <<EOF

**$timestamp**: $message
EOF
  fi
}

# Propagate repository_history.md from remote main to current branch if available.
# Efficient: uses SHA comparison to skip fetch if already current.
# Gracefully handles: offline mode, file not in repo, network errors.
#
# Strategy: Attempts to fetch repository_history.md from origin/main (the primary source)
# to the current branch if the file exists on main and differs from local.
#
# Return codes:
#   0 = Already up to date (local SHA matches remote main's SHA, no fetch needed)
#   1 = Updated successfully (fetched newer version from origin/main)
#   2 = Offline, file not in repo, or fetch failed (no output, silent fail)
#
# Usage:
#   bt_propagate_repository_history
#   case $? in
#     0) echo "Repository history already up to date" ;;
#     1) echo "Updated repository history from remote" ;;
#     2) ;;  # offline or unavailable, script continues
#   esac
bt_propagate_repository_history() {
  local local_sha remote_sha current_branch
  
  # Determine current branch (used for descriptive output if needed)
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
  
  # Check 1: Can we reach remote?
  if ! git ls-remote origin >/dev/null 2>&1; then
    return 2  # Offline or remote unreachable, silent fail
  fi

  # Check 2: Does file exist in current branch?
  if ! local_sha=$(git rev-parse HEAD:logs/repository_history.md 2>/dev/null); then
    return 2  # File not in repo yet, silent fail
  fi

  # Check 3: Does file exist in origin/main (the primary source)?
  # Try origin/main first (where it's authoritative), fall back to origin/<current-branch>
  if ! remote_sha=$(git rev-parse origin/main:logs/repository_history.md 2>/dev/null); then
    # origin/main doesn't have it, try current branch on remote
    if ! remote_sha=$(git rev-parse origin/"$current_branch":logs/repository_history.md 2>/dev/null); then
      return 2  # File not in remote, silent fail
    fi
  fi

  # Check 4: Efficient comparison - if SHAs match, skip fetch
  if [[ "$local_sha" == "$remote_sha" ]]; then
    return 0  # Already up to date, no fetch needed (fast path!)
  fi

  # SHAs differ, fetch from origin/main (preferred source) or current branch
  if git fetch origin main:logs/repository_history.md 2>/dev/null; then
    return 1  # Successfully updated from origin/main
  fi
  
  # origin/main fetch failed, try current branch on remote
  if git fetch origin "$current_branch":logs/repository_history.md 2>/dev/null; then
    return 1  # Successfully updated from origin/<current-branch>
  fi

  return 2  # All fetch attempts failed, silent fail
}

# Commit and push repository_history.md changes to origin/main.
# Silent success, returns 0 in all cases (continues even if push fails).
# Assumes working tree has changes staged in logs/repository_history.md.
#
# Usage: bt_commit_and_push_repository_history "commit message"
bt_commit_and_push_repository_history() {
  local commit_msg="${1:-Update repository history}"
  
  # Only proceed if we're connected to remote
  if ! git ls-remote origin >/dev/null 2>&1; then
    return 0  # No remote, skip silently
  fi
  
  # Only proceed if file exists and has changes
  if [[ ! -f "logs/repository_history.md" ]]; then
    return 0  # File doesn't exist, skip silently
  fi
  
  # Commit and push (silently fail if not on main or can't push)
  git add "logs/repository_history.md" 2>/dev/null || return 0
  git commit -m "$commit_msg" 2>/dev/null || return 0
  git push origin HEAD:main 2>/dev/null || return 0
  
  return 0
}
