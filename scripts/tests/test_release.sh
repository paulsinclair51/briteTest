#!/usr/bin/env bash

# test_release.sh - smoke tests for scripts/bin/release.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RELEASE_SRC="$REPO_ROOT/scripts/bin/release"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

for dep in bash find git grep mktemp; do
  command -v "$dep" >/dev/null 2>&1 || fail "missing required command: $dep"
done

TMPDIR="$(mktemp -d)"
cleanup() {
  chmod -R u+w "$TMPDIR" 2>/dev/null || true
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

ORIGIN="$TMPDIR/origin.git"
WORK="$TMPDIR/work"
FAKEBIN="$TMPDIR/fakebin"

git init --bare "$ORIGIN" >/dev/null 2>&1
git clone "file://$ORIGIN" "$WORK" >/dev/null 2>&1
mkdir -p "$WORK/scripts/bin" "$WORK/scripts/helpers" "$WORK/reports" "$FAKEBIN"
cp "$RELEASE_SRC" "$WORK/scripts/bin/release"
for helper in common.sh git_helpers.sh github_helpers.sh history_log.sh \
  report_helpers.sh; do
  cp "$REPO_ROOT/scripts/helpers/$helper" "$WORK/scripts/helpers/$helper"
done
chmod +x "$WORK/scripts/bin/release"

cat > "$FAKEBIN/gh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$FAKEBIN/gh"

(
  cd "$WORK"
  git config user.name "testuser"
  git config user.email "test@example.com"
  echo "seed" > README.md
  printf 'reports/*.md\n!reports/README.md\n' > .gitignore
  echo "# Reports" > reports/README.md
  git add README.md scripts reports .gitignore
  git commit -m "seed repo" >/dev/null 2>&1
  git branch -M main
  git push -u origin main >/dev/null 2>&1
  git tag -a v1.0.0 -m "existing release"
)

set +e
(
  cd "$WORK"
  PATH="$FAKEBIN:$PATH" bash ./scripts/bin/release -e
) >"$TMPDIR/error-run.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 8 ]] || fail "release -e should exit 8 (got $rc)"
grep -Fq "Release skipped due to -e option" "$TMPDIR/error-run.out" || \
  fail "expected release error-run message"
grep -Fq "See reports/release-e-" "$TMPDIR/error-run.out" || \
  fail "expected release error report path"
[[ -n "$(find "$WORK/reports" -maxdepth 1 -type f \
  -name 'release-e-*.md' -print -quit)" ]] || \
  fail "expected release error report"
echo "PASS: explicit error-run report"

set +e
(
  cd "$WORK"
  PATH="$FAKEBIN:$PATH" bash ./scripts/bin/release v1.1.0 -d
) >"$TMPDIR/dry-run.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "release -d should exit 0 (got $rc)"
grep -Fq "Dry-run: release v1.1.0 validation passed" \
  "$TMPDIR/dry-run.out" || fail "expected release dry-run summary"
grep -Fq "See reports/release-d-" "$TMPDIR/dry-run.out" || \
  fail "expected release dry-run report path"
git -C "$WORK" show-ref --verify --quiet refs/tags/v1.1.0 && \
  fail "release dry-run should not create a tag"
echo "PASS: dry-run report without release mutation"

set +e
(
  cd "$WORK"
  PATH="$FAKEBIN:$PATH" bash ./scripts/bin/release v1.1.0 -d -e
) >"$TMPDIR/mode-conflict.out" 2>&1
rc=$?
set -e
[[ "$rc" -eq 1 ]] || fail "release -d -e should exit 1 (got $rc)"
grep -Fq "mutually exclusive" "$TMPDIR/mode-conflict.out" || \
  fail "expected release mode conflict"
echo "PASS: dry-run and error-run conflict"

rm -f "$WORK"/reports/release-d-*.md "$WORK"/reports/release-e-*.md

set +e
(
  cd "$WORK"
  PATH="$FAKEBIN:$PATH" bash ./scripts/bin/release v1.0.0
) >"$TMPDIR/noop.out" 2>&1
rc=$?
set -e

[[ "$rc" -ne 0 ]] || fail "existing release should not be recreated"
grep -Fq "Tag already exists: v1.0.0" "$TMPDIR/noop.out" || \
  fail "expected existing-release summary"
[[ -z "$(find "$WORK/reports" -maxdepth 1 -type f -name 'release-*.md' -print -quit)" ]] || \
  fail "existing release should not create a report"

echo "PASS: existing release creates no report"
echo "All release smoke tests passed."