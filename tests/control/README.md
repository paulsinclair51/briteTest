# tests/golden/

Directory for golden files used for output comparison and validation.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `../../LICENSE`.

See `../../README.md` for an introduction to LiteTest.

## Files

- **.golden**: Golden files that contain the expected contents of each test
  output file .
- **README.md**: This directory guide.
- 
## Directories

- None.

## Golden Files

- Each test output file is compared with its golden file of the same name (but with
  the`.golden` extension  to determine whether they match.
- If no corresponding golden file exists, the output file is automatically copied (promoted)
  into this directory using the `.golden` extension and a match is assumed. The test report
  notes that the file was promoted.
- A golden file containing only the line `##MATCH##\n` skips comparison and forces a match.
- A golden file containing only the line `##MISMATCH##\n` skips comparision and forces a
  mismatch.  
- If an output file does not match its golden file but inspection determines the output
  is correct, update the golden file with a copy of the output. Alternatively, remove its
  golden file so that the next run will promote the output automatically.
