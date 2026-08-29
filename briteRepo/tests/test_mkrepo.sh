#!/usr/bin/env bash

# test_mkrepo.sh - smoke tests for briteRepo/bin/mkrepo
#
# GitHub access is stubbed with a fake 'gh' command backed by local bare
# repositories, so these tests never contact github.com.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MKREPO="$REPO_ROOT/briteRepo/bin/mkrepo"

pass() {
  echo "PASS: $1"
}

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

WORK_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

run_capture() {
  local outfile="$1"
  shift
  set +e
  "$@" >"$outfile" 2>&1
  local rc=$?
  set -e
  echo "$rc"
}

# Commit identity for the working clones mkrepo creates.
export GIT_AUTHOR_NAME="Test User"
export GIT_AUTHOR_EMAIL="test@example.com"
export GIT_COMMITTER_NAME="Test User"
export GIT_COMMITTER_EMAIL="test@example.com"

# Fake 'gh' backed by bare repositories under $GH_FAKE_REMOTES.
export GH_FAKE_REMOTES="$WORK_DIR/remotes"
mkdir -p "$GH_FAKE_REMOTES" "$WORK_DIR/bin"
cat > "$WORK_DIR/bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  auth) exit 0 ;;
  api)
    [[ "${2:-}" == "user" ]] || exit 1
    echo "testuser"
    exit 0
    ;;
  repo)
    sub="${2:-}"
    slug="${3:-}"
    bare="$GH_FAKE_REMOTES/${slug#*/}.git"
    case "$sub" in
      view)
        [[ -d "$bare" ]] || exit 1
        if git -C "$bare" rev-parse --verify HEAD >/dev/null 2>&1; then
          git -C "$bare" symbolic-ref --short HEAD
        else
          echo ""
        fi
        exit 0
        ;;
      create)
        [[ ! -d "$bare" ]] || exit 1
        git init -q --bare -b main "$bare"
        exit 0
        ;;
      clone)
        git clone -q "$bare" "${4:-}"
        exit 0
        ;;
    esac
    exit 1
    ;;
esac
exit 1
EOF
chmod +x "$WORK_DIR/bin/gh"
export PATH="$WORK_DIR/bin:$PATH"

# Run from a neutral directory so the sibling-clone check is not triggered.
cd "$WORK_DIR"

# Help output
rc="$(run_capture "$WORK_DIR/help.out" bash "$MKREPO" -h)"
[[ "$rc" -eq 0 ]] || fail "mkrepo -h exit code $rc"
grep -Fq "mkrepo [OPTIONS] <repository>" "$WORK_DIR/help.out" || \
  fail "mkrepo -h missing usage line"
pass "mkrepo -h prints usage"

# Invalid option
rc="$(run_capture "$WORK_DIR/bad.out" bash "$MKREPO" --bogus new-repo)"
[[ "$rc" -eq 1 ]] || fail "mkrepo --bogus exit code $rc (expected 1)"
pass "mkrepo rejects unknown options with exit 1"

# Missing repository argument
rc="$(run_capture "$WORK_DIR/noarg.out" bash "$MKREPO")"
[[ "$rc" -eq 1 ]] || fail "mkrepo without arguments exit code $rc (expected 1)"
pass "mkrepo requires a repository argument"

# Invalid repository name
rc="$(run_capture "$WORK_DIR/name.out" bash "$MKREPO" "bad name")"
[[ "$rc" -eq 1 ]] || fail "mkrepo with invalid name exit code $rc (expected 1)"
rc="$(run_capture "$WORK_DIR/owner.out" bash "$MKREPO" "someone/repo")"
[[ "$rc" -eq 1 ]] || fail "mkrepo with OWNER/NAME exit code $rc (expected 1)"
pass "mkrepo rejects invalid repository names"

# Invalid timeout
rc="$(run_capture "$WORK_DIR/timeout.out" bash "$MKREPO" -t 0 new-repo)"
[[ "$rc" -eq 1 ]] || fail "mkrepo -t 0 exit code $rc (expected 1)"
pass "mkrepo rejects an invalid -t value"

# Dry run for a repository that does not exist creates nothing on the remote
rc="$(run_capture "$WORK_DIR/dry.out" bash "$MKREPO" -d dry-repo)"
[[ "$rc" -eq 0 ]] || fail "mkrepo -d exit code $rc"
[[ ! -d "$GH_FAKE_REMOTES/dry-repo.git" ]] || \
  fail "mkrepo -d created the remote repository"
grep -Fq "Dry run complete" "$WORK_DIR/dry.out" || \
  fail "mkrepo -d missing dry-run summary"
grep -Fq "Report:" "$WORK_DIR/dry.out" || \
  fail "mkrepo -d did not report a report path"
