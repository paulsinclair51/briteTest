#!/usr/bin/env bash

# genpdf.sh - Normalize markdown input before delegating to genpdf.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail

# Internal helper: preserve the styled genpdf behavior by normalizing the
# source markdown before delegating to the original generator.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REAL_GENPDF="$SCRIPT_DIR/../bin/genpdf"

preprocess_source_file() {
	local source_file=$1
	local temp_file=$2
	local logo_line

	logo_line=$(awk '
		/^[[:space:]]*!\[[^]]*\]\([^)]*\.[Pp][Nn][Gg]([[:space:]][^)]+)?\)[[:space:]]*$/ {
			print NR
			exit
		}
	' "$source_file")

	if [[ -z "$logo_line" || "$logo_line" -le 1 ]]; then
		return 1
	fi

	{
		sed -n "${logo_line}p" "$source_file"
		printf '\n'
		awk -v skip_line="$logo_line" 'NR != skip_line { print }' "$source_file"
	} > "$temp_file"
}

args=("$@")
input_index=-1
seen_double_dash=0

for ((i=0; i<${#args[@]}; i++)); do
	arg=${args[i]}
	if [[ $seen_double_dash -eq 1 ]]; then
		input_index=$i
		break
	fi

	case "$arg" in
		--)
			seen_double_dash=1
			;;
		-b|-i|-x)
			i=$((i + 1))
			;;
		-h|--help|-t|-c|-n|-q|-v|-r|-k|-g|-s|-p)
			;;
		-* )
			;;
		*)
			input_index=$i
			break
			;;
	esac
done

temp_input=''
trap_cleanup() {
	[[ -n "$temp_input" && -f "$temp_input" ]] && rm -f "$temp_input"
	return 0
}
trap trap_cleanup EXIT

if [[ $input_index -ge 0 ]]; then
	input_path=${args[input_index]}
	if [[ -f "$input_path" && "$input_path" == *.md ]]; then
		temp_input=$(mktemp --tmpdir="$REPO_ROOT" .genpdf.XXXXXX.md)
		if preprocess_source_file "$input_path" "$temp_input"; then
			args[input_index]="$temp_input"
		else
			rm -f "$temp_input"
			temp_input=''
		fi
	fi
fi

bash "$REAL_GENPDF" "${args[@]}"
