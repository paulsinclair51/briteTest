#!/usr/bin/env bash

# Shared Git branch and history helpers.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

# High-Level Flow:
# - Provides shared Git helper functions for branch lookup, status checks, and
#   history operations.
# - Encapsulates repeated Git command patterns used by briteRepo/bin workflows.
# - Standardizes error handling and output for Git-related helper calls.

bt_is_valid_remote_timeout() {
  [[ "$1" =~ ^[0-9]+$ ]] && [[ "$1" -gt 0 ]]
}

bt_run_remote_command() {
  local timeout_seconds="${BT_REMOTE_TIMEOUT_SECONDS:-10}"

  bt_is_valid_remote_timeout "$timeout_seconds" || return 125

  if command -v timeout >/dev/null 2>&1; then
    timeout "${timeout_seconds}s" "$@"
    return $?
  fi

  "$@"
}

bt_git_preferred_branch_ref() {
  local mode="$1"
  local branch="$2"

  if [[ "$mode" == "remote" ]] && \
    git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    printf 'refs/remotes/origin/%s\n' "$branch"
  elif git show-ref --verify --quiet "refs/heads/$branch"; then
    printf 'refs/heads/%s\n' "$branch"
  elif git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    printf 'refs/remotes/origin/%s\n' "$branch"
  fi
}

bt_git_format_tracking_relation_tag() {
  local mode="$1"
  local ahead="$2"
  local behind="$3"
  local has_uncommitted="$4"

  [[ "$ahead" =~ ^[0-9]+$ && "$behind" =~ ^[0-9]+$ ]] || return 0

  if [[ "$ahead" -eq 0 && "$behind" -eq 0 ]]; then
    return 0
  elif [[ "$ahead" -gt 0 && "$behind" -eq 0 ]]; then
    if [[ "$mode" == "local" ]]; then
      printf '[ahead of remote by %s]' "$ahead"
    else
      printf '[behind local by %s]' "$ahead"
    fi
  elif [[ "$ahead" -eq 0 && "$behind" -gt 0 ]]; then
    if [[ "$mode" == "local" ]]; then
      printf '[behind remote by %s]' "$behind"
    else
      printf '[ahead of local by %s]' "$behind"
    fi
  elif [[ "$mode" == "local" ]]; then
    printf '[diverged from remote: %s/%s]' "$ahead" "$behind"
  else
    printf '[diverged from local: %s/%s]' "$behind" "$ahead"
  fi
  return 0
}

bt_git_format_parent_relation_tags() {
  local parent="$1"
  local ahead="$2"
  local behind="$3"
  local available="$4"

  [[ -n "$parent" ]] || return 0
  if [[ "$available" != true ]]; then
    printf '[parent unavailable: %s]' "$parent"
    return 0
  fi

  printf '[parent: %s]' "$parent"
  [[ "$ahead" =~ ^[0-9]+$ && "$behind" =~ ^[0-9]+$ ]] || return 0

  if [[ "$ahead" -gt 0 && "$behind" -eq 0 ]]; then
    printf ' [ahead of parent by %s]' "$ahead"
  elif [[ "$ahead" -eq 0 && "$behind" -gt 0 ]]; then
    printf ' [behind parent by %s]' "$behind"
  elif [[ "$ahead" -gt 0 && "$behind" -gt 0 ]]; then
    printf ' [diverged from parent: %s/%s]' "$ahead" "$behind"
  fi
  return 0
}

bt_git_tracking_relation_tag() {
  local mode="$1"
  local local_ref="$2"
  local remote_ref="$3"
  local has_uncommitted="$4"
  local ahead=0
  local behind=0
  local counts=""

  counts=$(git rev-list --left-right --count \
    "$local_ref...$remote_ref" 2>/dev/null || true)
  read -r ahead behind <<< "$counts"
  bt_git_format_tracking_relation_tag \
    "$mode" "$ahead" "$behind" "$has_uncommitted"
}

