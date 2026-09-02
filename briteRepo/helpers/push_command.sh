#!/usr/bin/env bash

# push_command.sh - push workflow used by push and pushup.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see '<repo>/LICENSE'.

# Internal library: must be sourced by a briteRepo command or helper. Direct
# execution by a user is not supported.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "push_command.sh is a briteRepo internal library and must be sourced." >&2
  exit 1
fi

# The sourcing command owns usage and argument validation; this library owns
# the work. Callers run bt_push_init, set the validated globals, then call
# bt_push_run.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=helpers/common.sh
source "$SCRIPT_DIR/common.sh"
# shellcheck source=helpers/git_helpers.sh
source "$SCRIPT_DIR/git_helpers.sh"
# shellcheck source=helpers/github_helpers.sh
source "$SCRIPT_DIR/github_helpers.sh"
# shellcheck source=helpers/history_log.sh
source "$SCRIPT_DIR/history_log.sh"
# shellcheck source=helpers/report_helpers.sh
source "$SCRIPT_DIR/report_helpers.sh"
# shellcheck source=helpers/report_sync.sh
source "$SCRIPT_DIR/report_sync.sh"
# shellcheck source=helpers/push_workflow.sh
source "$SCRIPT_DIR/push_workflow.sh"

# Establish the library's own runtime state before callers override it.
bt_push_init() {
  PUSH_WORKFLOW_ARGS=()
  PUSH_TIMEOUT_SECONDS=10
  PUSH_ENTRY_MODE="--public"
  PENDING_PUSHUP=false
  PENDING_PUSHUP_SOURCE=""
  PENDING_PUSHUP_SOURCE_TIP=""
  PENDING_PUSHUP_TARGET=""
  PENDING_PUSHUP_PR=""
  PUSHUP_SOURCE_SYNC=false
}

pushup_state_value() {
  local key="$1"
  local state_file=""

  state_file="$(git rev-parse --git-path briteRepo/pushup.state \
    2>/dev/null || true)"
  [[ -f "$state_file" ]] || return 0
  git config --file "$state_file" --get "pushup.$key" 2>/dev/null || true
}

push_error_exit() {
  local code="$1"
  local message="$2"
  bt_emit_error "$message"
  exit "$code"
}

push_is_targeted_branch() {
  local branch="$1"
  [[ "$branch" =~ \
    ^(dev|fix)/[a-z0-9][a-z0-9-]*-(v[1-9][0-9]?\.(0|[1-9][0-9]?)\.0)$ ]]
}

push_is_contributor_branch() {
  local branch="$1"
  local desc='[a-z0-9]+(-[a-z0-9]+)*'
  local type='[a-z][a-z]{0,29}'

  [[ "$branch" != "main" ]] || return 1
  bt_is_version_branch "$branch" && return 1
  push_is_targeted_branch "$branch" && return 1
  [[ "$branch" =~ ^((${type}/)?${desc})$ ]]
}

push_worktree_has_blocking_changes() {
  local status_lines=""
  local remaining=""

  status_lines="$(git --no-optional-locks status --porcelain \
    --untracked-files=all 2>/dev/null || true)"
  [[ -n "$status_lines" ]] || return 1
  remaining="$(printf '%s\n' "$status_lines" | \
    grep -Ev '^\?\? reports/push(-d|-e)?-[0-9]{8}-[0-9]{6}[+-][0-9]{4}(-[0-9]+)?\.md$' \
      || true)"
  [[ -n "$remaining" ]]
}

push_require_contributor_role() {
  local actor_login=""
  local actor_email=""
  local repo_root=""
  local contributors_file=""

  actor_login="$(bt_require_login 2>/dev/null || true)"
  [[ -n "$actor_login" ]] || return 1

  actor_email="$(git config user.email 2>/dev/null || true)"
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  [[ -n "$repo_root" ]] || return 1

  contributors_file="$repo_root/config/contributors.md"
  bt_contributors_has_min_role_by_login_or_email \
    "$actor_login" "$actor_email" "contributor" "$contributors_file"
}

