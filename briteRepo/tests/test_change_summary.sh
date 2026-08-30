#!/usr/bin/env bash

# test_change_summary.sh - comprehensive change-summary helper tests.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../helpers/git_helpers.sh
source "$SCRIPT_DIR/../helpers/git_helpers.sh"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -z "$(bt_git_format_tracking_relation_tag local 0 0 0)" ]] || \
  fail "zero-difference tracking tag should be omitted"
[[ "$(bt_git_format_tracking_relation_tag local 2 0 1)" == \
  "[remote behind by 1]" ]] || fail "local-ahead tracking tag"
[[ "$(bt_git_format_tracking_relation_tag remote 2 0 1)" == \
  "[local ahead by 1]" ]] || fail "remote-behind tracking tag"
[[ "$(bt_git_format_tracking_relation_tag local 2 3 4)" == \
  "[remote differs by 4]" ]] || \
  fail "local tracking divergence tag"
[[ "$(bt_git_format_tracking_relation_tag remote 2 3 4)" == \
  "[local differs by 4]" ]] || \
  fail "remote tracking divergence tag"
[[ "$(bt_git_format_parent_relation_tags v1.0.0 2 3 true 4)" == \
  "[parent v1.0.0 differs by 4]" ]] || \
  fail "parent divergence tags"
[[ "$(bt_git_format_parent_relation_tags v2.0.0 0 0 false)" == \
  "[parent unavailable v2.0.0]" ]] || fail "unavailable parent tag"

cat > "$TMPDIR/old-files" <<'EOF'
same.txt
deleted-root.txt
rename-old/pure.txt
rename-mod-old/changed.txt
split-old/one.txt
split-old/two.txt
gone-dir/file.txt
EOF
cat > "$TMPDIR/new-files" <<'EOF'
same.txt
added-root.txt
rename-new/pure.txt
rename-mod-new/changed.txt
split-new-a/one.txt
split-new-b/two.txt
new-dir/file.txt
EOF
printf 'M\0same.txt\0D\0deleted-root.txt\0A\0added-root.txt\0' \
  > "$TMPDIR/status"
printf 'R100\0rename-old/pure.txt\0rename-new/pure.txt\0' \
  >> "$TMPDIR/status"
printf 'R075\0rename-mod-old/changed.txt\0rename-mod-new/changed.txt\0' \
  >> "$TMPDIR/status"
printf 'R100\0split-old/one.txt\0split-new-a/one.txt\0' \
  >> "$TMPDIR/status"
printf 'R100\0split-old/two.txt\0split-new-b/two.txt\0' \
  >> "$TMPDIR/status"
printf 'D\0gone-dir/file.txt\0A\0new-dir/file.txt\0' \
  >> "$TMPDIR/status"

bt_git_collect_change_summary_from_files \
  "$TMPDIR/status" "$TMPDIR/old-files" "$TMPDIR/new-files"

[[ "$BT_CHANGE_MODIFIED_FILES" -eq 1 ]] || fail "modified file count"
[[ "$BT_CHANGE_DELETED_FILES" -eq 2 ]] || fail "deleted file count"
[[ "$BT_CHANGE_ADDED_FILES" -eq 2 ]] || fail "added file count"
[[ "$BT_CHANGE_RENAMED_FILES" -eq 3 ]] || fail "renamed file count"
[[ "$BT_CHANGE_RENAMED_MODIFIED_FILES" -eq 1 ]] || \
  fail "renamed/modified file count"
[[ "$BT_CHANGE_DELETED_DIRECTORIES" -eq 1 ]] || \
  fail "deleted directory count"
[[ "$BT_CHANGE_ADDED_DIRECTORIES" -eq 1 ]] || \
  fail "added directory count"
[[ "$BT_CHANGE_RENAMED_DIRECTORIES" -eq 4 ]] || \
  fail "renamed directory count"

expected="1 modified file, 2 deleted files, 2 added files, 3 renamed files, 1 renamed/modified file, 1 deleted directory, 1 added directory and 4 renamed directories"
[[ "$(bt_format_change_summary)" == "$expected" ]] || \
  fail "comprehensive summary formatting"

bt_git_reset_change_summary
BT_CHANGE_ADDED_FILES=1
[[ "$(bt_format_change_summary)" == "1 added file" ]] || \
  fail "zero suppression and singular formatting"

echo "All change summary tests passed."