bt_git_parent_relation_tags() {
  local mode="$1"
  local branch="$2"
  local selected_ref="$3"
  local parent=""
  local parent_ref=""
  local ahead=0
  local behind=0
  local counts=""
  local merge_base=""
  local available=false

  parent=$(bt_resolve_parent_branch "$branch" "main" 2>/dev/null || true)
  [[ -n "$parent" ]] || return 0
  parent_ref=$(bt_git_preferred_branch_ref "$mode" "$parent")

  if [[ -n "$parent_ref" ]]; then
    available=true
    if git diff --quiet "$selected_ref" "$parent_ref" 2>/dev/null; then
      printf '[parent: %s]' "$parent"
      return 0
    fi
    counts=$(git rev-list --left-right --count \
      "$selected_ref...$parent_ref" 2>/dev/null || true)
    read -r ahead behind <<< "$counts"
    if [[ "$behind" =~ ^[0-9]+$ && "$behind" -gt 0 ]]; then
      merge_base="$(git merge-base "$selected_ref" "$parent_ref" \
        2>/dev/null || true)"
      if [[ -n "$merge_base" ]] && \
        git diff --quiet "$merge_base" "$parent_ref" 2>/dev/null; then
        behind=0
      fi
    fi
  fi
  bt_git_format_parent_relation_tags \
    "$parent" "$ahead" "$behind" "$available"
}

bt_git_reset_change_summary() {
  BT_CHANGE_MODIFIED_FILES=0
  BT_CHANGE_DELETED_FILES=0
  BT_CHANGE_ADDED_FILES=0
  BT_CHANGE_RENAMED_FILES=0
  BT_CHANGE_RENAMED_MODIFIED_FILES=0
  BT_CHANGE_DELETED_DIRECTORIES=0
  BT_CHANGE_ADDED_DIRECTORIES=0
  BT_CHANGE_RENAMED_DIRECTORIES=0
  # Rows are "<directory>|<action>" for report Directories tables.
  BT_CHANGE_DIRECTORY_ROWS=()
}

bt_git_list_parent_directories() {
  local files_file="$1"
  local output_file="$2"
  local file_path=""
  local directory=""

  : > "$output_file"
  while IFS= read -r file_path; do
    directory="${file_path%/*}"
    while [[ "$directory" != "$file_path" && "$directory" != "." ]]; do
      printf '%s\n' "$directory" >> "$output_file"
      file_path="$directory"
      directory="${file_path%/*}"
    done
  done < "$files_file"
  sort -u -o "$output_file" "$output_file"
}

bt_git_collect_change_summary_from_files() {
  local status_file="$1"
  local old_files="$2"
  local new_files="$3"
  local old_directories=""
  local new_directories=""
  local renamed_directory_pairs=""
  local renamed_old_directories=""
  local renamed_new_directories=""
  local status=""
  local old_path=""
  local new_path=""
  local old_directory=""
  local new_directory=""
  local directory=""

  bt_git_reset_change_summary
  old_directories="$(mktemp)"
  new_directories="$(mktemp)"
  renamed_directory_pairs="$(mktemp)"
  renamed_old_directories="$(mktemp)"
  renamed_new_directories="$(mktemp)"
  bt_git_list_parent_directories "$old_files" "$old_directories"
  bt_git_list_parent_directories "$new_files" "$new_directories"

  exec 8<"$status_file"
  while IFS= read -r -d '' status <&8; do
    case "$status" in
      A*)
        IFS= read -r -d '' new_path <&8 || new_path=""
        ((++BT_CHANGE_ADDED_FILES))
        ;;
      D*)
        IFS= read -r -d '' old_path <&8 || old_path=""
        ((++BT_CHANGE_DELETED_FILES))
        ;;
      R*)
        IFS= read -r -d '' old_path <&8 || old_path=""
        IFS= read -r -d '' new_path <&8 || new_path=""
        if [[ "$status" == "R100" ]]; then
          ((++BT_CHANGE_RENAMED_FILES))
        else
          ((++BT_CHANGE_RENAMED_MODIFIED_FILES))
        fi
        old_directory="${old_path%/*}"
        new_directory="${new_path%/*}"
        if [[ "$old_directory" != "$old_path" && \
          "$new_directory" != "$new_path" && \
          "$old_directory" != "$new_directory" ]]; then
          printf '%s\t%s\n' "$old_directory" "$new_directory" \
            >> "$renamed_directory_pairs"
        fi
        ;;
      *)
        IFS= read -r -d '' new_path <&8 || new_path=""
        ((++BT_CHANGE_MODIFIED_FILES))
        ;;
    esac
  done
  exec 8<&-

  sort -u -o "$renamed_directory_pairs" "$renamed_directory_pairs"
  cut -f1 "$renamed_directory_pairs" | sort -u \
    > "$renamed_old_directories"
  cut -f2 "$renamed_directory_pairs" | sort -u \
    > "$renamed_new_directories"
  BT_CHANGE_RENAMED_DIRECTORIES="$(wc -l \
    < "$renamed_directory_pairs" | tr -d ' ')"

  while IFS= read -r directory; do
    [[ -n "$directory" ]] || continue
    grep -Fxq -- "$directory" "$new_directories" && continue
    grep -Fxq -- "$directory" "$renamed_old_directories" && continue
    ((++BT_CHANGE_DELETED_DIRECTORIES))
    BT_CHANGE_DIRECTORY_ROWS+=("$directory|Deleted")
  done < "$old_directories"
  while IFS= read -r directory; do
    [[ -n "$directory" ]] || continue
    grep -Fxq -- "$directory" "$old_directories" && continue
    grep -Fxq -- "$directory" "$renamed_new_directories" && continue
    ((++BT_CHANGE_ADDED_DIRECTORIES))
    BT_CHANGE_DIRECTORY_ROWS+=("$directory|Added")
  done < "$new_directories"
  while IFS=$'\t' read -r old_directory new_directory; do
    [[ -n "$old_directory" && -n "$new_directory" ]] || continue
    BT_CHANGE_DIRECTORY_ROWS+=("$new_directory|Renamed (was $old_directory)")
  done < "$renamed_directory_pairs"

  rm -f "$old_directories" "$new_directories" \
    "$renamed_directory_pairs" "$renamed_old_directories" \
    "$renamed_new_directories"
}

