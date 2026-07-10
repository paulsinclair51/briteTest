#!/usr/bin/env bash

# test_lsbranch.sh - smoke tests for scripts/bin/lsbranch
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

extract_report_path() {
  local infile="$1"
  awk -F': ' '/^Report generated: /{print $2}' "$infile" | tail -n 1
}

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
REAL_GIT="$(command -v git)"

# 1) Help output
rc=$(run_capture "$TMPDIR/help.out" "$LSBRANCH" -h)
[[ "$rc" -eq 0 ]] || fail "lsbranch -h should exit 0"
grep -q '^Usage:' "$TMPDIR/help.out" || fail "lsbranch -h should print Usage"
pass "help output"

# 2) -a -r should include remote view output and not claim no branches for "*"
rc=$(run_capture "$TMPDIR/remote.out" "$LSBRANCH" -a -r)
[[ "$rc" -eq 0 ]] || fail "lsbranch -a -r should exit 0"
if grep -q 'No branches found matching pattern: \*' "$TMPDIR/remote.out"; then
  fail "lsbranch -a -r should not report no branches for '*'"
fi
grep -q '\[remote\]' "$TMPDIR/remote.out" || fail "lsbranch -a -r should include [remote] output"

remote_only_branch=$(git branch -r | sed 's|^..origin/||' | grep -v ' -> ' | while IFS= read -r b; do
  [[ -n "$b" ]] || continue
  if [[ -z "$(git branch --list "$b")" ]]; then
    echo "$b"
    break
  fi
done)
if [[ -n "$remote_only_branch" ]]; then
  grep -Fx "$remote_only_branch [remote]" "$TMPDIR/remote.out" >/dev/null || fail "remote-only branch should be present in -a -r output"
fi
pass "-a -r includes remote rows"

# 3) -a -l should not print remote tags
rc=$(run_capture "$TMPDIR/local.out" "$LSBRANCH" -a -l)
[[ "$rc" -eq 0 ]] || fail "lsbranch -a -l should exit 0"
if grep -q '\[remote\]' "$TMPDIR/local.out"; then
  fail "lsbranch -a -l should not include [remote] output"
fi
grep -q '\[local\]' "$TMPDIR/local.out" || fail "lsbranch -a -l should include [local] output"
pass "-a -l local-only output"

# 4) Current branch marker should be a trailing * in the report (not malformed markdown)
rc=$(run_capture "$TMPDIR/default.out" "$LSBRANCH")
[[ "$rc" -eq 0 ]] || fail "lsbranch should exit 0"
report_rel=$(extract_report_path "$TMPDIR/default.out")
[[ -n "$report_rel" ]] || fail "lsbranch output should include generated report path"
report_path="$SCRIPT_DIR/../../$report_rel"
[[ -f "$report_path" ]] || fail "generated report file should exist"

current_branch=$(git rev-parse --abbrev-ref HEAD)
grep -Eq "\\| ${current_branch}(\\*|<span[^>]*>\\*</span>) \\| local \\|" "$report_path" || fail "current branch should be marked with trailing * in local report row"
pass "current branch report marker"

# 5) BRANCH mode allows only -v/-b/-n; local/remote filters are invalid in BRANCH mode
rc=$(run_capture "$TMPDIR/branch_mode_invalid.out" "$LSBRANCH" "v1.0.0" -l)
[[ "$rc" -eq 1 ]] || fail "lsbranch 'v1.0.0' -l should exit 1"
grep -q 'only -v, -b, and -n are allowed' "$TMPDIR/branch_mode_invalid.out" || fail "BRANCH mode should reject -l/-r/-i/-x"
pass "BRANCH mode option restrictions"

