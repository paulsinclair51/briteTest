#!/usr/bin/env bash

# ckrole.sh - Verify whether the current user has a requested contributor role.
#
# Usage:
#   ./scripts/helpers/ckrole.sh <ROLE>
#
# ROLE is case-insensitive and one of:
#   contributor | reviewer | approver
#
# contributors.md format (relevant fields):
#   - <github-login>, <C|R|A>, <email>
#
# Identity resolution uses shared helper logic in this order:
#   1) GITHUB_ACTOR
#   2) gh api user --jq '.login' (when gh is authenticated)
#   3) git config user.name
#   4) USER
#
# Optional env override for automation/bots:
#   CKROLE_TRUSTED_ACTORS="actor1,actor2,..."
# If GITHUB_ACTOR matches one of those entries (case-insensitive), ckrole
# returns success for any requested role.
#
# Exit codes:
#   0 if user has requested role
#   1 otherwise

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$script_dir/common.sh"

role_arg="${1:-}"
if [[ -z "$role_arg" ]]; then
  echo "Usage: $0 <ROLE>" >&2
  exit 1
fi

role="$(printf '%s' "$role_arg" | tr '[:upper:]' '[:lower:]')"
case "$role" in
  contributor|reviewer|approver) ;;
  *)
    echo "Error: ROLE must be one of: contributor, reviewer, approver" >&2
    exit 1
    ;;
esac

if ! actor_lc="$(bt_require_login)"; then
  exit 1
fi
actor="$actor_lc"

trusted_actors="${CKROLE_TRUSTED_ACTORS:-}"
if [[ -n "$trusted_actors" ]]; then
  IFS=',' read -r -a trusted_list <<< "$trusted_actors"
  for trusted in "${trusted_list[@]}"; do
    trusted="$(printf '%s' "$trusted" | tr '[:upper:]' '[:lower:]')"
    trusted="${trusted#@}"
    trusted="$(printf '%s' "$trusted" | tr -d '[:space:]')"
    if [[ -n "$trusted" && "$actor_lc" == "$trusted" ]]; then
      exit 0
    fi
  done
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
contributors_file="$repo_root/config/contributors.md"

if [[ ! -f "$contributors_file" ]]; then
  echo "Error: contributors file not found: $contributors_file" >&2
  exit 1
fi

has_required_role() {
  local code="$1"
  local requested="$2"

  case "$requested" in
    contributor)
      [[ "$code" == "C" || "$code" == "R" || "$code" == "A" ]]
      ;;
    reviewer)
      [[ "$code" == "R" || "$code" == "A" ]]
      ;;
    approver)
      [[ "$code" == "A" ]]
      ;;
    *)
      return 1
      ;;
  esac
}

trim() {
  local s="$1"
  s="${s#${s%%[![:space:]]*}}"
  s="${s%${s##*[![:space:]]}}"
  printf '%s' "$s"
}

matched=0
while IFS= read -r line; do
  [[ "$line" =~ ^[[:space:]]*-[[:space:]] ]] || continue

  entry="${line#- }"
  IFS=',' read -r raw_login raw_role _raw_email _extra <<< "$entry"

  login="$(trim "${raw_login:-}")"
  role_code="$(trim "${raw_role:-}")"
  role_code="$(printf '%s' "$role_code" | tr '[:lower:]' '[:upper:]')"
  login_lc="$(printf '%s' "${login#@}" | tr '[:upper:]' '[:lower:]')"

  [[ "$role_code" =~ ^[CRA]$ ]] || continue
  [[ -n "$login_lc" ]] || continue

  if [[ "$actor_lc" == "$login_lc" ]]; then
    matched=1
    if has_required_role "$role_code" "$role"; then
      exit 0
    fi
    exit 1
  fi
done < "$contributors_file"

if [[ $matched -eq 0 ]]; then
  echo "Role check failed: user '$actor' not found in contributors list" >&2
fi
exit 1
