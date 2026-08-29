#!/usr/bin/env bash

# test_rmbranch.sh - smoke tests for briteRepo/bin/rmbranch
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common_test_helpers.sh
source "$SCRIPT_DIR/common_test_helpers.sh"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RMBRANCH_SRC="$REPO_ROOT/briteRepo/bin/rmbranch"
COMMON_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/common.sh"
GIT_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/git_helpers.sh"
HISTORY_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/history_log.sh"
CKROLE_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/ckrole.sh"
VALIDATION_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/validation_helpers.sh"
COMMON_UTILS_HELPER_SRC="$REPO_ROOT/briteRepo/helpers/common_utils.sh"

for dep in bash git grep mktemp; do
  command -v "$dep" >/dev/null 2>&1 || fail "missing required command: $dep"
done

[[ -f "$RMBRANCH_SRC" ]] || fail "missing script: $RMBRANCH_SRC"
[[ -f "$COMMON_HELPER_SRC" ]] || fail "missing helper: $COMMON_HELPER_SRC"
[[ -f "$GIT_HELPER_SRC" ]] || fail "missing helper: $GIT_HELPER_SRC"
[[ -f "$HISTORY_HELPER_SRC" ]] || fail "missing helper: $HISTORY_HELPER_SRC"
[[ -f "$CKROLE_HELPER_SRC" ]] || fail "missing helper: $CKROLE_HELPER_SRC"

