#!/usr/bin/env bash

# test_review.sh - smoke tests for scripts/bin/review workflow actions.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REVIEW_SRC="$REPO_ROOT/scripts/bin/review"

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

[[ -f "$REVIEW_SRC" ]] || fail "missing script: $REVIEW_SRC"
[[ -x "$REVIEW_SRC" ]] || fail "review must be executable: $REVIEW_SRC"

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
printf '%s\n' "$*" >> "${FAKE_GH_LOG:-/dev/null}"

state_file="${FAKE_GH_STATE_FILE:-}"

get_state() {
  if [[ -n "$state_file" && -f "$state_file" ]]; then
    cat "$state_file"
  else
    echo "none"
  fi
}

set_state() {
  local new_state="$1"
  if [[ -n "$state_file" ]]; then
    printf '%s\n' "$new_state" > "$state_file"
  fi
}

case "$*" in
  *"pr list"*"--state open"*)
    if [[ "${FAKE_FAIL_PR_LIST:-}" == "1" ]]; then
      echo "forced pr list failure" >&2
      exit 1
    fi
    state="$(get_state)"
    if [[ "$state" == "draft" || "$state" == "ready" ]]; then
      echo "11"
    else
      echo ""
    fi
    exit 0
    ;;
  *"pr list"*"--state all"*)
    if [[ "${FAKE_FAIL_PR_LIST:-}" == "1" ]]; then
      echo "forced pr list failure" >&2
      exit 1
    fi
    state="$(get_state)"
    if [[ "$state" == "draft" || "$state" == "ready" ]]; then
      echo "11"
    else
      echo ""
    fi
    exit 0
    ;;
  *"pr list"*"--state closed"*)
    if [[ "${FAKE_FAIL_PR_LIST:-}" == "1" ]]; then
      echo "forced pr list failure" >&2
      exit 1
    fi
    state="$(get_state)"
    if [[ "$state" == "closed" ]]; then
      echo "11"
    else
      echo ""
    fi
    exit 0
    ;;
  *"pr view 11 --json isDraft --jq .isDraft"*)
    state="$(get_state)"
    [[ "$state" == "draft" ]] && echo "true" || echo "false"
    exit 0
    ;;
  *"pr view 11 --json labels --jq .labels[].name"*)
    if [[ -n "${FAKE_EXISTING_LABELS:-}" ]]; then
      printf '%s\n' "${FAKE_EXISTING_LABELS}" | tr ',' '\n'
    fi
    exit 0
    ;;
  *"pr view 11 --json id,isDraft --jq [.id,.isDraft] | @tsv"*)
    state="$(get_state)"
    if [[ "$state" == "draft" ]]; then
      printf 'PR_node_11\ttrue\n'
    else
      printf 'PR_node_11\tfalse\n'
    fi
    exit 0
    ;;
  *"api graphql"*"deletePullRequest"*)
    set_state "none"
    echo "deleted"
    exit 0
    ;;
  *"pr create"*)
    if [[ "$*" == *" --draft"* ]]; then
      set_state "draft"
    else
      set_state "ready"
    fi
    echo "https://github.com/testowner/testrepo/pull/11"
    exit 0
    ;;
  *"pr ready 11"*)
    set_state "ready"
    echo "ready"
    exit 0
    ;;
  *"pr edit 11"*)
    echo "edited"
    exit 0
    ;;
  *"pr view 11 --web"*)
    echo "opened"
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
mkdir -p "$WORK/scripts/bin" "$WORK/scripts/helpers" "$WORK/config"
cp "$REVIEW_SRC" "$WORK/scripts/bin/review"
for helper in common.sh git_helpers.sh github_helpers.sh history_log.sh ckrole.sh; do
  cp "$REPO_ROOT/scripts/helpers/$helper" "$WORK/scripts/helpers/$helper"
done
chmod +x "$WORK/scripts/bin/review"

