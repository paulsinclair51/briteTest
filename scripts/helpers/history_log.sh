#!/usr/bin/env bash

# Shared helpers for writing branch history markdown logs.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

# High-Level Flow:
# - Maintain tracked branch-history markdown used by merge/retarget workflows.
# - Record completed workflow activity on the resulting commits.
# - Keep note field validation and user/timestamp attribution consistent.
# - Propagate repository-level history used by branch workflows.

bt_history_run_remote_command() {
  if declare -F bt_run_remote_command >/dev/null 2>&1; then
    bt_run_remote_command "$@"
  elif command -v timeout >/dev/null 2>&1; then
    timeout "${BT_REMOTE_TIMEOUT_SECONDS:-10}s" "$@"
  else
    "$@"
  fi
}

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

# Record one completed workflow action. Additional arguments are key/value
# pairs rendered by report without requiring workflow-specific parsing.
bt_record_workflow_event_to_ref() {
  local notes_ref="$1"
  local workflow_type="$2"
  local branch="$3"
  local command_line="$4"
  local summary="$5"
  local commit_ref="${6:-HEAD}"
  local timestamp=""
  local user_name=""
  local user_email=""
  local record=""
  local field_name=""
  local field_value=""

  shift 6
  (( $# % 2 == 0 )) || return 2

  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
  user_name="$(git config user.name 2>/dev/null || true)"
  user_email="$(git config user.email 2>/dev/null || true)"
  record="--- briteTest workflow ---
Workflow-Type: ${workflow_type}
Workflow-Time: ${timestamp}
Workflow-Branch: ${branch}
Workflow-User: ${user_name} <${user_email}>
Command-Line: ${command_line}
Summary: ${summary}"

  while [[ $# -gt 0 ]]; do
    field_name="$1"
    field_value="$2"
    shift 2
    [[ "$field_name" =~ ^[A-Za-z][A-Za-z0-9-]*$ ]] || return 2
    field_value="$(printf '%s' "$field_value" | tr '\r\n' '  ')"
    record+=$'\n'
    record+="${field_name}: ${field_value}"
  done

  git notes --ref="$notes_ref" append -m "$record" "$commit_ref" \
    >/dev/null 2>&1
}

bt_record_workflow_event() {
  bt_record_workflow_event_to_ref "briteTest-workflow" "$@"
}

bt_record_remote_workflow_event() {
  bt_record_workflow_event_to_ref "briteTest-remote-workflow" "$@"
}

bt_refresh_remote_workflow_history() {
  local remote_ref="refs/notes/briteTest-remote-workflow"
  local remote_tip=""

  remote_tip="$(bt_history_run_remote_command git ls-remote origin \
    "$remote_ref" 2>/dev/null | awk 'NR == 1 { print $1 }')" || return 1
  if [[ -z "$remote_tip" ]]; then
    git update-ref -d "$remote_ref" >/dev/null 2>&1 || return 1
    return 0
  fi
  bt_history_run_remote_command git fetch origin \
    "+${remote_ref}:${remote_ref}" >/dev/null 2>&1
}

bt_publish_remote_workflow_history() {
  bt_history_run_remote_command env GIT_BYPASS_HOOKS=true git push origin \
    refs/notes/briteTest-remote-workflow:refs/notes/briteTest-remote-workflow \
    >/dev/null 2>&1
}

bt_workflow_note_field() {
  local note="$1"
  local field="$2"

  printf '%s\n' "$note" | awk -v prefix="${field}: " \
    'index($0, prefix) == 1 { value = substr($0, length(prefix) + 1) }
     END { print value }'
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
  current_branch=$(bt_get_current_branch_or_empty || echo "unknown")
  
  # Check 1: Can we reach remote?
  if ! bt_history_run_remote_command git ls-remote origin >/dev/null 2>&1; then
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
  if bt_history_run_remote_command git fetch origin main:logs/repository_history.md 2>/dev/null; then
    return 1  # Successfully updated from origin/main
  fi
  
  # origin/main fetch failed, try current branch on remote
  if bt_history_run_remote_command git fetch origin "$current_branch":logs/repository_history.md 2>/dev/null; then
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
  if ! bt_history_run_remote_command git ls-remote origin >/dev/null 2>&1; then
    return 0  # No remote, skip silently
  fi
  
  # Only proceed if file exists and has changes
  if [[ ! -f "logs/repository_history.md" ]]; then
    return 0  # File doesn't exist, skip silently
  fi
  
  # Commit and push (silently fail if not on main or can't push)
  git add "logs/repository_history.md" 2>/dev/null || return 0
  git commit -m "$commit_msg" 2>/dev/null || return 0
  bt_history_run_remote_command git push origin HEAD:main 2>/dev/null || return 0
  
  return 0
}
