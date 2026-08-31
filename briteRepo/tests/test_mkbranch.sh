#!/usr/bin/env bash

# test_mkbranch.sh - smoke tests for briteRepo/bin/mkbranch
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MKBRANCH_SRC="$REPO_ROOT/briteRepo/bin/mkbranch"
COMMON_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/common.sh"
HISTORY_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/history_log.sh"
GIT_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/git_helpers.sh"

pass() {
  echo "PASS: $1"
}

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

run_capture() {
  # Usage: run_capture <outfile> <command...>
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

[[ -f "$MKBRANCH_SRC" ]] || fail "missing script: $MKBRANCH_SRC"
[[ -f "$COMMON_HELPER_SRC" ]] || fail "missing helper: $COMMON_HELPER_SRC"
[[ -f "$HISTORY_HELPER_SRC" ]] || fail "missing helper: $HISTORY_HELPER_SRC"

TMPDIR="$(mktemp -d)"
cleanup() {
  if [[ "${KEEP_TMPDIR:-0}" == "1" ]]; then
    echo "KEEP_TMPDIR=1 preserving test artifacts at: $TMPDIR" >&2
    return 0
  fi
  rm -rf "$TMPDIR"
}
trap cleanup EXIT
export GITHUB_ACTOR="testuser"

ORIGIN="$TMPDIR/origin.git"
WORK="$TMPDIR/work"

git init --bare "$ORIGIN" >/dev/null 2>&1

git clone "$ORIGIN" "$WORK" >/dev/null 2>&1

mkdir -p "$WORK/briteRepo/bin" "$WORK/briteRepo/helpers" "$WORK/config" "$WORK/logs"
cp "$MKBRANCH_SRC" "$WORK/briteRepo/bin/mkbranch"
cp "$COMMON_HELPER_SRC" "$WORK/briteRepo/helpers/common.sh"
cp "$HISTORY_HELPER_SRC" "$WORK/briteRepo/helpers/history_log.sh"
cp "$GIT_HELPER_SRC" "$WORK/briteRepo/helpers/git_helpers.sh"
chmod +x "$WORK/briteRepo/bin/mkbranch"

cat > "$WORK/config/contributors.md" <<'EOF'
- testuser, C
EOF

(
  cd "$WORK"
  git config user.name "Test User Display Name"
  git config user.email "test@example.com"

  echo "seed" > README.md
  git add README.md briteRepo config
  git commit -m "seed repo" >/dev/null 2>&1
  git branch -M main
  git push -u origin main >/dev/null 2>&1

  git checkout -b v1.0.0 >/dev/null 2>&1
  git commit --allow-empty -m "version parent v1.0.0" >/dev/null 2>&1
  git push -u origin v1.0.0 >/dev/null 2>&1
  git checkout main >/dev/null 2>&1

  # local-only parent for local-mode checks
  git checkout -b v2.0.0 >/dev/null 2>&1
  git commit --allow-empty -m "local-only parent v2.0.0" >/dev/null 2>&1
  git checkout main >/dev/null 2>&1

  # local existing branch (not remote)
  git checkout -b dev/local-exists-v1.0.0 v1.0.0 >/dev/null 2>&1
  git checkout main >/dev/null 2>&1

  # remote existing branch
  git checkout -b dev/remote-exists-v1.0.0 v1.0.0 >/dev/null 2>&1
  git push -u origin dev/remote-exists-v1.0.0 >/dev/null 2>&1
  git checkout main >/dev/null 2>&1

  # remote-only parent for remote-mode parent checks
  git checkout -b dev/remote-parent-v1.0.0 v1.0.0 >/dev/null 2>&1
  git push -u origin dev/remote-parent-v1.0.0 >/dev/null 2>&1
  git checkout main >/dev/null 2>&1
  git branch -D dev/remote-parent-v1.0.0 >/dev/null 2>&1
)

# 1) Help output
rc=$(run_capture "$TMPDIR/help.out" bash "$WORK/briteRepo/bin/mkbranch" -h)
[[ "$rc" -eq 0 ]] || fail "mkbranch -h should exit 0"
assert_contains "Usage:" "$TMPDIR/help.out"
pass "help output"

# 2) Local parent missing -> exit 6
rc=$(run_capture "$TMPDIR/local-parent-missing.out" \
  bash "$WORK/briteRepo/bin/mkbranch" dev/new-v3.0.0 v3.0.0)
[[ "$rc" -eq 6 ]] || fail "local parent missing should exit 6 (got $rc)"
assert_contains "Local parent branch 'v3.0.0' does not exist" \
  "$TMPDIR/local-parent-missing.out"
pass "local parent missing exit code"

# 3) Remote parent missing -> exit 7
rc=$(run_capture "$TMPDIR/remote-parent-missing.out" \
  bash "$WORK/briteRepo/bin/mkbranch" -r dev/new-v3.0.0 v3.0.0)
[[ "$rc" -eq 7 ]] || fail "remote parent missing should exit 7 (got $rc)"
assert_contains "Remote parent branch 'v3.0.0' does not exist" \
  "$TMPDIR/remote-parent-missing.out"
pass "remote parent missing exit code"

# 4) Local branch exists -> exit 8
rc=$(run_capture "$TMPDIR/local-exists.out" \
  bash "$WORK/briteRepo/bin/mkbranch" dev/local-exists-v1.0.0 v1.0.0)
[[ "$rc" -eq 8 ]] || fail "local branch exists should exit 8 (got $rc)"
assert_contains "already exists locally" "$TMPDIR/local-exists.out"
pass "local branch exists exit code"

# 5) Remote branch exists -> exit 9
rc=$(run_capture "$TMPDIR/remote-exists.out" \
  bash "$WORK/briteRepo/bin/mkbranch" -r dev/remote-exists-v1.0.0 v1.0.0)
[[ "$rc" -eq 9 ]] || fail "remote branch exists should exit 9 (got $rc)"
assert_contains "already exists on remote" "$TMPDIR/remote-exists.out"
pass "remote branch exists exit code"

# 6) Validate mode reports specific existence exit code (not generic 10)
rc=$(run_capture "$TMPDIR/validate-specific.out" \
  bash "$WORK/briteRepo/bin/mkbranch" -d dev/local-exists-v1.0.0 v1.0.0)
[[ "$rc" -eq 8 ]] || fail "validate local-exists should exit 8 (got $rc)"
pass "validate specific exit code"

# 6b) Contributor branch with optional type prefix should validate
rc=$(run_capture "$TMPDIR/contributor-prefixed.out" \
  bash "$WORK/briteRepo/bin/mkbranch" -d mywork/feature-one dev/local-exists-v1.0.0)
[[ "$rc" -eq 0 ]] || fail "prefixed contributor branch should validate (got $rc)"
assert_contains "can be created" "$TMPDIR/contributor-prefixed.out"
pass "contributor optional prefix format"

# 6c) Successful creation records workflow metadata instead of branch log files.
rc=$(run_capture "$TMPDIR/workflow-note.out" \
  bash "$WORK/briteRepo/bin/mkbranch" dev/workflow-note-v1.0.0 v1.0.0)
[[ "$rc" -eq 0 ]] || fail "mkbranch success should exit 0 (got $rc)"
note="$(git -C "$WORK" notes --ref=briteRepo-workflow show dev/workflow-note-v1.0.0 2>/dev/null || true)"
[[ "$note" == *"Workflow-Type: mkbranch"* ]] || \
  fail "mkbranch should record workflow metadata"
[[ "$note" == *"Workflow-Branch: dev/workflow-note-v1.0.0"* ]] || \
  fail "mkbranch metadata should name the new branch"
[[ "$note" == *"Parent-Branch: v1.0.0"* ]] || \
  fail "mkbranch metadata should record the parent branch"
if find "$WORK/logs" -maxdepth 1 -type f -name '*_history.md' -print -quit | grep -q .; then
  fail "mkbranch should not create branch history log files"
fi
pass "workflow metadata on branch creation"

# 6d) A remote branch requires a parent that exists both locally and remotely.
rc=$(run_capture "$TMPDIR/remote-only-parent.out" \
  bash "$WORK/briteRepo/bin/mkbranch" -r mywork/remote-child \
  dev/remote-parent-v1.0.0)
[[ "$rc" -eq 6 ]] || \
  fail "remote-only parent should fail local parent check (got $rc)"
assert_contains "Local parent branch 'dev/remote-parent-v1.0.0' does not exist" \
  "$TMPDIR/remote-only-parent.out"
if git -C "$WORK" show-ref --verify --quiet \
  refs/remotes/origin/mywork/remote-child; then
  fail "remote child should not be created without a local parent"
fi
pass "remote branch requires local and remote parent"

# 6e) Active pushup participants cannot gain a remote copy mid-workflow.
state_file="$WORK/.git/briteRepo/pushup.state"
mkdir -p "$(dirname "$state_file")"
git config --file "$state_file" pushup.source dev/local-exists-v1.0.0
git config --file "$state_file" pushup.parent v1.0.0
notes_before="$(git -C "$WORK" rev-parse refs/notes/briteRepo-workflow \
  2>/dev/null || true)"
rc=$(run_capture "$TMPDIR/pushup-source-remote.out" \
  bash "$WORK/briteRepo/bin/mkbranch" -r dev/local-exists-v1.0.0 v1.0.0)
[[ "$rc" -eq 5 ]] || \
  fail "active pushup source remote creation should exit 5 (got $rc)"
assert_contains "participating in an unfinished pushup workflow" \
  "$TMPDIR/pushup-source-remote.out"
[[ "$(git -C "$WORK" rev-parse refs/notes/briteRepo-workflow \
  2>/dev/null || true)" == "$notes_before" ]] || \
  fail "blocked remote creation should not change workflow notes"

git config --file "$state_file" pushup.source mywork/pushup-child
git config --file "$state_file" pushup.parent dev/local-exists-v1.0.0
rc=$(run_capture "$TMPDIR/pushup-parent-remote.out" \
  bash "$WORK/briteRepo/bin/mkbranch" -r dev/local-exists-v1.0.0 v1.0.0)
[[ "$rc" -eq 5 ]] || \
  fail "active pushup parent remote creation should exit 5 (got $rc)"
assert_contains "participating in an unfinished pushup workflow" \
  "$TMPDIR/pushup-parent-remote.out"
rm -f "$state_file"
if git -C "$WORK" show-ref --verify --quiet \
  refs/remotes/origin/dev/local-exists-v1.0.0; then
  fail "active pushup participant should remain local-only"
fi
pass "active pushup participants remain local-only"

# 6f) Remote creation and pushup use the same repository lock.
lock_file="$WORK/.git/briteRepo/pushup.lock"
mkdir -p "$(dirname "$lock_file")"
(
  exec 9>"$lock_file"
  flock -n 9
  printf 'locked\n' > "$TMPDIR/pushup-lock-ready"
  while [[ ! -f "$TMPDIR/release-pushup-lock" ]]; do
    read -r -t 0.1 _ </dev/null || true
  done
) &
lock_pid=$!
while [[ ! -f "$TMPDIR/pushup-lock-ready" ]]; do
  read -r -t 0.1 _ </dev/null || true
done
rc=$(run_capture "$TMPDIR/pushup-lock.out" \
  bash "$WORK/briteRepo/bin/mkbranch" -r dev/locked-v1.0.0 v1.0.0)
touch "$TMPDIR/release-pushup-lock"
wait "$lock_pid"
[[ "$rc" -eq 5 ]] || \
  fail "remote creation during active pushup lock should exit 5 (got $rc)"
assert_contains "pushup process is active" "$TMPDIR/pushup-lock.out"
if git -C "$WORK" show-ref --verify --quiet \
  refs/remotes/origin/dev/locked-v1.0.0; then
  fail "lock contention should prevent remote branch creation"
fi
pass "remote creation shares pushup lock"

# 7) Missing helper fails gracefully with exit 5
mv "$WORK/briteRepo/helpers/history_log.sh" \
  "$WORK/briteRepo/helpers/history_log.sh.bak"
rc=$(run_capture "$TMPDIR/missing-helper.out" \
  bash "$WORK/briteRepo/bin/mkbranch" -h)
[[ "$rc" -eq 5 ]] || fail "missing helper should exit 5 (got $rc)"
assert_contains "Required helper not found" "$TMPDIR/missing-helper.out"
mv "$WORK/briteRepo/helpers/history_log.sh.bak" \
  "$WORK/briteRepo/helpers/history_log.sh"
pass "missing helper graceful failure"

# 8) Local creation does not require a configured remote.
(
  cd "$WORK"
  git remote remove origin
)
rc=$(run_capture "$TMPDIR/missing-origin.out" \
  bash "$WORK/briteRepo/bin/mkbranch" dev/new-v2.0.0 v2.0.0)
[[ "$rc" -eq 0 ]] || \
  fail "local creation without origin should exit 0 (got $rc)"
git -C "$WORK" show-ref --verify --quiet refs/heads/dev/new-v2.0.0 || \
  fail "local creation without origin should create the branch"
pass "local creation without remote"

rc=$(run_capture "$TMPDIR/missing-origin-remote.out" \
  bash "$WORK/briteRepo/bin/mkbranch" -r dev/remote-v2.0.0 v2.0.0)
[[ "$rc" -eq 5 ]] || \
  fail "remote creation without origin should exit 5 (got $rc)"
assert_contains "This clone has no remote repository URL" \
  "$TMPDIR/missing-origin-remote.out"
pass "remote creation requires configured remote"

echo "All mkbranch smoke tests passed."
