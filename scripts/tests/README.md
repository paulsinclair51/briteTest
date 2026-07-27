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

- **test_fixlocal.sh**: Orchestrator for split `fixlocal` smoke tests.

- **test_fixlocal_core.sh**: Core smoke tests for `<repo>/scripts/bin/fixlocal`
  covering help output, verified cleanup, report summaries, layout skip
  behavior, argument/authorization handling, and dependency/report-path
  hard-failure handling.

- **test_fixlocal_remote.sh**: Remote-state smoke tests for
  `<repo>/scripts/bin/fixlocal` covering unreachable origin,
  remote-tracking refresh failure classification, and timeout
  classification exit codes.

- **test_fixlocal_retention.sh**: Report-retention smoke tests for
  `<repo>/scripts/bin/fixlocal` covering dry-run and non-dry retention
  deletion behavior.

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

- **test_commit.sh**: Orchestrator for split `commit` smoke tests.

- **test_commit_core.sh**: Core smoke tests for `<repo>/scripts/bin/commit`
  covering help output, role and argument validation, message validation,
  and dry-run reporting.

- **test_commit_history.sh**: History/push semantics smoke tests for
  `<repo>/scripts/bin/commit` covering divergence auto-resolution,
  selected-for-push labeling, and local-only branch behavior.

- **test_commit_reports.sh**: Report-retention and permissions smoke tests for
  `<repo>/scripts/bin/commit` covering stale report cleanup and read-only
  report enforcement.

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
  continue-on-failure modes. When split `fixlocal` test files are present,
  it skips `test_fixlocal.sh` to avoid duplicate execution. Likewise, when
  split `commit` test files are present, it skips `test_commit.sh`.

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
bash ./scripts/tests/test_fixlocal_core.sh
bash ./scripts/tests/test_fixlocal_remote.sh
bash ./scripts/tests/test_fixlocal_retention.sh
bash ./scripts/tests/test_fixremote.sh
bash ./scripts/tests/test_mkbranch.sh
bash ./scripts/tests/test_mrgdown.sh
bash ./scripts/tests/test_commit.sh
bash ./scripts/tests/test_commit_core.sh
bash ./scripts/tests/test_commit_history.sh
bash ./scripts/tests/test_commit_reports.sh
bash ./scripts/tests/test_report_helpers.sh
bash ./scripts/tests/test_ckstyle.sh
bash ./scripts/tests/test_rmbranch.sh
bash ./scripts/tests/test_genpngs.sh
bash ./scripts/tests/test_scripts.sh
```
