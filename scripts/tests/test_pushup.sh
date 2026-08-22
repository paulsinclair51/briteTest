#!/usr/bin/env bash

# Focused pushup transaction and resume tests.

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
  local state_file="$WORK/.git/briteTest/pushup.state"

  mkdir -p "$(dirname "$state_file")"
  rm -f "$state_file"
  git config --file "$state_file" pushup.version 1
  git config --file "$state_file" pushup.source feature
  git config --file "$state_file" pushup.parent main
  git config --file "$state_file" pushup.source-tip "$source_tip"
  git config --file "$state_file" pushup.parent-tip "$parent_tip"
  git config --file "$state_file" pushup.timeout 10
  git config --file "$state_file" pushup.verbose false
  git config --file "$state_file" pushup.owner-override false
  git config --file "$state_file" pushup.comment-mode none
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
mkdir -p "$WORK/scripts/bin" "$WORK/scripts/helpers" "$WORK/reports"
cp "$REPO_ROOT/scripts/bin/pushup" "$WORK/scripts/bin/pushup"
cp "$REPO_ROOT/scripts/helpers/common.sh" \
  "$REPO_ROOT/scripts/helpers/git_helpers.sh" \
  "$REPO_ROOT/scripts/helpers/report_helpers.sh" \
  "$REPO_ROOT/scripts/helpers/history_log.sh" "$WORK/scripts/helpers/"
chmod +x "$WORK/scripts/bin/pushup"

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

cat > "$WORK/scripts/helpers/pushup_parent.sh" <<'EOF'
#!/usr/bin/env bash
set -e
git checkout main >/dev/null
git merge --squash feature >/dev/null
git commit -m "pushed up" >/dev/null
EOF
cat > "$WORK/scripts/bin/push" <<'EOF'
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
cat > "$WORK/scripts/bin/chbranch" <<'EOF'
#!/usr/bin/env bash
git checkout "${@: -1}" >/dev/null
EOF
cat > "$WORK/scripts/bin/pulldown" <<'EOF'
#!/usr/bin/env bash
set -e
timeout_seconds=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -t) timeout_seconds="$2"; shift 2 ;;
    *) shift ;;
  esac
done
printf 'pulldown %s\n' "$timeout_seconds" >> .remote-timeouts
if [[ -f .fail-sync-once ]]; then
  rm -f .fail-sync-once
  exit 81
fi
git fetch origin main >/dev/null
git merge --no-edit origin/main >/dev/null
EOF
cat > "$WORK/scripts/bin/pull" <<'EOF'
#!/usr/bin/env bash
git pull --rebase origin "$(git branch --show-current)" >/dev/null
EOF
chmod +x "$WORK/scripts/bin/"{push,chbranch,pulldown,pull} "$WORK/scripts/helpers/pushup_parent.sh"

source_tip="$(git -C "$WORK" rev-parse feature)"
parent_tip="$(git -C "$WORK" rev-parse main)"
touch "$WORK/.fail-parent-push"
status="$(run_capture "$TMPDIR/rollback.out" bash -c \
  "cd '$WORK' && ./scripts/bin/pushup -t 7")"
[[ "$status" -eq 4 ]] || fail "pre-publication failure should exit 4, got $status"
[[ "$(git -C "$WORK" branch --show-current)" == feature ]] || \
  fail "rollback should restore source checkout"
[[ "$(git -C "$WORK" rev-parse main)" == "$parent_tip" ]] || \
  fail "rollback should restore parent tip"
[[ "$(git -C "$WORK" rev-parse feature)" == "$source_tip" ]] || \
  fail "rollback should restore source tip"
[[ ! -f "$WORK/.git/briteTest/pushup.state" ]] || \
  fail "rollback should remove pushup state"
assert_contains "No local push-up changes were retained" "$TMPDIR/rollback.out"
assert_contains "push-main 7" "$WORK/.remote-timeouts"
assert_contains "21s" "$WORK/.timeout-calls"
echo "PASS: pre-publication failure restores local state"

rm -f "$WORK/.fail-parent-push"
touch "$WORK/.fail-parent-finalize-once"
status="$(run_capture "$TMPDIR/finalize-fail.out" bash -c \
  "cd '$WORK' && ./scripts/bin/pushup")"
[[ "$status" -eq 5 ]] || fail "PR finalization failure should exit 5, got $status"
[[ "$(git config --file "$WORK/.git/briteTest/pushup.state" --get pushup.phase)" == \
  parent-finalization-failed ]] || fail "finalization failure phase should be retained"
