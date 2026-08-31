#!/usr/bin/env bash

# Internal parent-preparation engine for pushup.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see '<repo>/LICENSE'.

usage() {
  cat <<'EOF'
Usage:
  pushup [OPTIONS] [-- TOKEN...]
  pushup {-h | --help}

Merge the current branch up to its local parent branch. The merge remains local
until push is run from the parent branch.

Use the -d option to preview the local merge without applying it.

See the Contributor Guide for workflow details and role descriptions.
See the Glossary Reference for branch type definitions and other definitions.

Prerequisites:
  - If specified, a commit comment must contain a non-whitespace character.
  - Branch eligibility:
    - The current branch must be a contributor, targeted, or version branch.
    - If the current branch is a contributor branch, the -o option must not
      be specified, its parent branch must be a contributor or targeted
      branch, and the user must be a contributor, reviewer, or approver.
    - If the current branch is a targeted branch, its parent branch must be
      a version branch. If -o is specified, the user must be the repository
      owner; otherwise, the user must be a contributor, reviewer, or approver
      and the PR must be approved for the current commit.
    - If the current branch is a version branch, its parent branch must be
      the main branch, and the user must be an approver.
  - Local/remote and branch synchronization:
    - The current branch must be a local branch with no uncommitted changes.
      Use the commit or undo commands to commit or undo local changes before
      running pushup.
    - The current branch must not have an unfinished copyfix operation.
    - The current branch must not be behind file changes on its parent branch.
      Parent-only commits that leave the parent's file content unchanged are
      accepted and incorporated by pushup. Otherwise, use pulldown first.
    - The parent branch for the current branch must exist locally and be
      available for checkout.
    - A protected branch (either the current branch or its parent branch) must
      have a corresponding remote branch.
    - If a branch (either the current or its parent branch) has a remote branch:
      - The remote (origin) must be connected and reachable within -t SEC (or
        the default of 10 seconds).
    - The local branch must match its remote exactly; it cannot be ahead,
      behind, or diverged. Use the pull and push commands to synchronize
      a local branch with its remote branch before running pushup.
  - PR requirements:
    - With -o, a PR is optional for merges up to a version branch.
    - Without -o, a PR is required for merges up to a version branch.
    - A PR is optional for a merge up to a contributor or targeted branch,
      and for a merge from a version branch up to main.
    - If an associated PR exists, it must be open, not draft, head=current
      branch, base=parent branch, have no outstanding Changes Requested,
      be approved, and not already be merged.

Pushup behavior:
  - Combines changes into a single commit on the local parent branch.
  - Leaves the local parent branch checked out for review and testing.
  - Does not modify local source branches, remote branches, or PR state.
  - Records source branch and PR metadata for push to use when pushing.
  - CI/CD results attached to an associated PR are copied into reports when
    available.
  - After pushup, the source and parent histories normally diverge even though
    the source changes were merged.
  - A new source commit after approval requires review and approval again
    before pushup can run.
  - An approved contributor can run pushup from the source clone, then run push
    from the parent branch. push verifies the same source commit is still
    approved before updating the parent.
  - If another user pushes the parent first, return to the source branch, run
    pulldown, obtain approval for the updated source commit, then rerun pushup
    and push.
  - Review and test the parent, then run push from the parent. If development
    continues on the source branch, change back to it and run pulldown only
    after the parent has been pushed.

Options:
  -c TOKEN           Commit comment from TOKEN.
  -- TOKEN...        Commit comment from one or more tokens.
  -d                 If prerequisite checks pass, preview the merge and
                     local changes. No merge commit or history update is
                     created. Dry-run reports are generated, and applicable
                     failure exit codes are returned.
  -h, --help  Output this help to stdout and exit (other options and
              arguments are ignored).
  -o                 Repository-owner override for a merge to a version parent.
                     Bypasses the approver and required-PR checks for this run.
  -t SEC             Remote reachability timeout in seconds (default: 10).
                     SEC must be an integer greater than zero.
  -v                 Output progress and diagnostics to stdout.

  For commit comment options '-c TOKEN' and '-- TOKEN...':
    - These options are mutually exclusive.
    - For '-- TOKEN...', '--' must be a separate token.
    - Commit comment is built by joining tokens with a single space.
    - For a quoted token, whitespace in the token is preserved and the
      quotes are removed.
    - For example, the following both have the same commit comment:
        pushup -- do "  keep   this spacing  " for commit comment.
        pushup -c "do   keep   this spacing   for commit comment."
    - The resulting commit comment from TOKEN or TOKEN... must include at least
      one non-whitespace character.
    - Always ensure that the commit comment accurately reflects the changes
      being committed to the parent branch.

If a commit comment is not specified, pushup uses the PR title when
available; otherwise, a default commit comment is used:
  - pushup with -o option merging a targeted branch up to its
    corresponding parent version branch:
        "<targeted_branch> merged to <parent_branch> by owner <user>."
  - Approver merging a version branch up to the main branch:
        "<version_branch> merged to main branch by approver <user>."
  - Contributor merging a contributor branch up to a targeted or
    contributor branch:
        "<contributor_branch> merged to <parent_branch> by contributor <user>."

Common failure reasons:
  - Uncommitted changes.
  - Non-synchronized local/remote branches.
  - Missing PR or unexpected PR state.
  - Unreachable remote.

Examples:
  # Merge a targeted branch to its parent version branch, using the PR title
  # as the commit comment.
  pushup

  # Preview the merge.
  pushup -d

  # Merge with a '-c' commit comment.
  pushup -c "My commit comment."

  # Merge with a '--' commit comment.
  pushup -- "Merge parser fixes."

  # Merge with verbose output.
  pushup -v

Outputs:
  - Writes help text, status messages, and results or summaries to stdout.
  - Writes errors and diagnostics to stderr.
  - No reports are written when there are usage or prerequisite failures.
    Older dry-run and error reports for the current branch are not deleted.
  - No-work prerequisite failures do not generate or delete reports.
  - After a successful non-dry-run pushup, records workflow metadata for the
    report command, leaves the parent checked out, and tells the user to run
    report locally or push when ready. It does not write an immediate merge
    report.
  - If a non-dry-run operation fails after merge work starts, an
    untracked error report is written locally at:
      <repo>/reports/pushup-e-<datetime>.md
  - If -d was specified, an untracked dry-run report is written locally at:
        <repo>/reports/pushup-d-<datetime>.md
  - When a dry-run or error report is written,
    older pushup dry-run/error reports for the current branch are removed.
  - CI/CD results if available from an associated PR are included in dry-run
    and error reports and the successful PR comment.

Exit codes:
  0    Success, successful dry-run, or help requested.
  1    Invalid option or argument.
  2    Commit comment is specified but is empty after whitespace normalisation.
  3    The current branch is not a contributor, targeted, or version branch.
  4    The current branch is a contributor branch but its parent branch is
       not a contributor or targeted branch.
  5    The current branch is a targeted branch but its parent branch is not
       a version branch.
  6    The current branch is a version branch but its parent branch is not
       the main branch.
  7    The -o option is specified but the user is not the repository owner.
  8    The -o option is specified but the current branch is not a targeted
  branch.
  9    A contributor-branch merge is requested by a user who is not a
  contributor,
       reviewer, or approver.
  10   The user does not have the role required for the requested merge path.
  11   The current branch is not checked out as a local branch.
  12   The current branch has uncommitted changes.
  13   The current branch is behind its parent branch. Use the
       pulldown command to merge the parent branch into the current branch
       before running pushup.
  14   The parent branch for the current branch does not exist locally.
  15   The parent branch for the current branch is not available for
       checkout in this worktree.
  16   The protected current branch does not have a corresponding remote branch.
  17   The protected parent branch does not have a corresponding remote branch.
  18   Remote origin is not configured.
  19   Remote origin is configured but unreachable.
  20   Remote origin did not respond within the -t timeout.
  21   The current branch is behind its remote branch.
  22   The current branch is ahead of its remote branch.
  23   The current branch has diverged from its remote branch.
  24   The parent branch is behind its remote branch.
  25   The parent branch is ahead of its remote branch.
  26   The parent branch has diverged from its remote branch.
  27   No PR found for the current branch. Checked when PR is required
       (merging to a version branch without -o).
  28   PR exists but is not open. Checked when a PR is found.
  29   PR is a draft. Checked when a PR is found.
  30   PR head branch does not match the current branch. Checked when a PR
       is found.
  31   PR base branch does not match the parent branch. Checked when a PR
       is found.
  32   PR has outstanding changes requested. Checked when a PR is found.
  33   PR is not yet approved. Checked when a PR is found.
  34   PR is already merged. Checked when a PR is found.
  35   Another pushup process holds the repository run lock.
  36   Merge-up skipped because -e was specified.
  37   No changes are available to merge into the parent branch.
  38   The current branch has an unfinished copyfix operation.
  39   The PR head commit does not match the current branch commit.
  200  GitHub identity query failed.
  201  A required GitHub PR query failed.
    202  Git operation failed while checking branch state, during the merge,
      or while updating local history.
    203  Merge-up report history could not be generated.
EOF
}

