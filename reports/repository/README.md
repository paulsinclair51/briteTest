# `<repo>/reports/repository/`

Directory containing repository/fork/clone untracked reports.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `<repo>/LICENSE`.

See `<repo>/README.md` for an introduction to briteTest.

## Files

**repository-\<datetime\>-\<pid\>.md**: Report from `<repo>/scripts/bin/fixrepo`.

**repository-d-\<datetime\>-\<pid\>.md**: Dry-run report from `<repo>/scripts/bin/fixrepo`.

**README.md**: This directory guide.

## Subdirectories

None.

## Notes

`<datetime>` has the form `YYYYMMDD-HHMMSS`. Older reports may be removed by
the generating script after successful report creation.

`<pid>` is a process id to provide uniqueness to the file name.
