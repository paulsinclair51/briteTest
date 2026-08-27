#!/usr/bin/env bash

# test_pushup.sh - Contract tests for pushup policy and merge behavior.
#
# Exercises:
#   1. Help output includes -o.
#   2. -o requires repository ownership, not contributor membership.
#   3. -o by owner, no open PR → dry-run succeeds with compact summary output.
#   4. -o by owner, PR exists but NOT approved → blocked with "not approved" error.
#   5. -o by owner, PR IS approved, status checks pass → dry-run succeeds.
#   6. Normal path (no -o), user is approver, PR required, PR NOT approved → blocked.
#   7. Non-verbose dry-run output stays compact (no info-level chatter).
#   8. One-time post-merge verification mismatch triggers targeted auto-repair
#      and completes successfully.
#   9. Local run lock blocks overlapping pushup invocation.
#  10. Merge-time git failure emits recovery guidance (resolve + rerun).
#  11. Locality and branch-state failures return usage-defined exits 16-26.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PUSHUP_SRC="$REPO_ROOT/briteRepo/helpers/pushup_parent.sh"
PUSH_SRC="$REPO_ROOT/briteRepo/bin/push"
HELPERS_DIR="$REPO_ROOT/briteRepo/helpers"

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

run_capture() {
  local outfile="$1"
  shift
  set +e
  "$@" >"$outfile" 2>&1
  local rc=$?
  set -e
  echo "$rc"
}

latest_report() {
  local repo_root="$1"
  find "$repo_root/reports" -maxdepth 1 -type f -name 'pushup-e-*.md' -printf '%T@ %p\n' | sort -n | tail -n 1 | cut -d' ' -f2-
}

for dep in bash git grep mktemp; do
  command -v "$dep" >/dev/null 2>&1 || fail "missing required command: $dep"
done
[[ -f "$PUSHUP_SRC" ]] || fail "missing script: $PUSHUP_SRC"
[[ -f "$PUSH_SRC" ]] || fail "missing script: $PUSH_SRC"