assert_contains "parent was published" "$TMPDIR/finalize-fail.out"
status="$(run_capture "$TMPDIR/finalize-continue.out" bash -c \
  "cd '$WORK' && ./scripts/bin/pushup --continue")"
[[ "$status" -eq 0 ]] || fail "finalization continuation should complete, got $status"
assert_contains "push-main 10" "$WORK/.remote-timeouts"
assert_contains "push-main 30" "$WORK/.remote-timeouts"
assert_contains "pulldown 30" "$WORK/.remote-timeouts"
assert_contains "push-feature 30" "$WORK/.remote-timeouts"
assert_contains "30s" "$WORK/.timeout-calls"
echo "PASS: remote reaccess triples custom and default timeouts"
echo "PASS: published parent with failed finalization resumes safely"

# An incomplete state file must never be guessed at or silently removed.
mkdir -p "$WORK/.git/briteTest"
git config --file "$WORK/.git/briteTest/pushup.state" pushup.version 1
status="$(run_capture "$TMPDIR/incomplete-state.out" bash -c \
  "cd '$WORK' && ./scripts/bin/pushup --continue")"
[[ "$status" -eq 200 ]] || fail "incomplete state should exit 200, got $status"
[[ -f "$WORK/.git/briteTest/pushup.state" ]] || fail "incomplete state should be retained"
assert_contains "state is incomplete" "$TMPDIR/incomplete-state.out"
rm -f "$WORK/.git/briteTest/pushup.state"
echo "PASS: incomplete state fails closed"

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
  "cd '$WORK' && ./scripts/bin/pushup --continue")"
[[ "$status" -eq 5 ]] || fail "offline recovery should exit 5, got $status"
[[ -f "$WORK/.git/briteTest/pushup.state" ]] || \
  fail "offline recovery should retain state"
[[ "$(git config --file "$WORK/.git/briteTest/pushup.state" \
  --get pushup.phase)" == publication-uncertain ]] || \
  fail "offline recovery should record publication uncertainty"
assert_contains "origin is unavailable" "$TMPDIR/network-offline.out"
mv "$ORIGIN.offline" "$ORIGIN"
status="$(run_capture "$TMPDIR/network-reconnected.out" bash -c \
  "cd '$WORK' && ./scripts/bin/pushup --continue")"
[[ "$status" -eq 4 ]] || \
  fail "nonpublication after reconnect should roll back with exit 4, got $status"
[[ ! -f "$WORK/.git/briteTest/pushup.state" ]] || \
  fail "proven nonpublication should clear state after rollback"
status="$(run_capture "$TMPDIR/network-restart.out" bash -c \
  "cd '$WORK' && ./scripts/bin/pushup")"
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
state_file="$WORK/.git/briteTest/pushup.state"
write_state initialized "$source_tip" "$parent_tip"
git -C "$WORK" checkout main >/dev/null
git -C "$WORK" merge --squash feature >/dev/null
git -C "$WORK" commit -m "orphaned preparation" >/dev/null
orphaned_tip="$(git -C "$WORK" rev-parse main)"
status="$(run_capture "$TMPDIR/crash-before-publish.out" bash -c \
  "cd '$WORK' && ./scripts/bin/pushup")"
[[ "$status" -eq 0 ]] || fail "plain restart before publication should complete, got $status"
[[ "$(git --git-dir="$ORIGIN" rev-parse main)" != "$orphaned_tip" ]] || \
  fail "orphaned local preparation must not be published"
assert_contains "Recovered an interrupted prepublication" \
  "$TMPDIR/crash-before-publish.out"
echo "PASS: plain pushup recovers a prepublication hard crash"

git -C "$WORK" checkout feature >/dev/null
printf 'third feature\n' >> "$WORK/content.txt"
git -C "$WORK" commit -am "third feature" >/dev/null
git -C "$WORK" push origin feature >/dev/null
touch "$WORK/.fail-sync-once"
status="$(run_capture "$TMPDIR/partial.out" bash -c \
  "cd '$WORK' && ./scripts/bin/pushup")"
[[ "$status" -eq 5 ]] || fail "post-publication failure should exit 5, got $status"
[[ -f "$WORK/.git/briteTest/pushup.state" ]] || fail "partial run should retain state"
[[ "$(git config --file "$WORK/.git/briteTest/pushup.state" --get pushup.phase)" == \
  source-sync-failed ]] || fail "partial run should record failed synchronization"
report="$(find "$WORK/reports" -name 'pushup-e-*.md' | head -n 1)"
[[ -n "$report" ]] || fail "partial run should write a pushup error report"
assert_contains '| Publish parent | Completed |' "$report"
assert_contains '| Synchronize source from parent | Pending |' "$report"
assert_contains 'pushup --continue' "$report"
echo "PASS: partial report identifies completed and pending work"

