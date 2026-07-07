# /tests/golden/

Directory containing golden files used for output file comparison and validation.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `/LICENSE`.

See `/README.md` for an introduction to briteTest.

## Files

- **Golden files**: Files that contain the expected contents of each corresponding
  output file.

- **Metadata files**: Markdown Document (`.md`) metadata files associated with
  golden files and related file groups.
  
- **README.md**: This directory guide.

## Subdirectories

- None.

## Golden Files and Output Files

The Runner Framework compares each output file with a corresponding golden file
of the same name in `tests/golden/`. If no corresponding golden file exists,
the output may be promoted to become the matching golden file.

Golden file metadata can include markers such as `## MATCH` or `## MISMATCH` to
force a match or mismatch, respectively. Additional markdown text can follow
these markers to explain why the outcome is forced for a file or file group.

See also `../output/README.md`.

For full details, including customization options for comparison and promotion,
see the Runner User Guide.
