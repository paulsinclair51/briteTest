# `<repo>/reports/`

Directory containing script-generated report files.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `<repo>/LICENSE`.

See `<repo>/README.md` for an introduction to briteTest.

## Files

**<workflow>-d-<datetime>.md**: Latest untracked dry-run report from `pull`, `mrgup`,
`mrgdown`, or `copyfix`.

**<workflow>-e-<datetime>.md**: Latest untracked error report from `pull`, `mrgup`,
`mrgdown`, or `copyfix`.

**local-<datetime>.md**: Latest untracked activity report for a local branch from
`<repo>/scripts/bin/report`.
qe
**rebrand-<datetime>-<id>.md**: Latest untracked brand update report.

**recovery-<datetime>-<id>.md**: Latest untracked remote recovery report.

**remote-<datetime>.md**: Latest untracked activity report for a remote branch
from `<repo>/scripts/bin/report`.

**repo-<datetime>.md**: Latest untracked repository health and branch status report from
`<repo>/scripts/bin/report`.

**repository-<datetime>-<id>.md**: Repository diagnostic report.

**release-d-<datetime>.md**: Latest release dry-run report.

**release-e-<datetime>.md**: Latest release error-run report.

**retarget-e-<datetime>.md**: Latest retarget error-run report.

**style-<datetime>.md**: Latest untracked style report from
`<repo>/scripts/bin/report`.

**README.md**: This directory guide.

## Subdirectories

None.

## Notes

`<datetime>` has the form `YYYYMMDD-HHMMSS`.

Scripts delete pertinent older reports when a newer report is written
or the older report is obsolete.
