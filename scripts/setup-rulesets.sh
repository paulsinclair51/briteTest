#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./scripts/setup-rulesets.sh [owner/repo]
# Example:
#   ./scripts/setup-rulesets.sh paulsinclair51/briteTest
#
# Requirements:
#   - gh CLI installed and authenticated: gh auth status
#   - token has repo administration permission (repo + admin:repo_hook / rulesets access)

REPO="${1:-paulsinclair51/briteTest}"
API_ROOT="/repos/${REPO}/rulesets"

echo "Configuring rulesets for ${REPO} ..."

# -------------------------------
# Helper: create ruleset from JSON
# -------------------------------
create_ruleset() {
  local json_file="$1"
  local name
  name="$(jq -r '.name' "$json_file")"

  echo "Creating ruleset: ${name}"
  gh api \
    --method POST \
    -H "Accept: application/vnd.github+json" \
    "${API_ROOT}" \
    --input "$json_file" >/dev/null

  echo "✔ Created: ${name}"
}

# -------------------------------
# main protection
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

# -------------------------------
# version branch protection
# -------------------------------
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

# -------------------------------
# targeted branch protection
# -------------------------------
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

# Validate jq is installed (used only to print name)
command -v jq >/dev/null 2>&1 || {
  echo "Error: jq is required (brew install jq / apt install jq)."
  exit 1
}

create_ruleset /tmp/ruleset-main.json
create_ruleset /tmp/ruleset-version.json
create_ruleset /tmp/ruleset-targeted.json

echo
echo "Done."
echo "Review in: https://github.com/${REPO}/settings/rules"
