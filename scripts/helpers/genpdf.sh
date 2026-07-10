#!/usr/bin/env bash

# genpdf - Convert Markdown files to PDF optionally removing 
#          or converting <details> and <summary> tags.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

usage() {
  cat <<'EOF'
Usage:
  genpdf [<doc_options>] <document>[.md] [<outdocument>[.pdf]]
  genpdf [<dir_options>] <indirectory> [<outdirectory>]
  genpdf [<dir_options>]
  genpdf [-b <backend>] -t
  genpdf -h | --help

The third form is the same as: genpdf [<dir_options>] ./

<doc_options>:
  [-b <backend>] [-c] [-n] [-q] [-v]

<dir_options>:
  [-b <backend>] [-c] [-g] [-k] [-n] [-q] [-r] [-v]
  [-i "<pattern>"]... [-x "<pattern>"]...

Option values:
  <backend>  Conversion backend: all, auto, pandoc, wkhtmltopdf, weasyprint.
             all is only for -t; auto is default for conversions.
  <pattern>  Bash glob pattern for relative paths:
             - * or ** matches any characters, including '/'
             - ? matches one character, including '/'
             - [abc] matches one character from a set/range
             - any other character matches itself
             Note: this differs from common path-segment glob expectations,
             where * and ? do not match '/'. Use the -g option to enable
             * and ? not matching '/'.

Options:
  -b  Force conversion backend instead of auto-detecting.
      Useful for diagnostics and testing.
  -c  Convert details/summary blocks to PDF-friendly Markdown instead of
      removing details/summary tag lines. Default is to remove them.
  -e <file>
      For debugging (single-document mode only): write transformed markdown
      used for conversion to <file>.
  -h, --help  Output this help to stdout and exit (other options
              and arguments are ignored).
  -g  Use segment-style glob matching for -i/-x patterns:
      * and ? do not match '/'; ** matches across '/'.
  -i  Include only files whose relative path matches "<pattern>".
  -k  Keep directory structure under outdirectory (useful with -r).
  -n  Show planned conversions without writing output files.
  -q  Quiet mode: suppress informational messages to stdout. Help and
      diagnostics are not affected. There is no output to stdout in quiet mode
      when successful.
  -r  When input is a directory, include .md files in all subdirectories
      (default: only .md files directly in that directory).
  -t  Tool check: report available conversion toolchains and exit.
  -v  Verbose mode: print backend diagnostics to stderr.
  -x  Exclude files whose relative path matches "<pattern>".

Converts Markdown to PDF after optionally removing or converting
<details>/<summary> content for PDF output.

Examples:
  genpdf docs/md/briteTest.md
  genpdf docs/md/Documentation_Guide
  genpdf docs/md/Documentation_Guide.md docs/My_Documentation_Guide
  genpdf docs/md
  genpdf docs build

Outputs:
  - Writes help text, status messages, and results or summaries to stdout.
  - Writes errors and diagnostics to stderr.
  - May generate files, reports, or other artifacts in the documented
    output locations.

EOF
}

# High-Level Flow:
# - Implements helper functions used by markdown-to-PDF generation workflows.
# - Handles markdown preprocessing, branding/header/footer integration, and
#   converter invocation.
# - Provides reusable conversion logic for scripts that generate documentation
#   PDFs.
#
# Dependencies: pandoc (with a PDF engine), or
#               python3 plus wkhtmltopdf or weasyprint.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


# ============================================================================
# CONFIGURATION AND CONSTANTS
# ============================================================================

# Pandoc conversion engines (priority order: LaTeX native -> HTML fallback)
declare -a PANDOC_ENGINES=(
  pdflatex lualatex xelatex tectonic wkhtmltopdf weasyprint prince
)

# Logo dimensions (pixels)
readonly LOGO_WIDTH=200
readonly LOGO_HEIGHT=200

# LaTeX styling options
readonly LATEX_LINK_COLOR="RGB}{30,92,160"
readonly LATEX_FONT_SIZE="12"
readonly LATEX_FONT_LEADING="14"

# Command-line options
convert_details=0
quiet=0
verbose=0
check_only=0
recursive=0
keep_structure=0
dry_run=0
backend=auto
segment_glob=0
declare -a include_patterns=()
declare -a exclude_patterns=()
emit_markdown_path=""

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

# Output informational message to stdout (respects quiet mode).
log_info() {
  if [[ $quiet -eq 0 ]]; then
    echo "$1"
  fi
}

# Output warning message to stderr.
log_warn() {
  echo "Warning: $1" >&2
}

# Output debug message to stderr (only in verbose mode).
log_debug() {
  if [[ $verbose -eq 1 ]]; then
    echo "Debug: $1" >&2
  fi
}

# Output error message to stderr.
log_error() {
  echo "Error: $1" >&2
}

# ============================================================================
# UTILITY FUNCTIONS - PATH AND FILE HANDLING
# ============================================================================

# Remove trailing slashes from a path (except for root).
trim_trailing_slashes() {
  local path=$1
  while [[ "$path" != "/" && "$path" == */ ]]; do
    path=${path%/}
  done
  printf '%s\n' "$path"
}

# Check if target file can be written.
# Either target exists and is writable, or parent directory is writable.
can_write_target() {
  local target_file=$1
  local target_dir

  if [[ -e "$target_file" ]]; then
    [[ -w "$target_file" ]]
    return
  fi

  target_dir=$(dirname "$target_file")
  [[ -d "$target_dir" && -w "$target_dir" ]]
}

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

# Validate that backend name is one of the supported options.
validate_backend() {
  case "$1" in
    auto|pandoc|wkhtmltopdf|weasyprint)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# ============================================================================
# PATTERN MATCHING FUNCTIONS (Bash)
# ============================================================================

# Check if text matches any of the given patterns.
# Supports standard globs and segment-style glob matching.
match_any_pattern() {
  local text=$1
  shift
  local pattern
  local regex

  for pattern in "$@"; do
    if [[ $segment_glob -eq 1 ]]; then
      regex=$(glob_to_regex_segment "$pattern")
      if [[ "$text" =~ $regex ]]; then
        return 0
      fi
    elif [[ "$text" == $pattern ]]; then
      return 0
    fi
  done

  return 1
}

# Convert a glob pattern to a POSIX ERE regex with segment-style matching.
# In segment style:
# - * and ? do NOT match '/'
# - ** matches across '/' segments
glob_to_regex_segment() {
  local pattern=$1
  local regex='^'
  local i=0
  local len=${#pattern}
  local ch
  local next
  local j
  local cls

  while (( i < len )); do
    ch=${pattern:i:1}

    if [[ "$ch" == "*" ]]; then
      next=''
      if (( i + 1 < len )); then
        next=${pattern:i+1:1}
      fi

      if [[ "$next" == "*" ]]; then
        regex+='.*'
        ((i+=2))
        continue
      fi

      regex+='[^/]*'
      ((i++))
      continue
    fi

    if [[ "$ch" == "?" ]]; then
      regex+='[^/]'
      ((i++))
      continue
    fi

    if [[ "$ch" == "[" ]]; then
      j=$((i + 1))
      while (( j < len )) && [[ ${pattern:j:1} != "]" ]]; do
        ((j++))
      done

      if (( j < len )); then
        cls=${pattern:i+1:j-i-1}
        if [[ "${cls:0:1}" == "!" ]]; then
          cls="^${cls:1}"
        fi
        regex+="[$cls]"
        i=$((j + 1))
        continue
      fi

      regex+='\\['
      ((i++))
      continue
    fi

    case "$ch" in
      .|^|$|+|\(|\)|\{|\}|\|)
        regex+="\\$ch"
        ;;
      *)
        regex+="$ch"
        ;;
    esac

    ((i++))
  done

  regex+='$'
  printf '%s\n' "$regex"
}

# ============================================================================
# BACKEND DISCOVERY FUNCTIONS
# ============================================================================

# Find the first available pandoc PDF engine from the priority list.
find_pandoc_engine() {
  local engine
  for engine in "${PANDOC_ENGINES[@]}"; do
    if command -v "$engine" >/dev/null 2>&1; then
      printf '%s\n' "$engine"
      return 0
    fi
  done
  return 1
}

