#!/usr/bin/env bash

# test_commit_history.sh - history-focused smoke tests for briteRepo/bin/commit.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=test_commit_lib.sh
source "$SCRIPT_DIR/test_commit_lib.sh"

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
rc=$(run_capture "$TMPDIR/diverged.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/commit -c 'local diverged change'")
[[ "$rc" -eq 0 ]] || fail "local commit on diverged branch should exit 0 (got $rc)"
grep -Eq '^Committed \([0-9a-f]{7}\) to local .*: [0-9]+ (modified|deleted|added|renamed|renamed/modified) files?\.$' "$TMPDIR/diverged.out" || fail "expected final commit summary in diverged output"
! grep -Eq '(^|[,:] )0 (modified|deleted|added|renamed)' \
  "$TMPDIR/diverged.out" || fail "commit summary should omit zero counts"
assert_contains "Run report for details." "$TMPDIR/diverged.out"
if grep -Fq "See reports/commit-" "$TMPDIR/diverged.out"; then
  fail "successful commit should not output a report path"
fi
if find "$WORK/reports" -maxdepth 1 -type f -name 'commit-*.md' -print -quit | grep -q .; then
  fail "successful commit should not create a commit report"
fi
if [[ "$(cd "$WORK" && git log -1 --pretty=%s)" != \
  "dev/commit-tests-v1.0.0 committed by contributor testuser" ]]; then
  fail "latest commit subject should be standardized"
fi
pass "diverged history local commit"

# 2) Local-only branch should still commit and report normally.
(
  cd "$WORK"
  git checkout -b local-only-commit-test >/dev/null 2>&1
)
printf '\nlocal only branch change\n' >> "$WORK/README.md"
rc=$(run_capture "$TMPDIR/local-only.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/commit -c 'local only commit'")
[[ "$rc" -eq 0 ]] || fail "commit on local-only branch should exit 0 (got $rc)"
grep -Eq '^Committed \([0-9a-f]{7}\) to local .*: [0-9]+ (modified|deleted|added|renamed|renamed/modified) files?\.$' "$TMPDIR/local-only.out" || fail "expected final commit summary in local-only output"
assert_contains "Run report for details." "$TMPDIR/local-only.out"
if find "$WORK/reports" -maxdepth 1 -type f -name 'commit-*.md' -print -quit | grep -q .; then
  fail "successful local-only commit should not create a commit report"
fi
pass "local-only branch commit"

# 3) User comment '\\n' should render as newline and be quoted in body.
printf '\nquoted comment body test\n' >> "$WORK/README.md"
rc=$(run_capture "$TMPDIR/quoted-body.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/commit -c 'line one\\nFiles-Modified: 999'" )
[[ "$rc" -eq 0 ]] || fail "commit with escaped newline should exit 0 (got $rc)"
latest_body="$(cd "$WORK" && git log -1 --pretty=%b)"
printf '%s\n' "$latest_body" | grep -Fq '> line one' || \
  fail "commit body should quote first user comment line"
printf '%s\n' "$latest_body" | grep -Fq '> Files-Modified: 999' || \
  fail "commit body should quote trailer-like user comment line"
printf '%s\n' "$latest_body" | grep -Fq 'Files-Modified:' || \
  fail "commit body should include metadata trailer section"
printf '%s\n' "$latest_body" | grep -Fq 'Command-Line: commit -c <user-comment>' || \
  fail "commit body should include redacted command-line trailer"
pass "quoted user comment body"

echo "All commit history smoke tests passed."
