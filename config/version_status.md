# Version Status

Defines the status of versions for accepting changes.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `<repo>/LICENSE`.

See `<repo>/README.md` for an introduction to briteTest.

See `<repo>/docs/md/Contributot_Guide.md` for more information about version and release
workflows.

## Dev Status
- **Closed**: Not yet accepting dev changes.
- **Open**: Accepting dev changes.
- **Released**: Version has been released and is no longer accepting dev changes.

## Fix Status
- **Closed**: Not yet accepting fix changes.
- **Open**: Accepting fix changes.
- **Suspended**: Version has been suspended and is no longer accepting fix changes.

## Version Status Flow

| Dev | Fix |
|-----|-----|
| Closed | Closed |
| Open | Closed |
| Released | Closed |
| Released | Open |
| Released | Suspended |

Normally, Released/Suspended ends the flow but, as needed, fix status
can be updated back to Open.

## Current Status

| Version | Dev | Fix |
|---------|-----|-----|
| v1.0.0 | Open | Closed |
| v1.1.0 | Closed | Closed |
| v2.0.0 | Closed | Closed |

If a version is not listed, its status is Closed/Closed.

