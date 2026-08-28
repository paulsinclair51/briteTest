#!/usr/bin/env bash

# test_retarget.sh - smoke tests for briteRepo/bin/retarget
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RETARGET_SRC="$REPO_ROOT/briteRepo/bin/retarget"
COMMON_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/common.sh"
GIT_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/git_helpers.sh"
HISTORY_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/history_log.sh"
VALIDATION_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/validation_helpers.sh"
COMMON_UTILS_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/common_utils.sh"
REPORT_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/report_helpers.sh"

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

for dep in bash git grep mktemp; do
  command -v "$dep" >/dev/null 2>&1 || fail "missing required command: $dep"
done

[[ -f "$RETARGET_SRC" ]] || fail "missing script: $RETARGET_SRC"
[[ -f "$COMMON_HELPER_SRC" ]] || fail "missing helper: $COMMON_HELPER_SRC"
[[ -f "$GIT_HELPER_SRC" ]] || fail "missing helper: $GIT_HELPER_SRC"
[[ -f "$HISTORY_HELPER_SRC" ]] || fail "missing helper: $HISTORY_HELPER_SRC"
[[ -f "$VALIDATION_HELPER_SRC" ]] || fail "missing helper: $VALIDATION_HELPER_SRC"
[[ -f "$COMMON_UTILS_HELPER_SRC" ]] || fail "missing helper: $COMMON_UTILS_HELPER_SRC"
[[ -f "$REPORT_HELPER_SRC" ]] || fail "missing helper: $REPORT_HELPER_SRC"

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

git init --bare "$ORIGIN" >/dev/null 2>&1
git clone "$ORIGIN" "$WORK" >/dev/null 2>&1

mkdir -p "$WORK/briteRepo/bin" "$WORK/briteRepo/helpers" "$WORK/config" \
  "$WORK/logs" "$WORK/reports"
cp "$RETARGET_SRC" "$WORK/briteRepo/bin/retarget"
cp "$COMMON_HELPER_SRC" "$WORK/briteRepo/helpers/common.sh"
cp "$GIT_HELPER_SRC" "$WORK/briteRepo/helpers/git_helpers.sh"
cp "$HISTORY_HELPER_SRC" "$WORK/briteRepo/helpers/history_log.sh"
cp "$VALIDATION_HELPER_SRC" "$WORK/briteRepo/helpers/validation_helpers.sh"
cp "$COMMON_UTILS_HELPER_SRC" "$WORK/briteRepo/helpers/common_utils.sh"
cp "$REPORT_HELPER_SRC" "$WORK/briteRepo/helpers/report_helpers.sh"
chmod +x "$WORK/briteRepo/bin/retarget"

cat > "$WORK/config/contributors.md" <<'EOF'
- testapprover, A
- testcontrib, C
EOF

cat > "$WORK/config/version_branch_access.csv" <<'EOF'
version,dev,fix
v1.0.0,open,open
v1.1.0,open,open
EOF

(
  cd "$WORK"
  # Intentionally not the GitHub login to verify auth uses login resolution.
  git config user.name "Approver Display Name"
  git config user.email "approver@example.com"

  echo "seed" > README.md
  echo "# history" > logs/repository_history.md
  printf 'reports/*.md\n!reports/README.md\n' > .gitignore
  echo "# Reports" > reports/README.md
  git add README.md briteRepo config logs reports .gitignore
  git commit -m "seed repo" >/dev/null 2>&1
  git branch -M main
  git push -u origin main >/dev/null 2>&1

  git checkout -b v1.0.0 >/dev/null 2>&1
  git commit --allow-empty -m "version v1.0.0" >/dev/null 2>&1
  git push -u origin v1.0.0 >/dev/null 2>&1

  git checkout -b v1.1.0 main >/dev/null 2>&1
  git commit --allow-empty -m "version v1.1.0" >/dev/null 2>&1
  git push -u origin v1.1.0 >/dev/null 2>&1

  git checkout -b dev/parser-v1.0.0 v1.0.0 >/dev/null 2>&1
  git commit --allow-empty -m "targeted branch" >/dev/null 2>&1
  git push -u origin dev/parser-v1.0.0 >/dev/null 2>&1

  git checkout main >/dev/null 2>&1
)

# 1) Help output
rc=$(run_capture "$TMPDIR/help.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/retarget -h")
[[ "$rc" -eq 0 ]] || fail "retarget -h should exit 0 (got $rc)"
assert_contains "Usage:" "$TMPDIR/help.out"
assert_contains "-e" "$TMPDIR/help.out"
assert_contains "-r" "$TMPDIR/help.out"
pass "help output"

copyfix_state_root="$(git -C "$WORK" rev-parse \
  --path-format=absolute --git-common-dir)/briteRepo-copyfix-state"
