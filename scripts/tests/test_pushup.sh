#!/usr/bin/env bash

# Focused pushup transaction and resume tests.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

fail() { echo "FAIL: $1" >&2; exit 1; }
assert_contains() { grep -Fq -- "$1" "$2" || fail "expected '$1' in $2"; }
run_capture() {
  local output_file="$1"
  shift
  set +e
  "$@" >"$output_file" 2>&1
  local status=$?
  set -e
  printf '%s\n' "$status"
}

ORIGIN="$TMPDIR/origin.git"
WORK="$TMPDIR/work"
git init --bare "$ORIGIN" >/dev/null
git init -b main "$WORK" >/dev/null
git -C "$WORK" config user.name "Pushup Test"
git -C "$WORK" config user.email "pushup@example.com"
git -C "$WORK" remote add origin "$ORIGIN"
mkdir -p "$WORK/scripts/bin" "$WORK/scripts/helpers" "$WORK/reports"
cp "$REPO_ROOT/scripts/bin/pushup" "$WORK/scripts/bin/pushup"
cp "$REPO_ROOT/scripts/helpers/common.sh" \
  "$REPO_ROOT/scripts/helpers/git_helpers.sh" \
  "$REPO_ROOT/scripts/helpers/report_helpers.sh" "$WORK/scripts/helpers/"
chmod +x "$WORK/scripts/bin/pushup"

printf 'base\n' > "$WORK/content.txt"
git -C "$WORK" add content.txt
git -C "$WORK" commit -m base >/dev/null
git -C "$WORK" push -u origin main >/dev/null
git -C "$WORK" checkout -b feature >/dev/null
printf 'feature\n' >> "$WORK/content.txt"
git -C "$WORK" commit -am feature >/dev/null
git -C "$WORK" push -u origin feature >/dev/null

cat > "$WORK/scripts/helpers/pushup_parent.sh" <<'EOF'
#!/usr/bin/env bash
set -e
git checkout main >/dev/null
git merge --squash feature >/dev/null
git commit -m "pushed up" >/dev/null
EOF
cat > "$WORK/scripts/bin/push" <<'EOF'
#!/usr/bin/env bash
set -e
branch="$(git branch --show-current)"
if [[ -f .fail-parent-push && "$branch" == main ]]; then
  exit 80
fi
git push origin "$branch" >/dev/null
EOF
cat > "$WORK/scripts/bin/chbranch" <<'EOF'
#!/usr/bin/env bash
git checkout "${@: -1}" >/dev/null
EOF
cat > "$WORK/scripts/bin/pulldown" <<'EOF'
#!/usr/bin/env bash
set -e
if [[ -f .fail-sync-once ]]; then
  rm -f .fail-sync-once
  exit 81
fi
git fetch origin main >/dev/null
git merge --no-edit origin/main >/dev/null
EOF
cat > "$WORK/scripts/bin/pull" <<'EOF'
#!/usr/bin/env bash
git pull --rebase origin "$(git branch --show-current)" >/dev/null
EOF
chmod +x "$WORK/scripts/bin/"{push,chbranch,pulldown,pull} "$WORK/scripts/helpers/pushup_parent.sh"

source_tip="$(git -C "$WORK" rev-parse feature)"
parent_tip="$(git -C "$WORK" rev-parse main)"
touch "$WORK/.fail-parent-push"
status="$(run_capture "$TMPDIR/rollback.out" bash -c \
  "cd '$WORK' && ./scripts/bin/pushup")"
[[ "$status" -eq 4 ]] || fail "pre-publication failure should exit 4, got $status"
[[ "$(git -C "$WORK" branch --show-current)" == feature ]] || \
  fail "rollback should restore source checkout"
[[ "$(git -C "$WORK" rev-parse main)" == "$parent_tip" ]] || \
  fail "rollback should restore parent tip"
[[ "$(git -C "$WORK" rev-parse feature)" == "$source_tip" ]] || \
  fail "rollback should restore source tip"
[[ ! -f "$WORK/.git/briteTest/pushup.state" ]] || \
  fail "rollback should remove pushup state"
assert_contains "No local push-up changes were retained" "$TMPDIR/rollback.out"
echo "PASS: pre-publication failure restores local state"

rm -f "$WORK/.fail-parent-push"
touch "$WORK/.fail-sync-once"
status="$(run_capture "$TMPDIR/partial.out" bash -c \
  "cd '$WORK' && ./scripts/bin/pushup")"
[[ "$status" -eq 5 ]] || fail "post-publication failure should exit 5, got $status"
[[ -f "$WORK/.git/briteTest/pushup.state" ]] || fail "partial run should retain state"
[[ "$(git config --file "$WORK/.git/briteTest/pushup.state" --get pushup.phase)" == \
  source-sync-failed ]] || fail "partial run should record failed synchronization"
report="$(find "$WORK/reports" -name 'pushup-e-*.md' | head -n 1)"
[[ -n "$report" ]] || fail "partial run should write a pushup error report"
assert_contains '| Publish parent | Completed |' "$report"
assert_contains '| Synchronize source from parent | Pending |' "$report"
assert_contains 'pushup --continue' "$report"
echo "PASS: partial report identifies completed and pending work"

status="$(run_capture "$TMPDIR/continue.out" bash -c \
  "cd '$WORK' && ./scripts/bin/pushup --continue")"
[[ "$status" -eq 0 ]] || fail "continue should complete pushup, got $status"
[[ ! -f "$WORK/.git/briteTest/pushup.state" ]] || \
  fail "completed pushup should remove state"
[[ "$(git --git-dir="$ORIGIN" rev-parse main)" == "$(git -C "$WORK" rev-parse main)" ]] || \
  fail "parent should be published"
[[ "$(git --git-dir="$ORIGIN" rev-parse feature)" == \
  "$(git -C "$WORK" rev-parse feature)" ]] || fail "source should be published"
assert_contains 'Push-up complete' "$TMPDIR/continue.out"
echo "PASS: pushup --continue completes retained work"