(
  cd "$WORK"
  git config user.name "reviewer1"
  git config user.email "reviewer1@example.com"
  cat > config/contributors.md <<'EOF'
## Contributors

- reviewer1, R, reviewer1@example.com
- testapprover, A, approver@example.com
- testcontrib, C, contributor@example.com
EOF
  echo "seed" > README.md
  git add README.md config
  git commit -m "seed" >/dev/null 2>&1
  git branch -M dev/review-v1.0.0
  git remote set-url origin "https://github.com/testowner/testrepo.git"
)

run_capture() {
  local outfile="$1"
  local state="$2"
  shift
  shift
  printf '%s\n' "$state" > "$TMPDIR/gh_state"
  set +e
  env PATH="$FAKEBIN:$PATH" FAKE_GH_LOG="$TMPDIR/gh.log" FAKE_GH_STATE_FILE="$TMPDIR/gh_state" "$@" >"$outfile" 2>&1
  local rc=$?
  set -e
  echo "$rc"
}

clear_gh_log() {
  : > "$TMPDIR/gh.log"
}

clear_gh_log
rc=$(run_capture "$TMPDIR/help.out" none bash -c "cd '$WORK' && bash ./scripts/bin/review -h")
[[ "$rc" -eq 0 ]] || fail "review -h should exit 0 (got $rc)"
assert_not_contains "review approve" "$TMPDIR/help.out"
assert_not_contains "review disapprove" "$TMPDIR/help.out"
assert_contains "By default (-s option not specified), creates a draft PR" "$TMPDIR/help.out"
assert_contains "--delete" "$TMPDIR/help.out"
assert_contains "-s" "$TMPDIR/help.out"
pass "help documents draft-first workflow"

clear_gh_log
rc=$(run_capture "$TMPDIR/approve.out" none env GITHUB_ACTOR=testapprover bash -c "cd '$WORK' && bash ./scripts/bin/review approve -- 'Looks good to me.'")
[[ "$rc" -eq 1 ]] || fail "review approve should be rejected (got $rc)"
assert_contains "moved to feedback" "$TMPDIR/approve.out"
pass "approve action is rejected by review"

clear_gh_log
rc=$(run_capture "$TMPDIR/non_contrib.out" none env GITHUB_ACTOR=unknownactor bash -c "cd '$WORK' && bash ./scripts/bin/review")
[[ "$rc" -eq 3 ]] || fail "review should reject unknown contributor (got $rc)"
assert_contains "not listed as contributor" "$TMPDIR/non_contrib.out"
pass "non-contributors are denied review workflow"

cat > "$WORK/config/contributors.md" <<'EOF'
## Contributors

- reviewer1, R, reviewer1@example.com
- testcontrib, C, contributor@example.com
EOF
clear_gh_log
rc=$(run_capture "$TMPDIR/no_approver.out" none env GITHUB_ACTOR=reviewer1 bash -c "cd '$WORK' && bash ./scripts/bin/review")
[[ "$rc" -eq 4 ]] || fail "review should fail when no approver exists (got $rc)"
assert_contains "No approvers found" "$TMPDIR/no_approver.out"
pass "contributors config must contain at least one approver"

cat > "$WORK/config/contributors.md" <<'EOF'
## Contributors

- reviewer1, R, reviewer1@example.com
- testapprover, A, approver@example.com
- testcontrib, C, contributor@example.com
EOF

clear_gh_log
rc=$(run_capture "$TMPDIR/create_draft.out" none bash -c "cd '$WORK' && bash ./scripts/bin/review -T 'WIP Feature'")
[[ "$rc" -eq 1 ]] || fail "review create without description should fail (got $rc)"
assert_contains "PR description is required when creating a new PR" "$TMPDIR/create_draft.out"
assert_contains "use -c TOKEN or -- TOKEN..." "$TMPDIR/create_draft.out"
pass "create path requires a description"

clear_gh_log
rc=$(run_capture "$TMPDIR/create_draft_with_desc.out" none bash -c "cd '$WORK' && bash ./scripts/bin/review -T 'WIP Feature' -c 'Initial draft description.'")
[[ "$rc" -eq 0 ]] || fail "review should create draft PR with description (got $rc)"
assert_contains "Draft PR #11 created" "$TMPDIR/create_draft_with_desc.out"
assert_contains "pr create" "$TMPDIR/gh.log"
assert_contains "--draft" "$TMPDIR/gh.log"
assert_not_contains "--add-reviewer" "$TMPDIR/gh.log"
pass "default behavior creates draft PR when description is provided"

