#!/usr/bin/env bash

# test_lsbranch.sh - smoke tests for briteRepo/bin/lsbranch
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LSBRANCH="$SCRIPT_DIR/../bin/lsbranch"

pass() {
  echo "PASS: $1"
}

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

run_capture() {
  # Usage: run_capture <outfile> <command...>
  local outfile="$1"
  shift
  set +e
  "$@" >"$outfile" 2>&1
  local rc=$?
  set -e
  echo "$rc"
}

STATUS_TEST_REFS=()

cleanup_status_test_refs() {
  local ref

  for ref in "${STATUS_TEST_REFS[@]}"; do
    git update-ref -d "$ref" >/dev/null 2>&1 || true
  done
}

TMPDIR="$(mktemp -d)"
trap 'cleanup_status_test_refs; rm -rf "$TMPDIR"' EXIT
REAL_GIT="$(command -v git)"

# 1) Help output
rc=$(run_capture "$TMPDIR/help.out" "$LSBRANCH" -h)
[[ "$rc" -eq 0 ]] || fail "lsbranch -h should exit 0"
grep -q '^Usage:' "$TMPDIR/help.out" || fail "lsbranch -h should print Usage"
for status_tag in \
  "[local only]" "[remote only]" "[uncommitted]" "[invalid name]" \
  "[offline]" "[remote differs by N]" \
  "[local differs by N]" "[parent NAME]" \
  "[parent unavailable NAME]" "[parent NAME differs by N]" \
  "[copyfix in progress]" "[pushup in progress]" \
  "[pull in progress]" "[retarget in progress]" \
  "[pulldown in progress]" \
  "[PRs: N]"; do
  grep -Fq "$status_tag" "$TMPDIR/help.out" || \
    fail "lsbranch help should document $status_tag"
done
pass "help output"

mkdir -p "$TMPDIR/not-a-repo"
rc=$(run_capture "$TMPDIR/not-repo.out" bash -lc \
  "cd '$TMPDIR/not-a-repo' && '$LSBRANCH'")
[[ "$rc" -eq 8 ]] || fail "lsbranch outside repo should exit 8 (got $rc)"
grep -Fq 'inside a git repository' "$TMPDIR/not-repo.out" || \
  fail "lsbranch outside repo should explain the repository requirement"
pass "outside repository exit"

# 2) Remote timeout option validation
grep -q -- '-t SEC' "$TMPDIR/help.out" || \
  fail "lsbranch help should document -t SEC"
rc=$(run_capture "$TMPDIR/timeout_valid.out" "$LSBRANCH" -a -l -t 1)
[[ "$rc" -eq 0 ]] || fail "lsbranch -t should accept a positive integer"
rc=$(run_capture "$TMPDIR/timeout_zero.out" "$LSBRANCH" -a -l -t 0)
[[ "$rc" -eq 1 ]] || fail "lsbranch -t should reject zero"
rc=$(run_capture "$TMPDIR/timeout_missing.out" "$LSBRANCH" -a -l -t)
[[ "$rc" -eq 1 ]] || fail "lsbranch -t should reject a missing value"
pass "remote timeout option"

# 3) -a and PATTERN are mutually exclusive; no matches are not found.
rc=$(run_capture "$TMPDIR/all_and_pattern.out" "$LSBRANCH" -a "dev*" -l)
[[ "$rc" -eq 1 ]] || fail "lsbranch should reject -a with PATTERN"
grep -q 'Cannot combine PATTERN with -a' \
  "$TMPDIR/all_and_pattern.out" || \
  fail "lsbranch should explain the -a/PATTERN conflict"
rc=$(run_capture "$TMPDIR/no_match.out" "$LSBRANCH" "no-such-branch-*" -l)
[[ "$rc" -eq 2 ]] || fail "lsbranch should return 2 when no branches match"
grep -q 'No branches found matching pattern:' "$TMPDIR/no_match.out" || \
  fail "lsbranch should report a missing pattern match"
pass "selector and no-match behavior"

