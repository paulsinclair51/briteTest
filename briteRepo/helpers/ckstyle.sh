#!/usr/bin/env bash

# ckstyle.sh - Style validation helper for report.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see '<repo>/LICENSE'.

# High-Level Flow:
# 1. Parse validated check flags and file arguments from report.
# 2. Enforce prerequisites: local branch, targeted/contributor branch,
# contributor role.
# 3. Build the list of tracked files to check (all tracked, or scoped to FILE
# args).
# 4. Propagate repository history; initialize report path and issue state.
# 5. Run enabled check groups: documents (-m), includes (-i), guides (-r),
# sources/briteRepo (-s).
#    Document checks also populate DOC_VERSION_FILES/SEMVERS consumed by version
# checks.
# 6. Write a consolidated report and prune older style reports.
# 7. Exit 0 (clean), 2 (issues found), or a prerequisite/I-O error code.

bt_ckstyle() {
set -euo pipefail

CKSTYLE_HELPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=common.sh
source "$CKSTYLE_HELPER_DIR/common.sh"
# shellcheck source=git_helpers.sh
source "$CKSTYLE_HELPER_DIR/git_helpers.sh"

readonly CKSTYLE_EXIT_SUCCESS=0
readonly CKSTYLE_EXIT_INVALID_ARGUMENT=1
readonly CKSTYLE_EXIT_BRANCH_POLICY=2
readonly CKSTYLE_EXIT_VALIDATION_FAILED=3
readonly CKSTYLE_EXIT_NOT_AUTHORIZED=4
readonly CKSTYLE_EXIT_NOT_LOCAL_BRANCH=5
readonly CKSTYLE_EXIT_REPORT_IO_ERROR=201

usage_error() {
  local message="$1"
  echo "$message. See 'report -h' for details." >&2
  exit "$CKSTYLE_EXIT_INVALID_ARGUMENT"
}

report_io_error() {
  bt_error_exit "$CKSTYLE_EXIT_REPORT_IO_ERROR" "$1"
}

log_warning() {
  local message="$1"
  echo "WARN: $message" >&2
}

log_verbose() {
  local message="$1"
  if [[ "$VERBOSE" == true ]]; then
    echo "VERBOSE: $message" >&2
  fi
}

report_file_access_issue() {
  local file="$1"
  local action="$2"

  if [[ -n "${FILE_ACCESS_ISSUED[$file]+x}" ]]; then
    return 0
  fi

  FILE_ACCESS_ISSUED["$file"]=1
  add_issue "$file" "unable to ${action} file"
}

CHECK_INCLUDES=false
CHECK_DOCUMENTS=false
CHECK_GUIDES=false
CHECK_SOURCES=false
VERBOSE=false
declare -a ORIGINAL_ARGS=("$@")
declare -a TARGET_FILES_ARG=()
declare -a SELECTED_FILES_REL=()
declare -A SELECTED_FILE_SET=()
declare -A FILE_ACCESS_ISSUED=()
declare -a DOC_VERSION_FILES=()
declare -A DOC_VERSION_SEMVERS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i)
      CHECK_INCLUDES=true
      shift
      ;;
    -m)
      CHECK_DOCUMENTS=true
      shift
      ;;
    -r)
      CHECK_GUIDES=true
      shift
      ;;
    -v)
      VERBOSE=true
      shift
      ;;
    -s)
      CHECK_SOURCES=true
      shift
      ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do
        TARGET_FILES_ARG+=("$1")
        shift
      done
      ;;
    -*)
      usage_error "Unknown option: $1"
      ;;
    *)
      TARGET_FILES_ARG+=("$1")
      shift
      ;;
  esac
done

if ! $CHECK_INCLUDES && ! $CHECK_DOCUMENTS && ! $CHECK_GUIDES && \
  ! $CHECK_SOURCES; then
  CHECK_INCLUDES=true
  CHECK_DOCUMENTS=true
  CHECK_GUIDES=true
  CHECK_SOURCES=true
fi

repo_root="$(cd "$CKSTYLE_HELPER_DIR/../.." && pwd)"
cd "$repo_root"

CONTRIBUTORS_FILE="$repo_root/config/contributors.md"
CI_DOC_CHECK=false
if [[ "${BT_CI_DOC_CHECK:-false}" == true && \
  "${GITHUB_ACTIONS:-false}" == true && "$CHECK_DOCUMENTS" == true && \
  "$CHECK_GUIDES" == true && "$CHECK_INCLUDES" == false && \
  "$CHECK_SOURCES" == false ]]; then
  CI_DOC_CHECK=true
fi

CURRENT_BRANCH="$(bt_get_current_branch_or_empty)"
if [[ "$CI_DOC_CHECK" == false && -z "$CURRENT_BRANCH" ]]; then
  bt_emit_prerequisite_failure "$CKSTYLE_EXIT_NOT_LOCAL_BRANCH" \
    "Current branch must be a local branch." \
    "Use 'chbranch' to switch to a local targeted or contributor branch," \
    "then rerun 'report style'."
fi

if [[ "$CI_DOC_CHECK" == false ]] && \
  ! bt_is_targeted_branch "$CURRENT_BRANCH" && \
  ! bt_is_contributor_branch "$CURRENT_BRANCH"; then
  bt_emit_prerequisite_failure "$CKSTYLE_EXIT_BRANCH_POLICY" \
    "Current branch '$CURRENT_BRANCH' must be a targeted or contributor" \
    "branch (not main or a version branch)."
fi

if [[ "$CI_DOC_CHECK" == false && ! -f "$CONTRIBUTORS_FILE" ]]; then
  bt_emit_prerequisite_failure "$CKSTYLE_EXIT_NOT_AUTHORIZED" \
    "Configuration file not found: $CONTRIBUTORS_FILE"
fi
ACTOR_LOGIN=""
if [[ "$CI_DOC_CHECK" == false ]]; then
  ACTOR_LOGIN="$(bt_require_login || true)"
fi
if [[ "$CI_DOC_CHECK" == false && -z "$ACTOR_LOGIN" ]]; then
  bt_emit_prerequisite_failure "$CKSTYLE_EXIT_NOT_AUTHORIZED" \
    "Unable to determine GitHub login identity for permission check." \
    "Set GITHUB_ACTOR or run 'gh auth login', then rerun 'report style'."
fi
ACTOR_EMAIL="$(git config user.email 2>/dev/null || true)"
if [[ "$CI_DOC_CHECK" == false ]] && \
  ! bt_contributors_has_min_role_by_login_or_email \
  "$ACTOR_LOGIN" "$ACTOR_EMAIL" "contributor" "$CONTRIBUTORS_FILE"; then
  bt_emit_prerequisite_failure "$CKSTYLE_EXIT_NOT_AUTHORIZED" \
    "User '$ACTOR_LOGIN' is not authorized to run report style (requires" \
    "contributor role or higher)."
fi

# -----------------------------
# File selection helpers
# -----------------------------
normalize_rel_path() {
  local raw="$1"
  local rel

  if [[ "$raw" == /* ]]; then
    if [[ "$raw" != "$repo_root"/* ]]; then
      usage_error "File is outside repository: $raw"
    fi
    rel="${raw#"$repo_root"/}"
  else
    rel="$raw"
  fi

  rel="${rel#./}"

  if [[ -z "$rel" || "$rel" == .* || "$rel" == */.. || "$rel" == ../* ]]; then
    usage_error "Invalid file path: $raw"
  fi

  printf '%s\n' "$rel"
}

is_excluded_rel() {
  local rel="$1"
  [[ "$rel" == .git/* || "$rel" == obsolete/* ]]
}

build_selected_files() {
  local rel matched

  if [[ ${#TARGET_FILES_ARG[@]} -gt 0 ]]; then
    for rel in "${TARGET_FILES_ARG[@]}"; do
      rel="$(normalize_rel_path "$rel")"

      # Bare filename: apply to all tracked files with that basename.
      if [[ "$rel" != */* ]]; then
        matched=0
        while IFS= read -r path; do
          [[ -z "$path" ]] && continue
          if is_excluded_rel "$path"; then
            continue
          fi
          matched=1
          if [[ -z "${SELECTED_FILE_SET[$path]+x}" ]]; then
            SELECTED_FILE_SET["$path"]=1
            SELECTED_FILES_REL+=("$path")
          fi
        done < <(git ls-files | awk -F/ -v name="$rel" '$NF == name { print }')

        if [[ "$matched" -eq 0 ]]; then
          usage_error "No tracked files with filename: $rel"
        fi
        continue
      fi

      if is_excluded_rel "$rel"; then
        usage_error "Excluded file path is not allowed: $rel"
      fi
      if ! git ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
        usage_error "File is not tracked in current branch: $rel"
      fi
      if [[ -z "${SELECTED_FILE_SET[$rel]+x}" ]]; then
        SELECTED_FILE_SET["$rel"]=1
        SELECTED_FILES_REL+=("$rel")
      fi
    done
    return
  fi

  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    if is_excluded_rel "$rel"; then
      continue
    fi
    SELECTED_FILE_SET["$rel"]=1
    SELECTED_FILES_REL+=("$rel")
  done < <(git ls-files)
}