mkdir -p "$copyfix_state_root/dev/parser-v1.0.0"
rc=$(run_capture "$TMPDIR/copyfix-active.out" env GITHUB_ACTOR=testapprover \
  bash -lc "cd '$WORK' && bash ./briteRepo/bin/retarget -d dev/parser-v1.0.0 v1.1.0")
[[ "$rc" -eq 4 ]] || fail "unfinished copyfix should block retarget (got $rc)"
assert_contains "has an unfinished copyfix operation" \
  "$TMPDIR/copyfix-active.out"
rm -rf "$copyfix_state_root"
pass "unfinished copyfix blocks retarget"

# 2) Explicit error mode should write a report without retargeting.
rc=$(run_capture "$TMPDIR/error-run.out" bash -lc \
  "cd '$WORK' && bash ./briteRepo/bin/retarget -e dev/parser-v1.0.0 v1.1.0")
[[ "$rc" -eq 6 ]] || fail "retarget -e should exit 6 (got $rc)"
assert_contains "Retarget skipped due to -e option" "$TMPDIR/error-run.out"
assert_contains "See reports/retarget-e-" "$TMPDIR/error-run.out"
error_report="$(find "$WORK/reports" -maxdepth 1 -type f \
  -name 'retarget-e-*.md' -print -quit)"
[[ -f "$error_report" ]] || fail "expected retarget error report"
assert_contains '**Branch:** `dev/parser-v1.0.0`' "$error_report"
pass "explicit error-run report"

rc=$(run_capture "$TMPDIR/mode-conflict.out" bash -lc \
  "cd '$WORK' && bash ./briteRepo/bin/retarget -d -e")
[[ "$rc" -eq 1 ]] || fail "retarget -d -e should exit 1 (got $rc)"
assert_contains "mutually exclusive" "$TMPDIR/mode-conflict.out"
pass "dry-run and error-run conflict"

# 3) Unauthorized user should be blocked (permission denied exit code).
rc=$(run_capture "$TMPDIR/unauth.out" env GITHUB_ACTOR=testcontrib bash -lc "cd '$WORK' && bash ./briteRepo/bin/retarget -d dev/parser-v1.0.0 v1.1.0")
[[ "$rc" -eq 2 ]] || fail "unauthorized retarget should exit 2 (got $rc)"
assert_contains "is not an approver" "$TMPDIR/unauth.out"
pass "authorization enforcement"

# 3) Missing version policy should map to policy-denied exit code.
cat > "$WORK/config/version_branch_access.csv" <<'EOF'
version,dev,fix
v1.0.0,open,open
EOF
rc=$(run_capture "$TMPDIR/policy-missing.out" env GITHUB_ACTOR=testapprover bash -lc "cd '$WORK' && bash ./briteRepo/bin/retarget -d dev/parser-v1.0.0 v1.1.0")
[[ "$rc" -eq 3 ]] || fail "missing access policy should exit 3 (got $rc)"
assert_contains "has no access policy" "$TMPDIR/policy-missing.out"
pass "missing policy exit mapping"

# Restore policy and verify dry-run success under login-based auth.
cat > "$WORK/config/version_branch_access.csv" <<'EOF'
version,dev,fix
v1.0.0,open,open
v1.1.0,open,open
EOF

# 4) Authorized dry-run should succeed using login identity resolution.
rc=$(run_capture "$TMPDIR/dry-run.out" env GITHUB_ACTOR=testapprover bash -lc "cd '$WORK' && bash ./briteRepo/bin/retarget -d dev/parser-v1.0.0 v1.1.0")
[[ "$rc" -eq 0 ]] || fail "authorized dry-run retarget should exit 0 (got $rc)"
assert_contains "Dry-run passed" "$TMPDIR/dry-run.out"
assert_contains "Rebase preview: git rebase origin/v1.1.0" "$TMPDIR/dry-run.out"
pass "dry-run success with login identity"

# 5) Successful retarget should remain local and record details for report.
remote_tip_before="$(git -C "$ORIGIN" rev-parse refs/heads/dev/parser-v1.0.0)"
rc=$(run_capture "$TMPDIR/success.out" env GITHUB_ACTOR=testapprover \
  bash -lc "cd '$WORK' && bash ./briteRepo/bin/retarget -c 'move parser' dev/parser-v1.0.0 v1.1.0")
[[ "$rc" -eq 0 ]] || fail "retarget should exit 0 (got $rc)"
assert_contains "Local retarget complete" "$TMPDIR/success.out"
assert_contains \
  "Run chbranch dev/parser-v1.0.0, then run report for local details." \
  "$TMPDIR/success.out"
assert_contains "Run retarget -r dev/parser-v1.0.0 v1.1.0 when ready to update origin." \
  "$TMPDIR/success.out"
