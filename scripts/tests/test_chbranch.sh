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

assert_contains() {
  local text="$1"
  local file="$2"
  grep -Fq -- "$text" "$file" || fail "expected '$text' in $file"
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
assert_contains "8   Running outside a Git repository." "$TMPDIR/help.out"
assert_contains "9   Required command is not available (git or timeout)." \
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

# Selecting the current local branch is a successful no-op.
rc=$(run_in_work_capture "$TMPDIR/current-local.out" dev/local-only)
[[ "$rc" -eq 0 ]] || fail "current local branch should exit 0 (got $rc)"
assert_contains "Changed to local dev/local-only branch." \
  "$TMPDIR/current-local.out"
pass "current local branch"

# Omitting BRANCH defaults to the current local branch.
rc=$(run_in_work_capture "$TMPDIR/implicit-current.out")
[[ "$rc" -eq 0 ]] || fail "implicit current branch should exit 0 (got $rc)"
assert_contains "Changed to local dev/local-only branch." \
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
(
  cd "$WORK"
  git restore README.md
)
pass "dirty worktree handling"

# Local mode switches to a writable local branch.
rc=$(run_in_work_capture "$TMPDIR/local-success.out" -l dev/target)
[[ "$rc" -eq 0 ]] || fail "local switch should exit 0 (got $rc)"
assert_contains "Changed to local dev/target branch." \
  "$TMPDIR/local-success.out"
[[ "$(git -C "$WORK" symbolic-ref --short HEAD)" == "dev/target" ]] || \
  fail "expected local branch dev/target"
pass "local branch switch"

# Remote mode refreshes origin and checks out the remote branch detached.
rc=$(run_in_work_capture "$TMPDIR/remote-success.out" -r dev/target)
[[ "$rc" -eq 0 ]] || fail "remote switch should exit 0 (got $rc)"
assert_contains "Changed to remote dev/target branch." \
  "$TMPDIR/remote-success.out"
[[ -z "$(git -C "$WORK" symbolic-ref -q --short HEAD || true)" ]] || \
  fail "expected detached HEAD in remote mode"
pass "remote branch switch"

# Default mode falls back to a remote-only branch and remains detached.
rc=$(run_in_work_capture "$TMPDIR/default-remote-only.out" dev/remote-only)
[[ "$rc" -eq 0 ]] || fail "default remote-only switch should exit 0 (got $rc)"
assert_contains "Changed to remote dev/remote-only branch." \
  "$TMPDIR/default-remote-only.out"
[[ -z "$(git -C "$WORK" symbolic-ref -q --short HEAD || true)" ]] || \
  fail "expected detached HEAD for default remote-only branch"
[[ "$(git -C "$WORK" rev-parse HEAD)" == \
  "$(git -C "$WORK" rev-parse refs/remotes/origin/dev/remote-only)" ]] || \
  fail "expected HEAD to match origin/dev/remote-only"
pass "default remote-only branch switch"

# Protected local branches are checked out detached according to policy.
rc=$(run_in_work_capture "$TMPDIR/protected-success.out" -l main)
[[ "$rc" -eq 0 ]] || fail "protected local switch should exit 0 (got $rc)"
assert_contains "Changed to local main branch." \
  "$TMPDIR/protected-success.out"
[[ -z "$(git -C "$WORK" symbolic-ref -q --short HEAD || true)" ]] || \
  fail "expected detached HEAD for protected local branch"
pass "protected branch policy"

# Default mode also checks out a protected local branch detached.
rc=$(run_in_work_capture "$TMPDIR/protected-default.out" dev/target)
[[ "$rc" -eq 0 ]] || fail "setup switch should exit 0 (got $rc)"
rc=$(run_in_work_capture "$TMPDIR/protected-default.out" main)
[[ "$rc" -eq 0 ]] || \
  fail "default protected switch should exit 0 (got $rc)"
assert_contains "Changed to local main branch." \
  "$TMPDIR/protected-default.out"
[[ -z "$(git -C "$WORK" symbolic-ref -q --short HEAD || true)" ]] || \
  fail "expected detached HEAD for default protected branch"
pass "default protected branch policy"

# Version branches are protected and checked out detached.
rc=$(run_in_work_capture "$TMPDIR/version-setup.out" dev/target)
[[ "$rc" -eq 0 ]] || fail "version setup switch should exit 0 (got $rc)"
rc=$(run_in_work_capture "$TMPDIR/version-protected.out" v1.0.0)
[[ "$rc" -eq 0 ]] || fail "version branch should exit 0 (got $rc)"
assert_contains "Changed to local v1.0.0 branch." \
  "$TMPDIR/version-protected.out"
[[ -z "$(git -C "$WORK" symbolic-ref -q --short HEAD || true)" ]] || \
  fail "expected detached HEAD for protected version branch"
pass "version branch policy"

# Existing policy-invalid local branches can be inspected only as detached.
rc=$(run_in_work_capture "$TMPDIR/invalid-local.out" -l v1.0.1)
[[ "$rc" -eq 0 ]] || fail "policy-invalid local branch should exit 0 (got $rc)"
assert_contains "Changed to local v1.0.1 branch." "$TMPDIR/invalid-local.out"
[[ -z "$(git -C "$WORK" symbolic-ref -q --short HEAD || true)" ]] || \
  fail "expected detached HEAD for policy-invalid local branch"
[[ "$(git -C "$WORK" rev-parse HEAD)" == \
  "$(git -C "$WORK" rev-parse refs/heads/v1.0.1)" ]] || \
  fail "expected HEAD to match local v1.0.1"
pass "policy-invalid local branch is read-only"

# Existing policy-invalid remote branches can be inspected only as detached.
rc=$(run_in_work_capture "$TMPDIR/invalid-remote.out" -r dev/invalid-v1.0.1)
[[ "$rc" -eq 0 ]] || fail "policy-invalid remote branch should exit 0 (got $rc)"
assert_contains "Changed to remote dev/invalid-v1.0.1 branch." \
  "$TMPDIR/invalid-remote.out"
[[ -z "$(git -C "$WORK" symbolic-ref -q --short HEAD || true)" ]] || \
  fail "expected detached HEAD for policy-invalid remote branch"
[[ "$(git -C "$WORK" rev-parse HEAD)" == \
  "$(git -C "$WORK" rev-parse refs/remotes/origin/dev/invalid-v1.0.1)" ]] || \
  fail "expected HEAD to match origin/dev/invalid-v1.0.1"
pass "policy-invalid remote branch is read-only"

# Explicit remote mode keeps protected remote branches detached.
rc=$(run_in_work_capture "$TMPDIR/protected-remote.out" -r main)
[[ "$rc" -eq 0 ]] || fail "protected remote switch should exit 0 (got $rc)"
assert_contains "Changed to remote main branch." \
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
