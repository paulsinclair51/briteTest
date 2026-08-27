#!/usr/bin/env bash

# test_push.sh - smoke tests for briteRepo/bin/push.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PUSH_SRC="$REPO_ROOT/briteRepo/bin/push"
COMMON_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/common.sh"
GIT_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/git_helpers.sh"
GITHUB_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/github_helpers.sh"
HISTORY_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/history_log.sh"
REPORT_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/report_helpers.sh"
REPORT_SYNC_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/report_sync.sh"
PUSH_WORKFLOW_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/push_workflow.sh"
CKROLE_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/ckrole.sh"

pass() {
  echo "PASS: $1"
}

fail() {
  echo "FAIL: $1" >&2
  exit 1
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

assert_contains() {
  local text="$1"
  local file="$2"
  grep -Fq -- "$text" "$file" || fail "expected '$text' in $file"
}

assert_matches() {
  local regex="$1"
  local file="$2"
  grep -Eq -- "$regex" "$file" || fail "expected pattern '$regex' in $file"
}

latest_report() {
  local repo="$1"
  local pattern="$2"
  find "$repo/reports" -maxdepth 1 -type f -name "$pattern" -printf '%T@ %p\n' | sort -n | tail -n 1 | cut -d' ' -f2-
}

TMPDIR="$(mktemp -d)"
cleanup() {
  chmod -R u+w "$TMPDIR" 2>/dev/null || true
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

ORIGIN="$TMPDIR/origin.git"
WORK="$TMPDIR/work"

git init --bare "$ORIGIN" >/dev/null 2>&1
git clone "file://$ORIGIN" "$WORK" >/dev/null 2>&1

mkdir -p "$WORK/briteRepo/bin" "$WORK/briteRepo/helpers" "$WORK/config"
cp "$PUSH_SRC" "$WORK/briteRepo/bin/push"
cp "$COMMON_HELPER_SRC" "$WORK/briteRepo/helpers/common.sh"
cp "$GIT_HELPER_SRC" "$WORK/briteRepo/helpers/git_helpers.sh"
cp "$GITHUB_HELPER_SRC" "$WORK/briteRepo/helpers/github_helpers.sh"
cp "$HISTORY_HELPER_SRC" "$WORK/briteRepo/helpers/history_log.sh"
cp "$REPORT_HELPER_SRC" "$WORK/briteRepo/helpers/report_helpers.sh"
cp "$REPORT_SYNC_HELPER_SRC" "$WORK/briteRepo/helpers/report_sync.sh"
cp "$PUSH_WORKFLOW_HELPER_SRC" "$WORK/briteRepo/helpers/push_workflow.sh"
cp "$CKROLE_HELPER_SRC" "$WORK/briteRepo/helpers/ckrole.sh"
chmod +x "$WORK/briteRepo/bin/push" "$WORK/briteRepo/helpers/ckrole.sh"

mkdir -p "$WORK/reports"

cat > "$WORK/config/contributors.md" <<'EOF'
- testuser, C
EOF

(
  cd "$WORK"
  git config user.name "testuser"
  git config user.email "test@example.com"

  echo "seed" > README.md
  git add README.md briteRepo config
  git commit -m "seed repo" >/dev/null 2>&1
  git branch -M main
  git push -u origin main >/dev/null 2>&1

  git checkout -b dev/push-tests-v1.0.0 >/dev/null 2>&1
  git push -u origin dev/push-tests-v1.0.0 >/dev/null 2>&1
)

# 1) Help output should include the timeout option.
rc=$(run_capture "$TMPDIR/help.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/push -h")
[[ "$rc" -eq 0 ]] || fail "push -h should exit 0 (got $rc)"
assert_contains "-t SEC" "$TMPDIR/help.out"
assert_contains "A contributor may push a protected parent" "$TMPDIR/help.out"
assert_contains "If another user pushes the same parent first" \
  "$TMPDIR/help.out"
pass "help output"

copyfix_state_root="$(git -C "$WORK" rev-parse \
  --path-format=absolute --git-common-dir)/briteRepo-copyfix-state"
mkdir -p "$copyfix_state_root/dev/push-tests-v1.0.0"
rc=$(run_capture "$TMPDIR/copyfix-active.out" env GITHUB_ACTOR=testuser \
  bash -lc "cd '$WORK' && bash ./briteRepo/bin/push -t 5")
[[ "$rc" -eq 1 ]] || fail "unfinished copyfix should block push (got $rc)"
assert_contains "has an unfinished copyfix operation" \
  "$TMPDIR/copyfix-active.out"
rm -rf "$copyfix_state_root"
pass "unfinished copyfix blocks push"

# 1b) The explicit skip mode should emit an error report and summary line.
rc=$(run_capture "$TMPDIR/skip-e.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/push -e -t 5")
[[ "$rc" -eq 9 ]] || fail "push -e should exit 9 (got $rc)"
assert_contains "Error: Push skipped due to -e option." "$TMPDIR/skip-e.out"
assert_contains "Guidance: Run without -e option." "$TMPDIR/skip-e.out"
assert_contains "See reports/push-e-" "$TMPDIR/skip-e.out"
skip_report="$(latest_report "$WORK" 'push-e-*.md')"
[[ -f "$skip_report" ]] || fail "expected push skip report"
assert_contains "# Error Push Report" "$skip_report"
if grep -Fq "**Push Tip:**" "$skip_report"; then
  fail "push error report should not include internal Push Tip metadata"
fi
assert_contains "**Error:** Push skipped due to -e option." "$skip_report"
assert_contains "**Guidance:** Run without -e option." "$skip_report"
assert_contains "<summary>Files</summary>" "$skip_report"
assert_contains "| **File** | **Commit** | **Added** | **Deleted** | **Net** | **Lines** | **Action** |" "$skip_report"
assert_contains "| **Total** |" "$skip_report"
assert_contains "## Push Issue Attribution" "$skip_report"
assert_contains "Sample remote policy rejection would typically name one or more files." "$skip_report"
assert_contains "## Push Error Output" "$skip_report"
assert_contains "Sample push output:" "$skip_report"
assert_contains "rejected by sample remote policy: README.md policy violation" "$skip_report"
assert_contains "## Guidance" "$skip_report"
assert_contains "Remote policy/hook rejected this push." "$skip_report"
assert_contains "Push is atomic for this branch update." "$skip_report"
pass "skip mode"

# Nothing to push should not create a report.
cat > "$WORK/reports/push-d-20000101-000000.md" <<'EOF'
# Stale Push Report

**Branch:** `dev/push-tests-v1.0.0`
EOF
cat > "$WORK/reports/push-e-20000101-000001.md" <<'EOF'
# Stale Push Error Report

**Branch:** `dev/push-tests-v1.0.0`
EOF
chmod a-w "$WORK/reports/push-d-20000101-000000.md" \
  "$WORK/reports/push-e-20000101-000001.md"
rc=$(run_capture "$TMPDIR/noop.out" env GITHUB_ACTOR=testuser \
  bash -lc "cd '$WORK' && bash ./briteRepo/bin/push -t 5")
[[ "$rc" -eq 10 ]] || fail "no-work push should exit 10 (got $rc)"
assert_contains "no changes to push" "$TMPDIR/noop.out"
[[ -f "$WORK/reports/push-d-20000101-000000.md" ]] || \
  fail "push prerequisite failure should preserve stale dry-run reports"
[[ -f "$WORK/reports/push-e-20000101-000001.md" ]] || \
  fail "push prerequisite failure should preserve stale error reports"
pass "no-work push prerequisite"

# 2) Invalid timeout should fail before remote operations.
rc=$(run_capture "$TMPDIR/invalid-t.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/push -t 0")
[[ "$rc" -eq 1 ]] || fail "push -t 0 should exit 1 (got $rc)"
assert_contains "Option -t requires an integer greater than 0" "$TMPDIR/invalid-t.out"
pass "invalid timeout parsing"

# 3) Missing required tool should fail fast with clear guidance.
mkdir -p "$TMPDIR/minpath"
for tool in bash git awk sed grep wc cksum flock chmod rm mkdir date dirname; do
  ln -s "$(command -v "$tool")" "$TMPDIR/minpath/$tool"
done
rc=$(run_capture "$TMPDIR/missing-tool.out" env PATH="$TMPDIR/minpath" GITHUB_ACTOR=testuser /bin/bash -c "cd '$WORK' && /bin/bash ./briteRepo/bin/push -d -t 5")
[[ "$rc" -eq 1 ]] || fail "missing required tool preflight should exit 1 (got $rc)"
assert_contains "Error: Missing required tool(s): head" "$TMPDIR/missing-tool.out"
assert_contains "Guidance: run push in a standard repository shell environment and try again" "$TMPDIR/missing-tool.out"
pass "toolchain preflight"

# 4) Unauthorized user should be blocked with exit 2.
(
  cd "$WORK"
  git checkout dev/push-tests-v1.0.0 >/dev/null 2>&1
  git config user.name "outsider"
  git config user.email "outsider@example.com"
  echo "change" >> README.md
)
rc=$(run_capture "$TMPDIR/unauth.out" env GITHUB_ACTOR=outsider bash -lc "cd '$WORK' && bash ./briteRepo/bin/push -d -t 5")
[[ "$rc" -eq 2 ]] || fail "unauthorized push should exit 2 (got $rc)"
assert_contains "Error: User is not a contributor" "$TMPDIR/unauth.out"
assert_contains "Guidance: use an account and merge path authorized by repository policy" "$TMPDIR/unauth.out"
(
  cd "$WORK"
  git config user.name "testuser"
  git config user.email "test@example.com"
  git restore README.md
)
pass "authorization gate"

# 5) Protected main branch should be rejected with exit 3.
(
  cd "$WORK"
  git checkout main >/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/protected.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/push -d -t 5")
[[ "$rc" -eq 3 ]] || fail "protected branch push should exit 3 (got $rc)"
assert_contains "Cannot push protected branch" "$TMPDIR/protected.out"
pass "protected branch gate"

# Policy-invalid local branches are read-only and cannot be pushed.
(
  cd "$WORK"
  git checkout -b v1.0.1 main >/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/policy-invalid.out" env GITHUB_ACTOR=testuser \
  bash -lc "cd '$WORK' && bash ./briteRepo/bin/push -d -t 5")
[[ "$rc" -eq 3 ]] || fail "policy-invalid branch push should exit 3 (got $rc)"
assert_contains "Cannot push policy-invalid read-only branch" \
  "$TMPDIR/policy-invalid.out"
pass "policy-invalid branch gate"

# Internal helper modes are not options of the direct push command.
rc=$(run_capture "$TMPDIR/internal-option.out" env GITHUB_ACTOR=testuser \
  bash -lc "cd '$WORK' && bash ./briteRepo/bin/push -d --pushup dev/fake-v1.0.0 -t 5")
[[ "$rc" -eq 1 ]] || fail "direct internal option should exit 1 (got $rc)"
assert_contains "Internal push workflow options cannot be used" "$TMPDIR/internal-option.out"
pass "internal helper option rejected by direct push"

# 6) Valid dry-run should report what would be pushed.
(
  cd "$WORK"
  git checkout dev/push-tests-v1.0.0 >/dev/null 2>&1
  echo "push change" >> README.md
  git add README.md
  git commit -m "push test change" >/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/dry.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/push -d -t 5")
[[ "$rc" -eq 0 ]] || fail "dry-run push should exit 0 (got $rc)"
assert_contains "Dry-run: push to remote dev/push-tests-v1.0.0:" "$TMPDIR/dry.out"
assert_contains "See reports/push-d-" "$TMPDIR/dry.out"
dry_report="$(latest_report "$WORK" 'push-d-*.md')"
[[ -f "$dry_report" ]] || fail "expected dry-run push report"
[[ "$(basename "$dry_report")" == push-d-* ]] || fail "expected push-d report filename"
assert_contains "# Dry-run Push Report" "$dry_report"
if grep -Fq '**Push Tip:**' "$dry_report"; then
  fail "push dry-run report should not include internal Push Tip metadata"
fi
assert_contains '**Branch:** `dev/push-tests-v1.0.0`' "$dry_report"
assert_contains '**Status:** ' "$dry_report"
assert_contains '## 1. push: ' "$dry_report"
assert_contains '**User:** testuser' "$dry_report"
assert_contains '**Pushed-Tip:** `To be determined`' "$dry_report"
push_tip_line="$(grep -n '\*\*Pushed-Tip:\*\*' "$dry_report" | head -n 1 | cut -d: -f1)"
push_command_line="$(grep -n '\*\*Command:\*\*' "$dry_report" | head -n 1 | cut -d: -f1)"
[[ "$push_tip_line" -lt "$push_command_line" ]] || \
  fail "push-d Pushed-Tip should precede Command"
if grep -Fq "**Triggered By:**" "$dry_report"; then
  fail "dry-run push report should not include Triggered By"
fi
assert_contains "**Changes:** 1 modified file" "$dry_report"
assert_contains "**Lines:** " "$dry_report"
assert_contains "<details>" "$dry_report"
assert_contains "<summary>Commits</summary>" "$dry_report"
assert_contains "| **Commit Hash** | **DateTime** | **Comment** |" "$dry_report"
assert_contains "push test change" "$dry_report"
assert_contains "<summary>Files</summary>" "$dry_report"
assert_contains "| **File** | **Commit** | **Added** | **Deleted** | **Net** | **Lines** | **Action** |" "$dry_report"
assert_contains "| \`README.md\` |" "$dry_report"
assert_contains "| **Total** |" "$dry_report"
assert_contains "</details>" "$dry_report"
awk '
  /^\| --- \| ---: \| ---: \| ---: \| ---: \|$/ {
    getline
    exit($0 ~ /^\| `[^`]+` \|/ ? 0 : 1)
  }
  END { if (NR == 0) exit 1 }
' "$dry_report" || fail "expected dry-run table rows immediately after separator"
pass "dry-run push"

# 7) Invalid lock-timeout env var should fail with report error guidance.
rc=$(run_capture "$TMPDIR/invalid-lock-timeout.out" env BT_PUSH_REPORT_LOCK_TIMEOUT_SECONDS=abc GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/push -d -t 5")
[[ "$rc" -eq 201 ]] || fail "invalid lock-timeout env should exit 201 (got $rc)"
assert_contains "Invalid report lock timeout 'abc'" "$TMPDIR/invalid-lock-timeout.out"
assert_contains "Set BT_PUSH_REPORT_LOCK_TIMEOUT_SECONDS to an integer greater than 0" "$TMPDIR/invalid-lock-timeout.out"
pass "invalid lock-timeout env"

# 8) Dry-run should fail with 8 if report lock cannot be acquired within
# timeout.
repo_hash="$(printf '%s' "$WORK" | cksum | awk '{print $1}')"
lock_file="/tmp/briteRepo-report-push-${repo_hash}.lock"
mkfifo "$TMPDIR/lock.wait"
(
  exec 9>"$lock_file"
  flock 9
  cat "$TMPDIR/lock.wait" >/dev/null
) &
lock_holder_pid=$!

rc=$(run_capture "$TMPDIR/lock-timeout.out" env BT_PUSH_REPORT_LOCK_TIMEOUT_SECONDS=1 GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/push -d -t 5")
[[ "$rc" -eq 8 ]] || fail "dry-run should exit 8 when report lock times out (got $rc)"
assert_contains "Timed out waiting 1s for report write lock" "$TMPDIR/lock-timeout.out"
# Close the FIFO writer to deliver EOF so the lock holder exits cleanly.
: > "$TMPDIR/lock.wait"
wait "$lock_holder_pid" >/dev/null 2>&1 || true
rm -f "$TMPDIR/lock.wait"
pass "report lock timeout"

# 9) Concurrent dry-runs should serialize allocation/cleanup and leave one
# complete PID-free transient report.
set +e
env GITHUB_ACTOR=testuser bash -c "cd '$WORK' && bash ./briteRepo/bin/push -d -t 5" >"$TMPDIR/dry-race-1.out" 2>&1 &
p1=$!
env GITHUB_ACTOR=testuser bash -c "cd '$WORK' && bash ./briteRepo/bin/push -d -t 5" >"$TMPDIR/dry-race-2.out" 2>&1 &
p2=$!
wait "$p1"; rc1=$?
wait "$p2"; rc2=$?
set -e

[[ "$rc1" -eq 0 ]] || fail "first concurrent dry-run should exit 0 (got $rc1)"
[[ "$rc2" -eq 0 ]] || fail "second concurrent dry-run should exit 0 (got $rc2)"

race_report="$(latest_report "$WORK" 'push-d-*.md')"
[[ -f "$race_report" ]] || fail "expected concurrent dry-run report"
race_report_count="$(find "$WORK/reports" -maxdepth 1 -type f -name 'push-d-*.md' | wc -l | tr -d ' ')"
[[ "$race_report_count" -eq 1 ]] || fail "expected one serialized same-second dry-run report (got $race_report_count)"
[[ "$(basename "$race_report")" =~ ^push-d-[0-9]{8}-[0-9]{6}\.md$ ]] || \
  fail "expected PID-free dry-run filename"

pass "concurrent dry-run report serialization"

# 10) Real push should succeed without a confirmation prompt.
rc=$(run_capture "$TMPDIR/push.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/push -t 5")
[[ "$rc" -eq 0 ]] || fail "push should exit 0 (got $rc)"
assert_contains "Pushed (" "$TMPDIR/push.out"
assert_contains "to remote dev/push-tests-v1.0.0: 1 modified file." "$TMPDIR/push.out"
assert_contains "Run report -r for details." \
  "$TMPDIR/push.out"
push_note="$(git -C "$WORK" notes --ref=briteRepo-remote-workflow show HEAD)"
[[ "$push_note" == *"Workflow-Type: push"* ]] || \
  fail "successful push should record its workflow type"
[[ "$push_note" == *"Command-Line: push -t 5"* ]] || \
  fail "successful push should record its command line"
[[ "$push_note" == *"Previous-Remote-Tip: "* ]] || \
  fail "successful push should record its previous remote tip"
[[ "$push_note" == *"Pushed-Tip: "* ]] || \
  fail "successful push should record its pushed tip"
[[ "$push_note" == *"Commits: 1"* ]] || \
  fail "successful push should record its commit count"
[[ "$push_note" == *"Files-Modified: 1"* && \
  "$push_note" == *"Files-Renamed: 0"* && \
  "$push_note" == *"Directories-Renamed: 0"* ]] || \
  fail "successful push should record its file counts"
remote_push_note="$(git --git-dir="$ORIGIN" notes \
  --ref=briteRepo-remote-workflow show \
  "$(git -C "$WORK" rev-parse HEAD)" 2>/dev/null || true)"
[[ "$remote_push_note" == *"Workflow-Type: push"* ]] || \
  fail "successful push should publish its workflow history to origin"
if grep -Fq "See reports/push-" "$TMPDIR/push.out"; then
  fail "successful non-dry push should not output a report path"
fi
if find "$WORK/reports" -maxdepth 1 -type f -name 'push-*.md' -print -quit | grep -q .; then
  fail "successful non-dry push should not create a push report"
fi
remote_tip="$(git -C "$ORIGIN" rev-parse refs/heads/dev/push-tests-v1.0.0)"
local_tip="$(git -C "$WORK" rev-parse HEAD)"
[[ "$remote_tip" == "$local_tip" ]] || fail "remote tip should match local tip after push"
pass "real push"

# A local pushup event authorizes an approver to publish its protected parent
# and finalizes the associated PR only after the branch push succeeds.
PUSHUP_ORIGIN="$TMPDIR/pushup-origin.git"
PUSHUP_WORK="$TMPDIR/pushup-work"
PUSHUP_BIN="$TMPDIR/pushup-bin"
git init --bare "$PUSHUP_ORIGIN" >/dev/null 2>&1
git clone "file://$PUSHUP_ORIGIN" "$PUSHUP_WORK" >/dev/null 2>&1
mkdir -p "$PUSHUP_WORK/briteRepo/bin" "$PUSHUP_WORK/briteRepo/helpers" \
  "$PUSHUP_WORK/config" "$PUSHUP_WORK/reports" "$PUSHUP_BIN"
cp "$PUSH_SRC" "$PUSHUP_WORK/briteRepo/bin/push"
cp "$COMMON_HELPER_SRC" "$PUSHUP_WORK/briteRepo/helpers/common.sh"
cp "$GIT_HELPER_SRC" "$PUSHUP_WORK/briteRepo/helpers/git_helpers.sh"
cp "$GITHUB_HELPER_SRC" "$PUSHUP_WORK/briteRepo/helpers/github_helpers.sh"
cp "$HISTORY_HELPER_SRC" "$PUSHUP_WORK/briteRepo/helpers/history_log.sh"
cp "$REPORT_HELPER_SRC" "$PUSHUP_WORK/briteRepo/helpers/report_helpers.sh"
cp "$REPORT_SYNC_HELPER_SRC" "$PUSHUP_WORK/briteRepo/helpers/report_sync.sh"
cp "$PUSH_WORKFLOW_HELPER_SRC" "$PUSHUP_WORK/briteRepo/helpers/push_workflow.sh"
cat > "$PUSHUP_WORK/config/contributors.md" <<'EOF'
- testapprover, A
- testcontributor, C
EOF
cat > "$PUSHUP_BIN/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$FAKE_GH_LOG"

if [[ "$1 $2" == "pr view" && "$*" == *"headRefOid"* ]]; then
  if [[ -f "$FAKE_GH_STATE_DIR/stale-$3" ]]; then
    review_decision="REVIEW_REQUIRED"
  else
    review_decision="APPROVED"
  fi
  echo -e "OPEN\tfalse\t${FAKE_PUSHUP_SOURCE:?}\t${FAKE_PUSHUP_TARGET:?}\t${FAKE_PUSHUP_SOURCE_TIP:?}\t${review_decision}\t"
elif [[ "$1 $2" == "pr view" && "$*" == *"--json state"* ]]; then
  if [[ -f "$FAKE_GH_STATE_DIR/closed-$3" ]]; then
    echo "CLOSED"
  else
    echo "OPEN"
  fi
elif [[ "$1 $2" == "pr view" && "$*" == *"--json comments"* ]]; then
  cat "$FAKE_GH_STATE_DIR/comments-$3" 2>/dev/null || true
elif [[ "$1 $2" == "pr comment" ]]; then
  pr_number="$3"
  while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--body-file" ]]; then
      cat "$2" > "$FAKE_GH_STATE_DIR/comments-$pr_number"
      break
    fi
    shift
  done
elif [[ "$1 $2" == "pr close" ]]; then
  if [[ "${FAKE_GH_FAIL_CLOSE_ONCE:-false}" == true && \
    ! -f "$FAKE_GH_STATE_DIR/failed-close-$3" ]]; then
    touch "$FAKE_GH_STATE_DIR/failed-close-$3"
    exit 1
  fi
  touch "$FAKE_GH_STATE_DIR/closed-$3"
elif [[ "$1" == "api" && "$*" == *"/pulls/"*"/reviews"* ]]; then
  endpoint=""
  for arg in "$@"; do
    [[ "$arg" == repos/*/pulls/*/reviews ]] && endpoint="$arg"
  done
  pr_number="${endpoint%/reviews}"
  pr_number="${pr_number##*/}"
  [[ ! -f "$FAKE_GH_STATE_DIR/stale-$pr_number" ]] && echo 1001
fi
exit 0
EOF
chmod +x "$PUSHUP_BIN/gh" "$PUSHUP_WORK/briteRepo/bin/push"
FAKE_GH_STATE_DIR="$TMPDIR/pushup-gh-state"
mkdir -p "$FAKE_GH_STATE_DIR"
(
  cd "$PUSHUP_WORK"
  git config user.name testapprover
  git config user.email approver@example.com
  echo seed > README.md
  git add README.md briteRepo config
  git commit -m seed >/dev/null 2>&1
  git branch -M main
  git push -u origin main >/dev/null 2>&1
  git checkout -b v1.0.0 >/dev/null 2>&1
  git push -u origin v1.0.0 >/dev/null 2>&1
  echo merged > merged.txt
  git add merged.txt
  git commit -m "local pushup result" >/dev/null 2>&1
  source_tip="1111111111111111111111111111111111111111"
  source briteRepo/helpers/history_log.sh
  bt_record_workflow_event "pushup" "v1.0.0" "pushup" \
    "Merged dev/feature-v1.0.0 into v1.0.0" HEAD \
    "Source-Branch" "dev/feature-v1.0.0" \
    "Source-Tip" "$source_tip" \
    "Target-Branch" "v1.0.0" "PR" "42"
)
FAKE_GH_LOG="$TMPDIR/pushup-gh.log"
rc=$(run_capture "$TMPDIR/pushup-push.out" env GITHUB_ACTOR=testcontributor \
  FAKE_GH_LOG="$FAKE_GH_LOG" FAKE_GH_STATE_DIR="$FAKE_GH_STATE_DIR" \
  FAKE_PUSHUP_SOURCE=dev/feature-v1.0.0 FAKE_PUSHUP_TARGET=v1.0.0 \
  FAKE_PUSHUP_SOURCE_TIP=1111111111111111111111111111111111111111 \
  PATH="$PUSHUP_BIN:$PATH" \
  bash -c "cd '$PUSHUP_WORK' && bash ./briteRepo/bin/push -t 5")
[[ "$rc" -eq 0 ]] || fail "push should publish pending pushup (got $rc)"
assert_contains "Pushed (" "$TMPDIR/pushup-push.out"
assert_contains "pr comment 42" "$FAKE_GH_LOG"
assert_contains "pr close 42" "$FAKE_GH_LOG"
[[ "$(git -C "$PUSHUP_WORK" rev-parse v1.0.0)" == \
  "$(git --git-dir="$PUSHUP_ORIGIN" rev-parse refs/heads/v1.0.0)" ]] || \
  fail "push should publish the local pushup parent tip"
pass "approved contributor pushup publication and PR finalization"

# A failed close occurs after the atomic branch/history publication. A rerun
# with no commits retries only PR finalization and does not duplicate comments.
(
  cd "$PUSHUP_WORK"
  echo retry > retry.txt
  git add retry.txt
  git commit -m "pushup close retry" >/dev/null 2>&1
  source_tip="2222222222222222222222222222222222222222"
  source briteRepo/helpers/history_log.sh
  bt_record_workflow_event "pushup" "v1.0.0" "pushup" \
    "Merged dev/retry-v1.0.0 into v1.0.0" HEAD \
    "Source-Branch" "dev/retry-v1.0.0" \
    "Source-Tip" "$source_tip" \
    "Target-Branch" "v1.0.0" "PR" "43"
)
retry_tip="$(git -C "$PUSHUP_WORK" rev-parse HEAD)"
rc=$(run_capture "$TMPDIR/pushup-close-fail.out" env \
  GITHUB_ACTOR=testapprover FAKE_GH_LOG="$FAKE_GH_LOG" \
  FAKE_GH_STATE_DIR="$FAKE_GH_STATE_DIR" FAKE_GH_FAIL_CLOSE_ONCE=true \
  FAKE_PUSHUP_SOURCE=dev/retry-v1.0.0 FAKE_PUSHUP_TARGET=v1.0.0 \
  FAKE_PUSHUP_SOURCE_TIP=2222222222222222222222222222222222222222 \
  PATH="$PUSHUP_BIN:$PATH" \
  bash -c "cd '$PUSHUP_WORK' && bash ./briteRepo/bin/push -t 5")
[[ "$rc" -eq 202 ]] || fail "failed PR close should exit 202 (got $rc)"
[[ "$(git --git-dir="$PUSHUP_ORIGIN" rev-parse refs/heads/v1.0.0)" == \
  "$retry_tip" ]] || fail "failed PR close should leave the branch published"
remote_retry_note="$(git --git-dir="$PUSHUP_ORIGIN" notes \
  --ref=briteRepo-remote-workflow show "$retry_tip" 2>/dev/null || true)"
[[ "$remote_retry_note" == *"Workflow-Type: push"* ]] || \
  fail "failed PR close should leave remote history published"

rc=$(run_capture "$TMPDIR/pushup-close-retry.out" env \
  GITHUB_ACTOR=testapprover FAKE_GH_LOG="$FAKE_GH_LOG" \
  FAKE_GH_STATE_DIR="$FAKE_GH_STATE_DIR" FAKE_GH_FAIL_CLOSE_ONCE=true \
  FAKE_PUSHUP_SOURCE=dev/retry-v1.0.0 FAKE_PUSHUP_TARGET=v1.0.0 \
  FAKE_PUSHUP_SOURCE_TIP=2222222222222222222222222222222222222222 \
  PATH="$PUSHUP_BIN:$PATH" \
  bash -c "cd '$PUSHUP_WORK' && bash ./briteRepo/bin/push -t 5")
[[ "$rc" -eq 0 ]] || fail "no-change PR close retry should succeed (got $rc)"
assert_contains "Finalized pull request" "$TMPDIR/pushup-close-retry.out"
[[ "$(grep -Fc 'pr comment 43' "$FAKE_GH_LOG")" -eq 1 ]] || \
  fail "PR close retry should not duplicate its publication comment"

rc=$(run_capture "$TMPDIR/pushup-closed-noop.out" env \
  GITHUB_ACTOR=testapprover FAKE_GH_LOG="$FAKE_GH_LOG" \
  FAKE_GH_STATE_DIR="$FAKE_GH_STATE_DIR" \
  FAKE_PUSHUP_SOURCE=dev/retry-v1.0.0 FAKE_PUSHUP_TARGET=v1.0.0 \
  FAKE_PUSHUP_SOURCE_TIP=2222222222222222222222222222222222222222 \
  PATH="$PUSHUP_BIN:$PATH" \
  bash -c "cd '$PUSHUP_WORK' && bash ./briteRepo/bin/push -t 5")
[[ "$rc" -eq 10 ]] || fail "closed pushup no-work push should exit 10 (got $rc)"
pass "pushup PR finalization recovery"

# Approval changed after pushup blocks protected-parent push before publication.
(
  cd "$PUSHUP_WORK"
  echo stale > stale.txt
  git add stale.txt
  git commit -m "stale approval result" >/dev/null 2>&1
  source briteRepo/helpers/history_log.sh
  bt_record_workflow_event "pushup" "v1.0.0" "pushup" \
    "Merged dev/stale-v1.0.0 into v1.0.0" HEAD \
    "Source-Branch" "dev/stale-v1.0.0" \
    "Source-Tip" "3333333333333333333333333333333333333333" \
    "Target-Branch" "v1.0.0" "PR" "44"
)
touch "$FAKE_GH_STATE_DIR/stale-44"
stale_remote_before="$(git --git-dir="$PUSHUP_ORIGIN" rev-parse \
  refs/heads/v1.0.0)"
rc=$(run_capture "$TMPDIR/pushup-stale-approval.out" env \
  GITHUB_ACTOR=testcontributor FAKE_GH_LOG="$FAKE_GH_LOG" \
  FAKE_GH_STATE_DIR="$FAKE_GH_STATE_DIR" \
  FAKE_PUSHUP_SOURCE=dev/stale-v1.0.0 FAKE_PUSHUP_TARGET=v1.0.0 \
  FAKE_PUSHUP_SOURCE_TIP=3333333333333333333333333333333333333333 \
  PATH="$PUSHUP_BIN:$PATH" \
  bash -c "cd '$PUSHUP_WORK' && bash ./briteRepo/bin/push -t 5")
[[ "$rc" -eq 202 ]] || fail "stale approval push should exit 202 (got $rc)"
assert_contains "no longer approved for the source commit" \
  "$TMPDIR/pushup-stale-approval.out"
[[ "$(git --git-dir="$PUSHUP_ORIGIN" rev-parse refs/heads/v1.0.0)" == \
  "$stale_remote_before" ]] || \
  fail "stale approval must not update the protected parent"
pass "stale approval blocks protected parent push"

# A competing parent update is rejected atomically with recovery guidance.
(
  cd "$PUSHUP_WORK"
  source briteRepo/helpers/history_log.sh
  bt_record_workflow_event "pushup" "v1.0.0" "pushup" \
    "Merged dev/race-v1.0.0 into v1.0.0" HEAD \
    "Source-Branch" "dev/race-v1.0.0" \
    "Source-Tip" "4444444444444444444444444444444444444444" \
    "Target-Branch" "v1.0.0" "PR" "45"
)
cat > "$PUSHUP_ORIGIN/hooks/pre-receive" <<'EOF'
#!/usr/bin/env bash
while read -r _old _new ref; do
  if [[ "$ref" == "refs/heads/v1.0.0" ]]; then
    echo "remote parent changed (fetch first)" >&2
    exit 1
  fi
done
exit 0
EOF
chmod +x "$PUSHUP_ORIGIN/hooks/pre-receive"
rc=$(run_capture "$TMPDIR/pushup-parent-race.out" env \
  GITHUB_ACTOR=testcontributor FAKE_GH_LOG="$FAKE_GH_LOG" \
  FAKE_GH_STATE_DIR="$FAKE_GH_STATE_DIR" \
  FAKE_PUSHUP_SOURCE=dev/race-v1.0.0 FAKE_PUSHUP_TARGET=v1.0.0 \
  FAKE_PUSHUP_SOURCE_TIP=4444444444444444444444444444444444444444 \
  PATH="$PUSHUP_BIN:$PATH" \
  bash -c "cd '$PUSHUP_WORK' && bash ./briteRepo/bin/push -t 5")
[[ "$rc" -eq 200 ]] || fail "competing parent push should exit 200 (got $rc)"
assert_contains "Remote parent branch 'v1.0.0' changed" \
  "$TMPDIR/pushup-parent-race.out"
assert_contains "run pulldown, obtain approval for the updated source commit" \
  "$TMPDIR/pushup-parent-race.out"
rm -f "$PUSHUP_ORIGIN/hooks/pre-receive"
pass "competing parent push gives safe retry guidance"

# 11) Non-dry push should fail with 200 and write a failed push report.
cat > "$ORIGIN/hooks/pre-receive" <<'EOF'
#!/usr/bin/env bash
while read -r _old _new ref; do
  if [[ "$ref" == "refs/heads/dev/push-tests-v1.0.0" ]]; then
    echo "rejected by test hook: README.md policy violation" >&2
    exit 1
  fi
done
exit 0
EOF
chmod +x "$ORIGIN/hooks/pre-receive"

(
  cd "$WORK"
  echo "push failure report path" >> README.md
  git add README.md
  git commit -m "push failure report test" >/dev/null 2>&1
)
remote_branch_before="$(git --git-dir="$ORIGIN" rev-parse \
  refs/heads/dev/push-tests-v1.0.0)"
remote_notes_before="$(git --git-dir="$ORIGIN" rev-parse \
  refs/notes/briteRepo-remote-workflow)"
rc=$(run_capture "$TMPDIR/push-fail.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/push -t 5")
[[ "$rc" -eq 200 ]] || fail "push should exit 200 when remote rejects push (got $rc)"
[[ "$(git --git-dir="$ORIGIN" rev-parse \
  refs/heads/dev/push-tests-v1.0.0)" == "$remote_branch_before" ]] || \
  fail "rejected atomic push should not update the remote branch"
[[ "$(git --git-dir="$ORIGIN" rev-parse \
  refs/notes/briteRepo-remote-workflow)" == "$remote_notes_before" ]] || \
  fail "rejected atomic push should not update remote workflow history"
assert_contains "Failed to push branch 'dev/push-tests-v1.0.0' to remote" "$TMPDIR/push-fail.out"
assert_contains "rejected by test hook: README.md policy violation" "$TMPDIR/push-fail.out"
push_error_report="$(latest_report "$WORK" 'push-e-*.md')"
[[ -f "$push_error_report" ]] || fail "expected failed push report"
assert_contains "# Error Push Report" "$push_error_report"
if grep -Fq "**Push Tip:**" "$push_error_report"; then
  fail "push error report should not include internal Push Tip metadata"
fi
assert_contains "**Command:**" "$push_error_report"
assert_contains "**Branch:** \`dev/push-tests-v1.0.0\`" "$push_error_report"
assert_contains "**Commits:**" "$push_error_report"
assert_contains "**Error:**" "$push_error_report"
assert_contains "**Guidance:**" "$push_error_report"
assert_contains "<summary>Files</summary>" "$push_error_report"
assert_contains "| **File** | **Commit** | **Added** | **Deleted** | **Net** | **Lines** | **Action** |" "$push_error_report"
assert_contains "| **Total** |" "$push_error_report"
assert_contains "| \`README.md\` |" "$push_error_report"
assert_contains "## Push Issue Attribution" "$push_error_report"
assert_contains "Push output references the following file(s):" "$push_error_report"
assert_contains "## Push Error Output" "$push_error_report"
assert_contains "rejected by test hook: README.md policy violation" "$push_error_report"
assert_contains "## Guidance" "$push_error_report"
assert_contains "Remote policy/hook rejected this push" "$push_error_report"
assert_contains "Push is atomic for this branch update" "$push_error_report"
rm -f "$ORIGIN/hooks/pre-receive"
pass "failed push report"

# 12) Failed push report should fall back to group-level attribution when
# push output does not name specific files.
cat > "$ORIGIN/hooks/pre-receive" <<'EOF'
#!/usr/bin/env bash
while read -r _old _new ref; do
  if [[ "$ref" == "refs/heads/dev/push-tests-v1.0.0" ]]; then
    echo "policy rejection without file context" >&2
    exit 1
  fi
done
exit 0
EOF
chmod +x "$ORIGIN/hooks/pre-receive"

(
  cd "$WORK"
  mkdir -p src
  echo "push group-level failure" > src/group_scope.txt
  git add src/group_scope.txt
  git commit -m "push group-level failure test" >/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/push-fail-group.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/push -t 5")
[[ "$rc" -eq 200 ]] || fail "push should exit 200 for group-level failure (got $rc)"
push_error_report_group="$(latest_report "$WORK" 'push-e-*.md')"
[[ -f "$push_error_report_group" ]] || fail "expected failed push report for group-level failure"
assert_contains "# Error Push Report" "$push_error_report_group"
assert_contains "<summary>Files</summary>" "$push_error_report_group"
assert_contains "| **File** | **Commit** | **Added** | **Deleted** | **Net** | **Lines** | **Action** |" "$push_error_report_group"
assert_contains "| \`src/group_scope.txt\` |" "$push_error_report_group"
assert_contains "| **Total** |" "$push_error_report_group"
assert_contains "**Error:**" "$push_error_report_group"
assert_contains "**Guidance:**" "$push_error_report_group"
assert_contains "## Push Issue Attribution" "$push_error_report_group"
assert_contains "Push failed as a group-level operation. No specific file could be identified" "$push_error_report_group"
assert_contains "## Push Error Output" "$push_error_report_group"
assert_contains "policy rejection without file context" "$push_error_report_group"
assert_contains "## Guidance" "$push_error_report_group"
assert_contains "Remote policy/hook rejected this push" "$push_error_report_group"
assert_contains "Push is atomic for this branch update" "$push_error_report_group"
rm -f "$ORIGIN/hooks/pre-receive"
pass "group-level failed push attribution"

# 13) Non-dry push should succeed even when remote report directory is absent.
(
  cd "$WORK"
  echo "push report failure path" >> README.md
  git add README.md
  git commit -m "push report failure test" >/dev/null 2>&1
)
rm -rf "$ORIGIN/reports"
rc=$(run_capture "$TMPDIR/report-fail.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/push -t 5")
[[ "$rc" -eq 0 ]] || fail "push should not depend on remote report directory and exit 0 (got $rc)"
assert_contains "Pushed " "$TMPDIR/report-fail.out"
assert_contains "Pushed (" "$TMPDIR/report-fail.out"
assert_contains "to remote dev/push-tests-v1.0.0:" "$TMPDIR/report-fail.out"
if grep -Fq "See reports/push-" "$TMPDIR/report-fail.out"; then
  fail "successful non-dry push should not output a report path"
fi
if find "$WORK/reports" -maxdepth 1 -type f -name 'push-*.md' -print -quit | grep -q .; then
  fail "successful non-dry push should not create a push report"
fi
pass "push success remains independent of remote report directory"

# 14) Dry-run report should handle unusual file deltas (rename/delete/binary)
# in file summary output.
(
  cd "$WORK"
  echo "seed for rename" > edge_rename_source.txt
  git add edge_rename_source.txt
  git commit -m "edge seed for unusual deltas" >/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/edge-seed-push.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/push -t 5")
[[ "$rc" -eq 0 ]] || fail "edge seed push should exit 0 (got $rc)"

(
  cd "$WORK"
  git mv edge_rename_source.txt edge_rename_target.txt
  git rm -f README.md >/dev/null 2>&1
  printf '\x00\x01\x02' > edge_binary.bin
  git add edge_binary.bin
  git commit -m "edge unusual delta types" >/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/edge-dry.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/push -d -t 5")
[[ "$rc" -eq 0 ]] || fail "edge dry-run should exit 0 (got $rc)"
edge_report="$(latest_report "$WORK" 'push-d-*.md')"
[[ -f "$edge_report" ]] || fail "expected edge dry-run report"
assert_contains "<summary>Files</summary>" "$edge_report"
assert_matches 'edge_rename_source\.txt.*edge_rename_target\.txt|edge_rename_target\.txt' "$edge_report"
assert_contains "| \`edge_binary.bin\` | \`" "$edge_report"
assert_contains "| 0 | 0 | 0 | 0 |" "$edge_report"
assert_contains "| \`README.md\` |" "$edge_report"
pass "unusual file deltas in report"

echo "All push smoke tests passed."
