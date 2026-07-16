# `<repo>/reports/`

Directory containing script-generated report files.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `<repo>/LICENSE`.

See `<repo>/README.md` for an introduction to briteTest.

`<datetime>` has the form `YYYYMMDD-HHMMSS`. Older reports may be removed by
the generating script after successful report creation. Reports are not tracked
by Git.

## Layout

- **branch/**: Branch/workflow and sync reports.
	- `branch-<datetime>.md` from `<repo>/scripts/bin/lsbranch`
	- `commit[-d]-<datetime>.md` from `<repo>/scripts/bin/commit`
	- `syncfromremote[-d]-<datetime>.md` from `<repo>/scripts/bin/syncfromremote`

- **repository/**: Repository/fork/clone lifecycle reports.
	- `repository-<datetime>.md` from `<repo>/scripts/bin/fixrepo`
	- Reserved for future `mkclone`, `rmclone`, `mkfork` report outputs

- **guidelines/**: Style, wording, and guideline-conformance reports.
	- `ckstyle-<datetime>.md` from `<repo>/scripts/bin/ckstyle`
	- `rebrand[-dry-run]-<datetime>.md` from `<repo>/scripts/bin/rebrand`
	- Reserved for future guideline report outputs (for example,
	  `replacetext` if report generation is added)

- **(root-level files)**: General or legacy report files.
	- legacy historical report files generated before subdirectory migration
	- user-directed ad hoc outputs (for example `lsbranchlog -o <file>`)

## Files

- **README.md**: This directory guide.

## Subdirectories

- **branch/**: Branch-related reports.
- **repository/**: Repository/clone-related reports.
- **guidelines/**: Guideline and style-related reports.
