#!/usr/bin/env bash

# test_mrgup.sh - Smoke tests for mrgup -o (owner override) and PR approval gate.
#
# Exercises:
#   1. Help output includes -o.
#   2. -o rejected when current user is not the repository owner.
#   3. -o by owner, no open PR → dry-run succeeds without any PR validation.
#   4. -o by owner, PR exists but NOT approved → blocked with "not approved" error.
#   5. -o by owner, PR IS approved, status checks pass → dry-run succeeds, PR title used.
#   6. Normal path (no -o), user is approver, PR required, PR NOT approved → blocked.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MRGUP_SRC="$REPO_ROOT/scripts/bin/mrgup"
HELPERS_DIR="$REPO_ROOT/scripts/helpers"

pass() { echo "PASS: $1"; }

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

assert_contains() {
  local text="$1" file="$2"
  grep -Fq -- "$text" "$file" || fail "expected '$text' in output (see $file)"
}

assert_not_contains() {
  local text="$1" file="$2"
  ! grep -Fq -- "$text" "$file" || fail "did not expect '$text' in output (see $file)"
}

for dep in bash git grep mktemp; do
  command -v "$dep" >/dev/null 2>&1 || fail "missing required command: $dep"
done
[[ -f "$MRGUP_SRC" ]] || fail "missing script: $MRGUP_SRC"

