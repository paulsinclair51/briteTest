#!/usr/bin/env bash

# test_mkbranch.sh - smoke tests for scripts/bin/mkbranch
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MKBRANCH_SRC="$REPO_ROOT/scripts/bin/mkbranch"
HISTORY_HELPER_SRC="$REPO_ROOT/scripts/helpers/history_log.sh"

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
[[ -f "$HISTORY_HELPER_SRC" ]] || fail "missing helper: $HISTORY_HELPER_SRC"

TMPDIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT
export GITHUB_ACTOR="testuser"

ORIGIN="$TMPDIR/origin.git"
WORK="$TMPDIR/work"

git init --bare "$ORIGIN" >/dev/null 2>&1

git clone "$ORIGIN" "$WORK" >/dev/null 2>&1

mkdir -p "$WORK/scripts/bin" "$WORK/scripts/helpers" "$WORK/config" "$WORK/logs"
cp "$MKBRANCH_SRC" "$WORK/scripts/bin/mkbranch"
cp "$HISTORY_HELPER_SRC" "$WORK/scripts/helpers/history_log.sh"
chmod +x "$WORK/scripts/bin/mkbranch"

cat > "$WORK/config/contributors.md" <<'EOF'
testuser,C,test@example.com
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
)

# 1) Help output
rc=$(run_capture "$TMPDIR/help.out" bash "$WORK/scripts/bin/mkbranch" -h)
[[ "$rc" -eq 0 ]] || fail "mkbranch -h should exit 0"
assert_contains "Usage:" "$TMPDIR/help.out"
pass "help output"

# 2) Local parent missing -> exit 6
rc=$(run_capture "$TMPDIR/local-parent-missing.out" \
  bash "$WORK/scripts/bin/mkbranch" dev/new-v3.0.0 v3.0.0)
[[ "$rc" -eq 6 ]] || fail "local parent missing should exit 6 (got $rc)"
assert_contains "Local parent branch 'v3.0.0' does not exist" \
  "$TMPDIR/local-parent-missing.out"
pass "local parent missing exit code"

# 3) Remote parent missing -> exit 7
rc=$(run_capture "$TMPDIR/remote-parent-missing.out" \
  bash "$WORK/scripts/bin/mkbranch" -r dev/new-v3.0.0 v3.0.0)
[[ "$rc" -eq 7 ]] || fail "remote parent missing should exit 7 (got $rc)"
assert_contains "Remote parent branch 'v3.0.0' does not exist" \
  "$TMPDIR/remote-parent-missing.out"
pass "remote parent missing exit code"

# 4) Local branch exists -> exit 8
rc=$(run_capture "$TMPDIR/local-exists.out" \
  bash "$WORK/scripts/bin/mkbranch" dev/local-exists-v1.0.0 v1.0.0)
[[ "$rc" -eq 8 ]] || fail "local branch exists should exit 8 (got $rc)"
assert_contains "already exists locally" "$TMPDIR/local-exists.out"
pass "local branch exists exit code"

# 5) Remote branch exists -> exit 9
rc=$(run_capture "$TMPDIR/remote-exists.out" \
  bash "$WORK/scripts/bin/mkbranch" -r dev/remote-exists-v1.0.0 v1.0.0)
[[ "$rc" -eq 9 ]] || fail "remote branch exists should exit 9 (got $rc)"
assert_contains "already exists on remote" "$TMPDIR/remote-exists.out"
pass "remote branch exists exit code"

# 6) Validate mode reports specific existence exit code (not generic 10)
rc=$(run_capture "$TMPDIR/validate-specific.out" \
  bash "$WORK/scripts/bin/mkbranch" -d dev/local-exists-v1.0.0 v1.0.0)
[[ "$rc" -eq 8 ]] || fail "validate local-exists should exit 8 (got $rc)"
pass "validate specific exit code"

# 6b) Contributor branch with optional type prefix should validate
rc=$(run_capture "$TMPDIR/contributor-prefixed.out" \
  bash "$WORK/scripts/bin/mkbranch" -d mywork/feature-one dev/local-exists-v1.0.0)
[[ "$rc" -eq 0 ]] || fail "prefixed contributor branch should validate (got $rc)"
assert_contains "can be created" "$TMPDIR/contributor-prefixed.out"
pass "contributor optional prefix format"

# 7) Missing helper fails gracefully with exit 5
mv "$WORK/scripts/helpers/history_log.sh" \
  "$WORK/scripts/helpers/history_log.sh.bak"
rc=$(run_capture "$TMPDIR/missing-helper.out" \
  bash "$WORK/scripts/bin/mkbranch" -h)
[[ "$rc" -eq 5 ]] || fail "missing helper should exit 5 (got $rc)"
assert_contains "Required helper not found" "$TMPDIR/missing-helper.out"
mv "$WORK/scripts/helpers/history_log.sh.bak" \
  "$WORK/scripts/helpers/history_log.sh"
pass "missing helper graceful failure"

# 8) Missing origin fails gracefully with exit 5
(
  cd "$WORK"
  git remote remove origin
)
rc=$(run_capture "$TMPDIR/missing-origin.out" \
  bash "$WORK/scripts/bin/mkbranch" dev/new-v2.0.0 v2.0.0)
[[ "$rc" -eq 5 ]] || fail "missing origin should exit 5 (got $rc)"
assert_contains "Remote 'origin' is not configured" "$TMPDIR/missing-origin.out"
pass "missing origin graceful failure"

echo "All mkbranch smoke tests passed."
