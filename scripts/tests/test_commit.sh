#!/usr/bin/env bash

# test_commit.sh - smoke tests for scripts/bin/commit
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, '<repo>/LICENSE'.

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

# 1) Help output
rc=$(run_capture "$TMPDIR/help.out" bash -lc "cd '$WORK' && bash ./scripts/bin/commit -h")
[[ "$rc" -eq 0 ]] || fail "commit -h should exit 0"
assert_contains "Usage:" "$TMPDIR/help.out"
pass "help output"

# 2) Unauthorized user should be blocked with exit 5
printf '\nunauthorized role test\n' >> "$WORK/README.md"
(
  cd "$WORK"
  git config user.email "outsider@example.com"
)
rc=$(run_capture "$TMPDIR/unauth.out" env GITHUB_ACTOR=outsider bash -lc "cd '$WORK' && bash ./scripts/bin/commit -d -c 'test unauthorized'")
[[ "$rc" -eq 5 ]] || fail "unauthorized user should exit 5 (got $rc)"
assert_contains "is not authorized to run commit" "$TMPDIR/unauth.out"
(
  cd "$WORK"
  git config user.email "test@example.com"
)
pass "role validation"

# 3) Dry-run commit should succeed for contributor and generate report
rc=$(run_capture "$TMPDIR/dry.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/commit -d -c 'dry run commit'")
[[ "$rc" -eq 0 ]] || fail "dry-run commit should exit 0 (got $rc)"
dry_report="$(latest_report "$WORK")"
[[ -f "$dry_report" ]] || fail "expected dry-run commit report"
assert_contains "See reports/branch/commit-d-" "$TMPDIR/dry.out"
[[ "$(basename "$dry_report")" == commit-d-* ]] || fail "expected dry-run report filename"
assert_contains "**Commit Hash**" "$dry_report"
if grep -Fq -- "| n/a |" "$dry_report"; then
  fail "dry-run commit report should leave Commit Hash blank"
fi
pass "dry-run commit"

# 4) Missing message when changes exist should fail with exit 6
printf '\nmessage required test\n' >> "$WORK/README.md"
rc=$(run_capture "$TMPDIR/missing-message.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/commit")
[[ "$rc" -eq 6 ]] || fail "missing message should exit 6 (got $rc)"
assert_contains "Commit comment is required" "$TMPDIR/missing-message.out"
pass "missing message handling"

# 5) Empty message when changes exist should fail with exit 7
printf '\nempty message test\n' >> "$WORK/README.md"
rc=$(run_capture "$TMPDIR/empty-message.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/commit -c '   '")
[[ "$rc" -eq 7 ]] || fail "empty message should exit 7 (got $rc)"
assert_contains "must include at least one non-whitespace character" "$TMPDIR/empty-message.out"
pass "empty message handling"

# 6) -p should be rejected (auto-push is now implicit)
rc=$(run_capture "$TMPDIR/p_option.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/commit -d -p -c 'invalid option test'")
[[ "$rc" -eq 1 ]] || fail "commit -p should exit 1 (got $rc)"
assert_contains "Unknown option: -p" "$TMPDIR/p_option.out"
pass "-p option rejection"

# 7) Positional file arguments should be rejected
rc=$(run_capture "$TMPDIR/positional.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/commit README.md -c 'invalid positional arg test'")
[[ "$rc" -eq 1 ]] || fail "commit with positional file argument should exit 1 (got $rc)"
assert_contains "Unexpected argument: README.md" "$TMPDIR/positional.out"
pass "positional file argument rejection"