build_selected_files
log_verbose "selected files: ${#SELECTED_FILES_REL[@]}"

count_eligible_selected_files() {
  local rel dir
  local dir_for_exempt
  local is_exempt
  declare -A eligible=()

  for rel in "${SELECTED_FILES_REL[@]}"; do
    if [[ "$CHECK_DOCUMENTS" == true && "$rel" == docs/md/*.md && \
      "$(basename "$rel")" != "README.md" ]]; then
      eligible["$rel"]=1
    fi

    if [[ "$CHECK_INCLUDES" == true && "$rel" == include/*.h ]]; then
      eligible["$rel"]=1
    fi

    if [[ "$CHECK_GUIDES" == true && "$rel" =~ (^|/)README\.md$ ]]; then
      if [[ "$rel" == "README.md" ]]; then
        dir='.'
      else
        dir="${rel%/README.md}"
      fi

      if [[ "$dir" == '.' ]]; then
        dir_for_exempt='.'
      else
        dir_for_exempt="./$dir"
      fi

      is_exempt=false
      if [[ "$dir_for_exempt" == "." || "$dir_for_exempt" == "./.git" || \
        "$dir_for_exempt" == "./obsolete" ]]; then
        is_exempt=true
      fi

      if [[ "$is_exempt" == false ]]; then
        eligible["$rel"]=1
      fi
    fi

    if [[ "$CHECK_SOURCES" == true ]]; then
      if [[ "$rel" == src/*.c || "$rel" == *.sh || "$rel" == */*.sh || \
        ( "$rel" == briteRepo/bin/* && "$rel" != briteRepo/bin/*.* ) ]]; then
        eligible["$rel"]=1
      fi
    fi
  done

  printf '%s\n' "${#eligible[@]}"
}

ELIGIBLE_SELECTED_COUNT="$(count_eligible_selected_files)"

RUN_TS_FILE="$(date '+%Y%m%d-%H%M%S%z')"
RUN_TS_DISPLAY="$(date '+%Y-%m-%d %H:%M:%S%z' | sed -E 's/([+-][0-9]{2})([0-9]{2})$/\1:\2/')"
STYLE_REPORTS_DIR="$repo_root/reports"
REPORT_FILE="$STYLE_REPORTS_DIR/style-${RUN_TS_FILE}.md"

if ! mkdir -p "$STYLE_REPORTS_DIR"; then
  report_io_error "unable to create report directory: $STYLE_REPORTS_DIR"
fi

# -----------------------------
# Issue collection
# -----------------------------
declare -A FILE_ISSUES=()
declare -A FILE_SEEN=()
declare -a ISSUE_FILES=()
TOTAL_ISSUES=0

normalize_path() {
  local p="$1"
  if [[ "$p" == "$repo_root"/* ]]; then
    p="${p#"$repo_root"/}"
  fi
  p="${p#./}"
  printf '%s\n' "$p"
}

add_issue() {
  local file="$1"
  # ${3:-} lets callers split a long message across two string args.
  local msg="${2}${3:-}"
  local norm
  norm="$(normalize_path "$file")"

  if [[ -z "${FILE_SEEN[$norm]+x}" ]]; then
    FILE_SEEN["$norm"]=1
    ISSUE_FILES+=("$norm")
    FILE_ISSUES["$norm"]=""
  fi

  FILE_ISSUES["$norm"]+="- $msg"$'\n'
  TOTAL_ISSUES=$((TOTAL_ISSUES + 1))
}

# -----------------------------
# Document checks
# -----------------------------
license_summary='<summary><strong>License</strong></summary>'
preface_summary='<summary><strong>Preface</strong></summary>'
dvh_summary='<summary>&nbsp;&nbsp;&nbsp;&nbsp;Document Version '
dvh_summary+='History</summary>'
toc_summary='<summary><strong>Table of Contents</strong></summary>'

doc_front_matter() {
  local file="$1"
  awk '{ print } /^## Table of Contents$/ { exit }' "$file"
}

doc_summary_lines() {
  local file="$1"
  doc_front_matter "$file" | grep '^<summary>' || true
}

doc_check_standard_doc() {
  local file="$1"
  local first_nonblank
  local base

  base="$(basename "$file")"

  first_nonblank="$(awk 'NF { print; exit }' "$file")"
  if ! printf '%s\n' "$first_nonblank" | \
    grep -Eq '^!\[[^]]+\]\(/docs/branding/[^)]+\.png\)$'; then
    add_issue "$file" \
      "first non-blank line must be a banner image in /docs/branding/*.png" \
      "format"
  fi

  if [[ "$base" != "Guide.md" ]] && grep -q '^\[!\[' "$file"; then
    add_issue "$file" "badges are allowed only in Guide.md"
  fi
}

ensure_file_readable() {
  local file="$1"
  local action="$2"

  if [[ ! -r "$file" ]]; then
    report_file_access_issue "$file" "$action"
    return 1
  fi

  return 0
}

doc_check_details_structure() {
  local file="$1"
  local opens closes summaries

  opens=$(grep -c '^<details>$' "$file" || true)
  closes=$(grep -Ec '^[[:space:]]*</details>(<br>)?[[:space:]]*$' "$file" || \
    true)
  summaries=$(grep -c '^<summary>' "$file" || true)

  [[ "$opens" -eq "$closes" ]] ||
    add_issue "$file" "<details> and </details> counts differ " \
      "($opens != $closes)"
  [[ "$opens" -eq "$summaries" ]] ||
      add_issue "$file" "each <details> must have one <summary> " \
        "($opens != $summaries)"

  while IFS= read -r msg; do
    [[ -n "$msg" ]] && add_issue "$file" "$msg"
  done < <(
    awk '
      /^<details>$/ {
        if (getline nextline <= 0) {
          print "<details> at end of file without a summary"
          status=1
          exit
        }
        if (nextline !~ /^<summary>/) {
          print "<details> must be followed immediately by <summary>"
          status=1
          exit
        }
        next
      }
      END { exit status }
    ' "$file" || true
  )

  while IFS= read -r msg; do
    [[ -n "$msg" ]] && add_issue "$file" "$msg"
  done < <(
    awk '
      { lines[NR] = $0 }
      END {
        for (i = 1; i < NR; i++) {
          if (lines[i] ~ /^[[:space:]]*$/ && \
              lines[i + 1] ~ /^[[:space:]]*<\/details>(<br>)?[[:space:]]*$/) {
            print "blank line before </details> is not allowed"
          }
        }
      }
    ' "$file"
  )

  while IFS= read -r msg; do
    [[ -n "$msg" ]] && add_issue "$file" "$msg"
  done < <(
    awk '
      { lines[NR] = $0 }
      END {
        for (i = 2; i <= NR; i++) {
          if (lines[i] ~ /^<details>$/) {
            if (lines[i - 1] !~ /^[[:space:]]*$/) {
              print "<details> must be preceded by a blank line"
            }
          }
        }
      }
    ' "$file"
  )
}

doc_check_heading_numbering() {
  local file="$1"
  while IFS= read -r msg; do
    [[ -n "$msg" ]] && add_issue "$file" "$msg"
  done < <(
    awk '
      function is_numbered_heading(text) {
        return text ~ /^[0-9]+(\.[0-9]+)*(\.)?[[:space:]]+/
      }

      (/^```/ || /^~~~/) { in_code_block = !in_code_block; next }
      in_code_block { next }

      /^###[[:space:]]/ {
        heading=$0
        sub(/^###[[:space:]]+/, "", heading)
        if (heading ~ /^[0-9]/ && !is_numbered_heading(heading)) {
          print "malformed level-3 heading numbering: " $0
        }

        if (heading ~ /^[0-9]/) {
          if (current_section_heading == "") {
            print "numbered level-3 heading appears before a" \
              " level-2 heading: " \
              $0
          } else {
            if (current_section_heading !~ /^[0-9]/) {
              print "numbered level-3 heading requires numbered level-2 " \
                "section: " $0
            }
            section_has_numbered_h3=1
          }
        } else if (section_has_numbered_h3) {
          print "all level-3 headings in section must be numbered once one " \
            "is numbered: " $0
        }
      }

      /^##[[:space:]]/ {
        section_has_numbered_h3=0
        if ($0 == "## Preface" || $0 == "## Table of Contents") {
          current_section_heading=""
          next
        }
        heading=$0
        sub(/^##[[:space:]]+/, "", heading)
        current_section_heading=heading
        if (heading ~ /^[0-9]/ && !is_numbered_heading(heading)) {
          print "malformed level-2 heading numbering: " $0
        }
      }
    ' "$file"
  )
}

doc_check_toc_syntax() {
  local file="$1"
  while IFS= read -r msg; do
    [[ -n "$msg" ]] && add_issue "$file" "$msg"
  done < <(
    awk '
      /^## Table of Contents$/ { in_toc=1; next }
      in_toc && /^##[[:space:]]/ { exit }
      in_toc && /^<\/details>/ { exit }
      !in_toc { next }
      /^[[:space:]]*$/ { next }

      {
        line=$0
        gsub(/&nbsp;/, " ", line)

        if (line ~ /^[[:space:]]*[0-9]+,[[:space:]]*\[/) {
          print "Table of Contents entry uses comma instead of period: " $0
        }

        if (line ~ /^[[:space:]]*\[[^]]*[0-9]/) {
          if (line !~ /^[[:space:]]*\[[^]]*[0-9]+(\.[0-9]+)*\./) {
            print "numbered Table of Contents entry is malformed: " $0
          }
        }

        if (line ~ /^[[:space:]]*[0-9]/ &&
          line !~ /^[[:space:]]*[0-9]+(\.[0-9]+)*\.[[:space:]]+\[/) {
          print "Table of Contents numbering syntax is malformed: " $0
        }

        if (match(line,
          /^[[:space:]]*([0-9]+(\.[0-9]+)*)\.[[:space:]]+\[([^]]+)\]/,
          parts)) {
          label=parts[3]
          gsub(/\*\*/, "", label)
          if (label ~ /^[0-9]+(\.[0-9]+)*\./) {
            print "Table of Contents label repeats numbered prefix: " $0
          }
        }
      }
    ' "$file"
  )
}

