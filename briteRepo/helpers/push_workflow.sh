#!/usr/bin/env bash

# Shared push workflow used by push and pushup.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

# High-Level Flow:
# - Provides a shared push workflow for both the push and pushup commands.

bt_push_workflow() (
  set -euo pipefail

  local exit_invalid_argument=1
  local exit_remote_branch_not_found=7
  local exit_report_lock_timed_out=8
  local exit_nothing_to_push=10
  local exit_push_failed=200
  local exit_report_failed=201
  local exit_pr_finalize_failed=202

  local repo_root=""
  local reports_dir=""
  local report_file=""
  local run_ts_file=""
  local run_ts_display=""
  local current_branch=""
  local remote_branch_tip=""
  local commits_ahead=0
  local push_content_ref="HEAD"
  local source_branch=""
  local dry_run=false
  local error_run=false
  local pushup_mode=false
  local verbose=false
  local report_lock_fd=""
  local report_lock_held=false
  local pushed_modified_files=0
  local pushed_added_files=0
  local pushed_deleted_files=0
  local pushed_renamed_files=0
  local pushed_renamed_modified_files=0
  local pushed_deleted_directories=0
  local pushed_added_directories=0
  local pushed_renamed_directories=0
  local pushed_change_summary=""
  local -a original_args=("$@")

  bt_push_error_exit() {
    local code="$1"
    local message="$2"
    bt_emit_error "$message"
    exit "$code"
  }

  bt_push_emit_guidance() {
    local message="$1"

    if [[ "$pushup_mode" == true ]]; then
      return 0
    fi

    bt_emit_guidance "$message"
  }

  bt_push_emit_skip_report() {
    local message="Push skipped due to -e option."
    local guidance="Run without -e option."

    bt_push_generate_error_report "$message" "push skipped" "" "$guidance"
    bt_emit_error "$message"
    bt_emit_guidance "$guidance"
    printf 'See %s for details.\n' "${report_file#"${repo_root}"/}"
    exit 9
  }

  bt_push_cleanup() {
    if [[ "$report_lock_held" == true ]]; then
      bt_report_release_lock "$report_lock_fd"
      report_lock_held=false
    fi
  }
  trap bt_push_cleanup EXIT

  bt_push_usage_error() {
    local message="$1"
    if declare -F usage >/dev/null 2>&1; then
      usage
      echo >&2
    fi
    bt_push_error_exit "$exit_invalid_argument" "$message. See usage above for details"
  }

  bt_push_format_command_line() {
    local formatted="push"
    local arg=""
    local skip_next=false

    if [[ "$pushup_mode" == true ]]; then
      formatted="pushup"
    fi
    for arg in "${original_args[@]}"; do
      if [[ "$skip_next" == true ]]; then
        skip_next=false
        continue
      fi
      case "$arg" in
        --pushup|--preview-ref)
          skip_next=true
          continue
          ;;
      esac
      printf -v formatted '%s %q' "$formatted" "$arg"
    done
    printf '%s\n' "$formatted"
  }

  bt_push_acquire_report_lock() {
    local lock_timeout="${BT_PUSH_REPORT_LOCK_TIMEOUT_SECONDS:-10}"
    local lock_result=0

    if [[ ! "$lock_timeout" =~ ^[0-9]+$ || "$lock_timeout" -le 0 ]]; then
      bt_push_error_exit "$exit_report_failed" \
        "Invalid report lock timeout '$lock_timeout'. Set BT_PUSH_REPORT_LOCK_TIMEOUT_SECONDS to an integer greater than 0"
    fi
    if bt_report_acquire_lock "$repo_root" "push" "$lock_timeout" report_lock_fd; then
      report_lock_held=true
      return
    else
      lock_result=$?
    fi
    if [[ "$lock_result" -eq 1 ]]; then
      bt_push_error_exit "$exit_report_lock_timed_out" \
        "Timed out waiting ${lock_timeout}s for report write lock"
    fi
    bt_push_error_exit "$exit_report_failed" "Failed to acquire report write lock"
  }

  bt_push_release_report_lock() {
    bt_report_release_lock "$report_lock_fd"
    report_lock_fd=""
    report_lock_held=false
  }

  bt_push_enable_report_writes() {
    bt_report_dir_enable_writes "$reports_dir" "$exit_report_failed"
  }

  bt_push_format_commit_timestamp() {
    local value="${1:-}"

    value="${value//$'\r'/}"
    if [[ -z "$value" ]]; then
      printf '%s' ""
      return 0
    fi

    value="${value//Z/+00:00}"
    if [[ "$value" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})T([0-9]{2}:[0-9]{2}:[0-9]{2})([+-][0-9]{2}:[0-9]{2})$ ]]; then
      printf '%s %s%s' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}"
      return 0
    fi
    if [[ "$value" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})[[:space:]]+([0-9]{2}:[0-9]{2}:[0-9]{2})([+-][0-9]{2})([0-9]{2})$ ]]; then
      printf '%s %s%s:%s' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}"
      return 0
    fi
    if [[ "$value" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})[[:space:]]+([0-9]{2}:[0-9]{2}:[0-9]{2})$ ]]; then
      printf '%s %s+00:00' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
      return 0
    fi

    printf '%s' "$value"
  }

  bt_push_extract_commit_comment() {
    local commit_body="$1"
    local line=""
    local in_user_comment=false
    local comment=""

    while IFS= read -r line; do
      if [[ "$line" == "## User Comment" ]]; then
        in_user_comment=true
        continue
      fi
      if [[ "$in_user_comment" == true && "$line" == "##"* ]]; then
        break
      fi
      if [[ "$in_user_comment" != true ]]; then
        continue
      fi
      if [[ "$line" == "> "* ]]; then
        line="${line#> }"
      elif [[ "$line" == ">" ]]; then
        line=""
      else
        continue
      fi
      if [[ -z "$comment" ]]; then
        comment="$line"
      else
        comment+=$'\n'
        comment+="$line"
      fi
    done <<< "$commit_body"

    if [[ -n "$comment" ]]; then
      comment="${comment//$'\n'/ /}"
      printf '%s' "$comment"
      return 0
    fi

    commit_body="${commit_body//$'\r'/}"
    commit_body="${commit_body%%$'\n'*}"
    commit_body="${commit_body//[$'\n\r']/ }"
    printf '%s' "$commit_body"
  }

  bt_push_cleanup_old_reports() {
    local old_report=""
    local report_branch=""

    for old_report in "$reports_dir"/push-d-*.md "$reports_dir"/push-e-*.md; do
      [[ -e "$old_report" && "$old_report" != "$report_file" ]] || continue
      report_branch="$(grep -E '^\*\*Branch:\*\* ' "$old_report" 2>/dev/null | \
        sed -nE 's/^\*\*Branch:\*\* `([^`]+)`( \((local|remote)\))?[[:space:]]*$/\1/p' | head -n 1 || true)"
      [[ "$report_branch" == "$current_branch" ]] || continue
      chmod u+w "$old_report" >/dev/null 2>&1 || true
      rm -f "$old_report" 2>/dev/null || true
    done
  }

  bt_push_cleanup_success_transient_reports() {
    bt_push_acquire_report_lock
    bt_push_enable_report_writes
    report_file=""
    bt_push_cleanup_old_reports
    bt_push_release_report_lock
  }

  bt_push_generate_error_report() {
    local message="$1"
    local mode_label="${2:-error}"
    local push_output="${3:-}"
    local guidance="${4:-}"
    local command_text=""
    local file=""
    local matched_files=0
    local added=0
    local deleted=0
    local net=0
    local total_lines=0
    local total_added=0
    local total_deleted=0
    local total_net=0
    local total_lines_sum=0
    local num_added=""
    local num_deleted=""
    local rest=""
    local push_lines_added=0
    local push_lines_deleted=0

    command_text="$(bt_push_format_command_line)"
    bt_push_acquire_report_lock
    bt_push_enable_report_writes
    report_file="$(bt_report_transient_path "$reports_dir" "push-e" "$run_ts_file")"

    read -r push_lines_added push_lines_deleted < <(
      git diff --numstat --find-renames "${remote_branch_tip}..${push_content_ref}" 2>/dev/null |
        awk '{ added += $1; deleted += $2 } END { print added + 0, deleted + 0 }'
    )
    local branch_status
    branch_status="$(bt_git_branch_status_tags "$current_branch" "remote" 2>/dev/null || true)"
    [[ -n "$branch_status" ]] || branch_status="[remote]"
    local user_display
    user_display="$(bt_format_login_with_role "$(bt_resolve_login_or_empty)" \
      "$repo_root/config/contributors.md" 2>/dev/null || true)"
    [[ -n "$user_display" ]] || user_display="unknown (contributor)"
    local directories_summary="$(bt_push_format_directory_summary)"
    local files_summary="$(bt_push_format_file_summary)"
    cat > "$report_file" <<EOF
# Error Push Report ${run_ts_display}

**Branch:** \`${current_branch}\`  
**Status:** ${branch_status}  

## 1. push: ${run_ts_display}

**Pushed-Tip:** \`To be determined\`  
**Command:** \`${command_text}\`  
**User:** ${user_display}  
**Commits:** ${commits_ahead}  
EOF
    if [[ -n "$directories_summary" ]]; then
      printf '**Directories:** %s  \n' "$directories_summary" >> "$report_file"
    fi
    if [[ -n "$files_summary" ]]; then
      printf '**Files:** %s.  \n' "$files_summary" >> "$report_file"
      printf '**Lines:** %s added and %s deleted.  \n' \
        "$push_lines_added" "$push_lines_deleted" >> "$report_file"
    fi
    printf '\n**Error:** %s  \n**Guidance:** %s  \n\n<details>\n<summary>Files</summary>\n\n' \
      "$message" "$guidance" >> "$report_file"
    {
      printf '| **File** | **Commit** | **Added** | **Deleted** | **Net** | **Lines** | **Action** |\n'
      printf '| --- | --- | ---: | ---: | ---: | ---: | --- |\n'
    } >> "$report_file"

    bt_git_collect_file_actions < <(git diff --name-status --find-renames \
      "${remote_branch_tip}..${push_content_ref}" 2>/dev/null || true)

    while IFS= read -r file; do
      [[ -n "$file" ]] || continue
      added=0
      deleted=0
      while IFS=$'\t' read -r num_added num_deleted rest; do
        [[ "$num_added" =~ ^[0-9]+$ ]] && added=$((added + num_added))
        [[ "$num_deleted" =~ ^[0-9]+$ ]] && deleted=$((deleted + num_deleted))
      done < <(git diff --numstat --find-renames "${remote_branch_tip}..${push_content_ref}" -- "$file" 2>/dev/null || true)
      net=$((added - deleted))
      total_lines=0
      if git cat-file -e "${push_content_ref}:$file" 2>/dev/null; then
        total_lines="$(git show "${push_content_ref}:$file" 2>/dev/null | wc -l | tr -d ' ')"
      fi
      commit_hash="$(git log -1 --format='%h' "${remote_branch_tip}..${push_content_ref}" -- "$file" 2>/dev/null || true)"
      printf '| `%s` | `%s` | %s | %s | %+d | %s | %s |\n' \
        "$file" "$commit_hash" "$added" "$deleted" "$net" "$total_lines" \
        "$(bt_git_file_action "$file")" >> "$report_file"
      total_added=$((total_added + added))
      total_deleted=$((total_deleted + deleted))
      total_net=$((total_net + net))
      total_lines_sum=$((total_lines_sum + total_lines))
    done < <(git diff --name-only --find-renames "${remote_branch_tip}..${push_content_ref}" 2>/dev/null || true)

    printf '| **Total** |  | %s | %s | %+d | %s |  |\n' \
      "$total_added" "$total_deleted" "$total_net" "$total_lines_sum" \
      >> "$report_file"
    printf '</details>\n' >> "$report_file"

    if [[ "$mode_label" == "push skipped" && -z "$push_output" ]]; then
      {
        echo
        echo "## Push Issue Attribution"
        echo
        echo "Sample remote policy rejection would typically name one or more files."
        echo "- README.md"
        echo
        echo "## Push Error Output"
        echo
        echo "Sample push output:"
        echo "rejected by sample remote policy: README.md policy violation"
        echo
        echo "## Guidance"
        echo
        echo "- Remote policy/hook rejected this push."
        echo "- Push is atomic for this branch update."
        echo
      } >> "$report_file"
    fi

    if [[ -n "$push_output" ]]; then
      {
        echo
        echo "## Push Issue Attribution"
        echo
      } >> "$report_file"
      while IFS= read -r file; do
        [[ -n "$file" ]] || continue
        if printf '%s\n' "$push_output" | grep -Fq -- "$file"; then
          [[ "$matched_files" -ne 0 ]] || \
            echo "Push output references the following file(s):" >> "$report_file"
          printf -- '- %s\n' "$file" >> "$report_file"
          matched_files=1
        fi
      done < <(git diff --name-only --find-renames "${remote_branch_tip}..${push_content_ref}" 2>/dev/null || true)
      if [[ "$matched_files" -eq 0 ]]; then
        echo "Push failed as a group-level operation. No specific file could be identified." >> "$report_file"
      fi

      {
        echo
        echo "## Push Error Output"
        echo
        printf '%s\n' "$push_output"
        echo
        echo "## Guidance"
        echo
        if [[ -n "$guidance" ]]; then
          printf -- '- %s\n' "$guidance"
        else
          echo "- Remote policy/hook rejected this push."
          echo "- Push is atomic for this branch update."
        fi
        echo
      } >> "$report_file"
    fi

    bt_push_cleanup_old_reports
    bt_push_release_report_lock
  }

  bt_push_generate_report() {
    local command_text=""
    local report_heading=""
    local files_count=0
    local file=""
    local added=0
    local deleted=0
    local net=0
    local total_lines=0
    local total_added=0
    local total_deleted=0
    local total_net=0
    local total_lines_sum=0
    local num_added=""
    local num_deleted=""
    local rest=""
    local push_lines_added=0
    local push_lines_deleted=0
    local markdown_break="  "
    local branch_status="[remote]"
    local parent_tags=""
    local report_user=""
    local directory=""
    local old_directory=""
    local new_directory=""
    local directory_action=""
    local directory_count=0
    local name_status=""
    local -a directory_rows=()
    declare -A before_directories=()
    declare -A after_directories=()

    command_text="$(bt_push_format_command_line)"
    report_user="$(bt_resolve_login_or_empty)"
    if [[ "$dry_run" == true ]]; then
      report_heading="# Dry-run Push Report"
    else
      report_heading="# Push Report ${run_ts_display}"
    fi
    bt_push_acquire_report_lock
    bt_push_enable_report_writes
    if [[ "$dry_run" == true ]]; then
      report_file="$(bt_report_transient_path "$reports_dir" "push-d" "$run_ts_file")"
    else
      report_file="$(bt_report_transient_path "$reports_dir" "push" "$run_ts_file")"
    fi
    [[ ! -f "$report_file" ]] || chmod u+w "$report_file" 2>/dev/null || true

    files_count="$(git diff --name-only --find-renames "${remote_branch_tip}..${push_content_ref}" 2>/dev/null | sed '/^$/d' | wc -l | tr -d ' ')"
    [[ "$files_count" =~ ^[0-9]+$ ]] || files_count=0
    read -r push_lines_added push_lines_deleted < <(
      git diff --numstat --find-renames "${remote_branch_tip}..${push_content_ref}" 2>/dev/null |
        awk '{ added += $1; deleted += $2 } END { print added + 0, deleted + 0 }'
    )
    parent_tags="$(bt_git_parent_relation_tags "remote" "$current_branch" \
      "origin/$current_branch")"
    [[ -z "$parent_tags" ]] || branch_status+=" $parent_tags"

    while IFS= read -r file; do
      [[ -n "$file" ]] || continue
      directory="${file%/*}"
      [[ "$directory" == "$file" ]] || before_directories["$directory"]=1
    done < <(git ls-tree -r --name-only "$remote_branch_tip" 2>/dev/null || true)
    while IFS= read -r file; do
      [[ -n "$file" ]] || continue
      directory="${file%/*}"
      [[ "$directory" == "$file" ]] || after_directories["$directory"]=1
    done < <(git ls-tree -r --name-only "$push_content_ref" 2>/dev/null || true)
    for directory in "${!before_directories[@]}"; do
      [[ -n "${after_directories[$directory]+x}" ]] || \
        directory_rows+=("$directory|$(git log -1 --format='%h' "${remote_branch_tip}..${push_content_ref}" -- "$directory" 2>/dev/null || true)|Deleted")
    done
    for directory in "${!after_directories[@]}"; do
      [[ -n "${before_directories[$directory]+x}" ]] || \
        directory_rows+=("$directory|$(git log -1 --format='%h' "${remote_branch_tip}..${push_content_ref}" -- "$directory" 2>/dev/null || true)|Added")
    done
    name_status="$(git diff --name-status --find-renames \
      "${remote_branch_tip}..${push_content_ref}" 2>/dev/null || true)"
    while IFS=$'\t' read -r status old_path new_path; do
      [[ "$status" == R* ]] || continue
      old_directory="${old_path%/*}"
      new_directory="${new_path%/*}"
      [[ "$old_directory" != "$old_path" && \
        "$new_directory" != "$new_path" && \
        "$old_directory" != "$new_directory" ]] || continue
      directory_rows+=("$new_directory|$(git log -1 --format='%h' "${remote_branch_tip}..${push_content_ref}" -- "$new_directory" 2>/dev/null || true)|Renamed (was $old_directory)")
    done <<< "$name_status"
    directory_count="${#directory_rows[@]}"

    if [[ "$dry_run" == true ]]; then
      local directories_summary="$(bt_push_format_directory_summary)"
      local files_summary="$(bt_push_format_file_summary)"

      cat > "$report_file" <<EOF
# Dry-run Push Report

**Branch:** \`${current_branch}\`${markdown_break}
**Status:** ${branch_status}${markdown_break}

## 1. push: ${run_ts_display}

**Pushed-Tip:** \`To be determined\`${markdown_break}
**Command:** \`${command_text}\`${markdown_break}
**User:** ${report_user}${markdown_break}
**Commits:** ${commits_ahead}${markdown_break}
EOF
      if [[ -n "$directories_summary" ]]; then
        printf '**Directories:** %s%s\n' "$directories_summary" "$markdown_break" >> "$report_file"
      fi
      if [[ -n "$files_summary" ]]; then
        printf '**Files:** %s.%s\n' "$files_summary" "$markdown_break" >> "$report_file"
        printf '**Lines:** %s added and %s deleted.\n' \
          "$push_lines_added" "$push_lines_deleted" >> "$report_file"
      fi
      printf '\n<details>\n<summary>Commits</summary>\n\n' >> "$report_file"

      {
        printf '| **Commit** | **Date Time** | **Comment** |\n'
        printf '| --- | --- | --- |\n'
        while IFS= read -r commit_hash; do
          [[ -n "$commit_hash" ]] || continue
          commit_date="$(bt_push_format_commit_timestamp "$(git log -1 --format='%cI' "$commit_hash" 2>/dev/null || true)")"
          commit_body="$(git log -1 --format=%B "$commit_hash" 2>/dev/null || true)"
          commit_comment="$(bt_push_extract_commit_comment "$commit_body")"
          printf '| `%s` | %s | %s |\n' "$commit_hash" "$commit_date" "$commit_comment"
        done < <(git rev-list "${remote_branch_tip}..${push_content_ref}" 2>/dev/null || true)
        echo "</details>"
        echo
        echo "<details>"
        echo "<summary>Files</summary>"
        echo
        printf '| **File** | **Commit** | **Added** | **Deleted** | %s\n' \
          '**Net** | **Lines** | **Action** |'
        echo "| --- | --- | ---: | ---: | ---: | ---: | --- |"
      } >> "$report_file"

      bt_git_collect_file_actions < <(git diff --name-status --find-renames \
        "${remote_branch_tip}..${push_content_ref}" 2>/dev/null || true)

      while IFS= read -r file; do
        [[ -n "$file" ]] || continue
        added=0
        deleted=0
        while IFS=$'\t' read -r num_added num_deleted rest; do
          [[ "$num_added" =~ ^[0-9]+$ ]] && added=$((added + num_added))
          [[ "$num_deleted" =~ ^[0-9]+$ ]] && deleted=$((deleted + num_deleted))
        done < <(git diff --numstat --find-renames "${remote_branch_tip}..${push_content_ref}" -- "$file" 2>/dev/null || true)
        net=$((added - deleted))
        total_lines=0
        if git cat-file -e "${push_content_ref}:$file" 2>/dev/null; then
          total_lines="$(git show "${push_content_ref}:$file" 2>/dev/null | wc -l | tr -d ' ')"
        fi
        commit_hash="$(git log -1 --format='%h' "${remote_branch_tip}..${push_content_ref}" -- "$file" 2>/dev/null || true)"
        printf '| `%s` | `%s` | %s | %s | %s | %s | %s |\n' \
          "$file" "$commit_hash" "$added" "$deleted" "$net" "$total_lines" \
          "$(bt_git_file_action "$file")" >> "$report_file"
        total_added=$((total_added + added))
        total_deleted=$((total_deleted + deleted))
        total_net=$((total_net + net))
        total_lines_sum=$((total_lines_sum + total_lines))
      done < <(git diff --name-only --find-renames "${remote_branch_tip}..${push_content_ref}" 2>/dev/null || true)

      printf '| **Total** |  | %s | %s | %+d | %s |  |\n' \
        "$total_added" "$total_deleted" "$total_net" "$total_lines_sum" \
        >> "$report_file"

      {
        echo "</details>"
      } >> "$report_file"

      if [[ "$directory_count" -gt 0 ]]; then
        {
          echo
          echo '<details>'
          echo '<summary>Directories</summary>'
          echo
          echo '| **Directory** | **Commit** | **Action** |'
          echo '| --- | --- | --- |'
          for directory_row in "${directory_rows[@]}"; do
            directory="${directory_row%%|*}"
            directory_commit="${directory_row#*|}"
            directory_commit="${directory_commit%%|*}"
            directory_action="${directory_row#*|*|}"
            printf '| `%s` | `%s` | %s |\n' "$directory" "$directory_commit" "$directory_action"
          done
          echo '</details>'
        } >> "$report_file"
      fi
    else
      cat > "$report_file" <<EOF
# ${report_heading#\# }

${push_tip_line}

**Command:** \`${command_text}\`
**Branch:** \`${current_branch}\`
**Commits:** ${commits_ahead}

EOF

      {
        echo "## Files"
        echo
        printf '| **File** | **Commit** | **Added** | **Deleted** | %s\n' \
        '**Net** | **Lines** | **Action** |'
        echo "| --- | --- | ---: | ---: | ---: | ---: | --- |"
      } >> "$report_file"

      bt_git_collect_file_actions < <(git diff --name-status --find-renames \
        "${remote_branch_tip}..${push_content_ref}" 2>/dev/null || true)

      while IFS= read -r file; do
        [[ -n "$file" ]] || continue
        added=0
        deleted=0
        while IFS=$'\t' read -r num_added num_deleted rest; do
          [[ "$num_added" =~ ^[0-9]+$ ]] && added=$((added + num_added))
          [[ "$num_deleted" =~ ^[0-9]+$ ]] && deleted=$((deleted + num_deleted))
        done < <(git diff --numstat --find-renames "${remote_branch_tip}..${push_content_ref}" -- "$file" 2>/dev/null || true)
        net=$((added - deleted))
        total_lines=0
        if git cat-file -e "${push_content_ref}:$file" 2>/dev/null; then
          total_lines="$(git show "${push_content_ref}:$file" 2>/dev/null | wc -l | tr -d ' ')"
        fi
        commit_hash="$(git log -1 --format='%h' "${remote_branch_tip}..${push_content_ref}" -- "$file" 2>/dev/null || true)"
        printf '| `%s` | `%s` | %s | %s | %s | %s | %s |\n' \
          "$file" "$commit_hash" "$added" "$deleted" "$net" "$total_lines" \
          "$(bt_git_file_action "$file")" >> "$report_file"
        total_added=$((total_added + added))
        total_deleted=$((total_deleted + deleted))
        total_net=$((total_net + net))
        total_lines_sum=$((total_lines_sum + total_lines))
      done < <(git diff --name-only --find-renames "${remote_branch_tip}..${push_content_ref}" 2>/dev/null || true)

      printf '| **Total** |  | %s | %s | %+d | %s |  |\n' \
        "$total_added" "$total_deleted" "$total_net" "$total_lines_sum" \
        >> "$report_file"
    fi

    if [[ "$verbose" == true ]]; then
      {
        echo "## Commits"
        echo
        git log --oneline "${remote_branch_tip}..${push_content_ref}" | sed 's/^/- /'
        echo
      } >> "$report_file"
    fi
    bt_push_cleanup_old_reports
    bt_push_release_report_lock
  }

  bt_push_format_file_summary() {
    local -a parts=()
    local type_count=0
    local total_files=0
    local output=""
    local index=0
    local part=""

    total_files=$((pushed_modified_files + pushed_deleted_files + pushed_added_files + pushed_renamed_files + pushed_renamed_modified_files))
    if [[ "$pushed_modified_files" -gt 0 ]]; then
      parts+=("$pushed_modified_files modified")
      type_count=$((type_count + 1))
    fi
    if [[ "$pushed_deleted_files" -gt 0 ]]; then
      parts+=("$pushed_deleted_files deleted")
      type_count=$((type_count + 1))
    fi
    if [[ "$pushed_added_files" -gt 0 ]]; then
      parts+=("$pushed_added_files added")
      type_count=$((type_count + 1))
    fi
    if [[ "$pushed_renamed_files" -gt 0 ]]; then
      parts+=("$pushed_renamed_files renamed")
      type_count=$((type_count + 1))
    fi
    if [[ "$pushed_renamed_modified_files" -gt 0 ]]; then
      parts+=("$pushed_renamed_modified_files renamed/modified")
      type_count=$((type_count + 1))
    fi
    if [[ "${#parts[@]}" -eq 0 ]]; then
      printf ''
      return 0
    fi
    for index in "${!parts[@]}"; do
      part="${parts[$index]}"
      if [[ "$index" -gt 0 ]]; then
        if [[ "$index" -eq $((${#parts[@]} - 1)) ]]; then
          output+=" and "
        else
          output+=", "
        fi
      fi
      output+="$part"
    done
    if [[ "$type_count" -gt 1 ]]; then
      printf '%s; %s total' "$output" "$total_files"
    else
      printf '%s' "$output"
    fi
  }

  bt_push_format_directory_summary() {
    local -a parts=()
    local output=""
    local index=0
    local part=""

    if [[ "$pushed_deleted_directories" -gt 0 ]]; then
      parts+=("$pushed_deleted_directories deleted")
    fi
    if [[ "$pushed_added_directories" -gt 0 ]]; then
      parts+=("$pushed_added_directories added")
    fi
    if [[ "$pushed_renamed_directories" -gt 0 ]]; then
      parts+=("$pushed_renamed_directories renamed")
    fi
    if [[ "${#parts[@]}" -eq 0 ]]; then
      printf ''
      return 0
    fi
    for index in "${!parts[@]}"; do
      part="${parts[$index]}"
      if [[ "$index" -gt 0 ]]; then
        if [[ "$index" -eq $((${#parts[@]} - 1)) ]]; then
          output+=" and "
        else
          output+=", "
        fi
      fi
      output+="$part"
    done
    printf '%s' "$output"
  }

  bt_push_collect_stdout_summary_counts() {
    if [[ "$pushup_mode" == true && "$dry_run" == true ]]; then
      bt_git_collect_ref_change_summary "$current_branch" "$push_content_ref"
    else
      bt_git_collect_ref_change_summary "$remote_branch_tip" "$push_content_ref"
    fi
    pushed_modified_files="$BT_CHANGE_MODIFIED_FILES"
    pushed_deleted_files="$BT_CHANGE_DELETED_FILES"
    pushed_added_files="$BT_CHANGE_ADDED_FILES"
    pushed_renamed_files="$BT_CHANGE_RENAMED_FILES"
    pushed_renamed_modified_files="$BT_CHANGE_RENAMED_MODIFIED_FILES"
    pushed_deleted_directories="$BT_CHANGE_DELETED_DIRECTORIES"
    pushed_added_directories="$BT_CHANGE_ADDED_DIRECTORIES"
    pushed_renamed_directories="$BT_CHANGE_RENAMED_DIRECTORIES"
    pushed_change_summary="$(bt_format_change_summary)"
  }

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --pushup)
        [[ $# -ge 2 ]] || bt_push_error_exit "$exit_invalid_argument" "Internal --pushup option requires a source branch"
        pushup_mode=true
        source_branch="$2"
        shift 2
        ;;
      --preview-ref)
        [[ $# -ge 2 ]] || bt_push_error_exit "$exit_invalid_argument" "Internal --preview-ref option requires a ref"
        push_content_ref="$2"
        shift 2
        ;;
      -d)
        if [[ "$error_run" == true ]]; then
          bt_push_usage_error "Options -d and -e are mutually exclusive"
        fi
        dry_run=true
        shift
        ;;
      -e)
        if [[ "$dry_run" == true ]]; then
          bt_push_usage_error "Options -d and -e are mutually exclusive"
        fi
        error_run=true
        shift
        ;;
      -v|--verbose)
        verbose=true
        shift
        ;;
      *)
        bt_push_usage_error "Unknown option or argument: $1"
        ;;
    esac
  done

  if [[ -n "$source_branch" && "$pushup_mode" != true ]]; then
    bt_push_error_exit "$exit_invalid_argument" "Invalid pushup workflow mode"
  fi
  if [[ "$push_content_ref" != "HEAD" ]]; then
    if [[ "$pushup_mode" != true || "$dry_run" != true ]]; then
      bt_push_error_exit "$exit_invalid_argument" "Push preview ref is allowed only for an pushup dry run"
    fi
    push_content_ref="$(git rev-parse --verify "$push_content_ref" 2>/dev/null || true)"
    [[ -n "$push_content_ref" ]] || bt_push_error_exit "$exit_invalid_argument" "Unable to resolve pushup push preview ref"
  fi

  repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  [[ -n "$repo_root" ]] || bt_push_error_exit "$exit_invalid_argument" "Unable to resolve repository root"
  reports_dir="$repo_root/reports"
  run_ts_file="$(date '+%Y%m%d-%H%M%S%z')"
  run_ts_display="$(date '+%Y-%m-%d %H:%M:%S%z' | sed -E 's/([+-][0-9]{2})([0-9]{2})$/\1:\2/')"

  current_branch="$(bt_get_current_branch || true)"

  if [[ "$error_run" == true ]]; then
    bt_push_emit_skip_report
  fi

  remote_branch_tip="$(bt_run_remote_command git ls-remote --exit-code origin \
    "refs/heads/$current_branch" 2>/dev/null | awk 'NR==1 { print $1 }')"
  [[ -n "$remote_branch_tip" ]] || bt_push_error_exit "$exit_remote_branch_not_found" \
    "Remote branch '$current_branch' not found on origin"

  if declare -F bt_refresh_remote_workflow_history >/dev/null 2>&1 && \
    ! bt_refresh_remote_workflow_history; then
    bt_push_error_exit "$exit_report_failed" \
      "Failed to refresh remote report history before push"
  fi

  commits_ahead="$(git rev-list --count "${remote_branch_tip}..${push_content_ref}" 2>/dev/null || echo 0)"
  if [[ "$commits_ahead" == "0" ]]; then
    if [[ "$dry_run" == false ]] && \
      declare -F bt_push_has_pending_pushup_pr >/dev/null 2>&1 && \
      bt_push_has_pending_pushup_pr; then
      local pending_pr_state=""
      if ! pending_pr_state="$(bt_push_get_pushup_pr_state)"; then
        bt_push_error_exit "$exit_pr_finalize_failed" \
          "Remote branch is current, but its pull request state could not be read"
      fi
      if [[ "$pending_pr_state" == "OPEN" ]]; then
        if bt_push_finalize_pushup_pr "$push_content_ref"; then
          echo "Remote $current_branch already contains the local pushup result."
          echo "Finalized pull request for $current_branch."
          exit 0
        fi
        bt_push_error_exit "$exit_pr_finalize_failed" \
          "Remote branch is current, but its pull request could not be finalized"
      elif [[ "${BT_PUSHUP_FINALIZATION_RETRY:-false}" == true && \
        ( "$pending_pr_state" == "CLOSED" || \
          "$pending_pr_state" == "MERGED" ) ]]; then
        echo "Remote $current_branch already contains the local pushup result."
        echo "Pull request for $current_branch is already finalized."
        exit 0
      fi
    fi
    bt_emit_error "Local ${current_branch} branch has no changes to push."
    bt_push_emit_guidance "commit changes before rerunning push."
    exit "$exit_nothing_to_push"
  fi

  local commits_behind=0
  commits_behind="$(git rev-list --count "${push_content_ref}..${remote_branch_tip}" 2>/dev/null || echo 0)"
  if [[ "$commits_behind" != "0" ]]; then
    bt_push_error_exit "$exit_invalid_argument" \
      "Local and remote branches have diverged ($commits_ahead ahead, $commits_behind behind). Run pull to synchronize first"
  fi

  if [[ "$verbose" == true ]]; then
    echo "Current local branch ${current_branch}."
    echo "Commits to push: ${commits_ahead}."
    echo "Commits that will be pushed:"
    git log --oneline "${remote_branch_tip}..${push_content_ref}" | sed 's/^/  /'
  fi

  if [[ "$dry_run" == true ]]; then
    bt_push_collect_stdout_summary_counts
    bt_push_generate_report
    echo "Dry-run: push to remote $current_branch: ${pushed_change_summary}."
    echo "See ${report_file#"${repo_root}"/} for details."
    exit 0
  fi

  if declare -F bt_push_has_pending_pushup_pr >/dev/null 2>&1 && \
    bt_push_has_pending_pushup_pr && \
    ! bt_push_validate_pushup_pr_approval; then
    bt_push_error_exit "$exit_pr_finalize_failed" \
      "Pull request approval changed before the pushup result could be pushed"
  fi

  bt_push_collect_stdout_summary_counts
  if declare -F bt_record_remote_workflow_event >/dev/null 2>&1; then
    if ! bt_record_remote_workflow_event "push" "$current_branch" \
      "${BT_PUSH_COMMAND_LINE:-push}" \
      "Pushed ${commits_ahead} commit(s) to origin/$current_branch" \
      "$push_content_ref" \
      "Previous-Remote-Tip" "$remote_branch_tip" \
      "Pushed-Tip" "$push_content_ref" \
      "Commits" "$commits_ahead" \
      "Files-Modified" "$pushed_modified_files" \
      "Files-Deleted" "$pushed_deleted_files" \
      "Files-Added" "$pushed_added_files" \
      "Files-Renamed" "$pushed_renamed_files" \
      "Files-Renamed-Modified" "$pushed_renamed_modified_files" \
      "Directories-Deleted" "$pushed_deleted_directories" \
      "Directories-Added" "$pushed_added_directories" \
      "Directories-Renamed" "$pushed_renamed_directories"; then
      bt_push_error_exit "$exit_report_failed" \
        "Push was not started because its report history could not be recorded"
    fi
  fi

  local push_output=""
  if ! push_output="$(bt_run_remote_command env GIT_BYPASS_HOOKS=true \
    git push --atomic origin "$current_branch" \
      refs/notes/briteRepo-remote-workflow:refs/notes/briteRepo-remote-workflow \
      2>&1)"; then
    printf '%s\n' "$push_output" >&2
    bt_push_generate_error_report "Failed to push branch '$current_branch' to remote" "push failed" "$push_output"
    if [[ "${PENDING_PUSHUP:-false}" == true ]] && \
      grep -Eqi 'fetch first|non-fast-forward|stale info|remote.*changed' \
        <<< "$push_output"; then
      bt_emit_error "Remote parent branch '$current_branch' changed before this pushup result could be pushed."
      bt_push_emit_guidance "switch to '$PENDING_PUSHUP_SOURCE', run pulldown, obtain approval for the updated source commit, then rerun pushup and push."
      exit "$exit_push_failed"
    fi
    bt_push_error_exit "$exit_push_failed" "Failed to push branch '$current_branch' to remote"
  fi

  bt_undo_record_operation push "$current_branch" "$push_content_ref" \
    "$push_content_ref" remote-reset \
    "Pushed $commits_ahead commit(s) to origin/$current_branch" \
    "$remote_branch_tip" "$push_content_ref" >/dev/null || \
    bt_warn "Push completed, but undo metadata could not be recorded"

  bt_push_cleanup_success_transient_reports

  local pushed_tip_short=""
  pushed_tip_short="$(git rev-parse --short=7 "$push_content_ref" 2>/dev/null || true)"
  [[ -n "$pushed_tip_short" ]] || pushed_tip_short="${push_content_ref:0:7}"
  if declare -F bt_push_finalize_pushup_pr >/dev/null 2>&1; then
    if ! bt_push_finalize_pushup_pr "$push_content_ref"; then
      bt_push_error_exit "$exit_pr_finalize_failed" \
        "Push completed, but its pull request could not be finalized"
    fi
  fi
  echo "Pushed (${pushed_tip_short}) to remote $current_branch: ${pushed_change_summary}."
  echo "Run report -r for details."
)
