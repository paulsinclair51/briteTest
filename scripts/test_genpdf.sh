#!/usr/bin/env bash

# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see ./LICENSE.

set -euo pipefail
export LC_ALL=C

# Backend-related tests are intentionally environment-tolerant because
# optional conversion tools may or may not be installed on the host.

usage() {
  cat <<'EOF'
Usage:
  test_genpdf.sh
  test_genpdf.sh -v
  test_genpdf.sh -h | --help

Runs a test suite for scripts/genpdf using temporary files and
a stub pandoc binary.

Options:
  -h, --help  Show this help and exit.
  -v          Verbose: print phase markers.
EOF
}

fail() {
  echo "Error: $1" >&2
  exit 1
}

phase() {
  if [[ $verbose -eq 1 ]]; then
    echo "TEST: $1" >&2
  fi
}

assert_file_exists() {
  local file=$1
  [[ -f "$file" ]] || fail "expected file to exist: $file"
}

assert_file_not_exists() {
  local file=$1
  [[ ! -f "$file" ]] || fail "expected file to not exist: $file"
}

assert_empty_file() {
  local file=$1
  [[ ! -s "$file" ]] || fail "expected file to be empty: $file"
}

assert_contains() {
  local text=$1
  local file=$2
  grep -Fq -- "$text" "$file" || fail "expected '$text' in $file"
}

assert_matches() {
  local regex=$1
  local file=$2
  grep -Eq -- "$regex" "$file" || fail "expected pattern '$regex' in $file"
}

verbose=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -v)
      verbose=1
      shift
      ;;
    *)
      echo "Error: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

for dep in grep mktemp; do
  command -v "$dep" >/dev/null 2>&1 || fail "missing required command: $dep"
done

repo_root=$(cd "$(dirname "$0")/.." && pwd)
script="$repo_root/scripts/genpdf"

if [[ ! -x "$script" ]]; then
  fail "missing executable script: $script"
fi

# Keep this harness deterministic even when parent env exports these values.
unset GENPDF_STRICT || true
unset PANDOC_FAIL_CODE || true

tmpdir=$(mktemp -d)
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

mkdir -p "$tmpdir/in/sub" "$tmpdir/out" "$tmpdir/bin"

cat > "$tmpdir/in/readme.md" <<'EOF'
# Root README
EOF

cat > "$tmpdir/in/one.md" <<'EOF'
# One
<details>
<summary>Hidden</summary>
ignore me
</details>
EOF

cat > "$tmpdir/in/multisummary.md" <<'EOF'
# Multi Summary
<details>
<summary>
Hidden multiline summary text
</summary>
Visible body text
</details>
EOF

cat > "$tmpdir/in/whyclick.md" <<'EOF'
# Why Click

#### Why Click to view?

- This should be removed.

## Section One

Section one content.

## Section Two

Section two content.
EOF

cat > "$tmpdir/in/toc_bullets.md" <<'EOF'
# TOC Bullets

## Table of Contents

- [1. Introduction](#1-introduction)
  - [1.1 Subsection](#11-subsection)

## 1. Introduction

Intro text.

## 1.1 Subsection

Subsection text.
EOF

cat > "$tmpdir/in/sub/two.md" <<'EOF'
# Two
EOF

cat > "$tmpdir/in/sub/readme.md" <<'EOF'
# Sub README
EOF

cat > "$tmpdir/in/sub/skip.md" <<'EOF'
# Skip
EOF

mkdir -p "$tmpdir/in/sub/deep"
cat > "$tmpdir/in/sub/deep/three.md" <<'EOF'
# Three
EOF

cat > "$tmpdir/bin/pandoc" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
# Stub converter: create output file and keep a copy of markdown input for checks.
outfile=""
infile=""

if [[ -n "${PANDOC_FAIL_CODE:-}" ]]; then
  exit "$PANDOC_FAIL_CODE"
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o)
      outfile=$2
      shift 2
      ;;
    -V|--include-in-header)
      shift 2
      ;;
    -f|--pdf-engine)
      shift 2
      ;;
    *)
      infile=$1
      shift
      ;;
  esac
done

if [[ -n "$infile" && -n "$outfile" ]]; then
  cp "$infile" "${outfile}.src"
  touch "$outfile"
  exit 0
fi

exit 1
EOF

chmod +x "$tmpdir/bin/pandoc"

orig_path=$PATH
test_path="$tmpdir/bin:$orig_path"

