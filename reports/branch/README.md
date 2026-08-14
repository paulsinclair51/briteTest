# `<repo>/reports/branch/`

Directory containing branch/workflow untracked reports.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `<repo>/LICENSE`.

See `<repo>/README.md` for an introduction to briteTest.

## Files

**branch-<datetime>-<pid>.md**: Branch report from `<repo>/scripts/bin/lsbranch`.

**commit-<datetime>-<pid>.md**: Commit report from `<repo>/scripts/bin/commit`.

**mrgup-<datetime>-<pid>.md**: Merge-and-push report from `<repo>/scripts/bin/mrgup`.

**push-<datetime>-<pid>.md**: Push report from `<repo>/scripts/bin/push`.

**README.md**: This directory guide.

## Subdirectories

None.

## Notes

`<datetime>` has the form `YYYYMMDD-HHMMSS`. Older reports may be removed by
the generating script after successful report creation.

`<pid>` is a process id to provide uniqueness to the file name.
