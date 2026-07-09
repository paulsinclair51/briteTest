#!/bin/bash

# Validation Helper Functions for briteTest
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
#
# Purpose: Standard validation functions used across GitHub Actions workflows.
#          Centralizes validation logic to reduce duplication and improve
#          maintainability across 15+ workflow files.
#
# Usage: source scripts/helpers/common-utils.sh
#        source scripts/helpers/validation-helpers.sh
#
# Functions:
#   - validate_commit_message()  - Check conventional commit format
#   - validate_all_commit_messages() - Validate all commits in range
#   - scan_for_secrets()         - Detect credentials in files
#   - check_file_size()          - Verify file size limits
#   - validate_license_header()  - Check for MIT license header

set -euo pipefail

# Source common utilities (must be done before using them)
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common-utils.sh
source "${script_dir}/common-utils.sh"

#####################################################################
# COMMIT MESSAGE VALIDATION
#####################################################################

# validate_commit_message: Check if commit message follows conventional format
#
# Format: <type>[optional scope]: <description>
# Types: feat, fix, docs, style, refactor, test, chore
#
# Args: $1 = commit message
# Returns: 0 if valid, 1 if invalid
# Performance: O(1) - single regex check
#
# Examples:
#   validate_commit_message "feat: add new feature"          # Valid
#   validate_commit_message "fix(parser): resolve issue"     # Valid
#   validate_commit_message "Add new feature"                # Invalid
validate_commit_message() {
  local message="$1"

  # Regex explanation:
  # ^              = start of line
  # (feat|fix|...) = required commit type
  # (\([^)]+\))?   = optional scope in parentheses
  # :              = required colon
  # <space>        = required space
  # .+             = required description (at least 1 char)
  local pattern='^(feat|fix|docs|style|refactor|test|chore)(\([^)]+\))?: .+'

  if [[ $message =~ $pattern ]]; then
    return 0  # Valid
  else
    return 1  # Invalid
  fi
}

# validate_all_commit_messages: Validate all commits in range
#
# Args: $1 = base branch, $2 = head branch
# Returns: 0 if all valid, 1 if any invalid
# Performance: O(n) where n = number of commits
#
# Example: validate_all_commit_messages "main" "mywork/feature"
validate_all_commit_messages() {
  local base_ref="$1"
  local head_ref="$2"

  log_section "Validating commit messages"

  # Get all commits in range
  local commits
  commits=$(git log "origin/${base_ref}..origin/${head_ref}" --format=%H 2>/dev/null || echo "")

  # No commits to check
  if [[ -z "$commits" ]]; then
    log_info "No commits to validate"
    return 0
  fi

  local failed=0
  local validated=0

  # Check each commit
  while IFS= read -r commit; do
    local subject
    subject=$(git_get_commit_subject "$commit")

    if validate_commit_message "$subject"; then
      log_detail "✓ $subject"
      ((validated++))
    else
      log_error "Invalid format: $subject"
      ((failed++))
    fi
  done <<< "$commits"

  if [[ $failed -gt 0 ]]; then
    log_section "Commit Message Validation Results"
    log_detail "Valid: $validated"
    log_detail "Invalid: $failed"
    return 1
  fi

  log_info "All $validated commits have valid format"
  return 0
}

#####################################################################
# SECRET DETECTION
#####################################################################

# Secret patterns to detect (regex)
# Performance note: Patterns are in order of common to rare for quick matching
readonly SECRET_PATTERNS=(
  "-----BEGIN (RSA|OPENSSH|PRIVATE) KEY"  # Private keys
  "aws_access_key_id"                     # AWS credentials
  "aws_secret_access_key"                 # AWS credentials
  "AKIA[0-9A-Z]{16}"                      # AWS access key format
  "ghp_[0-9a-zA-Z]{36,255}"              # GitHub Personal Access Token
  "gho_[0-9a-zA-Z]{36,255}"              # GitHub OAuth token
  "github_pat_"                           # GitHub PAT prefix
  "apikey"                                # Generic API key pattern
  "password\s*[=:]"                       # Password assignment
)