bt_git_collect_ref_change_summary() {
  local old_ref="$1"
  local new_ref="$2"
  local status_file=""
  local old_files=""
  local new_files=""
  local excluded_files=""
  local excluded_path=""
  local -a pathspecs=(-- .)

  shift 2
  excluded_files="$(mktemp)"
  for excluded_path in "$@"; do
    [[ -n "$excluded_path" ]] || continue
    excluded_path="${excluded_path#./}"
    printf '%s\n' "$excluded_path" >> "$excluded_files"
    pathspecs+=(":(exclude)$excluded_path")
  done

  status_file="$(mktemp)"
  old_files="$(mktemp)"
  new_files="$(mktemp)"
  git diff --name-status -z --find-renames "$old_ref" "$new_ref" \
    "${pathspecs[@]}" > "$status_file" 2>/dev/null || true
  git ls-tree -r --name-only "$old_ref" > "$old_files" 2>/dev/null || true
  git ls-tree -r --name-only "$new_ref" > "$new_files" 2>/dev/null || true
  if [[ -s "$excluded_files" ]]; then
    grep -Fvx -f "$excluded_files" "$old_files" > "${old_files}.filtered" || true
    grep -Fvx -f "$excluded_files" "$new_files" > "${new_files}.filtered" || true
    mv "${old_files}.filtered" "$old_files"
    mv "${new_files}.filtered" "$new_files"
  fi
  bt_git_collect_change_summary_from_files "$status_file" "$old_files" "$new_files"
  rm -f "$status_file" "$old_files" "$new_files" "$excluded_files"
}

bt_git_collect_worktree_change_summary() {
  local status_file=""
  local old_files=""
  local new_files=""
  local file_path=""

  status_file="$(mktemp)"
  old_files="$(mktemp)"
  new_files="$(mktemp)"
  git diff HEAD --name-status -z --find-renames > "$status_file" 2>/dev/null || true
  while IFS= read -r -d '' file_path; do
    printf 'A\0%s\0' "$file_path" >> "$status_file"
  done < <(git ls-files --others --exclude-standard -z 2>/dev/null || true)
  git ls-tree -r --name-only HEAD > "$old_files" 2>/dev/null || true
  while IFS= read -r -d '' file_path; do
    [[ -e "$file_path" || -L "$file_path" ]] && printf '%s\n' "$file_path"
  done < <(git ls-files -co --exclude-standard -z 2>/dev/null || true) \
    | sort -u > "$new_files"
  bt_git_collect_change_summary_from_files "$status_file" "$old_files" "$new_files"
  rm -f "$status_file" "$old_files" "$new_files"
}

