#!/usr/bin/env bash

# pulldown_workflow.sh - merge-down workflow used by pulldown and pushup.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

# Internal library: must be sourced by a briteRepo command or helper. Direct
# execution by a user is not supported.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "pulldown_workflow.sh is a briteRepo internal library and must be sourced." >&2
  exit 1
fi

# The sourcing command owns usage and argument validation; this library owns
# the work. Callers run bt_pulldown_init, set the validated globals, then call
# bt_pulldown_run.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPORTS_DIR="$REPO_ROOT/reports"
RUN_TS_FILE="$(date '+%Y%m%d-%H%M%S%z')"
RUN_TS_DISPLAY="$(date '+%Y-%m-%d %H:%M:%S%z' | sed -E 's/([+-][0-9]{2})([0-9]{2})$/\1:\2/')"
REPORT_FILE=""
REPORTS_DIR_WRITE_ENABLED=false
REPORT_LOCK_FD=""
REPORT_LOCK_HELD=false
CURRENT_BRANCH=""
PARENT_BRANCH=""
MERGE_UPDATED_FILES=0
MERGE_ADDED_FILES=0
MERGE_DELETED_FILES=0
MERGE_RENAMED_FILES=0
MERGE_RENAMED_MODIFIED_FILES=0
MERGE_DELETED_DIRECTORIES=0
MERGE_ADDED_DIRECTORIES=0
MERGE_RENAMED_DIRECTORIES=0
MERGE_FILE_SUMMARY_TEXT=""
OPERATION_STARTED=false
ERROR_REPORT_WRITTEN=false
PUSHUP_SYNC=false

# Shared helpers
# shellcheck source=helpers/common.sh
source "$SCRIPT_DIR/common.sh"
# shellcheck source=helpers/history_log.sh
source "$SCRIPT_DIR/history_log.sh"
# shellcheck source=helpers/git_helpers.sh
source "$SCRIPT_DIR/git_helpers.sh"
# shellcheck source=helpers/report_helpers.sh
source "$SCRIPT_DIR/report_helpers.sh"

readonly EXIT_INVALID_ARGUMENT=1
readonly EXIT_NOT_FOUND=2
readonly EXIT_OPERATION_FAILED=3
readonly EXIT_CONFIG_ERROR=4
readonly EXIT_NOTHING_TO_MERGE=5
readonly EXIT_WORKFLOW_SKIPPED=6
readonly EXIT_INTERNAL_ERROR=100

cleanup_runtime_files() {
  if [[ "$REPORT_LOCK_HELD" == true ]]; then
    bt_report_release_lock "$REPORT_LOCK_FD"
    REPORT_LOCK_HELD=false
  fi
  if [[ "$REPORTS_DIR_WRITE_ENABLED" == true ]]; then
    REPORTS_DIR_WRITE_ENABLED=false
  fi
}

trap cleanup_runtime_files EXIT

enable_reports_write_access() {
  bt_report_dir_enable_writes "$REPORTS_DIR" "$EXIT_CONFIG_ERROR"
  REPORTS_DIR_WRITE_ENABLED=true
}

disable_reports_write_access() {
  if [[ "$REPORTS_DIR_WRITE_ENABLED" == true ]]; then
    REPORTS_DIR_WRITE_ENABLED=false
  fi
}

acquire_report_lock() {
  if ! bt_report_acquire_lock "$REPO_ROOT" "pulldown" 10 REPORT_LOCK_FD; then
    bt_emit_prerequisite_failure "$EXIT_CONFIG_ERROR" \
      "Timed out waiting 10s for report write lock." \
      "retry the operation after the report lock becomes available."
  fi
  REPORT_LOCK_HELD=true
}

release_report_lock() {
  bt_report_release_lock "$REPORT_LOCK_FD"
  REPORT_LOCK_FD=""
  REPORT_LOCK_HELD=false
}

collect_staged_merge_file_summary() {
  local staged_tree=""

  staged_tree="$(git write-tree 2>/dev/null)" || return 1
  bt_git_collect_ref_change_summary HEAD "$staged_tree"
  MERGE_UPDATED_FILES="$BT_CHANGE_MODIFIED_FILES"
  MERGE_DELETED_FILES="$BT_CHANGE_DELETED_FILES"
  MERGE_ADDED_FILES="$BT_CHANGE_ADDED_FILES"
  MERGE_RENAMED_FILES="$BT_CHANGE_RENAMED_FILES"
  MERGE_RENAMED_MODIFIED_FILES="$BT_CHANGE_RENAMED_MODIFIED_FILES"
  MERGE_DELETED_DIRECTORIES="$BT_CHANGE_DELETED_DIRECTORIES"
  MERGE_ADDED_DIRECTORIES="$BT_CHANGE_ADDED_DIRECTORIES"
  MERGE_RENAMED_DIRECTORIES="$BT_CHANGE_RENAMED_DIRECTORIES"
  MERGE_FILE_SUMMARY_TEXT="$(bt_format_change_summary)"
}

