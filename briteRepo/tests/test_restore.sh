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
printf 'version three\n' > "$WORK/example.txt"
git -C "$WORK" commit -am "version three" >/dev/null 2>&1
mkdir -p "$WORK/one" "$WORK/two"
printf 'one current\n' > "$WORK/one/shared.txt"
printf 'two current\n' > "$WORK/two/shared.txt"
git -C "$WORK" add one/shared.txt two/shared.txt
git -C "$WORK" commit -m "add duplicate names" >/dev/null 2>&1
printf 'one previous\n' > "$WORK/one/shared.txt"
printf 'two previous\n' > "$WORK/two/shared.txt"
git -C "$WORK" commit -am "update duplicate names" >/dev/null 2>&1
mkdir -p "$WORK/docs"
printf 'root readme\n' > "$WORK/README.md"
printf 'docs readme\n' > "$WORK/docs/README.md"
mkdir -p "$WORK/alternate"
printf 'root target\n' > "$WORK/target.txt"
printf 'alternate target\n' > "$WORK/alternate/target.txt"
ln -s example.txt "$WORK/example-link.txt"
ln -s target.txt "$WORK/target-link.txt"
mkdir -p "$WORK/links"
ln -s ../example.txt "$WORK/links/example-link.txt"
git -C "$WORK" add README.md docs/README.md target.txt alternate/target.txt \
  example-link.txt target-link.txt
git -C "$WORK" add links/example-link.txt
git -C "$WORK" commit -m "add readmes and symlink" >/dev/null 2>&1
printf 'shared 1\nshared 2\nshared 3\nshared 4\nbefore rename\n' \
  > "$WORK/old-name.txt"
git -C "$WORK" add old-name.txt
git -C "$WORK" commit -m "add old name" >/dev/null 2>&1
git -C "$WORK" mv old-name.txt renamed.txt
printf 'shared 1\nshared 2\nshared 3\nshared 4\nafter rename\n' \
  > "$WORK/renamed.txt"
git -C "$WORK" commit -am "rename file" >/dev/null 2>&1

status="$(run_capture "$TMPDIR/help.out" \
  bash -c "cd '$WORK' && ./briteRepo/bin/restore -h")"
[[ "$status" -eq 0 ]] || fail "restore help should exit 0"
grep -Fq "restore [OPTIONS] FILE" "$TMPDIR/help.out" || \
  fail "restore help should document FILE"
grep -Fq -- "-l LIMIT" "$TMPDIR/help.out" || \
  fail "restore help should document the version limit"

status="$(run_capture "$TMPDIR/readme-path.out" \
  bash -c "cd '$WORK' && ./briteRepo/bin/restore README.md")"
[[ "$status" -eq 1 ]] || fail "README.md basename should require a path"
grep -Fq "README.md requires an explicit path" "$TMPDIR/readme-path.out" || \
  fail "restore should explain the README.md path requirement"

status="$(run_capture "$TMPDIR/symlink.out" \
  bash -c "cd '$WORK' && ./briteRepo/bin/restore ./example-link.txt")"
[[ "$status" -eq 0 ]] || fail "restore should guide a symbolic link selection"
grep -Fq "'./example-link.txt' is a symbolic link. Run 'restore example.txt' instead" \
  "$TMPDIR/symlink.out" || \
  fail "restore should identify the symbolic link path and target"

status="$(run_capture "$TMPDIR/qualified-symlink.out" \
  bash -c "cd '$WORK' && ./briteRepo/bin/restore links/example-link.txt")"
[[ "$status" -eq 0 ]] || fail "restore should guide a qualified symbolic link"
grep -Fq "'links/example-link.txt' is a symbolic link. Run 'restore example.txt' instead" \
  "$TMPDIR/qualified-symlink.out" || \
  fail "duplicate link names should be qualified by repository path"

status="$(run_capture "$TMPDIR/ambiguous-target.out" \
  bash -c "cd '$WORK' && ./briteRepo/bin/restore ./target-link.txt")"
