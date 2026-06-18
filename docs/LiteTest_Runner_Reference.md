# LiteTest Runner Reference

This document provides a reference to the LiteTest Runner API. It includes types, structs, unions,
enums, macros, and functions.

Copyright (c) 2026 Paul Sinclair
SPDX-License-Identifier: MIT. For license details, see ../LICENSE.

## 1. Introduction


## 2. Types



## 3. Structs



## 4. Unions



## 5. Enums

## 6. Macros for Limits

## 7. Macros for Exit Codes

## 8. Macros for Return Codes

## 9. Macros for an Orchestrator Function

Macros used to define or declare the Orchestrator (`main`) function.

### 9.1. `LT_DECLARE_ORCHESTRATOR(funcname)[;]`

A semicolon is not allowed if the macro is followed by its definition `{...}` of the
orchestrator function; otherwise, it is required and indicates this is a decalaration
and a forward-reference to tne orchestrator function.

**funcname**: token specifying `main`.

Exit codes for failure: LT_DECLARE_ORCHESTRATOR_ERROR.

### 9.2. `LT_INIT_ORCHESTRATOR(funcname, project, size_t maxparallel);`

**funcname**: token specifying `main`.

**project**: token identifying the project.

**maxparallel**: maximum number of LT_GROUP and LT_TEST macros that are allowed to execute in parallel.

Exit codes for failure: LT_INIT_ORCHESTRATOR_ERROR.

### 9.3. `LT_PARSE_ARGS(size_t maxargs, char *defaultreportfilename, size_t maxlen);`

**maxargs**:

**defaultreportfilename**: 

**maxlen**: 

Exit codes for failure: LT_ARG_ERROR.

### 9.4. `LT_OPEN_REPORT(char *title, size_t maxlen);`

Exit codes for failure: LT_OPEN_ERROR.

### 9.5. `LT_WRITE_RESULT(gtm, char *category;`

**gtm**: LT_GROUP or LT_TEST macro.

**category**; 

Exit codes for failure: LT_WRITE_ERROR.

### 9.6. `LT_CLOSE_REPORT(char *notes, size_t maxlen);`

**notes**: Notes to append to the test report. Each note in notes must be ended by `'\n'` (newline). NULL or 0-length
           indicate no notes to append. maxlen specifies a mxaimmum length for notes to avoid missing null terminator for
           notes.

Exit codes for failure: LT_CLOSE_ERROR.

The macro writes the totals, pre-defined explanatory notes, `notes`, notes from the temporary notes file to the
test report file, and then closes the test report.

### 9.7. `LT_EXIT;`

Exit codes: LT_PASS (0), LT_FAIL (1), LT_FAULT (2), LT_FAIL_FAULT (3).

### 10. Macros for a Test Group Function

Macros used to define or declare a test group function.

### 10.1. `LT_DECLARE_GROUP(funcname)`

**funcname**: token specifying a function name other than `main`.

A semicolon is not allowed if the macro is followed by its definition `{...}` of the
test group function; otherwise, it is required and indicates this is a declaration
and a forward-reference to tne test group function.

Exit codes for failure: LT_DECLARE_GROUP_ERROR.

### 10.2. `LT_INIT_GROUP(funcname, maxparallel)`

**funcname**: the same token as the specified token for funcname in `LT_DECLARE_GROUP` macro defining the containing
              test group function.

**maxparallel**: maximum number of LT_GROUP and LT_TEST macros that are allowed to execute in parallel.

Exit codes for failure: LT_INIT_GROUP_ERROR.

### 10.3. `LT_RETURN`

Exit codes for failure: LT_RETURN_ERROR.

## 11. Macros to Execute a Test Group or a Test

- `LT_GROUP(funcname, [include], [isolation])[;]`
- `LT_TEST(expression, [include], [isolation][;])`

A semicolon is not allowed if the macro is used as an argument to LT_WRITE_RESULTS macro;
otherwise, it is required.

**include**: single character token or omit (defaults to 1):

- `0`   — Never execute.
- `1`   — Always execute. 
- `2–9` — Execute only when the `-In` flag is specified in the test command line and n ≥ include.
- `I`   — Execute only when the `-I` flag is specified in the test command line.

See Test Command Line for details on command line flags.

**isolation**: single character token or omit (defaults to 0):

- `0` — Same thread.
- `1` — Separate thread.
- `2` — Separate process.

See "Isolation" in the LiteTest Runner Guide.

### 11.1. `LT_GROUP(funcname, [include], [isolation])[;]

Exit codes for failure: LT_GROUP_ERROR.

### 11.2. `LT_TEST(expression, [include], [isolation])[;])``

Exit codes for failure: LT_TEST_ERROR.

## 12. Concurrent Block Macros

### 12.1. `LT_BEGIN_CONCURRENT([blockname])`

**blockname**: token specifying blockname. Default is no block name)

Exit codes for failure: LT_BEGIN_GROUP_ERROR.

### 12.2. `LT_END_CONCURRENT[blockname']);`

**blockname**: token specifying blockname. Default is no block name.
               Token must be the same as for the preceding `LT_BEGIN_CONCURRENT`, or
               if omitted, token must be omitted in the preceding ``LT_BEGIN_CONCURRENT`.

Exit codes for failure: LT_END_GROUP_ERROR.

## 13. Version Macros
 
### 13.1. `LT_RUNNER_VERSION`


### 13.2. `LT_VERSION_MAJOR(v)`


### 13.3. `LT_VERSION_MINOR(v)`


## 13.4.`LT_VERSION_PATCH(v)`


### 13.4.`LT_VERSION_NUM(v)`


### 13.5. `LT_VERSION_HEX(v)`


### 13.6. `LT_VERSION_CMP(v1, v2)`


## 14. Functions for Customization

## 14.1. `int lt_funcname(char *funcname, size_t outlen)`

## 14.2. `int lt_print_note(const char *note, size_t len)`

Opens a temporary temporary file if not already open and writes note to the the temporary file.

Return: LT_SUCCESS, LT_NOTES_OPEN_ERROR, LT_PRINT_ERROR

## 14.3. `lt_remove_notes()`

Force a close and remove the temporary notes file. LT_EXIT macro does this automactically

Return: LT_SUCCESS, LT_NTOES_REMOVE.

## 15. Golden Files

Golden files are handled as follows:

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

Rationale for Parallel Directory for Golden Files:

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

