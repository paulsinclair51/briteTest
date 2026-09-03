#!/usr/bin/env bash

# Focused pushup transaction and resume tests.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

fail() { echo "FAIL: $1" >&2; exit 1; }
assert_contains() { grep -Fq -- "$1" "$2" || fail "expected '$1' in $2"; }
run_capture() {
  local output_file="$1"
  shift
  set +e
  "$@" >"$output_file" 2>&1
  local status=$?
  set -e
  printf '%s\n' "$status"
}

write_state() {
  local phase="$1"
  local source_tip="$2"
  local parent_tip="$3"
  local prepared_tip="${4:-}"
  local state_file="$WORK/.git/briteRepo/pushup.state"

  mkdir -p "$(dirname "$state_file")"
  rm -f "$state_file"
  git config --file "$state_file" pushup.version 2
  git config --file "$state_file" pushup.source feature
  git config --file "$state_file" pushup.parent main
  git config --file "$state_file" pushup.source-tip "$source_tip"
  git config --file "$state_file" pushup.parent-tip "$parent_tip"
  git config --file "$state_file" pushup.timeout 10
  git config --file "$state_file" pushup.verbose false
  git config --file "$state_file" pushup.owner-override false
  git config --file "$state_file" pushup.comment-mode none
  git config --file "$state_file" pushup.command-line pushup
  git config --file "$state_file" pushup.source-has-remote true
  git config --file "$state_file" pushup.parent-has-remote true
  [[ -z "$prepared_tip" ]] || \
    git config --file "$state_file" pushup.prepared-parent-tip "$prepared_tip"
  git config --file "$state_file" pushup.phase "$phase"
}

add_feature_change() {
  local label="$1"
  git -C "$WORK" checkout feature >/dev/null
  printf '%s\n' "$label" >> "$WORK/content.txt"
  git -C "$WORK" commit -am "$label" >/dev/null
  git -C "$WORK" push origin feature >/dev/null
}

prepare_and_publish_parent() {
  git -C "$WORK" checkout main >/dev/null
  git -C "$WORK" merge --squash feature >/dev/null
  git -C "$WORK" commit -m "push up fixture" >/dev/null
  git -C "$WORK" push origin main >/dev/null
}

ORIGIN="$TMPDIR/origin.git"
WORK="$TMPDIR/work"
git init --bare "$ORIGIN" >/dev/null
git init -b main "$WORK" >/dev/null
git -C "$WORK" config user.name "Pushup Test"
git -C "$WORK" config user.email "pushup@example.com"
git -C "$WORK" remote add origin "$ORIGIN"
mkdir -p "$WORK/briteRepo/bin" "$WORK/briteRepo/helpers" "$WORK/reports"
cp "$REPO_ROOT/briteRepo/bin/pushup" "$WORK/briteRepo/bin/pushup"
cp "$REPO_ROOT/briteRepo/helpers/common.sh" \
  "$REPO_ROOT/briteRepo/helpers/git_helpers.sh" \
  "$REPO_ROOT/briteRepo/helpers/report_helpers.sh" \
  "$REPO_ROOT/briteRepo/helpers/history_log.sh" "$WORK/briteRepo/helpers/"
chmod +x "$WORK/briteRepo/bin/pushup"

REAL_TIMEOUT="$(command -v timeout)"
export REAL_TIMEOUT
export PUSHUP_TEST_WORK="$WORK"
mkdir -p "$TMPDIR/bin"
cat > "$TMPDIR/bin/timeout" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$1" >> "$PUSHUP_TEST_WORK/.timeout-calls"
exec "$REAL_TIMEOUT" "$@"
EOF
chmod +x "$TMPDIR/bin/timeout"
export PATH="$TMPDIR/bin:$PATH"

printf 'base\n' > "$WORK/content.txt"
git -C "$WORK" add content.txt
git -C "$WORK" commit -m base >/dev/null
git -C "$WORK" push -u origin main >/dev/null
git -C "$WORK" checkout -b feature >/dev/null
printf 'feature\n' >> "$WORK/content.txt"
git -C "$WORK" commit -am feature >/dev/null
git -C "$WORK" push -u origin feature >/dev/null

