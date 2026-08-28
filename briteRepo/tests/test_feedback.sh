#!/usr/bin/env bash

# test_feedback.sh - smoke tests for briteRepo/bin/feedback.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FEEDBACK_SRC="$REPO_ROOT/briteRepo/bin/feedback"

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
  if grep -Fq -- "$text" "$file"; then
    fail "did not expect '$text' in output (see $file)"
  fi
}

for dep in bash git grep mktemp; do
  command -v "$dep" >/dev/null 2>&1 || fail "missing required command: $dep"
done

[[ -f "$FEEDBACK_SRC" ]] || fail "missing script: $FEEDBACK_SRC"

TMPDIR="$(mktemp -d)"
cleanup() {
  chmod -R u+w "$TMPDIR" >/dev/null 2>&1 || true
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

ORIGIN="$TMPDIR/origin.git"
WORK="$TMPDIR/work"
FAKEBIN="$TMPDIR/fakebin"
mkdir -p "$FAKEBIN"

cat > "$FAKEBIN/gh" <<'GHEOF'
#!/usr/bin/env bash
log_file="${FAKE_GH_LOG:-}"
if [[ -n "$log_file" ]]; then
  printf '%s\n' "$*" >> "$log_file"
fi

case "$*" in
  *"pr list"*)
    if [[ "$*" == *"--base main"* ]]; then
      if [[ "${FAKE_APPROVED_QUERY_FAIL:-false}" == true ]]; then
        exit 1
      elif [[ "${FAKE_APPROVED_SIBLING:-false}" == true ]]; then
        printf '12\tdev/other-v1.0.0\n'
      fi
    elif [[ "$*" == *"--state closed"* ]]; then
      if [[ "${FAKE_GH_STATE:-open}" == "closed" ]]; then
        echo "7"
      else
        echo ""
      fi
    else
      if [[ "${FAKE_GH_STATE:-open}" == "open" ]]; then
        echo "7"
      else
        echo ""
      fi
    fi
    exit 0
    ;;
  *"pr view 7 --json baseRefName"*)
    echo "main"
    exit 0
    ;;
  *"pulls/7/comments"*)
    cat <<'EOF'
101	55	0	reviewer1	src/auth.sh	12	Root review comment.
102	55	101	reviewer1	src/auth.sh	12	Reply review comment.
EOF
    exit 0
    ;;
  *"reviewThreads"*)
    cat <<'EOF'
thread-abc	101	101,102
EOF
    exit 0
    ;;
  *"pulls/comments/101/replies"*)
    echo "replied"
    exit 0
    ;;
  *"pr view 7 --web"*)
    echo "opened"
    exit 0
    ;;
  *"resolveReviewThread"*)
    echo "resolved"
    exit 0
    ;;
  *"pr review 7 --approve"*)
    echo "approved"
    exit 0
    ;;
  *"pr review 7 --request-changes"*)
    echo "changes requested"
    exit 0
    ;;
  *)
    echo "unhandled gh args: $*" >&2
    exit 1
    ;;
esac
GHEOF
chmod +x "$FAKEBIN/gh"

git init --bare "$ORIGIN" >/dev/null 2>&1
git clone "$ORIGIN" "$WORK" >/dev/null 2>&1
mkdir -p "$WORK/briteRepo/bin" "$WORK/briteRepo/helpers" "$WORK/config"
cp "$FEEDBACK_SRC" "$WORK/briteRepo/bin/feedback"
for helper in common.sh git_helpers.sh github_helpers.sh history_log.sh ckrole.sh; do
  cp "$REPO_ROOT/briteRepo/helpers/$helper" "$WORK/briteRepo/helpers/$helper"
done
chmod +x "$WORK/briteRepo/bin/feedback"

(
  cd "$WORK"
  git config user.name "testuser"
  git config user.email "test@example.com"
  cat > config/contributors.md <<'EOF'
## Contributors

- reviewer1, R, reviewer1@example.com
- testapprover, A, approver@example.com
- testcontrib, C, contributor@example.com
EOF
  echo "seed" > README.md
  git add README.md config contributors >/dev/null 2>&1 || true
  git add README.md config >/dev/null 2>&1 || true
  git commit -m "seed" >/dev/null 2>&1
  git branch -M dev/review-v1.0.0
  git remote set-url origin "https://github.com/testowner/testrepo.git"
)

run_capture() {
  local outfile="$1"
  local gh_state="$2"
  shift
  shift
  set +e
  env PATH="$FAKEBIN:$PATH" FAKE_GH_LOG="$TMPDIR/gh.log" \
    FAKE_GH_STATE="$gh_state" "$@" >"$outfile" 2>&1
  local rc=$?
  set -e
  echo "$rc"
}

rc=$(run_capture "$TMPDIR/help.out" open bash -c "cd '$WORK' && bash ./briteRepo/bin/feedback -h")
[[ "$rc" -eq 0 ]] || fail "feedback -h should exit 0 (got $rc)"
assert_contains "-i ID" "$TMPDIR/help.out"
assert_contains "reply to a specific review comment" "$TMPDIR/help.out"
assert_contains "Mark a specific review thread" "$TMPDIR/help.out"
pass "help advertises review-thread support"