test_help_and_usage() {
  phase "help and usage"

  "$script" -h >"$tmpdir/help.out"
  assert_matches '^  genpdf \[<doc_options>\] <document>\[\.md\] \[<outdocument>\[\.pdf\]\]$' "$tmpdir/help.out"
  assert_contains "-b  Force conversion backend instead of auto-detecting." "$tmpdir/help.out"
  assert_contains "-n  Show planned conversions without writing output files." "$tmpdir/help.out"

  "$script" --help >"$tmpdir/help_long.out"
  assert_matches '^Usage:$' "$tmpdir/help_long.out"
}

test_backend_option_behavior() {
  phase "backend option behavior"

  PATH="$test_path" "$script" -b pandoc "$tmpdir/in/one.md" "$tmpdir/out/backend_pandoc.pdf" >/dev/null
  assert_file_exists "$tmpdir/out/backend_pandoc.pdf"

  if PATH="$test_path" "$script" -b invalid "$tmpdir/in/one.md" "$tmpdir/out/backend_invalid.pdf" >/dev/null 2>"$tmpdir/backend_invalid.err"; then
    fail "invalid backend check unexpectedly passed"
  fi
  assert_contains "invalid backend" "$tmpdir/backend_invalid.err"

  if PATH="$test_path" "$script" -b wkhtmltopdf "$tmpdir/in/one.md" "$tmpdir/out/backend_wkhtmltopdf.pdf" >/dev/null 2>"$tmpdir/backend_wkhtmltopdf.err"; then
    assert_file_exists "$tmpdir/out/backend_wkhtmltopdf.pdf"
  else
    assert_contains "requested backend 'wkhtmltopdf' failed or is not available" "$tmpdir/backend_wkhtmltopdf.err"
  fi

  if PATH="$test_path" "$script" -b weasyprint "$tmpdir/in/one.md" "$tmpdir/out/backend_weasyprint.pdf" >/dev/null 2>"$tmpdir/backend_weasyprint.err"; then
    assert_file_exists "$tmpdir/out/backend_weasyprint.pdf"
  else
    assert_contains "requested backend 'weasyprint' failed or is not available" "$tmpdir/backend_weasyprint.err"
  fi
}

test_dry_run_behavior() {
  phase "dry-run behavior"

  PATH="$test_path" "$script" -n "$tmpdir/in/one.md" "$tmpdir/out/dry_run_single.pdf" >"$tmpdir/dry_run_single.out"
  assert_contains "Dry-run:" "$tmpdir/dry_run_single.out"
  assert_file_not_exists "$tmpdir/out/dry_run_single.pdf"

  outdir_dry="$tmpdir/out_dryrun_missing"
  PATH="$test_path" "$script" -n -r -k "$tmpdir/in" "$outdir_dry" >"$tmpdir/dry_run_dir.out"
  assert_contains "Dry-run:" "$tmpdir/dry_run_dir.out"
  [[ ! -d "$outdir_dry" ]] || fail "dry-run unexpectedly created output directory: $outdir_dry"
}

test_toolchain_check() {
  phase "toolchain check"

  PATH="$test_path" "$script" -t >"$tmpdir/toolcheck.out"
  assert_contains "Toolchain:" "$tmpdir/toolcheck.out"
}

test_standalone_enforcement() {
  phase "standalone -t and -h enforcement"

  if PATH="$test_path" "$script" -q -t >/dev/null 2>"$tmpdir/qt.err"; then
    fail "standalone -t check unexpectedly passed"
  fi
  assert_contains "-t must be used by itself." "$tmpdir/qt.err"

  if PATH="$test_path" "$script" -q -h >/dev/null 2>"$tmpdir/qh.err"; then
    fail "standalone -h/--help check unexpectedly passed"
  fi
  assert_contains "-h and --help must be used by themselves." "$tmpdir/qh.err"
}

test_strict_extension_behavior() {
  phase "strict extension behavior"

  if GENPDF_STRICT=1 PATH="$test_path" "$script" "$tmpdir/in/one.v2" "$tmpdir/out/fail.pdf" >/dev/null 2>"$tmpdir/strict.err"; then
    fail "strict mode check unexpectedly passed"
  fi
  assert_contains "strict extension mode requires .md" "$tmpdir/strict.err"

  GENPDF_STRICT=1 PATH="$test_path" "$script" -p "$tmpdir/in/one" "$tmpdir/out/ok" >/dev/null
  assert_file_exists "$tmpdir/out/ok.pdf"
}

