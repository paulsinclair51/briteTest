#!/usr/bin/env bash

# test_chbranch.sh - smoke tests for scripts/bin/chbranch
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CHBRANCH_SRC="$REPO_ROOT/scripts/bin/chbranch"
COMMON_HELPER_SRC="$REPO_ROOT/scripts/helpers/common.sh"
GIT_HELPER_SRC="$REPO_ROOT/scripts/helpers/git_helpers.sh"
HISTORY_HELPER_SRC="$REPO_ROOT/scripts/helpers/history_log.sh"

pass() {
  echo "PASS: $1"
}

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

run_in_work_capture() {
  # Usage: run_in_work_capture <outfile> <args...>
  local outfile="$1"
  shift
  set +e
  (
    cd "$WORK"
    bash "$WORK/scripts/bin/chbranch" "$@"
  ) >"$outfile" 2>&1
  local rc=$?
  set -e
  echo "$rc"
}

run_in_work_capture_streams() {
  # Usage: run_in_work_capture_streams <stdout> <stderr> <args...>
  local stdout_file="$1"
  local stderr_file="$2"
  shift 2
  set +e
  (
    cd "$WORK"
    bash "$WORK/scripts/bin/chbranch" "$@"
  ) >"$stdout_file" 2>"$stderr_file"
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
  local pattern="$1"
  local file="$2"
  grep -Eq -- "$pattern" "$file" || fail "expected pattern '$pattern' in $file"
}

for dep in bash git grep mktemp timeout; do
  command -v "$dep" >/dev/null 2>&1 || fail "missing required command: $dep"
done

REAL_GIT="$(command -v git)"
REAL_TIMEOUT="$(command -v timeout)"

[[ -f "$CHBRANCH_SRC" ]] || fail "missing script: $CHBRANCH_SRC"
[[ -f "$COMMON_HELPER_SRC" ]] || fail "missing helper: $COMMON_HELPER_SRC"
[[ -f "$GIT_HELPER_SRC" ]] || fail "missing helper: $GIT_HELPER_SRC"
[[ -f "$HISTORY_HELPER_SRC" ]] || fail "missing helper: $HISTORY_HELPER_SRC"

TMPDIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

ORIGIN="$TMPDIR/origin.git"
WORK="$TMPDIR/work"

git init --bare "$ORIGIN" >/dev/null 2>&1
git clone "$ORIGIN" "$WORK" >/dev/null 2>&1

mkdir -p "$WORK/scripts/bin" "$WORK/scripts/helpers"
cp "$CHBRANCH_SRC" "$WORK/scripts/bin/chbranch"
cp "$COMMON_HELPER_SRC" "$WORK/scripts/helpers/common.sh"
cp "$GIT_HELPER_SRC" "$WORK/scripts/helpers/git_helpers.sh"
cp "$HISTORY_HELPER_SRC" "$WORK/scripts/helpers/history_log.sh"
chmod +x "$WORK/scripts/bin/chbranch"

(
  cd "$WORK"
  git config user.name "testuser"
  git config user.email "test@example.com"

  echo "seed" > README.md
  git add README.md scripts
  git commit -m "seed repo" >/dev/null 2>&1
  git branch -M main
  git push -u origin main >/dev/null 2>&1
  git branch v1.0.0 main
  git branch v1.0.1 main

  git checkout -b dev/local-only main >/dev/null 2>&1
  git checkout main >/dev/null 2>&1

  git checkout -b dev/target main >/dev/null 2>&1
  git push -u origin dev/target >/dev/null 2>&1
  git checkout dev/local-only >/dev/null 2>&1

  git checkout -b dev/remote-only main >/dev/null 2>&1
  git push -u origin dev/remote-only >/dev/null 2>&1
  git checkout dev/local-only >/dev/null 2>&1
  git branch -D dev/remote-only >/dev/null 2>&1

  git checkout -b dev/invalid-v1.0.1 main >/dev/null 2>&1
  git push -u origin dev/invalid-v1.0.1 >/dev/null 2>&1
  git checkout dev/local-only >/dev/null 2>&1
  git branch -D dev/invalid-v1.0.1 >/dev/null 2>&1
)

# 1) Help output
rc=$(run_in_work_capture "$TMPDIR/help.out" -h)
[[ "$rc" -eq 0 ]] || fail "chbranch -h should exit 0"
assert_contains "Usage:" "$TMPDIR/help.out"
assert_contains "Status tags:" "$TMPDIR/help.out"
assert_contains "[local only]" "$TMPDIR/help.out"
assert_contains "[remote only]" "$TMPDIR/help.out"
assert_contains "[invalid name]" "$TMPDIR/help.out"
assert_contains "[diverged from remote: N/M]" "$TMPDIR/help.out"
assert_contains "[ahead of parent by N]" "$TMPDIR/help.out"
assert_contains "[behind parent by N]" "$TMPDIR/help.out"
assert_contains "[diverged from parent: N/M]" "$TMPDIR/help.out"
assert_contains "[parent: NAME]" "$TMPDIR/help.out"
assert_contains "[parent unavailable: NAME]" "$TMPDIR/help.out"
assert_matches '^[[:space:]]*8[[:space:]]+Running outside a Git repository\.$' \
  "$TMPDIR/help.out"
