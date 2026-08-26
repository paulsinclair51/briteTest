#!/usr/bin/env bash

# Shared helpers for repository report lifecycle management.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

bt_run_lsbranch_mode() {
  local mode="$1"
  local lsbranch_path="$2"
  local report_dir="$3"
  local report_prefix="$4"
  shift 4

  [[ "$mode" == "report" ]] || return 2
  [[ -n "$lsbranch_path" && -x "$lsbranch_path" ]] || return 2
  [[ -n "$report_dir" && -n "$report_prefix" ]] || return 2
  "$lsbranch_path" --report "$report_dir" "$report_prefix" "$@"
}

bt_report_capture_command_output() {
  local stdout_var="$1"
  local stderr_var="$2"
  shift 2

  local stdout_file=""
  local stderr_file=""
  local rc=0

  if ! stdout_file=$(mktemp); then
    printf -v "$stdout_var" '%s' ""
    printf -v "$stderr_var" '%s' "mktemp failed for stdout"
    return 1
  fi
  if ! stderr_file=$(mktemp); then
    rm -f "$stdout_file"
    printf -v "$stdout_var" '%s' ""
    printf -v "$stderr_var" '%s' "mktemp failed for stderr"
    return 1
  fi

  set +e
  "$@" >"$stdout_file" 2>"$stderr_file"
  rc=$?
  set -e

  printf -v "$stdout_var" '%s' "$(<"$stdout_file")"
  printf -v "$stderr_var" '%s' "$(<"$stderr_file")"
  rm -f "$stdout_file" "$stderr_file" || true
  return "$rc"
}

bt_report_record_diagnostic() {
  local message="$1"
  local detail="${2:-}"

  if declare -F record_diagnostic >/dev/null 2>&1; then
    record_diagnostic "$message" "$detail"
    return 0
  fi

  if [[ -n "$detail" ]]; then
    bt_report_warn "$message ($detail)"
  else
    bt_report_warn "$message"
  fi
}

bt_lsbranch_has_local_branch() {
  local branch="$1"
  git show-ref --verify --quiet "refs/heads/$branch"
}

bt_lsbranch_has_remote_branch() {
  local branch="$1"
  git show-ref --verify --quiet "refs/remotes/origin/$branch"
}

matches_glob() {
  local text="$1"
  local pattern="$2"
  # shellcheck disable=SC2053  # pattern is intentionally treated as glob.
  [[ "$text" == $pattern ]]
}

append_unique_branch_line() {
  local existing_list="$1"
  local candidate="$2"

  [[ -n "$candidate" ]] || {
    printf '%s' "$existing_list"
    return 0
  }

  if [[ -z "$existing_list" ]]; then
    printf '%s' "$candidate"
    return 0
  fi

  if printf '%s\n' "$existing_list" | grep -Fxq "$candidate"; then
    printf '%s' "$existing_list"
  else
    printf '%s\n%s' "$existing_list" "$candidate"
  fi
}

apply_exclude_filter() {
  local branches="$1"
  local exclude_pattern="$2"

  if [[ -z "$exclude_pattern" ]]; then
    printf '%s\n' "$branches"
    return 0
  fi

  while IFS= read -r branch; do
    [[ -n "$branch" ]] || continue
    if ! matches_glob "$branch" "$exclude_pattern"; then
      echo "$branch"
    fi
  done <<< "$branches"
}

get_remote_branches() {
  local pattern="$1"
  local refs_output=""
  local refs_error=""

  if ! bt_report_capture_command_output \
    refs_output refs_error \
    git for-each-ref --format='%(refname:short)' refs/remotes/origin; then
    bt_report_record_diagnostic \
      "Failed to enumerate remote branches; remote rows may be incomplete." \
      "$refs_error"
    echo ""
    return 0
  fi

  while IFS= read -r branch; do
    [[ -n "$branch" ]] || continue
    [[ "$branch" == "origin" ]] && continue
    [[ "$branch" == "origin/HEAD" ]] && continue
    branch="${branch#origin/}"
    [[ -z "$branch" ]] && continue
    if matches_glob "$branch" "$pattern"; then
      echo "$branch"
    fi
  done <<< "$refs_output" | sort
}

