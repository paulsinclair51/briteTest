# tests/golden/

Directory for golden files used for output file comparison and validation.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `../../LICENSE`.

See `../../README.md` for an introduction to LiteTest.

## Files

- **.golden**: Golden files that contain the expected contents of each test
  output file.
- **README.md**: This directory guide.
- 
## Subirectories

- None.

## Golden Files

LiteTest compares each test output file with a golden file of the same name in
`tests/golden`. If no golden file exists, the output is automatically promoted.
Global file contents of `##MATCH##\n` or `##MISMATCH##\n` allow forcing matches
or mismatches, respectively.

For full details, including customization options and edge‑case handling, see the
LiteTest Runner User Guide.



## Golden Files

- Each test output file is compared with its golden file of the same name
  in the `tests/golden` directory to determine whether they match.

- If no corresponding golden file exists, the output file is automatically
  copied (promoted) into the `tests/golden` directory and is treated as a match.
  The test report notes that the file was promoted.

- A golden file containing only the line `##MATCH##\n` skips comparison and
  forces a match.

- A golden file containing only the line `##MISMATCH##\n` skips comparison and
  forces a mismatch.

- If an output file does not match its golden file but inspection determines
  the output is correct, update the golden file with a copy of the output.
  Alternatively, remove the golden file so that the next run will
  automatically promote the output.

## Rationale for Parallel Directory for Golden Files

LiteTest uses a parallel `tests/golden` directory with golden files that keep
the exact same filename as their corresponding test output. This design avoids
the common problems found in extension‑based naming schemes:

- **No filename collisions**  
  Different outputs such as `foo.c` and `foo.h` remain distinct (`foo.c` vs.
  `foo.h`) instead of collapsing into a single `foo.golden`.

- **No special‑case rules**  
  Files with or without extensions follow the same rule. The golden filename is
  always identical to the output filename.

- **Preserves file type information**  
  Because the original extension is retained, it is immediately clear whether a
  golden file contains text, JSON, HTML, binary data, or anything else.

- **Simpler mental model**  
  Developers do not need to remember naming conventions or extension‑replacement
  rules. Golden files simply live in a parallel directory and share the same
  name as the output they validate.

- **Identical filenames in different output directories**  
  The above approach does not directly address this situation. If it occurs, the
  conflict can be resolved by creating parallel subdirectories under `tests/golden`
  so that each output file has a unique corresponding location. This can be done
  through customization of your test runner or, when needed, by extending the
  Runner and Test API.

This approach keeps LiteTest predictable, easy to understand, and free of the
ambiguity that often arises in golden‑file systems that rewrite filenames.