DRY_REPORT="$(sed -n 's/^Report: //p' "$WORK_DIR/dry.out")"
[[ -f "$DRY_REPORT" ]] || fail "dry-run report not written to $DRY_REPORT"
[[ "$DRY_REPORT" == *"/mkrepo-d-"*.md ]] || \
  fail "unexpected dry-run report name: $DRY_REPORT"
grep -Fxq "# mkrepo Dry-Run Report" "$DRY_REPORT" || \
  fail "dry-run report missing its heading"
grep -Fxq "Commit: To be determined" "$DRY_REPORT" || \
  fail "dry-run report missing the placeholder commit"
grep -Fq "## Follow-Up Items" "$DRY_REPORT" || \
  fail "dry-run report missing the follow-up section"
pass "mkrepo -d reports without creating a repository"

# Create a new repository and push the canonical layout
rc="$(run_capture "$WORK_DIR/new.out" bash "$MKREPO" new-repo)"
[[ "$rc" -eq 0 ]] || fail "mkrepo exit code $rc"
[[ -d "$GH_FAKE_REMOTES/new-repo.git" ]] || fail "remote repository not created"

git clone -q "$GH_FAKE_REMOTES/new-repo.git" "$WORK_DIR/verify-new"
for item in \
  ".gitignore" "LICENSE" "CHANGELOG.md" "CONTRIBUTING.md" \
  "CODE_OF_CONDUCT.md" "MAINTAINERS.md" "SECURITY.md" \
  "config/contributors.md" "config/markdownlint.json" \
  "config/version_status.md" "briteRepo/bin/mkrepo" \
  "briteRepo/helpers/common.sh" ".github/workflows/validate-push.yml" \
  "docs/md/Guide.md" "docs/branding/Monogram.svg" "build/README.md" \
  "examples/README.md" "include/README.md" "obsolete/README.md" \
  "reports/README.md" "src/README.md" \
  "tests/golden/README.md" "tests/tmp/README.md"; do
  [[ -e "$WORK_DIR/verify-new/$item" ]] || \
    fail "missing $item in created repository"
done
pass "mkrepo creates and populates a new repository"

# The success report keeps the same shape as the dry-run report
FINAL_REPORT="$(sed -n 's/^Report: //p' "$WORK_DIR/new.out")"
[[ -f "$FINAL_REPORT" ]] || fail "success report not written"
[[ "$FINAL_REPORT" == *"/mkrepo-2"*.md ]] || \
  fail "unexpected success report name: $FINAL_REPORT"
grep -Fxq "# mkrepo Report" "$FINAL_REPORT" || \
  fail "success report missing its heading"
grep -Eq "^Commit: [0-9a-f]{40}$" "$FINAL_REPORT" || \
  fail "success report missing the commit hash"
rm -f "$DRY_REPORT" "$FINAL_REPORT"
pass "mkrepo writes a success report alongside the dry-run report"

# Branding, Guide.md, and the README link
[[ -L "$WORK_DIR/verify-new/README.md" ]] || \
  fail "README.md is not a symbolic link"
[[ "$(readlink "$WORK_DIR/verify-new/README.md")" == "docs/md/Guide.md" ]] || \
  fail "README.md does not link to docs/md/Guide.md"
grep -Fq "The best is yet to come." \
  "$WORK_DIR/verify-new/docs/branding/Logo_with_Tagline.svg" || \
  fail "tagline missing from the default branding"
grep -Fq "new-repo" \
  "$WORK_DIR/verify-new/docs/branding/Logo_with_BrandName.svg" || \
  fail "brand name missing from the default branding"
grep -Fq "fill=\"#000000\"" \
  "$WORK_DIR/verify-new/docs/branding/Monogram.svg" || \
  fail "monogram is not a black square"
[[ -e "$WORK_DIR/verify-new/docs/md/Contributor_Guide.md" ]] || \
  fail "Contributor documents were not copied"
[[ -e "$WORK_DIR/verify-new/docs/md/Contributor_Internal_Reference.md" ]] || \
  fail "internal Contributor documents were not copied"
pass "mkrepo adds branding, Guide.md, and the Contributor documents"

[[ -d "$WORK_DIR/verify-new/.github/workflows" ]] || \
  fail "mkrepo did not add .github/workflows"
[[ -n "$(find "$WORK_DIR/verify-new/.github/workflows" -name '*.yml' \
  -print -quit)" ]] || fail "mkrepo added no workflow files"
[[ -e "$WORK_DIR/verify-new/.github/CODEOWNERS" ]] || \
  fail "mkrepo did not add .github/CODEOWNERS"
pass "mkrepo adds the GitHub workflows and CODEOWNERS"

grep -Fq "setup_rulesets" "$WORK_DIR/new.out" || \
  fail "mkrepo did not suggest setup_rulesets in the next steps"
