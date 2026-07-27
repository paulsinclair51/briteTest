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

- **test_<script>.sh**: Test for `<repo>/scripts/bin/<script>`.

- **test_<script>_<function>.sh**: Test `<function>` for
  `<repo>/scripts/bin/<script>`.

- **test_<script>_lib.sh**: Test library for
  `<repo>/scripts/bin/<script>`.

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
# Run one script-level suite
bash ./scripts/tests/test_<script>.sh

# Run one split sub-suite (when a script has split tests)
bash ./scripts/tests/test_<script>_<function>.sh

# Run all suites in this directory
bash ./scripts/tests/test_scripts.sh
```