cat > "$WORK/briteRepo/helpers/pushup_parent.sh" <<'EOF'
#!/usr/bin/env bash
set -e
dry_run=false
error_run=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d) dry_run=true; shift ;;
    -e) error_run=true; shift ;;
    -t|-c) shift 2 ;;
    -o|-v) shift ;;
    --) shift; break ;;
    *) shift ;;
  esac
done
if [[ "$dry_run" == true ]]; then
  echo "Dry-run: merge to local main: 1 modified file."
  exit 0
fi
if [[ "$error_run" == true ]]; then
  echo "Error: Merge-up skipped due to -e option." >&2
  echo "Guidance: Run without -e option." >&2
  exit 36
fi
git checkout main >/dev/null
git merge --squash feature >/dev/null
git commit -m "pushed up" >/dev/null
EOF
cat > "$WORK/briteRepo/bin/push" <<'EOF'
#!/usr/bin/env bash
set -e
branch="$(git branch --show-current)"
timeout_seconds=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -t) timeout_seconds="$2"; shift 2 ;;
    *) shift ;;
  esac
done
printf 'push-%s %s\n' "$branch" "$timeout_seconds" >> .remote-timeouts
if [[ -f .fail-parent-push && "$branch" == main ]]; then
  exit 80
fi
git push origin "$branch" >/dev/null
if [[ -f .fail-parent-finalize-once && "$branch" == main ]]; then
  rm -f .fail-parent-finalize-once
  exit 202
fi
EOF
cat > "$WORK/briteRepo/helpers/push_command.sh" <<'EOF'
#!/usr/bin/env bash
bt_push_init() {
  PUSH_WORKFLOW_ARGS=()
  PUSH_TIMEOUT_SECONDS=""
  PUSH_ENTRY_MODE="--public"
}
bt_push_run() {
  local branch
  branch="$(git branch --show-current)"
  printf 'push-%s %s\n' "$branch" "$PUSH_TIMEOUT_SECONDS" >> .remote-timeouts
  if [[ -f .fail-parent-push && "$branch" == main ]]; then
    exit 80
  fi
  git push origin "$branch" >/dev/null
  if [[ -f .fail-parent-finalize-once && "$branch" == main ]]; then
    rm -f .fail-parent-finalize-once
    exit 202
  fi
}
EOF
cat > "$WORK/briteRepo/bin/chbranch" <<'EOF'
#!/usr/bin/env bash
git checkout "${@: -1}" >/dev/null
EOF
cat > "$WORK/briteRepo/helpers/pulldown_workflow.sh" <<'EOF'
#!/usr/bin/env bash
bt_pulldown_init() {
  REMOTE_TIMEOUT_SECONDS=""
}
bt_pulldown_run() {
  if [[ -f .fail-sync-once ]]; then
    rm -f .fail-sync-once
    exit 81
  fi
  local state_file parent_has_remote
  state_file="$(git rev-parse --git-path briteRepo/pushup.state)"
  parent_has_remote="$(git config --file "$state_file" --get pushup.parent-has-remote 2>/dev/null || true)"
  if [[ "$parent_has_remote" == false ]]; then
    git merge --no-edit main >/dev/null
  else
    printf 'pulldown %s\n' "$REMOTE_TIMEOUT_SECONDS" >> .remote-timeouts
    git fetch origin main >/dev/null
    git merge --no-edit origin/main >/dev/null
  fi
}
EOF
cat > "$WORK/briteRepo/bin/pull" <<'EOF'
#!/usr/bin/env bash
git pull --rebase origin "$(git branch --show-current)" >/dev/null
EOF
chmod +x "$WORK/briteRepo/bin/"{push,chbranch,pull} \
  "$WORK/briteRepo/helpers/"{pulldown_workflow.sh,push_command.sh,pushup_parent.sh}

source_tip="$(git -C "$WORK" rev-parse feature)"
parent_tip="$(git -C "$WORK" rev-parse main)"
status="$(run_capture "$TMPDIR/dry-run.out" bash -c \
  "cd '$WORK' && ./briteRepo/bin/pushup -d -t 7")"
