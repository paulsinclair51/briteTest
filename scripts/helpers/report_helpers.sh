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

bt_report_mark_read_only() {
  local report_path="$1"
  local exit_code="$2"

  if ! chmod a-w "$report_path" 2>/dev/null; then
    bt_report_error_exit "$exit_code" "Failed to mark report read-only: $report_path"
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

bt_report_dir_disable_writes() {
  local report_dir="$1"
  local exit_code="$2"
  local report_file

  [[ -d "$report_dir" ]] || return 0

  # Normalize report files to read-only before locking the directory.
  for report_file in "$report_dir"/*.md; do
    [[ -e "$report_file" ]] || continue
    if ! chmod a-w "$report_file" 2>/dev/null; then
      bt_report_warn "Could not mark report read-only: ${report_file}"
    fi
  done

  if ! chmod a-w "$report_dir" 2>/dev/null; then
    bt_report_error_exit "$exit_code" "Failed to disable writes for report directory: $report_dir"
  fi
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

bt_report_persist_changes() {
  local repo_root="$1"
  local report_path="$2"
  local deleted_array_name="$3"
  local commit_message="$4"
  local exit_code="$5"
  local allow_force_push="${6:-false}"
  local current_branch
  local report_filename
  local report_rel
  local -a report_paths=()
  # shellcheck disable=SC2178  # Nameref points to an array variable by contract.
  local -n deleted_reports_ref="$deleted_array_name"

  if [[ -z "$report_path" || ! -f "$report_path" ]]; then
    bt_report_error_exit "$exit_code" "Report file was not generated as expected."
  fi

  report_filename="$(basename "$report_path")"
  report_rel="${report_path#"${repo_root}"/}"
  current_branch="$(git symbolic-ref -q --short HEAD 2>/dev/null || true)"
  if [[ -z "$current_branch" ]]; then
    bt_report_error_exit "$exit_code" "Cannot save report. Check out a branch and try again."
  fi

  report_paths=("$report_rel")
  if [[ ${#deleted_reports_ref[@]} -gt 0 ]]; then
    report_paths+=("${deleted_reports_ref[@]}")
  fi

  if ! env GIT_BYPASS_HOOKS=true git add -A -- "${report_paths[@]}" >/dev/null 2>&1; then
    bt_report_error_exit "$exit_code" "Failed to prepare report for commit."
  fi

  if git diff --cached --quiet -- "${report_paths[@]}"; then
    bt_report_info "No changes to report."
    return 0
  fi

  if ! env GIT_BYPASS_HOOKS=true git commit -m "$commit_message" -- "${report_paths[@]}" >/dev/null 2>&1; then
    bt_report_error_exit "$exit_code" "Failed to commit report."
  fi

  if ! git remote get-url origin >/dev/null 2>&1; then
    bt_report_warn "No remote repository configured"
    bt_report_success "Report $report_filename committed."
    return 0
  fi

  if ! git ls-remote --heads origin >/dev/null 2>&1; then
    bt_report_warn "Cannot connect to remote repository"
    bt_report_success "Report $report_filename committed."
    return 0
  fi

  if env GIT_BYPASS_HOOKS=true git push origin "$current_branch" >/dev/null 2>&1; then
    bt_report_success "Report $report_filename committed/pushed."
    return 0
  fi

  if [[ "$allow_force_push" == true ]] && env GIT_BYPASS_HOOKS=true git push --force origin "$current_branch" >/dev/null 2>&1; then
    bt_report_success "Report $report_filename committed/pushed."
    return 0
  fi

  bt_report_warn "Failed to push report commit to remote."
  bt_report_success "Report $report_filename committed."
}