test_recursive_filters_and_patterns() {
  phase "recursive include and exclude filters"

  PATH="$test_path" "$script" -r -k -i 'sub/*' -x 'sub/skip.md' "$tmpdir/in" "$tmpdir/out" >/dev/null
  assert_file_exists "$tmpdir/out/sub/two.pdf"
  assert_file_exists "$tmpdir/out/sub/deep/three.pdf"
  assert_file_not_exists "$tmpdir/out/sub/skip.pdf"

  # Literal characters in patterns match themselves.
  mkdir -p "$tmpdir/out_literal"
  PATH="$test_path" "$script" -r -k -i 'sub/readme.md' "$tmpdir/in" "$tmpdir/out_literal" >/dev/null
  assert_file_exists "$tmpdir/out_literal/sub/readme.pdf"
  assert_file_not_exists "$tmpdir/out_literal/sub/two.pdf"

  # With -g, '*' does not cross '/'.
  mkdir -p "$tmpdir/out_segment_glob"
  PATH="$test_path" "$script" -r -k -g -i 'sub/*' "$tmpdir/in" "$tmpdir/out_segment_glob" >/dev/null
  assert_file_exists "$tmpdir/out_segment_glob/sub/two.pdf"
  assert_file_not_exists "$tmpdir/out_segment_glob/sub/deep/three.pdf"

  # With -g, '?' does not match '/'.
  mkdir -p "$tmpdir/out_segment_q"
  PATH="$test_path" "$script" -r -k -g -i 'sub/?wo.md' "$tmpdir/in" "$tmpdir/out_segment_q" >/dev/null
  assert_file_exists "$tmpdir/out_segment_q/sub/two.pdf"
  assert_file_not_exists "$tmpdir/out_segment_q/sub/deep/three.pdf"

  # With -g, '**' crosses '/'.
  mkdir -p "$tmpdir/out_segment_doublestar"
  PATH="$test_path" "$script" -r -k -g -i 'sub/**' "$tmpdir/in" "$tmpdir/out_segment_doublestar" >/dev/null
  assert_file_exists "$tmpdir/out_segment_doublestar/sub/two.pdf"
  assert_file_exists "$tmpdir/out_segment_doublestar/sub/deep/three.pdf"
}

test_quiet_mode_output_behavior() {
  phase "quiet mode output behavior"

  PATH="$test_path" "$script" -q "$tmpdir/in/one.md" "$tmpdir/out/quiet.pdf" >"$tmpdir/quiet.out"
  assert_empty_file "$tmpdir/quiet.out"
  assert_file_exists "$tmpdir/out/quiet.pdf"

  if PATH="$test_path" "$script" -q "$tmpdir/in/missing.md" "$tmpdir/out/missing.pdf" >"$tmpdir/quiet_fail.out" 2>"$tmpdir/quiet_fail.err"; then
    fail "quiet failure path unexpectedly passed"
  fi
  assert_empty_file "$tmpdir/quiet_fail.out"
  assert_contains "input file not found" "$tmpdir/quiet_fail.err"
}

test_details_conversion() {
  phase "details conversion"

  PATH="$test_path" "$script" -c "$tmpdir/in/one.md" "$tmpdir/out/converted.pdf" >/dev/null
  assert_file_exists "$tmpdir/out/converted.pdf"
  assert_file_exists "$tmpdir/out/converted.pdf.src"
  assert_matches '^### Hidden$' "$tmpdir/out/converted.pdf.src"
  assert_matches '^ignore me$' "$tmpdir/out/converted.pdf.src"

  # Default mode must remove summary content, including multiline summary blocks.
  PATH="$test_path" "$script" "$tmpdir/in/multisummary.md" "$tmpdir/out/multisummary_default.pdf" >/dev/null
  assert_file_exists "$tmpdir/out/multisummary_default.pdf.src"
  if grep -Fq "Hidden multiline summary text" "$tmpdir/out/multisummary_default.pdf.src"; then
    fail "default mode should remove multiline summary content"
  fi
  assert_contains "Visible body text" "$tmpdir/out/multisummary_default.pdf.src"

  # Default mode must remove "Why Click to view?" blocks and insert \clearpage before ## headings.
  PATH="$test_path" "$script" "$tmpdir/in/whyclick.md" "$tmpdir/out/whyclick.pdf" >/dev/null
  assert_file_exists "$tmpdir/out/whyclick.pdf.src"
  if grep -Fq "This should be removed." "$tmpdir/out/whyclick.pdf.src"; then
    fail "default mode should remove Why Click to view? content"
  fi
  assert_contains "\\clearpage" "$tmpdir/out/whyclick.pdf.src"
  assert_contains "Section one content." "$tmpdir/out/whyclick.pdf.src"

}