# 6) Literal dots in PATTERN should be treated literally, not as regex wildcard
rc=$(run_capture "$TMPDIR/literal.out" "$LSBRANCH" "v1.0.0*" -l)
[[ "$rc" -eq 0 ]] || fail "lsbranch 'v1.0.0*' -l should exit 0"
grep -q '^v1.0.0 ' "$TMPDIR/literal.out" || fail "literal dots in pattern should match branch v1.0.0"
pass "literal glob pattern behavior"

# 7) Dirty worktree should not cause non-current local branches to fail inspection
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
[[ -n "$scratch_file" ]] || fail "need one clean tracked file for dirty-worktree smoke test"
cp "$scratch_file" "$backup_file"
trap 'rm -rf "$TMPDIR"; if [[ -f "$backup_file" && -n "${scratch_file:-}" ]]; then cp "$backup_file" "$scratch_file"; fi' EXIT
printf '\nlsbranch dirty smoke test\n' >> "$scratch_file"
rc=$(run_capture "$TMPDIR/dirty.out" "$LSBRANCH" -a -l)
[[ "$rc" -eq 0 ]] || fail "lsbranch -a -l should exit 0 with a dirty worktree"
if grep -q '\[check failed\]' "$TMPDIR/dirty.out"; then
  fail "lsbranch -a -l should not emit [check failed] for local branches when the worktree is dirty"
fi
grep -q '^v1.0.0 \[local\] \[not checked out\]' "$TMPDIR/dirty.out" || fail "non-current local branches should be marked [not checked out]"
cp "$backup_file" "$scratch_file"
pass "dirty worktree local branch inspection"

# 8) Verbose mode and the report should surface degraded fetch/PR lookups
FAKEBIN="$TMPDIR/fakebin"
mkdir -p "$FAKEBIN"
cat > "$FAKEBIN/git" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "fetch" && "\${2:-}" == "origin" ]]; then
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

rc=$(run_capture "$TMPDIR/degraded.out" env PATH="$FAKEBIN:$PATH" "$LSBRANCH" -a -r -v)
[[ "$rc" -eq 0 ]] || fail "lsbranch -a -r -v should tolerate degraded fetch/PR helpers"
grep -q "Warning: Failed to fetch 'origin'; remote status may be stale in this report." "$TMPDIR/degraded.out" || fail "verbose output should include fetch diagnostics"
grep -q "Warning: Failed to query pull requests for 'main'; PR column shown as N/A." "$TMPDIR/degraded.out" || fail "verbose output should include PR diagnostics"
degraded_report_rel=$(extract_report_path "$TMPDIR/degraded.out")
[[ -n "$degraded_report_rel" ]] || fail "degraded run should still generate a report"
degraded_report_path="$SCRIPT_DIR/../../$degraded_report_rel"
grep -q '^## Warnings$' "$degraded_report_path" || fail "report should include a warnings section when helpers degrade"
grep -q "Failed to fetch 'origin'; remote status may be stale in this report." "$degraded_report_path" || fail "report should include fetch warning"
grep -q "Failed to query pull requests for 'main'; PR column shown as N/A." "$degraded_report_path" || fail "report should include PR warning"
pass "degraded helper diagnostics"

# 9) -n should skip fetch attempts and suppress fetch-failure warnings
cat > "$FAKEBIN/git" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "fetch" && "\${2:-}" == "origin" ]]; then
  echo "fetch should not be called under -n" >&2
  exit 99
fi
exec "$REAL_GIT" "\$@"
EOF
chmod +x "$FAKEBIN/git"
rm -f "$FAKEBIN/gh"

rc=$(run_capture "$TMPDIR/nofetch.out" env PATH="$FAKEBIN:$PATH" "$LSBRANCH" -a -r -n -v)
[[ "$rc" -eq 0 ]] || fail "lsbranch -a -r -n -v should succeed without attempting fetch"
if grep -q "Failed to fetch 'origin'" "$TMPDIR/nofetch.out"; then
  fail "-n should suppress fetch-failure warnings"
fi
pass "no-fetch mode"

echo "All lsbranch smoke tests passed."
