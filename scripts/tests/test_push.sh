#!/usr/bin/env bash

# test_push.sh - smoke tests for scripts/bin/push.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PUSH_SRC="$REPO_ROOT/scripts/bin/push"
COMMON_HELPER_SRC="$REPO_ROOT/scripts/helpers/common.sh"
GIT_HELPER_SRC="$REPO_ROOT/scripts/helpers/git_helpers.sh"
REPORT_HELPER_SRC="$REPO_ROOT/scripts/helpers/report_helpers.sh"
REPORT_SYNC_HELPER_SRC="$REPO_ROOT/scripts/helpers/report_sync.sh"
CKROLE_HELPER_SRC="$REPO_ROOT/scripts/helpers/ckrole.sh"

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
  find "$repo/reports/branch" -maxdepth 1 -type f -name "$pattern" -printf '%T@ %p\n' | sort -n | tail -n 1 | cut -d' ' -f2-
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

mkdir -p "$WORK/scripts/bin" "$WORK/scripts/helpers" "$WORK/config"
cp "$PUSH_SRC" "$WORK/scripts/bin/push"
cp "$COMMON_HELPER_SRC" "$WORK/scripts/helpers/common.sh"
cp "$GIT_HELPER_SRC" "$WORK/scripts/helpers/git_helpers.sh"
cp "$REPORT_HELPER_SRC" "$WORK/scripts/helpers/report_helpers.sh"
cp "$REPORT_SYNC_HELPER_SRC" "$WORK/scripts/helpers/report_sync.sh"
cp "$CKROLE_HELPER_SRC" "$WORK/scripts/helpers/ckrole.sh"
chmod +x "$WORK/scripts/bin/push" "$WORK/scripts/helpers/ckrole.sh"

mkdir -p "$WORK/reports/branch"
mkdir -p "$ORIGIN/reports/branch"

cat > "$WORK/config/contributors.md" <<'EOF'
- testuser, C
EOF

(
  cd "$WORK"
  git config user.name "testuser"
  git config user.email "test@example.com"

  echo "seed" > README.md
  git add README.md scripts config
  git commit -m "seed repo" >/dev/null 2>&1
  git branch -M main
  git push -u origin main >/dev/null 2>&1

  git checkout -b dev/push-tests-v1.0.0 >/dev/null 2>&1
  git push -u origin dev/push-tests-v1.0.0 >/dev/null 2>&1
)

# 1) Help output should include the timeout option.
rc=$(run_capture "$TMPDIR/help.out" bash -lc "cd '$WORK' && bash ./scripts/bin/push -h")
[[ "$rc" -eq 0 ]] || fail "push -h should exit 0 (got $rc)"
assert_contains "-r SEC" "$TMPDIR/help.out"
pass "help output"

# 2) Invalid timeout should fail before remote operations.
rc=$(run_capture "$TMPDIR/invalid-r.out" bash -lc "cd '$WORK' && bash ./scripts/bin/push -r 0")
[[ "$rc" -eq 1 ]] || fail "push -r 0 should exit 1 (got $rc)"
assert_contains "Option -r requires an integer greater than 0" "$TMPDIR/invalid-r.out"
pass "invalid timeout parsing"

# 3) Missing required tool should fail fast with clear guidance.
mkdir -p "$TMPDIR/minpath"
for tool in bash git awk sed grep wc cksum flock chmod rm mkdir date dirname; do
  ln -s "$(command -v "$tool")" "$TMPDIR/minpath/$tool"
done
rc=$(run_capture "$TMPDIR/missing-tool.out" env PATH="$TMPDIR/minpath" GITHUB_ACTOR=testuser /bin/bash -c "cd '$WORK' && /bin/bash ./scripts/bin/push -d -r 5")
[[ "$rc" -eq 1 ]] || fail "missing required tool preflight should exit 1 (got $rc)"
assert_contains "Missing required tool(s): head" "$TMPDIR/missing-tool.out"
assert_contains "Run push in a standard repository shell environment and try again" "$TMPDIR/missing-tool.out"
pass "toolchain preflight"

# 4) Unauthorized user should be blocked with exit 2.
(
  cd "$WORK"
  git checkout dev/push-tests-v1.0.0 >/dev/null 2>&1
  git config user.name "outsider"
  git config user.email "outsider@example.com"
  echo "change" >> README.md
)
rc=$(run_capture "$TMPDIR/unauth.out" env GITHUB_ACTOR=outsider bash -lc "cd '$WORK' && bash ./scripts/bin/push -d -r 5")
[[ "$rc" -eq 2 ]] || fail "unauthorized push should exit 2 (got $rc)"
assert_contains "User is not a contributor" "$TMPDIR/unauth.out"
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
rc=$(run_capture "$TMPDIR/protected.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/push -d -r 5")
[[ "$rc" -eq 3 ]] || fail "protected branch push should exit 3 (got $rc)"
assert_contains "Cannot push protected branch" "$TMPDIR/protected.out"
pass "protected branch gate"