pass "mkrepo points to setup_rulesets when rulesets are not applied"

[[ ! -e "$WORK_DIR/verify-new/briteRepo/tests/test_mkrepo.sh" ]] || \
  fail "mkrepo copied the script tests without --tests"
[[ -e "$WORK_DIR/verify-new/briteRepo/tests/README.md" ]] || \
  fail "mkrepo omitted the briteRepo/tests directory guide"
pass "mkrepo omits the script tests by default"

grep -Fq '# `<repo>/docs/`' "$WORK_DIR/verify-new/docs/README.md" || \
  fail "docs/README.md missing canonical heading"
grep -Fq '**branding/**' "$WORK_DIR/verify-new/docs/README.md" || \
  fail "docs/README.md missing subdirectory entry"
grep -Fq 'None.' "$WORK_DIR/verify-new/src/README.md" || \
  fail "src/README.md missing empty Subdirectories entry"
pass "mkrepo generates canonical directory guides"

# -e forces the error path and writes an error report
rc="$(run_capture "$WORK_DIR/forced.out" bash "$MKREPO" -e new-repo)"
[[ "$rc" -eq 4 ]] || fail "mkrepo -e exit code $rc (expected 4)"
ERROR_REPORT="$(sed -n 's/^Report: //p' "$WORK_DIR/forced.out")"
[[ -f "$ERROR_REPORT" ]] || fail "error report not written"
[[ "$ERROR_REPORT" == *"/mkrepo-e-"*.md ]] || \
  fail "unexpected error report name: $ERROR_REPORT"
grep -Fxq "# mkrepo Error Report" "$ERROR_REPORT" || \
  fail "error report missing its heading"
grep -Fq "## Canonical Items" "$ERROR_REPORT" || \
  fail "error report missing the shared report body"
grep -Fq "Exit code: 4" "$ERROR_REPORT" || \
  fail "error report missing the exit code"
grep -Fq "Forced error requested with -e" "$ERROR_REPORT" || \
  fail "error report missing the error message"
grep -Fq "## Error Guidance" "$ERROR_REPORT" || \
  fail "error report missing the guidance section"
rm -f "$ERROR_REPORT"
pass "mkrepo -e writes an error report"

# Re-running against the now-canonical repository pushes nothing
rc="$(run_capture "$WORK_DIR/rerun.out" bash "$MKREPO" new-repo)"
[[ "$rc" -eq 0 ]] || fail "mkrepo re-run exit code $rc"
grep -Fq "already has the canonical layout" "$WORK_DIR/rerun.out" || \
  fail "mkrepo re-run did not detect an unchanged repository"
pass "mkrepo re-run is a no-op for a canonical repository"

# --tests adds the script tests
rc="$(run_capture "$WORK_DIR/tests.out" bash "$MKREPO" --tests new-repo)"
[[ "$rc" -eq 0 ]] || fail "mkrepo --tests exit code $rc"
git clone -q "$GH_FAKE_REMOTES/new-repo.git" "$WORK_DIR/verify-tests"
[[ -e "$WORK_DIR/verify-tests/briteRepo/tests/test_mkrepo.sh" ]] || \
  fail "mkrepo --tests did not add the script tests"
pass "mkrepo --tests adds the script tests"

# Update an existing repository that has content but no canonical layout
git init -q --bare -b main "$GH_FAKE_REMOTES/legacy-repo.git"
git clone -q "$GH_FAKE_REMOTES/legacy-repo.git" "$WORK_DIR/legacy-seed" \
  2>/dev/null
echo "# Legacy" > "$WORK_DIR/legacy-seed/README.md"
echo "# Legacy contributing" > "$WORK_DIR/legacy-seed/CONTRIBUTING.md"
git -C "$WORK_DIR/legacy-seed" add README.md CONTRIBUTING.md
git -C "$WORK_DIR/legacy-seed" commit -q -m "seed"
git -C "$WORK_DIR/legacy-seed" push -q origin main
rm -rf "$WORK_DIR/legacy-seed"

# The dry-run and success reports for the same starting state must match
rc="$(run_capture "$WORK_DIR/legacy-dry.out" bash "$MKREPO" -d legacy-repo)"
[[ "$rc" -eq 0 ]] || fail "mkrepo -d on an existing repository exit code $rc"
LEGACY_DRY="$(sed -n 's/^Report: //p' "$WORK_DIR/legacy-dry.out")"

rc="$(run_capture "$WORK_DIR/legacy.out" bash "$MKREPO" -v legacy-repo)"
[[ "$rc" -eq 0 ]] || fail "mkrepo on an existing repository exit code $rc"
LEGACY_FINAL="$(sed -n 's/^Report: //p' "$WORK_DIR/legacy.out")"