# 4) -a -r should include remote view output and not claim no branches for "*"
rc=$(run_capture "$TMPDIR/remote.out" "$LSBRANCH" -a -r)
[[ "$rc" -eq 0 ]] || fail "lsbranch -a -r should exit 0"
if grep -q 'No branches found matching pattern: \*' "$TMPDIR/remote.out"; then
  fail "lsbranch -a -r should not report no branches for '*'"
fi
grep -q '\[remote\]' "$TMPDIR/remote.out" || \
  fail "lsbranch -a -r should include [remote] output"

remote_only_branch=$(git branch -r | sed 's|^..origin/||' | \
  grep -v ' -> ' | while IFS= read -r b; do
  [[ -n "$b" ]] || continue
  if [[ -z "$(git branch --list "$b")" ]]; then
    echo "$b"
    break
  fi
done)
if [[ -n "$remote_only_branch" ]]; then
  grep -E "^${remote_only_branch} \[remote\]( .*)?$" "$TMPDIR/remote.out" >/dev/null || \
    fail "remote-only branch should be present in -a -r output"
fi
pass "-a -r includes remote rows"

# 5) -a -l should not print remote tags
rc=$(run_capture "$TMPDIR/local.out" "$LSBRANCH" -a -l)
[[ "$rc" -eq 0 ]] || fail "lsbranch -a -l should exit 0"
if grep -q '\[remote\]' "$TMPDIR/local.out"; then
  fail "lsbranch -a -l should not include [remote] output"
fi
grep -q '\[local\]' "$TMPDIR/local.out" || \
  fail "lsbranch -a -l should include [local] output"
pass "-a -l local-only output"

# 6) Normal use should write only branch status to stdout
reports_before="$(find "$SCRIPT_DIR/../../reports" -maxdepth 1 \
  -type f -name 'branch-*.md' -printf '%f\n' | sort)"
rc=$(run_capture "$TMPDIR/default.out" "$LSBRANCH")
[[ "$rc" -eq 0 ]] || fail "lsbranch should exit 0"
current_branch="$(source "$SCRIPT_DIR/../helpers/common.sh"; \
  bt_get_current_branch_or_empty)"
grep -Eq "^${current_branch} \\[current\\]" \
  "$TMPDIR/default.out" || \
  fail "current branch should be marked with [current] in stdout"