cleanup_success_transient_reports() {
  REPORT_FILE=""
  acquire_report_lock
  enable_reports_write_access
  cleanup_old_transient_reports
  disable_reports_write_access
  release_report_lock
}

cleanup_old_transient_reports() {
  bt_report_cleanup_transient_reports \
    "$REPORTS_DIR" \
    "$CURRENT_BRANCH" \
    "$REPORT_FILE" \
    "pulldown-d-*.md" \
    "pulldown-e-*.md"
}

generate_dry_run_report() {
  local parent_branch="$1"
  local merge_message="$2"
  local commits_merged="$3"
  local command_text
  local staged_report_file=""

  command_text="$(format_command_line)"
  acquire_report_lock
  enable_reports_write_access

  REPORT_FILE="$(bt_report_transient_path "$REPORTS_DIR" "pulldown-d" \
    "$RUN_TS_FILE")"
  if ! bt_report_create_staging_file "$REPORT_FILE" staged_report_file; then
    bt_error_exit "$EXIT_CONFIG_ERROR" "Failed to stage dry-run report"
  fi

  if ! {
    bt_report_write_header "$staged_report_file" "Merge Report" \
      "$RUN_TS_DISPLAY" "$command_text"
    cat >> "$staged_report_file" <<EOF
**Branch:** \`${CURRENT_BRANCH}\`

**Merge Commit Hash:** n/a (dry-run)

**Merge Comment:** ${merge_message}

**Mode:** dry-run

## Merge

| Branch | Parent Branch | Parent Commits Integrated | Merge Commit Hash |
| --- | --- | --- | --- |
| ${CURRENT_BRANCH} | ${parent_branch} | ${commits_merged} | n/a |

EOF
  }; then
    bt_report_discard_staged_file "$staged_report_file"
    bt_error_exit "$EXIT_CONFIG_ERROR" "Failed to write dry-run report"
  fi
  if ! bt_report_publish_staged_file "$staged_report_file" "$REPORT_FILE"; then
    bt_report_discard_staged_file "$staged_report_file"
    bt_error_exit "$EXIT_CONFIG_ERROR" "Failed to publish dry-run report"
  fi
  cleanup_old_transient_reports

  disable_reports_write_access
  release_report_lock
}

generate_error_report() {
  local message="$1"
  local code="$2"
  local command_text
  local staged_report_file=""

  command_text="$(format_command_line)"
  acquire_report_lock
  enable_reports_write_access

  REPORT_FILE="$(bt_report_transient_path "$REPORTS_DIR" "pulldown-e" \
    "$RUN_TS_FILE")"
  if ! bt_report_create_staging_file "$REPORT_FILE" staged_report_file; then
    return 1
  fi

  if ! {
    bt_report_write_header "$staged_report_file" "Merge Error Report" \
      "$RUN_TS_DISPLAY" "$command_text"
    cat >> "$staged_report_file" <<EOF
**Branch:** \`${CURRENT_BRANCH:-unknown}\`

**Parent Branch:** ${PARENT_BRANCH:-unknown}

**Exit Code:** ${code}

**Error:** ${message}

## Guidance

- Run without -e option.

EOF
  }; then
    bt_report_discard_staged_file "$staged_report_file"
    return 1
  fi
  if ! bt_report_publish_staged_file "$staged_report_file" "$REPORT_FILE"; then
    bt_report_discard_staged_file "$staged_report_file"
    return 1
  fi
  cleanup_old_transient_reports

  disable_reports_write_access
  release_report_lock
}


bt_info() {
  if [[ "$VERBOSE" == true ]]; then
    printf '%s\n' "$(bt_ensure_trailing_period "$1")"
  fi
}

bt_success() {
  printf '%s\n' "$(bt_ensure_trailing_period "$1")"
}

bt_warn() {
  printf '%s\n' "$(bt_ensure_trailing_period "$1")"
}

bt_error_exit() {
  local code="$1"
  local message="$2"

  if [[ "$OPERATION_STARTED" == true && \
    "$ERROR_REPORT_WRITTEN" == false ]]; then
    ERROR_REPORT_WRITTEN=true
    generate_error_report "$message" "$code" >/dev/null 2>&1 || true
  fi

  bt_emit_error "$message"
  exit "$code"
}

skip_merge_down_and_exit() {
  local message="Merge down skipped due to -e option."
  local guidance="Run without -e option."

  generate_error_report "$message" "$EXIT_WORKFLOW_SKIPPED" >/dev/null 2>&1 || true
  bt_emit_error "$message"
  bt_emit_guidance "$guidance"
  bt_success "See ${REPORT_FILE#"${REPO_ROOT}"/} for details."
  exit "$EXIT_WORKFLOW_SKIPPED"
}

format_command_line() {
  local pushup_command=""

  if [[ "$PUSHUP_SYNC" == true ]]; then
    pushup_command="$(state_get_pushup_value command-line)"
    [[ -n "$pushup_command" ]] || \
      bt_error_exit "$EXIT_INTERNAL_ERROR" \
        "Active pushup state is missing its initiating command"
    printf '%s\n' "$pushup_command"
    return 0
  fi
  bt_format_command_line "pulldown" "${ORIGINAL_ARGS[@]}"
}

state_get_pushup_value() {
  local key="$1"
  local state_file=""

  state_file="$(git rev-parse --git-path briteRepo/pushup.state \
    2>/dev/null || true)"
  [[ -f "$state_file" ]] || return 0
  git config --file "$state_file" --get "pushup.$key" 2>/dev/null || true
}

ensure_clean_worktree() {
  if bt_is_worktree_dirty; then
    bt_emit_prerequisite_failure "$EXIT_NOT_FOUND" \
      "Current branch has uncommitted changes." \
      "commit or undo changes, then rerun pulldown."
  fi
}

auto_resolve_history_log_conflicts() {
  local conflicted_files="$1"
  local file=""
  local remaining_conflicts=""

  [[ -n "$conflicted_files" ]] || return 1

  # Only auto-resolve known pushup/pulldown history artifacts.
  while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    if [[ ! "$file" =~ ^logs/.+_history\.md$ ]]; then
      return 1
    fi
  done <<< "$conflicted_files"

  while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    if ! git checkout --theirs -- "$file" >/dev/null 2>&1; then
      if ! git checkout --ours -- "$file" >/dev/null 2>&1; then
        return 1
      fi
    fi

    if ! git add "$file" >/dev/null 2>&1; then
      return 1
    fi
  done <<< "$conflicted_files"

  remaining_conflicts="$(git diff --name-only --diff-filter=U 2>/dev/null \
    || true)"
  [[ -z "$remaining_conflicts" ]]
}

get_repository_owner_login() {
  bt_resolve_repo_owner_login_or_empty
}

is_repository_owner() {
  local user_name="$1"

  bt_is_repository_owner_login "$user_name"
}

is_pushup_source_sync() {
  local state_file=""
  local state_version=""
  local state_source=""
  local state_parent=""
  local state_phase=""

  [[ "$PUSHUP_SYNC" == true ]] || return 1
  state_file="$(git rev-parse --git-path briteRepo/pushup.state 2>/dev/null || true)"
  [[ -f "$state_file" ]] || return 1
  state_version="$(git config --file "$state_file" --get pushup.version 2>/dev/null || true)"
  state_source="$(git config --file "$state_file" --get pushup.source 2>/dev/null || true)"
  state_parent="$(git config --file "$state_file" --get pushup.parent 2>/dev/null || true)"
  state_phase="$(git config --file "$state_file" --get pushup.phase 2>/dev/null || true)"

  [[ "$state_version" == 2 && "$state_source" == "$CURRENT_BRANCH" && \
    "$state_parent" == "$PARENT_BRANCH" ]] || return 1
  [[ "$state_phase" == source-selected || "$state_phase" == source-sync-failed ]]
}

pushup_saved_parent() {
  local state_file=""
  local state_source=""
  local state_parent=""
  local state_phase=""

  [[ "$PUSHUP_SYNC" == true ]] || return 1
  state_file="$(git rev-parse --git-path briteRepo/pushup.state 2>/dev/null || true)"
  [[ -f "$state_file" ]] || return 1
  state_source="$(git config --file "$state_file" --get pushup.source 2>/dev/null || true)"
  state_parent="$(git config --file "$state_file" --get pushup.parent 2>/dev/null || true)"
  state_phase="$(git config --file "$state_file" --get pushup.phase 2>/dev/null || true)"
  [[ "$state_source" == "$CURRENT_BRANCH" && -n "$state_parent" ]] || return 1
  [[ "$state_phase" == source-selected || "$state_phase" == source-sync-failed ]] || return 1
  printf '%s\n' "$state_parent"
}

pushup_uses_local_parent() {
  local state_file=""
  local parent_has_remote=""

  is_pushup_source_sync || return 1
  state_file="$(git rev-parse --git-path briteRepo/pushup.state 2>/dev/null || true)"
  parent_has_remote="$(git config --file "$state_file" \
    --get pushup.parent-has-remote 2>/dev/null || true)"
  [[ "$parent_has_remote" == false ]]
}


# Establish the library's own runtime state before callers override it.
bt_pulldown_init() {
  VERBOSE=false
  CUSTOM_MESSAGE=""
  OWNER_OVERRIDE=false
  OWNER_OVERRIDE_ACTIVE=false
  DRY_RUN=false
  ERROR_RUN=false
  REMOTE_TIMEOUT_SECONDS=10
  CONTINUING_MERGE=false
  PUSHUP_SYNC=false
}

# Run the merge-down workflow for the validated globals set by the caller.
bt_pulldown_run() {
export BT_REMOTE_TIMEOUT_SECONDS="$REMOTE_TIMEOUT_SECONDS"

if [[ "$ERROR_RUN" == true ]]; then
  skip_merge_down_and_exit
fi

if [[ -n "$CUSTOM_MESSAGE" ]]; then
  CUSTOM_MESSAGE="$(bt_trim_whitespace "$CUSTOM_MESSAGE")"
  if [[ -z "$CUSTOM_MESSAGE" ]]; then
    usage_error "Commit comment must include at least one non-whitespace character"
  fi
fi

# Get current branch
CURRENT_BRANCH=$(bt_get_current_branch || \
  bt_error_exit "$EXIT_NOT_FOUND" "Failed to determine current branch")
if bt_is_current_internal_remote_copy; then
  bt_emit_prerequisite_failure "$EXIT_NOT_FOUND" \
    "Current branch '$CURRENT_BRANCH' is a read-only remote copy." \
    "use 'chbranch -r $CURRENT_BRANCH' to refresh it, or switch to a local branch."
fi
if [[ "$VERBOSE" == true ]]; then
  bt_info "Current local branch $CURRENT_BRANCH."
fi

if bt_is_copyfix_in_progress "$CURRENT_BRANCH"; then
  bt_emit_prerequisite_failure "$EXIT_OPERATION_FAILED" \
    "Current branch '$CURRENT_BRANCH' has an unfinished copyfix operation." \
    "rerun copyfix to complete it before rerunning pulldown."
fi

if [[ "$OWNER_OVERRIDE" == true ]]; then
  CURRENT_USER="$(bt_require_login || true)"
  if [[ -z "$CURRENT_USER" ]]; then
    bt_error_exit "$EXIT_NOT_FOUND" \
      "Option -o requires a resolvable GitHub login"
  fi
  if is_repository_owner "$CURRENT_USER"; then
    OWNER_OVERRIDE_ACTIVE=true
    bt_info "Owner override enabled for repository owner '$CURRENT_USER'"
  else
    bt_error_exit "$EXIT_CONFIG_ERROR" \
      "Option -o is allowed only for the repository owner"
  fi
fi

if bt_is_protected_branch "$CURRENT_BRANCH" && \
  [[ "$OWNER_OVERRIDE_ACTIVE" != true && "$PUSHUP_SYNC" != true ]]; then
  bt_emit_prerequisite_failure "$EXIT_CONFIG_ERROR" \
    "Cannot sync up on protected branch '$CURRENT_BRANCH'." \
    "use pushup to merge changes to this branch."
fi

# Determine parent branch before validating an internal pushup continuation.
bt_info "Determining parent branch..."
if ! PARENT_BRANCH="$(pushup_saved_parent)"; then
  PARENT_BRANCH=$(bt_resolve_parent_branch "$CURRENT_BRANCH" "main")
fi
if [[ -z "$PARENT_BRANCH" ]]; then
  bt_error_exit "$EXIT_INTERNAL_ERROR" "Failed to determine parent branch"
fi
bt_info "Parent branch: $PARENT_BRANCH"

if bt_git_workflow_marker_matches pulldown "$CURRENT_BRANCH" && \
  git rev-parse -q --verify MERGE_HEAD >/dev/null 2>&1; then
  CONTINUING_MERGE=true
  if ! bt_git_stage_resolved_rebase_files || \
    [[ -n "$(git diff --name-only --diff-filter=U 2>/dev/null || true)" ]]; then
    bt_emit_prerequisite_failure "$EXIT_OPERATION_FAILED" \
      "Pulldown still has unresolved conflicts on '$CURRENT_BRANCH'." \
      "resolve the remaining conflicts and rerun pulldown."
  fi
fi

# Check if branch is protected
if bt_is_protected_branch "$CURRENT_BRANCH"; then
  if [[ "$OWNER_OVERRIDE_ACTIVE" == true ]]; then
    bt_warn \
      "Owner override enabled: allowing sync on protected branch '$CURRENT_BRANCH'"
  elif is_pushup_source_sync; then
    bt_info "Allowing protected source synchronization for active pushup"
  else
    bt_emit_prerequisite_failure "$EXIT_CONFIG_ERROR" \
      "Cannot sync up on protected branch '$CURRENT_BRANCH'." \
      "use pushup to merge changes to this branch."
  fi
fi

if [[ "$CONTINUING_MERGE" == false ]]; then
  ensure_clean_worktree
fi

# Ensure parent branch exists and select its source.
PARENT_SOURCE_REF="origin/$PARENT_BRANCH"
if pushup_uses_local_parent; then
  PARENT_SOURCE_REF="$PARENT_BRANCH"
else
  bt_info "Fetching latest from remote..."
  if ! bt_run_remote_command git fetch origin "$PARENT_BRANCH" \
    >/dev/null 2>&1; then
    bt_error_exit "$EXIT_NOT_FOUND" \
      "Failed to fetch parent branch '$PARENT_BRANCH' from remote"
  fi
fi

# Count commits from parent branch to current branch
commits_to_merge=""
commits_to_merge=$(git rev-list --count "HEAD..$PARENT_SOURCE_REF" \
  2>/dev/null || echo "0")

if [[ "$commits_to_merge" == "0" ]]; then
  bt_emit_prerequisite_failure "$EXIT_NOTHING_TO_MERGE" \
    "Parent branch '$PARENT_BRANCH' has no changes to merge into '$CURRENT_BRANCH'." \
    "rerun pulldown after parent changes are available."
fi

bt_info "Commits to merge: $commits_to_merge"

# Determine merge message
if [[ -z "$CUSTOM_MESSAGE" ]]; then
  MERGE_MESSAGE="Merge $PARENT_BRANCH into $CURRENT_BRANCH"
else
  MERGE_MESSAGE="$CUSTOM_MESSAGE"
fi

if [[ "$DRY_RUN" == true ]]; then
  generate_dry_run_report "$PARENT_BRANCH" "$MERGE_MESSAGE" "$commits_to_merge"
  bt_success "Dry-run: merge $PARENT_BRANCH -> $CURRENT_BRANCH"
  if [[ -n "$REPORT_FILE" ]]; then
    report_rel="${REPORT_FILE#"${REPO_ROOT}"/}"
    bt_success "See ${report_rel} for details."
  fi
  exit 0
fi

# Perform merge without auto-commit so hooks cannot block the merge commit path.
bt_info "Merging $PARENT_BRANCH into $CURRENT_BRANCH..."
OPERATION_STARTED=true
PULLDOWN_BEFORE_TIP="$(git rev-parse HEAD 2>/dev/null || true)"
if [[ "$CONTINUING_MERGE" == false ]]; then
  bt_git_mark_workflow_in_progress pulldown "$CURRENT_BRANCH" || \
    bt_error_exit "$EXIT_OPERATION_FAILED" \
      "Failed to record pulldown progress for '$CURRENT_BRANCH'"
fi
if [[ "$CONTINUING_MERGE" == false ]] && \
  ! git merge --no-commit --no-ff "$PARENT_SOURCE_REF" >/dev/null 2>&1; then
  # Check if merge failed due to conflicts
  conflicted_files=$(git diff --name-only --diff-filter=U)
  if [[ -n "$conflicted_files" ]]; then
    if auto_resolve_history_log_conflicts "$conflicted_files"; then
      bt_warn "Auto-resolved history log conflicts from parent branch"
    else
    bt_warn "Merge conflicts detected"
    bt_info "Complex conflicts require manual resolution"
    bt_info "Conflicted files:"
    while IFS= read -r file; do
      [[ -n "$file" ]] && echo "  $file"
    done <<< "$conflicted_files"
    bt_info "Steps to resolve:"
    echo "  1. Edit conflicted files to resolve conflicts"
    echo "  2. Rerun pulldown to stage resolved files and complete the merge"
    bt_error_exit "$EXIT_OPERATION_FAILED" \
      "Merge stopped - manual conflict resolution needed"
    fi
  else
    bt_error_exit "$EXIT_NOT_FOUND" \
      "Failed to merge $PARENT_BRANCH into $CURRENT_BRANCH"
  fi
fi

collect_staged_merge_file_summary

workflow_context_metadata=""
if [[ "$PUSHUP_SYNC" == true ]]; then
  pushup_authority=""
  pushup_note="$(git notes --ref=briteRepo-workflow show \
    "$PARENT_SOURCE_REF" 2>/dev/null || true)"
  if [[ "$(state_get_pushup_value owner-override)" == true ]]; then
    pushup_authority="owner"
  fi
  [[ -z "$pushup_authority" ]] || \
    workflow_context_metadata+=$'Authority: '"$pushup_authority"$'\n'
  if [[ "$(bt_workflow_note_field "$pushup_note" "Workflow-Type")" == \
    "pushup" && \
    "$(bt_workflow_note_field "$pushup_note" "Source-Branch")" == \
    "$CURRENT_BRANCH" && \
    "$(bt_workflow_note_field "$pushup_note" "Target-Branch")" == \
    "$PARENT_BRANCH" ]]; then
    pushup_pr="$(bt_workflow_note_field "$pushup_note" "PR")"
    pushup_ci_cd="$(bt_workflow_note_field "$pushup_note" "CI-CD")"
    [[ -z "$pushup_pr" ]] || \
      workflow_context_metadata+=$'PR: '"$pushup_pr"$'\n'
    [[ -z "$pushup_ci_cd" ]] || \
      workflow_context_metadata+=$'CI-CD: '"$pushup_ci_cd"$'\n'
  fi
fi

if ! GIT_BYPASS_HOOKS=true git commit -m "$MERGE_MESSAGE" \
  -m "## Workflow Metadata

Command-Line: $(format_command_line)
Command-Source: user
Workflow-Type: pulldown
${workflow_context_metadata}Source-Branch: $PARENT_BRANCH
Target-Branch: $CURRENT_BRANCH
Parent-Commits-Integrated: $commits_to_merge
Files-Modified: $MERGE_UPDATED_FILES
Files-Added: $MERGE_ADDED_FILES
Files-Deleted: $MERGE_DELETED_FILES
Files-Renamed: $MERGE_RENAMED_FILES
Files-Renamed-Modified: $MERGE_RENAMED_MODIFIED_FILES
Directories-Deleted: $MERGE_DELETED_DIRECTORIES
Directories-Added: $MERGE_ADDED_DIRECTORIES
Directories-Renamed: $MERGE_RENAMED_DIRECTORIES
Status: Parent branch merged into current branch
Method: Merge commit (--no-ff) created by pulldown" >/dev/null 2>&1; then
  bt_error_exit "$EXIT_NOT_FOUND" \
    "Merge applied, but failed to create merge commit"
fi

bt_git_clear_workflow_in_progress pulldown
bt_undo_record_operation pulldown "$CURRENT_BRANCH" "$PULLDOWN_BEFORE_TIP" \
  "$(git rev-parse HEAD)" hard-reset \
  "Merged $PARENT_BRANCH into $CURRENT_BRANCH" >/dev/null || \
  bt_warn "Pulldown completed, but undo metadata could not be recorded"

# Show merge details if verbose
if [[ "$VERBOSE" == true ]]; then
  bt_info "Merge details:"
  git log -1 --oneline | sed 's/^/  /'
fi

cleanup_success_transient_reports

if [[ "$MERGE_FILE_SUMMARY_TEXT" == "no changes" ]]; then
  synchronized_tip_short="$(git rev-parse --short=7 HEAD 2>/dev/null || true)"
  bt_success \
    "Synchronized (${synchronized_tip_short}) parent '$PARENT_BRANCH' with '$CURRENT_BRANCH': no file or directory changes."
else
  bt_success \
    "Merged parent '$PARENT_BRANCH' into '$CURRENT_BRANCH': ${MERGE_FILE_SUMMARY_TEXT}."
fi
bt_success "Run report for details."
exit 0
}