[[ "$status" -eq 0 ]] || fail "restore should guide a link with ambiguous target name"
grep -Fq "'target-link.txt' is a symbolic link. Run 'restore ./target.txt' instead" \
  "$TMPDIR/ambiguous-target.out" || \
  fail "ambiguous root link targets should be path-qualified"

status="$(run_capture "$TMPDIR/restore.out" \
  bash -c "cd '$WORK' && printf 'bad\n1\n' | ./briteRepo/bin/restore -l 2 example.txt")"
[[ "$status" -eq 0 ]] || fail "interactive restore should exit 0"
[[ "$(grep -Ec '^  [0-9]+\.' "$TMPDIR/restore.out")" -eq 2 ]] || \
  fail "restore -l 2 should list exactly two versions"
[[ "$(cat "$WORK/example.txt")" == "version two" ]] || \
  fail "restore should place the selected version in the worktree"
grep -Fq "Select a number from 1 through 2" "$TMPDIR/restore.out" || \
  fail "restore should explain invalid input and reprompt"
[[ -n "$(git -C "$WORK" status --short -- example.txt)" ]] || \
  fail "restored content should remain uncommitted"
grep -Fq "Review the file, then run commit" "$TMPDIR/restore.out" || \
  fail "restore should direct the user to the commit workflow"

status="$(run_capture "$TMPDIR/dirty.out" \
  bash -c "cd '$WORK' && ./briteRepo/bin/restore example.txt")"
[[ "$status" -eq 1 ]] || fail "restore should reject a dirty target file"
grep -Fq "FILE has uncommitted changes" "$TMPDIR/dirty.out" || \
  fail "restore should explain dirty-file protection"

git -C "$WORK" restore example.txt
status="$(run_capture "$TMPDIR/range.out" \
  bash -c "cd '$WORK' && printf '99\nq\n' | ./briteRepo/bin/restore -l 2 example.txt")"
[[ "$status" -eq 0 ]] || fail "restore should allow cancellation after invalid input"
grep -Fq "Restore cancelled." "$TMPDIR/range.out" || \
  fail "restore should support q cancellation"

status="$(run_capture "$TMPDIR/limit.out" \
  bash -c "cd '$WORK' && ./briteRepo/bin/restore -l 1 example.txt")"
[[ "$status" -eq 1 ]] || fail "restore should reject a limit below 2"
grep -Fq "Option -l requires an integer greater than 1" "$TMPDIR/limit.out" || \
  fail "restore should explain invalid limits"

status="$(run_capture "$TMPDIR/ambiguous.out" \
  bash -c "cd '$WORK' && printf '2\n1\n' | ./briteRepo/bin/restore shared.txt")"
[[ "$status" -eq 0 ]] || fail "restore should disambiguate duplicate basenames"
grep -Fq "one/shared.txt" "$TMPDIR/ambiguous.out" || \
  fail "restore should list the first matching path"
grep -Fq "two/shared.txt" "$TMPDIR/ambiguous.out" || \
  fail "restore should list the second matching path"
[[ "$(cat "$WORK/two/shared.txt")" == "two current" ]] || \
  fail "restore should use the selected matching path and prior version"
git -C "$WORK" restore two/shared.txt

status="$(run_capture "$TMPDIR/rename.out" \
  bash -c "cd '$WORK' && printf '1\n' | ./briteRepo/bin/restore renamed.txt")"
[[ "$status" -eq 0 ]] || fail "restore should follow file renames"
[[ "$(cat "$WORK/renamed.txt")" == \
  $'shared 1\nshared 2\nshared 3\nshared 4\nbefore rename' ]] || \
  fail "restore should recover content from before a rename"
git -C "$WORK" restore renamed.txt

status="$(run_capture "$TMPDIR/eof.out" \
  bash -c "cd '$WORK' && ./briteRepo/bin/restore example.txt </dev/null")"
[[ "$status" -eq 0 ]] || fail "EOF should cancel restore cleanly"
grep -Fq "Restore cancelled: no selection received." "$TMPDIR/eof.out" || \
  fail "restore should explain EOF cancellation"

echo "All restore smoke tests passed."