# 8) Diverged local/remote history should auto-resolve and succeed with guidance
git clone "$ORIGIN" "$PEER" >/dev/null 2>&1
(
  cd "$PEER"
  git config user.name "peer"
  git config user.email "peer@example.com"
  git checkout dev/commit-tests-v1.0.0 >/dev/null 2>&1
  echo "peer change" > PEER_ONLY.md
  git add PEER_ONLY.md
  git commit -m "peer update" >/dev/null 2>&1
  git push origin dev/commit-tests-v1.0.0 >/dev/null 2>&1
)
(
  cd "$WORK"
  git fetch origin dev/commit-tests-v1.0.0 >/dev/null 2>&1
)
echo "local diverged change" > LOCAL_ONLY.md
rc=$(run_capture "$TMPDIR/diverged.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/commit -c 'local diverged change'")
[[ "$rc" -eq 0 ]] || fail "diverged branch auto-resolve should exit 0 (got $rc)"
assert_contains "auto-resolved" "$TMPDIR/diverged.out"
assert_contains "review resolved code" "$TMPDIR/diverged.out"
diverged_report="$(latest_report "$WORK")"
[[ -f "$diverged_report" ]] || fail "expected diverged commit report"
assert_contains "**Commit Hash**" "$diverged_report"
diverged_pushed_hash="$(extract_report_hash "Pushed Commit Hash" "$diverged_report")"
[[ "$diverged_pushed_hash" =~ ^[0-9a-f]+$ ]] || fail "expected pushed commit hash in diverged report"
if ! (cd "$WORK" && git cat-file -e "${diverged_pushed_hash}^{commit}" >/dev/null 2>&1); then
  fail "pushed commit hash from report does not resolve to a commit"
fi
if ! (cd "$WORK" && git merge-base --is-ancestor "$diverged_pushed_hash" HEAD >/dev/null 2>&1); then
  fail "pushed code commit hash should be an ancestor of final HEAD"
fi
assert_contains "**Commit Comment:** local diverged change" "$diverged_report"
assert_contains "local diverged change" "$diverged_report"
if grep -q '^## Commit Entries Selected For Push' "$diverged_report"; then
  fail "commit report should not include the old push-entries section"
fi
pass "divergence auto-resolution"

# 9) Pending local commit without a push in this run should use selected-for-push label
printf '\npending push direct commit\n' >> "$WORK/README.md"
(
  cd "$WORK"
  git add README.md
  git commit -m "manual pending push" >/dev/null 2>&1
)
pending_hash_before_run="$(cd "$WORK" && git rev-parse --short HEAD)"
rc=$(run_capture "$TMPDIR/pending-push.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/commit -d -c 'pending push dry run'")
[[ "$rc" -eq 0 ]] || fail "commit -d with pending local push should exit 0 (got $rc)"
pending_report="$(latest_report "$WORK")"
[[ -f "$pending_report" ]] || fail "expected pending-push commit report"
assert_contains "**Commit Selected for Push Hash:** $pending_hash_before_run" "$pending_report"
assert_contains "**Commit Comment:** manual pending push" "$pending_report"
if grep -q '^\*\*Pushed Commit Hash:\*\*' "$pending_report"; then
  fail "pending-push report should not use pushed-commit label"
fi
pass "pending push label"

# 10) No remote-tracked branch should omit push-summary line entirely
(
  cd "$WORK"
  git checkout -b local-only-commit-test >/dev/null 2>&1
)
printf '\nlocal only branch change\n' >> "$WORK/README.md"
rc=$(run_capture "$TMPDIR/no-remote.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./scripts/bin/commit -d -c 'local only dry run'")
[[ "$rc" -eq 0 ]] || fail "commit -d on local-only branch should exit 0 (got $rc)"
no_remote_report="$(latest_report "$WORK")"
[[ -f "$no_remote_report" ]] || fail "expected local-only commit report"
if grep -q '^\*\*Pushed Commit Hash and Comment:\*\*' "$no_remote_report"; then
  fail "local-only report should omit pushed-commit summary line"
fi
if grep -q '^\*\*Pushed Commit Hash:\*\*' "$no_remote_report"; then
  fail "local-only report should omit pushed-commit summary line"
fi
if grep -q '^\*\*Commit Selected for Push Hash:\*\*' "$no_remote_report"; then
  fail "local-only report should omit selected-for-push summary line"
fi
pass "no remote push summary omission"

echo "All commit smoke tests passed."