doc_check_dvh_canonical() {
  local file="$1"
  while IFS= read -r msg; do
    [[ -n "$msg" ]] && add_issue "$file" "$msg"
  done < <(
    awk '
      BEGIN {
        dvh_row_re = "^\\|[[:space:]]*v[0-9]+\\.[0-9]+\\.[0-9]+[[:space:]]*\\|"
        dvh_row_re = dvh_row_re "[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}"
        dvh_row_re = dvh_row_re "[[:space:]]*\\|"
      }

      function trim(s) {
        sub(/^[[:space:]]+/, "", s)
        sub(/[[:space:]]+$/, "", s)
        return s
      }

      /^#### Version:[[:space:]]*/ {
        if (match($0,
          /^#### Version:[[:space:]]*(v[0-9]+\.[0-9]+\.[0-9]+)[[:space:]]*$/,
          parts)) {
          doc_version=parts[1]
          doc_version_seen=1
        }
      }

      function version_value(v, parts, n) {
        gsub(/^v/, "", v)
        n=split(v, parts, ".")
        if (n != 3) return -1
        return (parts[1] * 1000000) + (parts[2] * 1000) + parts[3]
      }

      /^### Document Version History$/ {
        found=1
        state=1
        next
      }

      found && state == 1 {
        if ($0 != "") {
          print "Document Version History requires a blank line after heading"
        }
        state=2
        next
      }

      found && state == 2 {
        if ($0 != "| Version | Date | Comment | Author/Editor |") {
          print "Document Version History table header must be canonical"
        }
        state=3
        next
      }

      found && state == 3 {
        if ($0 != "|----------|------|---------|---------------|") {
          print "Document Version History table divider must be canonical"
        }
        state=4
        next
      }

      found && state >= 4 {
        if ($0 ~ dvh_row_re) {
          split($0, cols, "|")
          ver=trim(cols[2])
          date=trim(cols[3])

          if (!first_row_seen) {
            first_row_seen=1
            first_row_version=ver
            if (!doc_version_seen) {
              print "missing #### Version: v<M>.<m>.<p> line"
            } else if (doc_version != first_row_version) {
                print "#### Version value (" doc_version ") must match " \
                      "first Document Version History entry (" \
                      first_row_version ")"
            }
          }

          cur_ver=version_value(ver)
          if (cur_ver < 0) {
            print "Document Version History version format is invalid: " ver
            next
          }
          if (seen_rows) {
            if (cur_ver < prev_ver) {
              print "Document Version History versions must be in" \
                    "increasing order"
            }
            if (date > prev_date) {
              print "Document Version History dates must be in descending order"
            }
          }
          prev_ver=cur_ver
          prev_date=date
          seen_rows=1
          next
        }
        if ($0 ~ /^\|/) {
          print "Document Version History row has invalid format: " $0
          next
        }
        exit
      }

      END {
        if (!found) {
          print "missing ### Document Version History heading"
        } else if (!seen_rows) {
          print "Document Version History table must include at least one entry"
        }
      }
    ' "$file"
  )
}

doc_check_summary_alignment() {
  local file="$1"
  while IFS= read -r msg; do
    [[ -n "$msg" ]] && add_issue "$file" "$msg"
  done < <(
    awk '
      function is_strong_summary(raw) {
        return raw ~ /^<summary><strong>.*<\/strong><\/summary>$/
      }
      function is_indented_summary(raw) {
        return raw ~ /^<summary>&nbsp;&nbsp;&nbsp;&nbsp;.*<\/summary>$/
      }

      function normalize_summary(text, result) {
        result=text
        sub(/^<summary>/, "", result)
        sub(/<\/summary>$/, "", result)
        gsub(/&nbsp;/, "", result)
        gsub(/<strong>/, "", result)
        gsub(/<\/strong>/, "", result)
        sub(/^([0-9]+(\.[0-9]+)+) /, "\\1. ", result)
        sub(/^[[:space:]]+/, "", result)
        sub(/[[:space:]]+$/, "", result)
        return result
      }

      /^<summary>/ {
        raw_summary=$0
        summary=normalize_summary($0)
        if (summary == "License" || summary == "Preface" || \
            summary == "Document Version History" || \
            summary == "Table of Contents") {
          pending=""
          pending_raw=""
          next
        }
        pending=summary
        pending_raw=raw_summary
        next
      }

      pending != "" && /^###[[:space:]]/ {
        heading=$0
        sub(/^###[[:space:]]+/, "", heading)
        if (heading != pending) {
          print "summary/heading mismatch: " pending " != " heading
        }
        if (!is_indented_summary(pending_raw) || pending_raw ~ /<strong>/) {
          print "level-3 summary style must be indented without <strong>: " \
            pending_raw
        }
        pending=""
        pending_raw=""
        next
      }

      pending != "" && /^##[[:space:]]/ {
        heading=$0
        sub(/^##[[:space:]]+/, "", heading)
        if (heading != pending) {
          print "summary/heading mismatch: " pending " != " heading
        }
        if (!is_strong_summary(pending_raw) || pending_raw ~ /&nbsp;/) {
          print "level-2 summary style must use <strong> with no &nbsp; " \
            "prefix: " pending_raw
        }
        pending=""
        pending_raw=""
        next
      }
    ' "$file"
  )
}

doc_check_ascii_only() {
  local file="$1"
  local non_ascii_report

  non_ascii_report="$(python3 - "$file" <<'PY'
import sys
from collections import OrderedDict

path = sys.argv[1]
base = path.split('/')[-1]
text = open(path, 'r', encoding='utf-8').read()

allow_guide = {"💻"}

seen = OrderedDict()
for line_no, line in enumerate(text.splitlines(), start=1):
    for ch in line:
        if ord(ch) <= 127:
            continue
        if base == "Guide.md" and ch in allow_guide:
            continue
        if ch not in seen:
            seen[ch] = line_no

if not seen:
    print("")
    sys.exit(0)

parts = []
for ch, ln in seen.items():
    parts.append(f"U+{ord(ch):04X} '{ch}' at line {ln}")

print("non-ASCII characters found: " + "; ".join(parts))
PY
)"

  if [[ -n "$non_ascii_report" ]]; then
    add_issue "$file" "$non_ascii_report"
  fi
}

