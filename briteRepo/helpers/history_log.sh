#!/usr/bin/env bash

# Shared helpers for recording workflow history in Git notes.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

# High-Level Flow:
# - Record completed workflow activity as Git notes on the appropriate main ref.
# - Keep note field validation and user/timestamp attribution consistent.
# - Avoid tracked repository log files so branch metadata is not stored in a file
#   that can churn across merges and pull requests.

bt_history_run_remote_command() {
  if declare -F bt_run_remote_command >/dev/null 2>&1; then
    bt_run_remote_command "$@"
  elif command -v timeout >/dev/null 2>&1; then
    timeout "${BT_REMOTE_TIMEOUT_SECONDS:-10}s" "$@"
  else
    "$@"
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

  timestamp="$(date '+%Y-%m-%d %H:%M:%S%z' | sed -E 's/([+-][0-9]{2})([0-9]{2})$/\1:\2/')"
  user_name="$(git config user.name 2>/dev/null || true)"
  user_email="$(git config user.email 2>/dev/null || true)"
  record="--- briteRepo workflow ---
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
  bt_record_workflow_event_to_ref "briteRepo-workflow" "$@"
}

bt_record_remote_workflow_event() {
  bt_record_workflow_event_to_ref "briteRepo-remote-workflow" "$@"
}

bt_undo_sequence_state_file() {
  local branch="$1"
  local common_dir=""
  local sequence_dir=""
  local branch_id=""

  common_dir="$(git rev-parse --path-format=absolute --git-common-dir \
    2>/dev/null)" || return 1
  sequence_dir="$common_dir/briteRepo/undo-report-sequences"
  branch_id="$(printf '%s' "$branch" | cksum | awk '{print $1}')"
  printf '%s/%s.state\n' "$sequence_dir" "$branch_id"
}

bt_undo_reset_sequence() {
  local branch="$1"
  local state_file=""

  state_file="$(bt_undo_sequence_state_file "$branch")" || return 1
  rm -f "$state_file"
}

bt_undo_record_operation() {
  local operation="$1"
  local branch="$2"
  local before_tip="$3"
  local after_tip="$4"
  local strategy="$5"
  local summary="$6"
  local remote_before="${7:-}"
  local remote_after="${8:-}"
  local target="${9:-}"
  local common_dir=""
  local history_dir=""
  local operation_id=""
  local state_file=""

  common_dir="$(git rev-parse --path-format=absolute --git-common-dir \
    2>/dev/null)" || return 1
  history_dir="$common_dir/briteRepo-undo-history"
  mkdir -p "$history_dir" || return 1
  operation_id="$(date '+%s%N')-$$-${RANDOM:-0}"
  state_file="$history_dir/$operation_id.state"
  git config --file "$state_file" undo.id "$operation_id"
  git config --file "$state_file" undo.operation "$operation"
  git config --file "$state_file" undo.branch "$branch"
  git config --file "$state_file" undo.before-tip "$before_tip"
  git config --file "$state_file" undo.after-tip "$after_tip"
  git config --file "$state_file" undo.strategy "$strategy"
  git config --file "$state_file" undo.summary "$summary"
  git config --file "$state_file" undo.remote-before-tip "$remote_before"
  git config --file "$state_file" undo.remote-after-tip "$remote_after"
  git config --file "$state_file" undo.target "$target"
  git config --file "$state_file" undo.undone false
  bt_undo_reset_sequence "$branch" || return 1
  printf '%s\n' "$state_file"
}

bt_undo_latest_operation() {
  local branch="$1"
  local common_dir=""
  local history_dir=""
  local state_file=""

  common_dir="$(git rev-parse --path-format=absolute --git-common-dir \
    2>/dev/null)" || return 1
  history_dir="$common_dir/briteRepo-undo-history"
  [[ -d "$history_dir" ]] || return 1
  while IFS= read -r state_file; do
    [[ "$(git config --file "$state_file" --get undo.branch \
      2>/dev/null || true)" == "$branch" ]] || continue
    [[ "$(git config --file "$state_file" --get undo.undone \
      2>/dev/null || true)" != true ]] || continue
    printf '%s\n' "$state_file"
    return 0
  done < <(find "$history_dir" -maxdepth 1 -type f -name '*.state' \
    -printf '%f\n' | sort -r | sed "s#^#$history_dir/#")
  return 1
}

bt_undo_mark_operation_undone() {
  local state_file="$1"
  local undo_id="$2"

  [[ -f "$state_file" ]] || return 1
  git config --file "$state_file" undo.undone true
  git config --file "$state_file" undo.undo-id "$undo_id"
}

bt_refresh_remote_workflow_history() {
  local remote_ref="refs/notes/briteRepo-remote-workflow"
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
    refs/notes/briteRepo-remote-workflow:refs/notes/briteRepo-remote-workflow \
    >/dev/null 2>&1
}

bt_workflow_note_field() {
  local note="$1"
  local field="$2"

  printf '%s\n' "$note" | awk -v prefix="${field}: " \
    'index($0, prefix) == 1 { value = substr($0, length(prefix) + 1) }
     END { print value }'
}

# Workflow history is stored in Git notes rather than tracked files.