# ============================================================================
# LOGO HANDLING FUNCTIONS
# ============================================================================

# Search for a logo file with given extension in docs/branding/.
# Searches relative to repo root (parent of SCRIPT_DIR) and current working
# directory.
_genpdf_find_logo() {
  local ext=$1 root f
  for root in "$(dirname "$SCRIPT_DIR")" "$PWD"; do
    f="$root/docs/branding/BriteTest_Logo${ext}"
    [[ -f "$f" ]] && echo "$f" && return 0
  done
  return 1
}

# Return path to logo PNG, auto-converting from SVG if needed.
# Tries multiple SVG->PNG conversion tools:
# rsvg-convert, inkscape, convert, and cairosvg.
_genpdf_logo_png() {
  local png svg
  png=$(_genpdf_find_logo ".png") && echo "$png" && return 0
  svg=$(_genpdf_find_logo ".svg") || return 1
  png="${svg%.svg}.png"
  
  if command -v rsvg-convert >/dev/null 2>&1; then
    rsvg-convert -w "$LOGO_WIDTH" -h "$LOGO_HEIGHT" "$svg" > "$png" \
      2>/dev/null || return 1
  elif command -v inkscape >/dev/null 2>&1; then
    inkscape --export-type=png --export-width="$LOGO_WIDTH" "$svg" \
      -o "$png" 2>/dev/null || return 1
  elif command -v convert >/dev/null 2>&1; then
    convert -background none "$svg" -resize "${LOGO_WIDTH}x${LOGO_HEIGHT}" \
      "$png" 2>/dev/null || return 1
  elif python3 -c "import cairosvg" 2>/dev/null; then
    python3 -c \
      "import cairosvg; cairosvg.svg2png(url='$svg', write_to='$png', "\
"output_width=$LOGO_WIDTH)" \
      2>/dev/null || return 1
  else
    return 1
  fi
  echo "$png"
}

# ============================================================================
# DOCUMENT TITLE EXTRACTION
# ============================================================================

# Extract document title from first non-badge line.
# Priority order: heading > image alt > filename.
# Used for PDF metadata and page headers.
_genpdf_title_from_first_line() {
  local markdown_file=$1
  local fallback_title

  fallback_title=$(basename "${markdown_file%.*}")

  awk -v fallback_title="$fallback_title" '
    function trim(text) {
      sub(/^[[:space:]]+/, "", text)
      sub(/[[:space:]]+$/, "", text)
      return text
    }

    function is_badge_line(line,    t) {
      t = trim(line)
      badge_re = "^\\[!\\[[^]]*\\]\\([^)]*\\)\\]\\([^)]*\\)"
      badge_re = badge_re "([[:space:]]+\\[!\\[[^]]*\\]\\([^)]*\\)"
      badge_re = badge_re "\\]\\([^)]*\\))*[[:space:]]*$"
      return (t ~ badge_re)
    }

    function image_alt(line,   alt) {
      if (match(line, /^![[][^]]*[]][[:space:]]*\(/)) {
        alt = line
        sub(/^![[]/, "", alt)
        sub(/[]][[:space:]]*\(.*/, "", alt)
        return trim(alt)
      }
      return ""
    }

    function image_path(line,   path, parts, n) {
      if (match(line, /^![[][^]]*[]][[:space:]]*\([^)]*\)/)) {
        path = line
        sub(/^![[][^]]*[]][[:space:]]*\(/, "", path)
        sub(/\)[[:space:]]*$/, "", path)
        path = trim(path)
        if (path ~ /^<.*>$/) {
          sub(/^</, "", path)
          sub(/>$/, "", path)
        }
        n = split(path, parts, /[[:space:]]+/)
        return trim(parts[1])
      }
      return ""
    }

    {
      line = trim($0)

      if (line == "") {
        next
      }

      if (is_badge_line(line)) {
        next
      }

      lower = tolower(line)
      if (lower ~ /^<[[:space:]]*details([[:space:]][^>]*)?>$/ ||
          lower ~ /^<[[:space:]]*\/[[:space:]]*details([[:space:]][^>]*)?>$/ ||
          lower ~ /^<[[:space:]]*summary([[:space:]][^>]*)?>$/ ||
          lower ~ /^<[[:space:]]*\/[[:space:]]*summary([[:space:]][^>]*)?>$/) {
        next
      }

      if (line ~ /^#{1,6}[[:space:]]+/) {
        sub(/^#{1,6}[[:space:]]+/, "", line)
        emitted = 1
        print trim(line)
        exit
      }

      if (line ~ /^![[][^]]*[]][[:space:]]*\(/) {
        alt = image_alt(line)
        if (alt != "") {
          emitted = 1
          print alt
          exit
        }

        path = image_path(line)
        if (path != "") {
          gsub(/^.*\//, "", path)
          sub(/\.[^.]*$/, "", path)
          gsub(/[_-]+/, " ", path)
          emitted = 1
          print trim(path)
          exit
        }
      }

      emitted = 1
      print fallback_title
      exit
    }

    END {
      if (emitted != 1) {
        print fallback_title
      }
    }
  ' "$markdown_file"
}

# ============================================================================
# AWK HELPER FUNCTIONS - DEFINED FOR SINGLE-PASS METADATA SCAN
# ============================================================================

# Note: These AWK inline functions are used in single-pass
# scan_markdown_metadata to extract only document/runner/test versions with
# early exit once found. Logo extraction (PNG ref) is handled on second pass,
# when we encounter the first line after badges.

# ============================================================================
# METADATA SCANNING - SINGLE PASS WITH EARLY EXIT
# ============================================================================

# Single-pass scan for version information.
# Exits early once all three versions are found.
# Returns TSV output: DOC<tab>version, RUNNER<tab>version, TEST<tab>version
# Does NOT extract PNG reference (deferred to second pass).
# Does NOT extract has_toc (never used).
scan_markdown_metadata() {
  local markdown_file=$1

  awk '
    function trim(text) {
      sub(/^[[:space:]]+/, "", text)
      sub(/[[:space:]]+$/, "", text)
      return text
    }

    function parse_history_row(line,    n, parts, doc, run, test) {
      n = split(line, parts, /\|/)
      if (n < 4) return ""
      doc = trim(parts[2])
      run = trim(parts[3])
      test = trim(parts[4])
      if (length(doc) == 0 || length(run) == 0 || length(test) == 0) return ""
      return doc "\t" run "\t" test
    }

    BEGIN {
      in_history = 0
      saw_table_header = 0
      saw_separator = 0
      doc_ver = ""
      runner_ver = ""
      test_ver = ""
    }

    # Try to extract versions from inline "Version: X.X.X" lines first
    match($0, /^[[:space:]]*Document Version:[[:space:]]*/) {
      if (length(doc_ver) == 0) {
        value = $0
        sub(/^[[:space:]]*Document Version:[[:space:]]*/, "", value)
        doc_ver = trim(value)
      }
    }

    match($0, /^[[:space:]]*Runner Version:[[:space:]]*/) {
      if (length(runner_ver) == 0) {
        value = $0
        sub(/^[[:space:]]*Runner Version:[[:space:]]*/, "", value)
        runner_ver = trim(value)
      }
    }

    match($0, /^[[:space:]]*Test Version:[[:space:]]*/) {
      if (length(test_ver) == 0) {
        value = $0
        sub(/^[[:space:]]*Test Version:[[:space:]]*/, "", value)
        test_ver = trim(value)
      }
    }

    # Look for version history table
    /^### [[:space:]]*Document Version History/ {
      in_history = 1
      saw_table_header = 0
      saw_separator = 0
      next
    }

    in_history && /^\|/ {
      if (saw_table_header == 0) {
        saw_table_header = 1
        next
      }

      if (saw_separator == 0 && $0 ~ /^\|[-[:space:]]+\|/) {
        saw_separator = 1
        next
      }

        if (saw_separator && (length(doc_ver) == 0 ||
          length(runner_ver) == 0 || length(test_ver) == 0)) {
        row_versions = parse_history_row($0)
        if (length(row_versions) > 0) {
          split(row_versions, rows, /\t/)
          if (length(doc_ver) == 0) doc_ver = rows[1]
          if (length(runner_ver) == 0) runner_ver = rows[2]
          if (length(test_ver) == 0) test_ver = rows[3]
        }
        in_history = 0
      }
    }

    # Early exit: if all versions found, output and stop
    END {
      print "DOC\t" doc_ver
      print "RUNNER\t" runner_ver
      print "TEST\t" test_ver
    }
  ' "$markdown_file"
}