test_toc_bullet_link_rewrite() {
  phase "toc bullet link rewrite"

  PATH="$test_path" "$script" "$tmpdir/in/toc_bullets.md" "$tmpdir/out/toc_bullets.pdf" >/dev/null
  assert_file_exists "$tmpdir/out/toc_bullets.pdf.src"
  assert_contains "\\hyperref[introduction]{\\textcolor{ltlinkblue}{1. Introduction}}" "$tmpdir/out/toc_bullets.pdf.src"
  assert_contains "\\hyperref[subsection]{\\textcolor{ltlinkblue}{\\pageref*{subsection}}}" "$tmpdir/out/toc_bullets.pdf.src"
  if grep -Fq "\\tableofcontents" "$tmpdir/out/toc_bullets.pdf.src"; then
    fail "manual TOC path should not inject \\tableofcontents"
  fi
}

test_collision_detection_without_k() {
  phase "collision detection without -k"

  if PATH="$test_path" "$script" -r "$tmpdir/in" "$tmpdir/out" >/dev/null 2>"$tmpdir/collision.err"; then
    fail "duplicate basename collision check unexpectedly passed"
  fi
  assert_contains "multiple input files map to the same output file" "$tmpdir/collision.err"
  assert_contains "use -k to preserve directory structure" "$tmpdir/collision.err"
}

test_backend_failure_propagation() {
  phase "backend failure propagation"

  if PANDOC_FAIL_CODE=37 PATH="$test_path" "$script" -b pandoc "$tmpdir/in/one.md" "$tmpdir/out/failbackend.pdf" >/dev/null 2>"$tmpdir/backend.err"; then
    fail "backend failure check unexpectedly passed"
  fi
  assert_contains "exit code 37" "$tmpdir/backend.err"
}

test_directory_only_option_guards() {
  phase "directory-only option guards"

  for opt in -g -r -k -i -x; do
    case "$opt" in
      -i|-x)
        if PATH="$test_path" "$script" "$opt" 'sub/*' "$tmpdir/in/one.md" "$tmpdir/out/file_guard.pdf" >/dev/null 2>"$tmpdir/file_guard_${opt#-}.err"; then
          fail "file-mode guard check unexpectedly passed for $opt"
        fi
          assert_contains "-g, -k, -r, -i, and -x are only allowed in directory mode." "$tmpdir/file_guard_${opt#-}.err"
        ;;
      *)
        if PATH="$test_path" "$script" "$opt" "$tmpdir/in/one.md" "$tmpdir/out/file_guard.pdf" >/dev/null 2>"$tmpdir/file_guard_${opt#-}.err"; then
          fail "file-mode guard check unexpectedly passed for $opt"
        fi
        assert_contains "-g, -k, -r, -i, and -x are only allowed in directory mode." "$tmpdir/file_guard_${opt#-}.err"
        ;;
    esac
  done
}

test_no_argument_default_directory_mode() {
  phase "no-argument default directory mode"

  mkdir -p "$tmpdir/noarg"
  cat > "$tmpdir/noarg/noarg.md" <<'EOF'
# No-Arg
EOF
  pushd "$tmpdir/noarg" >/dev/null
  PATH="$test_path" "$script" >/dev/null
  popd >/dev/null
  assert_file_exists "$tmpdir/noarg/noarg.pdf"
}

