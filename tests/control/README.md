# tests/golden/

Directory for golden files used for output file comparison and validation.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `../../LICENSE`.

See `../../README.md` for an introduction to LiteTest.

## Files

- ***.golden**: Golden files that contain the expected contents of each corresponding 
  output file.
- **README.md**: This directory guide.

## Subirectories

- golden1
- golden2
- golden3

Create additional subdirectories golden4, golden5, etc. and corresponding output
subdirectories as needed for outputs that have the same name but are written
to different directories.

## Golden Files and Output Files

LiteTest compares each test output file with a corresponding golden file of
the same name in `tests/golden` or `tests/golden<n>`. If no corresponding golden
file exists, the output is automatically promoted.

Global file contents of `##MATCH##\n` or `##MISMATCH##\n` allow forcing matches
or mismatches, respectively.

For full details, including customization options and edge‑case handling, see the
LiteTest Runner User Guide.