assert_matches '^[[:space:]]*9[[:space:]]+Required command is not available \(git or timeout\)\.$' \
  "$TMPDIR/help.out"
pass "help output"

# Help takes precedence over repository and argument validation.
mkdir -p "$TMPDIR/not-a-repo"
set +e
(
  cd "$TMPDIR/not-a-repo"
  bash "$CHBRANCH_SRC" --badopt --help
) >"$TMPDIR/help-precedence.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "--help should exit 0 outside a repository"
assert_contains "Usage:" "$TMPDIR/help-precedence.out"
pass "help precedence"

# Argument validation -> exit 1.
rc=$(run_in_work_capture "$TMPDIR/unknown.out" --badopt)
[[ "$rc" -eq 1 ]] || fail "unknown option should exit 1 (got $rc)"
assert_contains "Unknown option" "$TMPDIR/unknown.out"
rc=$(run_in_work_capture "$TMPDIR/invalid-timeout.out" -t 0 dev/target)
[[ "$rc" -eq 1 ]] || fail "invalid timeout should exit 1 (got $rc)"
assert_contains "integer greater than 0" "$TMPDIR/invalid-timeout.out"
rc=$(run_in_work_capture "$TMPDIR/mutually-exclusive.out" -l -r dev/target)
[[ "$rc" -eq 1 ]] || fail "-l with -r should exit 1 (got $rc)"
assert_contains "mutually exclusive" "$TMPDIR/mutually-exclusive.out"
rc=$(run_in_work_capture "$TMPDIR/invalid-branch.out" 'bad..branch')
[[ "$rc" -eq 1 ]] || fail "invalid branch name should exit 1 (got $rc)"
assert_contains "Invalid branch name" "$TMPDIR/invalid-branch.out"
pass "argument validation"

# Help/status use stdout; errors use stderr.
rc=$(run_in_work_capture_streams "$TMPDIR/stream-error.out" \
  "$TMPDIR/stream-error.err" --badopt)
[[ "$rc" -eq 1 ]] || fail "stream error test should exit 1 (got $rc)"
assert_contains "Usage:" "$TMPDIR/stream-error.out"
assert_contains "Unknown option" "$TMPDIR/stream-error.err"
if grep -Fq "Unknown option" "$TMPDIR/stream-error.out"; then
  fail "argument error should not be written to stdout"
fi
pass "error output stream"

# Selecting the current local branch is a successful no-op.
rc=$(run_in_work_capture "$TMPDIR/current-local.out" dev/local-only)
[[ "$rc" -eq 0 ]] || fail "current local branch should exit 0 (got $rc)"
assert_contains "Changed to dev/local-only branch." \
  "$TMPDIR/current-local.out"
assert_contains "[local only] [current]" \
  "$TMPDIR/current-local.out"
rc=$(run_in_work_capture_streams "$TMPDIR/stream-success.out" \
  "$TMPDIR/stream-success.err" dev/local-only)
[[ "$rc" -eq 0 ]] || fail "stream success test should exit 0 (got $rc)"
assert_contains "Changed to dev/local-only branch." \
  "$TMPDIR/stream-success.out"
[[ ! -s "$TMPDIR/stream-success.err" ]] || \
  fail "successful selection should not write to stderr"
pass "current local branch"

# Omitting BRANCH defaults to the current local branch.
rc=$(run_in_work_capture "$TMPDIR/implicit-current.out")
[[ "$rc" -eq 0 ]] || fail "implicit current branch should exit 0 (got $rc)"
assert_contains "Changed to dev/local-only branch." \
  "$TMPDIR/implicit-current.out"
pass "implicit current branch"

# Missing branches use mode-specific exits.
rc=$(run_in_work_capture "$TMPDIR/missing-default.out" zz-missing-branch)
[[ "$rc" -eq 3 ]] || fail "missing branch should exit 3 (got $rc)"
assert_contains "does not exist and was not found on origin" \
  "$TMPDIR/missing-default.out"
rc=$(run_in_work_capture "$TMPDIR/missing-local.out" -l zz-missing-branch)
[[ "$rc" -eq 4 ]] || fail "missing local branch should exit 4 (got $rc)"
assert_contains "Local branch 'zz-missing-branch' does not exist" \
  "$TMPDIR/missing-local.out"
rc=$(run_in_work_capture "$TMPDIR/missing-remote.out" -r dev/local-only)
[[ "$rc" -eq 5 ]] || fail "missing remote branch should exit 5 (got $rc)"
assert_contains "Remote branch 'origin/dev/local-only' does not exist" \
  "$TMPDIR/missing-remote.out"
pass "missing branch exits"

# Dirty worktree blocks an actual switch but not a current-branch no-op.
echo "dirty" >> "$WORK/README.md"
rc=$(run_in_work_capture "$TMPDIR/dirty-switch.out" dev/target)
[[ "$rc" -eq 2 ]] || fail "dirty switch should exit 2 (got $rc)"
assert_contains "has uncommitted changes" "$TMPDIR/dirty-switch.out"
rc=$(run_in_work_capture "$TMPDIR/dirty-current.out" dev/local-only)
[[ "$rc" -eq 0 ]] || fail "dirty current branch should exit 0 (got $rc)"
assert_contains "[local only] [current] [uncommitted]" \
  "$TMPDIR/dirty-current.out"
