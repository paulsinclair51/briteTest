#!/usr/bin/env bash

# test_fixlocal_remote.sh - remote failure classification tests for fixlocal.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=test_fixlocal_lib.sh
source "$SCRIPT_DIR/test_fixlocal_lib.sh"

fixlocal_test_init

UNREACHABLE_REMOTE_REPO="$(make_unreachable_remote_repo)"
TRACKING_FAIL_REPO="$(make_fixture_repo trackingfail plain)"
TIMEOUT_REPO="$(make_fixture_repo timeoutcase plain)"

attach_reachable_origin "$TRACKING_FAIL_REPO" trackingfail
attach_reachable_origin "$TIMEOUT_REPO" timeoutcase

# 1) Unreachable origin should surface remote reachability issue and exit 4
rc=$(run_capture "$TMPDIR/unreachable.out" bash "$UNREACHABLE_REMOTE_REPO/briteRepo/bin/fixlocal" -d -t 1)
[[ "$rc" -eq 4 ]] || fail "fixlocal -d -t 1 with unreachable origin should exit 4 (got $rc)"
unreachable_report="$(latest_report "$UNREACHABLE_REMOTE_REPO")"
[[ -f "$unreachable_report" ]] || fail "expected report file for unreachable-origin run"
assert_contains "Remote is configured but not reachable" "$unreachable_report"
pass "remote reachability failure"

# 2) Remote tracking refresh failure should classify as remote unreachable (exit 4)
TRACKING_FAKEBIN="$TMPDIR/tracking-fakebin"
mkdir -p "$TRACKING_FAKEBIN"
cat > "$TRACKING_FAKEBIN/git" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "-C" ]]; then
  repo="\$2"
  shift 2

  if [[ "\${1:-}" == "fetch" && "\${2:-}" == "--prune" && "\${3:-}" == "origin" ]]; then
    echo "simulated fetch failure" >&2
    exit 1
  fi

  if [[ "\${1:-}" == "rev-list" && "\${2:-}" == "--left-right" && "\${3:-}" == "--count" ]]; then
    echo "not numeric"
    exit 0
  fi

  exec "$REAL_GIT" -C "\$repo" "\$@"
fi

if [[ "\${1:-}" == "fetch" && "\${2:-}" == "--prune" && "\${3:-}" == "origin" ]]; then
  echo "simulated fetch failure" >&2
  exit 1
fi

if [[ "\${1:-}" == "rev-list" && "\${2:-}" == "--left-right" && "\${3:-}" == "--count" ]]; then
  echo "not numeric"
  exit 0
fi

exec "$REAL_GIT" "\$@"
EOF
chmod +x "$TRACKING_FAKEBIN/git"

rc=$(run_capture "$TMPDIR/tracking-refresh-fail.out" env PATH="$TRACKING_FAKEBIN:$PATH" bash "$TRACKING_FAIL_REPO/briteRepo/bin/fixlocal" -t 5)
[[ "$rc" -eq 4 ]] || fail "fixlocal should exit 4 when remote tracking refresh fails (got $rc)"
tracking_fail_report="$(latest_report "$TRACKING_FAIL_REPO")"
[[ -f "$tracking_fail_report" ]] || fail "expected report file for tracking-refresh-failure run"
assert_contains "Unable to refresh remote-tracking references" "$tracking_fail_report"
pass "remote tracking refresh failure classification"

# 3) Timed-out origin probe should classify as timeout (exit 5)
TIMEOUT_FAKEBIN="$TMPDIR/timeout-fakebin"
mkdir -p "$TIMEOUT_FAKEBIN"
cat > "$TIMEOUT_FAKEBIN/git" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "-C" ]]; then
  repo="\$2"
  shift 2
  if [[ "\${1:-}" == "ls-remote" ]]; then
    echo "simulated timeout" >&2
    exit 124
  fi
  exec "$REAL_GIT" -C "\$repo" "\$@"
fi
if [[ "\${1:-}" == "ls-remote" ]]; then
  echo "simulated timeout" >&2
  exit 124
fi
exec "$REAL_GIT" "\$@"
EOF
chmod +x "$TIMEOUT_FAKEBIN/git"

rc=$(run_capture "$TMPDIR/timeout-classification.out" env PATH="$TIMEOUT_FAKEBIN:$PATH" bash "$TIMEOUT_REPO/briteRepo/bin/fixlocal" -d -t 1)
[[ "$rc" -eq 5 ]] || fail "fixlocal should exit 5 when origin probe times out (got $rc)"
pass "remote timeout classification"

echo "All fixlocal remote smoke tests passed."