TMPDIR="$(mktemp -d)"
cleanup() {
  if [[ "${KEEP_TMPDIR:-0}" == "1" ]]; then
    echo "KEEP_TMPDIR=1 preserving test artifacts at: $TMPDIR" >&2
    return 0
  fi
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

ORIGIN="$TMPDIR/origin.git"
WORK="$TMPDIR/work"

git init --bare "$ORIGIN" >/dev/null 2>&1
git clone "$ORIGIN" "$WORK" >/dev/null 2>&1

mkdir -p "$WORK/briteRepo/bin" "$WORK/briteRepo/helpers" "$WORK/config"
cp "$RMBRANCH_SRC" "$WORK/briteRepo/bin/rmbranch"
cp "$COMMON_HELPER_SRC" "$WORK/briteRepo/helpers/common.sh"
cp "$GIT_HELPER_SRC" "$WORK/briteRepo/helpers/git_helpers.sh"
cp "$HISTORY_HELPER_SRC" "$WORK/briteRepo/helpers/history_log.sh"
cp "$CKROLE_HELPER_SRC" "$WORK/briteRepo/helpers/ckrole.sh"
cp "$VALIDATION_HELPER_SRC" "$WORK/briteRepo/helpers/validation_helpers.sh"
cp "$COMMON_UTILS_HELPER_SRC" "$WORK/briteRepo/helpers/common_utils.sh"
chmod +x "$WORK/briteRepo/bin/rmbranch"

cat > "$WORK/config/contributors.md" <<'EOF'
- testuser,C,test@example.com
EOF

(
  cd "$WORK"
  git config user.name "testuser"
  git config user.email "test@example.com"

  cat > README.md <<'EOF'
# rmbranch fixture
EOF

  git add README.md briteRepo config
  git commit -m "seed repo" >/dev/null 2>&1
  git branch -M main
  git push -u origin main >/dev/null 2>&1

  # Create local+remote branch with intentionally non-conforming name.
  git checkout -b "Bad.Branch_Name" >/dev/null 2>&1
  echo "branch payload" > payload.txt
  git add payload.txt
  git commit -m "payload" >/dev/null 2>&1
  git push -u origin "Bad.Branch_Name" >/dev/null 2>&1
  git checkout main >/dev/null 2>&1

  # Create remote-only branch for remote deletion tests.
  git checkout -b "remote-only-delete" >/dev/null 2>&1
  echo "remote only" > remote_only.txt
  git add remote_only.txt
  git commit -m "remote only payload" >/dev/null 2>&1
  git push -u origin "remote-only-delete" >/dev/null 2>&1
  git checkout main >/dev/null 2>&1
  git branch -D "remote-only-delete" >/dev/null 2>&1

  # A nonzero-patch semantic version is policy-invalid, not protected.
  git checkout -b "v1.0.1" >/dev/null 2>&1
  git push -u origin "v1.0.1" >/dev/null 2>&1
  git checkout main >/dev/null 2>&1
  git branch -D "v1.0.1" >/dev/null 2>&1

  git checkout -b "v1.0.0" >/dev/null 2>&1
  git push -u origin "v1.0.0" >/dev/null 2>&1
  git checkout main >/dev/null 2>&1
  git branch -D "v1.0.0" >/dev/null 2>&1
)

# 1) Help output
rc=$(run_capture "$TMPDIR/help.out" bash -lc "cd '$WORK' && bash ./briteRepo/bin/rmbranch -h")
[[ "$rc" -eq 0 ]] || fail "rmbranch -h should exit 0"
assert_contains "Usage:" "$TMPDIR/help.out"
assert_contains "DELETE <branchname>" "$TMPDIR/help.out"
pass "help output"

# Risky deletion requires the exact branch-specific confirmation phrase.
(
  cd "$WORK"
  git checkout -b "confirm-delete" main >/dev/null 2>&1
  echo "confirm deletion" > confirm-delete.txt
  git add confirm-delete.txt
  git commit -m "confirm deletion" >/dev/null 2>&1
  git push -u origin "confirm-delete" >/dev/null 2>&1
  git checkout main >/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/confirm-cancel.out" env GITHUB_ACTOR=testuser \
  bash -lc "cd '$WORK' && printf 'DELETE wrong-branch\n' | bash ./briteRepo/bin/rmbranch -a -f confirm-delete")
[[ "$rc" -eq 2 ]] || fail "wrong deletion confirmation should cancel (got $rc)"
assert_contains "Type DELETE confirm-delete to confirm:" \
  "$TMPDIR/confirm-cancel.out"
git -C "$WORK" show-ref --verify --quiet refs/heads/confirm-delete || \
  fail "cancelled deletion should preserve local branch"
rc=$(run_capture "$TMPDIR/confirm-delete.out" env GITHUB_ACTOR=testuser \
  bash -lc "cd '$WORK' && printf 'DELETE confirm-delete\n' | bash ./briteRepo/bin/rmbranch -a -f confirm-delete")
[[ "$rc" -eq 0 ]] || fail "exact deletion confirmation should succeed (got $rc)"
pass "typed risky deletion confirmation"

# 2) Non-conforming branch names should still be removable.
rc=$(run_capture "$TMPDIR/nonconforming.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && printf 'DELETE Bad.Branch_Name\n' | bash ./briteRepo/bin/rmbranch -a -f 'Bad.Branch_Name'")
[[ "$rc" -eq 0 ]] || fail "rmbranch should delete non-conforming branch names (got $rc)"
if (cd "$WORK" && git show-ref --verify --quiet refs/heads/Bad.Branch_Name); then
  fail "local Bad.Branch_Name should be deleted"
fi
if (cd "$WORK" && git ls-remote --heads origin Bad.Branch_Name | grep -q 'Bad.Branch_Name'); then
  fail "remote Bad.Branch_Name should be deleted"
fi
pass "non-conforming branch deletion"

# A policy-invalid nonzero-patch branch is removable from remote.
rc=$(run_capture "$TMPDIR/nonzero-patch.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && printf 'DELETE v1.0.1\n' | bash ./briteRepo/bin/rmbranch -r 'v1.0.1'")
[[ "$rc" -eq 0 ]] || fail "rmbranch should delete policy-invalid v1.0.1 (got $rc)"
if (cd "$WORK" && git ls-remote --heads origin v1.0.1 | grep -q 'v1.0.1'); then
  fail "remote v1.0.1 should be deleted"
fi
pass "nonzero-patch invalid branch deletion"

# A valid .0 version branch remains protected from remote deletion.
rc=$(run_capture "$TMPDIR/version-protected.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/rmbranch -r 'v1.0.0'")
[[ "$rc" -eq 5 ]] || fail "rmbranch -r v1.0.0 should exit 5 (got $rc)"
assert_contains "is protected and cannot be removed" \
  "$TMPDIR/version-protected.out"
pass "version branch remote protection"

# 3) History propagation soft-fail should not abort remote deletion.
# logs/repository_history.md is intentionally absent in this fixture.
rc=$(run_capture "$TMPDIR/history-soft-fail.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && printf 'DELETE remote-only-delete\n' | bash ./briteRepo/bin/rmbranch -r 'remote-only-delete'")
[[ "$rc" -eq 0 ]] || fail "rmbranch -r should succeed when history propagation is unavailable (got $rc)"
if (cd "$WORK" && git ls-remote --heads origin remote-only-delete | grep -q 'remote-only-delete'); then
  fail "remote-only-delete should be deleted from origin"
fi
pass "history propagation soft-fail"

# 3b) Deletion logs should be recorded to main history regardless of current branch.
(
  cd "$WORK"
  git checkout -b "log-target-check" >/dev/null 2>&1
  git push -u origin "log-target-check" >/dev/null 2>&1
)
rc=$(run_capture "$TMPDIR/log-target.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && git checkout 'log-target-check' >/dev/null 2>&1 && printf 'DELETE log-target-check\n' | bash ./briteRepo/bin/rmbranch -r 'log-target-check'")
[[ "$rc" -eq 0 ]] || fail "rmbranch -r should delete a branch from a non-main working branch (got $rc)"
if (cd "$WORK" && git ls-remote --heads origin log-target-check | grep -q 'log-target-check'); then
  fail "log-target-check should be deleted from origin"
fi
main_note="$(cd "$WORK" && git notes --ref=briteRepo-workflow show refs/heads/main 2>/dev/null || true)"
if [[ -z "$main_note" ]]; then
  fail "rmbranch should record deletion history as a Git note on main"
fi
printf '%s\n' "$main_note" | grep -Fq "Workflow-Type: rmbranch" || fail "expected rmbranch workflow note on main"
printf '%s\n' "$main_note" | grep -Fq "Workflow-Branch: log-target-check" || fail "expected deleted branch name in main workflow note"
pass "main history log target"

# 4) Unauthorized user should be blocked.
rc=$(run_capture "$TMPDIR/unauthorized.out" env GITHUB_ACTOR=outsider bash -lc "cd '$WORK' && bash ./briteRepo/bin/rmbranch -r 'main'")
[[ "$rc" -eq 7 ]] || fail "unauthorized rmbranch call should exit 7 (got $rc)"
assert_contains "is not authorized to run rmbranch" "$TMPDIR/unauthorized.out"
pass "authorization enforcement"

# 5) Protected remote branch delete should fail with exit 5.
rc=$(run_capture "$TMPDIR/protected.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/rmbranch -r 'main'")
[[ "$rc" -eq 5 ]] || fail "rmbranch -r main should exit 5 (got $rc)"
assert_contains "is protected and cannot be removed" "$TMPDIR/protected.out"
pass "protected remote branch guard"

# 6) Local deletion should be blocked on dirty working tree.
(
  cd "$WORK"
  git checkout -b "dirty-local-delete" >/dev/null 2>&1
  echo "dirty target" > dirty_target.txt
  git add dirty_target.txt
  git commit -m "dirty target" >/dev/null 2>&1
  git checkout main >/dev/null 2>&1
)
printf '\nlocal dirty marker\n' >> "$WORK/README.md"
rc=$(run_capture "$TMPDIR/dirty-local.out" env GITHUB_ACTOR=testuser bash -lc "cd '$WORK' && bash ./briteRepo/bin/rmbranch -l 'dirty-local-delete'")
[[ "$rc" -eq 8 ]] || fail "rmbranch -l should exit 8 when worktree is dirty (got $rc)"
assert_contains "Working tree must be clean" "$TMPDIR/dirty-local.out"
(
  cd "$WORK"
  git checkout -- README.md >/dev/null 2>&1
)
pass "dirty worktree local deletion block"

REAL_GIT="$(command -v git)"
FAKEBIN="$TMPDIR/fakebin"
mkdir -p "$FAKEBIN"

# 7) Fetch failures should return actionable diagnostics.
cat > "$FAKEBIN/git" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "fetch" && "\${2:-}" == "origin" ]]; then
  echo "simulated fetch failure" >&2
  exit 1