(
  cd "$WORK"
  git restore README.md
)
pass "dirty worktree handling"

# Local mode switches to a writable local branch.
rc=$(run_in_work_capture "$TMPDIR/local-success.out" -l dev/target)
[[ "$rc" -eq 0 ]] || fail "local switch should exit 0 (got $rc)"
assert_contains "Changed to dev/target branch." \
  "$TMPDIR/local-success.out"
assert_contains "[local] [current]" "$TMPDIR/local-success.out"
[[ "$(git -C "$WORK" symbolic-ref --short HEAD)" == "dev/target" ]] || \
  fail "expected local branch dev/target"
pass "local branch switch"

# Parent tags compare the selected commit with its policy-defined parent.
(
  cd "$WORK"
  git branch dev/parent-behind-v1.0.0 v1.0.0
  git switch -c dev/parent-relation-v1.0.0 v1.0.0 >/dev/null 2>&1
  git commit --allow-empty -m "advance selected branch" >/dev/null 2>&1
  git push origin v1.0.0 dev/parent-relation-v1.0.0 >/dev/null 2>&1
)
rc=$(run_in_work_capture "$TMPDIR/parent-ahead.out" \
  dev/parent-relation-v1.0.0)
[[ "$rc" -eq 0 ]] || fail "parent-ahead selection should exit 0 (got $rc)"
assert_contains "[ahead of parent by 1]" "$TMPDIR/parent-ahead.out"
assert_contains "[parent: v1.0.0]" "$TMPDIR/parent-ahead.out"
(
  cd "$WORK"
  git switch v1.0.0 >/dev/null 2>&1
  git commit --allow-empty -m "advance parent branch" >/dev/null 2>&1
)
# Remote selection compares with the remote parent, not a newer local parent.
rc=$(run_in_work_capture "$TMPDIR/remote-parent.out" -r \
  dev/parent-relation-v1.0.0)
[[ "$rc" -eq 0 ]] || fail "remote-parent selection should exit 0 (got $rc)"
assert_contains "[parent: v1.0.0] [ahead of parent by 1]" \
  "$TMPDIR/remote-parent.out"
git -C "$WORK" push origin --delete v1.0.0 \
  dev/parent-relation-v1.0.0 >/dev/null 2>&1
rc=$(run_in_work_capture "$TMPDIR/parent-behind.out" \
  dev/parent-behind-v1.0.0)
[[ "$rc" -eq 0 ]] || fail "parent-behind selection should exit 0 (got $rc)"
assert_contains "[behind parent by 1]" "$TMPDIR/parent-behind.out"
rc=$(run_in_work_capture "$TMPDIR/parent-diverged.out" \
  dev/parent-relation-v1.0.0)
[[ "$rc" -eq 0 ]] || fail "parent-diverged selection should exit 0 (got $rc)"
assert_contains "[diverged from parent: 1/1]" \
  "$TMPDIR/parent-diverged.out"
(
  cd "$WORK"
  git switch dev/target >/dev/null 2>&1
  git branch -D dev/parent-behind-v1.0.0 \
    dev/parent-relation-v1.0.0 >/dev/null 2>&1
  git branch -f v1.0.0 main >/dev/null 2>&1
)
pass "parent relationship status"

# A policy-resolved parent can be named even when its ref is unavailable.
(
  cd "$WORK"
  git branch dev/missing-parent-v2.0.0 main
)
rc=$(run_in_work_capture "$TMPDIR/parent-unavailable.out" \
  dev/missing-parent-v2.0.0)
[[ "$rc" -eq 0 ]] || \
  fail "unavailable-parent selection should exit 0 (got $rc)"
assert_contains "[parent unavailable: v2.0.0]" \
  "$TMPDIR/parent-unavailable.out"
git -C "$WORK" switch dev/target >/dev/null 2>&1
git -C "$WORK" branch -D dev/missing-parent-v2.0.0 >/dev/null 2>&1
pass "unavailable parent status"

# Uncommitted worktree state takes precedence over commit synchronization.
echo "uncommitted tracked change" >> "$WORK/README.md"
rc=$(run_in_work_capture "$TMPDIR/local-uncommitted.out" dev/target)
[[ "$rc" -eq 0 ]] || fail "uncommitted current branch should exit 0 (got $rc)"
assert_contains "[local] [current] [uncommitted]" \
  "$TMPDIR/local-uncommitted.out"
for internal_status in staged unstaged; do
  if grep -Fq "[$internal_status]" "$TMPDIR/local-uncommitted.out"; then
    fail "output should not expose $internal_status status"
  fi
done
git -C "$WORK" restore README.md
pass "uncommitted status precedence"

# Local selection remains available when remote status cannot be refreshed.
(
  cd "$WORK"
  git switch dev/local-only >/dev/null 2>&1
  git remote set-url origin "$TMPDIR/missing-status-origin.git"
)
rc=$(run_in_work_capture "$TMPDIR/local-offline.out" dev/local-only)
[[ "$rc" -eq 0 ]] || fail "offline local selection should exit 0 (got $rc)"
assert_contains "Changed to dev/local-only branch." \
  "$TMPDIR/local-offline.out"
assert_contains "[local] [current] [offline]" "$TMPDIR/local-offline.out"
git -C "$WORK" remote set-url origin "$ORIGIN"
pass "local offline status indicator"

