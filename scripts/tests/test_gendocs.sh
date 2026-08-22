#!/usr/bin/env bash

# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see ./LICENSE.

set -euo pipefail
export LC_ALL=C

usage() {
  cat <<'EOF'
Usage:
  test_gendocs.sh
  test_gendocs.sh -v
  test_gendocs.sh {-h | --help}

Runs a test suite for scripts/bin/gendocs and its helper scripts
scripts/helpers/genpdf.sh and scripts/helpers/gendocx.sh.

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

assert_line_count() {
  local expected=$1
  local regex=$2
  local file=$3
  local actual
  actual=$(grep -Ec -- "$regex" "$file" || true)
  [[ "$actual" -eq "$expected" ]] || fail "expected $expected matches for "\
    "'$regex' in $file, found $actual"
}

run_capture() {
  local outfile=$1
  shift
  set +e
  "$@" >"$outfile" 2>&1
  local rc=$?
  set -e
  echo "$rc"
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

for dep in bash cmp cp diff grep mktemp python3 sed; do
  command -v "$dep" >/dev/null 2>&1 || fail "missing required command: $dep"
done

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
gendocs_script="$repo_root/scripts/bin/gendocs"
genpdf_helper="$repo_root/scripts/helpers/genpdf.sh"
gendocx_helper="$repo_root/scripts/helpers/gendocx.sh"
common_helper="$repo_root/scripts/helpers/common.sh"
git_helper="$repo_root/scripts/helpers/git_helpers.sh"

for script in "$gendocs_script" "$genpdf_helper" "$gendocx_helper"; do
  [[ -f "$script" ]] || fail "missing required script: $script"
done

tmpdir=$(mktemp -d)
cleanup() {
  rm -rf "$tmpdir"
}

commit_fixture_changes() {
  local repo=$1
  local status
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "update gendocs fixture"
  status="$(git -C "$repo" status --porcelain --untracked-files=all)"
  [[ -z "$status" ]] || fail "gendocs fixture is dirty after commit: $status"
}
trap cleanup EXIT

make_gendocs_repo() {
  local name=$1
  local repo="$tmpdir/$name"

  mkdir -p "$repo/scripts/bin" "$repo/scripts/helpers" \
    "$repo/docs/md" "$repo/docs/pdf" "$repo/docs/docx" "$repo/logs"
  cp "$gendocs_script" "$repo/scripts/bin/gendocs"

  cat > "$repo/scripts/helpers/genpdf.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
log_file="$repo_root/logs/helpers.log"
dry_run=0
tool_check=0
backend=auto
declare -a positional=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t)
      tool_check=1
      ;;
    -n)
      dry_run=1
      ;;
    -b|-i|-x)
      shift
      [[ $# -gt 0 ]] || exit 2
      if [[ "$1" == *failpdf* ]]; then
        exit 37
      fi
      ;;
    -e)
      shift
      [[ $# -gt 0 ]] || exit 2
      ;;
    -q|-v|-r|-k|-g|-c)
      ;;
    -*)
      exit 2
      ;;
    *)
      positional+=("$1")
      ;;
  esac
  shift
done

if [[ $tool_check -eq 1 ]]; then
  echo "stub-genpdf: available"
  exit 0
fi

in=${positional[0]:-}
out=${positional[1]:-}
[[ -n "$in" && -n "$out" ]] || exit 2

if [[ $dry_run -eq 1 ]]; then
  echo "Dry-run: $in -> $out"
  exit 0
fi

mkdir -p "$(dirname "$out")"
cp "$in" "${out}.src"
touch "$out"
printf 'genpdf %s -> %s\n' "$in" "$out" >> "$log_file"
EOF

  cat > "$repo/scripts/helpers/gendocx.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
