#!/usr/bin/env bash

# test_fixrepo.sh - smoke tests for scripts/bin/fixrepo
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXREPO_SRC="$REPO_ROOT/scripts/bin/fixrepo"
COMMON_HELPER_SRC="$REPO_ROOT/scripts/helpers/common.sh"
GIT_HELPER_SRC="$REPO_ROOT/scripts/helpers/git_helpers.sh"
REPORT_HELPER_SRC="$REPO_ROOT/scripts/helpers/report_helpers.sh"

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

make_fixture_repo() {
  local name="$1"
  local mode="$2"
  local repo="$TMPDIR/$name"

  mkdir -p "$repo/scripts/bin" "$repo/scripts/helpers" "$repo/reports"
  cp "$FIXREPO_SRC" "$repo/scripts/bin/fixrepo"
  cp "$COMMON_HELPER_SRC" "$repo/scripts/helpers/common.sh"
  cp "$GIT_HELPER_SRC" "$repo/scripts/helpers/git_helpers.sh"
  cp "$REPORT_HELPER_SRC" "$repo/scripts/helpers/report_helpers.sh"
  chmod +x "$repo/scripts/bin/fixrepo"

  git -C "$repo" init -q
  git -C "$repo" config user.name "Test User"
  git -C "$repo" config user.email "test@example.com"

  if [[ "$mode" == "brite" ]]; then
    mkdir -p "$repo/include" "$repo/src"
    cat > "$repo/README.md" <<'EOF'
# Test Fixture
EOF
    cat > "$repo/.gitignore" <<'EOF'
*.tmp
EOF
    cat > "$repo/reports/README.md" <<'EOF'
# Reports
EOF
    mkdir -p "$repo/reports"
    cat > "$repo/reports/README.md" <<'EOF'
# Repository Reports
EOF
    cat > "$repo/include/runnerapi.h" <<'EOF'
/* fixture */
EOF
    cat > "$repo/include/testapi.h" <<'EOF'
/* fixture */
EOF
    cat > "$repo/src/runnerapi.c" <<'EOF'
/* fixture */
EOF
    cat > "$repo/src/testapi.c" <<'EOF'
/* fixture */
EOF
    git -C "$repo" add README.md .gitignore include src scripts reports
    git -C "$repo" commit -q -m "seed brite fixture"
  else
    cat > "$repo/README.md" <<'EOF'
# Plain Fixture
EOF
    cat > "$repo/reports/README.md" <<'EOF'
# Reports
EOF
    mkdir -p "$repo/reports"
    cat > "$repo/reports/README.md" <<'EOF'
# Repository Reports
EOF
    git -C "$repo" add README.md scripts reports
    git -C "$repo" commit -q -m "seed plain fixture"
  fi

  if [[ "$mode" == "brite" ]]; then
    local i=1
    while [[ $i -le 120 ]]; do
      printf 'loose-object-%s\n' "$i" | git -C "$repo" hash-object -w --stdin >/dev/null
      i=$((i + 1))
    done
  fi

  if [[ "$mode" == "remote" ]]; then
    git -C "$repo" remote add origin "$TMPDIR/origin.git"
  fi

  printf '%s\n' "$repo"
}

make_remote_repo() {
  local repo
  repo="$(make_fixture_repo remote remote)"
  printf '%s\n' "$repo"
}

make_unreachable_remote_repo() {
  local repo
  repo="$(make_fixture_repo unreachable remote)"
  git -C "$repo" remote set-url origin "file://$TMPDIR/this/remote/does/not/exist.git"
  printf '%s\n' "$repo"
}

latest_report() {
  local repo="$1"
  find "$repo/reports" -maxdepth 1 -type f -name 'repository-*.md' | sort | tail -n 1
}

for dep in bash find git grep mktemp; do
  command -v "$dep" >/dev/null 2>&1 || fail "missing required command: $dep"
 done

