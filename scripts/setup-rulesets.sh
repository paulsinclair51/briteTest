#!/usr/bin/env bash

# setup-rulesets.sh - Setup result sets for approvers, reviewers, and contributors.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see '<repo>/LICENSE'.

# Usage:
#
#   ./scripts/setup-rulesets.sh [owner/repo]
#
# Idempotent GitHub ruleset setup with auto-cleanup (create-or-update by ruleset name)
#
# Example:
#   ./scripts/setup-rulesets.sh paulsinclair51/briteTest
#
# Requirements:
#   - gh CLI authenticated (gh auth status)
#   - jq installed
#   - repo admin permissions

set -euo pipefail

REPO="${1:-paulsinclair51/briteTest}"
API_ROOT="/repos/${REPO}/rulesets"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: required command not found: $1" >&2
    exit 1
  }
}

need_cmd gh
need_cmd jq

echo "Configuring rulesets for ${REPO} ..."

list_rulesets() {
  gh api --paginate -H "Accept: application/vnd.github+json" "${API_ROOT}"
}

# -------------------------------
# Helper: cleanup duplicates by name
# -------------------------------
cleanup_duplicates() {
  local name="$1"
  local keep_id="$2"

  # Find all rulesets with this name
  local all_ids
  all_ids="$(
    list_rulesets \
      | jq -r --arg NAME "$name" '.[] | select(.name == $NAME) | .id'
  )"

  # Delete all except the one we want to keep
  while IFS= read -r id; do
    if [[ "${id}" != "${keep_id}" ]]; then
      echo "  Removing duplicate: ${name} (id=${id})"
      gh api \
        --method DELETE \
        -H "Accept: application/vnd.github+json" \
        "${API_ROOT}/${id}" >/dev/null
    fi
  done <<< "$all_ids"
}

# -------------------------------
# Helper: upsert ruleset by name
# -------------------------------
upsert_ruleset() {
  local json_file="$1"
  local name
  name="$(jq -r '.name' "$json_file")"

  # Find existing ruleset id by exact name (prefer first match)
  local existing_id
  existing_id="$(
    list_rulesets \
      | jq -r --arg NAME "$name" '.[] | select(.name == $NAME) | .id' \
      | head -n1
  )"

  if [[ -n "${existing_id:-}" && "${existing_id}" != "null" ]]; then
    echo "Updating ruleset: ${name} (id=${existing_id})"
    
    # Cleanup any other duplicates with same name
    cleanup_duplicates "$name" "$existing_id"
    
    gh api \
      --method PUT \
      -H "Accept: application/vnd.github+json" \
      "${API_ROOT}/${existing_id}" \
      --input "$json_file" >/dev/null
    echo "✔ Updated: ${name}"
  else
    echo "Creating ruleset: ${name}"
    gh api \
      --method POST \
      -H "Accept: application/vnd.github+json" \
      "${API_ROOT}" \
      --input "$json_file" >/dev/null
    echo "✔ Created: ${name}"
  fi
}

# -------------------------------
# JSON payloads
# -------------------------------

cat > /tmp/ruleset-main.json <<'JSON'
{
  "name": "main protection",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["~DEFAULT_BRANCH"],
      "exclude": []
    }
  },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    {
      "type": "pull_request",
      "parameters": {
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": true,
        "require_last_push_approval": false,
        "required_approving_review_count": 1,
        "required_review_thread_resolution": false
      }
    },
    {
      "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": true,
        "do_not_enforce_on_create": false,
        "required_status_checks": [
          { "context": "Validate branch" }
        ]
      }
    }
  ],
  "bypass_actors": []
}
JSON

cat > /tmp/ruleset-version.json <<'JSON'
{
  "name": "version branch protection",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/v*.*.0"],
      "exclude": []
    }
  },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    {
      "type": "pull_request",
      "parameters": {
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": true,
        "require_last_push_approval": false,
        "required_approving_review_count": 1,
        "required_review_thread_resolution": false
      }
    },
    {
      "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": true,
        "do_not_enforce_on_create": false,
        "required_status_checks": [
          { "context": "Validate branch" }
        ]
      }
    }
  ],
  "bypass_actors": []
}
JSON

cat > /tmp/ruleset-targeted.json <<'JSON'
{
  "name": "targeted branch protection",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": [
        "refs/heads/dev/*-v*.*.0",
        "refs/heads/fix/*-v*.*.0"
      ],
      "exclude": []
    }
  },
  "rules": [
    {
      "type": "pull_request",
      "parameters": {
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_approving_review_count": 0,
        "required_review_thread_resolution": false
      }
    },
    {
      "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": true,
        "do_not_enforce_on_create": false,
        "required_status_checks": [
          { "context": "Validate branch" }
        ]
      }
    }
  ],
  "bypass_actors": []
}
JSON

# -------------------------------
# Apply
# -------------------------------
upsert_ruleset /tmp/ruleset-main.json
upsert_ruleset /tmp/ruleset-version.json
upsert_ruleset /tmp/ruleset-targeted.json

echo
echo "Done. Verify at: https://github.com/${REPO}/settings/rules"

echo
echo "Done."
echo "Review in: https://github.com/${REPO}/settings/rules"