push_require_approver_role() {
  local actor_login=""
  local actor_email=""
  local repo_root=""

  actor_login="$(bt_require_login 2>/dev/null || true)"
  [[ -n "$actor_login" ]] || return 1
  actor_email="$(git config user.email 2>/dev/null || true)"
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  [[ -n "$repo_root" ]] || return 1
  bt_contributors_has_min_role_by_login_or_email \
    "$actor_login" "$actor_email" "approver" \
    "$repo_root/config/contributors.md"
}

push_load_pending_pushup() {
  local current_branch="$1"
  local note=""
  local workflow_type=""

  note="$(git notes --ref=briteRepo-workflow show HEAD 2>/dev/null || true)"
  [[ -n "$note" ]] || return 0
  workflow_type="$(bt_workflow_note_field "$note" "Workflow-Type")"
  [[ "$workflow_type" == "pushup" ]] || return 0

  PENDING_PUSHUP_TARGET="$(bt_workflow_note_field "$note" "Target-Branch")"
  [[ "$PENDING_PUSHUP_TARGET" == "$current_branch" ]] || return 0
  PENDING_PUSHUP_SOURCE="$(bt_workflow_note_field "$note" "Source-Branch")"
  PENDING_PUSHUP_SOURCE_TIP="$(bt_workflow_note_field "$note" "Source-Tip")"
  PENDING_PUSHUP_PR="$(bt_workflow_note_field "$note" "PR")"
  PENDING_PUSHUP=true
}

push_is_pushup_source_sync() {
  local state_file=""
  local state_version=""
  local state_source=""
  local state_phase=""

  [[ "$PUSHUP_SOURCE_SYNC" == true ]] || return 1
  state_file="$(git rev-parse --git-path briteRepo/pushup.state 2>/dev/null || true)"
  [[ -f "$state_file" ]] || return 1
  state_version="$(git config --file "$state_file" --get pushup.version 2>/dev/null || true)"
  state_source="$(git config --file "$state_file" --get pushup.source 2>/dev/null || true)"
  state_phase="$(git config --file "$state_file" --get pushup.phase 2>/dev/null || true)"

  [[ "$state_version" == 2 && "$state_source" == "$1" ]] || return 1
  [[ "$state_phase" == source-synchronized || \
    "$state_phase" == source-publishing || "$state_phase" == source-publish-failed ]]
}

bt_push_has_pending_pushup_pr() {
  [[ "$PENDING_PUSHUP" == true && -n "$PENDING_PUSHUP_PR" && \
    "$PENDING_PUSHUP_PR" != "none" ]]
}

bt_push_get_pushup_pr_state() {
  bt_run_remote_command gh pr view "$PENDING_PUSHUP_PR" \
    --json state --jq '.state' 2>/dev/null
}

bt_push_validate_pushup_pr_approval() {
  local fields=""
  local state=""
  local is_draft=""
  local head_ref=""
  local base_ref=""
  local head_oid=""
  local review_decision=""
  local merged_at=""
  local approval_id=""

  bt_push_has_pending_pushup_pr || return 0
  [[ -n "$PENDING_PUSHUP_SOURCE_TIP" ]] || return 1

  if ! fields="$(bt_run_remote_command gh pr view "$PENDING_PUSHUP_PR" \
    --json state,isDraft,headRefName,headRefOid,baseRefName,reviewDecision,mergedAt \
    --jq '[.state, (.isDraft|tostring), .headRefName, .baseRefName, \
      .headRefOid, .reviewDecision, (.mergedAt // "")] | @tsv' \
    2>/dev/null)"; then
    return 1
  fi
  IFS=$'\t' read -r state is_draft head_ref base_ref head_oid \
    review_decision merged_at <<< "$fields"

  [[ "$state" == "OPEN" && "$is_draft" != "true" && -z "$merged_at" && \
    "$head_ref" == "$PENDING_PUSHUP_SOURCE" && \
    "$base_ref" == "$PENDING_PUSHUP_TARGET" && \
    "$head_oid" == "$PENDING_PUSHUP_SOURCE_TIP" && \
    "$review_decision" == "APPROVED" ]] || return 1

  if ! approval_id="$(bt_run_remote_command gh api --paginate \
    "repos/{owner}/{repo}/pulls/$PENDING_PUSHUP_PR/reviews" \
    --jq ".[] | select(.state == \"APPROVED\" and .commit_id == \"$head_oid\") | .id" \
    2>/dev/null)"; then
    return 1
  fi
  [[ -n "$approval_id" ]]
}

