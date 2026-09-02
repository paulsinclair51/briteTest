#!/bin/bash

# Common Utility Functions for Repository Scripts
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
#
# Purpose: Centralized bash utilities and helper functions used across multiple
#          helper scripts and GitHub Actions workflows. This file reduces code
#          duplication and provides consistent error handling and logging.
#
# Usage: source briteRepo/helpers/common_utils.sh
#
# Functions:
#   - log_info()     - Log informational message with ✓ prefix
#   - log_error()    - Log error message with ✗ prefix and exit
#   - log_section()  - Log section header (for visual organization)
#   - log_detail()   - Log detail message with indentation
#   - assert_set()   - Assert environment variable is set
#   - timer_start()  - Start execution timer
#   - timer_end()    - End execution timer and report duration

# Internal library: must be sourced by a briteRepo command or helper. Direct
# execution by a user is not supported.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "common_utils.sh is a briteRepo internal library and must be sourced." >&2
  exit 1
fi

# Shell options are the sourcing command's responsibility; do not change them.

# Color codes for terminal output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'  # No Color

# Timer tracking (for performance metrics)
_TIMER_START=""

#####################################################################
# LOG FUNCTIONS
#####################################################################

# log_info: Print informational message with checkmark
# Args: $1 = message
# Example: log_info "Validation passed"
log_info() {
  local msg="$1"
  echo -e "${GREEN}✓${NC} ${msg}"
}

# log_error: Print error message with X and exit with status
# Args: $1 = message, $2 = exit code (optional, default 1)
# Example: log_error "Invalid branch" 1
log_error() {
  local msg="$1"
  local code="${2:-1}"
  echo -e "${RED}✗${NC} ${msg}" >&2
  exit "$code"
}

# log_section: Print section header for visual organization
# Args: $1 = section title
# Example: log_section "Validating branch names"
log_section() {
  local title="$1"
  echo ""
  echo -e "${BLUE}=== ${title} ===${NC}"
}

# log_detail: Print indented detail message
# Args: $1 = message, $2 = indent level (optional, default 2)
# Example: log_detail "Branch type: contributor"
log_detail() {
  local msg="$1"
  local indent="${2:-2}"
  printf "%${indent}s%s\\n" " " "${msg}"
}

# log_warning: Print warning message
# Args: $1 = message
# Example: log_warning "This may cause issues"
log_warning() {
  local msg="$1"
  echo -e "${YELLOW}⚠${NC} ${msg}"
}

#####################################################################
# VALIDATION FUNCTIONS
#####################################################################

# assert_set: Assert that environment variable is set, exit if not
# Args: $1 = variable name
# Example: assert_set "HEAD_REF"
assert_set() {
  local var_name="$1"
  local var_value="${!var_name:-}"
  if [[ -z "$var_value" ]]; then
    log_error "Environment variable not set: $var_name"
  fi
}

# assert_not_empty: Assert that string is not empty
# Args: $1 = value, $2 = description
# Example: assert_not_empty "$branch" "branch name"
assert_not_empty() {
  local value="$1"
  local desc="${2:-value}"
  if [[ -z "$value" ]]; then
    log_error "$desc is empty"
  fi
}

# assert_file_exists: Assert that file exists
# Args: $1 = file path
# Example: assert_file_exists "briteRepo/helpers/ckbranchname.sh"
assert_file_exists() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    log_error "File not found: $file"
  fi
}

#####################################################################
# TIMER FUNCTIONS (Performance Metrics)
#####################################################################

# timer_start: Start performance timer
# Stores current time for later calculation
# Example: timer_start
timer_start() {
  _TIMER_START=$(date +%s%N)
}

# timer_end: End timer and report elapsed time
# Args: $1 = operation name (optional)
# Example: timer_end "branch validation"
timer_end() {
  local op_name="${1:-operation}"
  if [[ -z "$_TIMER_START" ]]; then
    log_warning "Timer was not started"
    return
  fi
  local end_time
  end_time=$(date +%s%N)
  local elapsed_ms=$(( (_TIMER_START - end_time) / 1000000 ))
  elapsed_ms=$(( elapsed_ms < 0 ? -elapsed_ms : elapsed_ms ))
  log_detail "${op_name} completed in ${elapsed_ms}ms"
}

#####################################################################
# STRING FUNCTIONS
#####################################################################

# string_contains: Check if string contains substring
# Args: $1 = haystack, $2 = needle
# Returns: 0 if found, 1 if not found
# Example: if string_contains "v1.0.0" "v1"; then ...
string_contains() {
  local haystack="$1"
  local needle="$2"
  [[ "$haystack" == *"$needle"* ]]
}

# string_equals: Check if strings are equal (with better readability)
# Args: $1 = string1, $2 = string2
# Returns: 0 if equal, 1 if not
# Example: if string_equals "$branch" "main"; then ...
string_equals() {
  [[ "$1" == "$2" ]]
}

#####################################################################
# ARRAY FUNCTIONS
#####################################################################

# array_contains: Check if array contains value
# Args: $1 = value, $2+ = array elements
# Returns: 0 if found, 1 if not found
# Example: if array_contains "feat" "${valid_types[@]}"; then ...
array_contains() {
  local needle="$1"
  shift
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

#####################################################################
# GIT HELPER FUNCTIONS
#####################################################################

# git_log_range: Get git log for commit range
# Args: $1 = base branch, $2 = head branch
# Outputs: commit hashes, one per line
# Performance: Caches result in _GIT_LOG_CACHE
# Example: git_log_range "main" "mywork/feature"
git_log_range() {
  local base="$1"
  local head="$2"
  git log "origin/${base}..origin/${head}" --format=%H \
    2>/dev/null || echo ""
}

# git_changed_files: Get list of changed files in commit range
# Args: $1 = base branch, $2 = head branch
# Outputs: file paths, one per line
# Example: git_changed_files "main" "mywork/feature"
git_changed_files() {
  local base="$1"
  local head="$2"
  git diff "origin/${base}...origin/${head}" --name-only \
    2>/dev/null || echo ""
}

# git_get_commit_subject: Get subject line of commit
# Args: $1 = commit hash
# Outputs: commit subject
# Example: subject=$(git_get_commit_subject "abc123")
git_get_commit_subject() {
  local commit="$1"
  git log -1 --format=%s "$commit" 2>/dev/null || echo ""
}

#####################################################################
# FINAL MESSAGE FUNCTIONS
#####################################################################

# print_success: Print success summary
# Args: $1 = message (optional)
print_success() {
  local msg="${1:-All validations passed}"
  echo ""
  echo "=========================================="
  log_info "$msg"
  echo "=========================================="
}

# print_failure: Print failure summary and exit
# Args: $1 = message (optional)
print_failure() {
  local msg="${1:-Validation failed}"
  echo ""
  echo "=========================================="
  log_error "$msg"
  echo "=========================================="
}
