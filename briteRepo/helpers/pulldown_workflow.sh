#!/usr/bin/env bash

# pulldown_workflow.sh - Internal merge-down workflow implementation.
#
# See usage below for details, or run: pulldown -h
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see '<repo>/LICENSE'.

usage() {
  cat <<'EOF'
Usage:
  pulldown [OPTIONS] [-- TOKEN...]
  pulldown {-h | --help}

Merge the parent branch of the current branch into the current branch
to sync with latest changes.

Automatically determines the parent branch based on branch naming
and Git history (the branch that the current branch was created
from). Handles simple conflicts automatically and provides
instructions for complex ones.

Prerequisites:
  - The current branch must have no uncommitted changes.
  - If there are changes, use the commit or undo workflow first.
  - The current branch must not have an unfinished copyfix operation.

Protected branches (cannot run pulldown):
  - main
  - v<M>.<m>.0 version branches created from main.

Allowed branches (can use pulldown):
  - Unprotected branches with an identified parent branch.

Features:
  - Automatically determines parent branch
  - Merges parent branch into current branch
  - Synchronizes content-equivalent parent history without presenting it as
    file or directory changes
  - Shows instructions for complex conflicts

Options:
  -c TOKEN           Merge commit comment from TOKEN.
  -- TOKEN...        Merge commit comment from one or more tokens.
  -d                 Dry-run for the merge workflow. The script does not
                     create the merge commit, but it still generates the
                     report and may delete stale dry-run reports.
  -h, --help  Output this help to stdout and exit (other options and
              arguments are ignored).
  -o                 Owner override. Allows repository owner to run even
                     on version branches normally blocked by user policy
                     for this command run only; normal role restrictions
                     apply again after exit.
  -t SEC             Remote operation timeout in seconds (default: 10).
                     SEC must be an integer greater than 0.
  -v                 Output progress and diagnostics to stdout.

  For merge commit comment options '-c TOKEN' and '-- TOKEN...':
    - These options are mutually exclusive.
    - If not specified, the default commit comment is used.
    - For '-- TOKEN...', '--' must be a separate token.
    - Comment text is built by joining tokens with a single space.
    - For a quoted token, whitespace in the token is preserved and the
      quotes are removed.
    - The resulting merge commit comment from TOKEN or TOKEN... must include
      at least one non-whitespace character.

  If a commit comment is not specified, the default commit comment is:
    "Merge <parent_branch> into <current_branch>"

Examples:
  # Merge down.
  pulldown

  # Merge down with verbose output.
  pulldown -v

Outputs:
  - Writes help text, status messages, and results or summaries to stdout.
  - Writes errors and diagnostics to stderr.
  - No-work prerequisite failures do not generate or delete reports.
  - After a successful non-dry-run pulldown, records history for the report
    command and writes 'Run report for details.' to stdout. It does not write
    an immediate merge report.
  - A dry-run report is written (untracked) locally to:
        <repo>/reports/pulldown-d-<datetime>.md
  - If a non-dry-run operation fails after merge work starts, writes an
    untracked error report to:
        <repo>/reports/pulldown-e-<datetime>.md
    Usage and prerequisite failures do not create reports.

Exit codes:
  0     Success.
  1     Invalid option or argument.
  2     Conflicts detected (user must resolve).
  3     Branch is protected (cannot sync up).
  5     No parent changes are available to merge.
  200   Failed to determine parent branch.
  201   Git merge failed.
EOF
}

# High-Level Flow:
# - Validate actor, current/parent branch policy, worktree, and remote state.
# - Reject runs with no parent commits; preview changes and report them for -d.
# - Merge with --no-ff, auto-resolving only known history-log conflicts.
# - Store command, branch, commit-count, and file-count metadata in the merge
#   commit so report can reconstruct the completed action.
# - Write local reports only for dry-run/error paths and clean them on success.

