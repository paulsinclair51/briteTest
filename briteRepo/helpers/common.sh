#!/usr/bin/env bash

# Shared text output and branch-detection helpers.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

# Internal library: must be sourced by a briteRepo command or helper. Direct
# execution by a user is not supported.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "common.sh is a briteRepo internal library and must be sourced." >&2
  exit 1
fi

# High-Level Flow:
# - Provides shared output helpers for info/success/warn messaging.
# - Provides a common error-exit helper and branch-detection utility.
# - Provides shared GitHub login resolution helpers for role-gated scripts.
# - Maintains consistent lightweight shell behavior across briteRepo/bin tools.

bt_info() {
  echo "$1"
}

bt_success() {
  echo "$1"
}

bt_warn() {
  echo "$1"
}

bt_error_exit() {
  local code="$1"
  local message="$2"

  bt_emit_error "$message"
  exit "$code"
}

bt_ensure_trailing_period() {
  local message="$1"

  if [[ -z "$message" ]]; then
    printf '.'
    return 0
  fi

  if [[ "$message" == *"." ]]; then
    printf '%s' "$message"
  else
    printf '%s.' "$message"
  fi
}

bt_format_command_line() {
  local program_name="$1"
  shift

  local formatted="$program_name"
  local arg

  for arg in "$@"; do
    printf -v formatted '%s %q' "$formatted" "$arg"
  done

  printf '%s\n' "$formatted"
}

bt_datetime_display_now() {
  date '+%Y-%m-%d %H:%M:%S%z' | \
    sed -E 's/([+-][0-9]{2})([0-9]{2})$/\1:\2/'
}

bt_datetime_filename_now() {
  date '+%Y%m%d-%H%M%S%z'
}

bt_trim_whitespace() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

bt_normalize_whitespace() {
  printf '%s' "$1" | tr '\t' ' ' | tr -s '[:space:]' ' ' | \
    sed 's/^ //; s/ $//'
}

bt_increment_counter() {
  local var_name="$1"
  printf -v "$var_name" '%d' "$(( ${!var_name} + 1 ))"
}

bt_repo_has_required_api_files() {
  local repo_path="$1"

  [[ -f "$repo_path/src/runnerapi.c" || \
    -f "$repo_path/src/testapi.c" || \
    -f "$repo_path/include/runnerapi.h" || \
    -f "$repo_path/include/testapi.h" ]]
}

bt_emit_error() {
  local message="$1"
  printf 'Error: %s\n' "$(bt_ensure_trailing_period "$message")" >&2
}

bt_emit_guidance() {
  local message="$1"
  printf 'Guidance: %s\n' "$(bt_ensure_trailing_period "$message")" >&2
}

bt_emit_prerequisite_failure() {
  local code="$1"
  local message="$2"
  local guidance="${3:-}"

  bt_emit_error "$message"
  if [[ -n "$guidance" ]]; then
    bt_emit_guidance "$guidance"
  fi
  exit "$code"
}

bt_get_current_branch_or_empty() {
  bt_get_current_branch || true
}

bt_get_current_branch_raw() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null
}

bt_get_current_branch() {
  local branch=""

  if ! branch="$(bt_get_current_branch_raw)"; then
    return 1
  fi
  if [[ "$branch" == r-* ]]; then
    printf '%s\n' "${branch#r-}"
  else
    printf '%s\n' "$branch"
  fi
}

bt_get_current_branch_for_repo() {
  local repo="$1"
  local branch=""

  branch="$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null)" || \
    return 1
  if [[ "$branch" == r-* ]]; then
    printf '%s\n' "${branch#r-}"
  else
    printf '%s\n' "$branch"
  fi
}

bt_is_internal_remote_copy() {
  local branch="$1"

  [[ "$branch" == r-* ]]
}

bt_is_current_internal_remote_copy() {
  local branch=""

  branch="$(bt_get_current_branch_raw 2>/dev/null || true)"
  [[ "$branch" == r-* ]] && bt_is_internal_remote_copy "$branch"
}

