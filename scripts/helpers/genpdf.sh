#!/usr/bin/env bash
set -euo pipefail

# Internal helper: genpdf.sh (not public CLI)

quiet=0
verbose=0
check_only=0
recursive=0
keep_structure=0
dry_run=0
backend=auto
segment_glob=0
convert_details=0
declare -a include_patterns=()
declare -a exclude_patterns=()

log_info() { [[ $quiet -eq 0 ]] && echo "$1"; }
log_debug() { [[ $verbose -eq 1 ]] && echo "Debug: $1" >&2; }
log_error() { echo "Error: $1" >&2; }

validate_backend() {
  case "$1" in
    auto|pandoc|wkhtmltopdf|weasyprint) return 0 ;;
    *) return 1 ;;
  esac
}

toolcheck() {
  if command -v pandoc >/dev/null 2>&1; then
    echo "Toolchain: pandoc available"
    return 0
  fi
  if command -v python3 >/dev/null 2>&1 && (command -v wkhtmltopdf >/dev/null 2>&1 || command -v weasyprint >/dev/null 2>&1); then
    echo "Toolchain: python3 + HTML-to-PDF backend available"
    return 0
  fi
  log_error "no supported Markdown-to-PDF toolchain found"
  return 1
}

convert_md_to_pdf() {
  local in_md=$1
  local out_pdf=$2
  local tmp_md=''

  if [[ $convert_details -eq 0 ]]; then
    tmp_md=$(mktemp)
    awk '
      {
        l=tolower($0)
        if (l ~ /^[[:space:]]*<[[:space:]]*details([[:space:]][^>]*)?>[[:space:]]*$/) next
        if (l ~ /^[[:space:]]*<[[:space:]]*\/[[:space:]]*details([[:space:]][^>]*)?>[[:space:]]*$/) next
        if (l ~ /<[[:space:]]*summary([[:space:]][^>]*)?>/) next
        if (l ~ /<[[:space:]]*\/[[:space:]]*summary([[:space:]][^>]*)?>/) next
        print
      }' "$in_md" > "$tmp_md"
    in_md="$tmp_md"
  fi

  mkdir -p "$(dirname "$out_pdf")"

  if [[ "$backend" == "pandoc" || "$backend" == "auto" ]]; then
    if command -v pandoc >/dev/null 2>&1; then
      pandoc "$in_md" -o "$out_pdf" && { [[ -n "$tmp_md" ]] && rm -f "$tmp_md"; return 0; }
      [[ "$backend" == "pandoc" ]] && { [[ -n "$tmp_md" ]] && rm -f "$tmp_md"; return 1; }
    fi
  fi

  # Simple fallback: markdown->html->pdf
  html_tmp=$(mktemp --suffix=.html)
  python3 - "$in_md" "$html_tmp" <<'PY'
import html, pathlib, sys
md = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
pathlib.Path(sys.argv[2]).write_text(f"<html><body><pre>{html.escape(md)}</pre></body></html>", encoding="utf-8")
PY

  if [[ "$backend" == "wkhtmltopdf" || "$backend" == "auto" ]]; then
    if command -v wkhtmltopdf >/dev/null 2>&1; then
      wkhtmltopdf "$html_tmp" "$out_pdf" >/dev/null 2>&1 && { rm -f "$html_tmp"; [[ -n "$tmp_md" ]] && rm -f "$tmp_md"; return 0; }
      [[ "$backend" == "wkhtmltopdf" ]] && { rm -f "$html_tmp"; [[ -n "$tmp_md" ]] && rm -f "$tmp_md"; return 1; }
    fi
  fi

  if [[ "$backend" == "weasyprint" || "$backend" == "auto" ]]; then
    if command -v weasyprint >/dev/null 2>&1; then
      weasyprint "$html_tmp" "$out_pdf" && { rm -f "$html_tmp"; [[ -n "$tmp_md" ]] && rm -f "$tmp_md"; return 0; }
    fi
  fi

  rm -f "$html_tmp"
  [[ -n "$tmp_md" ]] && rm -f "$tmp_md"
  return 1
}

# Parse
while [[ $# -gt 0 ]]; do
  case "$1" in
    -b) shift; backend="${1:-}" ;;
    -c) convert_details=1 ;;
    -g) segment_glob=1 ;; # accepted for symmetry
    -i) shift; include_patterns+=("${1:-}") ;;
    -k) keep_structure=1 ;;
    -n) dry_run=1 ;;
    -q) quiet=1 ;;
    -r) recursive=1 ;;
    -t) check_only=1 ;;
    -v) verbose=1 ;;
    -x) shift; exclude_patterns+=("${1:-}") ;;
    -*) log_error "unknown option: $1"; exit 2 ;;
    *) break ;;
  esac
  shift
done

validate_backend "$backend" || { log_error "invalid backend: $backend"; exit 2; }
if [[ $check_only -eq 1 ]]; then toolcheck; exit $?; fi

in="${1:-}"
out="${2:-}"
[[ -n "$in" ]] || { log_error "missing input"; exit 2; }
[[ -n "$out" ]] || { log_error "missing output"; exit 2; }

if [[ $dry_run -eq 1 ]]; then
  log_info "Dry-run: $in -> $out"
  exit 0
fi

[[ -f "$in" ]] || { [[ -f "${in}.md" ]] && in="${in}.md" || { log_error "input not found: $in"; exit 1; }; }
[[ "$out" == *.pdf ]] || out="${out}.pdf"

convert_md_to_pdf "$in" "$out" || { log_error "failed converting $in -> $out"; exit 1; }
log_info "Generated $out"