fi
exec "$REAL_GIT" "\$@"
EOF
chmod +x "$FAKEBIN/git"

# Ensure a remote branch exists for this run.
(
  cd "$WORK"
  git checkout -b "fetch-fail-target" >/dev/null 2>&1
  echo "fetch fail target" > fetch_target.txt
  git add fetch_target.txt
  git commit -m "fetch target" >/dev/null 2>&1
  git push -u origin "fetch-fail-target" >/dev/null 2>&1
  git checkout main >/dev/null 2>&1
  git branch -D "fetch-fail-target" >/dev/null 2>&1
)

rc=$(run_capture "$TMPDIR/fetch-fail.out" env PATH="$FAKEBIN:$PATH" GITHUB_ACTOR=testuser bash -c "cd '$WORK' && bash ./briteRepo/bin/rmbranch -r 'fetch-fail-target'")
[[ "$rc" -eq 2 ]] || fail "rmbranch should exit 2 on fetch failure (got $rc)"
assert_contains "Failed to fetch from remote: simulated fetch failure" "$TMPDIR/fetch-fail.out"
pass "fetch failure diagnostics"

# 8) Remote delete failures should return actionable diagnostics.
cat > "$FAKEBIN/git" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "push" && "\${2:-}" == "origin" && "\${3:-}" == "--delete" ]]; then
  echo "simulated remote delete failure" >&2
  exit 1
fi
exec "$REAL_GIT" "\$@"
EOF
chmod +x "$FAKEBIN/git"

# Ensure target exists remotely.
(
  cd "$WORK"
  git checkout -b "push-fail-target" >/dev/null 2>&1
  echo "push fail target" > push_target.txt
  git add push_target.txt
  git commit -m "push target" >/dev/null 2>&1
  git push -u origin "push-fail-target" >/dev/null 2>&1
  git checkout main >/dev/null 2>&1
  git branch -D "push-fail-target" >/dev/null 2>&1
)

rc=$(run_capture "$TMPDIR/push-fail.out" env PATH="$FAKEBIN:$PATH" GITHUB_ACTOR=testuser bash -c "cd '$WORK' && printf 'DELETE push-fail-target\n' | bash ./briteRepo/bin/rmbranch -r 'push-fail-target'")
[[ "$rc" -eq 2 ]] || fail "rmbranch should exit 2 on remote delete failure (got $rc)"
assert_contains "Failed to delete remote branch 'push-fail-target': simulated remote delete failure" "$TMPDIR/push-fail.out"
pass "remote delete diagnostics"

echo "All rmbranch smoke tests passed."
