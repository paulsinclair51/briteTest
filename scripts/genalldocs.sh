#!/usr/bin/env bash
set -euo pipefail

# Generate all LiteTest documentation PDFs by invoking scripts/genpdf for
# each source document individually.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
genpdf_script="$repo_root/scripts/genpdf"
docs_dir="$repo_root/docs"
out_dir="$repo_root/docs/pdf"

usage() {
  cat <<'EOF'
Usage:
  genalldocs.sh
  genalldocs.sh -h | --help

Generates all LiteTest documentation PDFs by calling scripts/genpdf once per
source document.

Outputs:
  docs/pdf/LiteTest.pdf                         (from README.md)
  docs/pdf/LiteTest_*.pdf                       (from docs/LiteTest_*.md)
EOF
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -ne 0 ]]; then
  echo "Error: no positional arguments are supported." >&2
  usage >&2
  exit 1
fi

if [[ ! -x "$genpdf_script" ]]; then
  echo "Error: missing executable genpdf script: $genpdf_script" >&2
  exit 1
fi

mkdir -p "$out_dir"

"$genpdf_script" "$repo_root/README.md" "$out_dir/LiteTest.pdf"

mapfile -t docs_files < <(find "$docs_dir" -maxdepth 1 -type f -name 'LiteTest_*.md' | sort)

if [[ ${#docs_files[@]} -eq 0 ]]; then
  echo "Error: no docs/LiteTest_*.md files found." >&2
  exit 1
fi

for src in "${docs_files[@]}"; do
  base="$(basename "${src%.md}")"
  dst="$out_dir/${base}.pdf"
  "$genpdf_script" "$src" "$dst"
done

echo "Generated all documentation PDFs in $out_dir"