get_local_branches() {
  local pattern="$1"
  local refs_output=""
  local refs_error=""

  if ! bt_report_capture_command_output \
    refs_output refs_error \
    git for-each-ref --format='%(refname:short)' refs/heads; then
    bt_report_record_diagnostic \
      "Failed to enumerate local branches; local rows may be incomplete." \
      "$refs_error"
    echo ""
    return 0
  fi

  while IFS= read -r branch; do
    [[ -n "$branch" ]] || continue
    [[ "$branch" == r-* ]] && continue
    if matches_glob "$branch" "$pattern"; then
      echo "$branch"
    fi
  done <<< "$refs_output" | sort
}

get_remote_only_branches() {
  local pattern="$1"
  get_remote_branches "$pattern" | while IFS= read -r branch; do
    [[ -n "$branch" ]] || continue
    if ! bt_lsbranch_has_local_branch "$branch"; then
      echo "$branch"
    fi
  done | sort || echo ""
}

bt_collect_lsbranch_mode_branches() {
  local mode="$1"
  local target_branch="$2"
  local current_branch="$3"
  local branch_pattern="$4"
  local exclude_pattern="$5"
  local -n local_out="$6"
  local -n remote_out="$7"
  local -n remote_only_out="$8"
  local candidate_branch=""
  local parent_branch=""
  local basis_branch=""
  local local_branches=""
  local remote_branches=""
  local remote_only_branches=""

  local_out=""
  remote_out=""
  remote_only_out=""

  case "$mode" in
    target)
      basis_branch="$target_branch"
      ;;
    current)
      basis_branch="$current_branch"
      ;;
    pattern)
      local_branches=$(get_local_branches "$branch_pattern")
      remote_branches=$(get_remote_branches "$branch_pattern")
      remote_only_branches=$(get_remote_only_branches "$branch_pattern")

      local_out=$(apply_exclude_filter "$local_branches" "$exclude_pattern")
      remote_out=$(apply_exclude_filter "$remote_branches" "$exclude_pattern")
      remote_only_out=$(apply_exclude_filter \
        "$remote_only_branches" "$exclude_pattern")
      return 0
      ;;
    *)
      return 2
      ;;
  esac

  parent_branch="$(bt_resolve_parent_branch "$basis_branch" "main" \
    2>/dev/null || true)"

  for candidate_branch in "$basis_branch" "$parent_branch"; do
    [[ -n "$candidate_branch" ]] || continue

    if bt_lsbranch_has_local_branch "$candidate_branch"; then
      local_out="$(append_unique_branch_line \
        "$local_out" "$candidate_branch")"
    fi

    if bt_lsbranch_has_remote_branch "$candidate_branch"; then
      remote_out="$(append_unique_branch_line \
        "$remote_out" "$candidate_branch")"
      if ! bt_lsbranch_has_local_branch "$candidate_branch"; then
        remote_only_out="$(append_unique_branch_line \
          "$remote_only_out" "$candidate_branch")"
      fi
    fi
  done
}

bt_report_warn() {
  if declare -F bt_warn >/dev/null 2>&1; then
    bt_warn "$1"
  else
    echo "$1"
  fi
}

bt_report_info() {
  if declare -F bt_info >/dev/null 2>&1; then
    bt_info "$1"
  else
    echo "$1"
  fi
}

bt_report_success() {
  if declare -F bt_success >/dev/null 2>&1; then
    bt_success "$1"
  else
    echo "$1"
  fi
}

bt_report_error_exit() {
  local exit_code="$1"
  local message="$2"

  if declare -F bt_error_exit >/dev/null 2>&1; then
    bt_error_exit "$exit_code" "$message"
  else
    echo "Error: $message" >&2
    exit "$exit_code"
  fi
}

bt_report_dir_enable_writes() {
  local report_dir="$1"
  local exit_code="$2"

  if ! mkdir -p "$report_dir" 2>/dev/null; then
    bt_report_error_exit "$exit_code" "Failed to create report directory: $report_dir"
  fi

  if ! chmod u+rwx "$report_dir" 2>/dev/null; then
    bt_report_error_exit "$exit_code" "Failed to enable writes for report directory: $report_dir"
  fi
}

# Retained reports keep every run, so an ID distinguishes same-second files.
bt_report_retained_path() {
  local report_dir="$1"
  local prefix="$2"
  local timestamp="$3"
  local process_id="${4:-$BASHPID}"

  printf '%s/%s-%s-%s.md\n' \
    "${report_dir%/}" "$prefix" "$timestamp" "$process_id"
}