rc=$(run_in_work_capture "$TMPDIR/local-target-setup.out" dev/target)
[[ "$rc" -eq 0 ]] || fail "remote mode setup should exit 0 (got $rc)"

# Remote mode refreshes origin and checks out the remote branch detached.
rc=$(run_in_work_capture "$TMPDIR/remote-success.out" -r dev/target)
[[ "$rc" -eq 0 ]] || fail "remote switch should exit 0 (got $rc)"
assert_contains "Changed to dev/target branch." \
  "$TMPDIR/remote-success.out"
assert_contains "[remote snapshot] [current] [read-only]" \
  "$TMPDIR/remote-success.out"
[[ -z "$(git -C "$WORK" symbolic-ref -q --short HEAD || true)" ]] || \
  fail "expected detached HEAD in remote mode"
pass "remote branch switch"

# Refreshing the current remote snapshot requires a clean worktree.
NO_REMOTE_BIN="$TMPDIR/no-remote-bin"
REMOTE_CALL_MARKER="$TMPDIR/dirty-remote-call"
mkdir -p "$NO_REMOTE_BIN"
cat > "$NO_REMOTE_BIN/git" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "ls-remote" || "$1" == "fetch" ]]; then
  : > "${REMOTE_CALL_MARKER:?}"
  exit 99
fi
exec "${REAL_GIT:?}" "$@"
EOF
chmod +x "$NO_REMOTE_BIN/git"
echo "dirty remote snapshot" >> "$WORK/README.md"
set +e
(
  cd "$WORK"
  PATH="$NO_REMOTE_BIN:$PATH" REAL_GIT="$REAL_GIT" \
    REMOTE_CALL_MARKER="$REMOTE_CALL_MARKER" \
    bash "$WORK/scripts/bin/chbranch" -r dev/target
) >"$TMPDIR/dirty-current-remote.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 2 ]] || \
  fail "dirty current remote snapshot should exit 2 (got $rc)"
assert_contains "changes that have not been committed" \
  "$TMPDIR/dirty-current-remote.out"
[[ ! -e "$REMOTE_CALL_MARKER" ]] || \
  fail "dirty remote selection should not query or fetch the remote"
(
  cd "$WORK"
  git restore README.md
)
pass "dirty remote snapshot refresh blocked"

# Re-selecting a remote snapshot refreshes the remote ref and moves HEAD when
# the remote branch has advanced.
(
  cd "$WORK"
  git switch dev/target >/dev/null 2>&1
  git commit --allow-empty -m "advance remote snapshot" >/dev/null 2>&1
  advanced_remote_tip="$(git rev-parse HEAD)"
  git push origin dev/target >/dev/null 2>&1
  git switch --detach HEAD^ >/dev/null 2>&1
  printf '%s\n' "$advanced_remote_tip" > "$TMPDIR/advanced-remote-tip"
)
rc=$(run_in_work_capture "$TMPDIR/remote-refresh.out" -r dev/target)
[[ "$rc" -eq 0 ]] || fail "remote refresh should exit 0 (got $rc)"
[[ "$(git -C "$WORK" rev-parse HEAD)" == \
  "$(cat "$TMPDIR/advanced-remote-tip")" ]] || \
  fail "expected refreshed snapshot to match the advanced remote tip"
pass "existing remote snapshot refresh"

# A rewritten remote branch should still refresh the remote snapshot instead
# of being misclassified as unreachable.
(
  cd "$WORK"
  stale_remote_tip="$(git rev-parse refs/remotes/origin/dev/target)"
  git switch dev/target >/dev/null 2>&1
  git reset --hard main >/dev/null 2>&1
  git commit --allow-empty -m "rewrite remote snapshot" >/dev/null 2>&1
  rewritten_remote_tip="$(git rev-parse HEAD)"
  git push --force origin dev/target >/dev/null 2>&1
  git update-ref refs/remotes/origin/dev/target "$stale_remote_tip"
  git switch --detach refs/remotes/origin/dev/target >/dev/null 2>&1
  printf '%s\n' "$rewritten_remote_tip" > "$TMPDIR/rewritten-remote-tip"
)
rc=$(run_in_work_capture "$TMPDIR/remote-rewrite.out" -r dev/target)
[[ "$rc" -eq 0 ]] || fail "remote rewrite refresh should exit 0 (got $rc)"
[[ "$(git -C "$WORK" rev-parse HEAD)" == \
  "$(cat "$TMPDIR/rewritten-remote-tip")" ]] || \
  fail "expected refreshed snapshot to match the rewritten remote tip"
pass "rewritten remote snapshot refresh"

# Resolving an omitted branch from a uniquely identifiable detached snapshot
# must not update remembered state until the requested selection succeeds.
(
  cd "$WORK"
  git config --local --unset-all chbranch.lastBranch >/dev/null 2>&1 || true
)
echo "dirty failed selection" >> "$WORK/README.md"
rc=$(run_in_work_capture "$TMPDIR/failed-implicit.out")
[[ "$rc" -eq 2 ]] || fail "dirty implicit switch should exit 2 (got $rc)"
if git -C "$WORK" config --local --get chbranch.lastBranch >/dev/null 2>&1; then
  fail "failed branch selection should not update remembered branch state"