bt_role_name_from_code() {
  case "$1" in
    A) printf 'approver' ;;
    R) printf 'reviewer' ;;
    C|*) printf 'contributor' ;;
  esac
}

# Role name for a login, defaulting to contributor when it is not listed.
bt_role_name_for_login() {
  local login="$1"
  local contributors_file="$2"
  local role_code=""

  login="$(bt_normalize_login "$login")"
  [[ -n "$login" ]] || {
    printf 'contributor'
    return 0
  }

  role_code="$(bt_contributors_get_role_or_empty "$login" \
    "$contributors_file")"
  if [[ -z "$role_code" ]] && bt_is_repository_owner_login "$login"; then
    role_code="A"
  fi

  bt_role_name_from_code "$role_code"
}

# "<login> (<role>)" for report user lines.
bt_format_login_with_role() {
  local login="$1"
  local contributors_file="$2"

  login="$(bt_normalize_login "$login")"
  [[ -n "$login" ]] || login="unknown"
  printf '%s (%s)' "$login" \
    "$(bt_role_name_for_login "$login" "$contributors_file")"
}

bt_normalize_login() {
  local login="$1"

  login="${login#@}"
  login="${login,,}"
  login="${login//[[:space:]]/}"
  printf '%s' "$login"
}

bt_resolve_login_or_empty() {
  local login=""
  local gh_login=""
  local timeout_seconds="${BT_REMOTE_TIMEOUT_SECONDS:-10}"

  if [[ -n "${GITHUB_ACTOR:-}" ]]; then
    login="$GITHUB_ACTOR"
  fi

  if [[ -z "$login" ]] && command -v gh >/dev/null 2>&1; then
    if declare -F bt_run_remote_command >/dev/null 2>&1; then
      if gh_login="$(bt_run_remote_command gh api user --jq '.login' 2>/dev/null)"; then
        login="$gh_login"
      fi
    elif [[ "$timeout_seconds" =~ ^[1-9][0-9]*$ ]] && \
      command -v timeout >/dev/null 2>&1; then
      if gh_login="$(timeout "${timeout_seconds}s" gh api user --jq '.login' 2>/dev/null)"; then
        login="$gh_login"
      fi
    else
      if gh_login="$(gh api user --jq '.login' 2>/dev/null)"; then
        login="$gh_login"
      fi
    fi
  fi

  if [[ -z "$login" ]]; then
    login="$(git config user.name 2>/dev/null || true)"
  fi

  if [[ -z "$login" && -n "${USER:-}" ]]; then
    login="$USER"
  fi

  login="$(bt_normalize_login "$login")"
  if [[ -z "$login" ]]; then
    printf ''
    return 0
  fi

  # GitHub login format check: 1-39 chars, lowercase alnum and hyphen,
  # cannot start or end with hyphen.
  if [[ ! "$login" =~ ^([a-z0-9]|[a-z0-9][a-z0-9-]{0,37}[a-z0-9])$ ]]; then
    printf ''
    return 0
  fi

  printf '%s' "$login"
}

bt_require_login() {
  local login

  login="$(bt_resolve_login_or_empty)"
  if [[ -n "$login" ]]; then
    printf '%s\n' "$login"
    return 0
  fi

  bt_emit_error "Unable to determine GitHub login identity."
  printf 'Set GITHUB_ACTOR, or run '\''gh auth login'\'', or set git user.name to your GitHub login.\n'
  return 1
}

