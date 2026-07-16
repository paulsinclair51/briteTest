#!/bin/bash

# Script Permission Definitions for briteTest
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
#
# Purpose: Define which scripts can be executed by each role.
#          Roles are hierarchical: Approver > Reviewer > Contributor
#
# Note: Command-name mappings were updated to renamed scripts (mrgup,
# mrgdown, mrgbranch, review). End-to-end RBAC enforcement integration
# requires a separate full review and is intentionally deferred.
#
# Role Hierarchy:
#   Approver (A) = Full access to all scripts
#   Reviewer (R) = Access to contributor + reviewer scripts
#   Contributor (C) = Access to contributor scripts only
#
# Protected Scripts (require approver override):
#   - mrgup - Merge branches to protected branches
#   - release     - Create releases and tags
#   - fixrepo - Repair repository state

set -euo pipefail

# Source common utilities
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common-utils.sh
source "${script_dir}/common-utils.sh"

#####################################################################
# ROLE DEFINITIONS
#####################################################################

# Contributor scripts (available to C, R, A)
readonly CONTRIBUTOR_SCRIPTS=(
  "mkbranch"           # Create branches
  "mkclone"            # Clone repository
  "rmclone"            # Remove local clone safely
  "commit"           # Create commits
  "copyfix"            # Cherry-pick fixes between branches
  "mrgbranch"       # Sync with remote
  "mrgdown"           # Sync current branch with parent branch
  "undo"             # Undo changes
  "lsbranchlog"   # Check branch history
  "lsbranch"           # List branches
)

# Reviewer scripts (available to R, A - in addition to contributor scripts)
readonly REVIEWER_SCRIPTS=(
  "feedback"         # Provide code review feedback
  "review"      # Create/update pull requests
  "ckstyle"            # Check code style
)

# Approver scripts (available to A only - in addition to all scripts)
readonly APPROVER_SCRIPTS=(
  "mrgup"    # Merge branches (protected)
  "retarget"           # Retarget targeted branch to another version parent
  "release"          # Create releases (protected)
  "fixrepo"            # Fix repository issues (protected)
  "rebrand"        # Update branding
  "replacetext"     # Replace text globally
)

# Utility scripts (available to all)
readonly UTILITY_SCRIPTS=(
  "gendocs"            # Generate documentation
  "genpngs"            # Generate PNG files
  "lsbranchlog"   # Check branch history
  "installscripts"     # Install scripts
)

# Protected scripts (require approver override confirmation)
readonly PROTECTED_SCRIPTS=(
  "mrgup"
  "retarget"
  "release"
  "fixrepo"
)

#####################################################################
# PERMISSION CHECK FUNCTIONS
#####################################################################

# get_user_role: Get role from config/contributors.md
# Args: $1 = username (from GITHUB_ACTOR or git config)
# Returns: prints role (A, R, or C), or empty if not found
get_user_role() {
  local username="$1"
  local contributors_file="config/contributors.md"

  if [[ ! -f "$contributors_file" ]]; then
    log_warning "Contributors file not found: $contributors_file"
    echo "C"  # Default to Contributor
    return
  fi

  # Extract role for username (format: username, role, email)
  local role
  role=$(grep "^- $username," "$contributors_file" 2>/dev/null | \
          awk -F',' '{print $2}' | tr -d ' ' || echo "")

  if [[ -z "$role" ]]; then
    # User not in contributors list
    echo "C"  # Default to Contributor
  else
    echo "$role"
  fi
}

# can_execute_script: Check if user can execute a specific script
#
# Args: $1 = username, $2 = script name
# Returns: 0 if allowed, 1 if not allowed
#
# Example: can_execute_script "paulsinclair51" "mrgup"
can_execute_script() {
  local username="$1"
  local script="$2"

  # Get user's role
  local role
  role=$(get_user_role "$username")

  # Check if script is in allowed list for this role
  if [[ "$role" == "A" ]]; then
    # Approvers can run anything
    return 0
  elif [[ "$role" == "R" ]]; then
    # Reviewers can run contributor + reviewer scripts
    if array_contains "$script" "${CONTRIBUTOR_SCRIPTS[@]}" \
                                 "${REVIEWER_SCRIPTS[@]}" \
                                 "${UTILITY_SCRIPTS[@]}"; then
      return 0
    fi
  elif [[ "$role" == "C" ]]; then
    # Contributors can run contributor scripts only
    if array_contains "$script" "${CONTRIBUTOR_SCRIPTS[@]}" \
                                 "${UTILITY_SCRIPTS[@]}"; then
      return 0
    fi
  fi

  return 1
}

# is_protected_script: Check if script is protected (requires approver)
#
# Args: $1 = script name
# Returns: 0 if protected, 1 if not protected
#
# Example: is_protected_script "mrgup"
is_protected_script() {
  local script="$1"
  array_contains "$script" "${PROTECTED_SCRIPTS[@]}"
}

# requires_approver_override: Check if script requires approver override
#
# Protected scripts require explicit approval even from approvers
#
# Args: $1 = script name, $2 = username
# Returns: 0 if requires override, 1 if not required
#
# Example: requires_approver_override "mrgup" "paulsinclair51"
requires_approver_override() {
  local script="$1"
  local username="$2"

  # Only protected scripts require override
  if ! is_protected_script "$script"; then
    return 1
  fi

  # Even approvers need override for protected scripts
  local role
  role=$(get_user_role "$username")

  if [[ "$role" != "A" ]]; then
    # Non-approvers cannot run protected scripts at all
    return 2  # Not allowed
  fi

  return 0  # Requires override
}