log_file="$repo_root/logs/helpers.log"
dry_run=0
tool_check=0
declare -a positional=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t)
      tool_check=1
      ;;
    -n)
      dry_run=1
      ;;
    -b|-i|-x)
      shift
      [[ $# -gt 0 ]] || exit 2
      ;;
    -q|-v|-r|-k|-g)
      ;;
    -*)
      exit 2
      ;;
    *)
      positional+=("$1")
      ;;
  esac
  shift
done

if [[ $tool_check -eq 1 ]]; then
  echo "stub-gendocx: available"
  exit 0
fi

in=${positional[0]:-}
out=${positional[1]:-}
[[ -n "$in" && -n "$out" ]] || exit 2

if [[ $dry_run -eq 1 ]]; then
  echo "Dry-run: $in -> $out"
  exit 0
fi

mkdir -p "$(dirname "$out")"
printf 'docx generated from %s\n' "$in" > "$out"
printf 'gendocx %s -> %s\n' "$in" "$out" >> "$log_file"
EOF

  chmod +x "$repo/scripts/bin/gendocs" \
    "$repo/scripts/helpers/genpdf.sh" \
    "$repo/scripts/helpers/gendocx.sh"
  cp "$common_helper" "$repo/scripts/helpers/common.sh"
  cp "$git_helper" "$repo/scripts/helpers/git_helpers.sh"
  mkdir -p "$repo/config"
  printf '%s\n' '- testuser, C, test@example.com' > \
    "$repo/config/contributors.md"
  git -C "$repo" init -q
  git -C "$repo" config user.name testuser
  git -C "$repo" config user.email test@example.com
  git -C "$repo" branch -M main
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "seed gendocs fixture"
  git -C "$repo" checkout -q -b dev/gendocs-tests-v1.0.0
  printf '%s\n' "$repo"
}

make_genpdf_helper_repo() {
  local name=$1
  local repo="$tmpdir/$name"

  mkdir -p "$repo/scripts/helpers" "$repo/docs/branding" \
    "$repo/in/docs/branding" "$repo/in" "$repo/out" "$repo/bin"
  cp "$genpdf_helper" "$repo/scripts/helpers/genpdf.sh"

  python3 - <<'PY' "$repo/docs/branding/Logo_with_BrandName.png" \
    "$repo/in/docs/branding/Logo_with_BrandName.png"
import base64
import sys

png = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/"
    "x8AAwMCAO+X2n8AAAAASUVORK5CYII="
)
for path in sys.argv[1:]:
    with open(path, "wb") as f:
        f.write(png)
PY

  cat > "$repo/bin/pandoc" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

out=''
in=''

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o)
      out=$2
      shift 2
      ;;
    --output=*)
      out=${1#*=}
      shift
      ;;
    -*)
      shift
      ;;
    *)
      in=$1
      shift
      ;;
  esac
done

[[ -n "$out" ]] || exit 2
mkdir -p "$(dirname "$out")"
if [[ -n "$in" && -f "$in" ]]; then
  cp "$in" "$out"
else
  : > "$out"
fi
EOF

  chmod +x "$repo/scripts/helpers/genpdf.sh" "$repo/bin/pandoc"
  printf '%s\n' "$repo"
}

