#!/usr/bin/env bash

# Shared health-report rendering helpers.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

bt_hr_increment_counter() {
  local var_name="$1"
  printf -v "$var_name" '%d' "$(( ${!var_name} + 1 ))"
}

bt_hr_append_section() {
  local report_file="$1"
  local section_title="$2"

  echo "
### $section_title
" >> "$report_file"
}

# bt_hr_append_check
#
# Args:
#   $1 report file path
#   $2 check title
#   $3 status: PASS | ISSUE | FIXED | ERROR
#   $4 detail text (may be empty)
#   $5 issue counter variable name (optional)
#   $6 fixed counter variable name (optional)
bt_hr_append_check() {
  local report_file="$1"
  local check_name="$2"
  local status="$3"
  local details="$4"
  local issue_counter_var="${5:-}"
  local fixed_counter_var="${6:-}"

  case "$status" in
    PASS)
      echo "- [PASS] **$check_name**" >> "$report_file"
      ;;
    ISSUE)
      echo "- [ISSUE] **$check_name**" >> "$report_file"
      if [[ -n "$issue_counter_var" ]]; then
        bt_hr_increment_counter "$issue_counter_var"
      fi
      ;;
    FIXED)
      echo "- [FIXED] **$check_name**" >> "$report_file"
      if [[ -n "$fixed_counter_var" ]]; then
        bt_hr_increment_counter "$fixed_counter_var"
      fi
      ;;
    ERROR)
      echo "- [ERROR] **$check_name**" >> "$report_file"
      if [[ -n "$issue_counter_var" ]]; then
        bt_hr_increment_counter "$issue_counter_var"
      fi
      ;;
    *)
      echo "- [ERROR] **$check_name**" >> "$report_file"
      echo "  - Invalid status '$status' passed to bt_hr_append_check." >> "$report_file"
      if [[ -n "$issue_counter_var" ]]; then
        bt_hr_increment_counter "$issue_counter_var"
      fi
      ;;
  esac

  if [[ -n "$details" ]]; then
    echo "  - $details" >> "$report_file"
  fi
}