normalize_report() {
  sed -e '1s/.*/HEADING/' -e 's/^Commit: .*/COMMIT/' \
    -e 's/^Generated: .*/GENERATED/' "$1"
}
normalize_report "$LEGACY_DRY" > "$WORK_DIR/legacy-dry.norm"
normalize_report "$LEGACY_FINAL" > "$WORK_DIR/legacy-final.norm"
diff -u "$WORK_DIR/legacy-dry.norm" "$WORK_DIR/legacy-final.norm" \
  > "$WORK_DIR/report.diff" || \
  fail "dry-run and success reports differ beyond heading and commit"
grep -Fxq "Commit: To be determined" "$LEGACY_DRY" || \
  fail "dry-run report missing the placeholder commit"
rm -f "$LEGACY_DRY" "$LEGACY_FINAL"
pass "dry-run and success reports match except heading and commit"

git clone -q "$GH_FAKE_REMOTES/legacy-repo.git" "$WORK_DIR/verify-legacy"
grep -Fxq "# Legacy" "$WORK_DIR/verify-legacy/README.md" || \
  fail "mkrepo overwrote the existing README.md"
grep -Fq "README.md (not a symbolic link" "$WORK_DIR/legacy.out" || \
  fail "mkrepo did not report the non-symlink README.md"
[[ -e "$WORK_DIR/verify-legacy/CONTRIBUTING-canonical.md" ]] || \
  fail "mkrepo did not add the canonical copy for a divergent file"
grep -Fq "CONTRIBUTING.md (non-canonical content" "$WORK_DIR/legacy.out" || \
  fail "mkrepo did not report the divergent file"
[[ -e "$WORK_DIR/verify-legacy/briteRepo/bin/mkrepo" ]] || \
  fail "mkrepo did not add the scripts to the existing repository"
[[ -e "$WORK_DIR/verify-legacy/reports/README.md" ]] || \
  fail "mkrepo did not add the canonical layout to the existing repository"
pass "mkrepo keeps divergent files and adds -canonical copies"

# Stale scripts are removed by the fresh copy
git clone -q "$GH_FAKE_REMOTES/legacy-repo.git" "$WORK_DIR/stale-seed"
echo "stale" > "$WORK_DIR/stale-seed/briteRepo/bin/obsolete-script"
git -C "$WORK_DIR/stale-seed" add -A
git -C "$WORK_DIR/stale-seed" commit -q -m "add stale script"
git -C "$WORK_DIR/stale-seed" push -q origin main
rm -rf "$WORK_DIR/stale-seed"

rc="$(run_capture "$WORK_DIR/stale.out" bash "$MKREPO" legacy-repo)"
[[ "$rc" -eq 0 ]] || fail "mkrepo refresh exit code $rc"
git clone -q "$GH_FAKE_REMOTES/legacy-repo.git" "$WORK_DIR/verify-stale"
[[ ! -e "$WORK_DIR/verify-stale/briteRepo/bin/obsolete-script" ]] || \
  fail "mkrepo did not replace briteRepo/bin with a fresh copy"
pass "mkrepo replaces the briteRepo scripts with a fresh copy"

# A local clone of the target repository blocks the run
mkdir -p "$WORK_DIR/guard"
git clone -q "$GH_FAKE_REMOTES/legacy-repo.git" "$WORK_DIR/guard/legacy-repo"
git -C "$WORK_DIR/guard/legacy-repo" remote set-url origin \
  "https://github.com/testuser/legacy-repo.git"
rc="$(cd "$WORK_DIR/guard" && \
  run_capture "$WORK_DIR/guard.out" bash "$MKREPO" legacy-repo)"
[[ "$rc" -eq 2 ]] || fail "mkrepo with a local clone exit code $rc (expected 2)"
pass "mkrepo refuses to run with a local clone of the target present"

# Running from inside a clone of the target repository is refused
rc="$(cd "$WORK_DIR/guard/legacy-repo" && \
  run_capture "$WORK_DIR/inside.out" bash "$MKREPO" legacy-repo)"
[[ "$rc" -eq 2 ]] || \
  fail "mkrepo inside a clone exit code $rc (expected 2)"
pass "mkrepo refuses to run from inside a clone of the target"

# --rulesets reports a failure when rulesets cannot be applied
rc="$(run_capture "$WORK_DIR/rulesets.out" bash "$MKREPO" --rulesets \
  rulesets-repo)"
[[ "$rc" -eq 6 ]] || fail "mkrepo --rulesets exit code $rc (expected 6)"
grep -Fq "Canonical layout pushed" "$WORK_DIR/rulesets.out" || \
  fail "mkrepo --rulesets did not push the layout before applying rulesets"
pass "mkrepo --rulesets surfaces ruleset failures after the push"

echo "All mkrepo smoke tests passed."
