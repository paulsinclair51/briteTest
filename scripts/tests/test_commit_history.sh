#!/usr/bin/env bash

# test_commit_history.sh - history-focused smoke tests for scripts/bin/commit.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=commit_test_lib.sh
source "$SCRIPT_DIR/commit_test_lib.sh"

commit_test_init

git clone "$ORIGIN" "$PEER" >/dev/null 2>&1

# 1) Diverged local/remote history should not block local commit.
(
  cd "$PEER"
  git config user.name "peer"
  git config user.email "peer@example.com"
  git checkout dev/commit-tests-v1.0.0 >/dev/null 2>&1
  echo "peer change" > PEER_ONLY.md
  git add PEER_ONLY.md
  git commit -m "peer update" >/dev/null 2>&1
  git push origin dev/commit-tests-v1.0.0 >/dev/null 2>&1
)
(
  cd "$WORK"
  git fetch origin dev/commit-tests-v1.0.0 >/dev/null 2>&1
)
echo "local diverged change" > "$WORK/LOCAL_ONLY.md"
rc=$(run_capture "$TMPDIR/diverged.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/commit -c 'local diverged change'")
[[ "$rc" -eq 0 ]] || fail "local commit on diverged branch should exit 0 (got $rc)"
grep -Eq '[0-9]+ file(s)? committed\.' "$TMPDIR/diverged.out" || fail "expected committed-file summary in diverged output"
assert_contains "See reports/branch/commit-" "$TMPDIR/diverged.out"
diverged_report="$(latest_report "$WORK")"
[[ -f "$diverged_report" ]] || fail "expected diverged commit report"
assert_contains "**Commit Hash**" "$diverged_report"
diverged_commit_hash="$(awk -F'|' '/^\| [^*]/ && $3 ~ /[0-9a-f]+/ { gsub(/ /, "", $3); print $3; exit }' "$diverged_report")"
[[ "$diverged_commit_hash" =~ ^[0-9a-f]+$ ]] || fail "expected commit hash in diverged report"
if ! (cd "$WORK" && git cat-file -e "${diverged_commit_hash}^{commit}" >/dev/null 2>&1); then
  fail "commit hash from diverged report does not resolve to a commit"
fi
if [[ "$(cd "$WORK" && git log -1 --pretty=%s)" != "local diverged change" ]]; then
  fail "latest commit message should match commit comment"
fi
pass "diverged history local commit"

# 2) Local-only branch should still commit and report normally.
(
  cd "$WORK"
  git checkout -b local-only-commit-test >/dev/null 2>&1
)
printf '\nlocal only branch change\n' >> "$WORK/README.md"
rc=$(run_capture "$TMPDIR/local-only.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/commit -c 'local only commit'")
[[ "$rc" -eq 0 ]] || fail "commit on local-only branch should exit 0 (got $rc)"
grep -Eq '[0-9]+ file(s)? committed\.' "$TMPDIR/local-only.out" || fail "expected committed-file summary in local-only output"
local_only_report="$(latest_report "$WORK")"
[[ -f "$local_only_report" ]] || fail "expected local-only commit report"
assert_contains '**Branch:** `local-only-commit-test`' "$local_only_report"
pass "local-only branch commit"

echo "All commit history smoke tests passed."
