#!/usr/bin/env bash

# test_retarget.sh - smoke tests for scripts/bin/retarget
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RETARGET_SRC="$REPO_ROOT/scripts/bin/retarget"
COMMON_HELPER_SRC="$REPO_ROOT/scripts/helpers/common.sh"
GIT_HELPER_SRC="$REPO_ROOT/scripts/helpers/git_helpers.sh"
HISTORY_HELPER_SRC="$REPO_ROOT/scripts/helpers/history_log.sh"
VALIDATION_HELPER_SRC="$REPO_ROOT/scripts/helpers/validation_helpers.sh"
COMMON_UTILS_HELPER_SRC="$REPO_ROOT/scripts/helpers/common_utils.sh"

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

[[ -f "$RETARGET_SRC" ]] || fail "missing script: $RETARGET_SRC"
[[ -f "$COMMON_HELPER_SRC" ]] || fail "missing helper: $COMMON_HELPER_SRC"
[[ -f "$GIT_HELPER_SRC" ]] || fail "missing helper: $GIT_HELPER_SRC"
[[ -f "$HISTORY_HELPER_SRC" ]] || fail "missing helper: $HISTORY_HELPER_SRC"
[[ -f "$VALIDATION_HELPER_SRC" ]] || fail "missing helper: $VALIDATION_HELPER_SRC"
[[ -f "$COMMON_UTILS_HELPER_SRC" ]] || fail "missing helper: $COMMON_UTILS_HELPER_SRC"

TMPDIR="$(mktemp -d)"
cleanup() {
  if [[ "${KEEP_TMPDIR:-0}" == "1" ]]; then
    echo "KEEP_TMPDIR=1 preserving test artifacts at: $TMPDIR" >&2
    return 0
  fi
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

ORIGIN="$TMPDIR/origin.git"
WORK="$TMPDIR/work"

git init --bare "$ORIGIN" >/dev/null 2>&1
git clone "$ORIGIN" "$WORK" >/dev/null 2>&1

mkdir -p "$WORK/scripts/bin" "$WORK/scripts/helpers" "$WORK/config" "$WORK/logs"
cp "$RETARGET_SRC" "$WORK/scripts/bin/retarget"
cp "$COMMON_HELPER_SRC" "$WORK/scripts/helpers/common.sh"
cp "$GIT_HELPER_SRC" "$WORK/scripts/helpers/git_helpers.sh"
cp "$HISTORY_HELPER_SRC" "$WORK/scripts/helpers/history_log.sh"
cp "$VALIDATION_HELPER_SRC" "$WORK/scripts/helpers/validation_helpers.sh"
cp "$COMMON_UTILS_HELPER_SRC" "$WORK/scripts/helpers/common_utils.sh"
chmod +x "$WORK/scripts/bin/retarget"

cat > "$WORK/config/contributors.md" <<'EOF'
- testapprover, A
- testcontrib, C
EOF

cat > "$WORK/config/version_branch_access.csv" <<'EOF'
version,dev,fix
v1.0.0,open,open
v1.1.0,open,open
EOF

(
  cd "$WORK"
  # Intentionally not the GitHub login to verify auth uses login resolution.
  git config user.name "Approver Display Name"
  git config user.email "approver@example.com"

  echo "seed" > README.md
  echo "# history" > logs/repository_history.md
  git add README.md scripts config logs
  git commit -m "seed repo" >/dev/null 2>&1
  git branch -M main
  git push -u origin main >/dev/null 2>&1

  git checkout -b v1.0.0 >/dev/null 2>&1
  git commit --allow-empty -m "version v1.0.0" >/dev/null 2>&1
  git push -u origin v1.0.0 >/dev/null 2>&1

  git checkout -b v1.1.0 main >/dev/null 2>&1
  git commit --allow-empty -m "version v1.1.0" >/dev/null 2>&1
  git push -u origin v1.1.0 >/dev/null 2>&1

  git checkout -b dev/parser-v1.0.0 v1.0.0 >/dev/null 2>&1
  git commit --allow-empty -m "targeted branch" >/dev/null 2>&1
  git push -u origin dev/parser-v1.0.0 >/dev/null 2>&1

  git checkout main >/dev/null 2>&1
)

# 1) Help output
rc=$(run_capture "$TMPDIR/help.out" bash -lc "cd '$WORK' && bash ./scripts/bin/retarget -h")
[[ "$rc" -eq 0 ]] || fail "retarget -h should exit 0 (got $rc)"
assert_contains "Usage:" "$TMPDIR/help.out"
pass "help output"

# 2) Unauthorized user should be blocked (permission denied exit code).
rc=$(run_capture "$TMPDIR/unauth.out" env GITHUB_ACTOR=testcontrib bash -lc "cd '$WORK' && bash ./scripts/bin/retarget -d dev/parser-v1.0.0 v1.1.0")
[[ "$rc" -eq 2 ]] || fail "unauthorized retarget should exit 2 (got $rc)"
assert_contains "is not an approver" "$TMPDIR/unauth.out"
pass "authorization enforcement"

# 3) Missing version policy should map to policy-denied exit code.
cat > "$WORK/config/version_branch_access.csv" <<'EOF'
version,dev,fix
v1.0.0,open,open
EOF
rc=$(run_capture "$TMPDIR/policy-missing.out" env GITHUB_ACTOR=testapprover bash -lc "cd '$WORK' && bash ./scripts/bin/retarget -d dev/parser-v1.0.0 v1.1.0")
[[ "$rc" -eq 3 ]] || fail "missing access policy should exit 3 (got $rc)"
assert_contains "has no access policy" "$TMPDIR/policy-missing.out"
pass "missing policy exit mapping"

# Restore policy and verify dry-run success under login-based auth.
cat > "$WORK/config/version_branch_access.csv" <<'EOF'
version,dev,fix
v1.0.0,open,open
v1.1.0,open,open
EOF

# 4) Authorized dry-run should succeed using login identity resolution.
rc=$(run_capture "$TMPDIR/dry-run.out" env GITHUB_ACTOR=testapprover bash -lc "cd '$WORK' && bash ./scripts/bin/retarget -d dev/parser-v1.0.0 v1.1.0")
[[ "$rc" -eq 0 ]] || fail "authorized dry-run retarget should exit 0 (got $rc)"
assert_contains "Dry-run passed" "$TMPDIR/dry-run.out"
assert_contains "Rebase preview: git rebase origin/v1.1.0" "$TMPDIR/dry-run.out"
pass "dry-run success with login identity"

echo "All retarget smoke tests passed."
