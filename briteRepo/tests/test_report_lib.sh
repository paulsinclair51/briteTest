#!/usr/bin/env bash

# Shared test helpers for report smoke tests.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPORT_SRC="$REPO_ROOT/briteRepo/bin/report"
COMMON_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/common.sh"
GIT_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/git_helpers.sh"
REPORT_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/report_helpers.sh"

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

assert_matches() {
  local regex="$1"
  local file="$2"
  grep -Eq -- "$regex" "$file" || fail "expected pattern '$regex' in $file"
}

report_path_from_output() {
  local output_file="$1"

  sed -n "s/^See '\(reports\/\(local\|remote\)-[0-9]\{8\}-[0-9]\{6\}[+-][0-9]\{4\}\.md\)'\.$/\1/p" \
    "$output_file" | tail -n 1
}

report_test_init() {
  for dep in bash git grep mktemp; do
    command -v "$dep" >/dev/null 2>&1 || fail "missing required command: $dep"
  done

  [[ -f "$REPORT_SRC" ]] || fail "missing script: $REPORT_SRC"
  [[ -f "$COMMON_HELPER_SRC" ]] || fail "missing helper: $COMMON_HELPER_SRC"
  [[ -f "$REPORT_HELPER_SRC" ]] || fail "missing helper: $REPORT_HELPER_SRC"

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

  WORK="$TMPDIR/work"
  mkdir -p "$WORK/briteRepo/bin" "$WORK/briteRepo/helpers"
  cp "$REPORT_SRC" "$WORK/briteRepo/bin/report"
  cp "$COMMON_HELPER_SRC" "$WORK/briteRepo/helpers/common.sh"
  cp "$GIT_HELPER_SRC" "$WORK/briteRepo/helpers/git_helpers.sh"
  cp "$REPORT_HELPER_SRC" "$WORK/briteRepo/helpers/report_helpers.sh"
  cat > "$WORK/briteRepo/helpers/ckstyle.sh" <<'EOF'
#!/usr/bin/env bash
bt_ckstyle() {
  printf '%s\n' "$@" > style-args.txt
  echo "See reports/style-test.md for details."
  exit 0
}
EOF
  cat > "$WORK/briteRepo/bin/lsbranch" <<'EOF'
#!/usr/bin/env bash
report_dir="$2"
report_prefix="$3"
mkdir -p "$report_dir"
report="$report_dir/$report_prefix-test.md"
cat > "$report" <<'REPORT'
# Branch Report

| **Branch** | **Type** | **Status** |
| --- | --- | --- |
| dev/report-tests-v1.0.0 | local | clean |
REPORT
printf "See '%s'.\n" "${report#"$PWD"/}"
EOF
  chmod +x "$WORK/briteRepo/bin/report" "$WORK/briteRepo/helpers/ckstyle.sh" \
    "$WORK/briteRepo/bin/lsbranch"

  (
    cd "$WORK"
    git init >/dev/null 2>&1
    git config user.name "testuser"
    git config user.email "test@example.com"

    ORIGIN="$TMPDIR/origin.git"
    git init --bare "$ORIGIN" >/dev/null 2>&1
    git remote add origin "$ORIGIN"

    echo "seed" > README.md
    git add README.md briteRepo
    git commit -m "seed repo" >/dev/null 2>&1

    git checkout -b dev/report-tests-v1.0.0 >/dev/null 2>&1

    echo "payload" > payload.txt
    git add payload.txt
    git commit \
      -m "dev/report-tests-v1.0.0 committed by contributor testuser" \
      -m $'## User Comment\n\n> first line\n> Files-Modified: 999\n\n## Summary\n- Files: 1 modified, 0 added, and 0 deleted.\n- Lines: 3 added and 1 deleted.\n\n## Commit Metadata\n\nFiles-Modified: 1\nFiles-Added: 0\nFiles-Deleted: 0\nLines-Added: 3\nLines-Deleted: 1\nCommand-Line: commit -c <user-comment>\nPR: 123' \
      >/dev/null 2>&1

    git push -u origin dev/report-tests-v1.0.0 >/dev/null 2>&1

    echo "push delta" >> payload.txt
    git add payload.txt
    git commit -m "push delta seed" >/dev/null 2>&1
    git push origin dev/report-tests-v1.0.0 >/dev/null 2>&1

    remote_push_tip="$(git rev-parse origin/dev/report-tests-v1.0.0)"
    remote_push_previous="$(git rev-parse "${remote_push_tip}^")"
    git notes --ref=briteRepo-remote-workflow append -m \
      "--- briteRepo workflow ---
Workflow-Type: push
Workflow-Time: 2026-08-16 11:59:59
Workflow-Branch: dev/report-tests-v1.0.0
Workflow-User: testuser <test@example.com>
Command-Line: push -t 5
Summary: Pushed 1 commit(s) to origin/dev/report-tests-v1.0.0
Details: Previous-Remote-Tip: $remote_push_previous; Pushed-Tip: $remote_push_tip; Commits: 1; Files: 1 modified, 0 added, 0 deleted" \
      "$remote_push_tip" >/dev/null 2>&1
    git push origin \
      refs/notes/briteRepo-remote-workflow:refs/notes/briteRepo-remote-workflow \
      >/dev/null 2>&1

    git commit --allow-empty -m "empty push metadata only" >/dev/null 2>&1
    git push origin dev/report-tests-v1.0.0 >/dev/null 2>&1
    empty_push_tip="$(git rev-parse origin/dev/report-tests-v1.0.0)"
    git notes --ref=briteRepo-remote-workflow append -m \
      "--- briteRepo workflow ---
Workflow-Type: push
Workflow-Time: 2026-08-16 12:00:00
Workflow-Branch: dev/report-tests-v1.0.0
Workflow-User: testuser <test@example.com>
Command-Line: push -t 5
Summary: Pushed 1 empty commit(s) to origin/dev/report-tests-v1.0.0
Details: Previous-Remote-Tip: $remote_push_tip; Pushed-Tip: $empty_push_tip; Commits: 1; Files: 0 modified, 0 added, 0 deleted" \
      "$empty_push_tip" >/dev/null 2>&1
    git push origin \
      refs/notes/briteRepo-remote-workflow:refs/notes/briteRepo-remote-workflow \
      >/dev/null 2>&1

    git commit --allow-empty \
      -m "pushup activity" \
      >/dev/null 2>&1
    git notes --ref=briteRepo-workflow append -m \
      "--- briteRepo workflow ---
Workflow-Type: pushup
Workflow-Time: 2026-08-16 12:00:01
Workflow-Branch: v1.0.0
Workflow-User: testuser <test@example.com>
Command-Line: pushup -o
Summary: pushup activity
Source-Branch: dev/report-tests-v1.0.0
Target-Branch: v1.0.0
PR: 42
Status: Current branch merged into parent branch
Method: Squash merge created by pushup
CI-CD: ci build SUCCESS" \
      HEAD >/dev/null 2>&1

    git commit --allow-empty \
      -m "copyfix activity" \
      >/dev/null 2>&1
    git notes --ref=briteRepo-workflow append -m \
      "--- briteRepo workflow ---
Workflow-Type: copyfix
Workflow-Time: 2026-08-16 12:00:02
Workflow-Branch: dev/report-tests-v1.0.0
Workflow-User: testuser <test@example.com>
Command-Line: copyfix fix/source-v1.0.0
Summary: copyfix activity
Source-Branch: fix/source-v1.0.0
Target-Branch: dev/report-tests-v1.0.0
Commits-Copied: 2
Files-Modified: 1
Files-Added: 1
Files-Deleted: 0
Status: Fix commits copied to target branch
Method: Cherry-pick created by copyfix" \
      HEAD >/dev/null 2>&1

    git commit --allow-empty \
      -m "pulldown activity" \
      -m $'## Workflow Metadata\n\nCommand-Line: pulldown -f\nSource-Branch: v1.0.0\nTarget-Branch: dev/report-tests-v1.0.0\nParent-Commits-Integrated: 2\nFiles-Modified: 1\nFiles-Added: 1\nFiles-Deleted: 0\nStatus: Parent branch merged into current branch\nMethod: Merge commit (--no-ff) created by pulldown' \
      >/dev/null 2>&1

    git notes --ref=briteRepo-workflow append -m \
      "--- briteRepo workflow ---
Workflow-Type: pull
Workflow-Time: 2026-08-16 12:00:04
Workflow-Branch: dev/report-tests-v1.0.0
Workflow-User: testuser <test@example.com>
Command-Line: pull -v
Summary: pull activity
Record-Group: appended pair
  Status: recorded pull details with --- briteRepo workflow --- marker" \
  HEAD >/dev/null 2>&1

    git notes --ref=briteRepo-workflow append -m \
      "--- briteRepo workflow ---
Workflow-Type: mkbranch
Workflow-Time: 2026-08-16 12:00:05
Workflow-Branch: dev/report-tests-v1.0.0
Workflow-User: testuser <test@example.com>
Command-Line: mkbranch dev/report-tests-v1.0.0 v1.0.0
Summary: mkbranch activity
New-Branch: dev/report-tests-v1.0.0
Parent-Branch: v1.0.0
Status: SUCCESS" \
  HEAD >/dev/null 2>&1

    git notes --ref=briteRepo-workflow append -m \
      "--- briteRepo workflow ---
Workflow-Type: release
Workflow-Time: 2026-08-16 12:00:06
Workflow-Branch: dev/report-tests-v1.0.0
Workflow-User: testuser <test@example.com>
Command-Line: release v1.2.0
Summary: release activity
Version: v1.2.0
Status: Released" \
  HEAD >/dev/null 2>&1

    git notes --ref=briteRepo-workflow append -m \
      "--- briteRepo workflow ---
Workflow-Type: undo
Workflow-Time: 2026-08-16 12:00:07
Workflow-Branch: dev/report-tests-v1.0.0
Workflow-User: testuser <test@example.com>
Command-Line: undo commit
Summary: undo activity
Undo-Type: commit
Details: Soft reset from abc123" \
  HEAD >/dev/null 2>&1

    retarget_tip="$(git rev-parse HEAD)"
    git notes --ref=briteRepo-workflow append -m \
  "--- briteRepo workflow ---
Workflow-Type: retarget
Workflow-Time: 2026-08-16 12:00:08
Workflow-Branch: dev/report-tests-v1.0.0
Workflow-User: testuser <test@example.com>
Command-Line: retarget -c move\\ branch dev/report-tests-v1.0.0 v1.1.0
Summary: retarget activity
Old-Parent: v1.0.0
New-Parent: v1.1.0
Retargeted-Tip: $retarget_tip
Record-Group: appended pair
Comment: move branch" \
  HEAD >/dev/null 2>&1

    git notes --ref=briteRepo-workflow append -m \
      "--- briteRepo workflow ---
Workflow-Type: push
Workflow-Time: 2026-08-16 12:00:09
Workflow-Branch: dev/report-tests-v1.0.0
Workflow-User: testuser <test@example.com>
Command-Line: push
Status: malformed fixture missing summary" HEAD >/dev/null 2>&1

    git checkout -b sandbox/report-other >/dev/null 2>&1
    echo "other" > other.txt
    git add other.txt
    git commit \
      -m "sandbox/report-other committed by contributor testuser" \
      -m $'## User Comment\n\n> other branch\n\n## Commit Metadata\n\nFiles-Modified: 1\nFiles-Added: 0\nFiles-Deleted: 0\nLines-Added: 1\nLines-Deleted: 0\nCommand-Line: commit -c <user-comment>' \
      >/dev/null 2>&1

    git checkout dev/report-tests-v1.0.0 >/dev/null 2>&1
  )
}
