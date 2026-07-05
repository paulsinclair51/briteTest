#!/usr/bin/env bash

# replace_phrases.sh - Replace configured phrases across markdown files.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

usage() {
  cat <<'EOF'
Usage:
  bash scripts/helpers/replace_phrases.sh [config_file] [-d]
  bash scripts/helpers/replace_phrases.sh -h | --help

Configuration file format:
  old_phrase = new_phrase

Options:
  -d           Show what would be replaced without modifying files.
  -h, --help   Show this help and exit.

Outputs:
  - Writes help text, status messages, and results or summaries to stdout.
  - Writes errors and diagnostics to stderr.
  - May generate files, reports, or other artifacts in the documented output locations.

EOF
}

# High-Level Flow:
# - Loads phrase replacement rules from a config file.
# - Traverses markdown files and applies phrase replacements (or previews with
#   -d).
# - Reports per-file replacement details and aggregate summary totals.

set -euo pipefail


count_occurrences() {
  local file="$1"
  local old_text="$2"

  OLD_TEXT="$old_text" perl -0777 -ne 'my $count = () = $_ =~ /\Q$ENV{OLD_TEXT}\E/g; print $count;' "$file"
}

apply_replacement() {
  local file="$1"
  local old_text="$2"
  local new_text="$3"
  local tmp_file

  tmp_file="$(mktemp)"
  OLD_TEXT="$old_text" NEW_TEXT="$new_text" perl -0777 -e '
    use strict;
    use warnings;
    my ($old_text, $new_text) = @ENV{qw(OLD_TEXT NEW_TEXT)};
    local $/;
    my $content = <>;
    $content =~ s/\Q$old_text\E/$new_text/g;
    print $content;
  ' "$file" > "$tmp_file"
  mv "$tmp_file" "$file"
}

trim_leading_spaces() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  printf '%s' "$value"
}

trim_trailing_spaces() {
  local value="$1"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

config_file="config/phrase_replacements.txt"
dry_run=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -d)
      dry_run=1
      ;;
    -*)
      echo "Error: Unknown option: $1" >&2
      exit 1
      ;;
    *)
      if [[ "$config_file" != "config/phrase_replacements.txt" ]]; then
        echo "Error: Multiple config files provided." >&2
        exit 1
      fi
      config_file="$1"
      ;;
  esac
  shift
done

if [[ ! -f "$config_file" ]]; then
  echo "Error: Config file not found: $config_file" >&2
  exit 1
fi

declare -a old_phrases=()
declare -a new_phrases=()

line_num=0
while IFS= read -r line || [[ -n "$line" ]]; do
  line_num=$((line_num + 1))
  line="${line%$'\r'}"

  stripped="$(trim_leading_spaces "$line")"
  if [[ -z "$stripped" || "$stripped" == \#* ]]; then
    continue
  fi

  if [[ "$line" != *"="* ]]; then
    echo "Error: Line $line_num: Missing '=' separator. Expected format: old_phrase = new_phrase" >&2
    exit 1
  fi

  old_phrase="${line%%=*}"
  new_phrase="${line#*=}"
  old_phrase="$(trim_trailing_spaces "$old_phrase")"
  new_phrase="$(trim_leading_spaces "$new_phrase")"

  if [[ -z "$old_phrase" ]]; then
    echo "Error: Line $line_num: old_phrase cannot be empty" >&2
    exit 1
  fi

  old_phrases+=("$old_phrase")
  new_phrases+=("$new_phrase")
done < "$config_file"

if [[ ${#old_phrases[@]} -eq 0 ]]; then
  echo "No replacements found in $config_file"
  exit 0
fi

echo "Loaded ${#old_phrases[@]} replacement(s) from $config_file"
echo

if [[ "$dry_run" -eq 1 ]]; then
  echo "DRY RUN MODE - No files will be modified"
  echo
fi

mapfile -t md_files < <(find . -type f -name '*.md' ! -path './.git/*' ! -path './.github/*' | sort)

if [[ ${#md_files[@]} -eq 0 ]]; then
  echo "No .md files found"
  exit 0
fi

total_replacements=0
files_modified=0

for file in "${md_files[@]}"; do
  file_replacements=0
  declare -a changes=()

  for i in "${!old_phrases[@]}"; do
    old_phrase="${old_phrases[$i]}"
    new_phrase="${new_phrases[$i]}"

    count="$(count_occurrences "$file" "$old_phrase")"
    if [[ "$count" -gt 0 ]]; then
      file_replacements=$((file_replacements + count))
      changes+=("  - Replaced '$old_phrase' -> '$new_phrase' (${count} occurrence(s))")
      if [[ "$dry_run" -eq 0 ]]; then
        apply_replacement "$file" "$old_phrase" "$new_phrase"
      fi
    fi
  done

  if [[ "$file_replacements" -gt 0 ]]; then
    files_modified=$((files_modified + 1))
    total_replacements=$((total_replacements + file_replacements))
    echo "$file:"
    for change in "${changes[@]}"; do
      echo "$change"
    done
    echo
  fi
done

echo "============================================================"
if [[ "$dry_run" -eq 1 ]]; then
  echo "DRY RUN SUMMARY:"
else
  echo "SUMMARY:"
fi
echo "  Files processed: ${#md_files[@]}"
echo "  Files modified: ${files_modified}"
echo "  Total replacements: ${total_replacements}"

if [[ "$dry_run" -eq 1 ]]; then
  echo
  echo "Run without -d to apply these changes"
fi