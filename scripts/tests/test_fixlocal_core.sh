#!/usr/bin/env bash

# test_fixlocal_core.sh - core smoke tests for scripts/bin/fixlocal.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=test_fixlocal_lib.sh
source "$SCRIPT_DIR/test_fixlocal_lib.sh"

fixlocal_test_init

BRITE_REPO="$(make_fixture_repo brite brite)"
PLAIN_REPO="$(make_fixture_repo plain plain)"
REMOTE_REPO="$(make_remote_repo)"
BRITE_FAIL_REPO="$(make_fixture_repo britefail brite)"
UNAUTHORIZED_REPO="$(make_fixture_repo unauthorized plain someotheruser)"

attach_reachable_origin "$BRITE_REPO" brite
attach_reachable_origin "$PLAIN_REPO" plain
attach_reachable_origin "$REMOTE_REPO" remote
attach_reachable_origin "$BRITE_FAIL_REPO" britefail

# 1) Help output
rc=$(run_capture "$TMPDIR/help.out" bash "$BRITE_REPO/scripts/bin/fixlocal" -h)
[[ "$rc" -eq 0 ]] || fail "fixlocal -h should exit 0"
assert_contains "Usage:" "$TMPDIR/help.out"
assert_contains "repository-d-<date>-<time>-<pid>.md" "$TMPDIR/help.out"
assert_contains "<repo>/reports/" "$TMPDIR/help.out"
pass "help output"

# 2) Verified remediation flow should resolve fixable loose-object issues
rc=$(run_capture "$TMPDIR/brite.out" bash "$BRITE_REPO/scripts/bin/fixlocal")
[[ "$rc" -eq 0 ]] || fail "fixlocal should exit 0 after verified remediation (got $rc)"
brite_report="$(latest_report "$BRITE_REPO")"
[[ -f "$brite_report" ]] || fail "expected report file for brite fixture"
assert_contains "- [ISSUE] **Loose Objects**" "$brite_report"
assert_contains "### Post-Cleanup Verification" "$brite_report"
assert_contains "- [FIXED] **Repository Cleanup**" "$brite_report"
assert_contains "**Auto-Handled Attempts:** 1" "$brite_report"
assert_contains "**Remediations Verified:** 1" "$brite_report"
assert_contains "**Issues Remaining:** 0" "$brite_report"
pass "verified remediation flow"

# 3) Non-API fixture should skip repository structure layout checks
rc=$(run_capture "$TMPDIR/plain.out" bash "$PLAIN_REPO/scripts/bin/fixlocal" -d)
[[ "$rc" -eq 0 ]] || fail "fixlocal -d should exit 0 on clean plain fixture (got $rc)"
plain_report="$(latest_report "$PLAIN_REPO")"
[[ -f "$plain_report" ]] || fail "expected report file for plain fixture"
assert_contains "Repository structure checks skipped" "$plain_report"
pass "non-API fixture skip path"

# 4) -t 0 should fail argument validation (SEC must be > 0)
rc=$(run_capture "$TMPDIR/remote.out" bash "$REMOTE_REPO/scripts/bin/fixlocal" -d -t 0)
[[ "$rc" -eq 1 ]] || fail "fixlocal -d -t 0 should exit 1 (got $rc)"
assert_contains "Invalid -t value" "$TMPDIR/remote.out"
pass "strict remote timeout validation"

# 5) Invalid timeout should fail with argument error
rc=$(run_capture "$TMPDIR/bad-timeout.out" bash "$PLAIN_REPO/scripts/bin/fixlocal" -t abc)
[[ "$rc" -eq 1 ]] || fail "fixlocal -t abc should exit 1 (got $rc)"
assert_contains "Invalid -t value" "$TMPDIR/bad-timeout.out"
pass "invalid timeout handling"

# 6) Fixable items detected in dry-run should exit 7
LOOSE_REPO="$(make_fixture_repo fixture_loose plain)"
attach_reachable_origin "$LOOSE_REPO" loose
i=1
while [[ $i -le 120 ]]; do
  printf 'loose-object-%s\n' "$i" | git -C "$LOOSE_REPO" hash-object -w --stdin >/dev/null
  i=$((i + 1))
done
rc=$(run_capture "$TMPDIR/loose.out" bash "$LOOSE_REPO/scripts/bin/fixlocal" -d)
[[ "$rc" -eq 7 ]] || fail "fixlocal -d with only fixable items should exit 7 (got $rc)"
loose_report="$(latest_report "$LOOSE_REPO")"
[[ -f "$loose_report" ]] || fail "expected report file for loose objects run"
assert_contains "- [FIXABLE] **Loose Objects**" "$loose_report"
assert_contains "Status: Fixable items detected; no automated fixes applied (-d)." "$loose_report"
pass "fixable items detected in dry-run"

# 7) Non-dry remediation failure should be reported and counted
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

rc=$(run_capture "$TMPDIR/gc-fail.out" env PATH="$FAKEBIN:$PATH" bash "$BRITE_FAIL_REPO/scripts/bin/fixlocal")
[[ "$rc" -eq 6 ]] || fail "fixlocal with simulated gc failure should exit 6 (got $rc)"
gc_fail_report="$(latest_report "$BRITE_FAIL_REPO")"
[[ -f "$gc_fail_report" ]] || fail "expected report file for gc-failure run"
assert_contains "Garbage collection failed during cleanup" "$gc_fail_report"
assert_contains "**Remediations Failed:** 1" "$gc_fail_report"
pass "remediation failure path"

# 8) Missing helper dependency should exit 100
MISSING_HELPER_REPO="$(make_fixture_repo missinghelper plain)"
rm -f "$MISSING_HELPER_REPO/scripts/helpers/git_helpers.sh"
rc=$(run_capture "$TMPDIR/missing-helper.out" bash "$MISSING_HELPER_REPO/scripts/bin/fixlocal" -d)
[[ "$rc" -eq 100 ]] || fail "fixlocal should exit 100 when helper dependency is missing (got $rc)"
assert_contains "Required helper not found" "$TMPDIR/missing-helper.out"
pass "missing helper dependency handling"

# 9) Unwritable report path setup should exit 100
REPORT_PATH_FAIL_REPO="$(make_fixture_repo reportpathfail plain)"
rm -rf "$REPORT_PATH_FAIL_REPO/reports"
echo "blocking file" > "$REPORT_PATH_FAIL_REPO/reports"
rc=$(run_capture "$TMPDIR/report-path-fail.out" bash "$REPORT_PATH_FAIL_REPO/scripts/bin/fixlocal" -d)
[[ "$rc" -eq 100 ]] || fail "fixlocal should exit 100 when report directory cannot be created (got $rc)"
assert_contains "Reports directory not found" "$TMPDIR/report-path-fail.out"
pass "report path creation failure handling"

# 10) Unauthorized user should be blocked
rc=$(run_capture "$TMPDIR/unauthorized.out" env GITHUB_ACTOR="someotheruser" bash "$UNAUTHORIZED_REPO/scripts/bin/fixlocal" -d)
[[ "$rc" -eq 2 ]] || fail "fixlocal should exit 2 for unauthorized user (got $rc)"
assert_contains "User is not a contributor" "$TMPDIR/unauthorized.out"
pass "authorization enforcement"

echo "All fixlocal core smoke tests passed."