TMPDIR="$(mktemp -d)"
cleanup() {
  if [[ "${KEEP_TMPDIR:-0}" == "1" ]]; then
    echo "KEEP_TMPDIR=1 preserving test artifacts at: $TMPDIR" >&2
    return 0
  fi
  chmod -R u+w "$TMPDIR" >/dev/null 2>&1 || true
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
  if [[ "\${FAKE_REMOTE_UNCONFIGURED:-0}" == "1" ]]; then
    exit 2
  fi
  echo "https://github.com/\${FAKE_REPO_OWNER:-testowner}/testrepo.git"
  exit 0
fi

if [[ "\$1" == "ls-remote" && "\$2" == "--exit-code" && "\$3" == "origin" ]]; then
  if [[ "\${FAKE_PUSH_REMOTE_BRANCH_MISSING:-0}" == "1" ]]; then
    exit 0
  fi
  exec "$REAL_GIT" "\$@"
fi

if [[ "\${FAKE_REMOTE_UNREACHABLE:-0}" == "1" && "\$*" == *"ls-remote --exit-code origin HEAD"* ]]; then
  exit 1
fi

# Deterministic branch-state faults avoid mutating the shared fixture for each
# ahead/behind/diverged contract case.
if [[ "\$1" == "rev-list" && "\$2" == "--left-right" && "\$3" == "--count" && \
      -n "\${FAKE_SYNC_REF:-}" && "\${4:-}" == "\$FAKE_SYNC_REF" ]]; then
  echo -e "\${FAKE_SYNC_COUNTS:-0\\t0}"
  exit 0
fi

if [[ "\${FAKE_CURRENT_BEHIND_PARENT:-0}" == "1" && "\$1" == "merge-base" && \
      "\$2" == "--is-ancestor" && "\${3:-}" == "v1.0.0" && \
      "\${4:-}" == "dev/feat-v1.0.0" ]]; then
  exit 1
fi

if [[ "\${FAKE_FAIL_PARENT_SWITCH:-0}" == "1" && "\$1" == "switch" && \
      "\${2:-}" == "v1.0.0" ]]; then
  exit 1
fi

# Optional one-shot rev-parse fault injection for post-merge verification tests.
if [[ "\$1" == "rev-parse" && "\$#" -eq 2 && -n "\${FAKE_REVPARSE_ONCE_REF:-}" && "\$2" == "\${FAKE_REVPARSE_ONCE_REF}" ]]; then
  marker="\${FAKE_REVPARSE_ONCE_MARKER:-}"
  if [[ -n "\$marker" && ! -f "\$marker" ]]; then
    mkdir -p "$(dirname "\$marker")" 2>/dev/null || true
    : > "\$marker"
    echo "0000000000000000000000000000000000000001"
    exit 0
  fi
fi

# Optional failure injection for merge conflict/error guidance coverage.
if [[ "\${FAKE_GIT_FAIL_MERGE_SQUASH:-0}" == "1" && "\$1" == "merge" && "\$2" == "--squash" ]]; then
  echo "simulated merge failure" >&2
  exit 1
fi

if [[ "\${FAKE_GIT_FAIL_COMMIT:-0}" == "1" && "\$1" == "commit" ]]; then
  echo "simulated commit failure" >&2
  exit 1
fi

if [[ "\${FAKE_GIT_FAIL_HISTORY_ADD:-0}" == "1" && "\$1" == "add" && \
      "\${2:-}" == logs/*_history.md ]]; then
  echo "simulated history staging failure" >&2
  exit 1
fi

exec "$REAL_GIT" "\$@"
GITEOF
chmod +x "$FAKEBIN/git"

REAL_TIMEOUT="$(command -v timeout)"
cat > "$FAKEBIN/timeout" << TIMEOUTEOF
#!/usr/bin/env bash
if [[ "\${FAKE_REMOTE_TIMEOUT:-0}" == "1" ]]; then
  exit 124
fi
exec "$REAL_TIMEOUT" "\$@"
TIMEOUTEOF
chmod +x "$FAKEBIN/timeout"

# ---------------------------------------------------------------------------
# Fake gh: dispatches on arg patterns; controlled by FAKE_GH_* env vars.
#   FAKE_GH_LOGIN           — identity returned for 'gh api user'
#   FAKE_GH_PR_NUMBER       — empty = no open PR; set = PR number
#   FAKE_GH_REVIEW_DECISION — APPROVED | CHANGES_REQUESTED | ...
#   FAKE_GH_STATUS_CHECKS   — SUCCESS | FAILURE | PENDING
#   FAKE_GH_PR_TITLE        — commit message when PR title is used
#   FAKE_GH_PR_STATE         — OPEN | CLOSED | MERGED
#   FAKE_GH_PR_DRAFT         — true | false
#   FAKE_GH_PR_HEAD          — expected PR head branch
#   FAKE_GH_PR_HEAD_OID      — expected PR head commit
#   FAKE_GH_APPROVED_COMMIT  — commit covered by the approving review
#   FAKE_GH_PR_BASE          — expected PR base branch
#   FAKE_GH_PR_MERGED_AT     — non-empty indicates merged
# ---------------------------------------------------------------------------
cat > "$FAKEBIN/gh" << 'GHEOF'
#!/usr/bin/env bash
args="$*"
if [[ -n "${FAKE_GH_FAIL_QUERY:-}" && "$args" == *"$FAKE_GH_FAIL_QUERY"* ]]; then
  exit 1
fi
# Identity lookup
if [[ "$args" == *"api user"* ]]; then
  if [[ "${FAKE_GH_IDENTITY_FAIL:-0}" == "1" ]]; then
    echo '{"message":"Service unavailable"}'
    exit 1
  fi
  echo "${FAKE_GH_LOGIN:-testowner}"
  exit 0
fi
# PR list (bt_gh_find_pr_number_for_branch)
if [[ "$args" == *"pr list"* ]]; then
  echo "${FAKE_GH_PR_NUMBER:-}"
  exit 0
fi
# PR metadata validation (validate_pr_for_merge)
if [[ "$args" == *"state,isDraft,headRefName,headRefOid,baseRefName,reviewDecision,mergedAt"* ]]; then
  head_oid="${FAKE_GH_PR_HEAD_OID:-$(git rev-parse dev/feat-v1.0.0 2>/dev/null || true)}"
  echo -e "${FAKE_GH_PR_STATE:-OPEN}\t${FAKE_GH_PR_DRAFT:-false}\t${FAKE_GH_PR_HEAD:-dev/feat-v1.0.0}\t${FAKE_GH_PR_BASE:-v1.0.0}\t${head_oid}\t${FAKE_GH_REVIEW_DECISION:-APPROVED}\t${FAKE_GH_PR_MERGED_AT:-}"
  exit 0
fi
# Commit-pinned approving review.
if [[ "$args" == *"pulls/"*"/reviews"* ]]; then
  head_oid="${FAKE_GH_PR_HEAD_OID:-$(git rev-parse dev/feat-v1.0.0 2>/dev/null || true)}"
  approved_commit="${FAKE_GH_APPROVED_COMMIT:-$head_oid}"
  if [[ "$args" == *"$approved_commit"* && \
    "${FAKE_GH_REVIEW_DECISION:-APPROVED}" == "APPROVED" ]]; then
    echo 1001
  fi
  exit 0
fi
# PR metadata validation (no-op retry-close compatibility query)
if [[ "$args" == *"state,isDraft,headRefName,baseRefName,mergedAt"* ]]; then
  echo -e "${FAKE_GH_PR_STATE:-OPEN}\t${FAKE_GH_PR_DRAFT:-false}\t${FAKE_GH_PR_HEAD:-dev/feat-v1.0.0}\t${FAKE_GH_PR_BASE:-v1.0.0}\t${FAKE_GH_PR_MERGED_AT:-}"
  exit 0
fi
# PR review decision (legacy query compatibility)
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
# PR comment posting (post_report_comment_to_pr)
if [[ "$args" == *"pr comment"* ]]; then
  exit 0
fi
# PR closing (close_pr_after_success)
if [[ "$args" == *"pr close"* ]]; then
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

# Copy scripts so pushup sources helpers relative to its own SCRIPT_DIR.
mkdir -p "$WORK/briteRepo/bin" "$WORK/briteRepo/helpers" \
         "$WORK/config" "$WORK/reports" "$WORK/logs"
cp "$PUSHUP_SRC" "$WORK/briteRepo/helpers/pushup_parent.sh"
cp "$PUSH_SRC" "$WORK/briteRepo/bin/push"
chmod +x "$WORK/briteRepo/helpers/pushup_parent.sh" "$WORK/briteRepo/bin/push"
for helper in common.sh git_helpers.sh github_helpers.sh \
              validation_helpers.sh history_log.sh report_helpers.sh report_sync.sh rbac.sh \
              push_workflow.sh ckrole.sh common_utils.sh ckbranchname.sh; do
  [[ -f "$HELPERS_DIR/$helper" ]] && \
    cp "$HELPERS_DIR/$helper" "$WORK/briteRepo/helpers/$helper"
done

(
  cd "$WORK"
  "$REAL_GIT" config user.name "testowner"
  "$REAL_GIT" config user.email "testowner@example.com"

  # contributors.md: testowner is an approver
  cat > config/contributors.md << 'MDEOF'
## Contributors

- testowner, A, testowner@example.com
- otheruser, C, otheruser@example.com
MDEOF

  echo "# README" > README.md
  echo "# Repository History" > logs/repository_history.md
  "$REAL_GIT" add .
  "$REAL_GIT" commit -m "seed" >/dev/null 2>&1
  "$REAL_GIT" branch -M main
  "$REAL_GIT" push -u origin main >/dev/null 2>&1

  # v1.0.0 — parent protected version branch
  "$REAL_GIT" checkout -b v1.0.0 >/dev/null 2>&1
  cat > briteRepo/bin/push <<'LEGACYPUSHEOF'
#!/usr/bin/env bash
echo "Error: legacy parent push must not be executed" >&2
exit 3
LEGACYPUSHEOF
  chmod +x briteRepo/bin/push
  "$REAL_GIT" add briteRepo/bin/push
  "$REAL_GIT" commit --allow-empty -m "v1.0.0 base" >/dev/null 2>&1
  "$REAL_GIT" push -u origin v1.0.0 >/dev/null 2>&1

  # dev/feat-v1.0.0 — targeted branch; parent resolves to v1.0.0 by naming rule
  "$REAL_GIT" checkout -b dev/feat-v1.0.0 >/dev/null 2>&1
  cp "$PUSH_SRC" briteRepo/bin/push
  cp "$HELPERS_DIR/push_workflow.sh" briteRepo/helpers/push_workflow.sh
  chmod +x briteRepo/bin/push
  echo "feature work" > feature.txt
  "$REAL_GIT" add feature.txt briteRepo/bin/push briteRepo/helpers/push_workflow.sh
  "$REAL_GIT" commit -m "feature commit" >/dev/null 2>&1
  "$REAL_GIT" push -u origin dev/feat-v1.0.0 >/dev/null 2>&1
)

# 0) Skip mode should emit an error report and summary line.
rc=$(run_capture "$TMPDIR/skip-e.out" env PATH="$FAKEBIN:$PATH" GITHUB_ACTOR=testowner bash -lc "cd '$WORK' && bash ./briteRepo/helpers/pushup_parent.sh -e")
[[ "$rc" -eq 36 ]] || fail "pushup -e should exit 36 (got $rc)"
assert_contains "Error: Merge-up skipped due to -e option." "$TMPDIR/skip-e.out"
assert_contains "Guidance: Run without -e option." "$TMPDIR/skip-e.out"
assert_contains "See reports/pushup-e-" "$TMPDIR/skip-e.out"
skip_report="$(latest_report "$WORK")"
[[ -f "$skip_report" ]] || fail "expected pushup skip report"
assert_contains "**Error:** Merge-up skipped due to -e option." "$skip_report"
assert_contains "## Guidance" "$skip_report"
assert_contains "- Run without -e option." "$skip_report"
pass "skip mode"

# ---------------------------------------------------------------------------
# Helper: run pushup in $WORK with faked PATH and extra env args
# Usage: run_pushup <outfile> [ENV=val ...] -- [pushup-args ...]
# Returns exit code on stdout.
# ---------------------------------------------------------------------------
run_pushup() {
  local outfile="$1"; shift
  # Collect env assignments until '--'
  local -a envvars=()
  while [[ $# -gt 0 && "$1" != "--" ]]; do
    envvars+=("$1"); shift
  done
  [[ "${1:-}" == "--" ]] && shift
  local -a pushup_args=("$@")

  set +e
  (
    cd "$WORK"
    export PATH="$FAKEBIN:$PATH"
    env "${envvars[@]}" bash ./briteRepo/helpers/pushup_parent.sh "${pushup_args[@]}"
  ) >"$outfile" 2>&1
  local rc=$?
  set -e
  echo "$rc"
}

# ---------------------------------------------------------------------------
# Help output includes -o and owner-override text
# ---------------------------------------------------------------------------
rc=$(
  set +e; bash "$PUSHUP_SRC" -h >"$TMPDIR/help.out" 2>&1; echo $?
)
[[ "$rc" -eq 0 ]] || fail "pushup -h should exit 0"
assert_contains "Usage:" "$TMPDIR/help.out"
assert_contains "-o" "$TMPDIR/help.out"
assert_contains "-t SEC" "$TMPDIR/help.out"
assert_contains "Repository-owner override" "$TMPDIR/help.out"
assert_contains "Bypasses the approver and required-PR checks" "$TMPDIR/help.out"
assert_contains "After pushup, the source and parent histories normally diverge" \
  "$TMPDIR/help.out"
assert_contains "run pulldown only" "$TMPDIR/help.out"
assert_contains "after the parent has been pushed" "$TMPDIR/help.out"
assert_contains "the PR must be approved for the current commit" \
  "$TMPDIR/help.out"
assert_contains "An approved contributor can run pushup" "$TMPDIR/help.out"
assert_contains "If another user pushes the parent first" "$TMPDIR/help.out"
duplicate_exit_codes="$(
  awk '
    /^Exit codes:$/ { in_exit_table=1; next }
    in_exit_table && /^[[:space:]]+[0-9]+/ {
      if (seen[$1]++) print $1
    }
  ' "$TMPDIR/help.out"
)"
[[ -z "$duplicate_exit_codes" ]] || \
  fail "help output contains duplicate exit codes: $duplicate_exit_codes"
pass "help output includes -o"

copyfix_state_root="$($REAL_GIT -C "$WORK" rev-parse \
  --path-format=absolute --git-common-dir)/briteRepo-copyfix-state"
mkdir -p "$copyfix_state_root/dev/feat-v1.0.0"
rc=$(run_pushup "$TMPDIR/copyfix-active.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" -- -d)
[[ "$rc" -eq 38 ]] || fail "unfinished copyfix should block pushup (got $rc)"
assert_contains "has an unfinished copyfix operation" \
  "$TMPDIR/copyfix-active.out"
rm -rf "$copyfix_state_root"
pass "unfinished copyfix blocks pushup"

# ---------------------------------------------------------------------------
# Invalid timeout is rejected before remote operations
# ---------------------------------------------------------------------------
rc=$(run_pushup "$TMPDIR/invalid-timeout.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" -- -t 0 -d)
[[ "$rc" -eq 1 ]] || fail "invalid -t should exit 1 (got $rc)"
assert_contains "Invalid -t value" "$TMPDIR/invalid-timeout.out"
pass "invalid timeout is rejected"

# ---------------------------------------------------------------------------
# Remote failures distinguish unconfigured, unreachable, and timeout states
# ---------------------------------------------------------------------------
rc=$(run_pushup "$TMPDIR/remote-unconfigured.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_REMOTE_UNCONFIGURED=1" -- -d)
[[ "$rc" -eq 18 ]] || fail "unconfigured remote should exit 18 (got $rc)"
assert_contains "is not configured" "$TMPDIR/remote-unconfigured.out"

rc=$(run_pushup "$TMPDIR/remote-unreachable.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_REMOTE_UNREACHABLE=1" -- -d)
[[ "$rc" -eq 19 ]] || fail "unreachable remote should exit 19 (got $rc)"
assert_contains "is not reachable" "$TMPDIR/remote-unreachable.out"

rc=$(run_pushup "$TMPDIR/remote-timeout.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_REMOTE_TIMEOUT=1" -- -t 7 -d)
[[ "$rc" -eq 20 ]] || fail "remote timeout should exit 20 (got $rc)"
assert_contains "timed out after 7s" "$TMPDIR/remote-timeout.out"
pass "remote connection failures return distinct exits 18-20"

# ---------------------------------------------------------------------------
# A whitespace-only explicit comment returns the documented exit
# ---------------------------------------------------------------------------
rc=$(run_pushup "$TMPDIR/empty-comment.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" -- -c "   ")
[[ "$rc" -eq 2 ]] || fail "empty commit comment should exit 2 (got $rc)"
assert_contains "empty after normalization" "$TMPDIR/empty-comment.out"
pass "whitespace-only commit comment returns exit 2"

# ---------------------------------------------------------------------------
# A targeted-branch merge rejects users without a repository role.
# ---------------------------------------------------------------------------
rc=$(run_pushup "$TMPDIR/noncontributor.out" \
  "GITHUB_ACTOR=outsider" "FAKE_REPO_OWNER=testowner" -- -d)
[[ "$rc" -eq 10 ]] || fail "non-approver should exit 10 (got $rc)"
assert_contains "is not a contributor" "$TMPDIR/noncontributor.out"
pass "targeted-branch merge rejects an unauthorized user"

# ---------------------------------------------------------------------------
# -o rejects a non-owner without applying the contributor gate
# ---------------------------------------------------------------------------
rc=$(run_pushup "$TMPDIR/nonowner.out" \
  "GITHUB_ACTOR=outsider" "FAKE_REPO_OWNER=testowner" -- -o -d)
[[ "$rc" -eq 7 ]] || fail "-o by non-owner should exit 7 (got $rc)"
assert_contains "allowed only for the repository owner" "$TMPDIR/nonowner.out"
pass "-o rejected for non-owner"

# ---------------------------------------------------------------------------
# A source branch with the same tree as its parent has nothing to merge and
# must not create a success, dry-run, or error report.
# ---------------------------------------------------------------------------
(
  cd "$WORK"
  "$REAL_GIT" checkout v1.0.0 >/dev/null 2>&1
  "$REAL_GIT" checkout -b dev/noop-v1.0.0 >/dev/null 2>&1
  "$REAL_GIT" commit --allow-empty -m "no-op source branch" >/dev/null 2>&1
  "$REAL_GIT" push -u origin dev/noop-v1.0.0 >/dev/null 2>&1
)
cat > "$WORK/reports/pushup-d-20000101-000000+0000.md" <<'EOF'
# Stale Merge-Up Report

**Source Branch:** dev/noop-v1.0.0
EOF
cat > "$WORK/reports/pushup-e-20000101-000001+0000.md" <<'EOF'
# Stale Merge-Up Error Report

**Source Branch:** dev/noop-v1.0.0
EOF
chmod a-w "$WORK/reports/pushup-d-20000101-000000+0000.md" \
  "$WORK/reports/pushup-e-20000101-000001+0000.md"
rc=$(run_pushup "$TMPDIR/noop.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=" -- -o -d)
[[ "$rc" -eq 37 ]] || fail "no-work pushup should exit 37 (got $rc)"
assert_contains "no changes to merge" "$TMPDIR/noop.out"
[[ -e "$WORK/reports/pushup-d-20000101-000000+0000.md" ]] || \
  fail "pushup prerequisite failure should preserve stale dry-run report"
[[ -e "$WORK/reports/pushup-e-20000101-000001+0000.md" ]] || \
  fail "pushup prerequisite failure should preserve stale error report"
(
  cd "$WORK"
  "$REAL_GIT" checkout dev/feat-v1.0.0 >/dev/null 2>&1
)
pass "no-work pushup prerequisite"

# ---------------------------------------------------------------------------
# -o accepts a repository owner who is not a contributor
# ---------------------------------------------------------------------------
rc=$(run_pushup "$TMPDIR/owner-noncontributor.out" \
  "GITHUB_ACTOR=outsider" "FAKE_REPO_OWNER=outsider" \
  "FAKE_GH_PR_NUMBER=" -- -o -d)
[[ "$rc" -eq 0 ]] || fail "-o by non-contributor owner should succeed (got $rc)"
assert_not_contains "Dry run complete" "$TMPDIR/owner-noncontributor.out"
assert_not_contains "is not a contributor" "$TMPDIR/owner-noncontributor.out"
pass "-o accepts a non-contributor repository owner"

# ---------------------------------------------------------------------------
# Branch-policy and authorization failures use the documented exits
# ---------------------------------------------------------------------------
(
  cd "$WORK"
  "$REAL_GIT" switch main >/dev/null 2>&1
)
rc=$(run_pushup "$TMPDIR/main-current.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" -- -d)
[[ "$rc" -eq 3 ]] || fail "main as current branch should exit 3 (got $rc)"
assert_contains "is not a contributor, targeted, or version branch" \
  "$TMPDIR/main-current.out"

(
  cd "$WORK"
  "$REAL_GIT" switch v1.0.0 >/dev/null 2>&1
  "$REAL_GIT" switch -c invalid-parent-shape >/dev/null 2>&1
  echo "invalid parent shape" > invalid-parent-shape.txt
  "$REAL_GIT" add invalid-parent-shape.txt
  "$REAL_GIT" commit -m "invalid contributor parent fixture" >/dev/null 2>&1
)
rc=$(run_pushup "$TMPDIR/contributor-version-parent.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" -- -d)
[[ "$rc" -eq 4 ]] || \
  fail "contributor branch with version parent should exit 4 (got $rc)"
assert_contains "requires a contributor or targeted parent branch" \
  "$TMPDIR/contributor-version-parent.out"

(
  cd "$WORK"
  "$REAL_GIT" switch v1.0.0 >/dev/null 2>&1
  "$REAL_GIT" branch -D invalid-parent-shape >/dev/null 2>&1
)
rc=$(run_pushup "$TMPDIR/owner-version-branch.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" -- -o -d)
[[ "$rc" -eq 8 ]] || fail "-o from a version branch should exit 8 (got $rc)"
assert_contains "requires the current branch to be a targeted branch" \
  "$TMPDIR/owner-version-branch.out"

(
  cd "$WORK"
  "$REAL_GIT" switch dev/feat-v1.0.0 >/dev/null 2>&1
)
# An approved contributor may merge their targeted branch to its version parent.
rc=$(run_pushup "$TMPDIR/contributor-approved.out" \
  "GITHUB_ACTOR=otheruser" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=42" "FAKE_GH_REVIEW_DECISION=APPROVED" -- -d)
[[ "$rc" -eq 0 ]] || \
  fail "approved contributor targeted merge should succeed (got $rc)"
assert_contains "Dry-run: merge to local v1.0.0:" \
  "$TMPDIR/contributor-approved.out"

(
  cd "$WORK"
  "$REAL_GIT" update-ref -d refs/remotes/origin/v1.0.0
)
rc=$(run_pushup "$TMPDIR/protected-remote-missing.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" -- -o -d)
[[ "$rc" -eq 17 ]] || fail "missing protected parent remote should exit 17 (got $rc)"
assert_contains "must have a corresponding remote branch" \
  "$TMPDIR/protected-remote-missing.out"
(
  cd "$WORK"
  "$REAL_GIT" fetch origin v1.0.0:refs/remotes/origin/v1.0.0 >/dev/null 2>&1
)
pass "branch-policy and authorization failures use documented exits"

# ---------------------------------------------------------------------------
# An unresolved GitHub identity returns the dedicated infrastructure exit
# ---------------------------------------------------------------------------
rc=$(run_pushup "$TMPDIR/identity-failed.out" \
  "GITHUB_ACTOR=-" "FAKE_REPO_OWNER=testowner" -- -d)
[[ "$rc" -eq 200 ]] || fail "unresolved GitHub identity should exit 200 (got $rc)"
assert_contains "Unable to determine GitHub login identity" "$TMPDIR/identity-failed.out"
pass "unresolved GitHub identity returns exit 200"

# ---------------------------------------------------------------------------
# A failed GitHub identity query must fall back to the configured Git login,
# even when the failed query emits an error response on stdout.
# ---------------------------------------------------------------------------
rc=$(run_pushup "$TMPDIR/identity-fallback.out" \
  "GITHUB_ACTOR=" "FAKE_GH_IDENTITY_FAIL=1" \
  "FAKE_REPO_OWNER=testowner" "FAKE_GH_PR_NUMBER=" -- -o -d)
[[ "$rc" -eq 0 ]] || \
  fail "failed GitHub identity query should use Git login fallback (got $rc)"
assert_contains "Dry-run: merge to local v1.0.0:" \
  "$TMPDIR/identity-fallback.out"
assert_not_contains "Unable to determine GitHub login identity" \
  "$TMPDIR/identity-fallback.out"
pass "failed GitHub identity query uses Git login fallback"

# ---------------------------------------------------------------------------
# -o by owner, no open PR uses the owner default message
# ---------------------------------------------------------------------------
rc=$(run_pushup "$TMPDIR/owner-nopr.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=" -- -o -d)
[[ "$rc" -eq 0 ]] || {
  echo "--- output ---"; cat "$TMPDIR/owner-nopr.out"
  fail "-o owner, no PR: dry-run should exit 0 (got $rc)"
}
assert_not_contains "0 modified, 0 added, and 0 deleted files would be merged." "$TMPDIR/owner-nopr.out"
assert_contains "Dry-run: merge to local v1.0.0:" "$TMPDIR/owner-nopr.out"
assert_contains "See reports/pushup-d-" "$TMPDIR/owner-nopr.out"
assert_not_contains "See reports/push-d-" "$TMPDIR/owner-nopr.out"
assert_not_contains "in remote for details" "$TMPDIR/owner-nopr.out"
assert_not_contains "Dry run complete" "$TMPDIR/owner-nopr.out"
assert_not_contains "no merge commit was created and no branch was pushed" "$TMPDIR/owner-nopr.out"
report_line_number="$(grep -n "See .*pushup-d-.* for details\." "$TMPDIR/owner-nopr.out" | head -n 1 | cut -d: -f1)"
merge_line_number="$(grep -n "Dry-run: merge to local v1.0.0:" "$TMPDIR/owner-nopr.out" | head -n 1 | cut -d: -f1)"
[[ -n "$report_line_number" ]] || fail "expected report line in dry-run output"
[[ -n "$merge_line_number" ]] || fail "expected merge summary line in dry-run output"
[[ "$report_line_number" -gt "$merge_line_number" ]] || fail "expected report line after the merge summary"
assert_not_contains "PR is not required" "$TMPDIR/owner-nopr.out"
assert_not_contains "Using custom message:" "$TMPDIR/owner-nopr.out"
assert_not_contains "is not approved" "$TMPDIR/owner-nopr.out"
owner_report="$WORK/reports/$(cd "$WORK/reports" && ls -1t pushup-d-*.md | head -n 1)"
assert_contains "**Commit Comment:** dev/feat-v1.0.0 merged to v1.0.0 by owner testowner." "$owner_report"
pass "-o owner, no PR: owner default message is reported"

# ---------------------------------------------------------------------------
# pushup does not invoke the shared push workflow
# ---------------------------------------------------------------------------
rc=$(run_pushup "$TMPDIR/parent-push-guidance.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_PUSH_REMOTE_BRANCH_MISSING=1" "FAKE_GH_PR_NUMBER=" -- -o -d)
[[ "$rc" -eq 0 ]] || fail "pushup dry-run should ignore push failures (got $rc)"
assert_not_contains "Parent branch push workflow failed" \
  "$TMPDIR/parent-push-guidance.out"
pass "pushup does not invoke push workflow"

# ---------------------------------------------------------------------------
# -o by owner with an unapproved PR fails
# ---------------------------------------------------------------------------
rc=$(run_pushup "$TMPDIR/owner-pr-unapproved.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=42" "FAKE_GH_REVIEW_DECISION=CHANGES_REQUESTED" -- -o -d)
[[ "$rc" -ne 0 ]] || fail "-o owner with unapproved PR should fail (got exit 0)"
assert_contains "outstanding changes requested" "$TMPDIR/owner-pr-unapproved.out"
assert_contains "Guidance: fix PR state/approval" "$TMPDIR/owner-pr-unapproved.out"
pass "-o owner, PR not approved: merge correctly blocked"

# ---------------------------------------------------------------------------
# -o by owner with an approved PR succeeds in dry-run
# ---------------------------------------------------------------------------
rc=$(run_pushup "$TMPDIR/owner-pr-approved.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=42" "FAKE_GH_REVIEW_DECISION=APPROVED" \
  "FAKE_GH_STATUS_CHECKS=SUCCESS" "FAKE_GH_PR_TITLE=My approved PR" -- -o -d)
[[ "$rc" -eq 0 ]] || {
  echo "--- output ---"; cat "$TMPDIR/owner-pr-approved.out"
  fail "-o owner, approved PR: dry-run should exit 0 (got $rc)"
}
assert_not_contains "0 modified, 0 added, and 0 deleted files would be merged." "$TMPDIR/owner-pr-approved.out"
assert_contains "Dry-run: merge to local v1.0.0:" "$TMPDIR/owner-pr-approved.out"
assert_not_contains "Dry-run: push to remote v1.0.0:" "$TMPDIR/owner-pr-approved.out"
assert_not_contains "Dry run complete" "$TMPDIR/owner-pr-approved.out"
assert_not_contains "is approved" "$TMPDIR/owner-pr-approved.out"
assert_not_contains "My approved PR" "$TMPDIR/owner-pr-approved.out"
pass "-o owner, approved PR: dry-run succeeds with compact output"

# New source commits require the PR head and approval to match that commit.
rc=$(run_pushup "$TMPDIR/pr-head-commit-mismatch.out" \
  "GITHUB_ACTOR=otheruser" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=42" \
  "FAKE_GH_PR_HEAD_OID=0000000000000000000000000000000000000001" -- -d)
[[ "$rc" -eq 39 ]] || fail "changed PR head should exit 39 (got $rc)"
assert_contains "head commit does not match current branch" \
  "$TMPDIR/pr-head-commit-mismatch.out"

rc=$(run_pushup "$TMPDIR/pr-stale-approval.out" \
  "GITHUB_ACTOR=otheruser" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=42" "FAKE_GH_REVIEW_DECISION=APPROVED" \
  "FAKE_GH_APPROVED_COMMIT=0000000000000000000000000000000000000001" -- -d)
[[ "$rc" -eq 33 ]] || fail "stale PR approval should exit 33 (got $rc)"
assert_contains "not approved for its current commit" \
  "$TMPDIR/pr-stale-approval.out"
pass "new commits require renewed PR approval"

# ---------------------------------------------------------------------------
# Normal path with an unapproved required PR fails
# ---------------------------------------------------------------------------
rc=$(run_pushup "$TMPDIR/normal-pr-unapproved.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=42" "FAKE_GH_REVIEW_DECISION=CHANGES_REQUESTED" -- -d)
[[ "$rc" -ne 0 ]] || fail "normal path with unapproved PR should fail (got exit 0)"
assert_contains "outstanding changes requested" "$TMPDIR/normal-pr-unapproved.out"
pass "normal path, PR required but not approved: merge correctly blocked"

# ---------------------------------------------------------------------------
# Every documented PR metadata failure has a dedicated exit
# ---------------------------------------------------------------------------
pr_exits=(28 29 30 31 32 33 34)
pr_states=(CLOSED OPEN OPEN OPEN OPEN OPEN MERGED)
pr_drafts=(false true false false false false false)
pr_heads=(dev/feat-v1.0.0 dev/feat-v1.0.0 wrong/head dev/feat-v1.0.0 dev/feat-v1.0.0 dev/feat-v1.0.0 dev/feat-v1.0.0)
pr_bases=(v1.0.0 v1.0.0 v1.0.0 wrong/base v1.0.0 v1.0.0 v1.0.0)
pr_reviews=(APPROVED APPROVED APPROVED APPROVED CHANGES_REQUESTED REVIEW_REQUIRED APPROVED)
pr_merged_at=("" "" "" "" "" "" "2026-07-31T00:00:00Z")
pr_messages=("not open" "is a draft" "head is not current" "base is not parent" "outstanding changes requested" "is not approved" "already merged")

for i in "${!pr_exits[@]}"; do
  rc=$(run_pushup "$TMPDIR/pr-${pr_exits[$i]}.out" \
    "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
    "FAKE_GH_PR_NUMBER=42" "FAKE_GH_PR_STATE=${pr_states[$i]}" \
    "FAKE_GH_PR_DRAFT=${pr_drafts[$i]}" "FAKE_GH_PR_HEAD=${pr_heads[$i]}" \
    "FAKE_GH_PR_BASE=${pr_bases[$i]}" "FAKE_GH_REVIEW_DECISION=${pr_reviews[$i]}" \
    "FAKE_GH_PR_MERGED_AT=${pr_merged_at[$i]}" -- -d)
  [[ "$rc" -eq "${pr_exits[$i]}" ]] || \
    fail "PR validation should exit ${pr_exits[$i]} (got $rc)"
  assert_contains "${pr_messages[$i]}" "$TMPDIR/pr-${pr_exits[$i]}.out"
done
pass "PR metadata failures return distinct exits 28-34"

# ---------------------------------------------------------------------------
# Required PR absence and required PR query failure are distinct
# ---------------------------------------------------------------------------
rc=$(run_pushup "$TMPDIR/pr-missing.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=" -- -d)
[[ "$rc" -eq 27 ]] || fail "missing required PR should exit 27 (got $rc)"
assert_contains "does not have an approved pull request" "$TMPDIR/pr-missing.out"
guidance_lines="$(grep -c '^Guidance:' "$TMPDIR/pr-missing.out" || true)"
[[ "$guidance_lines" -eq 1 ]] || fail "expected exactly one guidance line in missing-PR output (got $guidance_lines)"
assert_contains "Guidance: create or approve a pull request for this branch and rerun pushup." "$TMPDIR/pr-missing.out"
assert_not_contains "fix PR state/approval" "$TMPDIR/pr-missing.out"

rc=$(run_pushup "$TMPDIR/pr-query-failed.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_FAIL_QUERY=pr list" -- -d)
[[ "$rc" -eq 201 ]] || fail "failed PR query should exit 201 (got $rc)"
assert_contains "Failed to query pull requests" "$TMPDIR/pr-query-failed.out"
pass "missing PR and failed PR query return distinct exits"

# ---------------------------------------------------------------------------
# Unavailable CI/CD results do not block the merge preview
# ---------------------------------------------------------------------------
rc=$(run_pushup "$TMPDIR/github-query-failed.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=42" "FAKE_GH_REVIEW_DECISION=APPROVED" \
  "FAKE_GH_FAIL_QUERY=statusCheckRollup" -- -d)
[[ "$rc" -eq 0 ]] || fail "unavailable CI/CD results should not block preview (got $rc)"
query_report="$(cd "$WORK/reports" && ls -1t pushup-d-*.md | head -n 1)"
assert_contains "CI/CD results were unavailable for PR #42." \
  "$WORK/reports/$query_report"
pass "unavailable CI/CD results are report-only"

# ---------------------------------------------------------------------------
# CI/CD failures and pending checks are included in reports without blocking
# ---------------------------------------------------------------------------
ci_cd_checks=(
  $'ci build\tFAILURE'
  $'cd deploy\tFAILURE'
  $'ci build\tPENDING\ncd deploy\tFAILURE'
)

for i in "${!ci_cd_checks[@]}"; do
  rc=$(run_pushup "$TMPDIR/ci-cd-report-$i.out" \
    "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
    "FAKE_GH_PR_NUMBER=42" "FAKE_GH_REVIEW_DECISION=APPROVED" \
    "FAKE_GH_STATUS_CHECKS=${ci_cd_checks[$i]}" -- -d)
  [[ "$rc" -eq 0 ]] || fail "CI/CD results should not block preview (got $rc)"
  ci_cd_dry_report="$(cd "$WORK/reports" && ls -1t pushup-d-*.md | head -n 1)"
  assert_contains "| Check | State |" "$WORK/reports/$ci_cd_dry_report"
  assert_contains "FAILURE" "$WORK/reports/$ci_cd_dry_report"
done
pass "CI/CD results are included without blocking"

# ---------------------------------------------------------------------------
# Normal approved PR uses its title as the commit comment
# ---------------------------------------------------------------------------
rc=$(run_pushup "$TMPDIR/normal-pr-approved.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=42" "FAKE_GH_REVIEW_DECISION=APPROVED" \
  "FAKE_GH_STATUS_CHECKS=SUCCESS" "FAKE_GH_PR_TITLE=Approved release title" -- -d)
[[ "$rc" -eq 0 ]] || fail "normal approved PR dry-run should succeed (got $rc)"
pr_report="$WORK/reports/$(cd "$WORK/reports" && ls -1t pushup-d-*.md | head -n 1)"
assert_contains "**Commit Comment:** Approved release title" "$pr_report"
assert_contains "| unlabeled | SUCCESS |" "$pr_report"
pass "approved PR title is used as the commit comment"

# ---------------------------------------------------------------------------
# Non-verbose dry-run remains compact
# ---------------------------------------------------------------------------
rc=$(run_pushup "$TMPDIR/quiet-dryrun.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=" -- -o -d -c "Quiet dry-run")
[[ "$rc" -eq 0 ]] || fail "non-verbose dry-run should succeed (got $rc)"
assert_not_contains "Current branch:" "$TMPDIR/quiet-dryrun.out"
assert_not_contains "Determining parent branch" "$TMPDIR/quiet-dryrun.out"
assert_not_contains "Parent branch:" "$TMPDIR/quiet-dryrun.out"
assert_not_contains "0 modified, 0 added, and 0 deleted files would be merged." "$TMPDIR/quiet-dryrun.out"
assert_contains "Dry-run: merge to local v1.0.0:" "$TMPDIR/quiet-dryrun.out"
assert_not_contains "Dry-run: push to remote v1.0.0:" "$TMPDIR/quiet-dryrun.out"
pass "non-verbose dry-run output stays compact"

# ---------------------------------------------------------------------------
# Verbose mode identifies the required local current branch
# ---------------------------------------------------------------------------
rc=$(run_pushup "$TMPDIR/verbose-dryrun.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=" -- -o -d -v -c "Verbose dry-run")
[[ "$rc" -eq 0 ]] || fail "verbose dry-run should succeed (got $rc)"
assert_contains "Current local branch dev/feat-v1.0.0." "$TMPDIR/verbose-dryrun.out"
pass "verbose mode reports the local current branch"

# ---------------------------------------------------------------------------
# Detached HEAD is rejected because no local branch is checked out
# ---------------------------------------------------------------------------
(
  cd "$WORK"
  "$REAL_GIT" switch --detach >/dev/null 2>&1
)
rc=$(run_pushup "$TMPDIR/current-detached.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" -- -d)
(
  cd "$WORK"
  "$REAL_GIT" switch dev/feat-v1.0.0 >/dev/null 2>&1
)
[[ "$rc" -eq 11 ]] || fail "detached current branch should exit 11 (got $rc)"
assert_contains "detached HEAD" "$TMPDIR/current-detached.out"
pass "detached current branch returns exit 11"

# ---------------------------------------------------------------------------
# Uncommitted current-branch changes return exit 12
# ---------------------------------------------------------------------------
echo "uncommitted" > "$WORK/uncommitted.txt"
rc=$(run_pushup "$TMPDIR/current-uncommitted.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" -- -o -d)
rm -f "$WORK/uncommitted.txt"
[[ "$rc" -eq 12 ]] || fail "uncommitted current branch should exit 12 (got $rc)"
assert_contains "Current branch has uncommitted changes" "$TMPDIR/current-uncommitted.out"
assert_contains "Guidance: commit or undo changes, then rerun pushup" "$TMPDIR/current-uncommitted.out"
assert_not_contains "discard local changes" "$TMPDIR/current-uncommitted.out"
pass "uncommitted current branch returns exit 12"

# ---------------------------------------------------------------------------
# Current and parent sync states have distinct exits
# ---------------------------------------------------------------------------
sync_refs=(
  "origin/dev/feat-v1.0.0...dev/feat-v1.0.0"
  "origin/dev/feat-v1.0.0...dev/feat-v1.0.0"
  "origin/dev/feat-v1.0.0...dev/feat-v1.0.0"
  "origin/v1.0.0...v1.0.0"
  "origin/v1.0.0...v1.0.0"
  "origin/v1.0.0...v1.0.0"
)
sync_counts=("1\\t0" "0\\t1" "1\\t1" "1\\t0" "0\\t1" "1\\t1")
sync_exits=(21 22 23 24 25 26)
sync_messages=("is behind" "is ahead" "has diverged" "is behind" "is ahead" "has diverged")

for i in "${!sync_exits[@]}"; do
  rc=$(run_pushup "$TMPDIR/sync-${sync_exits[$i]}.out" \
    "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
    "FAKE_SYNC_REF=${sync_refs[$i]}" "FAKE_SYNC_COUNTS=${sync_counts[$i]}" -- -o -d)
  [[ "$rc" -eq "${sync_exits[$i]}" ]] || \
    fail "sync state should exit ${sync_exits[$i]} (got $rc)"
  assert_contains "${sync_messages[$i]}" "$TMPDIR/sync-${sync_exits[$i]}.out"
done
pass "current and parent remote states return distinct exits 21-26"

# ---------------------------------------------------------------------------
# Missing local parent returns exit 14
# ---------------------------------------------------------------------------
(
  cd "$WORK"
  "$REAL_GIT" branch -D v1.0.0 >/dev/null 2>&1
)
rc=$(run_pushup "$TMPDIR/parent-missing.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" -- -o -d)
(
  cd "$WORK"
  "$REAL_GIT" branch v1.0.0 origin/v1.0.0 >/dev/null 2>&1
)
[[ "$rc" -eq 14 ]] || fail "missing local parent should exit 14 (got $rc)"
assert_contains "does not exist locally" "$TMPDIR/parent-missing.out"
pass "missing local parent returns exit 14"

# ---------------------------------------------------------------------------
# Parent checkout failure returns exit 15
# ---------------------------------------------------------------------------
rc=$(run_pushup "$TMPDIR/parent-checkout.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=" "FAKE_FAIL_PARENT_SWITCH=1" -- -o -c "checkout failure")
[[ "$rc" -eq 15 ]] || fail "parent checkout failure should exit 15 (got $rc)"
assert_contains "cannot be checked out" "$TMPDIR/parent-checkout.out"
checkout_error_report="$(cd "$WORK/reports" && ls -1t pushup-e-*.md | head -n 1)"
assert_contains "**Error:** Parent branch 'v1.0.0' cannot be checked out" \
  "$WORK/reports/$checkout_error_report"
pass "parent checkout failure returns exit 15 with actionable report"

# ---------------------------------------------------------------------------
# Current branch behind parent returns exit 13
# ---------------------------------------------------------------------------
rc=$(run_pushup "$TMPDIR/current-behind-parent.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_CURRENT_BEHIND_PARENT=1" -- -o -d)
[[ "$rc" -eq 13 ]] || fail "current behind parent should exit 13 (got $rc)"
assert_contains "not up-to-date with parent" "$TMPDIR/current-behind-parent.out"
pass "current branch behind parent returns exit 13"

# ---------------------------------------------------------------------------
# Local merge succeeds without remote post-merge repair
# ---------------------------------------------------------------------------
VERIFY_MARKER="$TMPDIR/revparse-once.marker"
rc=$(run_pushup "$TMPDIR/verify-repair.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=" \
  "FAKE_REVPARSE_ONCE_REF=origin/v1.0.0" \
  "FAKE_REVPARSE_ONCE_MARKER=$VERIFY_MARKER" -- -o -c "verify repair path")
[[ "$rc" -eq 0 ]] || {
  echo "--- output ---"; cat "$TMPDIR/verify-repair.out"
  fail "one-time verification mismatch should auto-repair and succeed (got $rc)"
}
merge_line_number="$(grep -n "Merged to local v1.0.0:" "$TMPDIR/verify-repair.out" | head -n 1 | cut -d: -f1)"
[[ -n "$merge_line_number" ]] || fail "expected merge success line in verify-repair output"
assert_contains "Merged to local v1.0.0:" "$TMPDIR/verify-repair.out"
assert_not_contains "Pushed (" "$TMPDIR/verify-repair.out"
assert_contains "Local merge complete on v1.0.0." \
  "$TMPDIR/verify-repair.out"
assert_contains "Run push when ready to publish v1.0.0 and finalize its PR." \
  "$TMPDIR/verify-repair.out"
[[ "$(git -C "$WORK" branch --show-current)" == "v1.0.0" ]] || \
  fail "successful pushup should leave the local parent checked out"
if find "$WORK/reports" -maxdepth 1 -type f \
  -name 'pushup-[0-9]*.md' -print -quit | grep -q .; then
  fail "successful merge-up should not create an immediate local report"
fi
merge_body="$(git -C "$WORK" log -1 --format=%B v1.0.0)"
if grep -Fq "Command-Line: pushup" <<< "$merge_body"; then
  fail "merge-up commit should not claim workflow success before finalization"
fi
merge_note="$(git -C "$WORK" notes --ref=briteRepo-workflow show v1.0.0)"
[[ "$merge_note" == *"Workflow-Type: pushup"* ]] || \
  fail "completed merge-up should record one final workflow event"
[[ "$merge_note" == *"Command-Line: pushup -o -c verify\\ repair\\ path"* ]] || \
  fail "merge-up event should record its command line"
[[ "$merge_note" == *"Source-Branch: dev/feat-v1.0.0"* ]] || \
  fail "merge-up event should record its source branch"
[[ "$merge_note" == *"Target-Branch: v1.0.0"* ]] || \
  fail "merge-up event should record its target branch"
[[ "$merge_note" == *"PR: none"* ]] || \
  fail "merge-up event should record that no PR was associated"
[[ "$merge_note" == *"Status: Current branch merged into parent branch"* ]] || \
  fail "merge-up event should record merge status"
[[ "$merge_note" == *"Method: Squash merge created by pushup"* ]] || \
  fail "merge-up event should record merge method"
[[ "$merge_note" == *"No associated PR; CI/CD checks were not queried."* ]] || \
  fail "merge-up event should record CI/CD availability"
remote_parent_tip="$(git -C "$ORIGIN" rev-parse refs/heads/v1.0.0)"
[[ "$remote_parent_tip" != "$(git -C "$WORK" rev-parse v1.0.0)" ]] || \
  fail "pushup should leave origin/v1.0.0 unchanged"
(
  cd "$WORK"
  "$REAL_GIT" switch dev/feat-v1.0.0 >/dev/null 2>&1
  "$REAL_GIT" branch -f v1.0.0 origin/v1.0.0 >/dev/null 2>&1
)
pass "pushup completes locally without remote repair"

# ---------------------------------------------------------------------------
# Local run lock blocks overlapping invocation
# ---------------------------------------------------------------------------
echo "$$" > "$WORK/.git/pushup.run.lock"
rc=$(run_pushup "$TMPDIR/lock-blocked.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=" -- -o -d -c "lock blocked")
rm -f "$WORK/.git/pushup.run.lock"
[[ "$rc" -ne 0 ]] || fail "expected pushup lock contention to fail (got exit 0)"
[[ "$rc" -eq 35 ]] || fail "pushup lock contention should exit 35 (got $rc)"
assert_contains "Another pushup run appears active" "$TMPDIR/lock-blocked.out"
assert_contains "Guidance:" "$TMPDIR/lock-blocked.out"
pass "local run lock blocks overlapping invocation"

# ---------------------------------------------------------------------------
# Merge-time git failure emits resolve-and-rerun guidance
# ---------------------------------------------------------------------------
(
  cd "$WORK"
  "$REAL_GIT" checkout dev/feat-v1.0.0 >/dev/null 2>&1
  echo "failure path merge content" > failure-path.txt
  "$REAL_GIT" add failure-path.txt
  "$REAL_GIT" commit -m "prepare merge failure paths" >/dev/null 2>&1
  "$REAL_GIT" push origin dev/feat-v1.0.0 >/dev/null 2>&1
)
rc=$(run_pushup "$TMPDIR/merge-fail-guidance.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=" "FAKE_GIT_FAIL_MERGE_SQUASH=1" -- -o -c "fail guidance")
[[ "$rc" -eq 202 ]] || fail "expected git-operation failure exit 202 (got $rc)"
assert_contains "Failed to squash merge" "$TMPDIR/merge-fail-guidance.out"
assert_contains "Guidance: if merge conflicts occurred" "$TMPDIR/merge-fail-guidance.out"
assert_contains "rerun pushup" "$TMPDIR/merge-fail-guidance.out"
pass "merge-time git failure emits resolve-and-rerun guidance"

# ---------------------------------------------------------------------------
# Commit failure must not leave a success report claiming the merge completed
# ---------------------------------------------------------------------------
success_reports_before="$(find "$WORK/reports" -maxdepth 1 -type f \
  -name 'pushup-[0-9]*.md' | wc -l | tr -d ' ')"
rc=$(run_pushup "$TMPDIR/commit-fail-report.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=" "FAKE_GIT_FAIL_COMMIT=1" -- -o -c "commit failure")
success_reports_after="$(find "$WORK/reports" -maxdepth 1 -type f \
  -name 'pushup-[0-9]*.md' | wc -l | tr -d ' ')"
[[ "$rc" -eq 202 ]] || fail "commit failure should exit 202 (got $rc)"
[[ "$success_reports_after" -eq "$success_reports_before" ]] || \
  fail "commit failure must not create a success report"
assert_contains "Failed to create commit" "$TMPDIR/commit-fail-report.out"
remaining_dirty="$(
  (cd "$WORK" || exit 1; git status --porcelain --untracked-files=all) | \
    grep -Ev '^\?\? reports/(pushup|push)(-d|-e)?-[0-9]{8}-[0-9]{6}[+-][0-9]{4}(-[0-9]+)?\.md$' || true
)"
[[ -z "$remaining_dirty" ]] || fail "commit failure should restore a clean worktree"
pass "commit failure does not create a success report"

# ---------------------------------------------------------------------------
# History staging failure is fatal and must not produce a success report
# ---------------------------------------------------------------------------
success_reports_before="$(find "$WORK/reports" -maxdepth 1 -type f \
  -name 'pushup-[0-9]*.md' | wc -l | tr -d ' ')"
rc=$(run_pushup "$TMPDIR/history-add-fail.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=" "FAKE_GIT_FAIL_HISTORY_ADD=1" -- \
  -o -c "history staging failure")
success_reports_after="$(find "$WORK/reports" -maxdepth 1 -type f \
  -name 'pushup-[0-9]*.md' | wc -l | tr -d ' ')"
[[ "$rc" -eq 202 ]] || fail "history staging failure should exit 202 (got $rc)"
[[ "$success_reports_after" -eq "$success_reports_before" ]] || \
  fail "history staging failure must not create a success report"
assert_contains "Failed to stage parent history file" "$TMPDIR/history-add-fail.out"
pass "history staging failure is reported and creates no success report"

# ---------------------------------------------------------------------------
# Version-to-main merges use the documented approver default comment
# ---------------------------------------------------------------------------
(
  cd "$WORK"
  "$REAL_GIT" switch v1.0.0 >/dev/null 2>&1
)
rc=$(run_pushup "$TMPDIR/version-main-default.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=" -- -d)
[[ "$rc" -eq 0 ]] || fail "version-to-main preview should succeed (got $rc)"
version_report="$(cd "$WORK/reports" && ls -1t pushup-d-*.md | head -n 1)"
assert_contains \
  "**Commit Comment:** v1.0.0 merged to main branch by approver testowner." \
  "$WORK/reports/$version_report"
pass "version-to-main preview uses the documented default comment"

# ---------------------------------------------------------------------------
# Contributor merges require contributor membership and validate a PR if present
# ---------------------------------------------------------------------------
(
  cd "$WORK"
  "$REAL_GIT" switch dev/feat-v1.0.0 >/dev/null 2>&1
  "$REAL_GIT" switch -c contributor-work >/dev/null 2>&1
  echo "contributor work" > contributor-work.txt
  "$REAL_GIT" add contributor-work.txt
  "$REAL_GIT" commit -m "contributor merge fixture" >/dev/null 2>&1
)
contributor_tip="$($REAL_GIT -C "$WORK" rev-parse contributor-work)"

rc=$(run_pushup "$TMPDIR/contributor-no-pr.out" \
  "GITHUB_ACTOR=otheruser" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=" -- -d)
[[ "$rc" -eq 0 ]] || fail "contributor merge without PR should succeed (got $rc)"
contributor_report="$(cd "$WORK/reports" && ls -1t pushup-d-*.md | head -n 1)"
assert_contains \
  "**Commit Comment:** contributor-work merged to dev/feat-v1.0.0 by contributor otheruser." \
  "$WORK/reports/$contributor_report"

rc=$(run_pushup "$TMPDIR/contributor-outsider.out" \
  "GITHUB_ACTOR=outsider" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=" -- -d)
[[ "$rc" -eq 9 ]] || fail "contributor branch by outsider should exit 9 (got $rc)"
assert_contains "is not a contributor" "$TMPDIR/contributor-outsider.out"

rc=$(run_pushup "$TMPDIR/contributor-unapproved-pr.out" \
  "GITHUB_ACTOR=otheruser" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=42" "FAKE_GH_PR_HEAD=contributor-work" \
  "FAKE_GH_PR_HEAD_OID=$contributor_tip" \
  "FAKE_GH_PR_BASE=dev/feat-v1.0.0" \
  "FAKE_GH_REVIEW_DECISION=REVIEW_REQUIRED" -- -d)
[[ "$rc" -eq 33 ]] || \
  fail "contributor merge with unapproved PR should exit 33 (got $rc)"
assert_contains "is not approved" "$TMPDIR/contributor-unapproved-pr.out"

rc=$(run_pushup "$TMPDIR/contributor-approved-pr.out" \
  "GITHUB_ACTOR=otheruser" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=42" "FAKE_GH_PR_HEAD=contributor-work" \
  "FAKE_GH_PR_HEAD_OID=$contributor_tip" \
  "FAKE_GH_PR_BASE=dev/feat-v1.0.0" \
  "FAKE_GH_REVIEW_DECISION=APPROVED" -- -d)
[[ "$rc" -eq 0 ]] || \
  fail "contributor merge with approved PR should succeed (got $rc)"
pass "contributor merge validates approval only when a PR exists"

rc=$(run_pushup "$TMPDIR/contributor-failed-ci-merge.out" \
  "GITHUB_ACTOR=otheruser" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=42" "FAKE_GH_PR_HEAD=contributor-work" \
  "FAKE_GH_PR_HEAD_OID=$contributor_tip" \
  "FAKE_GH_PR_BASE=dev/feat-v1.0.0" \
  "FAKE_GH_REVIEW_DECISION=APPROVED" \
  "FAKE_GH_STATUS_CHECKS=ci build"$'\t'"FAILURE" --)
[[ "$rc" -eq 0 ]] || fail "failed CI result should not block merge (got $rc)"
  ci_merge_note="$(git -C "$WORK" notes --ref=briteRepo-workflow show \
  dev/feat-v1.0.0)"
[[ "$ci_merge_note" == *"ci build"* && "$ci_merge_note" == *"FAILURE"* ]] || \
  fail "merge-up event should record CI/CD results"
[[ "$ci_merge_note" == *"PR: 42"* ]] || \
  fail "merge-up event should record its PR number"
if ! grep -Fq "Command-Line: pushup" <<< "$ci_merge_note"; then
  fail "merge-up event should record its command line"
fi
pass "failed CI result is reported without blocking a real merge"

# ---------------------------------------------------------------------------
# Contributor branches cannot merge directly to main
# ---------------------------------------------------------------------------
(
  cd "$WORK"
  "$REAL_GIT" switch main >/dev/null 2>&1
  "$REAL_GIT" switch -c feature-main >/dev/null 2>&1
  echo "main-targeted contribution" > main-feature.txt
  "$REAL_GIT" add main-feature.txt
  "$REAL_GIT" commit -m "contributor branch for main" >/dev/null 2>&1
)
rc=$(run_pushup "$TMPDIR/contributor-main-rejected.out" \
  "GITHUB_ACTOR=testowner" "FAKE_REPO_OWNER=testowner" \
  "FAKE_GH_PR_NUMBER=" -- -d)
[[ "$rc" -eq 4 ]] || fail "contributor-to-main merge should exit 4 (got $rc)"
assert_contains "requires a contributor or targeted parent branch" \
  "$TMPDIR/contributor-main-rejected.out"
pass "contributor-to-main merge is rejected"

echo "All pushup owner-override and PR-approval smoke tests passed."
