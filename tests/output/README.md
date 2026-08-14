# `<repo>/tests/output/`

Directory containing copies of generated test outputs.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `<repo>/LICENSE`.

See `<repo>/README.md` for an introduction to briteTest.

Output files in this directory are compared against corresponding
golden files and metadata files in `<repo>/tests/golden/`.

## Files

**Output files**: Captured copies of `stdout`, `stderr`, and named output files
produced during test runs.

**Metadata files**: Markdown Document (`.md`) metadata files associated with
captured output files and related file groups.

**README.md**: This directory guide.

## Subdirectories

None.

## Output and Golden Files

Output files in `<repo>/tests/output/` provide captured copies for review. Golden
files in `<repo>/tests/golden/` provide the expected results used for validation.

- Named output files are captured using a unique suffix to avoid collisions:

  - If the output file is `<name>.<ext>`, the captured file is
    `<name>-<uid>.ext`.

  - If the output file is `<name>` (no extension), the captured file is
    `<name>-<uid>`.

- `stdout` and `stderr` are captured as `stdout-<uid>` and `stderr-<uid>`.

- Temporary files are not captured in `<repo>/tests/output/`.

For each captured output file, a metadata file is also written:

- For `<name>-<uid>.ext`, metadata is `<name>-<uid>.ext.md`.
- For `<name>-<uid>`, metadata is `<name>-<uid>.md`.

Captured output files may be promoted to `<repo>/tests/golden/` for future
comparisons.

For full details, including customization options for comparison and promotion,
see the Test User Guide.

See also `<repo>/tests/golden/README.md`.