run_documents_checks() {
  local docs_dir="$repo_root/docs/md"
  local branding_dir="$repo_root/docs/branding"
  local file rel summaries semver yr
  local base
  local md_files=()

  if [[ ! -d "$docs_dir" ]]; then
    add_issue "docs/md" "missing directory"
    return
  fi

  for rel in "${SELECTED_FILES_REL[@]}"; do
    if [[ "$rel" == docs/md/*.md && "$(basename "$rel")" != "README.md" ]]; then
      md_files+=("$repo_root/$rel")
    fi
  done

  mapfile -t md_files < <(printf '%s\n' "${md_files[@]}" | sed '/^$/d' | sort)

  for file in "${md_files[@]}"; do
    if ! ensure_file_readable "$file" "read"; then
      continue
    fi

    if ! doc_front_matter "$file" | grep -qx '## Table of Contents'; then
      add_issue "$file" "missing Table of Contents heading in front matter"
      continue
    fi

    if ! doc_front_matter "$file" | \
      grep -qx 'SPDX-License-Identifier: MIT'; then
      add_issue "$file" "missing SPDX identifier before Table of Contents"
    fi

    yr="$(doc_front_matter "$file" | \
      grep -oE '^#### Copyright \(c\) [0-9]{4} Paul Sinclair$' | \
      grep -oE '[0-9]{4}' || true)"
    if [[ -z "$yr" || "$yr" -lt 2026 || "$yr" -gt "$(date +%Y)" ]]; then
      add_issue "$file" \
        "missing canonical copyright line before Table of Contents"
    fi

    summaries="$(doc_summary_lines "$file")"
    if [[ "$summaries" != "$license_summary
$preface_summary
$dvh_summary
$toc_summary" ]]; then
      add_issue "$file" "summary tags before Table of Contents do not match "\
    "canonical order/style"
    fi

    doc_check_standard_doc "$file"

    doc_check_ascii_only "$file"
    doc_check_details_structure "$file"
    doc_check_heading_numbering "$file"
    doc_check_toc_syntax "$file"
    doc_check_summary_alignment "$file"
    doc_check_dvh_canonical "$file"

    # Cache the doc semantic version here so -m and version consistency can
    # share the same file selection without re-reading the document later.
    semver="$(doc_semver "$file")"
    DOC_VERSION_FILES+=("$file")
    DOC_VERSION_SEMVERS["$file"]="$semver"

    # Require document branding PNG artifacts, but do not require SVGs.
    base="$(basename "$file" .md)"
    if [[ ! -f "$branding_dir/${base}.png" ]]; then
      add_issue "docs/branding/${base}.png" \
        "missing PNG matching docs/md/${base}.md"
    fi

  done
}

# -----------------------------
# Include / source / script checks
# -----------------------------
check_copyright_and_license() {
  local file="$1"
  local label="$2"
  local header

  header="$(head -n 40 "$file" 2>/dev/null || true)"

  if ! printf '%s\n' "$header" | \
    grep -Eq 'Copyright \(c\) [0-9]{4} Paul Sinclair'; then
    add_issue "$file" "$label missing copyright line"
  fi

  if ! printf '%s\n' "$header" | \
    grep -Eq 'SPDX-License-Identifier:[[:space:]]*MIT'; then
    add_issue "$file" "$label missing SPDX-License-Identifier: MIT"
  fi

  if ! printf '%s\n' "$header" | grep -Eiq \
    '(For license details|See.*LICENSE|LICENSE in the repository root)'; then
    add_issue "$file" "$label missing license reference line"
  fi
}

run_includes_checks() {
  local file

  while IFS= read -r file; do
    check_copyright_and_license "$file" "include header"
  done < <(selected_files_abs_by_kind include)
}

run_sources_checks() {
  local file

  while IFS= read -r file; do
    check_copyright_and_license "$file" "source/script file"
  done < <(selected_files_abs_by_kind src)

  while IFS= read -r file; do
    check_copyright_and_license "$file" "source/script file"
  done < <(selected_files_abs_by_kind scripts)
}

# -----------------------------
# Directory guide checks
# -----------------------------
exempt_dirs=(
  "."
  "./.git"
  "./.github"
  "./obsolete"
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

list_immediate_subdirs() {
  local dir="$1"
  find "$dir" -mindepth 1 -maxdepth 1 -type d \
    -not -path './.git*' -not -name 'obsolete' -printf '%f\n' | sort
}

extract_subdirectory_entries() {
  local file="$1"
  awk '
    BEGIN { in_section = 0 }
    /^## Subdirectories$/ { in_section = 1; next }
    /^## / && in_section { exit }
    in_section { print }
  ' "$file"
}

extract_files_section_lines() {
  local file="$1"
  awk '
    BEGIN { in_section = 0 }
    /^## Files$/ { in_section = 1; next }
    /^## / && in_section { exit }
    in_section { print }
  ' "$file"
}

list_immediate_files() {
  local dir="$1"
  find "$dir" -mindepth 1 -maxdepth 1 -type f \
    -not -name '.*' -printf '%f\n' | sort
}

normalize_file_entry() {
  local entry="$1"
  entry="$(printf '%s' "$entry" | sed \
    's/^[[:space:]]*//; s/[[:space:]]*$//; s/\\\*/*/g; s/\\</</g; s/\\>/>/g')"
  entry="${entry#\`}"; entry="${entry%\`}"
  printf '%s\n' "$entry"
}

format_command_line() {
  bt_format_command_line "report style" "${ORIGINAL_ARGS[@]}"
}

entry_matches_file() {
  local entry="$1"
  local file="$2"
  local ext
  local entry_regex

  entry="$(normalize_file_entry "$entry")"

  # ".EXT files" collective pattern, e.g. ".md files" matches any *.md file.
  if [[ "$entry" =~ ^\.([A-Za-z0-9_+-]+)[[:space:]]+files$ ]]; then
    ext="${BASH_REMATCH[1]}"
    [[ "$file" == *."$ext" ]]
    return
  fi

  # "*.ext files" collective pattern, e.g. "*.o files" matches any *.o file.
  if [[ "$entry" =~ ^\*\.([A-Za-z0-9_+-]+)[[:space:]]+files$ ]]; then
    ext="${BASH_REMATCH[1]}"
    [[ "$file" == *."$ext" ]]
    return
  fi

  # <datetime> placeholder, e.g. "ckstyle-<datetime>.md".
  if [[ "$entry" == *"<datetime>"* ]]; then
    entry_regex="${entry//./\\.}"
    entry_regex="${entry_regex//\*/.*}"
    _dt='[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
    _dt="$_dt"'-[0-9][0-9][0-9][0-9][0-9][0-9]'
    entry_regex="${entry_regex//<datetime>/$_dt}"
    entry_regex="$(printf '%s' "$entry_regex" | sed -E 's/<[^>]+>/[^\/]+/g')"
    [[ "$file" =~ ^${entry_regex}$ ]]
    return
  fi

  # <PLACEHOLDER> generic substitution, e.g. "commit-<hash>.md" or
  # "commit-<...>.md".
  if printf '%s\n' "$entry" | grep -Eq '<[^>]+>'; then
    entry_regex="${entry//./\\.}"
    entry_regex="${entry_regex//\*/.*}"
    entry_regex="$(printf '%s' "$entry_regex" | \
      sed -E 's/<[^>]+>/[^\/]+/g')"
    [[ "$file" =~ ^${entry_regex}$ ]]
    return
  fi

  # Glob pattern, e.g. "ckstyle-*.md".
  if [[ "$entry" == *'*'* ]]; then
    # shellcheck disable=SC2053  # entry is an intentional glob pattern.
    [[ "$file" == $entry ]]
    return
  fi

  [[ "$file" == "$entry" ]]
}

is_filelike_entry() {
  local entry="$1"
  entry="$(normalize_file_entry "$entry")"

  if printf '%s\n' "$entry" | grep -Eq '^[A-Za-z0-9_.<>/-]+$'; then
    return 0
  fi
  [[ "$entry" == *"*"* ]] && return 0
  [[ "$entry" == *"<datetime>"* ]] && return 0
  [[ "$entry" =~ ^\.[A-Za-z0-9_+-]+[[:space:]]+files$ ]] && return 0
  [[ "$entry" =~ ^\*\.[A-Za-z0-9_+-]+[[:space:]]+files$ ]] && return 0
  [[ "$entry" =~ ^[^[:space:]]+\.[^[:space:]]+$ ]] && return 0
  return 1
}

guide_check_files_section() {
  local readme="$1"
  local dir="$2"
  local rel_dir allow_logical_order
  local files_section_entries=()
  local files_section_lines=()
  local actual_files=()
  local actual entry line section section_name
  local desc
  local has_h3 root_entry_count last_readme_section
  local last_section last_entry_in_last_section prev
  local pending_entry pending_needs_period pending_has_continuation
  local prev_nonblank
  declare -A prev_by_section=()
  declare -A readme_seen_by_section=()
  declare -A last_entry_by_section=()
  declare -A seen_entries=()
  local found_match

  rel_dir="${dir#./}"
  allow_logical_order=0
  if [[ "$rel_dir" == "docs/branding" ]]; then
    allow_logical_order=1
  fi

  section='__ROOT__'
  has_h3=0
  root_entry_count=0
  last_readme_section=''
  last_section='__ROOT__'
  pending_entry=''
  pending_needs_period=0
  pending_has_continuation=0
  prev_nonblank=''
  mapfile -t files_section_lines < <(extract_files_section_lines "$readme")
  mapfile -t actual_files < <(list_immediate_files "$dir")

  for line in "${files_section_lines[@]}"; do
    if [[ -z "${line//[[:space:]]/}" ]]; then
      if [[ -n "$pending_entry" && "$pending_needs_period" -eq 1 && \
        "$pending_has_continuation" -eq 0 ]]; then
        add_issue "$readme" \
          "Files entry '$pending_entry' description must end with a period"
      fi
      pending_entry=''
      pending_needs_period=0
      pending_has_continuation=0
      prev_nonblank=''
      continue
    fi

    if [[ "$line" =~ ^###[[:space:]]+(.+)$ ]]; then
      if [[ -n "$pending_entry" && "$pending_needs_period" -eq 1 && \
        "$pending_has_continuation" -eq 0 ]]; then
        add_issue "$readme" \
          "Files entry '$pending_entry' description must end with a period"
      fi
      pending_entry=''
      pending_needs_period=0
      pending_has_continuation=0

      has_h3=1
      section_name="${BASH_REMATCH[1]}"
      section="$section_name"
      last_section="$section"
      prev_nonblank="$line"
      continue
    fi

    if [[ "$line" =~ ^#{1,6}[[:space:]]+ && \
      ! "$line" =~ ^###[[:space:]]+ ]]; then
      if [[ -n "$pending_entry" && "$pending_needs_period" -eq 1 && \
        "$pending_has_continuation" -eq 0 ]]; then
        add_issue "$readme" \
          "Files entry '$pending_entry' description must end with a period"
      fi
      pending_entry=''
      pending_needs_period=0
      pending_has_continuation=0

      add_issue "$readme" \
        "Files section contains unsupported heading level (only ###" \
        "subsections are allowed)"
      prev_nonblank="$line"
      continue
    fi

    # Use sed extraction so wildcard-bearing entries like "validate-*.yml" and
    # "*.pdf" are captured correctly.
    if [[ "$line" =~ ^\*\*.+\*\*:[[:space:]]* ]]; then
      if [[ -n "$pending_entry" && "$pending_needs_period" -eq 1 && \
        "$pending_has_continuation" -eq 0 ]]; then
        add_issue "$readme" \
          "Files entry '$pending_entry' description must end with a period"
      fi

      entry="$(printf '%s\n' "$line" | sed -nE \
        's/^[[:space:]]*\*\*(.+)\*\*:[[:space:]]*.*/\1/p')"
      desc="$(printf '%s\n' "$line" | sed -nE \
        's/^[[:space:]]*\*\*.+\*\*:[[:space:]]*(.*)$/\1/p')"
      entry="$(normalize_file_entry "$entry")"
      desc="$(printf '%s' "$desc" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
      files_section_entries+=("$entry")

      pending_entry="$entry"
      pending_has_continuation=0
      if [[ -n "$desc" && "$desc" != *. && "$desc" != *: ]]; then
        pending_needs_period=1
      else
        pending_needs_period=0
      fi

      if [[ -n "${seen_entries[$entry]+x}" ]]; then
        add_issue "$readme" "duplicate Files entry '$entry'"
      else
        seen_entries["$entry"]=1
      fi

      if [[ "$section" == '__ROOT__' ]]; then
        root_entry_count=$((root_entry_count + 1))
      fi

      if is_filelike_entry "$entry"; then
        if [[ "$entry" == 'README.md' ]]; then
          readme_seen_by_section["$section"]=1
        else
          if [[ "${readme_seen_by_section[$section]-0}" -eq 1 ]]; then
            if [[ "$section" == '__ROOT__' ]]; then
              add_issue "$readme" \
                "lists entries after README.md in Files section"
            else
              add_issue "$readme" \
                "lists entries after README.md in Files subsection '$section'"
            fi
          fi

          prev="${prev_by_section[$section]-}"
          if [[ $allow_logical_order -eq 0 && -n "$prev" && \
            "$entry" < "$prev" ]]; then
            if [[ "$section" == '__ROOT__' ]]; then
              add_issue "$readme" \
                "non-alphabetical Files entries ('$prev' before '$entry')"
            else
              add_issue "$readme" \
                "non-alphabetical Files entries in subsection '$section'" \
                " ('$prev' before '$entry')"
            fi
          fi
          prev_by_section["$section"]="$entry"
        fi
      fi

      if [[ "$entry" == 'README.md' ]]; then
        last_readme_section="$section"
      fi

      last_entry_by_section["$section"]="$entry"
      prev_nonblank="$line"
      continue
    fi

    if [[ "$line" =~ ^(-[[:space:]]*)?\*\*.+\*\* ]]; then
      if [[ -n "$pending_entry" && "$pending_needs_period" -eq 1 && \
        "$pending_has_continuation" -eq 0 ]]; then
        add_issue "$readme" \
          "Files entry '$pending_entry' description must end with a period"
      fi
      pending_entry=''
      pending_needs_period=0
      pending_has_continuation=0

      add_issue "$readme" \
        "Files entry must use canonical syntax '**name**: description'"
      prev_nonblank="$line"
      continue
    fi

    if [[ -n "$pending_entry" ]]; then
      pending_has_continuation=1
    fi

    if [[ "$line" =~ ^[[:space:]]+ ]]; then
      if [[ -n "$pending_entry" && "$line" =~ ^[[:space:]]{2}[^[:space:]] && \
        ( "$prev_nonblank" =~ ^[[:space:]]*-[[:space:]]+ || \
          "$prev_nonblank" =~ ^[[:space:]]{2}[^[:space:]] ) ]]; then
        :
      else
        add_issue "$readme" \
          "continuation lines in Files section must not be indented"
      fi
    fi

    prev_nonblank="$line"
  done

  if [[ -n "$pending_entry" && "$pending_needs_period" -eq 1 && \
    "$pending_has_continuation" -eq 0 ]]; then
    add_issue "$readme" \
      "Files entry '$pending_entry' description must end with a period"
  fi

  if [[ ${#files_section_entries[@]} -eq 0 ]]; then
    add_issue "$readme" "no file entries in Files section"
  fi

  if [[ $has_h3 -eq 1 && $root_entry_count -gt 0 ]]; then
    add_issue "$readme" \
      "mixes top-level file entries with level-3 Files subsections"
  fi

  for actual in "${actual_files[@]}"; do
    found_match=0
    for entry in "${files_section_entries[@]}"; do
      if entry_matches_file "$entry" "$actual"; then
        found_match=1
        break
      fi
    done

    if [[ $found_match -eq 0 ]]; then
      add_issue "$readme" "does not list file '$actual' in Files section"
    fi
  done

  if [[ ${#files_section_entries[@]} -gt 0 ]]; then
    if [[ $has_h3 -eq 0 ]]; then
      if [[ "${files_section_entries[-1]}" != 'README.md' ]]; then
        add_issue "$readme" "must list README.md last in Files section"
      fi
    else
      if [[ -z "$last_readme_section" ]]; then
        add_issue "$readme" "must include README.md in final Files subsection"
      elif [[ "$last_readme_section" != "$last_section" ]]; then
        add_issue "$readme" "must place README.md in final Files subsection"
      else
        last_entry_in_last_section="${last_entry_by_section[$last_section]-}"
        if [[ "$last_entry_in_last_section" != 'README.md' ]]; then
          add_issue "$readme" \
            "must list README.md last within final Files subsection"
        fi
      fi
    fi
  fi
}

guide_check_subdirectories_section() {
  local readme="$1"
  local dir="$2"
  local subdirs_section
  local expected_subdirs=()
  local found_subdirs=()
  local subdir_lines=()
  local line entry desc prev
  local pending_entry pending_needs_period pending_has_continuation
  local prev_nonblank
  declare -A found_subdir_set=()
  declare -A seen_subdirs=()

  subdirs_section="$(extract_subdirectory_entries "$readme")"
  mapfile -t expected_subdirs < <(list_immediate_subdirs "$dir")
  mapfile -t subdir_lines < <(printf '%s\n' "$subdirs_section")

  if [[ ${#expected_subdirs[@]} -eq 0 ]]; then
    if ! printf '%s\n' "$subdirs_section" | \
      grep -qx 'None\.'; then
      add_issue "$readme" "missing 'None.' line in Subdirectories section"
    fi
    return
  fi

  if printf '%s\n' "$subdirs_section" | grep -qx 'None\.'; then
    add_issue "$readme" "has 'None.' but directory contains subdirectories"
  fi

  prev=""
  pending_entry=''
  pending_needs_period=0
  pending_has_continuation=0
  prev_nonblank=''
  for line in "${subdir_lines[@]}"; do
    if [[ -z "${line//[[:space:]]/}" ]]; then
      if [[ -n "$pending_entry" && "$pending_needs_period" -eq 1 && \
        "$pending_has_continuation" -eq 0 ]]; then
        add_issue "$readme" \
          "Subdirectories entry '$pending_entry' description must end with" \
          "a period"
      fi
      pending_entry=''
      pending_needs_period=0
      pending_has_continuation=0
      prev_nonblank=''
      continue
    fi

    if [[ "$line" =~ ^(-[[:space:]]*)?\*\*.+\*\*:[[:space:]]* ]]; then
      if [[ -n "$pending_entry" && "$pending_needs_period" -eq 1 && \
        "$pending_has_continuation" -eq 0 ]]; then
        add_issue "$readme" \
          "Subdirectories entry '$pending_entry' description must end with" \
          "a period"
      fi

      entry="$(printf '%s\n' "$line" | sed -nE \
        's/^[[:space:]]*(-[[:space:]]*)?\*\*(.+)\*\*:[[:space:]]*.*/\2/p')"
      desc="$(printf '%s\n' "$line" | sed -nE \
        's/^[[:space:]]*(-[[:space:]]*)?\*\*.+\*\*:[[:space:]]*(.*)$/\2/p')"
      entry="$(normalize_file_entry "$entry")"
      desc="$(printf '%s' "$desc" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"

      pending_entry="$entry"
      pending_has_continuation=0
      if [[ -n "$desc" && "$desc" != *. && "$desc" != *: ]]; then
        pending_needs_period=1
      else
        pending_needs_period=0
      fi

      if [[ "$entry" != */ ]]; then
        add_issue "$readme" \
          "Subdirectories entry '$entry' must use trailing '/'"
      fi

      entry="${entry%/}"
      found_subdirs+=("$entry")
      found_subdir_set["$entry"]=1

      if [[ -n "${seen_subdirs[$entry]+x}" ]]; then
        add_issue "$readme" "duplicate Subdirectories entry '$entry'"
      else
        seen_subdirs["$entry"]=1
      fi

      if [[ -n "$prev" && "$entry" < "$prev" ]]; then
        add_issue "$readme" \
          "non-alphabetical Subdirectories entries ('$prev' before '$entry')"
      fi
      prev="$entry"
      prev_nonblank="$line"
      continue
    fi

    if [[ "$line" =~ ^(-[[:space:]]*)?\*\*.+\*\* ]]; then
      if [[ -n "$pending_entry" && "$pending_needs_period" -eq 1 && \
        "$pending_has_continuation" -eq 0 ]]; then
        add_issue "$readme" \
          "Subdirectories entry '$pending_entry' description must end with" \
          "a period"
      fi
      pending_entry=''
      pending_needs_period=0
      pending_has_continuation=0

      add_issue "$readme" \
        "Subdirectories entry must use canonical syntax '**name/**:" \
        "description'"
      prev_nonblank="$line"
      continue
    fi

    if [[ "$line" == 'None.' ]]; then
      if [[ -n "$pending_entry" && "$pending_needs_period" -eq 1 && \
        "$pending_has_continuation" -eq 0 ]]; then
        add_issue "$readme" \
          "Subdirectories entry '$pending_entry' description must end with" \
          "a period"
      fi
      pending_entry=''
      pending_needs_period=0
      pending_has_continuation=0
      prev_nonblank="$line"
      continue
    fi

    if [[ -n "$pending_entry" ]]; then
      pending_has_continuation=1
    fi

    if [[ "$line" =~ ^[[:space:]]+ ]]; then
      if [[ -n "$pending_entry" && "$line" =~ ^[[:space:]]{2}[^[:space:]] && \
        ( "$prev_nonblank" =~ ^[[:space:]]*-[[:space:]]+ || \
          "$prev_nonblank" =~ ^[[:space:]]{2}[^[:space:]] ) ]]; then
        :
      else
        add_issue "$readme" \
          "continuation lines in Subdirectories section must not be indented"
      fi
    fi

    prev_nonblank="$line"
  done

  if [[ -n "$pending_entry" && "$pending_needs_period" -eq 1 && \
    "$pending_has_continuation" -eq 0 ]]; then
    add_issue "$readme" \
      "Subdirectories entry '$pending_entry' description must end with a period"
  fi

  for line in "${found_subdirs[@]}"; do
    [[ -z "$line" ]] && continue
    if ! printf '%s\n' "${expected_subdirs[@]}" | grep -qxF "$line"; then
      add_issue "$readme" "lists unexpected subdirectory '$line'"
    fi
  done

  for line in "${expected_subdirs[@]}"; do
    [[ -z "$line" ]] && continue
    if [[ -z "${found_subdir_set[$line]+x}" ]]; then
      add_issue "$readme" "is missing subdirectory '$line'"
    fi
  done
}

has_unexpected_h1_after_line1() {
  local readme="$1"

  awk '
    NR == 1 { next }

    /^[[:space:]]*```/ || /^[[:space:]]*~~~/ {
      in_fence = !in_fence
      next
    }

    in_fence { next }

    /^# / {
      found = 1
      exit
    }

    END {
      if (found) {
        exit 0
      }
      exit 1
    }
  ' "$readme"
}

run_directory_guides_checks() {
  local expected_license_line expected_intro_line
  local dirs=() dir readme display_dir rel_dir expected_heading
  local heading_line second_line description_line line4 line5 line6 line7 line8
  local copyright_ln spdx_ln license_ln intro_ln
  local files_ln files_heading_any_ln files_heading_any_text
  local subdirs_ln subdirs_heading_any_ln subdirs_heading_any_text

  # shellcheck disable=SC2016  # Literal backticks are part of the required
  # text.
  expected_license_line='For license details, see `<repo>/LICENSE`.'
  # shellcheck disable=SC2016  # Literal backticks are part of the required
  # text.
  expected_intro_line='See `<repo>/README.md` for an introduction to the repository.'

  mapfile -t dirs < <(
    printf '%s\n' "${SELECTED_FILES_REL[@]}" | \
      awk '/(^|\/)README\.md$/' | \
      awk '{
        if ($0 == "README.md") {
          print "."
        } else {
          sub(/\/README\.md$/, "", $0)
          print "./" $0
        }
      }' | \
      sort -u
  )

  for dir in "${dirs[@]}"; do
    if is_exempt_dir "$dir"; then
      continue
    fi

    readme="$dir/README.md"
    display_dir="${dir#./}"

    if [[ ! -f "$readme" ]]; then
      add_issue "$readme" "missing README.md in directory '$display_dir'"
      continue
    fi

    if ! ensure_file_readable "$readme" "read"; then
      continue
    fi

    rel_dir="${dir#./}"
    expected_heading="# \`<repo>/${rel_dir}/\`"
    heading_line="$(sed -n '1p' "$readme")"
    second_line="$(sed -n '2p' "$readme")"
    description_line="$(sed -n '3p' "$readme")"
    line4="$(sed -n '4p' "$readme")"
    line5="$(sed -n '5p' "$readme")"
    line6="$(sed -n '6p' "$readme")"
    line7="$(sed -n '7p' "$readme")"
    line8="$(sed -n '8p' "$readme")"

    [[ "$heading_line" == "$expected_heading" ]] || \
      add_issue "$readme" \
      "heading mismatch (expected '$expected_heading', found '$heading_line')"
    [[ -z "$second_line" ]] || add_issue "$readme" "second line must be blank"
    [[ "$description_line" == 'Directory containing '* ]] || \
      add_issue "$readme" "third line must start with 'Directory containing '"

    if has_unexpected_h1_after_line1 "$readme"; then
      add_issue "$readme" "contains unexpected H1 heading after line 1"
    fi

    [[ -z "$line4" ]] || add_issue "$readme" "line 4 must be blank"
    [[ "$line5" =~ ^Copyright\ \(c\)\ [0-9]{4}\ .+ ]] || \
      add_issue "$readme" "line 5 must be a valid copyright line"
    [[ "$line6" == 'SPDX-License-Identifier: MIT  ' ]] || \
      add_issue "$readme" "line 6 must be 'SPDX-License-Identifier: MIT  '"
    [[ "$line7" == "$expected_license_line" ]] || \
      add_issue "$readme" "line 7 must match expected license reference"
    [[ -z "$line8" ]] || add_issue "$readme" "line 8 must be blank"

    grep -qE '^Copyright \(c\) [0-9]{4} .+' "$readme" || \
      add_issue "$readme" "missing/invalid copyright line"
    grep -qx 'SPDX-License-Identifier: MIT  *' "$readme" || \
      add_issue "$readme" "missing SPDX line"
    grep -qxF "$expected_license_line" "$readme" || \
      add_issue "$readme" "missing expected license reference"
    if ! grep -qxF "$expected_intro_line" "$readme"; then
      add_issue "$readme" "missing expected root README reference"
    fi

    copyright_ln="$(grep -nE '^Copyright \(c\) [0-9]{4} .+' "$readme" \
      | cut -d: -f1 | head -n1 || true)"
    spdx_ln="$(grep -n '^SPDX-License-Identifier: MIT  *$' "$readme" \
      | cut -d: -f1 | head -n1 || true)"
    license_ln="$(grep -nFx "$expected_license_line" "$readme" \
      | cut -d: -f1 | head -n1 || true)"
    intro_ln="$(grep -nFx "$expected_intro_line" "$readme" \
      | cut -d: -f1 | head -n1 || true)"

    if [[ -n "$copyright_ln" && -n "$spdx_ln" && \
      -n "$license_ln" && -n "$intro_ln" ]]; then
      if ! [[ "$copyright_ln" -lt "$spdx_ln" && \
        "$spdx_ln" -lt "$license_ln" && \
        "$license_ln" -lt "$intro_ln" ]]; then
        add_issue "$readme" \
          "canonical header order mismatch (Copyright, SPDX, license line," \
          " root README line)"
      fi
    fi

    files_ln="$(grep -n '^## Files$' "$readme" \
      | cut -d: -f1 | head -n1 || true)"
    files_heading_any_ln="$(grep -nE '^#{1,6}[[:space:]]+Files$' "$readme" \
      | cut -d: -f1 | head -n1 || true)"
    files_heading_any_text="$(grep -E '^#{1,6}[[:space:]]+Files$' "$readme" \
      | head -n1 || true)"

    subdirs_ln="$(grep -n '^## Subdirectories$' "$readme" \
      | cut -d: -f1 | head -n1 || true)"
    subdirs_heading_any_ln="$(grep -nE '^#{1,6}[[:space:]]+Subdirectories$' \
      "$readme" | cut -d: -f1 | head -n1 || true)"
    subdirs_heading_any_text="$(grep -E '^#{1,6}[[:space:]]+Subdirectories$' \
      "$readme" | head -n1 || true)"

    if [[ -z "$files_ln" ]]; then
      if [[ -n "$files_heading_any_ln" ]]; then
        add_issue "$readme" \
          "incorrect heading level for Files section" \
          " (found '$files_heading_any_text')"
      else
        add_issue "$readme" "missing '## Files' section"
      fi
    fi

    if [[ -z "$subdirs_ln" ]]; then
      if [[ -n "$subdirs_heading_any_ln" ]]; then
        add_issue "$readme" \
          "incorrect heading level for Subdirectories section" \
          " (found '$subdirs_heading_any_text')"
      else
        add_issue "$readme" "missing '## Subdirectories' section"
      fi
    fi

    if [[ -n "$files_ln" && -n "$subdirs_ln" && \
      "$files_ln" -ge "$subdirs_ln" ]]; then
      add_issue "$readme" \
        "section order mismatch ('## Files' must come" \
        " before '## Subdirectories')"
    fi

    if [[ -n "$files_ln" ]]; then
      guide_check_files_section "$readme" "$dir"
    fi

    if [[ -n "$subdirs_ln" ]]; then
      guide_check_subdirectories_section "$readme" "$dir"
    fi
  done
}

# -----------------------------
# Version checks
# -----------------------------
extract_major() { printf '%s\n' "${1%%.*}"; }
extract_minor() {
  local minor_patch="${1#*.}"
  printf '%s\n' "${minor_patch%%.*}"
}
extract_patch() { printf '%s\n' "${1##*.}"; }
extract_major_minor() { printf '%s\n' "${1%.*}"; }

# Return selected files as absolute paths for a given regex over relative paths.
selected_files_abs() {
  local regex="$1"
  printf '%s\n' "${SELECTED_FILES_REL[@]}" | \
    grep -E "$regex" | \
    sed -E "s#^#$repo_root/#" | \
    sort || true
}

selected_files_abs_by_kind() {
  local kind="$1"

  case "$kind" in
    docs)
      selected_files_abs '^docs/md/.*\.md$'
      ;;
    include)
      selected_files_abs '^include/.*\.h$'
      ;;
    scripts)
      selected_files_abs '(^briteRepo/bin/[^/.]+$|(^|/).*[.]sh$)'
      ;;
    src)
      selected_files_abs '^src/.*\.c$'
      ;;
    *)
      return 1
      ;;
  esac
}

extract_semver_from_file() {
  local file="$1"
  grep -Eo "[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}" "$file" | head -n 1 || true
}

doc_semver() {
  local file="$1"
  head -n 220 "$file" | \
    grep -Eo '[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}' | head -n 1 || true
}

header_semver() {
  local file="$1"
  local semver

  semver="$(grep -Ei '^#[[:space:]]*define[[:space:]]+RA_[A-Za-z_]*VERSION'\
'[A-Za-z_]*[[:space:]]+"[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}"' "$file" \
    | grep -Eo '[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}' \
    | head -n 1 || true)"

  if [[ -z "$semver" ]]; then
    semver="$(extract_semver_from_file "$file")"
  fi

  printf '%s\n' "$semver"
}

source_semver() {
  local file="$1"
  local semver include_line

  semver="$(grep -Ei '^#[[:space:]]*define[[:space:]]+[A-Za-z_]*VERSION'\
'[A-Za-z_]*[[:space:]]+"[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}"' "$file" \
    | grep -Eo '[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}' \
    | head -n 1 || true)"

  if [[ -n "$semver" ]]; then
    printf '%s\n' "$semver"
    return
  fi

  include_line="$(grep -E \
    '^#[[:space:]]*include[[:space:]]+"'\
'(runnerapi|testapi)\.h"' \
    "$file" | head -n 1 || true)"
  if [[ "$include_line" == *'"runnerapi.h"'* ]]; then
    semver="$(header_semver "include/runnerapi.h")"
  elif [[ "$include_line" == *'"testapi.h"'* ]]; then
    semver="$(header_semver "include/testapi.h")"
  else
    semver="$(extract_semver_from_file "$file")"
  fi

  printf '%s\n' "$semver"
}

collect_selected_semvers() {
  local kind="$1"
  local mode="$2"
  local file semver

  while IFS= read -r file; do
    if ! ensure_file_readable "$file" "read"; then
      continue
    fi

    case "$mode" in
      header)
        semver="$(header_semver "$file")"
        ;;
      source)
        semver="$(source_semver "$file")"
        ;;
      *)
        return 1
        ;;
    esac
    [[ -n "$semver" ]] && printf '%s\t%s\n' "$file" "$semver"
  done < <(selected_files_abs_by_kind "$kind")
}

collect_selected_semver_pairs() {
  local kind="$1"
  local mode="$2"
  local base_ref="$3"
  local file rel semver
  local header_semver_re
  local source_semver_re

  header_semver_re='^#[[:space:]]*define[[:space:]]+RA_[A-Za-z_]*VERSION'
  header_semver_re+='[A-Za-z_]*[[:space:]]+"[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}"'
  source_semver_re='^#[[:space:]]*define[[:space:]]+[A-Za-z_]*VERSION'
  source_semver_re+='[A-Za-z_]*[[:space:]]+"[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}"'

  while IFS= read -r file; do
    if ! ensure_file_readable "$file" "read"; then
      continue
    fi
    rel="${file#"$repo_root"/}"

    case "$mode" in
      doc)
        semver="$(git show "$base_ref":"$rel" 2>/dev/null | head -n 220 | \
          grep -Eo '[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}' | head -n 1 || true)"
        ;;
      header)
        semver="$(git show "$base_ref":"$rel" 2>/dev/null | grep -Ei \
          "$header_semver_re" | \
          grep -Eo '[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}' | head -n 1 || true)"
        ;;
      source)
        semver="$(git show "$base_ref":"$rel" 2>/dev/null | grep -Ei \
          "$source_semver_re" | \
          grep -Eo '[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}' | head -n 1 || true)"
        ;;
      *)
        return 1
        ;;
    esac
    # Format: "path:semver" — file paths in this repo do not contain colons.
    [[ -n "$semver" ]] && printf '%s:%s\n' "$file" "$semver"
  done < <(selected_files_abs_by_kind "$kind")
}

current_branch_for_policy() {
  printf '%s\n' "$CURRENT_BRANCH"
}

resolve_main_baseline_ref() {
  if git show-ref --verify --quiet refs/heads/main; then
    printf '%s\n' "main"
    return
  fi

  if git show-ref --verify --quiet refs/remotes/origin/main; then
    printf '%s\n' "origin/main"
    return
  fi

  printf '%s\n' ""
}

display_repo_path() {
  local path="$1"

  if [[ "$path" == "$repo_root"/* ]]; then
    printf '<repo>/%s\n' "${path#"$repo_root"/}"
    return
  fi

  printf '%s\n' "$path"
}

run_versions_checks() {
  local expected_major expected_major_minor
  local file semver current_branch branch_type baseline_ref
  local -A versions=()
  local -a main_versions=()
  local entry main_semver current_semver
  local current_major_minor current_patch current_major current_minor

  expected_major=""
  expected_major_minor=""

  # Nested function: closes over expected_major, expected_major_minor, and
  # versions.
  record_and_check() {
    local file_path="$1"
    local semver_val="$2"
    local mm

    if [[ -z "$semver_val" ]]; then
      add_issue "$file_path" "semantic version not found"
      return
    fi

    versions["$file_path"]="$semver_val"
    mm="$(extract_major_minor "$semver_val")"

    if [[ -z "$expected_major_minor" ]]; then
      expected_major="$(extract_major "$semver_val")"
      expected_major_minor="$mm"
      return
    fi

    if [[ "$mm" != "$expected_major_minor" ]]; then
      add_issue "$file_path" \
        "major.minor release mismatch" \
        " (found $mm, expected $expected_major_minor)"
    fi
  }

  for file in "${DOC_VERSION_FILES[@]}"; do
    semver="${DOC_VERSION_SEMVERS[$file]:-}"
    record_and_check "$file" "$semver"
  done

  while IFS=$'\t' read -r file semver; do
    [[ -n "$file" && -n "$semver" ]] && versions["$file"]="$semver"
  done < <(collect_selected_semvers include header)

  while IFS=$'\t' read -r file semver; do
    [[ -n "$file" && -n "$semver" ]] && versions["$file"]="$semver"
  done < <(collect_selected_semvers src source)

  current_branch="$(current_branch_for_policy)"
  branch_type=""
  if [[ "$current_branch" == fix/* ]]; then
    branch_type="fix"
  elif [[ "$current_branch" == minor/* ]]; then
    branch_type="minor"
  elif [[ "$current_branch" == major/* ]]; then
    branch_type="major"
  fi

  if [[ -z "$branch_type" ]]; then
    return
  fi

  baseline_ref="$(resolve_main_baseline_ref)"
  if [[ -z "$baseline_ref" ]]; then
    log_warning "version consistency branch policy checks skipped: missing" \
                "main or origin/main reference"
    return
  fi

  while IFS=: read -r file semver; do
    [[ -n "$file" && -n "$semver" ]] && main_versions+=("$file:$semver")
  done < <(collect_selected_semver_pairs docs doc "$baseline_ref")

  while IFS=: read -r file semver; do
    [[ -n "$file" && -n "$semver" ]] && main_versions+=("$file:$semver")
  done < <(collect_selected_semver_pairs include header "$baseline_ref")

  while IFS=: read -r file semver; do
    [[ -n "$file" && -n "$semver" ]] && main_versions+=("$file:$semver")
  done < <(collect_selected_semver_pairs src source "$baseline_ref")

  for entry in "${main_versions[@]}"; do
    file="${entry%:*}"
    main_semver="${entry#*:}"
    current_semver="${versions[$file]:-}"

    [[ -z "$current_semver" ]] && continue

    case "$branch_type" in
      fix)
        current_major_minor="$(extract_major_minor "$current_semver")"
        if [[ "$current_major_minor" != \
          "$(extract_major_minor "$main_semver")" ]]; then
          add_issue "$file" \
            "fix branch policy violation: major.minor changed from main" \
            " ($main_semver -> $current_semver)"
        fi
        ;;
      minor)
        current_patch="$(extract_patch "$current_semver")"
        current_major_minor="$(extract_major_minor "$current_semver")"
        [[ "$current_patch" == "0" ]] || add_issue "$file" \
          "minor branch policy violation: patch must be 0" \
          " (found $current_semver)"
        [[ "$current_major_minor" == "$expected_major_minor" ]] || \
          add_issue "$file" \
            "minor branch policy violation: major.minor mismatch (found" \
            "$current_major_minor, expected $expected_major_minor)"
        ;;
      major)
        current_major="$(extract_major "$current_semver")"
        current_minor="$(extract_minor "$current_semver")"
        current_patch="$(extract_patch "$current_semver")"
        [[ "$current_major" == "$expected_major" ]] || add_issue "$file" \
          "major branch policy violation: major mismatch" \
          " (found $current_semver, expected major $expected_major)"
        [[ "$current_minor" == "0" ]] || add_issue "$file" \
          "major branch policy violation: minor must be 0" \
          " (found $current_semver)"
        [[ "$current_patch" == "0" ]] || add_issue "$file" \
          "major branch policy violation: patch must be 0" \
          " (found $current_semver)"
        ;;
    esac
  done
}

REPORT_BRANCH_NAME="$CURRENT_BRANCH"
REPORT_BRANCH_SCOPE="local"

# -----------------------------
# Execute selected checks
# -----------------------------
if [[ "$CHECK_DOCUMENTS" == true ]]; then
  log_verbose "running document checks"
  run_documents_checks
  log_verbose "running version consistency checks (enabled by -m)"
  run_versions_checks
fi

if [[ "$CHECK_INCLUDES" == true ]]; then
  log_verbose "running include checks"
  run_includes_checks
fi

if [[ "$CHECK_GUIDES" == true ]]; then
  log_verbose "running directory guide checks"
  run_directory_guides_checks
fi

if [[ "$CHECK_SOURCES" == true ]]; then
  log_verbose "running source/script checks"
  run_sources_checks
fi

# -----------------------------
# Write single consolidated report
# -----------------------------
{
  command_line="$(format_command_line)"

  echo "# Style Validation Report"
  echo
  echo "**Command:** \`${command_line}\`  "
  echo "**Timestamp:** $RUN_TS_DISPLAY"
  echo
  echo "## Configuration"
  echo
  echo "- **Selected Files:** $ELIGIBLE_SELECTED_COUNT"
  echo "- **Include Checks:** $CHECK_INCLUDES"
  echo "- **Documents Checks:** $CHECK_DOCUMENTS"
  echo "- **Directory Guide Checks:** $CHECK_GUIDES"
  echo "- **Source/Script Checks:** $CHECK_SOURCES"
  echo "- **Branch:** $REPORT_BRANCH_NAME ($REPORT_BRANCH_SCOPE)"
  echo "- **Version Consistency Included in -m:** $CHECK_DOCUMENTS"
  echo "- **Verbose Output:** $VERBOSE"
  echo "- **Excluded Paths:** .git, obsolete"
  echo
  echo "## Summary"
  echo
  echo "- **Files With Issues:** ${#ISSUE_FILES[@]}"
  echo "- **Total Issues:** $TOTAL_ISSUES"
  echo

  if [[ ${#ISSUE_FILES[@]} -eq 0 ]]; then
    echo "## Result"
    echo
    echo "No issues found."
  else
    echo "## Issues By File"
    echo
    while IFS= read -r f; do
      echo "### $f"
      echo
      printf '%s' "${FILE_ISSUES[$f]}"
      echo
    done < <(printf '%s\n' "${ISSUE_FILES[@]}" | sort)
  fi
} > "$REPORT_FILE" || report_io_error "unable to open report file: $REPORT_FILE"

# Normalize report EOF: exactly one trailing newline.
report_tmp="${REPORT_FILE}.tmp"
awk '
  { lines[NR] = $0 }
  END {
    last = NR
    while (last > 0 && lines[last] == "") {
      last--
    }
    for (i = 1; i <= last; i++) {
      print lines[i]
    }
  }
' "$REPORT_FILE" > "$report_tmp" || \
  report_io_error "unable to normalize report file: $REPORT_FILE"
mv "$report_tmp" "$REPORT_FILE" || \
  report_io_error "unable to finalize report file: $REPORT_FILE"

# Remove old reports of this type only after successful write.
old_report_rel=""
for old_report in "$STYLE_REPORTS_DIR"/style-*.md; do
  [[ "$old_report" == "$REPORT_FILE" ]] && continue
  [[ -e "$old_report" ]] || continue

  old_report_rel="${old_report#"$repo_root"/}"
  if git ls-files --error-unmatch -- "$old_report_rel" >/dev/null 2>&1; then
    continue
  fi

  if ! rm -f "$old_report"; then
    log_warning "unable to remove old report: $old_report"
  fi
done

if [[ $TOTAL_ISSUES -gt 0 ]]; then
  echo "Validation found $TOTAL_ISSUES issue(s) across" \
    "${#ISSUE_FILES[@]} file(s)."
  echo "See $(display_repo_path "$REPORT_FILE") for details."
  exit "$CKSTYLE_EXIT_VALIDATION_FAILED"
fi

echo "All selected files pass style checks."
echo "See $(display_repo_path "$REPORT_FILE") for details."
exit "$CKSTYLE_EXIT_SUCCESS"
}