rc=$(run_capture "$TMPDIR/unauthorized.out" open env \
  GITHUB_ACTOR=outsider bash -c "cd '$WORK' && bash ./briteRepo/bin/feedback view")
[[ "$rc" -eq 4 ]] || fail "feedback by an unconfigured user should exit 4 (got $rc)"
assert_contains "not listed as contributor, reviewer, or approver" \
  "$TMPDIR/unauthorized.out"
pass "feedback requires contributor role"

git -C "$WORK" branch v1.0.0
git -C "$WORK" checkout v1.0.0 >/dev/null 2>&1
rc=$(run_capture "$TMPDIR/invalid-branch.out" open env \
  GITHUB_ACTOR=reviewer1 bash -c "cd '$WORK' && bash ./briteRepo/bin/feedback view")
[[ "$rc" -eq 2 ]] || fail "feedback on an invalid branch should exit 2 (got $rc)"
assert_contains "is not a contributor or targeted branch" \
  "$TMPDIR/invalid-branch.out"
git -C "$WORK" checkout dev/review-v1.0.0 >/dev/null 2>&1
pass "feedback requires a contributor or targeted branch"

rc=$(run_capture "$TMPDIR/view.out" open env GITHUB_ACTOR=reviewer1 bash -c "cd '$WORK' && bash ./briteRepo/bin/feedback view")
[[ "$rc" -eq 0 ]] || fail "feedback view should exit 0 (got $rc)"
assert_contains "[101] reviewer1 src/auth.sh:12" "$TMPDIR/view.out"
assert_contains "reply-to: 101" "$TMPDIR/view.out"
pass "review comments are listed with IDs"

rc=$(run_capture "$TMPDIR/view-browser.out" open env GITHUB_ACTOR=reviewer1 bash -c "cd '$WORK' && bash ./briteRepo/bin/feedback view -b")
[[ "$rc" -eq 0 ]] || fail "feedback view -b should exit 0 (got $rc)"
assert_contains "pr view 7 --web" "$TMPDIR/gh.log"
pass "browser option opens the PR page"

rc=$(run_capture "$TMPDIR/browser-only-open.out" open env GITHUB_ACTOR=reviewer1 bash -c "cd '$WORK' && bash ./briteRepo/bin/feedback -b")
[[ "$rc" -eq 0 ]] || fail "feedback -b should exit 0 when an open PR exists (got $rc)"
assert_contains "pr view 7 --web" "$TMPDIR/gh.log"
pass "browser-only mode opens open PR"

rc=$(run_capture "$TMPDIR/view-browser-closed.out" closed env GITHUB_ACTOR=reviewer1 bash -c "cd '$WORK' && bash ./briteRepo/bin/feedback view -b")
[[ "$rc" -eq 0 ]] || fail "feedback view -b should open latest closed PR when no open PR exists (got $rc)"
assert_contains "Opened latest closed PR #7" "$TMPDIR/view-browser-closed.out"
assert_contains "pr list --head dev/review-v1.0.0 --state closed" "$TMPDIR/gh.log"
assert_contains "pr view 7 --web" "$TMPDIR/gh.log"
pass "browser option falls back to latest closed PR"

rc=$(run_capture "$TMPDIR/browser-only-closed.out" closed env GITHUB_ACTOR=reviewer1 bash -c "cd '$WORK' && bash ./briteRepo/bin/feedback -b")
[[ "$rc" -eq 0 ]] || fail "feedback -b should fall back to latest closed PR when no open PR exists (got $rc)"
assert_contains "Opened latest closed PR #7" "$TMPDIR/browser-only-closed.out"
assert_contains "pr list --head dev/review-v1.0.0 --state closed" "$TMPDIR/gh.log"
assert_contains "pr view 7 --web" "$TMPDIR/gh.log"
pass "browser-only mode falls back to latest closed PR"

rc=$(run_capture "$TMPDIR/view-no-pr.out" none env GITHUB_ACTOR=reviewer1 bash -c "cd '$WORK' && bash ./briteRepo/bin/feedback view -b")
[[ "$rc" -eq 3 ]] || fail "feedback view -b with no open/closed PR should exit 3 (got $rc)"
assert_contains "No PR found for branch" "$TMPDIR/view-no-pr.out"
pass "browser option reports when no PR exists"

rc=$(run_capture "$TMPDIR/browser-only-no-pr.out" none env GITHUB_ACTOR=reviewer1 bash -c "cd '$WORK' && bash ./briteRepo/bin/feedback -b")
[[ "$rc" -eq 3 ]] || fail "feedback -b with no open/closed PR should exit 3 (got $rc)"
assert_contains "No PR found for branch" "$TMPDIR/browser-only-no-pr.out"
pass "browser-only mode reports when no PR exists"

