# `<repo>/scripts/tests/`

Directory containing script tests.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `<repo>/LICENSE`.

See `<repo>/README.md` for an introduction to briteTest.

This directory stores tests for user-facing commands in `<repo>/scripts/bin/`.
These tests are intended to quickly verify key CLI behavior, exit codes,
and high-signal output contracts.

## Files

- **test_ckbranch.sh**: Smoke tests for `<repo>/scripts/bin/ckbranch` covering
  help output, local/remote inclusion flags, report marker formatting,
  remote-only branch visibility, and pattern matching behavior.
  
- **test_gendocs.sh**: Validation tests for `<repo>/scripts/bin/gendocs` and its
  helper scripts `<repo>/scripts/helpers/genpdf.sh` and `<repo>/scripts/helpers/gendocx.sh`.

- **test_lsbranch.sh**: Smoke tests for `<repo>/obsolete/lsbranch` covering
  help output, local/remote listing, invalid-only behavior, and selected
  error paths.

- **README.md**: This directory guide.

## Subdirectories

- None.

## Running Tests

From repository root:

```sh
make test-lsbranch
make test-gendocs
make test-ckbranch
```

Or run directly:

```sh
bash ./scripts/tests/test_lsbranch.sh
bash ./scripts/tests/test_gendocs.sh
bash ./scripts/tests/test_ckbranch.sh
```
