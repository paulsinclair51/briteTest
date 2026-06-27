#!/usr/bin/env bash
set -euo pipefail

# Generate BriteTest branding PNGs from the corresponding SVG sources.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
branding_dir="$repo_root/docs/branding"

usage() {
  cat <<'EOF'
Usage:
  genpng.sh
  genpng.sh -h | --help

Generates all BriteTest branding PNGs from docs/branding/BriteTest_*.svg.

Outputs:
  docs/branding/BriteTest_*.png  (from docs/branding/BriteTest_*.svg)
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

if ! command -v rsvg-convert >/dev/null 2>&1; then
  echo "Error: missing required command: rsvg-convert" >&2
  exit 1
fi

mapfile -t svg_files < <(find "$branding_dir" -maxdepth 1 -type f -name 'BriteTest_*.svg' | sort)

if [[ ${#svg_files[@]} -eq 0 ]]; then
  echo "Error: no docs/branding/BriteTest_*.svg files found." >&2
  exit 1
fi

for src in "${svg_files[@]}"; do
  dst="${src%.svg}.png"
  rsvg-convert "$src" -o "$dst"
done

echo "Generated all branding PNGs in $branding_dir"