#!/usr/bin/env bash

# test_restore.sh - smoke tests for briteRepo/bin/restore.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

fail() { echo "FAIL: $1" >&2; exit 1; }
run_capture() {
  local output_file="$1"
  shift
  set +e
  "$@" > "$output_file" 2>&1
  local status=$?
  set -e
  printf '%s\n' "$status"
}

WORK="$TMPDIR/work"
git init -b main "$WORK" >/dev/null 2>&1
mkdir -p "$WORK/briteRepo/bin" "$WORK/briteRepo/helpers"
cp "$REPO_ROOT/briteRepo/bin/restore" "$WORK/briteRepo/bin/restore"
cp "$REPO_ROOT/briteRepo/helpers/common.sh" \
  "$REPO_ROOT/briteRepo/helpers/git_helpers.sh" \
  "$WORK/briteRepo/helpers/"
chmod +x "$WORK/briteRepo/bin/restore"
git -C "$WORK" config user.name restore-test
git -C "$WORK" config user.email restore@example.com
printf 'version one\n' > "$WORK/example.txt"
git -C "$WORK" add .
git -C "$WORK" commit -m "version one" >/dev/null 2>&1
printf 'version two\n' > "$WORK/example.txt"
git -C "$WORK" commit -am "version two" >/dev/null 2>&1

status="$(run_capture "$TMPDIR/help.out" \
  bash -c "cd '$WORK' && ./briteRepo/bin/restore -h")"
[[ "$status" -eq 0 ]] || fail "restore help should exit 0"
grep -Fq "restore [OPTIONS] FILE" "$TMPDIR/help.out" || \
  fail "restore help should document FILE"

status="$(run_capture "$TMPDIR/restore.out" \
  bash -c "cd '$WORK' && ./briteRepo/bin/restore -n 2 example.txt")"
[[ "$status" -eq 0 ]] || fail "restore -n should exit 0"
[[ "$(cat "$WORK/example.txt")" == "version one" ]] || \
  fail "restore should place the selected version in the worktree"
[[ -n "$(git -C "$WORK" status --short -- example.txt)" ]] || \
  fail "restored content should remain uncommitted"
grep -Fq "Review the file, then run commit" "$TMPDIR/restore.out" || \
  fail "restore should direct the user to the commit workflow"

status="$(run_capture "$TMPDIR/dirty.out" \
  bash -c "cd '$WORK' && ./briteRepo/bin/restore -n 1 example.txt")"
[[ "$status" -eq 1 ]] || fail "restore should reject a dirty target file"
grep -Fq "FILE has uncommitted changes" "$TMPDIR/dirty.out" || \
  fail "restore should explain dirty-file protection"

git -C "$WORK" restore example.txt
status="$(run_capture "$TMPDIR/range.out" \
  bash -c "cd '$WORK' && ./briteRepo/bin/restore -n 99 example.txt")"
[[ "$status" -eq 1 ]] || fail "restore should reject an invalid selection"
grep -Fq "Version selection is out of range" "$TMPDIR/range.out" || \
  fail "restore should explain invalid selections"

echo "All restore smoke tests passed."