#!/usr/bin/env bash

# test_rmclone.sh - smoke tests for briteRepo/bin/rmclone.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=common_test_helpers.sh
source "$SCRIPT_DIR/common_test_helpers.sh"

RMCLONE_SRC="$REPO_ROOT/briteRepo/bin/rmclone"
COMMON_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/common.sh"
GIT_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/git_helpers.sh"
HISTORY_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/history_log.sh"

for required in "$RMCLONE_SRC" "$COMMON_HELPER_SRC" "$GIT_HELPER_SRC" \
  "$HISTORY_HELPER_SRC"; do
  [[ -f "$required" ]] || fail "missing source file: $required"
done

TMPDIR="$(mktemp -d)"
cleanup() {
  chmod -R u+w "$TMPDIR" 2>/dev/null || true
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

git_quiet() {
  git -c init.defaultBranch=main -c user.name=tester \
    -c user.email=tester@example.com "$@"
}

# rmclone appends a workflow note to the repository it is run from, so every
# run must happen inside this fixture rather than the real repository.
RUNNER="$TMPDIR/runner"
mkdir -p "$RUNNER/briteRepo/bin" "$RUNNER/briteRepo/helpers"
cp "$RMCLONE_SRC" "$RUNNER/briteRepo/bin/rmclone"
cp "$COMMON_HELPER_SRC" "$RUNNER/briteRepo/helpers/common.sh"
cp "$GIT_HELPER_SRC" "$RUNNER/briteRepo/helpers/git_helpers.sh"
cp "$HISTORY_HELPER_SRC" "$RUNNER/briteRepo/helpers/history_log.sh"
chmod +x "$RUNNER/briteRepo/bin/rmclone"
(
  cd "$RUNNER"
  git_quiet init -q .
  echo runner > runner.txt
  git_quiet add -A
  git_quiet commit -qm "runner fixture"
)

ORIGIN="$TMPDIR/origin.git"
git_quiet init -q --bare "$ORIGIN"
SEED="$TMPDIR/seed"
git_quiet clone -q "file://$ORIGIN" "$SEED" 2>/dev/null
(
  cd "$SEED"
  echo seed > seed.txt
  git_quiet add -A
  git_quiet commit -qm "seed commit"
  git_quiet push -q origin HEAD:main
)

# Create a clean clone whose commits all exist on a reachable origin.
make_clone() {
  local path="$1"
  rm -rf "$path"
  git_quiet clone -q "file://$ORIGIN" "$path"
}

run_rmclone() {
  local outfile="$1"
  shift
  run_capture "$outfile" env HOME="$TMPDIR" bash -c \
    "cd '$RUNNER' && bash ./briteRepo/bin/rmclone $*"
}

# 1) Help output documents the supported options.
rc=$(run_rmclone "$TMPDIR/help.out" -h)
[[ "$rc" -eq 0 ]] || fail "rmclone -h should exit 0 (got $rc)"
assert_contains "Usage:" "$TMPDIR/help.out"
assert_contains "-d          Dry-run." "$TMPDIR/help.out"
assert_contains "--override  Override safety checks" "$TMPDIR/help.out"
pass "help output"

# 2) Undocumented aliases are rejected.
for removed_alias in -O --dry-run; do
  rc=$(run_rmclone "$TMPDIR/alias.out" "$removed_alias" "$TMPDIR/seed")
  [[ "$rc" -eq 1 ]] || fail "rmclone $removed_alias should exit 1 (got $rc)"
  assert_contains "Unknown option: $removed_alias" "$TMPDIR/alias.out"
done
pass "undocumented option aliases rejected"

# 3) Exactly one clone path is required.
rc=$(run_rmclone "$TMPDIR/noargs.out")
[[ "$rc" -eq 1 ]] || fail "rmclone without a path should exit 1 (got $rc)"
assert_contains "Expected exactly 1 argument" "$TMPDIR/noargs.out"

rc=$(run_rmclone "$TMPDIR/twoargs.out" "$TMPDIR/seed" "$TMPDIR/runner")
[[ "$rc" -eq 1 ]] || fail "rmclone with two paths should exit 1 (got $rc)"
assert_contains "Expected exactly 1 argument" "$TMPDIR/twoargs.out"
pass "argument count validation"

# 4) Timeout validation rejects non-positive values.
rc=$(run_rmclone "$TMPDIR/timeout.out" -t 0 "$TMPDIR/seed")
[[ "$rc" -eq 1 ]] || fail "rmclone -t 0 should exit 1 (got $rc)"
assert_contains "SEC for -t must be an integer greater than 0" \
  "$TMPDIR/timeout.out"
pass "timeout validation"

# 5) A missing target path is an argument error.
rc=$(run_rmclone "$TMPDIR/missing.out" "$TMPDIR/does-not-exist")
[[ "$rc" -eq 1 ]] || fail "rmclone on a missing path should exit 1 (got $rc)"
assert_contains "Clone path not found or not a directory" "$TMPDIR/missing.out"
pass "missing target path"

# 6) Dry-run reports the plan and leaves the clone in place.
make_clone "$TMPDIR/clone-dry"
rc=$(run_rmclone "$TMPDIR/dryrun.out" -d "$TMPDIR/clone-dry")
[[ "$rc" -eq 0 ]] || fail "rmclone -d should exit 0 on a clean clone (got $rc)"
assert_contains "Safety checks passed." "$TMPDIR/dryrun.out"
assert_contains "Dry-run mode enabled. No files were removed." \
  "$TMPDIR/dryrun.out"
assert_contains "Would remove clone directory" "$TMPDIR/dryrun.out"
[[ -d "$TMPDIR/clone-dry" ]] || fail "rmclone -d must not remove the clone"
pass "dry-run leaves the clone in place"

# 7) Safety checks block removal of a dirty clone without --override.
make_clone "$TMPDIR/clone-dirty"
echo "uncommitted" > "$TMPDIR/clone-dirty/dirty.txt"
rc=$(run_rmclone "$TMPDIR/dirty.out" "$TMPDIR/clone-dirty")
[[ "$rc" -eq 2 ]] || fail "dirty clone removal should exit 2 (got $rc)"
assert_contains "Working tree is not clean" "$TMPDIR/dirty.out"
assert_contains "Re-run with --override to override safety checks." \
  "$TMPDIR/dirty.out"
[[ -d "$TMPDIR/clone-dirty" ]] || fail "blocked removal must keep the clone"
pass "dirty clone blocked without override"

# 8) --override bypasses the safety checks and the confirmation prompt.
rc=$(run_rmclone "$TMPDIR/override.out" --override "$TMPDIR/clone-dirty")
[[ "$rc" -eq 0 ]] || fail "rmclone --override should exit 0 (got $rc)"
assert_contains "Override enabled (--override)." "$TMPDIR/override.out"
[[ ! -e "$TMPDIR/clone-dirty" ]] || fail "--override should remove the clone"
pass "override removes a dirty clone"

# 9) A non-Git directory is reported as unsafe.
mkdir -p "$TMPDIR/plain-dir"
rc=$(run_rmclone "$TMPDIR/plain.out" "$TMPDIR/plain-dir")
[[ "$rc" -eq 2 ]] || fail "non-Git target should exit 2 (got $rc)"
assert_contains "Target is not a valid Git repository" "$TMPDIR/plain.out"
pass "non-Git target blocked"

# 10) The repository rmclone runs from is never a removal target.
rc=$(run_rmclone "$TMPDIR/self.out" "$RUNNER")
[[ "$rc" -eq 2 ]] || fail "removing the runner repository should exit 2 (got $rc)"
assert_contains "Refusing to remove the current" "$TMPDIR/self.out"
[[ -d "$RUNNER" ]] || fail "runner repository must not be removed"
pass "repository root is protected"

# 11) A clean clone is removed once safety checks pass.
make_clone "$TMPDIR/clone-clean"
rc=$(run_rmclone "$TMPDIR/clean.out" --override "$TMPDIR/clone-clean")
[[ "$rc" -eq 0 ]] || fail "clean clone removal should exit 0 (got $rc)"
assert_contains "Safety checks passed." "$TMPDIR/clean.out"
assert_contains "Removed clone" "$TMPDIR/clean.out"
[[ ! -e "$TMPDIR/clone-clean" ]] || fail "clean clone should be removed"
pass "clean clone removed"

echo "All rmclone smoke tests passed."