# High-Level Flow:
# - Parse options, acquire the repository lock, and resolve the checked-out
#   current branch, its local parent, actor roles, and remote requirements.
# - Validate worktree, branch synchronization, merge ancestry, and PR state;
#   reject no-work runs and collect available CI/CD results.
# - For -d, preview the local merge, restore the current branch, and write a
#   dry-run report without creating a commit.
# - Otherwise, check out the parent, squash merge, update local history,
#   commit, record one completed event, and leave the parent checked out.
# - On failure, restore the source branch when possible, write an operation
#   error report, restore report permissions, and release the run lock.

# shellcheck disable=SC1091,SC2317  # Helper source paths and trap-managed
# cleanup paths.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Shared helpers
# shellcheck source=helpers/common.sh
source "$SCRIPT_DIR/../helpers/common.sh"
# shellcheck source=helpers/git_helpers.sh
source "$SCRIPT_DIR/../helpers/git_helpers.sh"
# shellcheck source=helpers/github_helpers.sh
source "$SCRIPT_DIR/../helpers/github_helpers.sh"
# shellcheck source=helpers/validation_helpers.sh
source "$SCRIPT_DIR/../helpers/validation_helpers.sh"
# shellcheck source=helpers/history_log.sh
source "$SCRIPT_DIR/../helpers/history_log.sh"
# shellcheck source=helpers/report_helpers.sh
source "$SCRIPT_DIR/../helpers/report_helpers.sh"

readonly EXIT_INVALID_ARGUMENT=1
readonly EXIT_EMPTY_COMMIT_COMMENT=2
readonly EXIT_INVALID_CURRENT_BRANCH=3
readonly EXIT_INVALID_CONTRIBUTOR_PARENT=4
readonly EXIT_INVALID_TARGETED_PARENT=5
readonly EXIT_INVALID_VERSION_PARENT=6
readonly EXIT_NOT_REPOSITORY_OWNER=7
readonly EXIT_OWNER_OVERRIDE_INVALID_BRANCH=8
readonly EXIT_NOT_CONTRIBUTOR=9
readonly EXIT_NOT_APPROVER=10
readonly EXIT_CURRENT_NOT_CHECKED_OUT=11
readonly EXIT_CURRENT_UNCOMMITTED=12
readonly EXIT_CURRENT_BEHIND_PARENT=13
readonly EXIT_PARENT_MISSING=14
readonly EXIT_PARENT_CHECKOUT_FAILED=15
readonly EXIT_CURRENT_PROTECTED_REMOTE_MISSING=16
readonly EXIT_PARENT_PROTECTED_REMOTE_MISSING=17
readonly EXIT_REMOTE_UNCONFIGURED=18
readonly EXIT_REMOTE_UNREACHABLE=19
readonly EXIT_REMOTE_TIMEOUT=20
readonly EXIT_CURRENT_BEHIND_REMOTE=21
readonly EXIT_CURRENT_AHEAD_REMOTE=22
readonly EXIT_CURRENT_DIVERGED_REMOTE=23
readonly EXIT_PARENT_BEHIND_REMOTE=24
readonly EXIT_PARENT_AHEAD_REMOTE=25
readonly EXIT_PARENT_DIVERGED_REMOTE=26
readonly EXIT_PR_MISSING=27
readonly EXIT_PR_NOT_OPEN=28
readonly EXIT_PR_DRAFT=29
readonly EXIT_PR_HEAD_MISMATCH=30
readonly EXIT_PR_BASE_MISMATCH=31
readonly EXIT_PR_HAS_CHANGES_REQUESTED=32
readonly EXIT_PR_NOT_APPROVED=33
readonly EXIT_PR_ALREADY_MERGED=34
readonly EXIT_RUN_LOCKED=35
readonly EXIT_WORKFLOW_SKIPPED=36
readonly EXIT_NOTHING_TO_MERGE=37
readonly EXIT_COPYFIX_IN_PROGRESS=38
readonly EXIT_PR_HEAD_COMMIT_MISMATCH=39
readonly EXIT_GITHUB_IDENTITY_FAILED=200
readonly EXIT_GITHUB_PR_QUERY_FAILED=201
readonly EXIT_GIT_OPERATION_FAILED=202
readonly EXIT_LOCAL_REPORT_FAILED=203
readonly EXIT_PR_CLOSE_FAILED=205

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$REPO_ROOT" ]] || {
  echo "Error: pushup must run in a Git repository." >&2
  exit "$EXIT_INVALID_ARGUMENT"
}
REPORTS_DIR="$REPO_ROOT/reports"
REPORT_FILE=""
REPORT_LOCK_FD=""
ORIGINAL_ARGS=("$@")

usage_error() {
  local message="$1"
  usage
  echo >&2
  echo "$message. See usage above for details." >&2
  exit "$EXIT_INVALID_ARGUMENT"
}

# Default options
CUSTOM_MESSAGE=""
VERBOSE=false
DRY_RUN=false
ERROR_RUN=false
RUN_TS_FILE="$(date '+%Y%m%d-%H%M%S%z')"
OWNER_OVERRIDE=false
OWNER_OVERRIDE_ACTIVE=false
MESSAGE_SOURCE=""
RUN_TS_DISPLAY="$(date '+%Y-%m-%d %H:%M:%S%z' | sed -E 's/([+-][0-9]{2})([0-9]{2})$/\1:\2/')"
CURRENT_SOURCE_REF=""
CURRENT_SOURCE_TIP=""
REMOTE_TIMEOUT_SECONDS=10
PARENT_CHECKOUT_ACTIVE=false
VERIFY_LAST_ERROR=""
VERIFY_FAILURE_KIND=""
CI_CD_REPORT_DETAILS="No associated PR; CI/CD checks were not queried."
APPROVED_SOURCE_TIP=""
LOCK_FILE=""
LOCK_HELD=false
OPERATION_STARTED=false
LAST_ERROR_MESSAGE=""

# Keep informational logs quiet unless verbose mode is requested.
bt_info() {
  local message="$*"

  if [[ "$VERBOSE" == true ]]; then
    printf '%s\n' "$(bt_ensure_trailing_period "$message")"
  fi
}

bt_success() {
  local message="$*"

  printf '%s\n' "$(bt_ensure_trailing_period "$message")"
}

bt_warn() {
  local message="$*"

  printf '%s\n' "$(bt_ensure_trailing_period "$message")"
}

bt_error_exit() {
  local code="$1"
  shift
  local message="$*"

  LAST_ERROR_MESSAGE="$message"
  bt_emit_error "$message"
  exit "$code"
}

bt_emit_guidance_joined() {
  local message="$*"

  bt_emit_guidance "$message"
}

format_command_line() {
  bt_format_command_line "pushup" "${ORIGINAL_ARGS[@]}"
}

current_checked_out_branch() {
  git symbolic-ref -q --short HEAD 2>/dev/null || true
}

bt_run_cmd() {
  if [[ "$VERBOSE" == true ]]; then
    "$@"
  else
    "$@" >/dev/null 2>&1
  fi
}

bt_run_remote_cmd() {
  if [[ "$VERBOSE" == true ]]; then
    bt_run_remote_command "$@"
  else
    bt_run_remote_command "$@" >/dev/null 2>&1
  fi
}

acquire_report_lock() {
  if ! bt_report_acquire_lock "$REPO_ROOT" "pushup" 10 REPORT_LOCK_FD; then
    bt_error_exit "$EXIT_LOCAL_REPORT_FAILED" \
      "Timed out waiting for the pushup report lock"
  fi
}

release_report_lock() {
  bt_report_release_lock "$REPORT_LOCK_FD"
  REPORT_LOCK_FD=""
}

