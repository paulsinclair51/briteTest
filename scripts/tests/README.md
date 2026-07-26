# `<repo>/scripts/tests/`

Directory containing script tests.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `<repo>/LICENSE`.

See `<repo>/README.md` for an introduction to briteTest.

This directory stores tests for the user-facing commands in `<repo>/scripts/bin/`.
These tests are intended to quickly verify key CLI behavior, exit codes,
and high-signal output contracts.

## Files

- **test_fixlocal.sh**: Smoke tests for `<repo>/scripts/bin/fixlocal`
  covering help output, verified cleanup, report summaries, and briteTest
  layout skip behavior.

- **test_fixremote.sh**: Smoke tests for `<repo>/scripts/bin/fixremote`
  covering help output, authorization and argument validation, preflight
  behavior, guarded recovery execution checks, and parity verification.

- **test_gendocs.sh**: Validation tests for `<repo>/scripts/bin/gendocs`
  and its helper scripts `<repo>/scripts/helpers/genpdf.sh` and
  `<repo>/scripts/helpers/gendocx.sh`.

- **test_lsbranch.sh**: Smoke tests for `<repo>/scripts/bin/lsbranch` covering
  help output, local/remote inclusion flags, report marker formatting,
  remote branch visibility, and pattern matching behavior.
  
- **test_mkbranch.sh**: Smoke tests for `<repo>/scripts/bin/mkbranch` covering
  help output, mode-specific parent checks, split exit codes, and graceful
  failures for missing helper/remote interfaces.

- **test_mrgdown.sh**: Smoke tests for `<repo>/scripts/bin/mrgdown` covering
  help output, protected-branch gate behavior, merge report generation,
  read-only report enforcement, and remote report copy semantics.

- **test_commit.sh**: Smoke tests for `<repo>/scripts/bin/commit` covering
  help output, role validation, message validation, dry-run reporting, and
  disconnected-remote push handling.
  Included automatically by `test_scripts.sh`.

- **test_report_helpers.sh**: Focused tests for
  `<repo>/scripts/helpers/report_helpers.sh` covering exact deleted-report
  tracking, read-only enforcement, exact staged-path persistence, and
  local-only fallback when push is unavailable.
  Included automatically by `test_scripts.sh`.

- **test_ckstyle.sh**: Smoke tests for `<repo>/scripts/bin/ckstyle` covering
  help output, clean-report generation, verbose diagnostics, long-option
  rejection, and report I/O failure handling.
  Included automatically by `test_scripts.sh`.

- **test_rmbranch.sh**: Smoke tests for `<repo>/scripts/bin/rmbranch` covering
  non-conforming branch deletion support, non-fatal history propagation,
  and actionable fetch/remote-delete error diagnostics.
  Included automatically by `test_scripts.sh`.

- **test_genpngs.sh**: Smoke tests for `<repo>/scripts/bin/genpngs` covering
  document-derived PNG generation and second-pass repeatability (must report
  0 new and 0 changed PNG files).
  Included automatically by `test_scripts.sh`.

- **test_scripts.sh**: Script-test orchestrator that runs all `test_*.sh`
  scripts in this directory (except itself), with stop-on-failure and
  continue-on-failure modes.

- **README.md**: This directory guide.

## Subdirectories

None.

## Running Tests

From repository root:

```sh
make test-lsbranch
make test-gendocs
make test-fixlocal
make test-fixremote
make test-mkbranch
make test-mrgdown
make test-report-helpers
make test-ckstyle
make test-genpngs
make test-all-scripts
```

Or run directly:

```sh
bash ./scripts/tests/test_lsbranch.sh
bash ./scripts/tests/test_gendocs.sh
bash ./scripts/tests/test_fixlocal.sh
bash ./scripts/tests/test_fixremote.sh
bash ./scripts/tests/test_mkbranch.sh
bash ./scripts/tests/test_mrgdown.sh
bash ./scripts/tests/test_commit.sh
bash ./scripts/tests/test_report_helpers.sh
bash ./scripts/tests/test_ckstyle.sh
bash ./scripts/tests/test_rmbranch.sh
bash ./scripts/tests/test_genpngs.sh
bash ./scripts/tests/test_scripts.sh
```
