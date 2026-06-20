#!/usr/bin/env bash
set -euo pipefail

# Validate that repository subdirectories have README.md files and that each
# README follows the normalized directory-guide format.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

# Directories that are intentionally exempt from requiring a README.md.
# .github is excluded because GitHub does not expose it as a normal browsable
# directory in the repository UI, but .github/workflows is still validated.
exempt_dirs=(
  "."
  "./.git"
  "./.github"
)

is_exempt_dir() {
  local dir="$1"
  local e
  for e in "${exempt_dirs[@]}"; do
    if [[ "$dir" == "$e" ]]; then
      return 0
    fi
  done
  return 1
}

relative_parent_prefix() {
  local rel_dir="$1"
  local depth
  local prefix=""

  if [[ -z "$rel_dir" ]]; then
    echo ""
    return 0
  fi

  depth="$(awk -F'/' '{print NF}' <<<"$rel_dir")"
  for ((i = 0; i < depth; i++)); do
    prefix+="../"
  done
  echo "$prefix"
}

failures=0

mapfile -t dirs < <(find . -type d -not -path './.git*' | sort)

for dir in "${dirs[@]}"; do
  if is_exempt_dir "$dir"; then
    continue
  fi

  readme="$dir/README.md"
  display_dir="${dir#./}"

  if [[ ! -f "$readme" ]]; then
    echo "ERROR: Missing README.md in directory '$display_dir'"
    failures=$((failures + 1))
    continue
  fi

  rel_dir="${dir#./}"
  expected_heading="# ${rel_dir}/"
  expected_prefix="$(relative_parent_prefix "$rel_dir")"
  expected_license_line="For license details, see \`${expected_prefix}LICENSE\`."
  expected_intro_line="See \`${expected_prefix}README.md\` for an introduction to LiteTest."

  heading_line="$(sed -n '1p' "$readme")"

  if [[ "$heading_line" != "$expected_heading" ]]; then
    echo "ERROR: '$readme' heading mismatch"
    echo "  Expected: $expected_heading"
    echo "  Found:    $heading_line"
    failures=$((failures + 1))
  fi

  if ! grep -qE '^Copyright \(c\) [0-9]{4} .+' "$readme"; then
    echo "ERROR: '$readme' missing/invalid copyright line"
    failures=$((failures + 1))
  fi

  if ! grep -qx 'SPDX-License-Identifier: MIT  *' "$readme"; then
    echo "ERROR: '$readme' missing SPDX line"
    failures=$((failures + 1))
  fi

  if ! grep -qxF "$expected_license_line" "$readme"; then
    echo "ERROR: '$readme' missing expected license reference"
    echo "  Expected: $expected_license_line"
    failures=$((failures + 1))
  fi

  if ! grep -qxF "$expected_intro_line" "$readme"; then
    echo "ERROR: '$readme' missing expected root README reference"
    echo "  Expected: $expected_intro_line"
    failures=$((failures + 1))
  fi

  files_ln="$(grep -n '^## Files$' "$readme" | cut -d: -f1 | head -n1 || true)"
  subdirs_ln="$(grep -n '^## Subdirectories$' "$readme" | cut -d: -f1 | head -n1 || true)"

  if [[ -z "$files_ln" ]]; then
    echo "ERROR: '$readme' missing '## Files' section"
    failures=$((failures + 1))
  fi

  if [[ -z "$subdirs_ln" ]]; then
    echo "ERROR: '$readme' missing '## Subdirectories' section"
    failures=$((failures + 1))
  fi

  if [[ -n "$files_ln" && -n "$subdirs_ln" && "$files_ln" -ge "$subdirs_ln" ]]; then
    echo "ERROR: '$readme' has section order mismatch ('## Files' must come before '## Subdirectories')"
    failures=$((failures + 1))
  fi

done

if [[ "$failures" -ne 0 ]]; then
  echo
  echo "README directory format check failed with $failures issue(s)."
  exit 1
fi

echo "README directory format check passed."
