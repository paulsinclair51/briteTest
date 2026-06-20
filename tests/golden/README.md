# tests/golden/

Directory for golden files used for output file comparison and validation.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `../../LICENSE`.

See `../../README.md` for an introduction to LiteTest.

## Files

- Golden files that contain the expected contents of each
  corresponding output file.
- **README.md**: This directory guide.

## Subdirectories

- None.

## Golden Files and Output Files

LiteTest compares each output file with a corresponding golden file of
the same name in `tests/golden/` or `tests/golden<n>/`. If no corresponding golden
file exists, the output is automatically promoted.

Golden file contents of `##MATCH##\n` or `##MISMATCH##\n` allow forcing matches
or mismatches, respectively.

See also `../output/README.md`.

For full details, including customization options, see the
LiteTest Runner User Guide.