# Resolve role code for a login from contributors.md.
# Memoized per (file, login) since callers may resolve the same login many
# times in one run (e.g. rendering many commits by the same author).
declare -gA BT_CONTRIBUTOR_ROLE_CACHE 2>/dev/null || true
bt_contributors_get_role_or_empty() {
  local login="$1"
  local contributors_file="${2:-config/contributors.md}"
  local target_login=""
  local cache_key=""
  local role_code=""

  [[ -f "$contributors_file" ]] || {
    printf ''
    return 0
  }

  target_login="$(bt_normalize_login "$login")"
  [[ -n "$target_login" ]] || {
    printf ''
    return 0
  }

  cache_key="${contributors_file}|${target_login}"
  if [[ -n "${BT_CONTRIBUTOR_ROLE_CACHE[$cache_key]+x}" ]]; then
    printf '%s' "${BT_CONTRIBUTOR_ROLE_CACHE[$cache_key]}"
    return 0
  fi

  # Single awk pass replaces per-line sed/tr forking: strips leading
  # whitespace and a leading "- " bullet, splits on the first comma, then
  # normalizes login (lowercase, no whitespace, no leading @) and role
  # (uppercase, no whitespace) the same way bt_normalize_login does.
  role_code="$(awk -F',' -v target="$target_login" '
    {
      line = $0
      sub(/^[[:space:]]+/, "", line)
      if (line == "" || line ~ /^#/) next
      if (line ~ /^-[[:space:]]+/) { sub(/^-[[:space:]]+/, "", line) }
      n = split(line, parts, ",")
      raw_login = parts[1]
      raw_role = (n >= 2) ? parts[2] : ""
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", raw_login)
      sub(/^@/, "", raw_login)
      parsed_login = tolower(raw_login)
      gsub(/[[:space:]]/, "", parsed_login)
      role = toupper(raw_role)
      gsub(/[[:space:]]/, "", role)
      if (role !~ /^[CRA]$/) next
      if (parsed_login == target) {
        print role
        exit
      }
    }
  ' "$contributors_file")"

  BT_CONTRIBUTOR_ROLE_CACHE["$cache_key"]="$role_code"
  printf '%s' "$role_code"
}

bt_contributors_has_min_role() {
  local login="$1"
  local required_role="$2"
  local contributors_file="${3:-config/contributors.md}"

  local role_code
  role_code="$(bt_contributors_get_role_or_empty "$login" "$contributors_file")"

  case "$required_role" in
    contributor)
      [[ "$role_code" == "C" || "$role_code" == "R" || "$role_code" == "A" ]]
      ;;
    reviewer)
      [[ "$role_code" == "R" || "$role_code" == "A" ]]
      ;;
    approver)
      [[ "$role_code" == "A" ]]
      ;;
    *)
      return 1
      ;;
  esac
}

bt_contributors_has_approver() {
  local contributors_file="${1:-config/contributors.md}"

  [[ -f "$contributors_file" ]] || return 1

  grep -E '^[[:space:]]*-[[:space:]]*[^,]+,[[:space:]]*A([[:space:]]*,|[[:space:]]*$)' "$contributors_file" >/dev/null 2>&1 && return 0
  grep -E '^[[:space:]]*-[[:space:]]*A/[^,[:space:]]+' "$contributors_file" >/dev/null 2>&1 && return 0
  return 1
}

bt_require_min_role_or_exit() {
  local login="$1"
  local required_role="$2"
  local contributors_file="$3"
  local exit_code="$4"
  local message="$5"

  if ! bt_contributors_has_min_role "$login" "$required_role" "$contributors_file"; then
    bt_error_exit "$exit_code" "$message"
  fi
}

bt_require_approver_presence_or_exit() {
  local contributors_file="$1"
  local exit_code="$2"
  local message="$3"

  if ! bt_contributors_has_approver "$contributors_file"; then
    bt_error_exit "$exit_code" "$message"
  fi
}

bt_role_satisfies_minimum() {
  local role_code="$1"
  local required_role="$2"

  case "$required_role" in
    contributor)
      [[ "$role_code" == "C" || "$role_code" == "R" || "$role_code" == "A" ]]
      ;;
    reviewer)
      [[ "$role_code" == "R" || "$role_code" == "A" ]]
      ;;
    approver)
      [[ "$role_code" == "A" ]]
      ;;
    *)
      return 1
      ;;
  esac
}