[[ "$status" -eq 0 ]] || fail "top-level pushup -d should exit 0, got $status"
assert_contains "Dry-run: merge to local main" "$TMPDIR/dry-run.out"
[[ "$(git -C "$WORK" branch --show-current)" == feature ]] || \
  fail "top-level pushup -d should leave source branch checked out"
[[ "$(git -C "$WORK" rev-parse main)" == "$parent_tip" ]] || \
  fail "top-level pushup -d should not change parent tip"
[[ "$(git -C "$WORK" rev-parse feature)" == "$source_tip" ]] || \
  fail "top-level pushup -d should not change source tip"
[[ ! -f "$WORK/.git/briteRepo/pushup.state" ]] || \
  fail "top-level pushup -d should not write pushup state"
echo "PASS: top-level dry-run delegates without state"

status="$(run_capture "$TMPDIR/error-run.out" bash -c \
  "cd '$WORK' && ./briteRepo/bin/pushup -e -t 7")"
[[ "$status" -eq 36 ]] || fail "top-level pushup -e should exit 36, got $status"
assert_contains "Merge-up skipped due to -e option" "$TMPDIR/error-run.out"
[[ "$(git -C "$WORK" branch --show-current)" == feature ]] || \
  fail "top-level pushup -e should leave source branch checked out"
[[ "$(git -C "$WORK" rev-parse main)" == "$parent_tip" ]] || \
  fail "top-level pushup -e should not change parent tip"
[[ "$(git -C "$WORK" rev-parse feature)" == "$source_tip" ]] || \
  fail "top-level pushup -e should not change source tip"
[[ ! -f "$WORK/.git/briteRepo/pushup.state" ]] || \
  fail "top-level pushup -e should not write pushup state"
echo "PASS: top-level error-run delegates without state"

# Local-only contributor/targeted paths update neither remote branch.
git -C "$WORK" update-ref -d refs/remotes/origin/main
git -C "$WORK" update-ref -d refs/remotes/origin/feature
rm -f "$WORK/.remote-timeouts"
status="$(run_capture "$TMPDIR/local-only.out" bash -c \
  "cd '$WORK' && ./briteRepo/bin/pushup")"
[[ "$status" -eq 0 ]] || fail "local-only pushup should exit 0, got $status"
[[ "$(git -C "$WORK" branch --show-current)" == feature ]] || \
  fail "local-only pushup should leave the source branch selected"
git -C "$WORK" diff --quiet feature main || \
  fail "local-only pushup should leave source and parent files matching"
[[ ! -f "$WORK/.git/briteRepo/pushup.state" ]] || \
  fail "local-only pushup should remove completed state"
[[ ! -f "$WORK/.remote-timeouts" ]] || \
  fail "local-only pushup should not call remote push or synchronization"
local_only_parent_tip_short="$(git -C "$WORK" rev-parse --short=7 main)"
assert_contains "Pushed up 'feature' to 'main' (${local_only_parent_tip_short}) locally." \
  "$TMPDIR/local-only.out"
if grep -Fq "and remotely" "$TMPDIR/local-only.out"; then
  fail "local-only pushup should not claim a remote update"
fi
assert_contains "Run report -pl for local parent details." \
  "$TMPDIR/local-only.out"
if grep -Fq "remote parent details" "$TMPDIR/local-only.out"; then
  fail "local-only pushup should not suggest a remote parent report"
fi
git -C "$WORK" fetch origin main feature >/dev/null
git -C "$WORK" checkout feature >/dev/null
git -C "$WORK" reset --hard origin/feature >/dev/null
git -C "$WORK" branch -f main origin/main >/dev/null
echo "PASS: local-only pushup completion"

source_tip="$(git -C "$WORK" rev-parse feature)"
parent_tip="$(git -C "$WORK" rev-parse main)"
touch "$WORK/.fail-parent-push"
status="$(run_capture "$TMPDIR/rollback.out" bash -c \
  "cd '$WORK' && ./briteRepo/bin/pushup -t 7")"
[[ "$status" -eq 4 ]] || fail "pre-publication failure should exit 4, got $status"
[[ "$(git -C "$WORK" branch --show-current)" == feature ]] || \
  fail "rollback should restore source checkout"
[[ "$(git -C "$WORK" rev-parse main)" == "$parent_tip" ]] || \
  fail "rollback should restore parent tip"
