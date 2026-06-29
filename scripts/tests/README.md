# scripts/tests/

Directory containing script smoke tests.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `LICENSE` in the root directory.

## Purpose

This directory stores lightweight smoke tests for scripts in `scripts/`.
These tests are intended to quickly verify key CLI behavior, exit codes,
and high-signal output contracts.

## Files

- **test_lsbranch.sh**: Smoke tests for `scripts/lsbranch` covering help output,
  local/remote listing, invalid-only behavior, and selected error paths.

- **test_genpdf.sh**: Validation tests for the `scripts/genpdf` workflow.

## Subdirectories

- None.

## Running Tests

From repository root:

```sh
make test-lsbranch
make test-genpdf
```

Or run directly:

```sh
bash ./scripts/tests/test_lsbranch.sh
bash ./scripts/tests/test_genpdf.sh
```