test_docs_directory_includes_root_readme() {
  phase "docs directory includes root readme"

  mkdir -p "$tmpdir/project/docs/pdf"
  cat > "$tmpdir/project/README.md" <<'EOF'
![LiteTest Logo](docs/branding/LiteTest_Logo_with_LiteTest.png)

Document Version: 9.9.9
Runner Version: 8.8.8
Test Version: 7.7.7

![Second Logo](docs/branding/LiteTest_Logo_with_Tagline.png)

Project Root README
EOF
  cat > "$tmpdir/project/docs/guide.md" <<'EOF'
# Guide
EOF
  cat > "$tmpdir/project/docs/README.md" <<'EOF'
# Docs README
EOF

  pushd "$tmpdir/project" >/dev/null
  PATH="$test_path" "$script" docs docs/pdf >/dev/null
  popd >/dev/null

  assert_file_exists "$tmpdir/project/docs/pdf/guide.pdf"
  assert_file_exists "$tmpdir/project/docs/pdf/LiteTest.pdf"
  assert_file_not_exists "$tmpdir/project/docs/pdf/README.pdf"
  assert_file_not_exists "$tmpdir/project/docs/pdf/LiteTest_README.pdf"
  if ! perl -0777 -ne 'exit 0 if /```\{=latex\}\n\\vspace\*\{\\baselineskip\}\n\\vspace\*\{\\baselineskip\}\n\\noindent\\includegraphics\[width=\\textwidth\]\{\\detokenize\{docs\/branding\/LiteTest_Logo_with_LiteTest\.png\}\}\n```\n```\{=latex\}\n\\vspace\{\\baselineskip\}\n\\vspace\{\\baselineskip\}\n\\noindent Document Version: 9\.9\.9\\\\\n\\noindent Runner Version: 8\.8\.8\\\\\n\\noindent Test Version: 7\.7\.7\\\\\n\\vspace\{\\baselineskip\}\n\\vspace\{\\baselineskip\}\n```/s; exit 1' "$tmpdir/project/docs/pdf/LiteTest.pdf.src"; then
    fail "expected first-line PNG to be emitted as raw LaTeX with 2 forced pre-image blank lines (vspace*), 2 blank lines before version lines, and 2 blank lines after version lines in $tmpdir/project/docs/pdf/LiteTest.pdf.src"
  fi
  if ! grep -Fq -- "![Second Logo](docs/branding/LiteTest_Logo_with_Tagline.png)" "$tmpdir/project/docs/pdf/LiteTest.pdf.src"; then
    fail "expected non-first PNG reference to pass through unchanged in $tmpdir/project/docs/pdf/LiteTest.pdf.src"
  fi
  if grep -Fq -- "Figure 1:" "$tmpdir/project/docs/pdf/LiteTest.pdf.src"; then
    fail "did not expect figure-caption text in generated markdown source: $tmpdir/project/docs/pdf/LiteTest.pdf.src"
  fi
  if perl -0777 -ne 'exit 0 if /<br>\n<br>\n<br>\n!\[Second Logo\]\(docs\/branding\/LiteTest_Logo_with_Tagline\.png\)/s; exit 1' "$tmpdir/project/docs/pdf/LiteTest.pdf.src"; then
    fail "did not expect 3 rendered blank lines before non-first PNG in $tmpdir/project/docs/pdf/LiteTest.pdf.src"
  fi
}

test_first_png_not_on_line_one_no_special_handling() {
  phase "first PNG not on line one has no special handling"

  mkdir -p "$tmpdir/noline1"
  cat > "$tmpdir/noline1/notline1.md" <<'EOF'
# Not Line 1
![LiteTest Logo](docs/branding/LiteTest_Logo_with_LiteTest.png)

Document Version: 3.2.1
Runner Version: 2.1.0
Test Version: 1.0.9
EOF

  PATH="$test_path" "$script" "$tmpdir/noline1/notline1.md" "$tmpdir/out/notline1.pdf" >/dev/null

  assert_file_exists "$tmpdir/out/notline1.pdf.src"
  assert_contains "![LiteTest Logo](docs/branding/LiteTest_Logo_with_LiteTest.png)" "$tmpdir/out/notline1.pdf.src"
  if grep -Fq -- "\\includegraphics[width=0.55\\textwidth]" "$tmpdir/out/notline1.pdf.src"; then
    fail "did not expect raw LaTeX includegraphics title-page handling when first line is not PNG"
  fi
  if grep -Fq -- "\\noindent Document Version: 3.2.1\\" "$tmpdir/out/notline1.pdf.src"; then
    fail "did not expect injected version lines when first line is not PNG"
  fi
  assert_contains "Document Version: 3.2.1" "$tmpdir/out/notline1.pdf.src"
  assert_contains "Runner Version: 2.1.0" "$tmpdir/out/notline1.pdf.src"
  assert_contains "Test Version: 1.0.9" "$tmpdir/out/notline1.pdf.src"
}

run_all_tests() {
  test_help_and_usage
  test_toolchain_check
  test_backend_option_behavior
  test_dry_run_behavior
  test_standalone_enforcement
  test_strict_extension_behavior
  test_recursive_filters_and_patterns
  test_quiet_mode_output_behavior
  test_details_conversion
  test_toc_bullet_link_rewrite
  test_collision_detection_without_k
  test_backend_failure_propagation
  test_directory_only_option_guards
  test_no_argument_default_directory_mode
  test_docs_directory_includes_root_readme
  test_first_png_not_on_line_one_no_special_handling
}

run_all_tests

echo "genpdf test suite passed"