fi
(
  cd "$WORK"
  git restore README.md
)
pass "remember branch only after success"

# Default mode falls back to a remote-only branch and remains detached.
rc=$(run_in_work_capture "$TMPDIR/default-remote-only.out" dev/remote-only)
[[ "$rc" -eq 0 ]] || fail "default remote-only switch should exit 0 (got $rc)"
assert_contains "Changed to dev/remote-only branch." \
  "$TMPDIR/default-remote-only.out"
assert_contains "[remote only] [current] [read-only]" \
  "$TMPDIR/default-remote-only.out"
[[ -z "$(git -C "$WORK" symbolic-ref -q --short HEAD || true)" ]] || \
  fail "expected detached HEAD for default remote-only branch"
[[ "$(git -C "$WORK" rev-parse HEAD)" == \
  "$(git -C "$WORK" rev-parse refs/remotes/origin/dev/remote-only)" ]] || \
  fail "expected HEAD to match origin/dev/remote-only"
pass "default remote-only branch switch"

# Protected local branches remain attached in explicit local mode.
rc=$(run_in_work_capture "$TMPDIR/protected-success.out" -l main)
[[ "$rc" -eq 0 ]] || fail "protected local switch should exit 0 (got $rc)"
assert_contains "Changed to main branch." \
  "$TMPDIR/protected-success.out"
if grep -Fq "[parent" "$TMPDIR/protected-success.out"; then
  fail "main should not output a parent status"
fi
[[ "$(git -C "$WORK" symbolic-ref -q --short HEAD || true)" == "main" ]] || \
  fail "expected attached HEAD for protected local branch"
pass "protected branch policy"

# Default mode is local-first and keeps a protected local branch attached.
rc=$(run_in_work_capture "$TMPDIR/protected-default.out" dev/target)
[[ "$rc" -eq 0 ]] || fail "setup switch should exit 0 (got $rc)"
rc=$(run_in_work_capture "$TMPDIR/protected-default.out" main)
[[ "$rc" -eq 0 ]] || \
  fail "default protected switch should exit 0 (got $rc)"
assert_contains "Changed to main branch." \
  "$TMPDIR/protected-default.out"
[[ "$(git -C "$WORK" symbolic-ref -q --short HEAD || true)" == "main" ]] || \
  fail "expected attached HEAD for default protected branch"
pass "default protected branch policy"

# Protected version branches remain attached in default local mode.
rc=$(run_in_work_capture "$TMPDIR/version-setup.out" dev/target)
[[ "$rc" -eq 0 ]] || fail "version setup switch should exit 0 (got $rc)"
rc=$(run_in_work_capture "$TMPDIR/version-protected.out" v1.0.0)
[[ "$rc" -eq 0 ]] || fail "version branch should exit 0 (got $rc)"
assert_contains "Changed to v1.0.0 branch." \
  "$TMPDIR/version-protected.out"
[[ "$(git -C "$WORK" symbolic-ref -q --short HEAD || true)" == "v1.0.0" ]] || \
  fail "expected attached HEAD for protected version branch"
pass "version branch policy"

# Clean protected local branches fast-forward when their remote advances.
PROTECTED_PEER="$TMPDIR/protected-peer"
git clone "$ORIGIN" "$PROTECTED_PEER" >/dev/null 2>&1
(
  cd "$PROTECTED_PEER"
  git config user.name "remote-testuser"
  git config user.email "remote-test@example.com"
  git checkout main >/dev/null 2>&1
  echo "remote protected update" > PROTECTED_REMOTE.md
  git add PROTECTED_REMOTE.md
  git commit -m "advance protected remote" >/dev/null 2>&1
  git push origin main >/dev/null 2>&1
  git rev-parse HEAD > "$TMPDIR/protected-remote-tip"
)
rc=$(run_in_work_capture "$TMPDIR/remote-ahead-local.out" -r main)
[[ "$rc" -eq 0 ]] || fail "remote-ahead selection should exit 0 (got $rc)"
assert_contains "[ahead of local by 1]" "$TMPDIR/remote-ahead-local.out"
rc=$(run_in_work_capture "$TMPDIR/protected-refresh.out" main)
[[ "$rc" -eq 0 ]] || fail "protected refresh should exit 0 (got $rc)"
[[ "$(git -C "$WORK" rev-parse main)" == \
  "$(cat "$TMPDIR/protected-remote-tip")" ]] || \
  fail "protected local branch should fast-forward to origin/main"
assert_contains "[local] [current] [read-only]" \
  "$TMPDIR/protected-refresh.out"
pass "protected local branch refresh"

# A dirty current protected branch is rejected before refresh.
echo "dirty protected branch" >> "$WORK/README.md"
protected_tip_before="$(git -C "$WORK" rev-parse main)"
rc=$(run_in_work_capture "$TMPDIR/protected-dirty.out" main)
[[ "$rc" -eq 2 ]] || fail "dirty protected selection should exit 2 (got $rc)"
assert_contains "has uncommitted changes" "$TMPDIR/protected-dirty.out"
[[ "$(git -C "$WORK" rev-parse main)" == "$protected_tip_before" ]] || \
  fail "dirty protected branch should remain unchanged"
git -C "$WORK" restore README.md
pass "dirty protected branch handling"