# ============================================================================
# TEXT ESCAPING FOR LATEX
# ============================================================================

# Escape special LaTeX characters in a string for use in LaTeX documents.
latex_escape() {
  printf '%s' "$1" | \
    sed -e 's/\\/\\textbackslash{}/g' \
        -e 's/{/\\{/g' \
        -e 's/}/\\}/g' \
        -e 's/#/\\#/g' \
        -e 's/\$/\\$/g' \
        -e 's/%/\\%/g' \
        -e 's/&/\\&/g' \
        -e 's/_/\\_/g' \
        -e 's/\^/\\textasciicircum{}/g' \
        -e 's/~/\\textasciitilde{}/g'
}

# ============================================================================
# HTML RENDERING (for HTML-to-PDF backends)
# ============================================================================

# Render markdown to HTML for wkhtmltopdf/weasyprint backends.
# Handles logo embedding and falls back to plaintext if mistune unavailable.
render_html() {
  local markdown_file=$1
  local html_file=$2
  local html_title=${3:-}

  if ! command -v python3 >/dev/null 2>&1; then
    return 1
  fi

  python3 - "$markdown_file" "$html_file" "$html_title" <<'PY'
import base64
import html
import pathlib
import sys

markdown_path = pathlib.Path(sys.argv[1])
html_path = pathlib.Path(sys.argv[2])
html_title = sys.argv[3] if len(sys.argv) > 3 else ""
text = markdown_path.read_text(encoding='utf-8')

logo_html = ""

try:
    import mistune
except Exception:
    body = f"<pre>{html.escape(text)}</pre>"
else:
    body = mistune.html(text)

doc = f"""<!doctype html>
<html lang=\"en\">
<head>
  <meta charset=\"utf-8\">
  <title>{html.escape(html_title if html_title else markdown_path.stem)}</title>
  <style>
    body {{
      font-family: serif; margin: 1in; line-height: 1.5; position: relative;
    }}
    pre {{ white-space: pre-wrap; }}
    code {{ font-family: monospace; }}
  </style>
</head>
<body>
{logo_html}
{body}
</body>
</html>
"""

html_path.write_text(doc, encoding='utf-8')
PY
}

# ============================================================================
# PDF CONVERSION - BACKEND LOGIC
# ============================================================================

# Convert markdown file to PDF using available backends.
# Pandoc is preferred, with HTML fallback backends.
# Args: $1=markdown_file, $2=target_pdf, $3=source_dir
#       $4=doc_title (metadata)
#       $5=copyright_text (optional, centered in running footer)
convert_to_pdf() {
  local markdown_file=$1
  local target_file=$2
  local source_dir=${3:-.}
  local doc_title=${4:-}
  local copyright_text=${5:-}
  local pandoc_engine
  local html_file
  local header_file=""
  local header_title
  local copyright_footer
  local display_title
  local status
  local use_latex_header=0
  local -a common_args=()
  local -a latex_header_args=()
  local -a title_args=()

  rm -f "$target_file"

  display_title=$(basename "${target_file%.pdf}")
  display_title=${display_title//_/ }
  header_title=$(latex_escape "$display_title")
  common_args=(
    -f markdown-implicit_figures
    --resource-path "$source_dir:."
    -V geometry:margin=1in
  )

  if [[ "$backend" == "pandoc" || "$backend" == "auto" ]]; then
    if command -v pandoc >/dev/null 2>&1; then
      if pandoc_engine=$(find_pandoc_engine); then
        case "$pandoc_engine" in
          pdflatex|lualatex|xelatex|tectonic)
            use_latex_header=1
            common_args+=(-V classoption=twoside)
            ;;
          *)
            use_latex_header=0
            if [[ -n "$doc_title" ]]; then
              title_args=(--metadata "title=$doc_title")
            fi
            ;;
        esac
      fi
    fi
  fi

  if [[ $use_latex_header -eq 1 ]]; then
    header_file=$(mktemp --suffix=.tex)
    copyright_footer=$(latex_escape "${copyright_text}")
    cat > "$header_file" <<EOF
