#!/usr/bin/env bash
set -euo pipefail

# Internal helper: gendocx.sh (not public CLI)

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

log_info() { [[ $quiet -eq 0 ]] && echo "$1"; }
log_debug() { [[ $verbose -eq 1 ]] && echo "Debug: $1" >&2; }
log_error() { echo "Error: $1" >&2; }

validate_backend() {
  case "$1" in
    auto|python|libreoffice) return 0 ;;
    *) return 1 ;;
  esac
}

toolcheck_python() {
  command -v python3 >/dev/null 2>&1 || return 1
  python3 - <<'PY' >/dev/null 2>&1
from pdf2docx import Converter  # noqa
print("ok")
PY
}
toolcheck_libreoffice() {
  command -v libreoffice >/dev/null 2>&1 || command -v soffice >/dev/null 2>&1
}

show_toolcheck() {
  local py="missing" lo="missing"
  toolcheck_python && py="available"
  toolcheck_libreoffice && lo="available"
  echo "python(pdf2docx): $py"
  echo "libreoffice:     $lo"
  [[ "$py" == "available" || "$lo" == "available" ]]
}

run_python() {
  python3 - "$1" "$2" <<'PY'
import sys
from pdf2docx import Converter
cv = Converter(sys.argv[1])
try:
    cv.convert(sys.argv[2])
finally:
    cv.close()
PY
}

run_libreoffice() {
  local in_pdf=$1 out_docx=$2 outdir cmd expected
  outdir=$(dirname "$out_docx")
  mkdir -p "$outdir"

  if command -v libreoffice >/dev/null 2>&1; then cmd=libreoffice
  elif command -v soffice >/dev/null 2>&1; then cmd=soffice
  else return 1
  fi

  "$cmd" --headless --convert-to docx --outdir "$outdir" "$in_pdf" >/dev/null
  expected="$outdir/$(basename "${in_pdf%.*}").docx"
  [[ -f "$expected" ]] || return 1
  [[ "$expected" == "$out_docx" ]] || mv -f "$expected" "$out_docx"
}

convert_pdf_to_docx() {
  local in_pdf=$1 out_docx=$2

  mkdir -p "$(dirname "$out_docx")"

  if [[ "$backend" != "auto" ]]; then
    case "$backend" in
      python) run_python "$in_pdf" "$out_docx" ;;
      libreoffice) run_libreoffice "$in_pdf" "$out_docx" ;;
    esac
    return
  fi

  run_python "$in_pdf" "$out_docx" 2>/dev/null || run_libreoffice "$in_pdf" "$out_docx"
}

# Parse
while [[ $# -gt 0 ]]; do
  case "$1" in
    -b) shift; backend="${1:-}" ;;
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
if [[ $check_only -eq 1 ]]; then show_toolcheck; exit $?; fi

in="${1:-}"
out="${2:-}"
[[ -n "$in" ]] || { log_error "missing input"; exit 2; }
[[ -n "$out" ]] || { log_error "missing output"; exit 2; }

if [[ $dry_run -eq 1 ]]; then
  log_info "Dry-run: $in -> $out"
  exit 0
fi

[[ -f "$in" ]] || { [[ -f "${in}.pdf" ]] && in="${in}.pdf" || { log_error "input not found: $in"; exit 1; }; }
[[ "$out" == *.docx ]] || out="${out}.docx"

convert_pdf_to_docx "$in" "$out" || { log_error "failed converting $in -> $out"; exit 1; }
log_info "$in -> $out"
