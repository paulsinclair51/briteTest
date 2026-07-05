# /reports/

Directory containing generated report files.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `/LICENSE`.

See `/README.md` for an introduction to briteTest.

## Files

- **docs-<datetime>.md**: Validation report from `scripts/bin/ckdocs`,
	where `<datetime>` has the form `YYYYMMDD-HHMMSS`.

- **versions-<datetime>.md**: Validation report from `scripts/bin/ckversions`,
	where `<datetime>` has the form `YYYYMMDD-HHMMSS`.

- **directory_guides-<datetime>.md**: Validation report from
	`scripts/bin/ckdirectory_guides`, where `<datetime>` has the form
	`YYYYMMDD-HHMMSS`.

- **branch_status.md**: Latest status report from `scripts/bin/ckbranch`.

- **updatebrand-<datetime>.md**: Report from `scripts/bin/updatebrand`,
	where `<datetime>` has the form `YYYYMMDD-HHMMSS`.

- **updatebrand-dry-run-<datetime>.md**: Dry-run report from `scripts/bin/updatebrand`.
	Old dry-run reports are deleted on a successful non-dry-run.

- **test_report-I.txt**: Report file for an injected test run.

- **test_report.txt**: Report file for a test run without the `-I` option.

- **README.md**: This directory guide.

## Subdirectories

- None.