bt_push_finalize_pushup_pr() {
  local pushed_tip="$1"
  local body_file=""
  local comment_bodies=""
  local marker="<!-- briteRepo-pushup-published:${pushed_tip} -->"

  bt_push_has_pending_pushup_pr || return 0
  bt_push_validate_pushup_pr_approval || return 1

  if ! comment_bodies="$(bt_run_remote_command gh pr view "$PENDING_PUSHUP_PR" \
    --json comments --jq '.comments[].body' 2>/dev/null)"; then
    return 1
  fi

  if ! printf '%s\n' "$comment_bodies" | grep -Fq -- "$marker"; then
    body_file="$(mktemp)"
    cat > "$body_file" <<EOF
$marker

## pushup Published

Source branch: \`$PENDING_PUSHUP_SOURCE\`

Parent branch: \`$PENDING_PUSHUP_TARGET\`

Published tip: \`$pushed_tip\`
EOF
    if ! bt_run_remote_command gh pr comment "$PENDING_PUSHUP_PR" \
      --body-file "$body_file" >/dev/null 2>&1; then
      rm -f "$body_file"
      return 1
    fi
    rm -f "$body_file"
  fi

  if ! bt_run_remote_command gh pr close "$PENDING_PUSHUP_PR" \
    >/dev/null 2>&1; then
    return 1
  fi

  return 0
}

push_validate_prerequisites() {
  local timeout_seconds="$PUSH_TIMEOUT_SECONDS"
  local current_branch=""
  local remote_probe_rc=0
  local required_tool=""
  local -a missing_tools=()

  for required_tool in \
    git awk sed grep wc cksum flock chmod rm mkdir head date; do
    command -v "$required_tool" >/dev/null 2>&1 || \
      missing_tools+=("$required_tool")
  done
  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    bt_emit_prerequisite_failure 1 \
      "Missing required tool(s): ${missing_tools[*]}." \
      "run push in a standard repository shell environment and try again."
  fi

  current_branch="$(bt_get_current_branch || true)"
  if bt_is_current_internal_remote_copy; then
    bt_emit_prerequisite_failure 3 \
      "Current branch '$current_branch' is a read-only remote copy." \
      "switch to a local targeted or contributor branch, then retry push."
  fi
  if [[ -z "$current_branch" || "$current_branch" == "HEAD" ]] || \
    ! git show-ref --verify --quiet "refs/heads/$current_branch"; then
    bt_emit_prerequisite_failure 1 \
      "Not on a local branch. Use 'chbranch' to switch to a local non-protected branch, then retry." \
      "switch to a local branch and rerun push."
  fi
  push_load_pending_pushup "$current_branch"
  if ! push_require_contributor_role; then
    bt_emit_prerequisite_failure 2 \
      "User is not a contributor." \
      "use an account and merge path authorized by repository policy, then rerun push."
  fi
  if bt_is_protected_branch "$current_branch" && \
    [[ "$PENDING_PUSHUP" != true ]] && \
    ! push_is_pushup_source_sync "$current_branch"; then
    bt_emit_prerequisite_failure 3 \
      "Cannot push protected branch '$current_branch' via push. Use the standard release workflow" \
      "for protected branches."
  fi
  if bt_push_has_pending_pushup_pr && \
    ! bt_push_validate_pushup_pr_approval; then
    bt_emit_prerequisite_failure 202 \
      "Pull request #$PENDING_PUSHUP_PR is no longer approved for the source commit merged by pushup." \
      "review and approve the current source commit, rerun pushup, then rerun push."
  fi
  if bt_is_protected_branch "$current_branch" && \
    ! push_require_approver_role && \
    ! bt_push_has_pending_pushup_pr; then
    bt_emit_prerequisite_failure 2 \
      "Pushing merged protected branch '$current_branch' requires an approver or a contributor with a PR approved for the recorded source commit." \
      "restore current PR approval or use an approver account, then rerun push."
  fi
  if bt_is_read_only_branch "$current_branch" && \
    [[ "$PENDING_PUSHUP" != true ]] && \
    ! push_is_pushup_source_sync "$current_branch"; then
    bt_emit_prerequisite_failure 3 \
      "Cannot push policy-invalid read-only branch '$current_branch'." \
      "switch to a valid targeted or contributor branch and rerun push."
  fi
  if [[ "$PENDING_PUSHUP" != true ]] && \
    ! push_is_pushup_source_sync "$current_branch" && \
    ! push_is_targeted_branch "$current_branch" && \
    ! push_is_contributor_branch "$current_branch"; then
    bt_emit_prerequisite_failure 1 \
      "Current branch must be a targeted or contributor branch. Use " \
      "chbranch or mkbranch to switch to a supported local branch, then retry."
  fi

  if [[ "$PENDING_PUSHUP" == true && -n "$PENDING_PUSHUP_PR" && \
    "$PENDING_PUSHUP_PR" != "none" ]] && ! command -v gh >/dev/null 2>&1; then
    bt_emit_prerequisite_failure 1 \
      "GitHub CLI is required to finalize pull request #$PENDING_PUSHUP_PR." \
      "install gh and rerun push."
  fi
  if bt_is_copyfix_in_progress "$current_branch"; then
    bt_emit_prerequisite_failure 1 \
      "Current branch '$current_branch' has an unfinished copyfix operation." \
      "rerun copyfix to complete it before rerunning push."
  fi
  if push_worktree_has_blocking_changes; then
    bt_emit_prerequisite_failure 1 \
      "Current branch has uncommitted changes." \
      "Commit or undo them before running push."
  fi
  if ! git remote get-url origin >/dev/null 2>&1; then
    bt_emit_prerequisite_failure 4 \
      "This clone has no remote repository." \
      "add the repository's remote URL, then rerun push."
  fi
  bt_git_ls_remote_origin_with_timeout \
    "$(git rev-parse --show-toplevel)" \
    "$timeout_seconds" >/dev/null 2>&1 || remote_probe_rc=$?
  if [[ "$remote_probe_rc" -eq 124 ]]; then
    bt_emit_prerequisite_failure 6 \
      "The remote repository did not respond within ${timeout_seconds}s." \
      "restore network access or increase -t, then rerun push."
  elif [[ "$remote_probe_rc" -ne 0 ]]; then
    bt_emit_prerequisite_failure 5 \
      "The remote repository could not be reached." \
      "check network access and authentication, then rerun push."
  fi

  export BT_REMOTE_TIMEOUT_SECONDS="$timeout_seconds"
}

# Run the push workflow for the validated globals set by the caller.
bt_push_run() {
  [[ "$PUSH_ENTRY_MODE" != "--pushup-source" ]] || PUSHUP_SOURCE_SYNC=true
  if [[ "$PUSH_ENTRY_MODE" == "--public" ]]; then
    BT_PUSH_COMMAND_LINE="$(bt_format_command_line "push" "${ORIGINAL_ARGS[@]}")"
    BT_PUSH_AUTHORITY=""
  else
    BT_PUSH_COMMAND_LINE="$(pushup_state_value command-line)"
    [[ -n "$BT_PUSH_COMMAND_LINE" ]] || \
      push_error_exit 1 "Active pushup state is missing its initiating command"
    if [[ "$(pushup_state_value owner-override)" == true ]]; then
      BT_PUSH_AUTHORITY="owner"
    else
      BT_PUSH_AUTHORITY=""
    fi
  fi
  export BT_PUSH_COMMAND_LINE
  export BT_PUSH_AUTHORITY
  push_validate_prerequisites
  bt_push_workflow "${PUSH_WORKFLOW_ARGS[@]}"
}