#####################################################################
# ENFORCEMENT FUNCTIONS
#####################################################################

# enforce_script_access: Enforce RBAC for script execution
#
# This function should be called at the start of every script.
# It checks if the user has permission to run the script.
#
# Args: $1 = script name
# Returns: 0 if allowed, exits with error if not allowed
#
# Example: enforce_script_access "mrgup"
enforce_script_access() {
  local script="$1"
  local username="${GITHUB_ACTOR:-$(git config user.name)}"

  log_section "Script Access Control Check"
  log_detail "Script: $script"
  log_detail "User: $username"

  # Get user role
  local role
  role=$(get_user_role "$username")
  log_detail "Role: $role"

  # Check if user can execute this script
  if ! can_execute_script "$username" "$script"; then
    log_error "Permission denied: $username ($role) cannot execute $script"
  fi

  log_info "Permission granted"
}

# request_approver_override: Request confirmation for protected script
#
# Protected scripts require explicit approver confirmation to prevent
# accidental execution of dangerous operations.
#
# Args: $1 = script name, $2 = operation description
# Returns: 0 if confirmed, exits if not confirmed
#
# Example: request_approver_override "mrgup" "merge feature to main"
request_approver_override() {
  local script="$1"
  local operation="${2:-execute this script}"

  local username="${GITHUB_ACTOR:-$(git config user.name)}"
  local role
  role=$(get_user_role "$username")

  # Check if user is approver
  if [[ "$role" != "A" ]]; then
    log_error "Only approvers can execute protected script: $script"
  fi

  log_section "Protected Script Confirmation Required"
  log_warning "This is a protected operation that modifies the repository"
  log_detail "Script: $script"
  log_detail "Operation: $operation"
  log_detail "User: $username (Approver)"

  # In GitHub Actions, we can't prompt interactively
  # So we check for explicit environment variable or command-line flag
  if [[ "${SCRIPT_OVERRIDE_CONFIRMED:-}" != "true" ]]; then
    log_error "Protected script requires SCRIPT_OVERRIDE_CONFIRMED=true"
  fi

  echo ""
  log_info "Override confirmed by approver"
  log_detail "Audit: $username approved execution of $script at $(date)"

  # Log to audit trail
  echo "[AUDIT] $(date '+%Y-%m-%d %H:%M:%S') Approver $username approved: "\
"$script ($operation)" >> logs/approver-audit.log 2>/dev/null || true
}

#####################################################################
# ROLE INFORMATION FUNCTIONS
#####################################################################

# print_role_capabilities: Display what a role can do
#
# Args: $1 = role (A, R, C)
#
# Example: print_role_capabilities "R"
print_role_capabilities() {
  local role="$1"

  case "$role" in
    A)
      echo "Approver (A) - Full Access"
      echo "Can execute all scripts including protected operations:"
      echo ""
      echo "  Contributor scripts:"
      printf '    - %s\n' "${CONTRIBUTOR_SCRIPTS[@]}"
      echo ""
      echo "  Reviewer scripts:"
      printf '    - %s\n' "${REVIEWER_SCRIPTS[@]}"
      echo ""
      echo "  Approver scripts (protected):"
      printf '    - %s\n' "${APPROVER_SCRIPTS[@]}"
      echo ""
      echo "  Utility scripts:"
      printf '    - %s\n' "${UTILITY_SCRIPTS[@]}"
      ;;
    R)
      echo "Reviewer (R) - Contributor + Reviewer Access"
      echo "Can execute:"
      echo ""
      echo "  Contributor scripts:"
      printf '    - %s\n' "${CONTRIBUTOR_SCRIPTS[@]}"
      echo ""
      echo "  Reviewer scripts:"
      printf '    - %s\n' "${REVIEWER_SCRIPTS[@]}"
      echo ""
      echo "  Utility scripts:"
      printf '    - %s\n' "${UTILITY_SCRIPTS[@]}"
      echo ""
      echo "  Cannot execute (require Approver role):"
      printf '    - %s\n' "${APPROVER_SCRIPTS[@]}"
      ;;
    C)
      echo "Contributor (C) - Basic Access"
      echo "Can execute:"
      echo ""
      echo "  Contributor scripts:"
      printf '    - %s\n' "${CONTRIBUTOR_SCRIPTS[@]}"
      echo ""
      echo "  Utility scripts:"
      printf '    - %s\n' "${UTILITY_SCRIPTS[@]}"
      echo ""
      echo "  Cannot execute (require Reviewer or Approver role):"
      printf '    - %s\n' "${REVIEWER_SCRIPTS[@]}"
      echo ""
      echo "  Cannot execute (require Approver role):"
      printf '    - %s\n' "${APPROVER_SCRIPTS[@]}"
      ;;
    *)
      log_error "Unknown role: $role"
      ;;
  esac
}

# whoami_script: Display current user's permissions
#
# Example: whoami_script
whoami_script() {
  local username="${GITHUB_ACTOR:-$(git config user.name)}"
  local role
  role=$(get_user_role "$username")

  echo "Current User: $username"
  echo "Role: $role"
  echo ""
  print_role_capabilities "$role"
}
