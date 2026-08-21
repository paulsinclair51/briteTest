#!/usr/bin/env bash

# Shared helpers for repository report lifecycle management.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

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
  lock_path="/tmp/briteTest-report-${safe_namespace}-${repo_hash}.lock"

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