TMPDIR="$(mktemp -d)"
cleanup() {
  if [[ "${KEEP_TMPDIR:-0}" == "1" ]]; then
    echo "KEEP_TMPDIR=1 preserving test artifacts at: $TMPDIR" >&2
    return 0
  fi
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

ORIGIN="$TMPDIR/origin.git"
WORK="$TMPDIR/work"
FAKEBIN="$TMPDIR/fakebin"

# ---------------------------------------------------------------------------
# Fake git: intercept 'git remote get-url origin' so get_repository_owner_login
# sees a GitHub-format URL while real git still operates against the local bare
# repo for fetches, pushes, etc.
# ---------------------------------------------------------------------------
mkdir -p "$FAKEBIN"
REAL_GIT="$(command -v git)"
cat > "$FAKEBIN/git" << GITEOF
#!/usr/bin/env bash
if [[ "\$#" -eq 3 && "\$1" == "remote" && "\$2" == "get-url" && "\$3" == "origin" ]]; then
  echo "https://github.com/\${FAKE_REPO_OWNER:-testowner}/testrepo.git"
  exit 0
fi
exec "$REAL_GIT" "\$@"
GITEOF
chmod +x "$FAKEBIN/git"

# ---------------------------------------------------------------------------
# Fake gh: dispatches on arg patterns; controlled by FAKE_GH_* env vars.
#   FAKE_GH_LOGIN           — identity returned for 'gh api user'
#   FAKE_GH_PR_NUMBER       — empty = no open PR; set = PR number
#   FAKE_GH_REVIEW_DECISION — APPROVED | CHANGES_REQUESTED | ...
#   FAKE_GH_STATUS_CHECKS   — SUCCESS | FAILURE | PENDING
#   FAKE_GH_PR_TITLE        — commit message when PR title is used
# ---------------------------------------------------------------------------
cat > "$FAKEBIN/gh" << 'GHEOF'
#!/usr/bin/env bash
args="$*"
# Identity lookup
if [[ "$args" == *"api user"* ]]; then
  echo "${FAKE_GH_LOGIN:-testowner}"
  exit 0
fi
# PR list (bt_gh_find_pr_number_for_branch)
if [[ "$args" == *"pr list"* ]]; then
  echo "${FAKE_GH_PR_NUMBER:-}"
  exit 0
fi
# PR review decision (check_pr_approval)
if [[ "$args" == *"reviewDecision"* ]]; then
  echo "${FAKE_GH_REVIEW_DECISION:-APPROVED}"
  exit 0
fi
# PR status checks (check_status_checks)
if [[ "$args" == *"statusCheckRollup"* ]]; then
  echo "${FAKE_GH_STATUS_CHECKS:-SUCCESS}"
  exit 0
fi
# PR title (get_pr_title)
if [[ "$args" == *"json title"* ]]; then
  echo "${FAKE_GH_PR_TITLE:-Test PR title}"
  exit 0
fi
echo "unhandled gh args: $args" >&2
exit 1
GHEOF
chmod +x "$FAKEBIN/gh"

# ---------------------------------------------------------------------------
# Bootstrap git repos
# ---------------------------------------------------------------------------
git init --bare "$ORIGIN" >/dev/null 2>&1
"$REAL_GIT" clone "$ORIGIN" "$WORK" >/dev/null 2>&1

# Copy scripts so mrgup sources helpers relative to its own SCRIPT_DIR.
mkdir -p "$WORK/scripts/bin" "$WORK/scripts/helpers" \
         "$WORK/config" "$WORK/reports/branch" "$WORK/logs"
cp "$MRGUP_SRC" "$WORK/scripts/bin/mrgup"
chmod +x "$WORK/scripts/bin/mrgup"
for helper in common.sh git_helpers.sh github_helpers.sh \
              validation-helpers.sh history_log.sh rbac.sh \
              ckrole.sh common-utils.sh ckbranchname.sh; do
  [[ -f "$HELPERS_DIR/$helper" ]] && \
    cp "$HELPERS_DIR/$helper" "$WORK/scripts/helpers/$helper"
done

(
  cd "$WORK"
  "$REAL_GIT" config user.name "testowner"
  "$REAL_GIT" config user.email "testowner@example.com"

  # contributors.md: testowner is an approver
  cat > config/contributors.md << 'MDEOF'
## Contributors

- testowner, A, testowner@example.com
MDEOF

  echo "# README" > README.md
  echo "# Repository History" > logs/repository_history.md
  "$REAL_GIT" add .
  "$REAL_GIT" commit -m "seed" >/dev/null 2>&1
  "$REAL_GIT" branch -M main
  "$REAL_GIT" push -u origin main >/dev/null 2>&1

  # v1.0.0 — parent protected version branch
  "$REAL_GIT" checkout -b v1.0.0 >/dev/null 2>&1
  "$REAL_GIT" commit --allow-empty -m "v1.0.0 base" >/dev/null 2>&1
  "$REAL_GIT" push -u origin v1.0.0 >/dev/null 2>&1

  # dev/feat-v1.0.0 — targeted branch; parent resolves to v1.0.0 by naming rule
  "$REAL_GIT" checkout -b dev/feat-v1.0.0 >/dev/null 2>&1
  echo "feature work" > feature.txt
  "$REAL_GIT" add feature.txt
  "$REAL_GIT" commit -m "feature commit" >/dev/null 2>&1
  "$REAL_GIT" push -u origin dev/feat-v1.0.0 >/dev/null 2>&1
)

# ---------------------------------------------------------------------------
# Helper: run mrgup in $WORK with faked PATH and extra env args
# Usage: run_mrgup <outfile> [ENV=val ...] -- [mrgup-args ...]
# Returns exit code on stdout.
# ---------------------------------------------------------------------------
run_mrgup() {
  local outfile="$1"; shift
  # Collect env assignments until '--'
  local -a envvars=()
  while [[ $# -gt 0 && "$1" != "--" ]]; do
    envvars+=("$1"); shift
  done
  [[ "${1:-}" == "--" ]] && shift
  local -a mrgup_args=("$@")

  set +e
  (
    cd "$WORK"
    export PATH="$FAKEBIN:$PATH"
    env "${envvars[@]}" bash ./scripts/bin/mrgup "${mrgup_args[@]}"
  ) >"$outfile" 2>&1
  local rc=$?
  set -e
  echo "$rc"
}

# ---------------------------------------------------------------------------
# Test 1: help output includes -o and Owner override text
# ---------------------------------------------------------------------------
rc=$(
  set +e; bash "$MRGUP_SRC" -h >"$TMPDIR/help.out" 2>&1; echo $?
)
[[ "$rc" -eq 0 ]] || fail "mrgup -h should exit 0"
assert_contains "Usage:" "$TMPDIR/help.out"
assert_contains "-o" "$TMPDIR/help.out"
assert_contains "Owner override" "$TMPDIR/help.out"
pass "help output includes -o"

# ---------------------------------------------------------------------------
# Test 2: -o rejected for non-owner user
# ---------------------------------------------------------------------------
rc=$(run_mrgup "$TMPDIR/nonowner.out" \
  "GITHUB_ACTOR=otheruser" "FAKE_REPO_OWNER=testowner" -- -o -d)
[[ "$rc" -ne 0 ]] || fail "-o by non-owner should fail (got exit 0)"
assert_contains "allowed only for the repository owner" "$TMPDIR/nonowner.out"
pass "-o rejected for non-owner"

# ---------------------------------------------------------------------------
# Test 3: -o by owner, no open PR → dry-run succeeds, no PR validation
# ---------------------------------------------------------------------------
rc=$(run_mrgup "$TMPDIR/owner-nopr.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=" -- -o -d -m "Owner override no PR")
[[ "$rc" -eq 0 ]] || {
  echo "--- output ---"; cat "$TMPDIR/owner-nopr.out"
  fail "-o owner, no PR: dry-run should exit 0 (got $rc)"
}
assert_contains "Dry run complete" "$TMPDIR/owner-nopr.out"
assert_contains "PR is not required" "$TMPDIR/owner-nopr.out"
assert_contains "Using custom message: Owner override no PR" "$TMPDIR/owner-nopr.out"
assert_not_contains "is not approved" "$TMPDIR/owner-nopr.out"
pass "-o owner, no PR: dry-run succeeds without PR check"

# ---------------------------------------------------------------------------
# Test 4: -o by owner, PR exists but NOT approved → fails
# ---------------------------------------------------------------------------
rc=$(run_mrgup "$TMPDIR/owner-pr-unapproved.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=42" "FAKE_GH_REVIEW_DECISION=CHANGES_REQUESTED" -- -o -d)
[[ "$rc" -ne 0 ]] || fail "-o owner with unapproved PR should fail (got exit 0)"
assert_contains "is not approved" "$TMPDIR/owner-pr-unapproved.out"
pass "-o owner, PR not approved: merge correctly blocked"

# ---------------------------------------------------------------------------
# Test 5: -o by owner, PR IS approved and status checks pass → dry-run succeeds
# ---------------------------------------------------------------------------
rc=$(run_mrgup "$TMPDIR/owner-pr-approved.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=42" "FAKE_GH_REVIEW_DECISION=APPROVED" \
  "FAKE_GH_STATUS_CHECKS=SUCCESS" "FAKE_GH_PR_TITLE=My approved PR" -- -o -d)
[[ "$rc" -eq 0 ]] || {
  echo "--- output ---"; cat "$TMPDIR/owner-pr-approved.out"
  fail "-o owner, approved PR: dry-run should exit 0 (got $rc)"
}
assert_contains "Dry run complete" "$TMPDIR/owner-pr-approved.out"
assert_contains "is approved" "$TMPDIR/owner-pr-approved.out"
assert_contains "My approved PR" "$TMPDIR/owner-pr-approved.out"
pass "-o owner, approved PR: dry-run succeeds, uses PR title"

# ---------------------------------------------------------------------------
# Test 6: Normal path (no -o), user is approver, PR NOT approved → fails
# ---------------------------------------------------------------------------
rc=$(run_mrgup "$TMPDIR/normal-pr-unapproved.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=42" "FAKE_GH_REVIEW_DECISION=CHANGES_REQUESTED" -- -d)
[[ "$rc" -ne 0 ]] || fail "normal path with unapproved PR should fail (got exit 0)"
assert_contains "is not approved" "$TMPDIR/normal-pr-unapproved.out"
pass "normal path, PR required but not approved: merge correctly blocked"

echo "All mrgup owner-override and PR-approval smoke tests passed."