clear_gh_log
rc=$(run_capture "$TMPDIR/description_alias.out" none bash -c "cd '$WORK' && bash ./scripts/bin/review --description 'alias text'")
[[ "$rc" -eq 1 ]] || fail "review --description should be rejected (got $rc)"
assert_contains "Unknown option: --description" "$TMPDIR/description_alias.out"
pass "--description alias is not accepted"

clear_gh_log
rc=$(run_capture "$TMPDIR/dry_run_create.out" none bash -c "cd '$WORK' && bash ./scripts/bin/review -d -T 'Dry Run Feature' -c 'Dry run description.'")
[[ "$rc" -eq 0 ]] || fail "review -d should succeed (got $rc)"
assert_contains "Dry run enabled" "$TMPDIR/dry_run_create.out"
assert_contains "Planned action: create draft PR" "$TMPDIR/dry_run_create.out"
assert_not_contains "pr create" "$TMPDIR/gh.log"
pass "dry-run previews create path without mutation"

clear_gh_log
rc=$(run_capture "$TMPDIR/dry_run_start.out" draft bash -c "cd '$WORK' && bash ./scripts/bin/review -d -s")
[[ "$rc" -eq 0 ]] || fail "review -d -s should succeed (got $rc)"
assert_contains "Planned action: update draft PR #11 and start review" "$TMPDIR/dry_run_start.out"
assert_not_contains "pr edit 11" "$TMPDIR/gh.log"
assert_not_contains "pr ready 11" "$TMPDIR/gh.log"
pass "dry-run previews start-review path without mutation"

clear_gh_log
rc=$(run_capture "$TMPDIR/dry_run_browser.out" none bash -c "cd '$WORK' && bash ./scripts/bin/review -d -b")
[[ "$rc" -eq 1 ]] || fail "review -d -b should fail (got $rc)"
assert_contains "cannot be combined with -d" "$TMPDIR/dry_run_browser.out"
pass "dry-run rejects browser option"

clear_gh_log
rc=$(run_capture "$TMPDIR/browser_open_ready.out" ready bash -c "cd '$WORK' && bash ./scripts/bin/review -b")
[[ "$rc" -eq 0 ]] || fail "review -b with open non-draft PR should open UI (got $rc)"
assert_contains "Opened open PR #11 in browser" "$TMPDIR/browser_open_ready.out"
assert_contains "pr view 11 --web" "$TMPDIR/gh.log"
pass "browser-only mode opens open non-draft PR"

clear_gh_log
rc=$(run_capture "$TMPDIR/browser_closed_fallback.out" closed bash -c "cd '$WORK' && bash ./scripts/bin/review -b")
[[ "$rc" -eq 0 ]] || fail "review -b should fall back to latest closed PR (got $rc)"
assert_contains "Opened latest closed PR #11 in browser" "$TMPDIR/browser_closed_fallback.out"
assert_contains "pr list --head dev/review-v1.0.0 --state closed" "$TMPDIR/gh.log"
assert_contains "pr view 11 --web" "$TMPDIR/gh.log"
pass "browser-only mode falls back to latest closed PR"

clear_gh_log
rc=$(run_capture "$TMPDIR/browser_no_pr.out" none bash -c "cd '$WORK' && bash ./scripts/bin/review -b")
[[ "$rc" -eq 1 ]] || fail "review -b with no PR should fail (got $rc)"
assert_contains "No open or closed PR found for branch" "$TMPDIR/browser_no_pr.out"
pass "browser-only mode reports when no PR exists"