bt_format_change_summary() {
  local -a parts=()
  local output=""
  local index=0

  bt_append_change_summary_part() {
    local count="$1"
    local singular="$2"
    local plural="$3"
    [[ "$count" -gt 0 ]] || return 0
    if [[ "$count" -eq 1 ]]; then
      parts+=("$count $singular")
    else
      parts+=("$count $plural")
    fi
  }

  bt_append_change_summary_part "$BT_CHANGE_MODIFIED_FILES" \
    "modified file" "modified files"
  bt_append_change_summary_part "$BT_CHANGE_DELETED_FILES" \
    "deleted file" "deleted files"
  bt_append_change_summary_part "$BT_CHANGE_ADDED_FILES" \
    "added file" "added files"
  bt_append_change_summary_part "$BT_CHANGE_RENAMED_FILES" \
    "renamed file" "renamed files"
  bt_append_change_summary_part "$BT_CHANGE_RENAMED_MODIFIED_FILES" \
    "renamed/modified file" "renamed/modified files"
  bt_append_change_summary_part "$BT_CHANGE_DELETED_DIRECTORIES" \
    "deleted directory" "deleted directories"
  bt_append_change_summary_part "$BT_CHANGE_ADDED_DIRECTORIES" \
    "added directory" "added directories"
  bt_append_change_summary_part "$BT_CHANGE_RENAMED_DIRECTORIES" \
    "renamed directory" "renamed directories"

  if [[ "${#parts[@]}" -eq 0 ]]; then
    printf 'no changes'
    return 0
  fi
  if [[ "${#parts[@]}" -eq 1 ]]; then
    printf '%s' "${parts[0]}"
    return 0
  fi
  for ((index = 0; index < ${#parts[@]}; index++)); do
    if [[ "$index" -gt 0 ]]; then
      if [[ "$index" -eq $((${#parts[@]} - 1)) ]]; then
        output+=" and "
      else
        output+=", "
      fi
    fi
    output+="${parts[index]}"
  done
  printf '%s' "$output"
}


bt_copyfix_state_dir_for_branch() {
  local branch="$1"
  local common_dir=""

  if bt_is_internal_remote_copy "$branch"; then
    branch="${branch#r-}"
  fi

  common_dir="$(git rev-parse --path-format=absolute --git-common-dir \
    2>/dev/null)" || return 1
  printf '%s/briteRepo-copyfix-state/%s\n' "$common_dir" "$branch"
}

bt_is_copyfix_in_progress() {
  local branch="$1"
  local state_dir=""

  state_dir="$(bt_copyfix_state_dir_for_branch "$branch")" || return 1
  [[ -d "$state_dir" ]]
}

bt_git_is_repository() {
  local repo_path="$1"
  git -C "$repo_path" rev-parse --git-dir >/dev/null 2>&1
}

bt_git_get_origin_url_or_empty() {
  local repo_path="$1"
  git -C "$repo_path" remote get-url origin 2>/dev/null || true
}

bt_git_has_origin() {
  local repo_path="$1"
  [[ -n "$(bt_git_get_origin_url_or_empty "$repo_path")" ]]
}

bt_git_ls_remote_origin_with_timeout() {
  local repo_path="$1"
  local timeout_seconds="$2"

  BT_REMOTE_TIMEOUT_SECONDS="$timeout_seconds" bt_run_remote_command \
    git -C "$repo_path" ls-remote --exit-code origin HEAD >/dev/null 2>&1
}

bt_git_run_with_retry() {
  local attempts="$1"
  local base_delay_seconds="$2"
  shift 2

  local attempt=1
  local delay="$base_delay_seconds"
  local rc=0

  while [[ "$attempt" -le "$attempts" ]]; do
    "$@"
    rc=$?
    if [[ "$rc" -eq 0 ]]; then
      return 0
    fi

    if [[ "$attempt" -ge "$attempts" ]]; then
      return "$rc"
    fi

    # Exponential backoff to smooth over transient remote/network failures.
    sleep "$delay"
    delay=$((delay * 2))
    attempt=$((attempt + 1))
  done

  return "$rc"
}

bt_git_ls_remote_origin_with_timeout_and_retry() {
  local repo_path="$1"
  local timeout_seconds="$2"
  local attempts="$3"
  local base_delay_seconds="$4"

  bt_git_run_with_retry "$attempts" "$base_delay_seconds" \
    bt_git_ls_remote_origin_with_timeout "$repo_path" "$timeout_seconds"
}

bt_git_fetch_prune_origin_with_retry() {
  local repo_path="$1"
  local attempts="$2"
  local base_delay_seconds="$3"

  bt_git_run_with_retry "$attempts" "$base_delay_seconds" \
    git -C "$repo_path" fetch --prune origin
}

bt_git_is_rebase_in_progress() {
  local rebase_dir=""

  for rebase_dir in \
    "$(git rev-parse --git-path rebase-merge 2>/dev/null || true)" \
    "$(git rev-parse --git-path rebase-apply 2>/dev/null || true)"; do
    [[ -d "$rebase_dir" ]] || continue
    [[ -n "$(find "$rebase_dir" -mindepth 1 -print -quit 2>/dev/null)" ]] && \
      return 0
  done
  return 1
}

bt_git_rebase_head_branch() {
  local head_name=""
  local path=""

  for path in \
    "$(git rev-parse --git-path rebase-merge/head-name 2>/dev/null || true)" \
    "$(git rev-parse --git-path rebase-apply/head-name 2>/dev/null || true)"; do
    [[ -f "$path" ]] || continue
    head_name="$(tr -d '\n' < "$path")"
    break
  done

  [[ -n "$head_name" ]] || return 1
  head_name="${head_name#refs/heads/}"
  [[ -n "$head_name" ]] || return 1
  printf '%s\n' "$head_name"
}

bt_git_conflict_files() {
  local conflict_files=""

  conflict_files="$(git diff --name-only --diff-filter=U 2>/dev/null || true)"
  if [[ -z "$conflict_files" ]]; then
    conflict_files="$(git --no-optional-locks status --porcelain \
      2>/dev/null | awk '/^UU / {print $2}')"
  fi
  [[ -n "$conflict_files" ]] || \
    conflict_files="(unable to determine conflicting files)"
  printf '%s\n' "$conflict_files"
}

bt_git_stage_resolved_rebase_files() {
  local conflict_path=""
  local unresolved=false

  while IFS= read -r -d '' conflict_path; do
    [[ -f "$conflict_path" ]] || {
      git add -A -- "$conflict_path" >/dev/null 2>&1 || return 1
      continue
    }
    if grep -Eq '^(<<<<<<<|=======|>>>>>>>)' -- "$conflict_path"; then
      unresolved=true
      continue
    fi
    git add -A -- "$conflict_path" >/dev/null 2>&1 || return 1
  done < <(git diff --name-only --diff-filter=U -z 2>/dev/null || true)

  [[ "$unresolved" == false ]]
}

bt_git_workflow_marker_path() {
  local action="$1"
  git rev-parse --git-path "briteRepo/${action}.in-progress" 2>/dev/null || true
}

bt_git_mark_workflow_in_progress() {
  local action="$1"
  local branch="$2"
  local marker=""

  marker="$(bt_git_workflow_marker_path "$action")"
  [[ -n "$marker" ]] || return 1
  mkdir -p "$(dirname "$marker")" || return 1
  printf '%s\n' "$branch" > "$marker"
}

bt_git_clear_workflow_in_progress() {
  local action="$1"
  local marker=""

  marker="$(bt_git_workflow_marker_path "$action")"
  [[ -z "$marker" ]] || rm -f "$marker"
}

bt_git_workflow_marker_matches() {
  local action="$1"
  local branch="$2"
  local marker=""
  local marker_branch=""

  marker="$(bt_git_workflow_marker_path "$action")"
  [[ -f "$marker" ]] || return 1
  marker_branch="$(tr -d '\n' < "$marker" 2>/dev/null || true)"
  [[ "$marker_branch" == "$branch" ]]
}

bt_git_workflow_in_progress_tags() {
  local branch="$1"
  local pushup_state=""
  local pushup_source=""
  local pushup_parent=""
  local pushup_phase=""
  local current_branch=""
  local tags=()

  if bt_is_copyfix_in_progress "$branch"; then
    tags+=('[copyfix in progress]')
  fi

  pushup_state="$(git rev-parse --git-path briteRepo/pushup.state \
    2>/dev/null || true)"
  if [[ -f "$pushup_state" ]]; then
    pushup_source="$(git config --file "$pushup_state" \
      --get pushup.source 2>/dev/null || true)"
    pushup_parent="$(git config --file "$pushup_state" \
      --get pushup.parent 2>/dev/null || true)"
    pushup_phase="$(git config --file "$pushup_state" \
      --get pushup.phase 2>/dev/null || true)"
    if [[ "$branch" == "$pushup_source" || "$branch" == "$pushup_parent" ]] && \
      [[ "$pushup_phase" != source-published ]]; then
      tags+=('[pushup in progress]')
    fi
  fi

  current_branch="$(git symbolic-ref -q --short HEAD 2>/dev/null || true)"
  if [[ "$branch" == "$current_branch" ]]; then
    if bt_git_workflow_marker_matches pull "$branch" && \
      bt_git_is_rebase_in_progress; then
      tags+=('[pull in progress]')
    elif bt_git_workflow_marker_matches retarget "$branch" && \
      bt_git_is_rebase_in_progress; then
      tags+=('[retarget in progress]')
    elif bt_git_workflow_marker_matches pulldown "$branch" && \
      git rev-parse -q --verify MERGE_HEAD >/dev/null 2>&1; then
      tags+=('[pulldown in progress]')
    fi
  fi

  [[ ${#tags[@]} -eq 0 ]] || printf '%s ' "${tags[*]}"
}

bt_git_workflow_in_progress_action() {
  local branch="$1"
  local pushup_state=""
  local pushup_source=""
  local pushup_parent=""
  local pushup_phase=""

  if bt_is_copyfix_in_progress "$branch"; then
    printf 'copyfix\n'
    return 0
  fi
  pushup_state="$(git rev-parse --git-path briteRepo/pushup.state \
    2>/dev/null || true)"
  if [[ -f "$pushup_state" ]]; then
    pushup_source="$(git config --file "$pushup_state" \
      --get pushup.source 2>/dev/null || true)"
    pushup_parent="$(git config --file "$pushup_state" \
      --get pushup.parent 2>/dev/null || true)"
    pushup_phase="$(git config --file "$pushup_state" \
      --get pushup.phase 2>/dev/null || true)"
    if [[ "$branch" == "$pushup_source" || "$branch" == "$pushup_parent" ]] && \
      [[ "$pushup_phase" != source-published ]]; then
      printf 'pushup\n'
      return 0
    fi
  fi
  if bt_git_workflow_marker_matches pull "$branch" && \
    bt_git_is_rebase_in_progress; then
    printf 'pull\n'
  elif bt_git_workflow_marker_matches retarget "$branch" && \
    bt_git_is_rebase_in_progress; then
    printf 'retarget\n'
  elif bt_git_workflow_marker_matches pulldown "$branch" && \
    git rev-parse -q --verify MERGE_HEAD >/dev/null 2>&1; then
    printf 'pulldown\n'
  fi
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

# Rename action text for report tables. The source keeps only its base name.
# Rename action text for report tables. The source is shown as a bare file
# name when the directory is unchanged, and as a full path when the file
# moved between directories.
bt_git_rename_action_text() {
  local old_path="$1"
  local new_path="$2"
  local modified="${3:-false}"
  local old_dir="${old_path%/*}"
  local new_dir="${new_path%/*}"
  local source_text="${old_path##*/}"

  [[ "$old_dir" == "$old_path" ]] && old_dir=""
  [[ "$new_dir" == "$new_path" ]] && new_dir=""
  [[ "$old_dir" == "$new_dir" ]] || source_text="$old_path"

  if [[ "$modified" == true ]]; then
    printf 'Modified/Renamed (was %s)' "$source_text"
  else
    printf 'Renamed (was %s)' "$source_text"
  fi
}

# Action text for a `git diff --name-status` letter, for example A, D, M,
# R100, or R087. OLD_PATH is required for rename and copy entries.
bt_git_action_from_diff_status() {
  local status="$1"
  local old_path="${2:-}"
  local new_path="${3:-}"

  case "$status" in
    A*) printf 'Added' ;;
    D*) printf 'Deleted' ;;
    C*) printf 'Added' ;;
    R100) bt_git_rename_action_text "$old_path" "$new_path" false ;;
    R*) bt_git_rename_action_text "$old_path" "$new_path" true ;;
    *) printf 'Modified' ;;
  esac
}

# Map paths to report actions from `git diff --name-status` lines on stdin.
# Rename and copy entries are keyed by their destination path.
bt_git_collect_file_actions() {
  local status="" old_path="" new_path=""

  declare -gA BT_FILE_ACTIONS=()
  while IFS=$'\t' read -r status old_path new_path; do
    [[ -n "$status" && -n "$old_path" ]] || continue
    if [[ "$status" == R* || "$status" == C* ]]; then
      [[ -n "$new_path" ]] || continue
      BT_FILE_ACTIONS["$new_path"]="$(bt_git_action_from_diff_status \
        "$status" "$old_path" "$new_path")"
    else
      BT_FILE_ACTIONS["$old_path"]="$(bt_git_action_from_diff_status "$status")"
    fi
  done
}

bt_git_file_action() {
  local file_path="$1"

  printf '%s' "${BT_FILE_ACTIONS[$file_path]:-Modified}"
}

# Branch status tags used in report headers, for example:
# [uncommitted] [local] [parent: v1.0.0] [ahead of parent by 49]
bt_git_branch_status_tags() {
  local branch="$1"
  local mode="$2"
  local local_ref="$branch"
  local remote_ref="origin/$branch"
  local branch_tag=""
  local relation_tag=""
  local parent_tags=""
  local has_local=false
  local has_remote=false
  local has_uncommitted=false

  git show-ref --verify --quiet "refs/heads/$branch" && has_local=true
  git show-ref --verify --quiet "refs/remotes/origin/$branch" && has_remote=true
  if [[ "$mode" == "local" ]] && bt_is_worktree_dirty; then
    has_uncommitted=true
  fi

  if [[ "$mode" == "remote" ]]; then
    if [[ "$has_local" == true ]]; then
      branch_tag="[remote]"
    else
      branch_tag="[remote only]"
    fi
    parent_tags="$(bt_git_parent_relation_tags \
      "remote" "$branch" "$remote_ref")"
  elif [[ "$has_remote" == true ]]; then
    branch_tag="[local]"
    relation_tag="$(bt_git_tracking_relation_tag \
      "local" "$local_ref" "$remote_ref" false)"
    parent_tags="$(bt_git_parent_relation_tags \
      "local" "$branch" "$local_ref")"
  else
    branch_tag="[local only]"
    parent_tags="$(bt_git_parent_relation_tags \
      "local" "$branch" "$local_ref")"
  fi

  if [[ "$has_uncommitted" == true ]]; then
    printf '[uncommitted] '
  fi
  printf '%s' "$branch_tag"
  [[ -z "$relation_tag" ]] || printf ' %s' "$relation_tag"
  [[ -z "$parent_tags" ]] || printf ' %s' "$parent_tags"
}

bt_is_version_branch() {
  local branch="$1"

  [[ "$branch" =~ ^v([1-9][0-9]?)\.(0|[1-9][0-9]?)\.0$ ]]
}

bt_is_targeted_branch() {
  local branch="$1"

  [[ "$branch" =~ ^(dev|fix)/[a-z0-9]+(-[a-z0-9]+)*-v[1-9][0-9]?\.(0|[1-9][0-9]?)\.0$ ]]
}

bt_is_contributor_branch() {
  local branch="$1"
  local desc='[a-z0-9]+(-[a-z0-9]+)*'
  local type='[a-z][a-z]{0,29}'

  [[ "$branch" != "main" ]] &&
    ! bt_is_version_branch "$branch" &&
    ! bt_is_targeted_branch "$branch" &&
    [[ "$branch" =~ ^((${type}/)?${desc})$ ]]
}

bt_is_valid_branch_name() {
  local branch="$1"

  [[ "$branch" == "main" ]] ||
    bt_is_version_branch "$branch" ||
    bt_is_targeted_branch "$branch" ||
    bt_is_contributor_branch "$branch"
}

bt_is_protected_branch() {
  local branch="$1"

  [[ "$branch" == "main" ]] || bt_is_version_branch "$branch"
}

bt_is_read_only_branch() {
  local branch="$1"

  bt_is_protected_branch "$branch" || ! bt_is_valid_branch_name "$branch"
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

  if [[ "$current_branch" =~ ^(dev|fix)/.+-(v[1-9][0-9]?\.(0|[1-9][0-9]?)\.0)$ ]]; then
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