make_gendocx_helper_repo() {
  local name=$1
  local repo="$tmpdir/$name"

  mkdir -p "$repo/scripts/helpers" "$repo/bin" "$repo/in" "$repo/out"
  cp "$gendocx_helper" "$repo/scripts/helpers/gendocx.sh"

  cat > "$repo/bin/libreoffice" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

outdir=''
infile=''

while [[ $# -gt 0 ]]; do
  case "$1" in
    --outdir)
      outdir=$2
      shift 2
      ;;
    --headless|--convert-to)
      shift
      [[ $# -gt 0 && "$1" != --outdir ]] && shift
      ;;
    *)
      infile=$1
      shift
      ;;
  esac
done

[[ -n "$outdir" && -n "$infile" ]] || exit 1
mkdir -p "$outdir"
printf 'docx from %s\n' "$infile" > "$outdir/$(basename "${infile%.*}").docx"
EOF

  chmod +x "$repo/scripts/helpers/gendocx.sh" "$repo/bin/libreoffice"
  printf '%s\n' "$repo"
}

test_help_and_usage() {
  phase "harness help and usage"

  bash "$0" -h > "$tmpdir/harness_help.out"
  assert_contains "Usage:" "$tmpdir/harness_help.out"
  assert_contains "test_gendocs.sh" "$tmpdir/harness_help.out"
}

test_gendocs_help() {
  phase "gendocs help"

  local repo
  repo=$(make_gendocs_repo repo_help)

  bash "$repo/scripts/bin/gendocs" -h > "$tmpdir/gendocs_help.out"
  assert_matches '^Simple Usage:$' "$tmpdir/gendocs_help.out"
  assert_contains "gendocs [-b <backend>] -T" "$tmpdir/gendocs_help.out"
  assert_contains "-n  Dry-run" "$tmpdir/gendocs_help.out"
  assert_contains "-d  Output only .docx files" "$tmpdir/gendocs_help.out"
  assert_contains "-x  Exclude files matching" "$tmpdir/gendocs_help.out"
}

test_gendocs_default_pipeline() {
  phase "gendocs default pipeline"

  local repo
  repo=$(make_gendocs_repo repo_default)

  cat > "$repo/docs/md/alpha.md" <<'EOF'
# Alpha
EOF
  cat > "$repo/docs/md/README.md" <<'EOF'
# Ignore Me
EOF

  commit_fixture_changes "$repo"

  bash "$repo/scripts/bin/gendocs" > "$tmpdir/gendocs_default.out"

  assert_file_exists "$repo/docs/pdf/alpha.pdf"
  assert_file_exists "$repo/docs/pdf/alpha.pdf.src"
  assert_file_exists "$repo/docs/docx/alpha.docx"
  assert_file_not_exists "$repo/docs/pdf/README.pdf"
  assert_contains "Generated PDF and DOCX files." "$tmpdir/gendocs_default.out"
  assert_contains "alpha.md" "$repo/docs/md/.md_metadata"
  assert_contains \
    "genpdf $repo/docs/md/alpha.md -> $repo/docs/pdf/alpha.pdf" \
    "$repo/logs/helpers.log"
}

test_gendocs_pdf_only_dry_run() {
  phase "gendocs PDF-only dry run"

  local repo
  repo=$(make_gendocs_repo repo_pdf_dry_run)

  cat > "$repo/docs/md/alpha.md" <<'EOF'
# Alpha
EOF

  commit_fixture_changes "$repo"

  bash "$repo/scripts/bin/gendocs" -n -p > \
    "$tmpdir/gendocs_pdf_dry_run.out"

  assert_contains "Dry-run: $repo/docs/md/alpha.md" \
    "$tmpdir/gendocs_pdf_dry_run.out"
  assert_contains "Planned PDF generation." \
    "$tmpdir/gendocs_pdf_dry_run.out"
  assert_file_not_exists "$repo/docs/pdf/alpha.pdf"
  assert_file_not_exists "$repo/docs/md/.md_metadata"
  assert_file_not_exists "$repo/logs/helpers.log"
}

test_gendocs_toolcheck() {
  phase "gendocs toolcheck"

  local repo
  repo=$(make_gendocs_repo repo_toolcheck)

  bash "$repo/scripts/bin/gendocs" -T > "$tmpdir/gendocs_toolcheck.out"
  assert_contains "stub-genpdf: available" "$tmpdir/gendocs_toolcheck.out"
  assert_contains "stub-gendocx: available" "$tmpdir/gendocs_toolcheck.out"
  assert_contains "STATUS[0]: success" "$tmpdir/gendocs_toolcheck.out"
}

test_gendocs_docx_only_pdf_source() {
  phase "gendocs docx-only from pdf source"

  local repo
  repo=$(make_gendocs_repo repo_docx_only)

  printf 'pdf bytes\n' > "$repo/docs/pdf/existing.pdf"
  commit_fixture_changes "$repo"

  bash "$repo/scripts/bin/gendocs" -d \
    "$repo/docs/pdf/existing.pdf" "$repo/custom-docx" \
    > "$tmpdir/gendocs_docx_only.out"

  assert_file_exists "$repo/custom-docx/existing.docx"
  assert_contains \
    "gendocx $repo/docs/pdf/existing.pdf -> $repo/custom-docx/existing.docx" \
    "$repo/logs/helpers.log"
  if grep -Fq "genpdf" "$repo/logs/helpers.log"; then
    fail \
      "did not expect genpdf helper to be used for direct pdf -> "
      "docx conversion"
  fi
}

test_gendocs_docx_target_collision() {
  phase "gendocs rejects duplicate DOCX targets"

  local repo rc
  repo=$(make_gendocs_repo repo_docx_collision)
  printf '# Markdown source\n' > "$repo/docs/md/same.md"
  printf 'pdf source\n' > "$repo/docs/md/same.pdf"
  commit_fixture_changes "$repo"

  rc=$(run_capture "$tmpdir/gendocs_docx_collision.out" \
    bash "$repo/scripts/bin/gendocs" -d "$repo/docs/md")
  [[ "$rc" -eq 1 ]] || fail "expected DOCX collision exit 1, got $rc"
  assert_contains "map to the same DOCX output" \
    "$tmpdir/gendocs_docx_collision.out"
  assert_file_not_exists "$repo/docs/docx/same.docx"
}

test_gendocs_prerequisites() {
  phase "gendocs conversion prerequisites"

  local repo rc
  repo=$(make_gendocs_repo repo_prerequisites)
  printf '# Alpha\n' > "$repo/docs/md/alpha.md"
  commit_fixture_changes "$repo"

  git -C "$repo" config user.name unknown
  git -C "$repo" config user.email unknown@example.com
  rc=$(run_capture "$tmpdir/gendocs_role.out" \
    bash "$repo/scripts/bin/gendocs" -n)
  [[ "$rc" -eq 4 ]] || fail "expected unauthorized exit 4, got $rc"

  git -C "$repo" config user.name testuser
  git -C "$repo" config user.email test@example.com
  git -C "$repo" checkout -q main
  rc=$(run_capture "$tmpdir/gendocs_branch.out" \
    bash "$repo/scripts/bin/gendocs" -n)
  [[ "$rc" -eq 6 ]] || fail "expected branch-policy exit 6, got $rc"

  git -C "$repo" checkout -q dev/gendocs-tests-v1.0.0
  printf 'dirty\n' >> "$repo/docs/md/alpha.md"
  rc=$(run_capture "$tmpdir/gendocs_dirty.out" \
    bash "$repo/scripts/bin/gendocs" -n)
  [[ "$rc" -eq 7 ]] || fail "expected dirty-worktree exit 7, got $rc"
}

test_gendocs_missing_helper() {
  phase "gendocs missing helper"

  local repo rc
  repo=$(make_gendocs_repo repo_missing_helper)
  rm -f "$repo/scripts/helpers/gendocx.sh"

  rc=$(run_capture "$tmpdir/gendocs_missing_helper.out" \
    bash "$repo/scripts/bin/gendocs")
  [[ "$rc" -eq 100 ]] || fail "expected missing-helper exit 100, got $rc"
  assert_contains "Missing helper script" "$tmpdir/gendocs_missing_helper.out"
}

test_gendocs_genpdf_helper_reorders_first_png() {
  phase "genpdf helper reorders first png"

  local repo input output emitted
  repo=$(make_genpdf_helper_repo repo_genpdf_reorder)
  input="$repo/in/reorder.md"
  output="$repo/out/reorder.pdf"
  emitted="$repo/out/reorder.transformed.md"

  cat > "$input" <<'EOF'
# Title
![BriteTest Logo](docs/branding/Logo_with_BrandName.png)

Body line.
EOF

  PATH="$repo/bin:$PATH" bash "$repo/scripts/helpers/genpdf.sh" -e \
    "$emitted" "$input" "$output"

  assert_file_exists "$output"
  assert_file_exists "$emitted"
  assert_line_count 1 \
    'includegraphics\[width=\\textwidth\]\{\\detokenize\{[^}]*Logo_with_BrandName\.png\}\}' \
    "$emitted"
  assert_contains "# Title" "$emitted"
  assert_contains "Body line." "$emitted"
  if grep -Fq '![BriteTest Logo](' "$emitted"; then
    fail "expected transformed markdown to replace markdown logo \
image with LaTeX includegraphics"
  fi
}

test_gendocs_genpdf_helper_passthrough_when_png_is_first_line() {
  phase "genpdf helper passthrough when png is first line"

  local repo input output emitted
  repo=$(make_genpdf_helper_repo repo_genpdf_passthrough)
  input="$repo/in/passthrough.md"
  output="$repo/out/passthrough.pdf"
  emitted="$repo/out/passthrough.transformed.md"

  cat > "$input" <<'EOF'
![BriteTest Logo](docs/branding/Logo_with_BrandName.png)

# Title
Body line.
EOF

  PATH="$repo/bin:$PATH" bash "$repo/scripts/helpers/genpdf.sh" -e \
    "$emitted" "$input" "$output"

  assert_file_exists "$emitted"
  assert_line_count 1 \
    'includegraphics\[width=\\textwidth\]\{\\detokenize\{[^}]*Logo_with_BrandName\.png\}\}' \
    "$emitted"
  assert_contains "# Title" "$emitted"
  assert_contains "Body line." "$emitted"
  if grep -Fq '![BriteTest Logo](' "$emitted"; then
    fail "expected transformed markdown to replace markdown logo \
image with LaTeX includegraphics"
  fi
}

test_gendocx_helper_invalid_backend() {
  phase "gendocx helper invalid backend"

  local repo rc
  repo=$(make_gendocx_helper_repo repo_gendocx_invalid)
  printf 'pdf\n' > "$repo/in/input.pdf"

  rc=$(run_capture "$tmpdir/gendocx_invalid.out" bash \
    "$repo/scripts/helpers/gendocx.sh" -b invalid \
    "$repo/in/input.pdf" "$repo/out/out.docx")
  [[ "$rc" -eq 2 ]] || fail "expected invalid-backend exit 2, got $rc"
  assert_contains "Error: invalid backend 'invalid' (expected: auto|python|libreoffice)" "$tmpdir/gendocx_invalid.out"
}

test_gendocx_helper_libreoffice_backend() {
  phase "gendocx helper libreoffice backend"

  local repo
  repo=$(make_gendocx_helper_repo repo_gendocx_libreoffice)
  printf 'pdf\n' > "$repo/in/input.pdf"

  PATH="$repo/bin:$PATH" bash "$repo/scripts/helpers/gendocx.sh" -b \
    libreoffice "$repo/in/input.pdf" "$repo/out/output.docx" > \
    "$tmpdir/gendocx_libreoffice.out"

  assert_file_exists "$repo/out/output.docx"
  assert_contains "$repo/in/input.pdf -> $repo/out/output.docx" \
    "$tmpdir/gendocx_libreoffice.out"
}

run_all_tests() {
  test_help_and_usage
  test_gendocs_help
  test_gendocs_default_pipeline
  test_gendocs_pdf_only_dry_run
  test_gendocs_toolcheck
  test_gendocs_docx_only_pdf_source
  test_gendocs_docx_target_collision
  test_gendocs_prerequisites
  test_gendocs_missing_helper
  test_gendocs_genpdf_helper_reorders_first_png
  test_gendocs_genpdf_helper_passthrough_when_png_is_first_line
  test_gendocx_helper_invalid_backend
  test_gendocx_helper_libreoffice_backend
}

run_all_tests

echo "gendocs test suite passed"