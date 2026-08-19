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
REPORT_SRC="$REPO_ROOT/scripts/bin/report"
COMMON_HELPER_SRC="$REPO_ROOT/scripts/helpers/common.sh"
REPORT_HELPER_SRC="$REPO_ROOT/scripts/helpers/report_helpers.sh"

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

report_path_from_output() {
  local output_file="$1"

  sed -n 's/^See \(reports\/\(local\|remote\)-[0-9]\{8\}-[0-9]\{6\}\.md\) for details\.$/\1/p' \
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
  mkdir -p "$WORK/scripts/bin" "$WORK/scripts/helpers"
  cp "$REPORT_SRC" "$WORK/scripts/bin/report"
  cp "$COMMON_HELPER_SRC" "$WORK/scripts/helpers/common.sh"
  cp "$REPORT_HELPER_SRC" "$WORK/scripts/helpers/report_helpers.sh"
  cat > "$WORK/scripts/helpers/ckstyle.sh" <<'EOF'
#!/usr/bin/env bash
bt_ckstyle() {
  printf '%s\n' "$@" > style-args.txt
  echo "See reports/style-test.md for details."
  exit 0
}
EOF
  cat > "$WORK/scripts/bin/lsbranch" <<'EOF'
#!/usr/bin/env bash
mkdir -p "$BRITETEST_LSBRANCH_REPORT_DIR"
report="$BRITETEST_LSBRANCH_REPORT_DIR/$BRITETEST_LSBRANCH_REPORT_PREFIX-test.md"
cat > "$report" <<'REPORT'
# Branch Report

| **Branch** | **Type** | **Status** |
| --- | --- | --- |
| dev/report-tests-v1.0.0 | local | clean |
REPORT
printf 'See %s for details.\n' "${report#"$PWD"/}"
EOF
  chmod +x "$WORK/scripts/bin/report" "$WORK/scripts/helpers/ckstyle.sh" \
    "$WORK/scripts/bin/lsbranch"

  (
    cd "$WORK"
    git init >/dev/null 2>&1
    git config user.name "testuser"
    git config user.email "test@example.com"

    ORIGIN="$TMPDIR/origin.git"
    git init --bare "$ORIGIN" >/dev/null 2>&1
    git remote add origin "$ORIGIN"

    echo "seed" > README.md
    git add README.md scripts
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
    git notes --ref=briteTest-workflow append -m \
      "--- briteTest workflow ---
Workflow-Type: push
Workflow-Time: 2026-08-16 11:59:59
Workflow-Branch: dev/report-tests-v1.0.0
Workflow-User: testuser <test@example.com>
Command-Line: push -t 5
Summary: Pushed 1 commit(s) to origin/dev/report-tests-v1.0.0
Details: Previous-Remote-Tip: $remote_push_previous; Pushed-Tip: $remote_push_tip; Commits: 1; Files: 1 modified, 0 added, 0 deleted" \
      "$remote_push_tip" >/dev/null 2>&1

    git commit --allow-empty \
      -m "mrgup activity" \
      >/dev/null 2>&1
    git notes --ref=briteTest-workflow append -m \
      "--- briteTest workflow ---
Workflow-Type: mrgup
Workflow-Time: 2026-08-16 12:00:01
Workflow-Branch: dev/report-tests-v1.0.0
Workflow-User: testuser <test@example.com>
Command-Line: mrgup -o
Summary: mrgup activity
Source-Branch: dev/source-v1.0.0
Target-Branch: v1.0.0
PR: 42
Status: Current branch merged into parent branch
Method: Squash merge created by mrgup
CI-CD: ci build SUCCESS" \
      HEAD >/dev/null 2>&1

    git commit --allow-empty \
      -m "copyfix activity" \
      >/dev/null 2>&1
    git notes --ref=briteTest-workflow append -m \
      "--- briteTest workflow ---
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
      -m "mrgdown activity" \
      -m $'## Workflow Metadata\n\nCommand-Line: mrgdown -f\nSource-Branch: v1.0.0\nTarget-Branch: dev/report-tests-v1.0.0\nParent-Commits-Integrated: 2\nFiles-Modified: 1\nFiles-Added: 1\nFiles-Deleted: 0\nStatus: Parent branch merged into current branch\nMethod: Merge commit (--no-ff) created by mrgdown' \
      >/dev/null 2>&1

    for workflow_type in push pull; do
      git notes --ref=briteTest-workflow append -m \
        "--- briteTest workflow ---
Workflow-Type: $workflow_type
Workflow-Time: 2026-08-16 12:00:0${#workflow_type}
Workflow-Branch: dev/report-tests-v1.0.0
Workflow-User: testuser <test@example.com>
Command-Line: $workflow_type -v
Summary: $workflow_type activity
Status: recorded $workflow_type details" HEAD >/dev/null 2>&1
    done

    retarget_tip="$(git rev-parse HEAD)"
    git notes --ref=briteTest-workflow append -m \
  "--- briteTest workflow ---
Workflow-Type: retarget
Workflow-Time: 2026-08-16 12:00:08
Workflow-Branch: dev/report-tests-v1.0.0
Workflow-User: testuser <test@example.com>
Command-Line: retarget -c move\\ branch dev/report-tests-v1.0.0 v1.1.0
Summary: retarget activity
Old-Parent: v1.0.0
New-Parent: v1.1.0
Retargeted-Tip: $retarget_tip
Comment: move branch" \
  HEAD >/dev/null 2>&1

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