# scan_for_secrets: Detect secrets in changed files
#
# Performance: O(n*m) where n = files, m = patterns
# Optimization: Skips binary files and excluded paths
#
# Args: $1 = base branch, $2 = head branch
# Returns: 0 if no secrets, 1 if secrets found
#
# Example: scan_for_secrets "main" "mywork/feature"
scan_for_secrets() {
  local base_ref="$1"
  local head_ref="$2"

  log_section "Scanning for secrets"

  # Get changed files
  local changed_files
  changed_files=$(git_changed_files "$base_ref" "$head_ref")

  if [[ -z "$changed_files" ]]; then
    log_info "No files changed"
    return 0
  fi

  local secrets_found=0

  # Check each file
  while IFS= read -r file; do
    # Skip if file doesn't exist (was deleted)
    [[ ! -f "$file" ]] && continue

    # Skip binary files
    if file "$file" | grep -q "binary"; then
      continue
    fi

    # Check each pattern
    for pattern in "${SECRET_PATTERNS[@]}"; do
      if grep -iE "$pattern" "$file" >/dev/null 2>&1; then
        log_error "Secret pattern detected in: $file"
        ((secrets_found++))
      fi
    done
  done <<< "$changed_files"

  if [[ $secrets_found -gt 0 ]]; then
    log_section "Secret Detection Results"
    log_detail "Secrets found: $secrets_found"
    return 1
  fi

  log_info "No secrets detected"
  return 0
}

#####################################################################
# FILE SIZE VALIDATION
#####################################################################

# check_file_size: Validate file size is within limits
#
# Limits:
#   Hard: 10 MB - File will be rejected
#   Soft: 1 MB  - Warning issued but file accepted
#
# Args: $1 = file path
# Returns: 0 if valid, 1 if exceeds hard limit
#
# Performance: O(1) - single stat call
#
# Example: check_file_size "docs/image.png"
check_file_size() {
  local file="$1"
  [[ ! -f "$file" ]] && return 0

  local size_bytes
  size_bytes=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")

  local hard_limit=$((10 * 1024 * 1024))  # 10 MB
  local soft_limit=$((1 * 1024 * 1024))   # 1 MB

  if [[ $size_bytes -gt $hard_limit ]]; then
    log_error "File exceeds 10MB limit: $file ($((size_bytes / 1024 / 1024))MB)"
    return 1
  fi

  if [[ $size_bytes -gt $soft_limit ]]; then
    log_warning "File exceeds 1MB soft limit: $file ($((size_bytes / 1024 / 1024))MB)"
  fi

  return 0
}

#####################################################################
# LICENSE HEADER VALIDATION
#####################################################################

# validate_license_header: Check file has MIT license header
#
# Required format (at start of file):
#   // Copyright (c) 2026 Paul Sinclair
#   // SPDX-License-Identifier: MIT
#
# Performance: O(1) - checks first few lines only
#
# Args: $1 = file path
# Returns: 0 if valid, 1 if missing
#
# Example: validate_license_header "src/newfile.c"
validate_license_header() {
  local file="$1"
  [[ ! -f "$file" ]] && return 0

  # Check first 3 lines for license header
  if head -n 3 "$file" | grep -q "SPDX-License-Identifier: MIT"; then
    return 0
  fi

  # Only required for source files (.c, .h, .sh)
  case "$file" in
    *.c|*.h|*.sh)
      log_error "Missing license header: $file"
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

#####################################################################
# CODE FORMAT VALIDATION
#####################################################################

# validate_shell_format: Check shell script formatting with shellcheck
#
# Args: $1 = file path
# Returns: 0 if valid, 1 if issues found
#
# Example: validate_shell_format "scripts/bin/mkbranch"
validate_shell_format() {
  local file="$1"
  [[ ! -f "$file" ]] && return 0

  # Only check shell scripts
  if [[ "$file" != *.sh ]]; then
    return 0
  fi

  if command -v shellcheck >/dev/null 2>&1; then
    if shellcheck "$file" >/dev/null 2>&1; then
      return 0
    else
      log_warning "shellcheck found issues in $file"
      return 1
    fi
  fi

  return 0
}

# validate_c_format: Check C/C++ formatting with clang-format
#
# Args: $1 = file path
# Returns: 0 if valid, 1 if formatting issues
#
# Example: validate_c_format "src/runnerapi.c"
validate_c_format() {
  local file="$1"
  [[ ! -f "$file" ]] && return 0

  # Only check C/C++ files
  if [[ "$file" != *.c ]] && [[ "$file" != *.h ]] && [[ "$file" != *.cpp ]]; then
    return 0
  fi

  if command -v clang-format >/dev/null 2>&1; then
    local formatted
    formatted=$(clang-format "$file" 2>/dev/null || echo "")
    local original
    original=$(cat "$file")

    if [[ "$formatted" != "$original" ]]; then
      log_warning "File not formatted correctly: $file"
      return 1
    fi
  fi

  return 0
}