default_branch_rows="$(grep -Ec "^${current_branch} \\[" \
  "$TMPDIR/default.out")"
[[ "$default_branch_rows" -eq 2 ]] || \
  fail "default lsbranch should show current local and remote rows"
if grep -Ev "^${current_branch} \\[|^Warning:" \
  "$TMPDIR/default.out" | grep -q '[^[:space:]]'; then
  fail "default lsbranch should not list the parent as a separate branch"
fi
if grep -q '^See .* for details\.$' "$TMPDIR/default.out"; then
  fail "lsbranch should not output a report path"
fi
reports_after="$(find "$SCRIPT_DIR/../../reports" -maxdepth 1 \
  -type f -name 'branch-*.md' -printf '%f\n' | sort)"
[[ "$reports_after" == "$reports_before" ]] || \
  fail "lsbranch should not create or remove branch reports"
pass "stdout-only branch status"

# 7) A detached checkout at a remote-tracking ref is a remote snapshot.
snapshot_branch="$(source "$SCRIPT_DIR/../helpers/common.sh"; \
  bt_get_current_branch_or_empty)"
git switch --detach "refs/remotes/origin/$snapshot_branch" >/dev/null 2>&1 || \
  fail "could not create remote snapshot fixture"
rc=$(run_capture "$TMPDIR/remote-snapshot.out" "$LSBRANCH")
[[ "$rc" -eq 0 ]] || fail "remote snapshot status should exit 0"
grep -Fq "${snapshot_branch} [current]" \
  "$TMPDIR/remote-snapshot.out" || \
  fail "current remote snapshot should be labeled [remote snapshot]"
grep -Fq "[remote snapshot]" "$TMPDIR/remote-snapshot.out" || \
  fail "current remote snapshot should be labeled [remote snapshot]"
git switch "$snapshot_branch" >/dev/null 2>&1 || \
  fail "could not restore branch after remote snapshot fixture"
pass "current remote snapshot status"

# Internal r- branches are hidden and displayed through their source branch.
git branch -f "r-$snapshot_branch" "$snapshot_branch" >/dev/null 2>&1 || \
  fail "could not create internal remote snapshot branch"
git switch "r-$snapshot_branch" >/dev/null 2>&1 || \
  fail "could not select internal remote snapshot branch"
rc=$(run_capture "$TMPDIR/internal-remote-snapshot.out" "$LSBRANCH")
[[ "$rc" -eq 0 ]] || fail "internal remote snapshot status should exit 0"
grep -Fq "${snapshot_branch} [current]" \
  "$TMPDIR/internal-remote-snapshot.out" || \
  fail "lsbranch should display the source branch for an internal snapshot"
grep -Fq "[remote snapshot]" "$TMPDIR/internal-remote-snapshot.out" || \
  fail "lsbranch should label an internal snapshot"
if grep -Eq '^r-' "$TMPDIR/internal-remote-snapshot.out"; then
  fail "lsbranch should hide internal r- branches"
fi
git switch "$snapshot_branch" >/dev/null 2>&1 || \
  fail "could not restore branch after internal snapshot fixture"
git branch -D "r-$snapshot_branch" >/dev/null 2>&1 || \
  fail "could not remove internal remote snapshot fixture"
pass "internal remote snapshot display"

# 8) BRANCH mode allows only -v; local/remote filters are
# invalid in BRANCH mode
rc=$(run_capture "$TMPDIR/branch_mode_invalid.out" "$LSBRANCH" "v1.0.0" -l)
[[ "$rc" -eq 1 ]] || fail "lsbranch 'v1.0.0' -l should exit 1"
grep -q 'only -v is allowed' "$TMPDIR/branch_mode_invalid.out" || \
  fail "BRANCH mode should reject -l/-r/-i/-x"
pass "BRANCH mode option restrictions"

# 8) Literal dots in PATTERN should be treated literally, not as regex wildcard
rc=$(run_capture "$TMPDIR/literal.out" "$LSBRANCH" "v1.0.0*" -l)
[[ "$rc" -eq 0 ]] || fail "lsbranch 'v1.0.0*' -l should exit 0"
grep -Eq '^v1\.0\.0(\*| )' "$TMPDIR/literal.out" || \
  fail "literal dots in pattern should match branch v1.0.0"
pass "literal glob pattern behavior"

# 9) Dirty worktree should not cause non-current local branches to
# fail inspection
backup_file="$TMPDIR/lsbranch-dirty-backup"
scratch_file=$(git ls-files | while IFS= read -r path; do
  [[ -n "$path" ]] || continue
  [[ "$path" == reports/* ]] && continue
  if ! git diff --quiet -- "$path"; then
    continue
  fi
  echo "$path"
  break
done)
[[ -n "$scratch_file" ]] || \
  fail "need one clean tracked file for dirty-worktree smoke test"
cp "$scratch_file" "$backup_file"
trap 'rm -rf "$TMPDIR"; if [[ -f "$backup_file" && \
  -n "${scratch_file:-}" ]]; then cp "$backup_file" "$scratch_file"; fi; \
  cleanup_status_test_refs' EXIT
printf '\nlsbranch dirty smoke test\n' >> "$scratch_file"
rc=$(run_capture "$TMPDIR/dirty.out" "$LSBRANCH" -a -l)
[[ "$rc" -eq 0 ]] || fail "lsbranch -a -l should exit 0 with a dirty worktree"
if grep -q '\[check failed\]' "$TMPDIR/dirty.out"; then
  fail "lsbranch -a -l should not emit [check failed] for local \
branches when the worktree is dirty"
fi
current_branch="$(source "$SCRIPT_DIR/../helpers/common.sh"; \
  bt_get_current_branch_or_empty)"
grep -Eq "^${current_branch} \\[current\\]" \
  "$TMPDIR/dirty.out" || \
  fail "dirty current branch should be marked [uncommitted]"
grep -Eq "^${current_branch} .*\\[uncommitted\\]" \
  "$TMPDIR/dirty.out" || \
  fail "dirty current branch should be marked [uncommitted]"
if grep -Eq '\[(dirty|staged|unstaged)\]' "$TMPDIR/dirty.out"; then
  fail "stdout should not expose dirty/staged/unstaged status tags"
fi
if [[ "$current_branch" != "v1.0.0" ]]; then
  grep -q '^v1.0.0 \[local\]' "$TMPDIR/dirty.out" || \
    fail "non-current local protected branches should be listed"
  if grep -q '^v1.0.0 \[local\].*\[read-only\]' "$TMPDIR/dirty.out"; then
    fail "non-current local protected branches should not be marked [read-only]"
  fi
else
  grep -q '^v1.0.0\* \[current\] \[local\]' "$TMPDIR/dirty.out" || \
    fail "current protected branch should be shown as current"
fi
if grep -q '\[not checked out\]' "$TMPDIR/dirty.out"; then
  fail "non-current local branches should not include [not checked out]"
fi
cp "$backup_file" "$scratch_file"
pass "dirty worktree local branch inspection"

# 8) Compact status tags cover tracking relations and branch availability.
STATUS_BIN="$TMPDIR/status-bin"
mkdir -p "$STATUS_BIN"
cat > "$STATUS_BIN/git" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "fetch" &&
  ( "\${2:-}" == "origin" ||
    ( "\${2:-}" == "--prune" && "\${3:-}" == "origin" ) ) ]]; then
  exit 0
fi
exec "$REAL_GIT" "\$@"
EOF
cat > "$STATUS_BIN/gh" <<'EOF'
#!/usr/bin/env bash
echo 0
EOF
chmod +x "$STATUS_BIN/git" "$STATUS_BIN/gh"

status_parent="v1.0.0"
status_parent_tip=$(git rev-parse "$status_parent")
status_tree=$(git rev-parse "$status_parent_tip^{tree}")
status_index="$TMPDIR/status.index"
status_blob=$(printf 'lsbranch local status fixture\n' | git hash-object -w --stdin)
GIT_INDEX_FILE="$status_index" git read-tree "$status_tree"
GIT_INDEX_FILE="$status_index" git update-index --add \
  --cacheinfo "100644,$status_blob,.lsbranch-status"
status_changed_tree=$(GIT_INDEX_FILE="$status_index" git write-tree)
status_local_tip=$(printf 'lsbranch local status fixture\n' | \
  git -c user.name=lsbranch-test -c user.email=lsbranch@example.com \
    commit-tree "$status_changed_tree" -p "$status_parent_tip")
status_remote_tip=$(printf 'lsbranch remote status fixture\n' | \
  git -c user.name=lsbranch-test -c user.email=lsbranch@example.com \
    commit-tree "$status_tree" -p "$status_parent_tip")
status_branch="dev/lsbranch-status-v1.0.0"
status_local_ref="refs/heads/$status_branch"
status_remote_ref="refs/remotes/origin/$status_branch"
STATUS_TEST_REFS+=("$status_local_ref" "$status_remote_ref")

git update-ref "$status_local_ref" "$status_local_tip"
git update-ref "$status_remote_ref" "$status_parent_tip"
rc=$(run_capture "$TMPDIR/status-ahead.out" env PATH="$STATUS_BIN:$PATH" \
  "$LSBRANCH" "$status_branch")
[[ "$rc" -eq 0 ]] || fail "ahead status fixture should exit 0"
grep -Fq "[remote behind by 1]" "$TMPDIR/status-ahead.out" || \
  fail "local row should report ahead of remote"
grep -Fq "[local ahead by 1]" "$TMPDIR/status-ahead.out" || \
  fail "remote row should report behind local"
grep -Fq "[parent v1.0.0 behind by 1]" \
  "$TMPDIR/status-ahead.out" || fail "row should report parent identity"

status_parent_remote_tip=$(git rev-parse refs/remotes/origin/v1.0.0)
status_neutral_parent_tip=$(printf 'content-neutral parent fixture\n' | \
  git -c user.name=lsbranch-test -c user.email=lsbranch@example.com \
    commit-tree "$status_tree" -p "$status_parent_tip")
git update-ref refs/heads/v1.0.0 "$status_neutral_parent_tip"
git update-ref refs/remotes/origin/v1.0.0 "$status_neutral_parent_tip"
git update-ref "$status_local_ref" "$status_local_tip"
git update-ref "$status_remote_ref" "$status_local_tip"
rc=$(run_capture "$TMPDIR/status-neutral-parent.out" \
  env PATH="$STATUS_BIN:$PATH" "$LSBRANCH" "$status_branch")
[[ "$rc" -eq 0 ]] || fail "content-neutral parent fixture should exit 0"
if grep -Fq "[differs from parent" "$TMPDIR/status-neutral-parent.out"; then
  fail "content-neutral parent-only commits should not report divergence"
fi
[[ "$(grep -Fc "[parent v1.0.0 behind by 1]" \
  "$TMPDIR/status-neutral-parent.out")" -eq 2 ]] || \
  fail "local and remote rows should retain the child's actionable ahead count"
git update-ref refs/heads/v1.0.0 "$status_parent_tip"
git update-ref refs/remotes/origin/v1.0.0 "$status_parent_remote_tip"

status_content_match_tip=$(printf 'lsbranch matching-content fixture\n' | \
  git -c user.name=lsbranch-test -c user.email=lsbranch@example.com \
    commit-tree "$status_tree" -p "$status_parent_tip")
git update-ref "$status_local_ref" "$status_content_match_tip"
git update-ref "$status_remote_ref" "$status_content_match_tip"
rc=$(run_capture "$TMPDIR/status-content-match.out" env PATH="$STATUS_BIN:$PATH" \
  "$LSBRANCH" "$status_branch")
[[ "$rc" -eq 0 ]] || fail "matching-content fixture should exit 0"
grep -Fq "[parent v1.0.0]" \
  "$TMPDIR/status-content-match.out" || \
  fail "matching-content row should identify its parent"
if grep -E "^${status_branch} \[local\].*\[parent .* behind" \
  "$TMPDIR/status-content-match.out" >/dev/null; then
  fail "matching-content row should not imply another pushup is needed"
fi

git update-ref "$status_local_ref" "$status_parent_tip"
git update-ref "$status_remote_ref" "$status_remote_tip"
rc=$(run_capture "$TMPDIR/status-behind.out" env PATH="$STATUS_BIN:$PATH" \
  "$LSBRANCH" "$status_branch")
[[ "$rc" -eq 0 ]] || fail "behind status fixture should exit 0"
if grep -Eq '\[(remote behind|behind remote|local behind|behind local|differs)' \
  "$TMPDIR/status-behind.out"; then
  fail "content-neutral tracking history should not produce a status tag"
fi

git update-ref "$status_local_ref" "$status_local_tip"
rc=$(run_capture "$TMPDIR/status-diverged.out" env PATH="$STATUS_BIN:$PATH" \
  "$LSBRANCH" "$status_branch")
[[ "$rc" -eq 0 ]] || fail "diverged status fixture should exit 0"
grep -Fq "[remote differs by 1]" "$TMPDIR/status-diverged.out" || \
  fail "local row should report divergence from remote"
grep -Fq "[local differs by 1]" "$TMPDIR/status-diverged.out" || \
  fail "remote row should report divergence from local"

git update-ref "$status_remote_ref" "$status_local_tip"
rc=$(run_capture "$TMPDIR/status-synced.out" env PATH="$STATUS_BIN:$PATH" \
  "$LSBRANCH" "$status_branch")
[[ "$rc" -eq 0 ]] || fail "synced status fixture should exit 0"
if grep -Fq "[synced]" "$TMPDIR/status-synced.out"; then
  fail "matching local and remote histories should omit synced"
fi
rc=$(run_capture "$TMPDIR/status-remote-filter.out" \
  env PATH="$STATUS_BIN:$PATH" "$LSBRANCH" "${status_branch}*" -r)
[[ "$rc" -eq 0 ]] || fail "remote-filter status fixture should exit 0"
grep -Fq "[remote]" \
  "$TMPDIR/status-remote-filter.out" || \
  fail "remote-only listing should retain tracked synchronization status"

git update-ref -d "$status_remote_ref"
rc=$(run_capture "$TMPDIR/status-local-only.out" \
  env PATH="$STATUS_BIN:$PATH" "$LSBRANCH" "$status_branch")
[[ "$rc" -eq 0 ]] || fail "local-only status fixture should exit 0"
grep -Fq "[local only]" "$TMPDIR/status-local-only.out" || \
  fail "branch without a remote should report local only"

git update-ref -d "$status_local_ref"
git update-ref "$status_remote_ref" "$status_remote_tip"
rc=$(run_capture "$TMPDIR/status-remote-only.out" \
  env PATH="$STATUS_BIN:$PATH" "$LSBRANCH" "$status_branch")
[[ "$rc" -eq 0 ]] || fail "remote-only status fixture should exit 0"
grep -Fq "[remote only]" "$TMPDIR/status-remote-only.out" || \
  fail "branch without a local branch should report remote only"
if grep -Fq "[remote only] [read-only]" "$TMPDIR/status-remote-only.out"; then
  fail "non-current remote-only branches should not be marked [read-only]"
fi

invalid_branch="dev/lsbranch-invalid-v1.0.1"
invalid_ref="refs/heads/$invalid_branch"
STATUS_TEST_REFS+=("$invalid_ref")
git update-ref "$invalid_ref" "$status_local_tip"
rc=$(run_capture "$TMPDIR/status-invalid.out" env PATH="$STATUS_BIN:$PATH" \
  "$LSBRANCH" "$invalid_branch")
[[ "$rc" -eq 0 ]] || fail "invalid-name status fixture should exit 0"
grep -Fq "[invalid name]" "$TMPDIR/status-invalid.out" || \
  fail "invalid branch should report invalid name"
if grep -Fq "[read-only] [invalid name]" "$TMPDIR/status-invalid.out"; then
  fail "non-current invalid branches should not be marked [read-only]"
fi

missing_parent_branch="dev/lsbranch-parent-v99.0.0"
missing_parent_ref="refs/heads/$missing_parent_branch"
STATUS_TEST_REFS+=("$missing_parent_ref")
git update-ref "$missing_parent_ref" "$status_local_tip"
rc=$(run_capture "$TMPDIR/status-parent-unavailable.out" \
  env PATH="$STATUS_BIN:$PATH" "$LSBRANCH" "$missing_parent_branch")
[[ "$rc" -eq 0 ]] || fail "unavailable-parent fixture should exit 0"
grep -Fq "[parent unavailable v99.0.0]" \
  "$TMPDIR/status-parent-unavailable.out" || \
  fail "missing parent branch should report parent unavailable"
pass "chbranch-compatible status tags"

# 10) Verbose mode should surface degraded fetch/PR lookups
FAKEBIN="$TMPDIR/fakebin"
mkdir -p "$FAKEBIN"
cat > "$FAKEBIN/git" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "fetch" &&
  ( "\${2:-}" == "origin" ||
    ( "\${2:-}" == "--prune" && "\${3:-}" == "origin" ) ) ]]; then
  echo "simulated fetch failure" >&2
  exit 1
fi
exec "$REAL_GIT" "\$@"
EOF
chmod +x "$FAKEBIN/git"
cat > "$FAKEBIN/gh" <<'EOF'
#!/usr/bin/env bash
echo "simulated gh failure" >&2
exit 1
EOF
chmod +x "$FAKEBIN/gh"

rc=$(run_capture "$TMPDIR/degraded.out" env PATH="$FAKEBIN:$PATH" \
  "$LSBRANCH" -a -r -v)
[[ "$rc" -eq 0 ]] || \
  fail "lsbranch -a -r -v should tolerate degraded fetch/PR helpers"
grep -q "Warning: Failed to fetch remote; remote status may use cached refs from your last successful remote update." "$TMPDIR/degraded.out" || \
  fail "verbose output should include fetch diagnostics"
grep -q "Warning: Failed to query pull requests for 'main'; PR column shown as N/A." "$TMPDIR/degraded.out" || \
  fail "verbose output should include PR diagnostics"
grep -Fq "[offline]" "$TMPDIR/degraded.out" || \
  fail "degraded remote rows should be marked [offline]"
pass "degraded helper diagnostics"

echo "All lsbranch smoke tests passed."
