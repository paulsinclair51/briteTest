# `<repo>/reports/branch/`

Directory containing branch/workflow untracked reports.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `<repo>/LICENSE`.

See `<repo>/README.md` for an introduction to briteTest.

## Files

**branch-<datetime>.md**: Latest branch report from
`<repo>/scripts/bin/lsbranch`.

**history-<datetime>-<id>.md**: Retained activity report from
`<repo>/scripts/bin/report`.

**<workflow>-d-<datetime>.md**: Dry-run report from a branch workflow.

**<workflow>-e-<datetime>.md**: Error report from a branch workflow.

**README.md**: This directory guide.

## Subdirectories

None.

## Notes

`<workflow>` can be commit, push, pull, mrgup, mrgdown, or copyfix.

`<datetime>` has the form `YYYYMMDD-HHMMSS`. Branch workflows serialize report
creation, wait for the next available second, and remove older dry-run/error
reports after successful work. History reports are retained.

`<id>` distinguishes retained reports created in the same second.