# shellcheck disable=SC1091,SC2317  # Helper source paths and trap-managed
# cleanup paths.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPORTS_DIR="$REPO_ROOT/reports"
RUN_TS_FILE="$(date '+%Y%m%d-%H%M%S%z')"
RUN_TS_DISPLAY="$(date '+%Y-%m-%d %H:%M:%S%z' | sed -E 's/([+-][0-9]{2})([0-9]{2})$/\1:\2/')"
REPORT_FILE=""
[[ "${1:-}" == "--public" || "${1:-}" == "--pushup" || \
  "${1:-}" == "--error-run" ]] || {
  echo "pulldown_workflow.sh must be called by a briteRepo command." >&2
  exit 1
}
ENTRY_MODE="$1"
shift
ORIGINAL_ARGS=("$@")
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

  command_text="$(format_command_line)"
  acquire_report_lock
  enable_reports_write_access

  REPORT_FILE="$(bt_report_transient_path "$REPORTS_DIR" "pulldown-d" \
    "$RUN_TS_FILE")"
  cleanup_old_transient_reports

  bt_report_write_header "$REPORT_FILE" "Merge Report" \
    "$RUN_TS_DISPLAY" "$command_text"
  cat >> "$REPORT_FILE" <<EOF
**Branch:** \`${CURRENT_BRANCH}\`

**Merge Commit Hash:** n/a (dry-run)

**Merge Comment:** ${merge_message}

**Mode:** dry-run

## Merge

| Branch | Parent Branch | Parent Commits Integrated | Merge Commit Hash |
| --- | --- | --- | --- |
| ${CURRENT_BRANCH} | ${parent_branch} | ${commits_merged} | n/a |

EOF

  disable_reports_write_access
  release_report_lock
}

generate_error_report() {
  local message="$1"
  local code="$2"
  local command_text

  command_text="$(format_command_line)"
  acquire_report_lock
  enable_reports_write_access

  REPORT_FILE="$(bt_report_transient_path "$REPORTS_DIR" "pulldown-e" \
    "$RUN_TS_FILE")"
  cleanup_old_transient_reports

  bt_report_write_header "$REPORT_FILE" "Merge Error Report" \
    "$RUN_TS_DISPLAY" "$command_text"
  cat >> "$REPORT_FILE" <<EOF
**Branch:** \`${CURRENT_BRANCH:-unknown}\`

**Parent Branch:** ${PARENT_BRANCH:-unknown}

**Exit Code:** ${code}

**Error:** ${message}

## Guidance

- Run without -e option.

EOF

  disable_reports_write_access
  release_report_lock
}

usage_error() {
  local message="$1"
  usage
  echo >&2
  echo "$message. See usage above for details." >&2
  exit "$EXIT_INVALID_ARGUMENT"
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

# Default options
VERBOSE=false
CUSTOM_MESSAGE=""
OWNER_OVERRIDE=false
OWNER_OVERRIDE_ACTIVE=false
DRY_RUN=false
ERROR_RUN=false
REMOTE_TIMEOUT_SECONDS=10
CONTINUING_MERGE=false
if [[ "$ENTRY_MODE" == "--pushup" ]]; then
  PUSHUP_SYNC=true
elif [[ "$ENTRY_MODE" == "--error-run" ]]; then
  ERROR_RUN=true
fi

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

# Parse options and arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    -d)
      if [[ "$ERROR_RUN" == true ]]; then
        usage_error "Options -d and -e are mutually exclusive."
      fi
      DRY_RUN=true
      shift
      ;;
    -f | --force)
      shift
      ;;
    -o)
      OWNER_OVERRIDE=true
      shift
      ;;
    -t)
      [[ $# -ge 2 ]] || usage_error "Option -t requires SEC"
      bt_is_valid_remote_timeout "$2" || \
        usage_error "SEC for -t must be an integer greater than 0"
      REMOTE_TIMEOUT_SECONDS="$2"
      shift 2
      ;;
    -v | --verbose)
      VERBOSE=true
      shift
      ;;
    -c)
      if [[ $# -lt 2 ]]; then
        usage_error "Option $1 requires a commit comment argument"
      fi
      if [[ -n "$CUSTOM_MESSAGE" ]]; then
        usage_error "Cannot use both single-token comment option and -- for "\
      "commit comment"
      fi
      CUSTOM_MESSAGE="$2"
      shift 2
      ;;
    --)
      # '-- TOKEN...' commit comment
      shift
      if [[ -n "$CUSTOM_MESSAGE" ]]; then
        usage_error "Cannot use both single-token comment option and -- for "\
      "commit comment."
      fi
      CUSTOM_MESSAGE="$*"
      break
      ;;
    -*)
      usage_error "Unknown option: $1"
      ;;
    *)
      usage_error "Unknown argument: $1"
      ;;
  esac
done

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