skip_merge_up_and_exit() {
  local message="Merge-up skipped due to -e option."
  local guidance="Run without -e option."

  acquire_report_lock
  bt_report_dir_enable_writes "$REPORTS_DIR" "$EXIT_LOCAL_REPORT_FAILED" >/dev/null 2>&1 || true
  REPORT_FILE="$(bt_report_transient_path "$REPORTS_DIR" "pushup-e" "$RUN_TS_FILE")"
  bt_report_write_header "$REPORT_FILE" "Merge-Up Error Report" "$RUN_TS_DISPLAY" "$(format_command_line)" >/dev/null 2>&1 || true
  cat >> "$REPORT_FILE" <<EOF
**Branch:** \`${CURRENT_BRANCH:-unknown}\`

**Exit Code:** ${EXIT_WORKFLOW_SKIPPED}

**Error:** ${message}

## Guidance

- ${guidance}

EOF
  release_report_lock
  bt_emit_error "$message"
  bt_emit_guidance "$guidance"
  bt_success "See ${REPORT_FILE#"${REPO_ROOT}"/} for details."
  exit "$EXIT_WORKFLOW_SKIPPED"
}

cleanup_old_transient_reports() {
  bt_report_cleanup_transient_reports \
    "$REPORTS_DIR" \
    "$CURRENT_BRANCH" \
    "$REPORT_FILE" \
    "pushup-d-*.md" \
    "pushup-e-*.md"
}

print_merge_change_summary() {
  local commit_sha="$1"
  local change_summary=""

  bt_git_collect_ref_change_summary "${commit_sha}^1" "$commit_sha"
  change_summary="$(bt_format_change_summary)"
  if [[ "$change_summary" == "no changes" ]]; then
    bt_success "Local ${CURRENT_BRANCH} branch: no changes to merge."
    return 0
  fi

  bt_success "Merged to local ${PARENT_BRANCH}: ${change_summary}."
}

format_merge_preview_change_summary_from_commit() {
  local commit_sha="$1"

  bt_git_collect_ref_change_summary "${commit_sha}^1" "$commit_sha"
  bt_format_change_summary
}

build_dry_run_push_preview_ref() {
  local current_branch="$1"
  local parent_branch="$2"
  local parent_tip=""
  local preview_tree=""
  local preview_commit=""

  parent_tip="$(git rev-parse HEAD 2>/dev/null || true)"
  if [[ -z "$parent_tip" ]]; then
    bt_error_exit "$EXIT_GIT_OPERATION_FAILED" \
      "Dry run failed to resolve parent tip while preparing push preview"
  fi

  if ! git merge --squash --no-commit "$current_branch" >/dev/null 2>&1; then
    git reset --hard "$parent_tip" >/dev/null 2>&1 || true
    bt_error_exit "$EXIT_GIT_OPERATION_FAILED" \
      "Dry run failed to prepare squash preview for '$current_branch' to" \
      "'$parent_branch'"
  fi

  preview_tree="$(git write-tree 2>/dev/null || true)"
  if [[ -z "$preview_tree" ]]; then
    git reset --hard "$parent_tip" >/dev/null 2>&1 || true
    bt_error_exit "$EXIT_GIT_OPERATION_FAILED" \
      "Dry run failed to build push preview tree for '$current_branch' to" \
      "'$parent_branch'"
  fi

  preview_commit="$(printf '%s\n' "pushup dry-run preview for $current_branch to $parent_branch" | git commit-tree "$preview_tree" -p "$parent_tip" 2>/dev/null || true)"
  if [[ -z "$preview_commit" ]]; then
    git reset --hard "$parent_tip" >/dev/null 2>&1 || true
    bt_error_exit "$EXIT_GIT_OPERATION_FAILED" \
      "Dry run failed to build push preview commit for '$current_branch' to" \
      "'$parent_branch'"
  fi

  git reset --hard "$parent_tip" >/dev/null 2>&1 || true

  printf '%s\n' "$preview_commit"
}

acquire_run_lock() {
  local lock_path=""
  local existing_pid=""

  lock_path="$(git rev-parse --git-path pushup.run.lock 2>/dev/null || true)"
  if [[ -z "$lock_path" ]]; then
    bt_error_exit "$EXIT_GIT_OPERATION_FAILED" "Unable to resolve repository lock path for pushup"
  fi

  LOCK_FILE="$lock_path"

  if [[ -f "$LOCK_FILE" ]]; then
    existing_pid="$(cat "$LOCK_FILE" 2>/dev/null || true)"
    if [[ "$existing_pid" =~ ^[0-9]+$ ]] && \
      ! kill -0 "$existing_pid" >/dev/null 2>&1; then
      rm -f "$LOCK_FILE" >/dev/null 2>&1 || true
    fi
  fi

  if ( set -o noclobber; printf '%s\n' "$$" > "$LOCK_FILE" ) 2>/dev/null; then
    LOCK_HELD=true
    return 0
  fi

  existing_pid="$(cat "$LOCK_FILE" 2>/dev/null || true)"
  if [[ "$existing_pid" =~ ^[0-9]+$ ]]; then
    bt_error_exit "$EXIT_RUN_LOCKED" \
      "Another pushup run appears active (pid $existing_pid). Verify with" \
      "'ps -p $existing_pid -o comm='. If no pushup process is running," \
      "remove stale lock '.git/pushup.run.lock' and rerun pushup"
  fi

  bt_error_exit "$EXIT_RUN_LOCKED" "Another pushup run appears active. If no run is active, remove " \
    "stale lock '.git/pushup.run.lock' and rerun pushup"
}

release_run_lock() {
  if [[ "$LOCK_HELD" == true && -n "$LOCK_FILE" ]]; then
    if ! rm -f "$LOCK_FILE" >/dev/null 2>&1; then
      echo "Warning: failed to remove pushup lock '$LOCK_FILE'; remove it" \
           "manually before the next run." >&2
      return 1
    fi
    LOCK_HELD=false
  fi

  return 0
}

print_failure_guidance() {
  local exit_code="$1"

  case "$exit_code" in
    "$EXIT_PR_NOT_OPEN"|"$EXIT_PR_DRAFT"|"$EXIT_PR_HEAD_MISMATCH"|\
    "$EXIT_PR_BASE_MISMATCH"|"$EXIT_PR_HAS_CHANGES_REQUESTED"|\
    "$EXIT_PR_NOT_APPROVED"|"$EXIT_PR_ALREADY_MERGED")
      bt_emit_guidance_joined "fix PR state/approval for this branch and rerun pushup"
      ;;
    "$EXIT_CURRENT_NOT_CHECKED_OUT"|"$EXIT_CURRENT_UNCOMMITTED")
      bt_emit_guidance_joined "commit or undo changes, then rerun pushup"
      ;;
    "$EXIT_CURRENT_BEHIND_REMOTE"|"$EXIT_CURRENT_AHEAD_REMOTE"|"$EXIT_CURRENT_DIVERGED_REMOTE"|\
    "$EXIT_PARENT_BEHIND_REMOTE"|"$EXIT_PARENT_AHEAD_REMOTE"|"$EXIT_PARENT_DIVERGED_REMOTE"|\
    "$EXIT_CURRENT_BEHIND_PARENT")
      bt_emit_guidance_joined "sync branches (fetch/rebase or merge parent as" \
                       "needed), resolve divergence, then rerun pushup"
      ;;
    "$EXIT_PARENT_MISSING"|"$EXIT_PARENT_CHECKOUT_FAILED")
      bt_emit_guidance_joined "fetch or create the local parent branch, make it" \
                       "available in this worktree, then rerun pushup"
      ;;
    "$EXIT_CURRENT_PROTECTED_REMOTE_MISSING"|"$EXIT_PARENT_PROTECTED_REMOTE_MISSING")
      bt_emit_guidance_joined "fetch or create the protected remote branch," \
                       "then rerun pushup"
      ;;
    "$EXIT_REMOTE_UNCONFIGURED")
      bt_emit_guidance_joined "configure the origin remote, then rerun pushup"
      ;;
    "$EXIT_REMOTE_UNREACHABLE"|"$EXIT_REMOTE_TIMEOUT")
      bt_emit_guidance_joined "restore remote connectivity (origin) and rerun pushup"
      ;;
    "$EXIT_NOT_REPOSITORY_OWNER"|"$EXIT_OWNER_OVERRIDE_INVALID_BRANCH"|\
    "$EXIT_NOT_CONTRIBUTOR"|"$EXIT_NOT_APPROVER")
      bt_emit_guidance_joined "use an account and merge path authorized by" \
                       "repository policy, then rerun pushup"
      ;;
    "$EXIT_GITHUB_IDENTITY_FAILED"|"$EXIT_GITHUB_PR_QUERY_FAILED")
      bt_emit_guidance_joined "verify GitHub CLI authentication and access, then" \
                       "rerun pushup"
      ;;
    "$EXIT_RUN_LOCKED")
      bt_emit_guidance_joined "wait for the active pushup process to finish, or" \
                       "remove a stale lock after verifying no process is" \
                       "active"
      ;;
    "$EXIT_GIT_OPERATION_FAILED")
      bt_emit_guidance_joined "if merge conflicts occurred, resolve conflicts," \
                       "ensure a clean branch state, then rerun pushup"
      ;;
    "$EXIT_PR_CLOSE_FAILED")
      bt_emit_guidance_joined "merge completed but PR closure failed; rerun pushup" \
                       "to retry closing the PR"
      ;;
    *)
      bt_emit_guidance_joined "review the error above, correct the reported issue," \
                       "then rerun pushup"
      ;;
  esac
}

restore_current_branch_on_failure() {
  local exit_code="$1"
  local restored=false
  local now_branch=""

  # Recover only when a failure occurs after switching to parent.
  if [[ "$exit_code" -eq 0 || "$PARENT_CHECKOUT_ACTIVE" != true ]]; then
    return 0
  fi

  git switch "$CURRENT_BRANCH" >/dev/null 2>&1 || true

  now_branch="$(current_checked_out_branch)"
  if [[ "$now_branch" == "$CURRENT_BRANCH" ]]; then
    restored=true
  else
    git switch -f "$CURRENT_BRANCH" >/dev/null 2>&1 || true
    now_branch="$(current_checked_out_branch)"
    if [[ "$now_branch" == "$CURRENT_BRANCH" ]]; then
      restored=true
    fi
  fi

  if [[ "$restored" == true ]]; then
    cleanup_tracked_changes_after_failure
    bt_warn "pushup failed; restored working branch to '$CURRENT_BRANCH'"
  else
    bt_warn "pushup failed and could not restore branch '$CURRENT_BRANCH'" \
            "automatically"
  fi
}

cleanup_tracked_changes_after_failure() {
  # Preflight requires a clean worktree, so tracked changes after restoration
  # belong to this failed operation. Untracked workflow reports are preserved.
  if ! git restore --source=HEAD --staged --worktree -- . >/dev/null 2>&1; then
    bt_warn "Could not fully restore tracked files after the failed pushup" \
            "operation"
  fi
}

on_exit_restore_branch_if_needed() {
  local exit_code=$?

  if [[ -n "${SUCCESS_COMMENT_FILE:-}" ]]; then
    rm -f "$SUCCESS_COMMENT_FILE" >/dev/null 2>&1 || true
  fi
  if [[ -n "${REPORT_LOCK_FD:-}" ]]; then
    release_report_lock || true
  fi

  # Keep the run lock through restoration and report generation so another
  # pushup cannot begin while this run is still repairing local state.
  restore_current_branch_on_failure "$exit_code" || true

  if [[ "$exit_code" -ne 0 && "$OPERATION_STARTED" == true ]]; then
    generate_error_report "$exit_code" >/dev/null 2>&1 || true
  fi

  if ! release_run_lock; then
    echo "Warning: pushup cleanup did not complete successfully." >&2
  fi
  if [[ "$exit_code" -ne 0 && "$exit_code" -ne "$EXIT_PR_MISSING" && \
    "$exit_code" -ne "$EXIT_CURRENT_UNCOMMITTED" ]]; then
    print_failure_guidance "$exit_code" || true
  fi
}

trap on_exit_restore_branch_if_needed EXIT

is_repository_owner() {
  local user_name="$1"

  bt_is_repository_owner_login "$user_name"
}


get_current_user() {
  local user_name

  if ! user_name="$(bt_require_login)"; then
    bt_error_exit "$EXIT_GITHUB_IDENTITY_FAILED" \
      "Unable to determine GitHub login identity for role checks"
  fi

  echo "$user_name"
}

get_parent_branch() {
  local current_branch="$1"

  local parent_branch
  parent_branch=$(bt_resolve_parent_branch \
    "$current_branch" "main") || {
    bt_error_exit "$EXIT_PARENT_MISSING" "Failed to determine parent branch"
  }

  echo "$parent_branch"
}

is_remote_connected() {
  git remote get-url origin >/dev/null 2>&1
}

has_local_branch() {
  local branch="$1"
  git show-ref --verify --quiet "refs/heads/$branch"
}

has_remote_branch() {
  local branch="$1"
  git show-ref --verify --quiet "refs/remotes/origin/$branch"
}

parent_has_remote_push_target() {
  local parent_branch="$1"

  if [[ "$parent_branch" == "main" ]]; then
    return 0
  fi

  has_remote_branch "$parent_branch"
}

set_verify_failure() {
  local failure_kind="$1"
  local message="$2"

  VERIFY_FAILURE_KIND="$failure_kind"
  VERIFY_LAST_ERROR="$message"
}

verify_ref_at_commit() {
  local ref_name="$1"
  local expected_sha="$2"
  local label="$3"
  local failure_kind="$4"
  local actual_sha=""

  actual_sha="$(git rev-parse "$ref_name" 2>/dev/null || true)"
  if [[ -z "$actual_sha" ]]; then
    set_verify_failure "$failure_kind" "unable to resolve $label ($ref_name)"
    return 1
  fi

  if [[ "$actual_sha" != "$expected_sha" ]]; then
    set_verify_failure "$failure_kind" \
      "$label is at $actual_sha, expected $expected_sha"
    return 1
  fi

  return 0
}

bt_is_worktree_dirty_except_merge_report() {
  local status_line
  local report_rel=""
  local pushup_report_re='^\?\? reports/pushup(-d|-e)?-[0-9]{8}-[0-9]{6}([+-][0-9]{4})(-[0-9]+)?\.md$'
  local push_report_re='^\?\? reports/push(-d|-e)?-[0-9]{8}-[0-9]{6}([+-][0-9]{4})(-[0-9]+)?\.md$'
  local dirty_found=false

  report_rel="${REPORT_FILE#"${REPO_ROOT}"/}"

  while IFS= read -r status_line; do
    [[ -n "$status_line" ]] || continue
    if [[ "$status_line" =~ $pushup_report_re ]]; then
      continue
    fi
    if [[ "$status_line" =~ $push_report_re ]]; then
      continue
    fi
    if [[ -n "$report_rel" && "$status_line" == "?? ${report_rel}" ]]; then
      continue
    fi
    dirty_found=true
    break
  done < <(git --no-optional-locks status --porcelain \
    --untracked-files=all 2>/dev/null || true)

  [[ "$dirty_found" == true ]]
}

verify_post_merge_sync() {
  local current_branch="$1"
  local parent_branch="$2"
  local expected_tip="$3"
  local now_branch=""

  VERIFY_LAST_ERROR=""
  VERIFY_FAILURE_KIND=""

  # Refresh remote refs before asserting final state.
  bt_run_remote_command git fetch origin "$current_branch" >/dev/null 2>&1 || \
    true
  if parent_has_remote_push_target "$parent_branch"; then
    bt_run_remote_command git fetch origin "$parent_branch" >/dev/null 2>&1 || true
  fi

  verify_ref_at_commit "$current_branch" "$expected_tip" \
    "local current branch '$current_branch'" "local_current_ref" || return 1

  if has_local_branch "$parent_branch"; then
    verify_ref_at_commit "$parent_branch" "$expected_tip" \
      "local parent branch '$parent_branch'" "local_parent_ref" || return 1
  fi

  if has_remote_branch "$current_branch"; then
    verify_ref_at_commit "origin/$current_branch" "$expected_tip" \
      "remote current branch origin/$current_branch" "remote_current_ref" || return 1
  fi

  if parent_has_remote_push_target "$parent_branch"; then
    verify_ref_at_commit "origin/$parent_branch" "$expected_tip" \
      "remote parent branch origin/$parent_branch" "remote_parent_ref" || return 1
  fi

  now_branch="$(current_checked_out_branch)"
  if [[ "$now_branch" != "$current_branch" ]]; then
    set_verify_failure "checked_out_branch" \
      "expected current branch '$current_branch', found '$now_branch'"
    return 1
  fi

  if bt_is_worktree_dirty_except_merge_report; then
    set_verify_failure "worktree_dirty" "worktree is dirty after pushup"
    return 1
  fi

  if [[ "$VERBOSE" == true ]]; then
    bt_info "Post-merge sync verification passed"
  fi

  return 0
}

attempt_post_merge_sync_repair() {
  local current_branch="$1"
  local parent_branch="$2"
  local expected_tip="$3"
  local failure_kind="$4"
  local now_branch=""

  case "$failure_kind" in
    local_current_ref)
      if ! git branch -f "$current_branch" "$expected_tip" >/dev/null 2>&1; then
        set_verify_failure "$failure_kind" \
          "failed to align local current branch '$current_branch' to " \
          "expected merge tip"
        return 1
      fi
      ;;
    local_parent_ref)
      if has_local_branch "$parent_branch"; then
        now_branch="$(current_checked_out_branch)"
        if [[ "$now_branch" == "$parent_branch" ]]; then
          set_verify_failure "$failure_kind" \
            "cannot force-align local parent branch '$parent_branch' while " \
            "it is checked out"
          return 1
        fi
        if ! git branch -f "$parent_branch" "$expected_tip" >/dev/null 2>&1; then
          set_verify_failure "$failure_kind" \
            "failed to align local parent branch '$parent_branch' to " \
            "expected merge tip"
          return 1
        fi
      fi
      ;;
    remote_current_ref)
      if has_remote_branch "$current_branch"; then
        if ! bt_run_remote_command env GIT_BYPASS_HOOKS=true git push \
          --force-with-lease origin "$expected_tip:$current_branch" \
          >/dev/null 2>&1; then
          set_verify_failure "$failure_kind" \
            "failed to align remote current branch origin/$current_branch"
          return 1
        fi
      fi
      ;;
    remote_parent_ref)
      if parent_has_remote_push_target "$parent_branch"; then
        if ! bt_run_remote_command env GIT_BYPASS_HOOKS=true git push origin \
          "$expected_tip:$parent_branch" >/dev/null 2>&1; then
          set_verify_failure "$failure_kind" \
            "failed to align remote parent branch origin/$parent_branch"
          return 1
        fi
      fi
      ;;
    checked_out_branch)
      if ! git switch "$current_branch" >/dev/null 2>&1; then
        set_verify_failure "$failure_kind" \
          "failed to restore current branch '$current_branch' after " \
          "repair"
        return 1
      fi
      ;;
    worktree_dirty)
      set_verify_failure "$failure_kind" "worktree became dirty after merge; auto-repair is " \
        "intentionally disabled for this condition"
      return 1
      ;;
    *)
      set_verify_failure "$failure_kind" "no targeted repair rule for verification failure kind " \
        "'$failure_kind'"
      return 1
      ;;
  esac

  return 0
}

ensure_post_merge_sync_or_repair() {
  local current_branch="$1"
  local parent_branch="$2"
  local expected_tip="$3"

  if verify_post_merge_sync "$current_branch" "$parent_branch" "$expected_tip"; then
    return 0
  fi

  bt_warn "Post-merge sync verification failed: $VERIFY_LAST_ERROR"
  bt_warn "Failure kind: ${VERIFY_FAILURE_KIND:-unknown}"
  bt_warn "Attempting automatic repair and retrying verification once"

  if ! attempt_post_merge_sync_repair "$current_branch" "$parent_branch" \
    "$expected_tip" "$VERIFY_FAILURE_KIND"; then
    bt_error_exit "$EXIT_GIT_OPERATION_FAILED" "Post-merge sync auto-repair failed: $VERIFY_LAST_ERROR"
  fi

  if verify_post_merge_sync "$current_branch" "$parent_branch" "$expected_tip"; then
    if [[ "$VERBOSE" == true ]]; then
      bt_info "Post-merge sync verification passed after one automatic" \
              "repair attempt"
    fi
    return 0
  fi

  bt_error_exit "$EXIT_GIT_OPERATION_FAILED" \
    "Post-merge verification failed after one repair attempt: " \
    "$VERIFY_LAST_ERROR"
}

ensure_branch_synced_with_remote() {
  local branch="$1"
  local label="$2"
  local behind_exit="$3"
  local ahead_exit="$4"
  local diverged_exit="$5"

  local counts
  local behind
  local ahead

  # For origin...local, the left count is commits only on origin (local is
  # behind); the right count is commits only on local (local is ahead).
  counts="$(git rev-list --left-right --count "origin/$branch...$branch" \
    2>/dev/null || true)"
  behind="${counts%%$'\t'*}"
  ahead="${counts##*$'\t'}"

  if [[ ! "$ahead" =~ ^[0-9]+$ || ! "$behind" =~ ^[0-9]+$ ]]; then
    bt_error_exit "$EXIT_GIT_OPERATION_FAILED" \
      "Unable to determine $label branch sync state for '$branch'"
  fi

  if [[ "$behind" -gt 0 && "$ahead" -gt 0 ]]; then
    bt_error_exit "$diverged_exit" \
      "$label branch '$branch' has diverged from origin/$branch " \
      "($behind behind, $ahead ahead)"
  fi
  if [[ "$behind" -gt 0 ]]; then
    bt_error_exit "$behind_exit" \
      "$label branch '$branch' is behind origin/$branch by $behind " \
      "commit(s)"
  fi
  if [[ "$ahead" -gt 0 ]]; then
    bt_error_exit "$ahead_exit" \
      "$label branch '$branch' is ahead of origin/$branch by $ahead " \
      "commit(s)"
  fi
}

resolve_parent_reference() {
  local parent_branch="$1"

  if has_local_branch "$parent_branch"; then
    echo "$parent_branch"
    return 0
  fi

  bt_error_exit "$EXIT_PARENT_MISSING" \
    "Parent branch '$parent_branch' does not exist locally"
}

ensure_current_up_to_date_with_parent() {
  local current_branch="$1"
  local parent_branch="$2"
  local parent_ref
  local current_ref="$current_branch"
  local merge_base=""

  parent_ref=$(resolve_parent_reference "$parent_branch")

  if git merge-base --is-ancestor "$parent_ref" "$current_ref" \
    >/dev/null 2>&1; then
    return 0
  fi

  merge_base="$(git merge-base "$parent_ref" "$current_ref" \
    2>/dev/null || true)"
  if [[ -n "$merge_base" ]] && \
    git diff --quiet "$merge_base" "$parent_ref" 2>/dev/null; then
    bt_info "Parent-only commits contain no file or directory changes; pushup will incorporate them"
    return 0
  fi

  bt_error_exit "$EXIT_CURRENT_BEHIND_PARENT" \
    "Current branch '$current_branch' is not up-to-date with parent " \
    "'$parent_branch'"
}

warn_downstream_targeted_branches_behind_version() {
  local version_branch="$1"
  local version_ref="$1"
  local version_regex=""
  local branch=""
  local branch_ref=""
  local counts=""
  local behind=""
  local ahead=""
  local -a behind_branches=()

  if ! bt_is_version_branch "$version_branch"; then
    return 0
  fi

  if ! has_local_branch "$version_branch" && \
    has_remote_branch "$version_branch"; then
    version_ref="origin/$version_branch"
  fi

  version_regex="${version_branch//./\\.}"

  while IFS= read -r branch; do
    [[ -n "$branch" ]] || continue
    [[ "$branch" == "$version_branch" ]] && continue

    if [[ ! "$branch" =~ ^(dev|fix)/.+-${version_regex}$ ]]; then
      continue
    fi

    branch_ref="$branch"
    if ! has_local_branch "$branch" && has_remote_branch "$branch"; then
      branch_ref="origin/$branch"
    elif ! has_local_branch "$branch" && ! has_remote_branch "$branch"; then
      continue
    fi

    counts="$(git rev-list --left-right --count "$version_ref...$branch_ref" \
      2>/dev/null || true)"
    [[ -n "$counts" ]] || continue

    behind="${counts%%$'\t'*}"
    ahead="${counts##*$'\t'}"
    if [[ "$behind" =~ ^[0-9]+$ && "$ahead" =~ ^[0-9]+$ && \
      "$behind" -gt 0 ]]; then
      behind_branches+=("$branch")
    fi
  done < <(
    {
      git for-each-ref --format='%(refname:short)' refs/heads
      git for-each-ref --format='%(refname:short)' refs/remotes/origin
    } | sed 's#^origin/##' | sort -u
  )

  if [[ ${#behind_branches[@]} -gt 0 ]]; then
    bt_warn "Downstream sync needed: ${#behind_branches[@]} targeted" \
            "branch(es) are now behind '$version_branch'. Run pulldown on" \
            "each affected branch."
    if [[ "$VERBOSE" == true ]]; then
      for branch in "${behind_branches[@]}"; do
        bt_info "  behind: $branch"
      done
    fi
  fi
}

is_targeted_branch() {
  local branch="$1"
  [[ "$branch" =~ ^(dev|fix)/.+-(v[1-9][0-9]?\.(0|[1-9][0-9]?)\.0)$ ]]
}

is_contributor_branch() {
  local branch="$1"

  if bt_is_protected_branch "$branch" || is_targeted_branch "$branch"; then
    return 1
  fi

  return 0
}

validate_merge_branch_relationship() {
  local current_branch="$1"
  local parent_branch="$2"

  if ! validate_branch_name "$current_branch" "current branch" || \
    [[ "$current_branch" == "main" ]]; then
    bt_error_exit "$EXIT_INVALID_CURRENT_BRANCH" \
      "Current branch '$current_branch' is not a contributor, targeted, or" \
      "version branch"
  fi

  if ! validate_branch_name "$parent_branch" "parent branch"; then
    bt_error_exit "$EXIT_INVALID_ARGUMENT" \
      "Parent branch '$parent_branch' does not conform to naming conventions"
  fi

  if is_targeted_branch "$current_branch"; then
    if ! bt_is_version_branch "$parent_branch"; then
      bt_error_exit "$EXIT_INVALID_TARGETED_PARENT" \
        "Targeted current branch '$current_branch' requires a version" \
        "parent branch"
    fi
    return 0
  fi

  if bt_is_version_branch "$current_branch"; then
    if [[ "$parent_branch" != "main" ]]; then
      bt_error_exit "$EXIT_INVALID_VERSION_PARENT" \
        "Version current branch '$current_branch' requires main as its" \
        "parent branch"
    fi
    return 0
  fi

  if ! is_contributor_branch "$parent_branch" && \
    ! is_targeted_branch "$parent_branch"; then
    bt_error_exit "$EXIT_INVALID_CONTRIBUTOR_PARENT" \
      "Contributor current branch '$current_branch' requires a contributor" \
      "or targeted parent branch"
  fi
}

is_pr_required() {
  local current_branch="$1"
  local parent_branch="$2"

  # Usage contract: PR is required when merging up to a version branch
  # unless owner override is active.
  if bt_is_version_branch "$parent_branch"; then
    return 0
  fi

  return 1
}

build_default_commit_message() {
  local current_branch="$1"
  local parent_branch="$2"
  local actor="$3"
  local owner_override_active="$4"

  if bt_is_version_branch "$current_branch" && \
    [[ "$parent_branch" == "main" ]]; then
    echo "$current_branch merged to main branch by approver $actor."
    return 0
  fi

  if [[ "$owner_override_active" == true ]] && \
    is_targeted_branch "$current_branch" && \
      bt_is_version_branch "$parent_branch"; then
    echo "$current_branch merged to $parent_branch by owner $actor."
    return 0
  fi

  if is_contributor_branch "$current_branch" && \
    (is_targeted_branch "$parent_branch" || \
      is_contributor_branch "$parent_branch"); then
    echo "$current_branch merged to $parent_branch by contributor $actor."
    return 0
  fi

  bt_error_exit "$EXIT_INVALID_ARGUMENT" \
    "No default commit message rule applies for '$current_branch' " \
    "to '$parent_branch'"
}

write_merge_success_content() {
  local output_file="$1"
  local current_branch="$2"
  local parent_branch="$3"
  local merge_message="$4"
  local command_text

  command_text="$(format_command_line)"

  if ! bt_report_write_header "$output_file" "Merge-Up Report" \
    "$RUN_TS_DISPLAY" "$command_text"; then
    bt_error_exit "$EXIT_LOCAL_REPORT_FAILED" \
      "Failed to write merge summary '$output_file'"
  fi

  if ! cat >> "$output_file" <<EOF
**Source Branch:** ${current_branch}

**Parent Branch:** ${parent_branch}

**Commit Comment:** ${merge_message}

## CI/CD Results

${CI_CD_REPORT_DETAILS}

## Merge Details

- **Status:** Current branch merged into parent branch.
- **Method:** Squash merge created by pushup.
- **Guidance:** Review merged changes and run tests before sharing.

EOF
  then
    bt_error_exit "$EXIT_LOCAL_REPORT_FAILED" \
      "Failed to write merge summary '$output_file'"
  fi
}

generate_dry_run_report() {
  local current_branch="$1"
  local parent_branch="$2"
  local merge_message="$3"
  local command_text

  command_text="$(format_command_line)"
  acquire_report_lock
  bt_report_dir_enable_writes "$REPORTS_DIR" "$EXIT_LOCAL_REPORT_FAILED"

  REPORT_FILE="$(bt_report_transient_path \
    "$REPORTS_DIR" "pushup-d" "$RUN_TS_FILE")"
  cleanup_old_transient_reports

  if ! bt_report_write_header "$REPORT_FILE" "Merge-Up Report" \
    "$RUN_TS_DISPLAY" "$command_text"; then
    bt_error_exit "$EXIT_LOCAL_REPORT_FAILED" \
      "Failed to write dry-run report '$REPORT_FILE'"
  fi

  if ! cat >> "$REPORT_FILE" <<EOF
**Source Branch:** ${current_branch}

**Parent Branch:** ${parent_branch}

**Mode:** dry-run

**Commit Comment:** ${merge_message}

## CI/CD Results

${CI_CD_REPORT_DETAILS}

## Merge Details

- **Status:** Preview only; no merge commit, history update, branch push,
  source alignment, or post-merge verification was performed.
- **Guidance:** Review planned merge conditions and rerun without -d when ready.

EOF
  then
    bt_error_exit "$EXIT_LOCAL_REPORT_FAILED" "Failed to write dry-run report '$REPORT_FILE'"
  fi
  release_report_lock

}

generate_error_report() {
  local exit_code="$1"
  local command_text

  command_text="$(format_command_line)"
  acquire_report_lock
  bt_report_dir_enable_writes "$REPORTS_DIR" "$EXIT_LOCAL_REPORT_FAILED"

  REPORT_FILE="$(bt_report_transient_path \
    "$REPORTS_DIR" "pushup-e" "$RUN_TS_FILE")"
  cleanup_old_transient_reports

  if ! bt_report_write_header "$REPORT_FILE" "Merge-Up Error Report" \
    "$RUN_TS_DISPLAY" "$command_text"; then
    bt_error_exit "$EXIT_LOCAL_REPORT_FAILED" \
      "Failed to write error report '$REPORT_FILE'"
  fi

  if ! cat >> "$REPORT_FILE" <<EOF
**Source Branch:** ${CURRENT_BRANCH}

**Parent Branch:** ${PARENT_BRANCH:-unknown}

**Exit Code:** ${exit_code}

**Failure Kind:** ${VERIFY_FAILURE_KIND:-unknown}

**Error:** ${VERIFY_LAST_ERROR:-${LAST_ERROR_MESSAGE:-merge-up operation \
failed}}

## CI/CD Results

${CI_CD_REPORT_DETAILS}

## Guidance

- Resolve the reported issue and rerun pushup.

EOF
  then
    bt_error_exit "$EXIT_LOCAL_REPORT_FAILED" "Failed to write error report '$REPORT_FILE'"
  fi
  release_report_lock

}

checkout_parent_branch() {
  local parent_branch="$1"

  if ! git switch "$parent_branch" >/dev/null 2>&1; then
    bt_error_exit "$EXIT_PARENT_CHECKOUT_FAILED" \
      "Parent branch '$parent_branch' cannot be checked out in this worktree"
  fi

  PARENT_CHECKOUT_ACTIVE=true
}

is_approver() {
  local user_name="$1"

  bt_contributors_has_min_role "$user_name" "approver" "$REPO_ROOT/config/contributors.md"
}

is_contributor() {
  local user_name="$1"

  bt_contributors_has_min_role "$user_name" "contributor" "$REPO_ROOT/config/contributors.md"
}

ensure_merge_actor_authorized() {
  local current_branch="$1"
  local actor="$2"

  if [[ "$OWNER_OVERRIDE_ACTIVE" == true ]]; then
    return 0
  fi

  if is_contributor_branch "$current_branch"; then
    if ! is_contributor "$actor"; then
      bt_error_exit "$EXIT_NOT_CONTRIBUTOR" \
        "User '$actor' is not a contributor and cannot merge '$current_branch'"
    fi
    return 0
  fi

  if is_targeted_branch "$current_branch"; then
    if ! is_contributor "$actor"; then
      bt_error_exit "$EXIT_NOT_APPROVER" \
        "User '$actor' is not a contributor and cannot merge '$current_branch'"
    fi
    return 0
  fi

  if ! is_approver "$actor"; then
    bt_error_exit "$EXIT_NOT_APPROVER" \
      "User '$actor' is not an approver and cannot merge a targeted or" \
      "version branch"
  fi
}

get_existing_pr_number() {
  local branch="$1"
  local pr_number=""

  # Search all states so a closed or merged PR reaches the dedicated
  # validation exits instead of being misreported as a missing PR.
  bt_gh_capture_or_exit pr_number "$EXIT_REMOTE_TIMEOUT" \
    "$EXIT_GITHUB_PR_QUERY_FAILED" \
    "Failed to query pull requests for branch '$branch'" \
    gh pr list --head "$branch" --state all --json number --jq '.[0].number'

  printf '%s\n' "$pr_number"
}

get_pr_title() {
  local pr_number="$1"
  local title=""

  bt_gh_capture_or_exit title "$EXIT_REMOTE_TIMEOUT" \
    "$EXIT_GITHUB_PR_QUERY_FAILED" \
    "Failed to query title for pull request #$pr_number" \
    gh pr view "$pr_number" --json title --jq '.title'

  printf '%s\n' "$title"
}

get_pr_validation_fields() {
  local pr_number="$1"
  local fields=""

  bt_gh_capture_or_exit fields "$EXIT_REMOTE_TIMEOUT" \
    "$EXIT_GITHUB_PR_QUERY_FAILED" \
    "Failed to query metadata for pull request #$pr_number" \
    gh pr view "$pr_number" \
    --json state,isDraft,headRefName,headRefOid,baseRefName,reviewDecision,mergedAt \
    --jq '[.state, (.isDraft|tostring), .headRefName, .baseRefName, \
      .headRefOid, .reviewDecision, (.mergedAt // "")] | @tsv'

  printf '%s\n' "$fields"
}

validate_pr_for_merge() {
  local pr_number="$1"
  local current_branch="$2"
  local parent_branch="$3"
  local fields=""
  local state=""
  local is_draft=""
  local head_ref=""
  local base_ref=""
  local head_oid=""
  local review_decision=""
  local merged_at=""

  fields="$(get_pr_validation_fields "$pr_number")"
  if [[ -z "$fields" ]]; then
    bt_error_exit "$EXIT_GITHUB_PR_QUERY_FAILED" \
      "Pull request #$pr_number is missing required metadata"
  fi

  IFS=$'\t' read -r state is_draft head_ref base_ref head_oid \
    review_decision merged_at <<< "$fields"

  if [[ -n "$merged_at" || "$state" == "MERGED" ]]; then
    bt_error_exit "$EXIT_PR_ALREADY_MERGED" \
      "Pull request #$pr_number indicates already merged"
  fi

  if [[ "$state" != "OPEN" ]]; then
    bt_error_exit "$EXIT_PR_NOT_OPEN" "Pull request #$pr_number is not open"
  fi

  if [[ "$is_draft" == "true" ]]; then
    bt_error_exit "$EXIT_PR_DRAFT" "Pull request #$pr_number is a draft"
  fi

  if [[ "$head_ref" != "$current_branch" ]]; then
    bt_error_exit "$EXIT_PR_HEAD_MISMATCH" \
      "Pull request #$pr_number head is not current branch " \
      "'$current_branch'"
  fi

  if [[ "$head_oid" != "$CURRENT_SOURCE_TIP" ]]; then
    bt_error_exit "$EXIT_PR_HEAD_COMMIT_MISMATCH" \
      "Pull request #$pr_number head commit does not match current branch " \
      "'$current_branch'"
  fi

  if [[ "$base_ref" != "$parent_branch" ]]; then
    bt_error_exit "$EXIT_PR_BASE_MISMATCH" \
      "Pull request #$pr_number base is not parent branch " \
      "'$parent_branch'"
  fi

  if [[ "$review_decision" == "CHANGES_REQUESTED" ]]; then
    bt_error_exit "$EXIT_PR_HAS_CHANGES_REQUESTED" \
      "Pull request #$pr_number has outstanding changes requested"
  fi

  if [[ "$review_decision" != "APPROVED" ]]; then
    bt_error_exit "$EXIT_PR_NOT_APPROVED" "Pull request #$pr_number is not approved"
  fi

  local approval_id=""
  bt_gh_capture_or_exit approval_id "$EXIT_REMOTE_TIMEOUT" \
    "$EXIT_GITHUB_PR_QUERY_FAILED" \
    "Failed to verify approval for pull request #$pr_number" \
    gh api --paginate "repos/{owner}/{repo}/pulls/$pr_number/reviews" \
    --jq ".[] | select(.state == \"APPROVED\" and .commit_id == \"$head_oid\") | .id"
  if [[ -z "$approval_id" ]]; then
    bt_error_exit "$EXIT_PR_NOT_APPROVED" \
      "Pull request #$pr_number is not approved for its current commit"
  fi
  APPROVED_SOURCE_TIP="$head_oid"
}

collect_ci_cd_results() {
  local pr_number="$1"
  local checks_text=""

  bt_info "Collecting CI/CD results..."

  if ! checks_text="$(bt_run_remote_command gh pr view "$pr_number" \
    --json statusCheckRollup \
    --jq '.statusCheckRollup[]? | "\((.name // .context // \
      .workflowName // "")|ascii_downcase)\t\((.state // .conclusion // "")|ascii_upcase)"' \
    2>/dev/null)"; then
    CI_CD_REPORT_DETAILS="CI/CD results were unavailable for PR #$pr_number."
    bt_info "CI/CD results were unavailable for PR #$pr_number"
    return 0
  fi

  if [[ -z "$checks_text" ]]; then
    CI_CD_REPORT_DETAILS="No CI/CD checks found for PR #$pr_number."
    bt_info "No CI/CD checks found"
    return 0
  fi

  CI_CD_REPORT_DETAILS="$(printf '%s\n' "$checks_text" | \
    awk -F '\t' 'BEGIN { print "| Check | State |"; print "| --- | --- |" }
      NF < 2 { printf "| unlabeled | %s |\n", $1; next }
      { printf "| %s | %s |\n", $1 == "" ? "unlabeled" : $1, $2 }')"
}

ensure_clean_worktree() {
  local status_lines
  local remaining

  status_lines="$(git --no-optional-locks status --porcelain \
    --untracked-files=all 2>/dev/null || true)"
  if [[ -z "$status_lines" ]]; then
    return 0
  fi

  remaining="$(printf '%s\n' "$status_lines" | \
    grep -Ev '^(\\?\\?|[ MARCUD?!][ MARCUD?!]) reports/(pushup|push)(-d|-e)?-[0-9]{8}-[0-9]{6}([+-][0-9]{4})(-[0-9]+)?\.md$' || true)"

  if [[ -n "$remaining" ]]; then
    bt_emit_prerequisite_failure "$EXIT_CURRENT_UNCOMMITTED" \
      "Current branch has uncommitted changes." \
      "commit or undo changes, then rerun pushup."
  fi
}

# Parse options and arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    -c)
      if [[ $# -lt 2 ]]; then
        usage_error "Option -c requires a commit comment token"
      fi
      if [[ -n "$MESSAGE_SOURCE" ]]; then
        usage_error "-c TOKEN and -- TOKENS are mutually exclusive"
      fi
      CUSTOM_MESSAGE="$2"
      MESSAGE_SOURCE="option"
      shift 2
      RUN_TS_FILE="$(bt_datetime_filename_now)"
      ;;
    -d)
      if [[ "$ERROR_RUN" == true ]]; then
        usage_error "Options -d and -e are mutually exclusive."
      fi
      DRY_RUN=true
      shift
      ;;
    -e)
      if [[ "$DRY_RUN" == true ]]; then
        usage_error "Options -d and -e are mutually exclusive."
      fi
      ERROR_RUN=true
      shift
      ;;
    -o)
      OWNER_OVERRIDE=true
      shift
      ;;
    -t)
      if [[ $# -lt 2 ]]; then
        usage_error "Option -t requires a timeout in seconds"
      fi
      if [[ ! "$2" =~ ^[0-9]+$ ]] || [[ "$2" -le 0 ]]; then
        usage_error "Invalid -t value: $2 (expected integer > 0)"
      fi
      REMOTE_TIMEOUT_SECONDS="$2"
      shift 2
      ;;
    -v | --verbose)
      VERBOSE=true
      shift
      ;;
    --)
      shift
      if [[ $# -eq 0 ]]; then
        usage_error "'-- TOKENS' requires at least one token"
      fi
      if [[ -n "$MESSAGE_SOURCE" ]]; then
        usage_error "-c TOKEN and -- TOKENS are mutually exclusive"
      fi
      CUSTOM_MESSAGE="$*"
      MESSAGE_SOURCE="tokens"
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
  skip_merge_up_and_exit
fi

if [[ -n "$MESSAGE_SOURCE" ]]; then
  CUSTOM_MESSAGE="$(bt_trim_whitespace "$CUSTOM_MESSAGE")"
  if [[ -z "$CUSTOM_MESSAGE" ]]; then
    bt_error_exit "$EXIT_EMPTY_COMMIT_COMMENT" \
      "Commit comment is specified but it is empty after normalization"
  fi
fi

# Lock after argument parsing. Help/usage exits do not require repository lock.
acquire_run_lock

# Get current branch
CURRENT_BRANCH=$(bt_get_current_branch || \
  bt_error_exit "$EXIT_CURRENT_NOT_CHECKED_OUT" "Failed to determine current branch")
if bt_is_current_internal_remote_copy; then
  bt_emit_prerequisite_failure "$EXIT_INVALID_CURRENT_BRANCH" \
    "Current branch '$CURRENT_BRANCH' is a read-only remote copy." \
    "switch to a local targeted branch before running pushup."
fi

if [[ "$CURRENT_BRANCH" == "HEAD" ]]; then
  bt_error_exit "$EXIT_CURRENT_NOT_CHECKED_OUT" \
    "Current branch is not checked out locally (detached HEAD)"
fi

if ! has_local_branch "$CURRENT_BRANCH"; then
  bt_error_exit "$EXIT_CURRENT_NOT_CHECKED_OUT" \
    "Current branch '$CURRENT_BRANCH' is not checked out locally"
fi
CURRENT_SOURCE_REF="$CURRENT_BRANCH"
CURRENT_SOURCE_TIP="$(git rev-parse "$CURRENT_BRANCH" 2>/dev/null || true)"
if [[ -z "$CURRENT_SOURCE_TIP" ]]; then
  bt_error_exit "$EXIT_GIT_OPERATION_FAILED" \
    "Failed to resolve current branch commit for '$CURRENT_BRANCH'"
fi
APPROVED_SOURCE_TIP="$CURRENT_SOURCE_TIP"

if bt_is_copyfix_in_progress "$CURRENT_BRANCH"; then
  bt_emit_prerequisite_failure "$EXIT_COPYFIX_IN_PROGRESS" \
    "Current branch '$CURRENT_BRANCH' has an unfinished copyfix operation." \
    "rerun copyfix to complete it before rerunning pushup."
fi

bt_info "Current local branch $CURRENT_BRANCH"

# Determine and validate the merge path before applying role checks.
bt_info "Determining parent branch..."
PARENT_BRANCH=$(get_parent_branch "$CURRENT_BRANCH")
bt_info "Parent branch: $PARENT_BRANCH"

validate_merge_branch_relationship "$CURRENT_BRANCH" "$PARENT_BRANCH"

# Get current user
CURRENT_USER=$(get_current_user)
bt_info "Current user: $CURRENT_USER"

if [[ "$OWNER_OVERRIDE" == true ]]; then
  if is_repository_owner "$CURRENT_USER"; then
    OWNER_OVERRIDE_ACTIVE=true
    bt_info "Owner override enabled for repository owner '$CURRENT_USER'"
  else
    bt_error_exit "$EXIT_NOT_REPOSITORY_OWNER" "Option -o is allowed only for the repository owner"
  fi
  if ! is_targeted_branch "$CURRENT_BRANCH"; then
    bt_error_exit "$EXIT_OWNER_OVERRIDE_INVALID_BRANCH" \
      "Option -o requires the current branch to be a targeted branch"
  fi
fi

ensure_merge_actor_authorized "$CURRENT_BRANCH" "$CURRENT_USER"

if ! has_local_branch "$PARENT_BRANCH"; then
  bt_error_exit "$EXIT_PARENT_MISSING" "Parent branch '$PARENT_BRANCH' does not exist locally"
fi

CURRENT_HAS_REMOTE=false
PARENT_HAS_REMOTE=false
has_remote_branch "$CURRENT_BRANCH" && CURRENT_HAS_REMOTE=true
has_remote_branch "$PARENT_BRANCH" && PARENT_HAS_REMOTE=true

if bt_is_protected_branch "$CURRENT_BRANCH" && \
  [[ "$CURRENT_HAS_REMOTE" != true ]]; then
  bt_error_exit "$EXIT_CURRENT_PROTECTED_REMOTE_MISSING" \
    "Protected current branch '$CURRENT_BRANCH' must have a corresponding" \
    "remote branch"
fi
if bt_is_protected_branch "$PARENT_BRANCH" && \
  [[ "$PARENT_HAS_REMOTE" != true ]]; then
  bt_error_exit "$EXIT_PARENT_PROTECTED_REMOTE_MISSING" \
    "Protected parent branch '$PARENT_BRANCH' must have a corresponding" \
    "remote branch"
fi
if [[ "$CURRENT_HAS_REMOTE" == true && "$PARENT_HAS_REMOTE" != true ]]; then
  bt_error_exit "$EXIT_PARENT_PROTECTED_REMOTE_MISSING" \
    "Parent branch '$PARENT_BRANCH' must have a remote copy because current" \
    "branch '$CURRENT_BRANCH' has one"
fi
# Remote access is a conditional prerequisite: local-only contributor and
# targeted branch merges do not contact origin unless one side has a remote.
if [[ "$CURRENT_HAS_REMOTE" == true || "$PARENT_HAS_REMOTE" == true ]]; then
  if ! is_remote_connected; then
    bt_error_exit "$EXIT_REMOTE_UNCONFIGURED" "Remote 'origin' is not configured"
  fi

  remote_check_rc=0
  bt_git_ls_remote_origin_with_timeout "$REPO_ROOT" "$REMOTE_TIMEOUT_SECONDS" >/dev/null 2>&1 || remote_check_rc=$?
  if [[ "$remote_check_rc" -eq 124 ]]; then
    bt_error_exit "$EXIT_REMOTE_TIMEOUT" "Remote 'origin' timed out after ${REMOTE_TIMEOUT_SECONDS}s"
  elif [[ "$remote_check_rc" -ne 0 ]]; then
    bt_error_exit "$EXIT_REMOTE_UNREACHABLE" "Remote 'origin' is not reachable"
  fi

  bt_run_remote_command git fetch origin >/dev/null 2>&1 || \
    bt_error_exit "$EXIT_REMOTE_UNREACHABLE" "Failed to fetch from remote 'origin'"

fi

ensure_clean_worktree
if [[ "$CURRENT_HAS_REMOTE" == true ]]; then
  ensure_branch_synced_with_remote "$CURRENT_BRANCH" "Current" \
    "$EXIT_CURRENT_BEHIND_REMOTE" "$EXIT_CURRENT_AHEAD_REMOTE" \
    "$EXIT_CURRENT_DIVERGED_REMOTE"
fi

if [[ "$PARENT_HAS_REMOTE" == true ]]; then
  ensure_branch_synced_with_remote "$PARENT_BRANCH" "Parent" \
    "$EXIT_PARENT_BEHIND_REMOTE" "$EXIT_PARENT_AHEAD_REMOTE" \
    "$EXIT_PARENT_DIVERGED_REMOTE"
fi

ensure_current_up_to_date_with_parent "$CURRENT_BRANCH" "$PARENT_BRANCH"

if git diff --quiet "$PARENT_BRANCH" "$CURRENT_BRANCH"; then
  bt_emit_prerequisite_failure "$EXIT_NOTHING_TO_MERGE" \
    "Current branch '$CURRENT_BRANCH' has no changes to merge into '$PARENT_BRANCH'." \
    "make changes before rerunning pushup."
fi

# Determine whether a PR is required for this merge path.
PR_REQUIRED=true
if [[ "$OWNER_OVERRIDE_ACTIVE" == true ]]; then
  PR_REQUIRED=false
  bt_info "Owner override enabled: PR is not required for this merge"
elif is_pr_required "$CURRENT_BRANCH" "$PARENT_BRANCH"; then
  PR_REQUIRED=true
else
  PR_REQUIRED=false
fi

PR_NUMBER=""
if [[ "$PR_REQUIRED" == true ]]; then
  PR_NUMBER=$(get_existing_pr_number "$CURRENT_BRANCH")
  if [[ -z "$PR_NUMBER" ]]; then
    bt_emit_prerequisite_failure "$EXIT_PR_MISSING" \
      "$CURRENT_BRANCH does not have an approved pull request (PR)." \
      "create or approve a pull request for this branch and rerun pushup."
  fi
  bt_info "Found PR #$PR_NUMBER"

  validate_pr_for_merge "$PR_NUMBER" "$CURRENT_BRANCH" "$PARENT_BRANCH"
else
  bt_info "PR not required for '$CURRENT_BRANCH' to '$PARENT_BRANCH'"

  PR_NUMBER=$(get_existing_pr_number "$CURRENT_BRANCH")
  if [[ -n "$PR_NUMBER" ]]; then
    bt_info "Found PR #$PR_NUMBER; validating PR state"
    validate_pr_for_merge "$PR_NUMBER" "$CURRENT_BRANCH" "$PARENT_BRANCH"
  else
    if [[ "$VERBOSE" == true ]]; then
      bt_info "PR validation skipped (a PR does not exist and is not required)"
    fi
  fi
fi

# CI/CD results are collected for reports only when a PR exists.
if [[ -n "$PR_NUMBER" ]]; then
  collect_ci_cd_results "$PR_NUMBER"
fi

# Determine commit message
if [[ -n "$CUSTOM_MESSAGE" ]]; then
  COMMIT_MESSAGE="$CUSTOM_MESSAGE"
  bt_info "Using custom message: $COMMIT_MESSAGE"
else
  if [[ -n "$PR_NUMBER" ]]; then
    COMMIT_MESSAGE=$(get_pr_title "$PR_NUMBER")
    if [[ -z "$COMMIT_MESSAGE" ]]; then
      bt_error_exit "$EXIT_GITHUB_PR_QUERY_FAILED" "Pull request #$PR_NUMBER has an empty title"
    fi
    bt_info "Using PR title as message: $COMMIT_MESSAGE"
  else
    COMMIT_MESSAGE=$(build_default_commit_message \
      "$CURRENT_BRANCH" "$PARENT_BRANCH" "$CURRENT_USER" "$OWNER_OVERRIDE_ACTIVE")
    bt_info "Using default message: $COMMIT_MESSAGE"
  fi
fi

if [[ "$DRY_RUN" == true ]]; then
  dry_run_push_preview_ref=""

  merge_summary=""

  checkout_parent_branch "$PARENT_BRANCH"
  dry_run_push_preview_ref="$(build_dry_run_push_preview_ref "$CURRENT_SOURCE_REF" "$PARENT_BRANCH")"
  merge_summary="$(format_merge_preview_change_summary_from_commit "$dry_run_push_preview_ref")"
  bt_success "Dry-run: merge to local $PARENT_BRANCH: ${merge_summary}."

  generate_dry_run_report "$CURRENT_BRANCH" "$PARENT_BRANCH" "$COMMIT_MESSAGE"
  if [[ -n "$REPORT_FILE" ]]; then
    report_rel="${REPORT_FILE#"${REPO_ROOT}"/}"
    bt_success "See ${report_rel} for details."
  fi

  if ! git switch "$CURRENT_BRANCH" >/dev/null 2>&1; then
    bt_error_exit "$EXIT_GIT_OPERATION_FAILED" \
      "Dry run completed, but failed to switch back to '$CURRENT_BRANCH'"
  fi
  PARENT_CHECKOUT_ACTIVE=false

  exit 0
fi

# Perform squash merge
bt_info "Performing squash merge..."
OPERATION_STARTED=true

checkout_parent_branch "$PARENT_BRANCH"


if [[ "$PARENT_BRANCH" != "main" ]] && \
  parent_has_remote_push_target "$PARENT_BRANCH"; then
  if ! bt_run_remote_cmd git pull --ff-only origin "$PARENT_BRANCH"; then
    bt_error_exit "$EXIT_GIT_OPERATION_FAILED" "Failed to fast-forward parent branch '$PARENT_BRANCH'"
  fi
fi

if ! bt_run_cmd git merge --squash --no-commit "$CURRENT_SOURCE_REF"; then
  bt_error_exit "$EXIT_GIT_OPERATION_FAILED" "Failed to squash merge '$CURRENT_BRANCH' into '$PARENT_BRANCH'"
fi

# Create the local squash commit. Publication and PR finalization are handled
# later by push.
if ! GIT_BYPASS_HOOKS=true bt_run_cmd git commit -m "$COMMIT_MESSAGE"; then
  bt_error_exit "$EXIT_GIT_OPERATION_FAILED" "Failed to create commit"
fi

MERGE_COMMIT_SHA="$(git rev-parse HEAD 2>/dev/null || true)"
if [[ -z "$MERGE_COMMIT_SHA" ]]; then
  bt_error_exit "$EXIT_GIT_OPERATION_FAILED" "Merge completed, but failed to resolve merge commit"
fi

# Successful details are durable in the local merge commit. push reads the
# recorded event when it publishes the parent and finalizes the PR.
REPORT_FILE=""
cleanup_old_transient_reports
OPERATION_STARTED=false

ci_history_details="$(printf '%s' "$CI_CD_REPORT_DETAILS" | tr '\n' ' ')"
if ! bt_record_workflow_event "pushup" "$PARENT_BRANCH" \
  "$(format_command_line)" \
  "$COMMIT_MESSAGE" "$MERGE_COMMIT_SHA" \
  "Source-Branch" "$CURRENT_BRANCH" \
  "Source-Tip" "$APPROVED_SOURCE_TIP" \
  "Target-Branch" "$PARENT_BRANCH" \
  "PR" "${PR_NUMBER:-none}" \
  "Status" "Current branch merged into parent branch" \
  "Method" "Squash merge created by pushup" \
  "CI-CD" "$ci_history_details"; then
  bt_error_exit "$EXIT_LOCAL_REPORT_FAILED" \
    "Merge-up completed, but its report history could not be recorded"
fi

if bt_is_version_branch "$CURRENT_BRANCH" && \
  [[ "$PARENT_BRANCH" == "main" ]]; then
  warn_downstream_targeted_branches_behind_version "$CURRENT_BRANCH"
fi

# Show verbose output if requested
if [[ "$VERBOSE" == true ]]; then
  bt_info "Merge details:"
  echo "  Branch: $CURRENT_BRANCH."
  echo "  Parent: $PARENT_BRANCH."
  echo "  Actor: $CURRENT_USER."
  echo "  PR: #$PR_NUMBER."
  echo "  Message: $COMMIT_MESSAGE."
fi

print_merge_change_summary "$MERGE_COMMIT_SHA"
bt_success "Local merge complete on $PARENT_BRANCH."
bt_success "Run report for local details."
bt_success "Run push when ready to update remote $PARENT_BRANCH and finalize its PR."
exit 0