[[ "$(git -C "$WORK" rev-parse feature)" == "$source_tip" ]] || \
  fail "rollback should restore source tip"
[[ ! -f "$WORK/.git/briteRepo/pushup.state" ]] || \
  fail "rollback should remove pushup state"
assert_contains "No local push-up changes were retained" "$TMPDIR/rollback.out"
assert_contains "push-main 7" "$WORK/.remote-timeouts"
assert_contains "21s" "$WORK/.timeout-calls"
echo "PASS: pre-publication failure restores local state"

rm -f "$WORK/.fail-parent-push"
touch "$WORK/.fail-parent-finalize-once"
status="$(run_capture "$TMPDIR/finalize-fail.out" bash -c \
  "cd '$WORK' && ./briteRepo/bin/pushup")"
[[ "$status" -eq 5 ]] || fail "PR finalization failure should exit 5, got $status"
[[ "$(git config --file "$WORK/.git/briteRepo/pushup.state" --get pushup.phase)" == \
  parent-finalization-failed ]] || fail "finalization failure phase should be retained"
[[ "$(git -C "$WORK" branch --show-current)" == feature ]] || \
  fail "partial pushup should return to the saved source branch"
assert_contains "parent was updated on the remote" "$TMPDIR/finalize-fail.out"
status="$(run_capture "$TMPDIR/finalize-continue.out" bash -c \
  "cd '$WORK' && ./briteRepo/bin/pushup")"
[[ "$status" -eq 0 ]] || fail "finalization continuation should complete, got $status"
assert_contains "push-main 10" "$WORK/.remote-timeouts"
assert_contains "push-main 30" "$WORK/.remote-timeouts"
assert_contains "pulldown 30" "$WORK/.remote-timeouts"
assert_contains "push-feature 30" "$WORK/.remote-timeouts"
assert_contains "30s" "$WORK/.timeout-calls"
echo "PASS: remote reaccess triples custom and default timeouts"
echo "PASS: published parent with failed finalization resumes safely"

# An incomplete state file must never be guessed at or silently removed.
mkdir -p "$WORK/.git/briteRepo"
git config --file "$WORK/.git/briteRepo/pushup.state" pushup.version 1
status="$(run_capture "$TMPDIR/incomplete-state.out" bash -c \
  "cd '$WORK' && ./briteRepo/bin/pushup")"
[[ "$status" -eq 200 ]] || fail "incomplete state should exit 200, got $status"
[[ -f "$WORK/.git/briteRepo/pushup.state" ]] || fail "incomplete state should be retained"
assert_contains "state is incomplete" "$TMPDIR/incomplete-state.out"
rm -f "$WORK/.git/briteRepo/pushup.state"
echo "PASS: incomplete state fails closed"

source_tip="$(git -C "$WORK" rev-parse feature)"
parent_tip="$(git -C "$WORK" rev-parse main)"
write_state initialized "$source_tip" "$parent_tip"
git config --file "$WORK/.git/briteRepo/pushup.state" \
  --unset pushup.parent-has-remote
status="$(run_capture "$TMPDIR/missing-remote-flag.out" bash -c \
  "cd '$WORK' && ./briteRepo/bin/pushup")"
[[ "$status" -eq 200 ]] || \
  fail "state without a remote-presence flag should exit 200, got $status"
[[ -f "$WORK/.git/briteRepo/pushup.state" ]] || \
  fail "invalid v2 state should be retained for inspection"
assert_contains "state is incomplete" "$TMPDIR/missing-remote-flag.out"
rm -f "$WORK/.git/briteRepo/pushup.state"
echo "PASS: state v2 requires remote-presence flags"

# If origin disappears while a parent push result is uncertain, continuation
# must retain state until remote history can prove whether publication occurred.
add_feature_change "network recovery feature"
source_tip="$(git -C "$WORK" rev-parse feature)"
parent_tip="$(git -C "$WORK" rev-parse main)"
git -C "$WORK" checkout main >/dev/null
git -C "$WORK" merge --squash feature >/dev/null
git -C "$WORK" commit -m "network recovery preparation" >/dev/null
prepared_tip="$(git -C "$WORK" rev-parse main)"
write_state parent-publishing "$source_tip" "$parent_tip" "$prepared_tip"
mv "$ORIGIN" "$ORIGIN.offline"
status="$(run_capture "$TMPDIR/network-offline.out" bash -c \
  "cd '$WORK' && ./briteRepo/bin/pushup")"