clear_gh_log
rc=$(run_capture "$TMPDIR/start_review.out" draft env FAKE_EXISTING_LABELS="old1,old2" bash -c "cd '$WORK' && bash ./scripts/bin/review -s -T 'Ready Feature' -l 'bug, urgent'")
[[ "$rc" -eq 0 ]] || fail "review -s should update draft and start review (got $rc)"
assert_contains "updated and review started" "$TMPDIR/start_review.out"
assert_contains "pr edit 11 --remove-label old1" "$TMPDIR/gh.log"
assert_contains "pr edit 11 --remove-label old2" "$TMPDIR/gh.log"
assert_contains "pr edit 11 --add-label bug" "$TMPDIR/gh.log"
assert_contains "pr edit 11 --add-label urgent" "$TMPDIR/gh.log"
assert_contains "pr edit 11 --add-reviewer" "$TMPDIR/gh.log"
assert_contains "pr ready 11" "$TMPDIR/gh.log"
pass "-s transitions draft to ready and requests review"

clear_gh_log
rc=$(run_capture "$TMPDIR/delete_draft.out" draft bash -c "cd '$WORK' && bash ./scripts/bin/review --delete")
[[ "$rc" -eq 0 ]] || fail "review --delete should delete draft PR (got $rc)"
assert_contains "Draft PR #11 deleted" "$TMPDIR/delete_draft.out"
assert_contains "api graphql" "$TMPDIR/gh.log"
assert_contains "deletePullRequest" "$TMPDIR/gh.log"
pass "--delete removes draft PR"

clear_gh_log
rc=$(run_capture "$TMPDIR/delete_browser.out" draft bash -c "cd '$WORK' && bash ./scripts/bin/review --delete -b")
[[ "$rc" -eq 1 ]] || fail "review --delete -b should fail (got $rc)"
assert_contains "mutually exclusive" "$TMPDIR/delete_browser.out"
pass "-b is rejected with --delete"

clear_gh_log
rc=$(run_capture "$TMPDIR/delete_start.out" draft bash -c "cd '$WORK' && bash ./scripts/bin/review --delete -s")
[[ "$rc" -eq 1 ]] || fail "review --delete -s should fail (got $rc)"
assert_contains "cannot be combined with -s" "$TMPDIR/delete_start.out"
pass "--delete rejects -s"

clear_gh_log
rc=$(run_capture "$TMPDIR/delete_description.out" draft bash -c "cd '$WORK' && bash ./scripts/bin/review --delete -c 'x'")
[[ "$rc" -eq 1 ]] || fail "review --delete -c should fail (got $rc)"
assert_contains "must not be provided with --delete" "$TMPDIR/delete_description.out"
pass "--delete rejects description input"

clear_gh_log
rc=$(run_capture "$TMPDIR/title_whitespace.out" none bash -c "cd '$WORK' && bash ./scripts/bin/review -T '   '")
[[ "$rc" -eq 1 ]] || fail "review -T whitespace should fail (got $rc)"
assert_contains "TITLE must include at least one non-whitespace character" "$TMPDIR/title_whitespace.out"
pass "title cannot be whitespace only"

clear_gh_log
rc=$(run_capture "$TMPDIR/labels_empty_token.out" none bash -c "cd '$WORK' && bash ./scripts/bin/review -l 'bug, ,urgent'")
[[ "$rc" -eq 1 ]] || fail "review with empty label token should fail (got $rc)"
assert_contains "LABELS contains an empty label token" "$TMPDIR/labels_empty_token.out"
pass "labels reject empty tokens"

clear_gh_log
rc=$(run_capture "$TMPDIR/pr_list_failure.out" none env FAKE_FAIL_PR_LIST=1 bash -c "cd '$WORK' && bash ./scripts/bin/review")
[[ "$rc" -eq 200 ]] || fail "review should surface gh pr list failure as API error (got $rc)"
assert_contains "Failed to query open PRs" "$TMPDIR/pr_list_failure.out"
pass "gh pr list failures are not silently treated as no PR"

clear_gh_log
rc=$(run_capture "$TMPDIR/non_draft_blocked.out" ready bash -c "cd '$WORK' && bash ./scripts/bin/review")
[[ "$rc" -eq 1 ]] || fail "review should reject branch with open non-draft PR (got $rc)"
assert_contains "open non-draft PR already exists" "$TMPDIR/non_draft_blocked.out"
pass "open non-draft PR blocks review command"

echo "All review smoke tests passed."