bt_contributors_get_role_for_email_or_empty() {
  local email="$1"
  local contributors_file="${2:-config/contributors.md}"

  [[ -f "$contributors_file" ]] || {
    printf ''
    return 0
  }

  local target_email
  target_email="$(printf '%s' "$email" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
  [[ -n "$target_email" ]] || {
    printf ''
    return 0
  }

  local line
  local role_code

  while IFS= read -r line; do
    local entry raw_role raw_email parsed_email
    entry="$(printf '%s' "$line" | sed -E 's/^[[:space:]]+//')"
    [[ -n "$entry" ]] || continue
    [[ "$entry" =~ ^# ]] && continue
    [[ "$entry" =~ ^## ]] && continue

    if [[ "$entry" =~ ^-[[:space:]]+ ]]; then
      entry="${entry#- }"
    fi

    IFS=',' read -r _ raw_role raw_email _ <<< "$entry"

    role_code="$(printf '%s' "${raw_role:-}" | tr '[:lower:]' '[:upper:]' | tr -d '[:space:]')"
    [[ "$role_code" =~ ^[CRA]$ ]] || continue

    parsed_email="$(printf '%s' "${raw_email:-}" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
    if [[ -n "$parsed_email" && "$parsed_email" == "$target_email" ]]; then
      printf '%s' "$role_code"
      return 0
    fi
  done < "$contributors_file"

  printf ''
}

bt_contributors_has_min_role_by_login_or_email() {
  local login="$1"
  local email="$2"
  local required_role="$3"
  local contributors_file="${4:-config/contributors.md}"

  local role_code
  role_code="$(bt_contributors_get_role_or_empty "$login" "$contributors_file")"
  if [[ -n "$role_code" ]]; then
    bt_role_satisfies_minimum "$role_code" "$required_role"
    return $?
  fi

  role_code="$(bt_contributors_get_role_for_email_or_empty "$email" "$contributors_file")"
  [[ -n "$role_code" ]] || return 1

  bt_role_satisfies_minimum "$role_code" "$required_role"
}

bt_resolve_repo_owner_login_or_empty() {
  local repo_slug="${GITHUB_REPOSITORY:-}"
  local remote_url=""
  local owner=""

  remote_url="$(git remote get-url origin 2>/dev/null || true)"
  if [[ "$remote_url" =~ ^git@github\.com:([^/]+)/([^/]+)(\.git)?$ ]]; then
    owner="${BASH_REMATCH[1]}"
  elif [[ "$remote_url" =~ ^https://github\.com/([^/]+)/([^/]+)(\.git)?$ ]]; then
    owner="${BASH_REMATCH[1]}"
  elif [[ "$remote_url" =~ ^ssh://git@github\.com/([^/]+)/([^/]+)(\.git)?$ ]]; then
    owner="${BASH_REMATCH[1]}"
  fi

  if [[ -z "$owner" && -n "$repo_slug" && "$repo_slug" == */* ]]; then
    owner="${repo_slug%%/*}"
  fi

  bt_normalize_login "$owner"
}

# Memoized so repeated per-commit lookups (e.g. from report generation)
# don't re-run "git remote get-url" every time.
BT_REPO_OWNER_LOGIN_RESOLVED=false
BT_REPO_OWNER_LOGIN_CACHED=""
bt_is_repository_owner_login() {
  local login="$1"

  if [[ "$BT_REPO_OWNER_LOGIN_RESOLVED" != true ]]; then
    BT_REPO_OWNER_LOGIN_CACHED="$(bt_resolve_repo_owner_login_or_empty)"
    BT_REPO_OWNER_LOGIN_RESOLVED=true
  fi
  [[ -n "$BT_REPO_OWNER_LOGIN_CACHED" ]] || return 1

  [[ "$(bt_normalize_login "$login")" == "$BT_REPO_OWNER_LOGIN_CACHED" ]]
}