status="$(run_capture "$TMPDIR/continue.out" bash -c \
  "cd '$WORK' && ./scripts/bin/pushup --continue")"
[[ "$status" -eq 0 ]] || fail "continue should complete pushup, got $status"
[[ ! -f "$WORK/.git/briteTest/pushup.state" ]] || \
  fail "completed pushup should remove state"
[[ "$(git --git-dir="$ORIGIN" rev-parse main)" == "$(git -C "$WORK" rev-parse main)" ]] || \
  fail "parent should be published"
[[ "$(git --git-dir="$ORIGIN" rev-parse feature)" == \
  "$(git -C "$WORK" rev-parse feature)" ]] || fail "source should be published"
assert_contains 'Push-up complete' "$TMPDIR/continue.out"
echo "PASS: pushup --continue completes retained work"

# Crash after the atomic parent push but before parent-published was saved.
add_feature_change "fourth feature"
source_tip="$(git -C "$WORK" rev-parse feature)"
parent_tip="$(git -C "$WORK" rev-parse main)"
prepare_and_publish_parent
prepared_tip="$(git -C "$WORK" rev-parse main)"
write_state parent-publishing "$source_tip" "$parent_tip" "$prepared_tip"
status="$(run_capture "$TMPDIR/published-needs-continue.out" bash -c \
  "cd '$WORK' && ./scripts/bin/pushup")"
[[ "$status" -eq 2 ]] || fail "plain pushup after parent publication should exit 2, got $status"
assert_contains "run pushup --continue" "$TMPDIR/published-needs-continue.out"
status="$(run_capture "$TMPDIR/published-continue.out" bash -c \
  "cd '$WORK' && ./scripts/bin/pushup --continue")"
[[ "$status" -eq 0 ]] || fail "published-parent continuation should complete, got $status"
echo "PASS: parent publication crash is inferred from the exact remote tip"

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
  "cd '$WORK' && ./scripts/bin/pushup --continue")"
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
cat > "$WORK/scripts/bin/pulldown" <<'EOF'
#!/usr/bin/env bash
echo "pulldown must not rerun after its commit is detected" >&2
exit 91
EOF
chmod +x "$WORK/scripts/bin/pulldown"
status="$(run_capture "$TMPDIR/sync-commit-continue.out" bash -c \
  "cd '$WORK' && ./scripts/bin/pushup --continue")"
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
  "cd '$WORK' && ./scripts/bin/pushup --continue")"
[[ "$status" -eq 0 ]] || fail "published source should be inferred, got $status"
[[ ! -f "$WORK/.git/briteTest/pushup.state" ]] || \
  fail "inferred completion should remove state"
echo "PASS: source publication crash is inferred from the exact remote tip"

# A signal must retain durable state and direct the user to continuation once
# the parent-published phase has been reached.
write_state parent-published \
  "$(git -C "$WORK" rev-parse feature)" \
  "$(git -C "$WORK" rev-parse main)" \
  "$(git -C "$WORK" rev-parse main)"
cat > "$WORK/scripts/bin/chbranch" <<'EOF'
#!/usr/bin/env bash
kill -TERM "$PPID"
exit 143
EOF
chmod +x "$WORK/scripts/bin/chbranch"
status="$(run_capture "$TMPDIR/signal.out" bash -c \
  "cd '$WORK' && ./scripts/bin/pushup --continue")"
[[ "$status" -eq 5 ]] || fail "signal interruption should exit 5, got $status"
[[ -f "$WORK/.git/briteTest/pushup.state" ]] || fail "signal should retain state"
assert_contains "Run pushup --continue" "$TMPDIR/signal.out"
cat > "$WORK/scripts/bin/chbranch" <<'EOF'
#!/usr/bin/env bash
git checkout "${@: -1}" >/dev/null
EOF
cat > "$WORK/scripts/bin/pulldown" <<'EOF'
#!/usr/bin/env bash
git fetch origin main >/dev/null
git merge --no-edit origin/main >/dev/null
EOF
chmod +x "$WORK/scripts/bin/chbranch" "$WORK/scripts/bin/pulldown"
status="$(run_capture "$TMPDIR/signal-continue.out" bash -c \
  "cd '$WORK' && ./scripts/bin/pushup --continue")"
[[ "$status" -eq 0 ]] || fail "continuation after signal should complete, got $status"
echo "PASS: signal interruption retains state and resumes"