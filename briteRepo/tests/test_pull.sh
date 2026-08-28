#!/usr/bin/env bash

# test_pull.sh - smoke tests for briteRepo/bin/pull
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PULL_SRC="$REPO_ROOT/briteRepo/bin/pull"
COMMON_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/common.sh"
GIT_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/git_helpers.sh"
HISTORY_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/history_log.sh"
REPORT_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/report_helpers.sh"
REPORT_SYNC_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/report_sync.sh"

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

[[ -f "$PULL_SRC" ]] || fail "missing script: $PULL_SRC"

TMPDIR="$(mktemp -d)"
cleanup() {
  chmod -R u+w "$TMPDIR" 2>/dev/null || true
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

ORIGIN="$TMPDIR/origin.git"
WORK="$TMPDIR/work"
PEER="$TMPDIR/peer"

git init --bare "$ORIGIN" >/dev/null 2>&1
git clone "$ORIGIN" "$WORK" >/dev/null 2>&1
git clone "$ORIGIN" "$PEER" >/dev/null 2>&1

mkdir -p "$WORK/briteRepo/bin" "$WORK/briteRepo/helpers" "$WORK/reports"
cp "$PULL_SRC" "$WORK/briteRepo/bin/pull"
cp "$COMMON_HELPER_SRC" "$WORK/briteRepo/helpers/common.sh"
cp "$GIT_HELPER_SRC" "$WORK/briteRepo/helpers/git_helpers.sh"
cp "$HISTORY_HELPER_SRC" "$WORK/briteRepo/helpers/history_log.sh"
cp "$REPORT_HELPER_SRC" "$WORK/briteRepo/helpers/report_helpers.sh"
cp "$REPORT_SYNC_HELPER_SRC" "$WORK/briteRepo/helpers/report_sync.sh"
chmod +x "$WORK/briteRepo/bin/pull"

(
  cd "$WORK"
  git config user.name "testuser"
  git config user.email "test@example.com"
  echo "seed" > README.md
  mkdir -p reports
  cat > .gitignore <<'GITIGNORE'
reports/branch-*.md
reports/pull-*.md
reports/commit-*.md
GITIGNORE
  git add README.md briteRepo reports .gitignore
  git commit -m "seed repo" >/dev/null 2>&1
  git branch -M main
  git push -u origin main >/dev/null 2>&1
  git checkout -b dev/current-v1.0.0 >/dev/null 2>&1
  git commit --allow-empty -m "current branch" >/dev/null 2>&1
  git push -u origin dev/current-v1.0.0 >/dev/null 2>&1
)

(
  cd "$PEER"
  git config user.name "peeruser"
  git config user.email "peer@example.com"
  git fetch origin >/dev/null 2>&1
  git checkout -b dev/current-v1.0.0 origin/dev/current-v1.0.0 >/dev/null 2>&1
)

rc=$(run_capture "$TMPDIR/help.out" bash "$WORK/briteRepo/bin/pull" -h)
[[ "$rc" -eq 0 ]] || fail "pull -h should exit 0"
assert_contains "Usage:" "$TMPDIR/help.out"
assert_contains "must be a targeted or contributor branch" "$TMPDIR/help.out"
assert_contains "12   Pull skipped because -e was specified." "$TMPDIR/help.out"
pass "help output"

copyfix_state_root="$(git -C "$WORK" rev-parse \
  --path-format=absolute --git-common-dir)/briteRepo-copyfix-state"
mkdir -p "$copyfix_state_root/dev/current-v1.0.0"
rc=$(run_capture "$TMPDIR/copyfix-active.out" \
  bash -lc "cd '$WORK' && bash ./briteRepo/bin/pull")
[[ "$rc" -eq 14 ]] || fail "unfinished copyfix should block pull (got $rc)"
assert_contains "has an unfinished copyfix operation" \
  "$TMPDIR/copyfix-active.out"
rm -rf "$copyfix_state_root"
pass "unfinished copyfix blocks pull"

cat > "$WORK/reports/pull-e-20000101-000000+0000.md" <<'EOF'
# Stale Pull Error Report

**Branch:** `dev/current-v1.0.0`
EOF

(
  cd "$PEER"
  git commit --allow-empty -m "remote error-run update" >/dev/null 2>&1
  git push origin dev/current-v1.0.0 >/dev/null 2>&1
)

rc=$(run_capture "$TMPDIR/skip-e.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/pull -e")
[[ "$rc" -eq 12 ]] || fail "pull -e should exit 12 (got $rc)"
assert_contains "Error: Pull skipped due to -e option." "$TMPDIR/skip-e.out"
assert_contains "Guidance: Run without -e option." "$TMPDIR/skip-e.out"
assert_contains "See reports/pull-e-" "$TMPDIR/skip-e.out"
skip_report="$(find "$WORK/reports" -maxdepth 1 -type f -name 'pull-e-*.md' | sort | tail -n 1)"
[[ -f "$skip_report" ]] || fail "expected pull skip report"
assert_contains '**Branch:** `dev/current-v1.0.0`' "$skip_report"
assert_contains "**Error:** Pull skipped due to -e option." "$skip_report"
assert_contains "## Guidance" "$skip_report"
assert_contains "- Run without -e option." "$skip_report"
[[ ! -e "$WORK/reports/pull-e-20000101-000000+0000.md" ]] || \
  fail "pull -e should delete the older error report for the current branch"
pass "skip mode"

(
  cd "$WORK"
  git fetch origin dev/current-v1.0.0 >/dev/null 2>&1
  git reset --hard origin/dev/current-v1.0.0 >/dev/null 2>&1
)

(
  cd "$WORK"
  git checkout main >/dev/null 2>&1
)
cat > "$WORK/reports/pull-e-20000101-000001+0000.md" <<'EOF'
# Stale Pull Error Report

**Branch:** `main`
EOF
rc=$(run_capture "$TMPDIR/skip-e-policy.out" \
  bash -lc "cd '$WORK' && bash ./briteRepo/bin/pull -e")
[[ "$rc" -eq 4 ]] || fail "pull -e on main should exit 4 (got $rc)"
assert_contains "Current branch 'main' must be a targeted or contributor branch" \
  "$TMPDIR/skip-e-policy.out"
[[ -e "$WORK/reports/pull-e-20000101-000001+0000.md" ]] || \
  fail "pull -e prerequisite failure should not delete reports"
[[ "$(find "$WORK/reports" -maxdepth 1 -type f \
  -name 'pull-e-*.md' | wc -l)" -eq 2 ]] || \
  fail "pull -e prerequisite failure should not generate a report"
rm -f "$WORK/reports/pull-e-20000101-000001+0000.md"
(
  cd "$WORK"
  git checkout dev/current-v1.0.0 >/dev/null 2>&1
)
pass "skip mode requires prerequisites"

rc=$(run_capture "$TMPDIR/arg-reject.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/pull dev/current-v1.0.0")
[[ "$rc" -eq 1 ]] || fail "positional branch argument should exit 1 (got $rc)"
assert_contains "Unexpected argument: dev/current-v1.0.0" "$TMPDIR/arg-reject.out"
pass "positional argument rejected"

rc=$(run_capture "$TMPDIR/not-worktree.out" \
  bash -lc "cd '$TMPDIR' && bash '$WORK/briteRepo/bin/pull'")
[[ "$rc" -eq 200 ]] || fail "pull outside a worktree should exit 200 (got $rc)"
assert_contains "Git failed to determine the current branch" \
  "$TMPDIR/not-worktree.out"
pass "invalid Git context"

(
  cd "$WORK"
  git checkout --detach >/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/detached.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/pull")
[[ "$rc" -eq 3 ]] || fail "pull from detached HEAD should exit 3 (got $rc)"
assert_contains "Current branch must be a local branch" "$TMPDIR/detached.out"
pass "detached HEAD policy"

(
  cd "$WORK"
  git checkout dev/current-v1.0.0 >/dev/null 2>&1
  git checkout main >/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/main-policy.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/pull")
[[ "$rc" -eq 4 ]] || fail "pull on main without owner override should exit 4 (got $rc)"
assert_contains "Current branch 'main' must be a targeted or contributor branch" "$TMPDIR/main-policy.out"
pass "main branch policy"

rc=$(run_capture "$TMPDIR/main-owner-policy.out" env \
  GITHUB_ACTOR=testowner GITHUB_REPOSITORY=testowner/testrepo \
  bash -lc "cd '$WORK' && bash ./briteRepo/bin/pull -o")
[[ "$rc" -eq 5 ]] || fail "pull -o on main should exit 5 (got $rc)"
assert_contains "Current branch 'main' must be a version branch" \
  "$TMPDIR/main-owner-policy.out"
pass "owner override version branch policy"

(
  cd "$WORK"
  git checkout -b v1.0.0 >/dev/null 2>&1
  git push -u origin v1.0.0 >/dev/null 2>&1
)
(
  cd "$PEER"
  git fetch origin v1.0.0 >/dev/null 2>&1
  git checkout -B v1.0.0 origin/v1.0.0 >/dev/null 2>&1
  git commit --allow-empty -m "remote version update" >/dev/null 2>&1
  git push origin v1.0.0 >/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/version-owner.out" env \
  GITHUB_ACTOR=testowner GITHUB_REPOSITORY=testowner/testrepo \
  bash -lc "cd '$WORK' && bash ./briteRepo/bin/pull -o -d")
[[ "$rc" -eq 0 ]] || fail "pull -o on version branch should succeed (got $rc)"
assert_contains "Owner override enabled" "$TMPDIR/version-owner.out"
assert_contains "See reports/pull-d-" "$TMPDIR/version-owner.out"
pass "owner override accepts version branch"

(
  cd "$WORK"
  git checkout dev/current-v1.0.0 >/dev/null 2>&1
)

cat > "$WORK/reports/pull-d-20000101-000000+0000.md" <<'EOF'
# Stale Pull Report

**Branch:** `dev/current-v1.0.0`
EOF
cat > "$WORK/reports/pull-e-20000101-000001+0000.md" <<'EOF'
# Stale Pull Error Report

**Branch:** `dev/current-v1.0.0`
EOF
chmod a-w "$WORK/reports/pull-d-20000101-000000+0000.md" \
  "$WORK/reports/pull-e-20000101-000001+0000.md"
rc=$(run_capture "$TMPDIR/noop.out" \
  bash -lc "cd '$WORK' && bash ./briteRepo/bin/pull")
[[ "$rc" -eq 13 ]] || fail "no-work pull should exit 13 (got $rc)"
assert_contains "no changes to pull" "$TMPDIR/noop.out"
assert_contains "Guidance: rerun pull after remote changes are available." \
  "$TMPDIR/noop.out"
if grep -Fq "See reports/pull-" "$TMPDIR/noop.out"; then
  fail "pull prerequisite failure should not output a report path"
fi
[[ -f "$WORK/reports/pull-d-20000101-000000+0000.md" ]] || \
  fail "pull prerequisite failure should preserve stale dry-run reports"
[[ -f "$WORK/reports/pull-e-20000101-000001+0000.md" ]] || \
  fail "pull prerequisite failure should preserve stale error reports"
pass "no-work pull prerequisite"

(
  cd "$PEER"
  git checkout dev/current-v1.0.0 >/dev/null 2>&1
  git commit --allow-empty -m "remote dry-run update" >/dev/null 2>&1
  git push origin dev/current-v1.0.0 >/dev/null 2>&1
)

rc=$(run_capture "$TMPDIR/dryrun.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/pull -d")
[[ "$rc" -eq 0 ]] || fail "dry-run pull should exit 0 (got $rc)"
assert_contains "Dry-run: no fetch, pull, or branch updates will be performed." "$TMPDIR/dryrun.out"
assert_contains "See reports/pull-d-" "$TMPDIR/dryrun.out"
dryrun_report="$(find "$WORK/reports" -maxdepth 1 -type f \
  -name 'pull-d-*.md' | sort | tail -n 1)"
[[ -f "$dryrun_report" ]] || fail "dry-run pull should create a report"
pass "dry-run output and report"

mkdir -p "$TMPDIR/fake-bin"
cat > "$TMPDIR/fake-bin/timeout" <<'EOF'
#!/usr/bin/env bash
exit 124
EOF
chmod +x "$TMPDIR/fake-bin/timeout"
rc=$(run_capture "$TMPDIR/remote-timeout.out" bash -lc \
  "cd '$WORK' && PATH='$TMPDIR/fake-bin':\$PATH bash ./briteRepo/bin/pull -t 1")
[[ "$rc" -eq 9 ]] || fail "remote timeout should exit 9 (got $rc)"
assert_contains "timed out after 1s" "$TMPDIR/remote-timeout.out"
pass "remote timeout"

(
  cd "$WORK"
  git remote remove origin
)
rc=$(run_capture "$TMPDIR/no-origin.out" \
  bash -lc "cd '$WORK' && bash ./briteRepo/bin/pull")
[[ "$rc" -eq 8 ]] || fail "missing origin should exit 8 (got $rc)"
assert_contains "Remote 'origin' is not configured" "$TMPDIR/no-origin.out"
(
  cd "$WORK"
  git remote add origin "$ORIGIN"
  git fetch origin >/dev/null 2>&1
)
pass "missing origin"

(
  cd "$PEER"
  git checkout dev/current-v1.0.0 >/dev/null 2>&1
  git reset --hard origin/dev/current-v1.0.0 >/dev/null 2>&1
  echo "peer side change" > peer-current.txt
  git add peer-current.txt
  git commit -m "peer current update" >/dev/null 2>&1
  git push origin dev/current-v1.0.0 >/dev/null 2>&1
)
(
  cd "$WORK"
  git checkout dev/current-v1.0.0 >/dev/null 2>&1
  cp "$PULL_SRC" briteRepo/bin/pull
  echo "local side change" > local-current.txt
  git add local-current.txt
  git commit -m "local current update" >/dev/null 2>&1
)
reports_before="$(find "$WORK/reports" -maxdepth 1 -type f \
  -name 'pull-[0-9]*.md' -print | sort)"
rc=$(run_capture "$TMPDIR/diverge-safe.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/pull")
[[ "$rc" -eq 0 ]] || fail "safe divergence should auto-resolve (got $rc)"
assert_contains "auto-resolved divergence" "$TMPDIR/diverge-safe.out"
assert_contains "Run report for details." "$TMPDIR/diverge-safe.out"
reports_after="$(find "$WORK/reports" -maxdepth 1 -type f \
  -name 'pull-[0-9]*.md' -print | sort)"
if [[ "$reports_after" != "$reports_before" ]]; then
  fail "successful pull should not add an immediate pull report"
fi
[[ -f "$WORK/local-current.txt" ]] || fail "expected local-current.txt after auto-resolution"
[[ -f "$WORK/peer-current.txt" ]] || fail "expected peer-current.txt after auto-resolution"
pull_note="$(git -C "$WORK" notes --ref=briteRepo-workflow show HEAD)"
[[ "$pull_note" == *"Workflow-Type: pull"* ]] || \
  fail "successful pull should record its workflow type"
[[ "$pull_note" == *"Command-Line: pull"* ]] || \
  fail "successful pull should record its command line"
pass "safe divergence auto-resolution"

(
  cd "$WORK"
  git reset --hard >/dev/null 2>&1
  git clean -fd >/dev/null 2>&1
  git checkout main >/dev/null 2>&1
  git checkout -b dev/conflict-v1.0.0 >/dev/null 2>&1
  printf 'base\n' > conflict.txt
  git add conflict.txt
  git commit -m "seed conflict branch" >/dev/null 2>&1
  git push -u origin dev/conflict-v1.0.0 >/dev/null 2>&1
)
(
  cd "$PEER"
  git fetch origin >/dev/null 2>&1
  git checkout -b dev/conflict-v1.0.0 origin/dev/conflict-v1.0.0 >/dev/null 2>&1
  printf 'peer\n' > conflict.txt
  git add conflict.txt
  git commit -m "peer conflict edit" >/dev/null 2>&1
  git push origin dev/conflict-v1.0.0 >/dev/null 2>&1
)
(
  cd "$WORK"
  git checkout dev/conflict-v1.0.0 >/dev/null 2>&1
  printf 'local\n' > conflict.txt
  git add conflict.txt
  git commit -m "local conflict edit" >/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/diverge-conflict.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/pull")
[[ "$rc" -eq 10 ]] || fail "conflicting divergence should exit 10 (got $rc)"
assert_contains "requires manual conflict resolution" "$TMPDIR/diverge-conflict.out"
[[ -d "$WORK/.git/rebase-merge" || -d "$WORK/.git/rebase-apply" ]] || fail "expected rebase to remain in progress"
pass "conflicting divergence pauses for manual resolution"

(
  cd "$WORK"
  printf 'peer\nlocal\n' > conflict.txt
  git add conflict.txt
)
reports_before="$(find "$WORK/reports" -maxdepth 1 -type f \
  -name 'pull-[0-9]*.md' -print | sort)"
rc=$(run_capture "$TMPDIR/rebase-rerun.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/pull")
[[ "$rc" -eq 0 ]] || fail "rerun after manual conflict resolution should complete sync (got $rc)"
assert_contains "Completed in-progress rebase" "$TMPDIR/rebase-rerun.out"
assert_contains "Run report for details." "$TMPDIR/rebase-rerun.out"
reports_after="$(find "$WORK/reports" -maxdepth 1 -type f \
  -name 'pull-[0-9]*.md' -print | sort)"
[[ "$reports_after" == "$reports_before" ]] || \
  fail "completed pull rebase should not add an immediate pull report"
[[ ! -d "$WORK/.git/rebase-merge" && ! -d "$WORK/.git/rebase-apply" ]] || fail "expected rebase to be completed"
pass "rerun completes paused rebase"

(
  cd "$WORK"
  git reset --hard >/dev/null 2>&1
  git clean -fd >/dev/null 2>&1
  git checkout dev/current-v1.0.0 >/dev/null 2>&1
  echo "dirty" >> README.md
)
rc=$(run_capture "$TMPDIR/dirty-current.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/pull")
[[ "$rc" -eq 6 ]] || fail "dirty current branch should exit 6 (got $rc)"
assert_contains "Error: Current branch 'dev/current-v1.0.0' has uncommitted changes." "$TMPDIR/dirty-current.out"
assert_contains "Guidance: commit or undo changes, then rerun pull." "$TMPDIR/dirty-current.out"
pass "dirty current branch gate"

(
  cd "$WORK"
  git checkout dev/current-v1.0.0 >/dev/null 2>&1
  git reset --hard >/dev/null 2>&1
  git clean -fd >/dev/null 2>&1
  git checkout -b local-only-current >/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/no-remote-gate.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/pull")
[[ "$rc" -eq 7 ]] || fail "missing remote branch should exit 7 (got $rc)"
assert_contains "Remote branch 'origin/local-only-current' does not exist" "$TMPDIR/no-remote-gate.out"
pass "current branch remote gate"

echo "All pull smoke tests passed."