\usepackage{xcolor}
\\usepackage{hyperref}
\\usepackage{graphicx}
\definecolor{ltlinkblue}{$LATEX_LINK_COLOR}
\hypersetup{
  colorlinks=true,
  linkcolor=ltlinkblue,
  urlcolor=ltlinkblue,
  citecolor=ltlinkblue,
  pdfborder={0 0 0}
}
\makeatletter
\renewcommand\section{%
  \@startsection{section}{1}{\z@}{-3.5ex \@plus -1ex \@minus -.2ex}%
  {2.3ex \@plus .2ex}{\normalfont\fontsize{17}{21}\selectfont\bfseries}%
}
\renewcommand\subsection{%
  \@startsection{subsection}{2}{\z@}{-3.25ex\@plus -1ex \@minus -.2ex}%
  {1.5ex \@plus .2ex}{\normalfont\fontsize{15}{19}\selectfont\bfseries}%
}
\renewcommand\subsubsection{%
  \@startsection{subsubsection}{3}{\z@}{-3.0ex\@plus -1ex \@minus -.2ex}%
  {1.0ex \@plus .2ex}{\normalfont\fontsize{13}{16}\selectfont\bfseries}%
}
\makeatother
\\usepackage{fancyhdr}
\\newif\\ifltaftertoc
\\ltaftertocfalse
\\newcommand{\\ltrunninghead}{}
\\newcommand{\\ltsetrunninghead}[1]{\\gdef\\ltrunninghead{#1}}
\\AtBeginDocument{\\fontsize{$LATEX_FONT_SIZE}{$LATEX_FONT_LEADING}\\selectfont}
\AtBeginDocument{\pagenumbering{roman}}
\\AtBeginDocument{\\thispagestyle{empty}}
\\fancypagestyle{plain}{%
  \\fancyhf{}
  \\renewcommand{\\headrulewidth}{0pt}
  \\renewcommand{\\footrulewidth}{0pt}
}
\\pagestyle{fancy}
\\fancyhf{}
\\fancyhead[LE]{\\nouppercase{\\ifltaftertoc\\ltrunninghead\\fi}}
\\fancyhead[RO]{\\nouppercase{\\ifltaftertoc\\ltrunninghead\\fi}}
\\fancyhead[RE,LO]{$header_title}
\\fancyfoot[LE,RO]{\\thepage}
\\fancyfoot[C]{\\small $copyright_footer}
\\renewcommand{\\headrulewidth}{0.4pt}
\\renewcommand{\\footrulewidth}{0.4pt}
EOF
    latex_header_args=(--include-in-header "$header_file")
  fi

  if [[ "$backend" == "pandoc" || "$backend" == "auto" ]]; then
    if command -v pandoc >/dev/null 2>&1; then
      if [[ -n "${pandoc_engine:-}" ]]; then
        rm -f "$target_file"
        if pandoc "${common_args[@]}" --pdf-engine "$pandoc_engine" \
          "${latex_header_args[@]}" "${title_args[@]}" \
          "$markdown_file" -o "$target_file"; then
          rm -f "$header_file" 2>/dev/null || true
          log_debug "converted using pandoc with engine '$pandoc_engine'"
          return 0
        else
          status=$?
          log_warn "pandoc with engine '$pandoc_engine' failed with exit code "\
"$status for: $target_file"
          if [[ "$backend" == "pandoc" ]]; then
            rm -f "$header_file" 2>/dev/null || true
            return 1
          fi
        fi
      else
        rm -f "$target_file"
        if pandoc "${common_args[@]}" "${title_args[@]}" "$markdown_file" \
          -o "$target_file"; then
          rm -f "$header_file" 2>/dev/null || true
          log_debug "converted using pandoc default engine"
          return 0
        else
          status=$?
          log_warn "pandoc default conversion failed with exit code $status "\
"for: $target_file"
          if [[ "$backend" == "pandoc" ]]; then
            rm -f "$header_file" 2>/dev/null || true
            return 1
          fi
        fi
      fi

      log_warn "trying fallback converter"
    elif [[ "$backend" == "pandoc" ]]; then
      rm -f "$header_file" 2>/dev/null || true
      log_error "requested backend 'pandoc' is not available"
      return 1
    fi
  fi

  rm -f "$header_file" 2>/dev/null || true

  if [[ "$backend" != "auto" && "$backend" != "wkhtmltopdf" && \
    "$backend" != "weasyprint" ]]; then
    log_error "unsupported backend selection: $backend"
    return 1
  fi

  html_file=$(mktemp --suffix=.html)

  if ! render_html "$markdown_file" "$html_file" "$doc_title"; then
    rm -f "$html_file"
    log_error "no supported Markdown-to-PDF toolchain found. Install pandoc,"
    log_error "or install python3 with wkhtmltopdf or weasyprint."
    return 1
  fi

  if [[ "$backend" == "auto" || "$backend" == "wkhtmltopdf" ]] && \
    command -v wkhtmltopdf >/dev/null 2>&1; then
    rm -f "$target_file"
    if wkhtmltopdf "$html_file" "$target_file"; then
      rm -f "$html_file"
      log_debug "converted using wkhtmltopdf fallback"
      return 0
    else
      status=$?
      log_warn "wkhtmltopdf failed with exit code $status for: $target_file"
    fi
  fi

  if [[ "$backend" == "auto" || "$backend" == "weasyprint" ]] && \
    command -v weasyprint >/dev/null 2>&1; then
    rm -f "$target_file"
    if weasyprint "$html_file" "$target_file"; then
      rm -f "$html_file"
      log_debug "converted using weasyprint fallback"
      return 0
    else
      status=$?
      log_warn "weasyprint failed with exit code $status for: $target_file"
    fi
  fi

  rm -f "$html_file"
  if [[ "$backend" == "wkhtmltopdf" || "$backend" == "weasyprint" ]]; then
    log_error "requested backend '$backend' failed or is not available for: "\
  "$target_file"
    return 1
  fi
  log_error "all available conversion backends failed for: $target_file"
  return 1
}

# ============================================================================
# AWK MARKDOWN PROCESSING - DETAILS CONVERSION MODE
# ============================================================================

# AWK program to convert <details>/<summary> HTML tags to PDF-friendly Markdown.
# Also handles logo embedding, version display, and section formatting for
# LaTeX.
# Called when convert_details=1 to transform details blocks into subsections.
generate_awk_convert_details() {
  cat <<'AWKPROGRAM'
    function tex_escape(text) {
      gsub(/\\/, "\\textbackslash{}", text)
      gsub(/\{/, "\\{", text)
      gsub(/\}/, "\\}", text)
      gsub(/#/, "\\#", text)
      gsub(/\$/, "\\$", text)
      gsub(/%/, "\\%", text)
      gsub(/&/, "\\&", text)
      gsub(/_/, "\\_", text)
      return text
    }

    function png_path_from_line(line,    value, parts) {
      if (match(line, re_png_ref)) {
        value = substr(line, RSTART, RLENGTH)
        sub(/^!\[[^]]*\]\(/, "", value)
        sub(/\)$/, "", value)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
        if (value ~ /^<.*>$/) {
          sub(/^</, "", value)
          sub(/>$/, "", value)
        }
        split(value, parts, /[[:space:]]+/)
        return parts[1]
      }
      return ""
    }

    function badge_png_url(image_url, link_url,    base, query) {
      if (image_url ~ re_gh_badge) {
        if (match(image_url, re_gh_badge_cap, m)) {
          return "https://img.shields.io/github/actions/workflow/status/" \
            m[1] "/" m[2] "/" m[3] ".png?branch=main" "&label=CI"
        }
      }

      if (image_url ~ /^https:\/\/img\.shields\.io\//) {
        if (index(image_url, "?") > 0) {
          split(image_url, q, "?")
          base = q[1]
          query = q[2]
          if (base ~ /\.svg$/) {
            sub(/\.svg$/, ".png", base)
          } else if (base !~ /\.(png|jpg|jpeg|gif|webp)$/) {
            base = base ".png"
          }
          return base "?" query
        }

        base = image_url
        if (base ~ /\.svg$/) {
          sub(/\.svg$/, ".png", base)
        } else if (base !~ /\.(png|jpg|jpeg|gif|webp)$/) {
          base = base ".png"
        }
        return base
      }

      return image_url
    }

    function normalize_anchor(anchor) {
      sub(/^#/, "", anchor)
      sub(/^user-content-/, "", anchor)
      if (anchor ~ /^[0-9]+([.-][0-9]+)*-/) {
        sub(/^[0-9]+([.-][0-9]+)*-/, "", anchor)
      }
      return anchor
    }

    function normalize_title(text,    t) {
      t = tolower(text)
      gsub(/\*\*/, "", t)
      gsub(/[*`_]/, "", t)
      gsub(/<[^>]+>/, "", t)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", t)
      if (t ~ /^[0-9]+([.][0-9]+)*[.)]?[[:space:]]+/) {
        sub(/^[0-9]+([.][0-9]+)*[.)]?[[:space:]]+/, "", t)
      }
      gsub(/[[:space:]]+/, " ", t)
      return t
    }

    BEGIN {
      re_png_ref = "!\\[[^]]*\\]\\(([^)]+\\.[Pp][Nn][Gg]"
      re_png_ref = re_png_ref "([[:space:]][^)]+)?)\\)"
      re_gh_badge = "^https://github\\.com/[^/]+/[^/]+/actions/"
      re_gh_badge = re_gh_badge "workflows/[^/]+/badge\\.svg$"
      re_gh_badge_cap = "^https://github\\.com/([^/]+)/([^/]+)/actions/"
      re_gh_badge_cap = re_gh_badge_cap "workflows/([^/]+)/badge\\.svg$"
      re_badge_single = "^[[:space:]]*\\[!\\[([^]]*)\\]\\(([^)]*)\\)"
      re_badge_single = re_badge_single "\\]\\(([^)]*)\\)[[:space:]]*$"
      re_badge_multi = "^[[:space:]]*\\[!\\[[^]]*\\]\\([^)]*\\)\\]\\([^)]*\\)"
      re_badge_multi = re_badge_multi "([[:space:]]+\\[!\\[[^]]*\\]\\([^)]*\\)"
      re_badge_multi = re_badge_multi "\\]\\([^)]*\\))*[[:space:]]*$"
      re_details_open = "^[[:space:]]*<[[:space:]]*details"
      re_details_open = re_details_open "([[:space:]][^>]*)?>[[:space:]]*$"
      re_details_close = "^[[:space:]]*<[[:space:]]*/[[:space:]]*details"
      re_details_close = re_details_close "([[:space:]][^>]*)?>[[:space:]]*$"
      re_summary_close = "<[[:space:]]*/[[:space:]]*summary([[:space:]][^>]*)?>"
      re_png_line = "^[[:space:]]*!\\[[^]]*\\]\\([^)]*\\.[Pp][Nn][Gg]"
      re_png_line = re_png_line "([[:space:]][^)]+)?\\)[[:space:]]*$"
      re_h2 = "^##[[:space:]]+"
      re_toc_h2 = "^##[[:space:]]*table of contents[[:space:]]*$"
    }

    {
      line = $0
      lower = tolower(line)

      if (match(line, re_badge_single, badge_parts)) {
        if (title_done != 1) {
          badge_img = badge_png_url(badge_parts[2], badge_parts[3])
          print "[![" badge_parts[1] "](" badge_img ")](" badge_parts[3] ")"
        }
        next
      }
      if (match(line, re_badge_multi)) {
        next
      }

      if (skip_why == 1) {
        if (match(line, /^##?#?#?[[:space:]]/)) {
          skip_why = 0
        } else {
          next
        }
      }

      if (match(lower, /^[[:space:]]*####[[:space:]]*why click to view/)) {
        skip_why = 1
        next
      }

      if (match(lower, re_details_open) || match(lower, re_details_close)) {
        next
      }

      if (in_summary == 1) {
        text = line
        if (match(lower, re_summary_close)) {
          gsub(/<[^>]+>/, "", text)
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", text)
          if (length(text) > 0) {
            if (length(summary_text) > 0) {
              summary_text = summary_text " " text
            } else {
              summary_text = text
            }
          }
          if (length(summary_text) > 0) {
            print "### " summary_text
          }
          summary_text = ""
          in_summary = 0
          next
        }
        gsub(/<[^>]+>/, "", text)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", text)
        if (length(text) > 0) {
          if (length(summary_text) > 0) {
            summary_text = summary_text " " text
          } else {
            summary_text = text
          }
        }
        next
      }

      if (match(lower, /<[[:space:]]*summary([[:space:]][^>]*)?>/)) {
        text = line
        gsub(/<[^>]+>/, "", text)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", text)
        if (match(lower, re_summary_close)) {
          if (length(text) > 0) {
            print "### " text
          }
          next
        }
        in_summary = 1
        summary_text = text
        next
      }

      if (match(line, re_png_line)) {
        if (title_done != 1) {
          png_path = logo_png
          if (length(png_path) == 0) {
            png_path = png_path_from_line(line)
          }
          title_done = 1
          print "```{=latex}"
          print "\\vspace*{\\baselineskip}"
          print "\\noindent\\includegraphics[width=\\textwidth]{" \
            "\\detokenize{" png_path "}}"
          print "```"
          if (have_versions == 1) {
            print "```{=latex}"
            print "\\vspace{\\baselineskip}"
            print "\\vspace{\\baselineskip}"
            print "\\noindent Document Version: " \
              tex_escape(document_version) "\\\\"
            print "\\noindent Runner Version: " \
              tex_escape(runner_version) "\\\\"
            print "\\noindent Test Version: " tex_escape(test_version) "\\\\"
            print "```"
          }
          next
        }
        print line
        next
      }

      if (title_done == 1 && match(line, /^Document Version:[[:space:]]/)) {
        next
      }
      if (title_done == 1 && match(line, /^Runner Version:[[:space:]]/)) {
        next
      }
      if (title_done == 1 && match(line, /^Test Version:[[:space:]]/)) {
        next
      }

      if (title_done == 1 && title_footer_pushed != 1 &&
          (match(line, /^\*\*Copyright/) || match(line, /^Copyright/) ||
           match(lower, /^#[[:space:]]*copyright/) ||
           match(lower, /^##[[:space:]]*copyright/) ||
           match(lower, /^###[[:space:]]*copyright/) ||
           match(lower, /^####[[:space:]]*copyright/) ||
           match(lower, /^#####[[:space:]]*copyright/) ||
           match(lower, /^######[[:space:]]*copyright/) ||
           match(lower, /^#[[:space:]]*license/) ||
           match(lower, /^##[[:space:]]*license/) ||
           match(lower, /^###[[:space:]]*license/) ||
           match(lower, /^####[[:space:]]*license/) ||
           match(lower, /^#####[[:space:]]*license/) ||
           match(lower, /^######[[:space:]]*license/))) {
        print "```{=latex}"
        print "\\vfill"
        print "```"
        title_footer_pushed = 1
      }

      if (match(line, re_h2)) {
        section_title = line
        sub(/^##[[:space:]]+/, "", section_title)
        if (tolower(section_title) != "license") {
          section_key = normalize_title(section_title)
          section_anchor = ""
          if (section_key in toc_title_to_anchor) {
            section_anchor = toc_title_to_anchor[section_key]
          }
          print "```{=latex}"
          print "\\clearpage"
          if (main_numbering_started != 1 && section_title ~ /^1\./) {
            print "\\pagenumbering{arabic}"
            print "\\setcounter{page}{1}"
            main_numbering_started = 1
          }
          if (length(section_anchor) > 0) {
            print "\\phantomsection"
            print "\\label{" section_anchor "}"
          }
          print "\\ltsetrunninghead{" tex_escape(section_title) "}"
          print "\\global\\ltaftertoctrue"
          print "```"
        }
      }

      if (match(lower, re_toc_h2)) {
        in_toc_md = 1
        print line
        print ""
        next
      }

      if (in_toc_md == 1) {
        if (match(line, re_h2) && !match(lower, re_toc_h2)) {
          in_toc_md = 0
        } else if (match(line, /\[[^]]+\]\([^)]*\)/)) {
          toc_item = substr(line, RSTART, RLENGTH)

          toc_text = toc_item
          sub(/^\[/, "", toc_text)
          sub(/\]\([^)]*\)$/, "", toc_text)
          gsub(/\*\*/, "", toc_text)

          toc_anchor = toc_item
          sub(/^\[[^]]+\]\(#?/, "", toc_anchor)
          sub(/\)$/, "", toc_anchor)
          toc_anchor = normalize_anchor(toc_anchor)

          toc_key = normalize_title(toc_text)
          if (length(toc_anchor) > 0 && !(toc_key in toc_title_to_anchor)) {
            toc_title_to_anchor[toc_key] = toc_anchor
          }

          if (length(toc_anchor) > 0) {
            print "```{=latex}"
            print "\\noindent\\hyperref[" toc_anchor "]{" \
              "\\textcolor{ltlinkblue}{" tex_escape(toc_text) "}}" \
              "\\nobreak\\hspace{0.5em}\\leaders\\hbox{.}" \
              "\\hfill\\hspace{0.5em}\\hyperref[" toc_anchor "]{" \
              "\\textcolor{ltlinkblue}{\\pageref*{" toc_anchor "}}}\\par"
            print "```"
          } else {
            print line
          }
          next
        } else {
          next
        }
      }

      if (title_footer_pushed != 1 &&
          (match(lower, /^#[[:space:]]*copyright/) ||
          match(lower, /^##[[:space:]]*copyright/) ||
          match(lower, /^###[[:space:]]*copyright/) ||
          match(lower, /^####[[:space:]]*copyright/) ||
          match(lower, /^#####[[:space:]]*copyright/) ||
          match(lower, /^######[[:space:]]*copyright/))) {
        print "```{=latex}"
        print "\\vfill"
        print "```"
        title_footer_pushed = 1
        print line
        next
      }

      if (match(lower, /^##[[:space:]]*license[[:space:]]*$/)) {
        print "License"
        next
      }

      if (match(lower, /^[[:space:]]*spdx-license-identifier:/)) {
        print tex_escape(line)
        next
      }

      print line
    }
AWKPROGRAM
}

# ============================================================================
# AWK MARKDOWN PROCESSING - DETAILS REMOVAL MODE (DEFAULT)
# ============================================================================

# AWK program to remove <details>/<summary> HTML tags (default behavior).
# Still handles logo embedding and version display, but strips collapsible
# sections.
generate_awk_remove_details() {
  cat <<'AWKPROGRAM'
    function tex_escape(text) {
      gsub(/\\/, "\\textbackslash{}", text)
      gsub(/\{/, "\\{", text)
      gsub(/\}/, "\\}", text)
      gsub(/#/, "\\#", text)
      gsub(/\$/, "\\$", text)
      gsub(/%/, "\\%", text)
      gsub(/&/, "\\&", text)
      gsub(/_/, "\\_", text)
      return text
    }

    function png_path_from_line(line,    value, parts) {
      if (match(line, re_png_ref)) {
        value = substr(line, RSTART, RLENGTH)
        sub(/^!\[[^]]*\]\(/, "", value)
        sub(/\)$/, "", value)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
        if (value ~ /^<.*>$/) {
          sub(/^</, "", value)
          sub(/>$/, "", value)
        }
        split(value, parts, /[[:space:]]+/)
        return parts[1]
      }
      return ""
    }

    function badge_png_url(image_url, link_url,    base, query) {
      if (image_url ~ re_gh_badge) {
        if (match(image_url, re_gh_badge_cap, \
            m)) {
          return "https://img.shields.io/github/actions/workflow/status/" \
            m[1] "/" m[2] "/" m[3] ".png?branch=main" "&label=CI"
        }
      }

      if (image_url ~ /^https:\/\/img\.shields\.io\//) {
        if (index(image_url, "?") > 0) {
          split(image_url, q, "?")
          base = q[1]
          query = q[2]
          if (base ~ /\.svg$/) {
            sub(/\.svg$/, ".png", base)
          } else if (base !~ /\.(png|jpg|jpeg|gif|webp)$/) {
            base = base ".png"
          }
          return base "?" query
        }

        base = image_url
        if (base ~ /\.svg$/) {
          sub(/\.svg$/, ".png", base)
        } else if (base !~ /\.(png|jpg|jpeg|gif|webp)$/) {
          base = base ".png"
        }
        return base
      }

      return image_url
    }

    function normalize_anchor(anchor) {
      sub(/^#/, "", anchor)
      sub(/^user-content-/, "", anchor)
      if (anchor ~ /^[0-9]+([.-][0-9]+)*-/) {
        sub(/^[0-9]+([.-][0-9]+)*-/, "", anchor)
      }
      return anchor
    }

    function normalize_title(text,    t) {
      t = tolower(text)
      gsub(/\*\*/, "", t)
      gsub(/[*`_]/, "", t)
      gsub(/<[^>]+>/, "", t)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", t)
      if (t ~ /^[0-9]+([.][0-9]+)*[.)]?[[:space:]]+/) {
        sub(/^[0-9]+([.][0-9]+)*[.)]?[[:space:]]+/, "", t)
      }
      gsub(/[[:space:]]+/, " ", t)
      return t
    }

    BEGIN {
      re_png_ref = "!\\[[^]]*\\]\\(([^)]+\\.[Pp][Nn][Gg]"
      re_png_ref = re_png_ref "([[:space:]][^)]+)?)\\)"
      re_gh_badge = "^https://github\\.com/[^/]+/[^/]+/actions/"
      re_gh_badge = re_gh_badge "workflows/[^/]+/badge\\.svg$"
      re_gh_badge_cap = "^https://github\\.com/([^/]+)/([^/]+)/actions/"
      re_gh_badge_cap = re_gh_badge_cap "workflows/([^/]+)/badge\\.svg$"
      re_badge_single = "^[[:space:]]*\\[!\\[([^]]*)\\]\\(([^)]*)\\)"
      re_badge_single = re_badge_single "\\]\\(([^)]*)\\)[[:space:]]*$"
      re_badge_multi = "^[[:space:]]*\\[!\\[[^]]*\\]\\([^)]*\\)\\]\\([^)]*\\)"
      re_badge_multi = re_badge_multi "([[:space:]]+\\[!\\[[^]]*\\]\\([^)]*\\)"
      re_badge_multi = re_badge_multi "\\]\\([^)]*\\))*[[:space:]]*$"
      re_details_open = "^[[:space:]]*<[[:space:]]*details"
      re_details_open = re_details_open "([[:space:]][^>]*)?>[[:space:]]*$"
      re_details_close = "^[[:space:]]*<[[:space:]]*/[[:space:]]*details"
      re_details_close = re_details_close "([[:space:]][^>]*)?>[[:space:]]*$"
      re_summary_close = "<[[:space:]]*/[[:space:]]*summary([[:space:]][^>]*)?>"
      re_png_line = "^[[:space:]]*!\\[[^]]*\\]\\([^)]*\\.[Pp][Nn][Gg]"
      re_png_line = re_png_line "([[:space:]][^)]+)?\\)[[:space:]]*$"
      re_h2 = "^##[[:space:]]+"
      re_toc_h2 = "^##[[:space:]]*table of contents[[:space:]]*$"
    }

    {
      line = $0
      lower = tolower(line)

      if (match(line, re_badge_single, badge_parts)) {
        if (title_done != 1) {
          badge_img = badge_png_url(badge_parts[2], badge_parts[3])
          print "[![" badge_parts[1] "](" badge_img ")](" badge_parts[3] ")"
        }
        next
      }
      if (match(line, re_badge_multi)) {
        next
      }

      if (skip_why == 1) {
        if (match(line, /^##?#?#?[[:space:]]/)) {
          skip_why = 0
        } else {
          next
        }
      }

      if (match(lower, /^[[:space:]]*####[[:space:]]*why click to view/)) {
        skip_why = 1
        next
      }

      if (match(lower, re_details_open) || match(lower, re_details_close)) {
        next
      }

      if (in_summary == 1) {
        if (match(lower, re_summary_close)) {
          in_summary = 0
        }
        next
      }

      if (match(lower, /<[[:space:]]*summary([[:space:]][^>]*)?>/)) {
        if (!match(lower, re_summary_close)) {
          in_summary = 1
        }
        next
      }

      if (match(line, re_png_line)) {
        if (title_done != 1) {
          png_path = logo_png
          if (length(png_path) == 0) {
            png_path = png_path_from_line(line)
          }
          title_done = 1
          print "```{=latex}"
          print "\\vspace*{\\baselineskip}"
          print "\\noindent\\includegraphics[width=\\textwidth]{" \
            "\\detokenize{" png_path "}}"
          print "```"
          if (have_versions == 1) {
            print "```{=latex}"
            print "\\vspace{\\baselineskip}"
            print "\\vspace{\\baselineskip}"
            print "\\noindent Document Version: " \
              tex_escape(document_version) "\\\\"
            print "\\noindent Runner Version: " \
              tex_escape(runner_version) "\\\\"
            print "\\noindent Test Version: " tex_escape(test_version) "\\\\"
            print "```"
          }
          next
        }
        print line
        next
      }

      if (title_done == 1 && match(line, /^Document Version:[[:space:]]/)) {
        next
      }
      if (title_done == 1 && match(line, /^Runner Version:[[:space:]]/)) {
        next
      }
      if (title_done == 1 && match(line, /^Test Version:[[:space:]]/)) {
        next
      }

      if (title_done == 1 && title_footer_pushed != 1 &&
          (match(line, /^\*\*Copyright/) || match(line, /^Copyright/) ||
           match(lower, /^#[[:space:]]*copyright/) ||
           match(lower, /^##[[:space:]]*copyright/) ||
           match(lower, /^###[[:space:]]*copyright/) ||
           match(lower, /^####[[:space:]]*copyright/) ||
           match(lower, /^#####[[:space:]]*copyright/) ||
           match(lower, /^######[[:space:]]*copyright/) ||
           match(lower, /^#[[:space:]]*license/) ||
           match(lower, /^##[[:space:]]*license/) ||
           match(lower, /^###[[:space:]]*license/) ||
           match(lower, /^####[[:space:]]*license/) ||
           match(lower, /^#####[[:space:]]*license/) ||
           match(lower, /^######[[:space:]]*license/))) {
        print "```{=latex}"
        print "\\vfill"
        print "```"
        title_footer_pushed = 1
      }

      if (match(line, re_h2)) {
        section_title = line
        sub(/^##[[:space:]]+/, "", section_title)
        if (tolower(section_title) != "license") {
          section_key = normalize_title(section_title)
          section_anchor = ""
          if (section_key in toc_title_to_anchor) {
            section_anchor = toc_title_to_anchor[section_key]
          }
          print "```{=latex}"
          print "\\clearpage"
          if (main_numbering_started != 1 && section_title ~ /^1\./) {
            print "\\pagenumbering{arabic}"
            print "\\setcounter{page}{1}"
            main_numbering_started = 1
          }
          if (length(section_anchor) > 0) {
            print "\\phantomsection"
            print "\\label{" section_anchor "}"
          }
          print "\\ltsetrunninghead{" tex_escape(section_title) "}"
          print "\\global\\ltaftertoctrue"
          print "```"
        }
      }

      if (match(lower, re_toc_h2)) {
        in_toc_md = 1
        print line
        print ""
        next
      }

      if (in_toc_md == 1) {
        if (match(line, re_h2) && !match(lower, re_toc_h2)) {
          in_toc_md = 0
        } else if (match(line, /\[[^]]+\]\([^)]*\)/)) {
          toc_item = substr(line, RSTART, RLENGTH)

          toc_text = toc_item
          sub(/^\[/, "", toc_text)
          sub(/\]\([^)]*\)$/, "", toc_text)
          gsub(/\*\*/, "", toc_text)

          toc_anchor = toc_item
          sub(/^\[[^]]+\]\(#?/, "", toc_anchor)
          sub(/\)$/, "", toc_anchor)
          toc_anchor = normalize_anchor(toc_anchor)

          toc_key = normalize_title(toc_text)
          if (length(toc_anchor) > 0 && !(toc_key in toc_title_to_anchor)) {
            toc_title_to_anchor[toc_key] = toc_anchor
          }

          if (length(toc_anchor) > 0) {
            print "```{=latex}"
            print "\\noindent\\hyperref[" toc_anchor "]{" \
              "\\textcolor{ltlinkblue}{" tex_escape(toc_text) "}}" \
              "\\nobreak\\hspace{0.5em}\\leaders\\hbox{.}" \
              "\\hfill\\hspace{0.5em}\\hyperref[" toc_anchor "]{" \
              "\\textcolor{ltlinkblue}{\\pageref*{" toc_anchor "}}}\\par"
            print "```"
          } else {
            print line
          }
          next
        } else {
          next
        }
      }

      if (title_footer_pushed != 1 &&
          (match(lower, /^#[[:space:]]*copyright/) ||
          match(lower, /^##[[:space:]]*copyright/) ||
          match(lower, /^###[[:space:]]*copyright/) ||
          match(lower, /^####[[:space:]]*copyright/) ||
          match(lower, /^#####[[:space:]]*copyright/) ||
          match(lower, /^######[[:space:]]*copyright/))) {
        print "```{=latex}"
        print "\\vfill"
        print "```"
        title_footer_pushed = 1
        print line
        next
      }

      if (match(lower, /^##[[:space:]]*license[[:space:]]*$/)) {
        print "License"
        next
      }

      if (match(lower, /^[[:space:]]*spdx-license-identifier:/)) {
        print tex_escape(line)
        next
      }

      print line
    }
AWKPROGRAM
}

# ============================================================================
# FILE PROCESSING - SINGLE DOCUMENT
# ============================================================================

# Process a single markdown file: extract metadata, preprocess, and convert
# to PDF.
# Handles logo extraction on second pass (during markdown conversion,
# not metadata scan).
# Args: $1=source_file, $2=target_pdf_file
process_file() {
  local source_file=$1
  local target_file=$2
  local source_dir
  local document_version=""
  local runner_version=""
  local test_version=""
  local have_versions=0
  local scan_key
  local scan_value
  local temp_file
  local logo_png=""
  local doc_title=""

  doc_title=$(_genpdf_title_from_first_line "$source_file" 2>/dev/null || true)

  # Single-pass metadata scan: extract only version numbers
  # (not logo, not unused TOC flag).
  while IFS=$'\t' read -r scan_key scan_value; do
    case "$scan_key" in
      DOC)
        document_version=$scan_value
        ;;
      RUNNER)
        runner_version=$scan_value
        ;;
      TEST)
        test_version=$scan_value
        ;;
    esac
  done < <(scan_markdown_metadata "$source_file")

  if [[ -n "$document_version" && -n "$runner_version" && \
    -n "$test_version" ]]; then
    have_versions=1
  fi

  temp_file=$(mktemp)
  source_dir=$(dirname "$source_file")

  # Extract the first PNG image line and resolve it relative to source_dir.
  # The AWK programs need an absolute-or-cwd-relative path for \includegraphics.
  logo_png=""
  first_png_line=$(awk '
    BEGIN {
      re_png = "^[[:space:]]*![[][^]]*[]][[:space:]]*\\([^)]*\\.[Pp][Nn][Gg]"
      re_png = re_png "([[:space:]][^)]+)?\\)[[:space:]]*$"
    }
    $0 ~ re_png {
      print
      exit
    }
  ' "$source_file")
  _png_regex='\!\[([^]]*)\]\(([^)]+\.[Pp][Nn][Gg])([[:space:]][^)]*)?\)'
  if [[ -n "$first_png_line" && "$first_png_line" =~ $_png_regex ]]; then
    raw_png="${BASH_REMATCH[2]}"
    if [[ "$raw_png" == /* ]]; then
      logo_png="$raw_png"
    else
      logo_png="$source_dir/$raw_png"
    fi
    if command -v realpath >/dev/null 2>&1; then
      logo_png=$(realpath "$logo_png")
    else
      logo_png=$(python3 - <<'PY' "$logo_png"
import os
import sys
print(os.path.realpath(sys.argv[1]))
PY
)
    fi
  fi

  log_debug "scan metadata: logo=${logo_png} versions=${have_versions} "\
"source=$source_file"

  # Extract copyright line for centered running footer (strip heading markup)
  copyright_text=$(grep -im1 '^[[:space:]#*]*copyright' "$source_file" | \
    sed 's/^[[:space:]#*]*//' || true)

  # Apply markdown preprocessing (convert or remove details/summary tags)
  if [[ $convert_details -eq 1 ]]; then
    generate_awk_convert_details | awk -v document_version="$document_version" \
                                      -v runner_version="$runner_version" \
                                      -v test_version="$test_version" \
                                      -v have_versions="$have_versions" \
                                      -v logo_png="$logo_png" \
                                      -f /dev/stdin \
                                      "$source_file" > "$temp_file"
  else
    generate_awk_remove_details | awk -v document_version="$document_version" \
                                      -v runner_version="$runner_version" \
                                      -v test_version="$test_version" \
                                      -v have_versions="$have_versions" \
                                      -v logo_png="$logo_png" \
                                      -f /dev/stdin \
                                      "$source_file" > "$temp_file"
  fi

  if [[ -n "$emit_markdown_path" ]]; then
    if ! mkdir -p "$(dirname "$emit_markdown_path")"; then
      rm -f "$temp_file"
      return 1
    fi
    if ! cp "$temp_file" "$emit_markdown_path"; then
      rm -f "$temp_file"
      return 1
    fi
  fi

  if ! convert_to_pdf "$temp_file" "$target_file" "$source_dir" \
    "$doc_title" "$copyright_text"; then
    rm -f "$temp_file"
    return 1
  fi

  rm -f "$temp_file"
}

# ============================================================================
# DIRECTORY PROCESSING UTILITIES
# ============================================================================

# Determine output PDF path for a given source markdown file in directory mode.
# Respects -k (keep_structure) flag.
target_file_for_source() {
  local source_file=$1
  local rel_path

  rel_path=${source_file#"$infile"/}
  if [[ $keep_structure -eq 1 ]]; then
    printf '%s\n' "$outdir/${rel_path%.md}.pdf"
  else
    printf '%s\n' "$outdir/$(basename "${source_file%.md}.pdf")"
  fi
}

# ============================================================================
# MAIN ENTRY POINT AND ARGUMENT PROCESSING
# ============================================================================

orig_args=("$@")

# Validate standalone-only options
for arg in "${orig_args[@]}"; do
  case "$arg" in
    -h|--help)
      if [[ ${#orig_args[@]} -ne 1 ]]; then
        log_error "-h and --help must be used by themselves."
        exit 1
      fi
      ;;
    -t)
      if [[ ${#orig_args[@]} -ne 1 ]]; then
        log_error "-t must be used by itself."
        exit 1
      fi
      ;;
  esac
done

# Parse command-line options
while [[ $# -gt 0 ]]; do
  case "$1" in
    -e)
      if [[ $# -lt 2 ]]; then
        log_error "-e requires an output file path"
        exit 1
      fi
      emit_markdown_path=$2
      shift 2
      ;;
    -c)
      convert_details=1
      shift
      ;;
    -n)
      dry_run=1
      shift
      ;;
    -q)
      quiet=1
      shift
      ;;
    -v)
      verbose=1
      shift
      ;;
    -t)
      check_only=1
      shift
      ;;
    -r)
      recursive=1
      shift
      ;;
    -k)
      keep_structure=1
      shift
      ;;
    -g)
      segment_glob=1
      shift
      ;;
    -b)
      if [[ $# -lt 2 ]]; then
        log_error "$1 requires a backend argument: auto, pandoc, "\
      "wkhtmltopdf, weasyprint"
        exit 1
      fi
      if ! validate_backend "$2"; then
        log_error "invalid backend: $2"
        echo "       Use one of: auto,pandoc,wkhtmltopdf,weasyprint" >&2
        exit 1
      fi
      backend=$2
      shift 2
      ;;
    -i)
      if [[ $# -lt 2 ]]; then
        log_error "-i requires a pattern argument."
        exit 1
      fi
      include_patterns+=("$2")
      shift 2
      ;;
    -x)
      if [[ $# -lt 2 ]]; then
        log_error "-x requires a pattern argument."
        exit 1
      fi
      exclude_patterns+=("$2")
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      log_error "unknown option: $1"
      usage >&2
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

# Handle toolchain check mode (-t)
if [[ $check_only -eq 1 ]]; then
  if [[ $# -gt 0 ]]; then
    log_error "-t cannot be used with positional arguments."
    exit 1
  fi

  if command -v pandoc >/dev/null 2>&1; then
    if command -v pdflatex >/dev/null 2>&1 ||
      command -v lualatex >/dev/null 2>&1 ||
      command -v xelatex >/dev/null 2>&1 ||
      command -v tectonic >/dev/null 2>&1 ||
      command -v wkhtmltopdf >/dev/null 2>&1 ||
      command -v weasyprint >/dev/null 2>&1 ||
      command -v prince >/dev/null 2>&1; then
      log_info "Toolchain: pandoc with PDF engine available"
      exit 0
    fi
    log_info "Toolchain: pandoc available (no explicit engine detected; "\
  "pandoc default may still work)"
    exit 0
  fi

  if command -v python3 >/dev/null 2>&1 &&
    (command -v wkhtmltopdf >/dev/null 2>&1 ||
      command -v weasyprint >/dev/null 2>&1); then
    log_info "Toolchain: python3 + HTML-to-PDF backend available"
    exit 0
  fi

  log_error "no supported Markdown-to-PDF toolchain found"
  log_info "Install pandoc (recommended), or install python3 with "\
"wkhtmltopdf or weasyprint."
  exit 1
fi

# Handle input/output argument processing
if [[ $# -gt 2 ]]; then
  usage >&2
  exit 1
fi

if [[ $# -eq 0 ]]; then
  infile='.'
else
  infile=$1
fi

# ============================================================================
# DIRECTORY MODE PROCESSING
# ============================================================================

if [[ -d "$infile" ]]; then
  if [[ -n "$emit_markdown_path" ]]; then
    log_error "-e is only supported in single-document mode."
    exit 1
  fi

  indir=$infile
  outdir=${2:-$indir}
  outdir=$(trim_trailing_slashes "$outdir")

  if [[ $# -gt 2 ]]; then
    echo "Error: directory mode accepts at most two arguments." >&2
    exit 1
  fi

  if [[ ! -d "$outdir" && $dry_run -eq 0 ]]; then
    if ! mkdir -p "$outdir"; then
      echo "Error: unable to create output directory: $outdir" >&2
      exit 1
    fi
  fi

  md_files=()

  if [[ $recursive -eq 1 ]]; then
    while IFS= read -r -d '' file; do
      md_files+=("$file")
    done < <(find "$infile" -type f -name '*.md' -print0 | sort -z)
  else
    shopt -s nullglob
    md_files=("$infile"/*.md)
    shopt -u nullglob
  fi

  if [[ ${#md_files[@]} -eq 0 ]]; then
    log_error "no .md files found in directory: $infile"
    exit 1
  fi

  filtered_md_files=()

  for source_file in "${md_files[@]}"; do
    rel_path=${source_file#"$infile"/}

    if [[ ${#include_patterns[@]} -gt 0 ]] && \
      ! match_any_pattern "$rel_path" "${include_patterns[@]}"; then
      continue
    fi

    if [[ ${#exclude_patterns[@]} -gt 0 ]] && \
      match_any_pattern "$rel_path" "${exclude_patterns[@]}"; then
      continue
    fi

    filtered_md_files+=("$source_file")
  done

  if [[ ${#filtered_md_files[@]} -eq 0 ]]; then
    log_error "no input files remain after applying include/exclude filters"
    exit 1
  fi

  # Without -k in recursive mode, duplicate basenames would overwrite outputs.
  if [[ $recursive -eq 1 && $keep_structure -eq 0 ]]; then
    declare -A output_to_source=()

    for source_file in "${filtered_md_files[@]}"; do
      target_file=$(target_file_for_source "$source_file")

      if [[ -n "${output_to_source[$target_file]:-}" ]]; then
        log_error "multiple input files map to the same output file: "\
      "$target_file"
        log_error "conflicting inputs: ${output_to_source[$target_file]} "\
      "and $source_file"
        log_error "use -k to preserve directory structure"
        exit 1
      fi

      output_to_source["$target_file"]=$source_file
    done
  fi

  writable_targets=0

  if [[ $dry_run -eq 0 ]]; then
    for source_file in "${filtered_md_files[@]}"; do
      target_file=$(target_file_for_source "$source_file")

      if [[ $keep_structure -eq 1 ]]; then
        if ! mkdir -p "$(dirname "$target_file")"; then
          continue
        fi
      fi

      if can_write_target "$target_file"; then
        writable_targets=$((writable_targets + 1))
      fi
    done
  fi

  if [[ $dry_run -eq 0 && $writable_targets -eq 0 ]]; then
    log_error "output directory is not writable: $outdir"
    exit 1
  fi

  had_errors=0

  for source_file in "${filtered_md_files[@]}"; do
    target_file=$(target_file_for_source "$source_file")

    if [[ $dry_run -eq 1 ]]; then
      log_info "Dry-run: $source_file -> $target_file"
      continue
    fi

    if [[ $keep_structure -eq 1 ]]; then
      if ! mkdir -p "$(dirname "$target_file")"; then
        log_error "unable to create output path for: $target_file"
        had_errors=1
        continue
      fi
    fi

    if ! can_write_target "$target_file"; then
      log_error "output file is not writable: $target_file"
      had_errors=1
      continue
    fi
    if ! process_file "$source_file" "$target_file"; then
      log_error "failed converting $source_file to $target_file"
      had_errors=1
      continue
    fi
    log_info "Generated $target_file"
  done

  if [[ $had_errors -ne 0 ]]; then
    exit 1
  fi

  exit 0
fi

# ============================================================================
# SINGLE DOCUMENT MODE PROCESSING
# ============================================================================

if [[ $recursive -eq 1 || $keep_structure -eq 1 ||
  $segment_glob -eq 1 || ${#include_patterns[@]} -gt 0 ||
  ${#exclude_patterns[@]} -gt 0 ]]; then
  log_error "-g, -k, -r, -i, and -x are only allowed in directory mode."
  exit 1
fi

input_name=${infile##*/}

if [[ "$infile" == *.md ]]; then
  source_file=$infile
else
  source_file="$infile.md"
fi

if [[ ! -f "$source_file" ]]; then
  log_error "input file not found: $source_file"
  exit 1
fi

outfile=${2:-${source_file%.md}}
outfile=$(trim_trailing_slashes "$outfile")

if [[ "$outfile" != *.pdf ]]; then
  outfile="$outfile.pdf"
fi

if [[ $dry_run -eq 1 ]]; then
  log_info "Dry-run: $source_file -> $outfile"
  exit 0
fi

if ! can_write_target "$outfile"; then
  log_error "output file is not writable: $outfile"
  exit 1
fi

process_file "$source_file" "$outfile"

log_info "Generated $outfile"