[[ "$status" -eq 5 ]] || fail "offline recovery should exit 5, got $status"
[[ -f "$WORK/.git/briteRepo/pushup.state" ]] || \
  fail "offline recovery should retain state"
[[ "$(git config --file "$WORK/.git/briteRepo/pushup.state" \
  --get pushup.phase)" == publication-uncertain ]] || \
  fail "offline recovery should record publication uncertainty"
assert_contains "remote is unavailable" "$TMPDIR/network-offline.out"
mv "$ORIGIN.offline" "$ORIGIN"
status="$(run_capture "$TMPDIR/network-reconnected.out" bash -c \
  "cd '$WORK' && ./briteRepo/bin/pushup")"
[[ "$status" -eq 4 ]] || \
  fail "nonpublication after reconnect should roll back with exit 4, got $status"
[[ ! -f "$WORK/.git/briteRepo/pushup.state" ]] || \
  fail "proven nonpublication should clear state after rollback"
status="$(run_capture "$TMPDIR/network-restart.out" bash -c \
  "cd '$WORK' && ./briteRepo/bin/pushup")"
[[ "$status" -eq 0 ]] || fail "pushup should restart after rollback, got $status"
echo "PASS: network loss retains uncertain state until safe recovery"

# Simulate a hard crash after the helper committed locally but before the
# coordinator changed phase from initialized. Plain pushup must roll back and
# restart because the prepared commit is not remote.
git -C "$WORK" checkout feature >/dev/null
printf 'second feature\n' >> "$WORK/content.txt"
git -C "$WORK" commit -am "second feature" >/dev/null
git -C "$WORK" push origin feature >/dev/null
source_tip="$(git -C "$WORK" rev-parse feature)"
parent_tip="$(git -C "$WORK" rev-parse main)"
state_file="$WORK/.git/briteRepo/pushup.state"
write_state initialized "$source_tip" "$parent_tip"
git -C "$WORK" checkout main >/dev/null
git -C "$WORK" merge --squash feature >/dev/null
git -C "$WORK" commit -m "orphaned preparation" >/dev/null
orphaned_tip="$(git -C "$WORK" rev-parse main)"
status="$(run_capture "$TMPDIR/crash-before-publish.out" bash -c \
  "cd '$WORK' && ./briteRepo/bin/pushup")"
[[ "$status" -eq 0 ]] || fail "plain restart before publication should complete, got $status"
[[ "$(git --git-dir="$ORIGIN" rev-parse main)" != "$orphaned_tip" ]] || \
  fail "orphaned local preparation must not be published"
assert_contains "Recovered an interrupted push-up before its remote update" \
  "$TMPDIR/crash-before-publish.out"
echo "PASS: plain pushup recovers a prepublication hard crash"

git -C "$WORK" checkout feature >/dev/null
printf 'third feature\n' >> "$WORK/content.txt"
git -C "$WORK" commit -am "third feature" >/dev/null
git -C "$WORK" push origin feature >/dev/null
touch "$WORK/.fail-sync-once"
status="$(run_capture "$TMPDIR/partial.out" bash -c \
  "cd '$WORK' && ./briteRepo/bin/pushup")"
[[ "$status" -eq 5 ]] || fail "post-publication failure should exit 5, got $status"
[[ -f "$WORK/.git/briteRepo/pushup.state" ]] || fail "partial run should retain state"
[[ "$(git config --file "$WORK/.git/briteRepo/pushup.state" --get pushup.phase)" == \
  source-sync-failed ]] || fail "partial run should record failed synchronization"
saved_source_version="$(git config --file "$WORK/.git/briteRepo/pushup.state" \
  --get pushup.source-tip)"
saved_parent_version="$(git config --file "$WORK/.git/briteRepo/pushup.state" \
  --get pushup.parent-tip)"
