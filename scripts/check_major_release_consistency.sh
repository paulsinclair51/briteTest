#!/usr/bin/env bash
set -euo pipefail

# Validate that major release versions are consistent across:
# - docs/*.md (excluding docs/README.md)
# - include/*.h
# - src/*.c

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

extract_semver() {
  local file="$1"
  local semver

  semver="$(grep -Eo '[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}' "$file" | head -n 1 || true)"
  printf '%s\n' "$semver"
}

extract_major() {
  local semver="$1"
  printf '%s\n' "${semver%%.*}"
}

doc_major() {
  local file="$1"
  local semver

  # The document version table appears near the top of each docs file.
  semver="$(head -n 220 "$file" | grep -Eo '[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}' | head -n 1 || true)"
  printf '%s\n' "$semver"
}

header_major() {
  local file="$1"
  local semver

  semver="$(grep -Ei '^#[[:space:]]*define[[:space:]]+LT_[A-Za-z_]*VERSION[A-Za-z_]*[[:space:]]+"[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}"' "$file" \
    | grep -Eo '[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}' \
    | head -n 1 || true)"

  if [[ -z "$semver" ]]; then
    semver="$(extract_semver "$file")"
  fi

  printf '%s\n' "$semver"
}

source_major() {
  local file="$1"
  local semver
  local include_line

  semver="$(grep -Ei '^#[[:space:]]*define[[:space:]]+[A-Za-z_]*VERSION[A-Za-z_]*[[:space:]]+"[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}"' "$file" \
    | grep -Eo '[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}' \
    | head -n 1 || true)"

  if [[ -n "$semver" ]]; then
    printf '%s\n' "$semver"
    return 0
  fi

  include_line="$(grep -E '^#[[:space:]]*include[[:space:]]+"litetest_(runner|test)\.h"' "$file" | head -n 1 || true)"

  if [[ "$include_line" == *'"litetest_runner.h"'* ]]; then
    semver="$(header_major "include/litetest_runner.h")"
  elif [[ "$include_line" == *'"litetest_test.h"'* ]]; then
    semver="$(header_major "include/litetest_test.h")"
  else
    semver="$(extract_semver "$file")"
  fi

  printf '%s\n' "$semver"
}

failures=0
expected_major=""

record_and_check() {
  local file="$1"
  local semver="$2"
  local major

  if [[ -z "$semver" ]]; then
    echo "ERROR: Could not find semantic version in '$file'"
    failures=$((failures + 1))
    return
  fi

  major="$(extract_major "$semver")"

  if [[ -z "$expected_major" ]]; then
    expected_major="$major"
    echo "Reference major release: $expected_major (from $file: $semver)"
    return
  fi

  if [[ "$major" != "$expected_major" ]]; then
    echo "ERROR: Major release mismatch in '$file'"
    echo "  Found:    $semver (major $major)"
    echo "  Expected: major $expected_major"
    failures=$((failures + 1))
  fi
}

while IFS= read -r file; do
  [[ "$(basename "$file")" == "README.md" ]] && continue
  semver="$(doc_major "$file")"
  record_and_check "$file" "$semver"
done < <(find docs -maxdepth 1 -type f -name '*.md' | sort)

while IFS= read -r file; do
  semver="$(header_major "$file")"
  record_and_check "$file" "$semver"
done < <(find include -maxdepth 1 -type f -name '*.h' | sort)

while IFS= read -r file; do
  semver="$(source_major "$file")"
  record_and_check "$file" "$semver"
done < <(find src -maxdepth 1 -type f -name '*.c' | sort)

if [[ "$failures" -ne 0 ]]; then
  echo
  echo "Major release consistency check failed with $failures issue(s)."
  exit 1
fi

echo "Major release consistency check passed."
