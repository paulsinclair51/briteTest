#!/usr/bin/env bash

# Shared test helpers for fixlocal smoke tests.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXLOCAL_SRC="$REPO_ROOT/briteRepo/bin/fixlocal"
COMMON_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/common.sh"
GIT_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/git_helpers.sh"
REPORT_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/report_helpers.sh"
HEALTH_REPORT_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/health_report.sh"
CKROLE_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/ckrole.sh"

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
  local actor="${3:-paulsinclair51}"
  local repo="$TMPDIR/$name"

  mkdir -p "$repo/briteRepo/bin" "$repo/briteRepo/helpers" "$repo/reports" "$repo/config"
  cp "$FIXLOCAL_SRC" "$repo/briteRepo/bin/fixlocal"
  cp "$COMMON_HELPER_SRC" "$repo/briteRepo/helpers/common.sh"
  cp "$GIT_HELPER_SRC" "$repo/briteRepo/helpers/git_helpers.sh"
  cp "$REPORT_HELPER_SRC" "$repo/briteRepo/helpers/report_helpers.sh"
  cp "$HEALTH_REPORT_HELPER_SRC" "$repo/briteRepo/helpers/health_report.sh"
  cp "$CKROLE_HELPER_SRC" "$repo/briteRepo/helpers/ckrole.sh"
  chmod +x "$repo/briteRepo/bin/fixlocal"

  git -C "$repo" init -q
  git -C "$repo" config user.name "$actor"
  git -C "$repo" config user.email "test@example.com"

  cat > "$repo/config/contributors.md" <<EOF
# Contributors

- paulsinclair51, A
EOF

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
    git -C "$repo" add README.md .gitignore include src briteRepo reports config
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
    git -C "$repo" add README.md briteRepo reports config
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

attach_reachable_origin() {
  local repo="$1"
  local name="$2"
  local origin_path="$TMPDIR/origin-${name}.git"
  local branch=""

  git init --bare -q "$origin_path"

  if git -C "$repo" remote get-url origin >/dev/null 2>&1; then
    git -C "$repo" remote set-url origin "$origin_path"
  else
    git -C "$repo" remote add origin "$origin_path"
  fi

  branch="$(git -C "$repo" rev-parse --abbrev-ref HEAD)"
  git -C "$repo" push -u origin "$branch" >/dev/null 2>&1
}

latest_report() {
  local repo="$1"
  find "$repo/reports" -maxdepth 1 -type f -name 'repository-*.md' | sort | tail -n 1
}

fixlocal_test_init() {
  for dep in bash find git grep mktemp; do
    command -v "$dep" >/dev/null 2>&1 || fail "missing required command: $dep"
  done

  [[ -f "$FIXLOCAL_SRC" ]] || fail "missing script: $FIXLOCAL_SRC"
  [[ -f "$COMMON_HELPER_SRC" ]] || fail "missing helper: $COMMON_HELPER_SRC"
  [[ -f "$GIT_HELPER_SRC" ]] || fail "missing helper: $GIT_HELPER_SRC"
  [[ -f "$REPORT_HELPER_SRC" ]] || fail "missing helper: $REPORT_HELPER_SRC"
  [[ -f "$HEALTH_REPORT_HELPER_SRC" ]] || fail "missing helper: $HEALTH_REPORT_HELPER_SRC"
  [[ -f "$CKROLE_HELPER_SRC" ]] || fail "missing helper: $CKROLE_HELPER_SRC"

  TMPDIR="$(mktemp -d)"
  cleanup() {
    rm -rf "$TMPDIR"
  }
  trap cleanup EXIT

  REAL_GIT="$(command -v git)"
}