# Earlier scenarios leave their own error reports, so take the newest one.
report="$(ls -t "$WORK/reports"/pushup-e-*.md 2>/dev/null | head -n 1)"
[[ -n "$report" ]] || fail "partial run should write a pushup error report"
assert_contains '| Update parent on remote | Completed |' "$report"
assert_contains '| Synchronize source from parent | Pending |' "$report"
assert_contains '## Saved Branch Versions' "$report"
assert_contains "| Source: \`feature\` | \`$saved_source_version\` |" "$report"
assert_contains "| Parent: \`main\` | \`$saved_parent_version\` |" "$report"
assert_contains 'rerun `pushup`' "$report"
echo "PASS: partial report identifies completed and pending work"

git -C "$WORK" checkout main >/dev/null
status="$(run_capture "$TMPDIR/continue.out" bash -c \
  "cd '$WORK' && ./briteRepo/bin/pushup")"
[[ "$status" -eq 0 ]] || fail "continue should complete pushup, got $status"
[[ "$(git -C "$WORK" branch --show-current)" == feature ]] || \
  fail "continue should reselect the saved source branch"
[[ ! -f "$WORK/.git/briteRepo/pushup.state" ]] || \
  fail "completed pushup should remove state"
[[ "$(git --git-dir="$ORIGIN" rev-parse main)" == "$(git -C "$WORK" rev-parse main)" ]] || \
  fail "parent should be published"
[[ "$(git --git-dir="$ORIGIN" rev-parse feature)" == \
  "$(git -C "$WORK" rev-parse feature)" ]] || fail "source should be published"
published_parent_tip_short="$(git -C "$WORK" rev-parse --short=7 main)"
assert_contains "Pushed up 'feature' to 'main' (${published_parent_tip_short}) locally and remotely." \
  "$TMPDIR/continue.out"
assert_contains "Run report -pl for local parent details; run report -pr for remote parent details." \
  "$TMPDIR/continue.out"
if grep -Eq 'Local merge complete|^Pushed \(' \
  "$TMPDIR/continue.out"; then
  fail "normal pushup output should suppress delegated command summaries"
fi
echo "PASS: plain pushup completes retained work"

# Crash after the atomic parent push but before parent-published was saved.
add_feature_change "fourth feature"
source_tip="$(git -C "$WORK" rev-parse feature)"
parent_tip="$(git -C "$WORK" rev-parse main)"
prepare_and_publish_parent
prepared_tip="$(git -C "$WORK" rev-parse main)"
write_state parent-publishing "$source_tip" "$parent_tip" "$prepared_tip"
status="$(run_capture "$TMPDIR/published-needs-continue.out" bash -c \
  "cd '$WORK' && ./briteRepo/bin/pushup")"
[[ "$status" -eq 0 ]] || \
  fail "plain pushup should resume published parent state, got $status"
echo "PASS: parent publication crash is inferred and resumed automatically"

# Another writer may fast-forward the remote after our parent push succeeds but
# before recovery. The prepared commit's ancestry proves publication even when
# it is no longer the remote tip.
add_feature_change "concurrent parent feature"
source_tip="$(git -C "$WORK" rev-parse feature)"
parent_tip="$(git -C "$WORK" rev-parse main)"
prepare_and_publish_parent
prepared_tip="$(git -C "$WORK" rev-parse main)"
write_state parent-publishing "$source_tip" "$parent_tip" "$prepared_tip"
concurrent="$TMPDIR/concurrent"
git clone --quiet "$ORIGIN" "$concurrent"
git -C "$concurrent" config user.name "Concurrent Test"
git -C "$concurrent" config user.email "concurrent@example.com"
printf 'concurrent\n' > "$concurrent/concurrent.txt"
git -C "$concurrent" add concurrent.txt
git -C "$concurrent" commit -m "concurrent parent update" >/dev/null
git -C "$concurrent" push origin main >/dev/null
concurrent_tip="$(git --git-dir="$ORIGIN" rev-parse main)"
status="$(run_capture "$TMPDIR/concurrent-parent-continue.out" bash -c \
  "cd '$WORK' && ./briteRepo/bin/pushup")"
[[ "$status" -eq 0 ]] || fail "remote descendant should be accepted, got $status"
git -C "$WORK" merge-base --is-ancestor "$concurrent_tip" feature || \
  fail "source should synchronize the newer remote parent tip"