# A protected branch ahead of its remote remains unchanged.
(
  cd "$WORK"
  git commit --allow-empty -m "local protected advance" >/dev/null 2>&1
)
protected_tip_before="$(git -C "$WORK" rev-parse main)"
rc=$(run_in_work_capture_streams "$TMPDIR/protected-ahead.out" \
  "$TMPDIR/protected-ahead.err" main)
[[ "$rc" -eq 0 ]] || fail "ahead protected selection should exit 0 (got $rc)"
assert_contains "was not refreshed because it is ahead of origin/main" \
  "$TMPDIR/protected-ahead.out"
assert_contains "[ahead of remote by 1]" "$TMPDIR/protected-ahead.out"
[[ ! -s "$TMPDIR/protected-ahead.err" ]] || \
  fail "non-fatal refresh warning should not be written to stderr"
[[ "$(git -C "$WORK" rev-parse main)" == "$protected_tip_before" ]] || \
  fail "ahead protected branch should remain unchanged"
rc=$(run_in_work_capture "$TMPDIR/remote-behind-local.out" -r main)
[[ "$rc" -eq 0 ]] || fail "remote-behind selection should exit 0 (got $rc)"
assert_contains "[behind local by 1]" "$TMPDIR/remote-behind-local.out"
rc=$(run_in_work_capture "$TMPDIR/restore-ahead-local.out" -l main)
[[ "$rc" -eq 0 ]] || fail "restore ahead local should exit 0 (got $rc)"
pass "ahead protected refresh warning"

# A protected branch diverged from its remote remains unchanged.
(
  cd "$PROTECTED_PEER"
  git pull --ff-only origin main >/dev/null 2>&1
  echo "diverged remote update" > PROTECTED_DIVERGED.md
  git add PROTECTED_DIVERGED.md
  git commit -m "diverge protected remote" >/dev/null 2>&1
  git push origin main >/dev/null 2>&1
)
protected_tip_before="$(git -C "$WORK" rev-parse main)"
rc=$(run_in_work_capture "$TMPDIR/protected-diverged.out" main)
[[ "$rc" -eq 0 ]] || \
  fail "diverged protected selection should exit 0 (got $rc)"
assert_contains "was not refreshed because it has diverged from origin/main" \
  "$TMPDIR/protected-diverged.out"
assert_contains "[diverged from remote: 1/1]" \
  "$TMPDIR/protected-diverged.out"
[[ "$(git -C "$WORK" rev-parse main)" == "$protected_tip_before" ]] || \
  fail "diverged protected branch should remain unchanged"
rc=$(run_in_work_capture "$TMPDIR/remote-diverged-local.out" -r main)
[[ "$rc" -eq 0 ]] || fail "remote diverged selection should exit 0 (got $rc)"
assert_contains "[diverged from local: 1/1]" \
  "$TMPDIR/remote-diverged-local.out"
rc=$(run_in_work_capture "$TMPDIR/restore-diverged-local.out" -l main)
[[ "$rc" -eq 0 ]] || fail "restore diverged local should exit 0 (got $rc)"
pass "diverged protected refresh warning"

# Missing and unreachable protected remotes warn without failing selection.
rc=$(run_in_work_capture "$TMPDIR/protected-missing.out" v1.0.0)
[[ "$rc" -eq 0 ]] || fail "missing protected remote should exit 0 (got $rc)"
assert_contains "was not refreshed because origin/v1.0.0 does not exist" \
  "$TMPDIR/protected-missing.out"
git -C "$WORK" remote set-url origin "$TMPDIR/missing-protected-origin.git"
rc=$(run_in_work_capture "$TMPDIR/protected-unreachable.out" v1.0.0)
[[ "$rc" -eq 0 ]] || \
  fail "unreachable protected remote should exit 0 (got $rc)"
assert_contains "was not refreshed because the remote is not reachable" \
  "$TMPDIR/protected-unreachable.out"
assert_contains "[offline]" "$TMPDIR/protected-unreachable.out"
git -C "$WORK" remote set-url origin "$ORIGIN"
pass "protected remote availability warnings"

# A protected refresh timeout warns and leaves the branch selected.
PROTECTED_TIMEOUT_BIN="$TMPDIR/protected-timeout-bin"
mkdir -p "$PROTECTED_TIMEOUT_BIN"
cat > "$PROTECTED_TIMEOUT_BIN/timeout" <<'EOF'
#!/usr/bin/env bash
for arg in "$@"; do
  if [[ "$arg" == "ls-remote" ]]; then
    exit 124
  fi
done
exec "${REAL_TIMEOUT:?}" "$@"
EOF
chmod +x "$PROTECTED_TIMEOUT_BIN/timeout"
set +e
(
  cd "$WORK"
  PATH="$PROTECTED_TIMEOUT_BIN:$PATH" REAL_TIMEOUT="$REAL_TIMEOUT" \
    bash "$WORK/scripts/bin/chbranch" -t 1 v1.0.0
) > "$TMPDIR/protected-timeout.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "protected refresh timeout should exit 0 (got $rc)"
assert_contains "was not refreshed because the remote request timed out" \
  "$TMPDIR/protected-timeout.out"
assert_contains "[offline]" "$TMPDIR/protected-timeout.out"
pass "protected refresh timeout warning"