# Transient reports replace earlier dry-run/error output. Call while holding
# the workflow report lock so path allocation, cleanup, and writing serialize.
bt_report_transient_path() {
  local report_dir="$1"
  local prefix="$2"
  local run_timestamp="$3"
  local timestamp=""
  local report_path=""

  while true; do
    timestamp="$(date '+%Y%m%d-%H%M%S')"
    report_path="${report_dir%/}/${prefix}-${timestamp}.md"
    if [[ "$timestamp" != "$run_timestamp" && ! -e "$report_path" ]]; then
      printf '%s\n' "$report_path"
      return 0
    fi
    sleep 1
  done
}

bt_report_write_header() {
  local report_path="$1"
  local report_title="$2"
  local run_ts_display="$3"
  local command_text="$4"

  cat > "$report_path" <<EOF
# ${report_title} ${run_ts_display}

**Command:** \`${command_text}\`

EOF
}

bt_report_acquire_lock() {
  local repo_root="$1"
  local namespace="$2"
  local timeout_seconds="$3"
  local output_fd_name="$4"
  local repo_hash=""
  local lock_fd=""
  local lock_path=""
  local safe_namespace=""
  local -n output_fd_ref="$output_fd_name"

  [[ "$timeout_seconds" =~ ^[0-9]+$ && "$timeout_seconds" -gt 0 ]] || return 2

  safe_namespace="${namespace//[^a-zA-Z0-9_.-]/-}"
  repo_hash="$(printf '%s' "$repo_root" | cksum | awk '{print $1}')"
  lock_path="/tmp/briteRepo-report-${safe_namespace}-${repo_hash}.lock"

  exec {lock_fd}>"$lock_path"
  if ! flock -w "$timeout_seconds" "$lock_fd"; then
    eval "exec ${lock_fd}>&-"
    return 1
  fi

  # shellcheck disable=SC2034  # Returned by nameref.
  output_fd_ref="$lock_fd"
}

bt_report_release_lock() {
  local lock_fd="$1"

  [[ "$lock_fd" =~ ^[0-9]+$ ]] || return 0
  flock -u "$lock_fd" >/dev/null 2>&1 || true
  eval "exec ${lock_fd}>&-"
}

bt_report_remove_and_record() {
  local repo_root="$1"
  local deleted_array_name="$2"
  local target_path="$3"
  local stale_label="$4"
  local target_rel
  # shellcheck disable=SC2178  # Nameref points to an array variable by contract.
  local -n deleted_reports_ref="$deleted_array_name"

  target_rel="${target_path#"${repo_root}"/}"
  if rm -f "$target_path" 2>/dev/null; then
    deleted_reports_ref+=("$target_rel")
  else
    bt_report_warn "Could not remove stale ${stale_label}: $target_rel"
  fi
}

bt_report_cleanup_transient_reports() {
  local reports_dir="$1"
  local current_branch="$2"
  local current_report_path="$3"
  shift 3

  local pattern
  local report_path
  local report_branch=""
  local matched_branch_field=""

  for pattern in "$@"; do
    for report_path in "$reports_dir"/$pattern; do
      [[ -e "$report_path" ]] || continue
      [[ -n "$current_report_path" && "$report_path" == "$current_report_path" ]] && continue

      report_branch=""
      matched_branch_field=""
      if grep -Eq '^\*\*Branch:\*\* ' "$report_path" 2>/dev/null; then
        matched_branch_field="Branch"
      elif grep -Eq '^\*\*Source Branch:\*\* ' "$report_path" 2>/dev/null; then
        matched_branch_field="Source Branch"
      fi

      if [[ -n "$matched_branch_field" ]]; then
        report_branch="$(awk -v field="$matched_branch_field" '
          $0 ~ "^\\*\\*" field "\\*\\* " {
            sub("^\\*\\*" field "\\*\\* ", "", $0)
            gsub(/^`|`$/, "", $0)
            sub(/ \((local|remote)\)$/, "", $0)
            print $0
            exit
          }
        ' "$report_path" 2>/dev/null || true)"
      fi

      if [[ -n "$report_branch" && "$report_branch" != "$current_branch" ]]; then
        continue
      fi

      chmod u+w "$report_path" >/dev/null 2>&1 || true
      rm -f "$report_path" >/dev/null 2>&1 || true
    done
  done
}