echo "PASS: parent publication is inferred from a newer remote descendant"

# Crash after pulldown committed but before source-synchronized was saved.
add_feature_change "fifth feature"
source_tip="$(git -C "$WORK" rev-parse feature)"
parent_tip="$(git -C "$WORK" rev-parse main)"
prepare_and_publish_parent
prepared_tip="$(git -C "$WORK" rev-parse main)"
git -C "$WORK" checkout feature >/dev/null
git -C "$WORK" merge --no-edit main >/dev/null
write_state source-selected "$source_tip" "$parent_tip" "$prepared_tip"
cat > "$WORK/briteRepo/helpers/pulldown_workflow.sh" <<'EOF'
#!/usr/bin/env bash
bt_pulldown_init() { :; }
bt_pulldown_run() {
  echo "pulldown must not rerun after its commit is detected" >&2
  exit 91
}
EOF
chmod +x "$WORK/briteRepo/helpers/pulldown_workflow.sh"
status="$(run_capture "$TMPDIR/sync-commit-continue.out" bash -c \
  "cd '$WORK' && ./briteRepo/bin/pushup")"
[[ "$status" -eq 0 ]] || fail "committed synchronization should be inferred, got $status"
echo "PASS: source synchronization crash is inferred from ancestry"

# Crash after the source push but before source-published was saved.
add_feature_change "sixth feature"
source_tip="$(git -C "$WORK" rev-parse feature)"
parent_tip="$(git -C "$WORK" rev-parse main)"
prepare_and_publish_parent
prepared_tip="$(git -C "$WORK" rev-parse main)"
git -C "$WORK" checkout feature >/dev/null
git -C "$WORK" merge --no-edit main >/dev/null
git -C "$WORK" push origin feature >/dev/null
write_state source-publishing "$source_tip" "$parent_tip" "$prepared_tip"
status="$(run_capture "$TMPDIR/source-push-continue.out" bash -c \
  "cd '$WORK' && ./briteRepo/bin/pushup")"
[[ "$status" -eq 0 ]] || fail "published source should be inferred, got $status"
[[ ! -f "$WORK/.git/briteRepo/pushup.state" ]] || \
  fail "inferred completion should remove state"
echo "PASS: source publication crash is inferred from the exact remote tip"

# A signal must retain durable state and direct the user to continuation once
# the parent-published phase has been reached.
write_state parent-published \
  "$(git -C "$WORK" rev-parse feature)" \
  "$(git -C "$WORK" rev-parse main)" \
  "$(git -C "$WORK" rev-parse main)"
cat > "$WORK/briteRepo/bin/chbranch" <<'EOF'
#!/usr/bin/env bash
kill -TERM "$PPID"
exit 143
EOF
chmod +x "$WORK/briteRepo/bin/chbranch"
status="$(run_capture "$TMPDIR/signal.out" bash -c \
  "cd '$WORK' && ./briteRepo/bin/pushup")"
[[ "$status" -eq 5 ]] || fail "signal interruption should exit 5, got $status"
[[ -f "$WORK/.git/briteRepo/pushup.state" ]] || fail "signal should retain state"
assert_contains "Rerun pushup" "$TMPDIR/signal.out"
cat > "$WORK/briteRepo/bin/chbranch" <<'EOF'
#!/usr/bin/env bash
git checkout "${@: -1}" >/dev/null
EOF
cat > "$WORK/briteRepo/helpers/pulldown_workflow.sh" <<'EOF'
#!/usr/bin/env bash
bt_pulldown_init() { :; }
bt_pulldown_run() {
  git fetch origin main >/dev/null
  git merge --no-edit origin/main >/dev/null
}
EOF
chmod +x "$WORK/briteRepo/bin/chbranch" \
  "$WORK/briteRepo/helpers/pulldown_workflow.sh"
rm -rf "$WORK/.git/briteRepo/pushup-tools"
status="$(run_capture "$TMPDIR/signal-continue.out" bash -c \
  "cd '$WORK' && ./briteRepo/bin/pushup")"
[[ "$status" -eq 0 ]] || fail "continuation after signal should complete, got $status"
echo "PASS: signal interruption retains state and resumes"