# tests/control

Directory for control files used for output comparison:

- A generated ouput file is compared with the control file with the same
  name to determine pass/fail outcomes.
- If there is no corresonding control file, the output file is copied
  (promoted) to the control directory with an outcome of pass.  This
  is noted in test report that it was promoted.
- A control file with only the line `##PASS##\n` indicates pass (without comparing).
- A control file with only the line `##FAIL##\n` indicates fail (without comparing).
- If a fail occurs for the output file but analysis indicates it is correct and control
  file is obsolete, copy the output file to the control directory (or remove the control file and the next run of the executable will copy the output file to control
  directory as mentioned above).

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `../../LICENSE`.

Directories:

- None.

Files:

- `README.md`: This directory guide.

See `../../README.md` for a concise introduction to LiteTest.