[[ -f "$FIXREPO_SRC" ]] || fail "missing script: $FIXREPO_SRC"
[[ -f "$COMMON_HELPER_SRC" ]] || fail "missing helper: $COMMON_HELPER_SRC"
[[ -f "$GIT_HELPER_SRC" ]] || fail "missing helper: $GIT_HELPER_SRC"

TMPDIR="$(mktemp -d)"
cleanup() {
  if [[ "${KEEP_TMPDIR:-0}" == "1" ]]; then
    echo "KEEP_TMPDIR=1 preserving test artifacts at: $TMPDIR" >&2
    return 0
  fi
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

BRITE_REPO="$(make_fixture_repo brite brite)"
PLAIN_REPO="$(make_fixture_repo plain plain)"
SECOND_PLAIN_REPO="$(make_fixture_repo plain2 plain)"
REMOTE_REPO="$(make_remote_repo)"
UNREACHABLE_REMOTE_REPO="$(make_unreachable_remote_repo)"
BRITE_FAIL_REPO="$(make_fixture_repo britefail brite)"

# 1) Help output
rc=$(run_capture "$TMPDIR/help.out" bash "$BRITE_REPO/scripts/bin/fixrepo" -h)
[[ "$rc" -eq 0 ]] || fail "fixrepo -h should exit 0"
assert_contains "Usage:" "$TMPDIR/help.out"
assert_contains "reports/repository-<datetime>.md" "$TMPDIR/help.out"
pass "help output"

# 2) Verified remediation flow should resolve fixable loose-object issues
rc=$(run_capture "$TMPDIR/brite.out" bash "$BRITE_REPO/scripts/bin/fixrepo" -q)
[[ "$rc" -eq 0 ]] || fail "fixrepo -q should exit 0 after verified remediation (got $rc)"
brite_report="$(latest_report "$BRITE_REPO")"
[[ -f "$brite_report" ]] || fail "expected report file for brite fixture"
assert_contains "- [ISSUE] **Loose Objects**" "$brite_report"
assert_contains "### Post-Cleanup Verification" "$brite_report"
assert_contains "- [FIXED] **Repository Cleanup**" "$brite_report"
assert_contains "**Auto-Handled Attempts:** 1" "$brite_report"
assert_contains "**Remediations Verified:** 1" "$brite_report"
assert_contains "**Issues Remaining:** 0" "$brite_report"
assert_contains "Status: All detected issues were resolved by verified remediations." "$brite_report"
pass "verified remediation flow"

# 3) Non-API fixture should skip repository structure layout checks
rc=$(run_capture "$TMPDIR/plain.out" bash "$PLAIN_REPO/scripts/bin/fixrepo" -d -q)
[[ "$rc" -eq 0 ]] || fail "fixrepo -d -q should exit 0 on clean plain fixture (got $rc)"
plain_report="$(latest_report "$PLAIN_REPO")"
[[ -f "$plain_report" ]] || fail "expected report file for plain fixture"
assert_contains "Repository structure checks skipped" "$plain_report"
pass "non-API fixture skip path"

# 4) A second clean repo can be checked as a clone-path target
rc=$(run_capture "$TMPDIR/clone.out" bash "$PLAIN_REPO/scripts/bin/fixrepo" -d -q "$SECOND_PLAIN_REPO")
[[ "$rc" -eq 0 ]] || fail "fixrepo -d -q with clone path should exit 0 on clean repos (got $rc)"
clone_report="$(latest_report "$PLAIN_REPO")"
[[ -f "$clone_report" ]] || fail "expected report file for clone-path run"
assert_contains "## Target: Clone Repository" "$clone_report"
pass "clone-path coverage"

# 5) -t 0 should skip remote connectivity and tracking checks when origin exists
rc=$(run_capture "$TMPDIR/remote.out" bash "$REMOTE_REPO/scripts/bin/fixrepo" -d -t 0)
[[ "$rc" -eq 0 ]] || fail "fixrepo -d -t 0 should exit 0 on remote-configured fixture (got $rc)"
remote_report="$(latest_report "$REMOTE_REPO")"
[[ -f "$remote_report" ]] || fail "expected report file for remote fixture"
assert_contains "Skipped (disabled by -t 0)" "$remote_report"
pass "remote checks disabled"

# 6) Unreachable origin should surface remote reachability issue and exit 2
rc=$(run_capture "$TMPDIR/unreachable.out" bash "$UNREACHABLE_REMOTE_REPO/scripts/bin/fixrepo" -d -t 1)
[[ "$rc" -eq 2 ]] || fail "fixrepo -d -t 1 with unreachable origin should exit 2 (got $rc)"
unreachable_report="$(latest_report "$UNREACHABLE_REMOTE_REPO")"
[[ -f "$unreachable_report" ]] || fail "expected report file for unreachable-origin run"
assert_contains "Remote is configured but not reachable" "$unreachable_report"
pass "remote reachability failure"

# 7) Invalid timeout should fail with argument error
rc=$(run_capture "$TMPDIR/bad-timeout.out" bash "$PLAIN_REPO/scripts/bin/fixrepo" -t abc)
[[ "$rc" -eq 1 ]] || fail "fixrepo -t abc should exit 1 (got $rc)"
assert_contains "Invalid -t value" "$TMPDIR/bad-timeout.out"
pass "invalid timeout handling"

# 8) Invalid clone path should fail with argument error
rc=$(run_capture "$TMPDIR/bad-clone.out" bash "$PLAIN_REPO/scripts/bin/fixrepo" -d -q "$TMPDIR/does-not-exist")
[[ "$rc" -eq 1 ]] || fail "fixrepo with missing clone path should exit 1 (got $rc)"
assert_contains "Clone path not found or not a directory" "$TMPDIR/bad-clone.out"
pass "invalid clone path handling"

# 9) Unresolved issue path should exit 2 (dry-run dirty worktree)
printf '\nlocal dirty change\n' >> "$PLAIN_REPO/README.md"
rc=$(run_capture "$TMPDIR/dirty.out" bash "$PLAIN_REPO/scripts/bin/fixrepo" -d -q)
[[ "$rc" -eq 2 ]] || fail "fixrepo -d -q on dirty worktree should exit 2 (got $rc)"
dirty_report="$(latest_report "$PLAIN_REPO")"
[[ -f "$dirty_report" ]] || fail "expected report file for dirty worktree run"
assert_contains "- [ISSUE] **Uncommitted Changes**" "$dirty_report"
assert_contains "Status: Issues detected; no automated fixes applied (-d)." "$dirty_report"
pass "unresolved issue exit path"

# 10) Non-dry remediation failure should be reported and counted
REAL_GIT="$(command -v git)"
FAKEBIN="$TMPDIR/fakebin"
mkdir -p "$FAKEBIN"
cat > "$FAKEBIN/git" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "-C" ]]; then
  repo="\$2"
  shift 2
  if [[ "\${1:-}" == "gc" ]]; then
    echo "simulated gc failure" >&2
    exit 1
  fi
  exec "$REAL_GIT" -C "\$repo" "\$@"
fi
if [[ "\${1:-}" == "gc" ]]; then
  echo "simulated gc failure" >&2
  exit 1
fi
exec "$REAL_GIT" "\$@"
EOF
chmod +x "$FAKEBIN/git"

rc=$(run_capture "$TMPDIR/gc-fail.out" env PATH="$FAKEBIN:$PATH" bash "$BRITE_FAIL_REPO/scripts/bin/fixrepo" -q)
[[ "$rc" -eq 2 ]] || fail "fixrepo -q with simulated gc failure should exit 2 (got $rc)"
gc_fail_report="$(latest_report "$BRITE_FAIL_REPO")"
[[ -f "$gc_fail_report" ]] || fail "expected report file for gc-failure run"
assert_contains "git gc failed during cleanup" "$gc_fail_report"
assert_contains "**Remediations Failed:** 1" "$gc_fail_report"
assert_contains "Status: Remediation attempts were made, but none were fully verified." "$gc_fail_report"
pass "remediation failure path"

echo "All fixrepo smoke tests passed."
