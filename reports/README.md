# `<repo>/reports/`
Directory containing report files.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `<repo>/LICENSE`.

See `<repo>/README.md` for an introduction to briteTest.

`<datetiem>` has the form `YYYYMMDD-HHMMSS`. Old reports are deleted when a
new report is successfully generated. Reports are not tracked by GitHub.

## Files

- **style-<datetime>.md**: Validation report from `<repo>/scripts/bin/ckstyle`.

- **branch-\<datetime\>.md**: Status report from `<repo>/scripts/bin/ckbranch`.

- **branch-history-<datetime>.md**: Report from `<repo>/scripts/bin/ckbranch_history`.

- **repository-<datetime>.md**: Report from `<repo>/scripts/bin/fixrepository`.

- **updatebrand[-dry-run]-<datetime>.md**: Report from `<repo>/scripts/bin/updatebrand`.

- **test_report.txt-<datetime>**: Report file for a test run without the `-I` option.

- **README.md**: This directory guide.

## Subdirectories

- None.
