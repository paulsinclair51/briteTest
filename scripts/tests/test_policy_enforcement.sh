#!/usr/bin/env bash

# test_policy_enforcement.sh - read-only and server-policy regression tests.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GIT_HELPER="$REPO_ROOT/scripts/helpers/git_helpers.sh"
PRE_COMMIT_HOOK="$REPO_ROOT/scripts/helpers/.githooks/pre-commit"
PRE_PUSH_HOOK="$REPO_ROOT/scripts/helpers/.githooks/pre-push"
RULESET_SCRIPT="$REPO_ROOT/scripts/bin/setup_rulesets"

pass() {
  echo "PASS: $1"
}

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

for dependency in bash git grep jq mktemp; do
  command -v "$dependency" >/dev/null 2>&1 || \
    fail "missing required command: $dependency"
done

# shellcheck source=../helpers/git_helpers.sh
source "$GIT_HELPER"

bt_is_read_only_branch main || fail "main must be read-only"
bt_is_read_only_branch v1.2.0 || fail "version branch must be read-only"
bt_is_read_only_branch v1.2.1 || fail "policy-invalid branch must be read-only"
! bt_is_read_only_branch dev/parser-v1.2.0 || \
  fail "valid targeted branch must be writable"
! bt_is_read_only_branch feature/parser || \
  fail "valid contributor branch must be writable"
pass "shared read-only classification"

TMPDIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

HOOK_REPO="$TMPDIR/hook-repo"
git init "$HOOK_REPO" >/dev/null 2>&1
(
  cd "$HOOK_REPO"
  git config user.name testuser
  git config user.email test@example.com
  echo seed > README.md
  git add README.md
  git commit -m seed >/dev/null 2>&1
  git switch -c writable >/dev/null 2>&1
  git switch --detach >/dev/null 2>&1
)

set +e
(
  cd "$HOOK_REPO"
  GIT_BYPASS_HOOKS=true bash "$PRE_COMMIT_HOOK"
) >"$TMPDIR/detached.out" 2>&1
detached_rc=$?
set -e
[[ "$detached_rc" -eq 1 ]] || \
  fail "detached pre-commit should fail before bypass"
grep -Fq "Commits are not allowed while HEAD is detached" \
  "$TMPDIR/detached.out" || fail "detached rejection should be actionable"

(
  cd "$HOOK_REPO"
  git switch writable >/dev/null 2>&1
  GIT_BYPASS_HOOKS=true bash "$PRE_COMMIT_HOOK"
) || fail "authorized bypass should work on an attached branch"
pass "detached commit enforcement"

set +e
(
  cd "$HOOK_REPO"
  bash "$PRE_PUSH_HOOK"
) >"$TMPDIR/direct-push.out" 2>&1
direct_push_rc=$?
set -e
[[ "$direct_push_rc" -eq 1 ]] || fail "direct push hook should reject"
grep -Fq "Direct git push operations are not allowed" \
  "$TMPDIR/direct-push.out" || fail "direct push rejection should be actionable"
pass "direct push hook enforcement"

assert_trigger() {
  local workflow="$1"
  local trigger="$2"

  grep -Eq "^[[:space:]]{2}${trigger}:" "$workflow" || \
    fail "$(basename "$workflow") must define ${trigger} trigger"
}

assert_trigger "$REPO_ROOT/.github/workflows/validate-pull-request.yml" \
  pull_request
assert_trigger "$REPO_ROOT/.github/workflows/validate-push.yml" push
assert_trigger "$REPO_ROOT/.github/workflows/validate-merge.yml" push
assert_trigger "$REPO_ROOT/.github/workflows/validate-rulesets.yml" schedule
for workflow in "$REPO_ROOT"/.github/workflows/validate-branch-name.yml \
  "$REPO_ROOT"/.github/workflows/validate-*.yml; do
  grep -Eq '^[[:space:]]{2}(pull_request|push|delete|create|schedule):' \
    "$workflow" || fail "$(basename "$workflow") must not be manual-only"
done
pass "automatic enforcement workflow triggers"

FAKE_BIN="$TMPDIR/fake-bin"
mkdir -p "$FAKE_BIN"
cat > "$FAKE_BIN/gh" <<'EOF'
#!/usr/bin/env bash
endpoint=""
for argument in "$@"; do
  if [[ "$argument" == /repos/* ]]; then
    endpoint="$argument"
  fi
done

case "$endpoint" in
  /repos/example/repo/rulesets)
    printf '%s\n' '[{"id":1,"name":"main protection"},{"id":2,"name":"version branch protection"},{"id":3,"name":"targeted branch protection"}]'
    ;;
  /repos/example/repo/rulesets/1)
    cat <<'JSON'
{"name":"main protection","target":"branch","enforcement":"active","conditions":{"ref_name":{"include":["~DEFAULT_BRANCH"],"exclude":[]}},"rules":[{"type":"deletion"},{"type":"non_fast_forward"}],"bypass_actors":[]}
JSON
    ;;
  /repos/example/repo/rulesets/2)
    if [[ "${SIMULATE_RULESET_DRIFT:-false}" == true ]]; then
      enforcement="disabled"
    else
      enforcement="active"
    fi
    printf '%s\n' "{\"name\":\"version branch protection\",\"target\":\"branch\",\"enforcement\":\"${enforcement}\",\"conditions\":{\"ref_name\":{\"include\":[\"refs/heads/v*.*.0\"],\"exclude\":[]}},\"rules\":[{\"type\":\"deletion\"},{\"type\":\"non_fast_forward\"}],\"bypass_actors\":[]}"
    ;;
  /repos/example/repo/rulesets/3)
    printf '%s\n' '{"name":"targeted branch protection","target":"branch","enforcement":"active","conditions":{"ref_name":{"include":["refs/heads/*"],"exclude":["refs/heads/main","refs/heads/v*.*.0"]}},"rules":[{"type":"deletion"},{"type":"non_fast_forward"}],"bypass_actors":[]}'
    ;;
  *)
    echo "unexpected gh endpoint: $endpoint" >&2
    exit 1
    ;;
esac
EOF
chmod +x "$FAKE_BIN/gh"

PATH="$FAKE_BIN:$PATH" bash "$RULESET_SCRIPT" --check example/repo \
  >"$TMPDIR/ruleset-ok.out" 2>&1 || fail "matching rulesets should verify"
grep -Fq "targeted branch protection" "$TMPDIR/ruleset-ok.out" || \
  fail "targeted branch protection ruleset should be validated"

set +e
PATH="$FAKE_BIN:$PATH" SIMULATE_RULESET_DRIFT=true \
  bash "$RULESET_SCRIPT" --check example/repo \
  >"$TMPDIR/validate-rulesets.out" 2>&1
drift_rc=$?
set -e
[[ "$drift_rc" -ne 0 ]] || fail "ruleset drift should fail verification"
grep -Fq "differs from repository policy" "$TMPDIR/validate-rulesets.out" || \
  fail "ruleset drift should identify the mismatch"
pass "ruleset drift verification"

echo "All policy enforcement smoke tests passed."