rc=$(run_capture "$TMPDIR/update-unsupported.out" open env GITHUB_ACTOR=reviewer1 bash -c "cd '$WORK' && bash ./briteRepo/bin/feedback update -c 'nope'")
[[ "$rc" -eq 1 ]] || fail "feedback update should be unsupported (got $rc)"
assert_contains "Unknown action: update" "$TMPDIR/update-unsupported.out"
pass "update action is rejected"

rc=$(run_capture "$TMPDIR/sync-unsupported.out" open env GITHUB_ACTOR=reviewer1 bash -c "cd '$WORK' && bash ./briteRepo/bin/feedback sync")
[[ "$rc" -eq 1 ]] || fail "feedback sync should be unsupported (got $rc)"
assert_contains "Unknown action: sync" "$TMPDIR/sync-unsupported.out"
pass "sync action is rejected"

rc=$(run_capture "$TMPDIR/respond.out" open env GITHUB_ACTOR=reviewer1 bash -c "cd '$WORK' && bash ./briteRepo/bin/feedback respond -i 102 -c 'Thanks for the clarification.'")
[[ "$rc" -eq 0 ]] || fail "feedback respond -i should exit 0 (got $rc)"
assert_contains "Reply added to review comment 102" "$TMPDIR/respond.out"
assert_contains "repos/testowner/testrepo/pulls/comments/101/replies" "$TMPDIR/gh.log"
pass "threaded response targets root review comment"

rc=$(run_capture "$TMPDIR/resolve-denied.out" open env GITHUB_ACTOR=testcontrib bash -c "cd '$WORK' && bash ./briteRepo/bin/feedback resolve -i 102")
[[ "$rc" -eq 4 ]] || fail "feedback resolve by contributor should exit 4 (got $rc)"
assert_contains "not allowed to resolve review comment '102'" "$TMPDIR/resolve-denied.out"
pass "contributors cannot resolve review threads"

rc=$(run_capture "$TMPDIR/resolve.out" open env GITHUB_ACTOR=testapprover bash -c "cd '$WORK' && bash ./briteRepo/bin/feedback resolve -i 102")
[[ "$rc" -eq 0 ]] || fail "feedback resolve -i should exit 0 (got $rc)"
assert_contains "Review thread resolved for comment 102" "$TMPDIR/resolve.out"
assert_contains "resolveReviewThread" "$TMPDIR/gh.log"
assert_contains "thread-abc" "$TMPDIR/gh.log"
pass "thread resolution uses the review thread id"

: > "$TMPDIR/gh.log"
rc=$(run_capture "$TMPDIR/approve-blocked.out" open env \
  GITHUB_ACTOR=testapprover FAKE_APPROVED_SIBLING=true bash -c \
  "cd '$WORK' && bash ./briteRepo/bin/feedback approve -- 'Looks good to me.'")
[[ "$rc" -eq 3 ]] || fail "approval with pending sibling should exit 3 (got $rc)"
assert_contains "PR #12 ('dev/other-v1.0.0') is already approved" \
  "$TMPDIR/approve-blocked.out"
assert_not_contains "pr review 7 --approve" "$TMPDIR/gh.log"
pass "approve waits for an approved PR targeting the same parent"

rc=$(run_capture "$TMPDIR/approve-query-fail.out" open env \
  GITHUB_ACTOR=testapprover FAKE_APPROVED_QUERY_FAIL=true bash -c \
  "cd '$WORK' && bash ./briteRepo/bin/feedback approve -- 'Looks good to me.'")
[[ "$rc" -eq 4 ]] || fail "failed pending-approval query should exit 4 (got $rc)"
assert_contains "Failed to check approved PRs targeting 'main'" \
  "$TMPDIR/approve-query-fail.out"
pass "approve fails closed when sibling approval state is unavailable"

rc=$(run_capture "$TMPDIR/approve.out" open env GITHUB_ACTOR=testapprover bash -c "cd '$WORK' && bash ./briteRepo/bin/feedback approve -- 'Looks good to me.'")
[[ "$rc" -eq 0 ]] || fail "feedback approve should exit 0 (got $rc)"
assert_contains "PR #7 approved" "$TMPDIR/approve.out"
assert_contains "pr list --state open --base main --limit 1000" "$TMPDIR/gh.log"
assert_contains "pr review 7 --approve --body Looks good to me." "$TMPDIR/gh.log"
pass "approve action submits an approval review"

rc=$(run_capture "$TMPDIR/disapprove.out" open env GITHUB_ACTOR=testapprover bash -c "cd '$WORK' && bash ./briteRepo/bin/feedback disapprove -- 'Please add tests.'")
[[ "$rc" -eq 0 ]] || fail "feedback disapprove should exit 0 (got $rc)"
assert_contains "Changes requested on PR #7" "$TMPDIR/disapprove.out"
assert_contains "pr review 7 --request-changes --body Please add tests." "$TMPDIR/gh.log"
pass "disapprove action submits a changes-requested review"

echo "All feedback smoke tests passed."