remote_tip_after="$(git -C "$ORIGIN" rev-parse refs/heads/dev/parser-v1.0.0)"
[[ "$remote_tip_after" == "$remote_tip_before" ]] || \
  fail "retarget without -r should not update origin"
retarget_note="$(git -C "$WORK" notes --ref=briteRepo-workflow show \
  dev/parser-v1.0.0)"
[[ "$retarget_note" == *"Workflow-Type: retarget"* ]] || \
  fail "retarget should record its workflow type"
[[ "$retarget_note" == *"Command-Line: retarget -c move\\ parser dev/parser-v1.0.0 v1.1.0"* ]] || \
  fail "retarget should record its command line"
[[ "$retarget_note" == *"Old-Parent: v1.0.0"* ]] || \
  fail "retarget should record its old parent"
[[ "$retarget_note" == *"New-Parent: v1.1.0"* ]] || \
  fail "retarget should record its new parent"
[[ "$retarget_note" == *"Retargeted-Tip: "* ]] || \
  fail "retarget should record its rewritten tip"
[[ "$retarget_note" == *"Comment: move parser"* ]] || \
  fail "retarget should record its comment"
pass "successful local retarget history"

# 6) A rejected -r publication should change neither remote ref and should be
# retryable without duplicating local or remote history.
cat > "$ORIGIN/hooks/pre-receive" <<'EOF'
#!/usr/bin/env bash
while read -r _old _new ref; do
  if [[ "$ref" == "refs/heads/dev/parser-v1.0.0" ]]; then
    echo "rejected by retarget test hook" >&2
    exit 1
  fi
done
exit 0
EOF
chmod +x "$ORIGIN/hooks/pre-receive"
remote_tip_before="$(git -C "$ORIGIN" rev-parse \
  refs/heads/dev/parser-v1.0.0)"
remote_notes_before="$(git --git-dir="$ORIGIN" rev-parse \
  refs/notes/briteRepo-remote-workflow 2>/dev/null || true)"
local_event_count_before="$(printf '%s\n' "$retarget_note" | \
  grep -Fc -- 'Workflow-Type: retarget')"
rc=$(run_capture "$TMPDIR/remote-rejected.out" env GITHUB_ACTOR=testapprover \
  bash -lc "cd '$WORK' && bash ./briteRepo/bin/retarget -r dev/parser-v1.0.0 v1.1.0")
[[ "$rc" -eq 4 ]] || fail "rejected retarget -r should exit 4 (got $rc)"
[[ "$(git -C "$ORIGIN" rev-parse refs/heads/dev/parser-v1.0.0)" == \
  "$remote_tip_before" ]] || \
  fail "rejected retarget should not update the remote branch"
[[ "$(git --git-dir="$ORIGIN" rev-parse \
  refs/notes/briteRepo-remote-workflow 2>/dev/null || true)" == \
  "$remote_notes_before" ]] || \
  fail "rejected retarget should not update remote workflow history"
local_retry_note="$(git -C "$WORK" notes --ref=briteRepo-workflow show \
  dev/parser-v1.0.0)"
[[ "$(printf '%s\n' "$local_retry_note" | \
  grep -Fc -- 'Workflow-Type: retarget')" -eq "$local_event_count_before" ]] || \
  fail "rejected retarget retry should not duplicate local history"
rm -f "$ORIGIN/hooks/pre-receive"

# 7) -r should publish the already-retargeted local branch after rejection.
rc=$(run_capture "$TMPDIR/remote-success.out" env GITHUB_ACTOR=testapprover \
  bash -lc "cd '$WORK' && bash ./briteRepo/bin/retarget -r dev/parser-v1.0.0 v1.1.0")
[[ "$rc" -eq 0 ]] || fail "retarget -r should exit 0 (got $rc)"
assert_contains "Retarget complete locally and on origin" "$TMPDIR/remote-success.out"
remote_tip_after="$(git -C "$ORIGIN" rev-parse refs/heads/dev/parser-v1.0.0)"
local_tip="$(git -C "$WORK" rev-parse dev/parser-v1.0.0)"
[[ "$remote_tip_after" == "$local_tip" ]] || \
  fail "retarget -r should update origin to the local retargeted tip"
remote_retarget_note="$(git --git-dir="$ORIGIN" notes \
  --ref=briteRepo-remote-workflow show "$local_tip" 2>/dev/null || true)"
[[ "$remote_retarget_note" == *"Workflow-Type: retarget"* ]] || \
  fail "retarget -r should publish remote workflow history"
[[ "$(printf '%s\n' "$remote_retarget_note" | \
  grep -Fc -- 'Workflow-Type: retarget')" -eq 1 ]] || \
  fail "retarget retry should publish one remote history event"
pass "atomic remote retarget publication and retry"

echo "All retarget smoke tests passed."