# 6) Valid dry-run should report what would be pushed.
(
  cd "$WORK"
  git checkout dev/push-tests-v1.0.0 >/dev/null 2>&1
  echo "push change" >> README.md
  git add README.md
  git commit -m "push test change" >/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/dry.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/push -d -r 5")
[[ "$rc" -eq 0 ]] || fail "dry-run push should exit 0 (got $rc)"
assert_contains "Dry run: 1 commit(s) would be pushed" "$TMPDIR/dry.out"
assert_contains "See reports/branch/push-d-" "$TMPDIR/dry.out"
dry_report="$(latest_report "$WORK" 'push-d-*.md')"
[[ -f "$dry_report" ]] || fail "expected dry-run push report"
[[ "$(basename "$dry_report")" == push-d-* ]] || fail "expected push-d report filename"
assert_contains "## Files Included in This Push" "$dry_report"
assert_contains "| File | Added | Deleted | Net | Total Lines |" "$dry_report"
assert_contains "| \`README.md\` |" "$dry_report"
pass "dry-run push"

# 7) Invalid lock-timeout env var should fail with report error guidance.
rc=$(run_capture "$TMPDIR/invalid-lock-timeout.out" env BT_PUSH_REPORT_LOCK_TIMEOUT_SECONDS=abc GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/push -d -r 5")
[[ "$rc" -eq 201 ]] || fail "invalid lock-timeout env should exit 201 (got $rc)"
assert_contains "Invalid report lock timeout 'abc'" "$TMPDIR/invalid-lock-timeout.out"
assert_contains "Set BT_PUSH_REPORT_LOCK_TIMEOUT_SECONDS to an integer greater than 0" "$TMPDIR/invalid-lock-timeout.out"
pass "invalid lock-timeout env"

# 8) Dry-run should fail with 8 if report lock cannot be acquired within
# timeout.
repo_hash="$(printf '%s' "$WORK" | cksum | awk '{print $1}')"
lock_file="/tmp/briteTest-push-report-${repo_hash}.lock"
mkfifo "$TMPDIR/lock.wait"
(
  exec 9>"$lock_file"
  flock 9
  cat "$TMPDIR/lock.wait" >/dev/null
) &
lock_holder_pid=$!

rc=$(run_capture "$TMPDIR/lock-timeout.out" env BT_PUSH_REPORT_LOCK_TIMEOUT_SECONDS=1 GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/push -d -r 5")
[[ "$rc" -eq 8 ]] || fail "dry-run should exit 8 when report lock times out (got $rc)"
assert_contains "Timed out waiting 1s for report write lock" "$TMPDIR/lock-timeout.out"
# Close the FIFO writer to deliver EOF so the lock holder exits cleanly.
: > "$TMPDIR/lock.wait"
wait "$lock_holder_pid" >/dev/null 2>&1 || true
rm -f "$TMPDIR/lock.wait"
pass "report lock timeout"

# 9) Concurrent dry-runs writing to the same report path should serialize and
# produce a non-intermixed report body.
mkdir -p "$TMPDIR/fakebin"
cat > "$TMPDIR/fakebin/date" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "+%Y%m%d-%H%M%S" ]]; then
  echo 20260727-195000
elif [[ "$1" == "+%Y-%m-%d %H:%M:%S" ]]; then
  echo "2026-07-27 19:50:00"
else
  /usr/bin/date "$@"
fi
EOF
chmod +x "$TMPDIR/fakebin/date"

set +e
env PATH="$TMPDIR/fakebin:$PATH" GITHUB_ACTOR=testuser bash -c "cd '$WORK' && bash ./scripts/bin/push -d -r 5" >"$TMPDIR/dry-race-1.out" 2>&1 &
p1=$!
env PATH="$TMPDIR/fakebin:$PATH" GITHUB_ACTOR=testuser bash -c "cd '$WORK' && bash ./scripts/bin/push -d -r 5" >"$TMPDIR/dry-race-2.out" 2>&1 &
p2=$!
wait "$p1"; rc1=$?
wait "$p2"; rc2=$?
set -e

[[ "$rc1" -eq 0 ]] || fail "first concurrent dry-run should exit 0 (got $rc1)"
[[ "$rc2" -eq 0 ]] || fail "second concurrent dry-run should exit 0 (got $rc2)"

race_report="$(latest_report "$WORK" 'push-d-*.md')"
[[ -f "$race_report" ]] || fail "expected concurrent dry-run report"

header_count="$(grep -c '^# Push Report ' "$race_report")"
[[ "$header_count" -eq 1 ]] || fail "expected exactly one report header in concurrent dry-run report (got $header_count)"

table_header_count="$(grep -c '^| File | Added | Deleted | Net | Total Lines |$' "$race_report")"
[[ "$table_header_count" -eq 1 ]] || fail "expected exactly one file summary table in concurrent dry-run report (got $table_header_count)"
pass "concurrent dry-run report serialization"

# 10) Real push should succeed without a confirmation prompt.
rc=$(run_capture "$TMPDIR/push.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/push -r 5")
[[ "$rc" -eq 0 ]] || fail "push should exit 0 (got $rc)"
assert_contains "Pushed 1 commit(s) to remote 'dev/push-tests-v1.0.0'" "$TMPDIR/push.out"
assert_contains "See reports/branch/push-" "$TMPDIR/push.out"
push_report="$(latest_report "$WORK" 'push-*.md')"
[[ -f "$push_report" ]] || fail "expected non-dry push report"
[[ "$(basename "$push_report")" == push-* ]] || fail "expected push report filename"
assert_contains "## Files Included in This Push" "$push_report"
assert_contains "| File | Added | Deleted | Net | Total Lines |" "$push_report"
assert_contains "| \`README.md\` |" "$push_report"
remote_tip="$(git -C "$ORIGIN" rev-parse refs/heads/dev/push-tests-v1.0.0)"
local_tip="$(git -C "$WORK" rev-parse HEAD)"
[[ "$remote_tip" == "$local_tip" ]] || fail "remote tip should match local tip after push"
[[ -f "$ORIGIN/reports/branch/$(basename "$push_report")" ]] || fail "expected push report copied to remote"
pass "real push"

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
rc=$(run_capture "$TMPDIR/push-fail.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/push -r 5")
[[ "$rc" -eq 200 ]] || fail "push should exit 200 when remote rejects push (got $rc)"
assert_contains "Failed to push branch 'dev/push-tests-v1.0.0' to remote" "$TMPDIR/push-fail.out"
assert_contains "rejected by test hook: README.md policy violation" "$TMPDIR/push-fail.out"
push_error_report="$(latest_report "$WORK" 'push-e-*.md')"
[[ -f "$push_error_report" ]] || fail "expected failed push report"
assert_contains "**Status:** Failed" "$push_error_report"
assert_contains "**Mode:** push failed" "$push_error_report"
assert_contains "## Files Included in This Push" "$push_error_report"
assert_contains "- README.md" "$push_error_report"
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
rc=$(run_capture "$TMPDIR/push-fail-group.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/push -r 5")
[[ "$rc" -eq 200 ]] || fail "push should exit 200 for group-level failure (got $rc)"
push_error_report_group="$(latest_report "$WORK" 'push-e-*.md')"
[[ -f "$push_error_report_group" ]] || fail "expected failed push report for group-level failure"
assert_contains "## Files Included in This Push" "$push_error_report_group"
assert_contains "- src/group_scope.txt" "$push_error_report_group"
assert_contains "Push failed as a group-level operation. No specific file could be identified" "$push_error_report_group"
assert_contains "policy rejection without file context" "$push_error_report_group"
rm -f "$ORIGIN/hooks/pre-receive"
pass "group-level failed push attribution"

# 13) Non-dry push should fail with 201 when remote report write fails.
(
  cd "$WORK"
  echo "push report failure path" >> README.md
  git add README.md
  git commit -m "push report failure test" >/dev/null 2>&1
)
rm -rf "$ORIGIN/reports/branch"
rc=$(run_capture "$TMPDIR/report-fail.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/push -r 5")
[[ "$rc" -eq 201 ]] || fail "push should exit 201 when remote report write fails (got $rc)"
assert_contains "Failed to write push report to remote branch report directory" "$TMPDIR/report-fail.out"
pass "remote report write failure"

# 14) Dry-run report should handle unusual file deltas (rename/delete/binary)
# in file summary output.
mkdir -p "$ORIGIN/reports/branch"
(
  cd "$WORK"
  echo "seed for rename" > edge_rename_source.txt
  git add edge_rename_source.txt
  git commit -m "edge seed for unusual deltas" >/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/edge-seed-push.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/push -r 5")
[[ "$rc" -eq 0 ]] || fail "edge seed push should exit 0 (got $rc)"

(
  cd "$WORK"
  git mv edge_rename_source.txt edge_rename_target.txt
  git rm -f README.md >/dev/null 2>&1
  printf '\x00\x01\x02' > edge_binary.bin
  git add edge_binary.bin
  git commit -m "edge unusual delta types" >/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/edge-dry.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/push -d -r 5")
[[ "$rc" -eq 0 ]] || fail "edge dry-run should exit 0 (got $rc)"
edge_report="$(latest_report "$WORK" 'push-d-*.md')"
[[ -f "$edge_report" ]] || fail "expected edge dry-run report"
assert_contains "## Files Included in This Push" "$edge_report"
assert_matches 'edge_rename_source\.txt.*edge_rename_target\.txt|edge_rename_target\.txt' "$edge_report"
assert_contains "| \`edge_binary.bin\` | 0 | 0 | 0 | 0 |" "$edge_report"
assert_contains "| \`README.md\` |" "$edge_report"
pass "unusual file deltas in report"

echo "All push smoke tests passed."