# Restore the disposable main branch fixture for subsequent policy tests.
(
  cd "$WORK"
  git switch dev/target >/dev/null 2>&1
  git branch -f main origin/main >/dev/null 2>&1
)

# A failed fast-forward operation warns and preserves the selected local tip.
(
  cd "$PROTECTED_PEER"
  git pull --ff-only origin main >/dev/null 2>&1
  echo "failed update remote" > PROTECTED_UPDATE_FAILED.md
  git add PROTECTED_UPDATE_FAILED.md
  git commit -m "advance remote for failed update" >/dev/null 2>&1
  git push origin main >/dev/null 2>&1
)
protected_tip_before="$(git -C "$WORK" rev-parse main)"
PROTECTED_UPDATE_BIN="$TMPDIR/protected-update-bin"
mkdir -p "$PROTECTED_UPDATE_BIN"
cat > "$PROTECTED_UPDATE_BIN/git" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "merge" ]]; then
  exit 1
fi
exec "${REAL_GIT:?}" "$@"
EOF
chmod +x "$PROTECTED_UPDATE_BIN/git"
set +e
(
  cd "$WORK"
  PATH="$PROTECTED_UPDATE_BIN:$PATH" REAL_GIT="$REAL_GIT" \
    bash "$WORK/scripts/bin/chbranch" main
) > "$TMPDIR/protected-update-failed.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "failed protected update should exit 0 (got $rc)"
assert_contains "was not refreshed because the fast-forward update failed" \
  "$TMPDIR/protected-update-failed.out"
assert_contains "[behind remote by 1]" \
  "$TMPDIR/protected-update-failed.out"
[[ "$(git -C "$WORK" symbolic-ref --short HEAD)" == "main" ]] || \
  fail "failed protected update should leave main selected"
[[ "$(git -C "$WORK" rev-parse main)" == "$protected_tip_before" ]] || \
  fail "failed protected update should preserve the local tip"
(
  cd "$WORK"
  git switch dev/target >/dev/null 2>&1
  git branch -f main origin/main >/dev/null 2>&1
)
pass "protected refresh update-failure warning"

# Existing policy-invalid local branches can be inspected only as detached.
rc=$(run_in_work_capture "$TMPDIR/invalid-local.out" -l v1.0.1)
[[ "$rc" -eq 0 ]] || fail "policy-invalid local branch should exit 0 (got $rc)"
assert_contains "Changed to v1.0.1 branch." "$TMPDIR/invalid-local.out"
assert_contains "[read-only] [invalid name]" "$TMPDIR/invalid-local.out"
[[ -z "$(git -C "$WORK" symbolic-ref -q --short HEAD || true)" ]] || \
  fail "expected detached HEAD for policy-invalid local branch"
[[ "$(git -C "$WORK" rev-parse HEAD)" == \
  "$(git -C "$WORK" rev-parse refs/heads/v1.0.1)" ]] || \
  fail "expected HEAD to match local v1.0.1"
pass "policy-invalid local branch is read-only"

# Existing policy-invalid remote branches can be inspected only as detached.
rc=$(run_in_work_capture "$TMPDIR/invalid-remote.out" -r dev/invalid-v1.0.1)
[[ "$rc" -eq 0 ]] || fail "policy-invalid remote branch should exit 0 (got $rc)"
assert_contains "Changed to dev/invalid-v1.0.1 branch." \
  "$TMPDIR/invalid-remote.out"
assert_contains "[read-only] [invalid name]" "$TMPDIR/invalid-remote.out"
[[ -z "$(git -C "$WORK" symbolic-ref -q --short HEAD || true)" ]] || \
  fail "expected detached HEAD for policy-invalid remote branch"
[[ "$(git -C "$WORK" rev-parse HEAD)" == \
  "$(git -C "$WORK" rev-parse refs/remotes/origin/dev/invalid-v1.0.1)" ]] || \
  fail "expected HEAD to match origin/dev/invalid-v1.0.1"
pass "policy-invalid remote branch is read-only"

# Explicit remote mode keeps protected remote branches detached.
rc=$(run_in_work_capture "$TMPDIR/protected-remote.out" -r main)
[[ "$rc" -eq 0 ]] || fail "protected remote switch should exit 0 (got $rc)"
assert_contains "Changed to main branch." \
  "$TMPDIR/protected-remote.out"
[[ -z "$(git -C "$WORK" symbolic-ref -q --short HEAD || true)" ]] || \
  fail "expected detached HEAD for protected remote branch"
[[ "$(git -C "$WORK" rev-parse HEAD)" == \
  "$(git -C "$WORK" rev-parse refs/remotes/origin/main)" ]] || \
  fail "expected HEAD to match origin/main"
pass "protected remote branch policy"

# A Git switch failure returns the documented runtime exit.
FAKE_GIT_BIN="$TMPDIR/fake-git-bin"
mkdir -p "$FAKE_GIT_BIN"
cat > "$FAKE_GIT_BIN/git" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "switch" ]]; then
  exit 1
