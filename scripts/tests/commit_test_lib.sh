#!/usr/bin/env bash

# Shared test helpers for commit smoke tests.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMMIT_SRC="$REPO_ROOT/scripts/bin/commit"
COMMON_HELPER_SRC="$REPO_ROOT/scripts/helpers/common.sh"
GIT_HELPER_SRC="$REPO_ROOT/scripts/helpers/git_helpers.sh"
REPORT_HELPER_SRC="$REPO_ROOT/scripts/helpers/report_helpers.sh"
REPORT_SYNC_HELPER_SRC="$REPO_ROOT/scripts/helpers/report_sync.sh"
HISTORY_LOG_HELPER_SRC="$REPO_ROOT/scripts/helpers/history_log.sh"

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

extract_report_hash() {
  local label="$1"
  local file="$2"

  grep -E "^\*\*${label}:\*\* [0-9a-f]+" "$file" | \
    sed -E "s/^\*\*${label}:\*\* ([0-9a-f]+).*$/\1/" | head -n 1
}

latest_report() {
  local repo="$1"
  find "$repo/reports/branch" -maxdepth 1 -type f -name 'commit*.md' -printf '%T@ %p\n' | sort -n | tail -n 1 | cut -d' ' -f2-
}

commit_test_init() {
  for dep in bash find git grep mktemp; do
    command -v "$dep" >/dev/null 2>&1 || fail "missing required command: $dep"
  done

  [[ -f "$COMMIT_SRC" ]] || fail "missing script: $COMMIT_SRC"
  [[ -f "$COMMON_HELPER_SRC" ]] || fail "missing helper: $COMMON_HELPER_SRC"
  [[ -f "$GIT_HELPER_SRC" ]] || fail "missing helper: $GIT_HELPER_SRC"
  [[ -f "$REPORT_HELPER_SRC" ]] || fail "missing helper: $REPORT_HELPER_SRC"
  [[ -f "$REPORT_SYNC_HELPER_SRC" ]] || fail "missing helper: $REPORT_SYNC_HELPER_SRC"
  [[ -f "$HISTORY_LOG_HELPER_SRC" ]] || fail "missing helper: $HISTORY_LOG_HELPER_SRC"

  TMPDIR="$(mktemp -d)"
  cleanup() {
    if [[ "${KEEP_TMPDIR:-0}" == "1" ]]; then
      echo "KEEP_TMPDIR=1 preserving test artifacts at: $TMPDIR" >&2
      return 0
    fi
    chmod -R u+w "$TMPDIR" 2>/dev/null || true
    rm -rf "$TMPDIR"
  }
  trap cleanup EXIT

  ORIGIN="$TMPDIR/origin.git"
  WORK="$TMPDIR/work"
  PEER="$TMPDIR/peer"

  git init --bare "$ORIGIN" >/dev/null 2>&1
  git clone "$ORIGIN" "$WORK" >/dev/null 2>&1

  mkdir -p "$WORK/scripts/bin" "$WORK/scripts/helpers" "$WORK/config" "$WORK/reports/branch"
  cp "$COMMIT_SRC" "$WORK/scripts/bin/commit"
  cp "$COMMON_HELPER_SRC" "$WORK/scripts/helpers/common.sh"
  cp "$GIT_HELPER_SRC" "$WORK/scripts/helpers/git_helpers.sh"
  cp "$REPORT_HELPER_SRC" "$WORK/scripts/helpers/report_helpers.sh"
  cp "$REPORT_SYNC_HELPER_SRC" "$WORK/scripts/helpers/report_sync.sh"
  cp "$HISTORY_LOG_HELPER_SRC" "$WORK/scripts/helpers/history_log.sh"
  chmod +x "$WORK/scripts/bin/commit"

  cat > "$WORK/config/contributors.md" <<'EOF'
testuser,C,test@example.com
EOF

  (
    cd "$WORK"
    git config user.name "testuser"
    git config user.email "test@example.com"

    echo "seed" > README.md
    cat > .gitignore <<'GITIGNORE'
reports/branch/branch-*.md
reports/branch/commit-*.md
GITIGNORE
    git add README.md scripts config reports .gitignore
    git commit -m "seed repo" >/dev/null 2>&1
    git branch -M main
    git push -u origin main >/dev/null 2>&1

    git checkout -b dev/commit-tests-v1.0.0 >/dev/null 2>&1
    git push -u origin dev/commit-tests-v1.0.0 >/dev/null 2>&1
  )
}