fi
exec "${REAL_GIT:?}" "$@"
EOF
chmod +x "$FAKE_GIT_BIN/git"
set +e
(
  cd "$WORK"
  PATH="$FAKE_GIT_BIN:$PATH" REAL_GIT="$REAL_GIT" \
    bash "$WORK/scripts/bin/chbranch" dev/target
) >"$TMPDIR/switch-failure.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 200 ]] || fail "Git switch failure should exit 200 (got $rc)"
assert_contains "Failed to switch to local branch 'dev/target'" \
  "$TMPDIR/switch-failure.out"
pass "Git switch failure exit"

# Default remote mode must verify connectivity even when a cached ref exists.
(
  cd "$WORK"
  git remote set-url origin "$TMPDIR/missing-origin.git"
)
rc=$(run_in_work_capture "$TMPDIR/cached-unreachable.out" dev/remote-only)
[[ "$rc" -eq 6 ]] || \
  fail "cached remote with unreachable origin should exit 6 (got $rc)"
assert_contains "Remote branch is not connected/reachable" \
  "$TMPDIR/cached-unreachable.out"
(
  cd "$WORK"
  current_commit="$(git rev-parse HEAD)"
  main_commit="$(git rev-parse main)"
  [[ "$current_commit" == "$main_commit" ]] || \
    fail "unreachable remote must not change the current branch"
  git remote set-url origin "$ORIGIN"
)
pass "cached remote still requires reachable origin"

# A timeout in either remote phase returns exit 7.
FAKE_BIN="$TMPDIR/fake-bin"
mkdir -p "$FAKE_BIN"
cat > "$FAKE_BIN/timeout" <<'EOF'
#!/usr/bin/env bash
for arg in "$@"; do
  if [[ "$arg" == "ls-remote" && "${FAIL_REMOTE_PHASE:-}" == "lookup" ]]; then
    exit 124
  fi
  if [[ "$arg" == "fetch" && "${FAIL_REMOTE_PHASE:-}" == "fetch" ]]; then
    exit 124
  fi
done
exec "${REAL_TIMEOUT:?}" "$@"
EOF
chmod +x "$FAKE_BIN/timeout"
set +e
(
  cd "$WORK"
  PATH="$FAKE_BIN:$PATH" REAL_TIMEOUT="$REAL_TIMEOUT" \
    FAIL_REMOTE_PHASE=lookup \
    bash "$WORK/scripts/bin/chbranch" -r -t 1 dev/target
) >"$TMPDIR/lookup-timeout.out" 2>&1
lookup_rc=$?
(
  cd "$WORK"
  PATH="$FAKE_BIN:$PATH" REAL_TIMEOUT="$REAL_TIMEOUT" \
    FAIL_REMOTE_PHASE=fetch \
    bash "$WORK/scripts/bin/chbranch" -r -t 1 dev/target
) >"$TMPDIR/fetch-timeout.out" 2>&1
fetch_rc=$?
set -e
[[ "$lookup_rc" -eq 7 ]] || fail "lookup timeout should exit 7"
[[ "$fetch_rc" -eq 7 ]] || fail "fetch timeout should exit 7"
assert_contains "Timeout waiting for remote branch" "$TMPDIR/lookup-timeout.out"
assert_contains "Timeout waiting for remote branch" "$TMPDIR/fetch-timeout.out"
pass "remote timeout exits"

# Running outside a Git repository is a user-context error.
set +e
(
  cd "$TMPDIR/not-a-repo"
  bash "$CHBRANCH_SRC" dev/target
) >"$TMPDIR/not-repo.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 8 ]] || fail "outside repository should exit 8 (got $rc)"
assert_contains "inside a git repository" "$TMPDIR/not-repo.out"
set +e
(
  cd "$TMPDIR/not-a-repo"
  bash "$CHBRANCH_SRC" --badopt
) >"$TMPDIR/not-repo-badopt.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 1 ]] || \
  fail "outside repository invalid option should exit 1 (got $rc)"
assert_contains "Unknown option" "$TMPDIR/not-repo-badopt.out"
pass "outside repository exit"

# Missing required utilities are user-environment errors.
NO_TIMEOUT_BIN="$TMPDIR/no-timeout-bin"
mkdir -p "$NO_TIMEOUT_BIN"
for command_name in dirname git grep head sed tr wc; do
  ln -s "$(command -v "$command_name")" "$NO_TIMEOUT_BIN/$command_name"
done
set +e
(
  cd "$WORK"
  PATH="$NO_TIMEOUT_BIN" /usr/bin/bash \
    "$WORK/scripts/bin/chbranch" -r dev/target
) >"$TMPDIR/missing-timeout.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 9 ]] || fail "missing timeout should exit 9 (got $rc)"
assert_contains "Required command 'timeout' is not available" \
  "$TMPDIR/missing-timeout.out"

NO_GIT_BIN="$TMPDIR/no-git-bin"
mkdir -p "$NO_GIT_BIN"
for command_name in dirname timeout; do
  ln -s "$(command -v "$command_name")" "$NO_GIT_BIN/$command_name"
done
set +e
(
  cd "$WORK"
  PATH="$NO_GIT_BIN" /usr/bin/bash \
    "$WORK/scripts/bin/chbranch" dev/target
) >"$TMPDIR/missing-git.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 9 ]] || fail "missing git should exit 9 (got $rc)"
assert_contains "Required command 'git' is not available" \
  "$TMPDIR/missing-git.out"
pass "required command exit"

echo "All chbranch smoke tests passed."
