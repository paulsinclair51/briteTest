# LiteTest Runner Reference

This document provides a reference to the LiteTest Runner API. It includes types, structs, unions,
enums, macros, and functions. Additionally, it provides a reference to LiteTest concepts and behavior.

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

**Negative exit codes for Runner termination**: `LT_DECLARE_ORCHESTRATOR_ERROR`.

### 9.2. `LT_INIT_ORCHESTRATOR(funcname, project, size_t maxparallel);`

**funcname**: token specifying `main`.

**project**: token identifying the project. Token is used to generate a default report title

**maxparallel**: maximum number of `LT_GROUP` and `LT_TEST` macros that are allowed to execute in parallel.

**Negative exit codes for Runner termination**: `LT_INIT_ORCHESTRATOR_ERROR`.

### 9.3. `LT_PARSE_ARGS(size_t maxargs, char *defaultreportfilename, size_t maxlen);`

**maxargs**:

**defaultreportfilename**: 

**maxlen**: 

**Negative exit codes for Runner termination**: `LT_ARG_ERROR`.

### 9.4. `LT_OPEN_REPORT(char *title, size_t maxlen);`

**Negative exit codes for Runner termination**: `LT_OPEN_ERROR`.

### 9.5. `LT_WRITE_RESULT(gtm, char *category;`

**gtm**: LT_GROUP or LT_TEST macro.

**category**; 

**Negative exit codes for Runner termination**: `LT_WRITE_ERROR`.

### 9.6. `LT_CLOSE_REPORT(char *notes, size_t maxlen);`

**notes**: Notes to append to the test report. Each note in notes must be ended by `'\n'` (newline). NULL or 0-length
           indicate no notes to append. maxlen specifies a mxaimmum length for notes to avoid missing null terminator for
           notes.
           
**maxlen**: Maximum length for `notes`.

**Negative exit codes for Runner termination**: `LT_CLOSE_ERROR`.

The macro writes the totals, pre-defined explanatory notes, `notes`, notes from the temporary notes file to the
test report file, and then closes the test report.

### 9.7. `LT_EXIT;`

**Exit codes**: LT_PASS (0), LT_FAIL (1), LT_FAULT (2), LT_FAIL_FAULT (3).

**Negative exit codes for Runner termination**: `LT_EXIT_ERROR`

## 10. Macros for a Test Group Function

Macros used to define or declare a test group function.

### 10.1. `LT_DECLARE_GROUP(funcname)`

**funcname**: token specifying a function name other than `main`.

A semicolon is not allowed if the macro is followed by its definition `{...}` of the
test group function; otherwise, it is required and indicates this is a declaration
and a forward-reference to tne test group function.

**Negative exit codes for Runner failure**: `LT_DECLARE_GROUP_ERROR`.

### 10.2. `LT_INIT_GROUP(funcname, maxparallel)`

**funcname**: the same token as the specified token for funcname in `LT_DECLARE_GROUP` macro defining the containing
              test group function.

**maxparallel**: maximum number of `LT_GROUP` and `LT_TEST` macros that are allowed to execute in parallel.

**Negative exit codes for Runner termination**: `LT_INIT_GROUP_ERROR`.

### 10.3. `LT_RETURN`

**Negative exit codes for Runner termination**: `LT_RETURN_ERROR`.

## 11. Macros to Execute a Test Group or a Test

- `LT_GROUP(funcname, [include], [isolation])[;]`
- `LT_TEST(expression, [include], [isolation][;])`

A semicolon is not allowed if the macro is used as an argument to the `LT_WRITE_RESULTS` macro;
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

**Negative exit codes for Runner termination**: `LT_GROUP_ERROR`.

### 11.2. `LT_TEST(expression, [include], [isolation])[;])``

**Negative exit codes for Runner termination**: `LT_TEST_ERROR`.

## 12. Concurrent Block Macros

### 12.1. `LT_BEGIN_CONCURRENT(blockname)`

**blockname**:
- Token specifying the name of the block.
- Token must be the same as for the subsequent matching `LT_END_CONCURRENT`.

**Negative exit codes for Runner termination**: `LT_BEGIN_GROUP_ERROR`.

### 12.2. `LT_END_CONCURRENT(blockname);`

**blockname**:
- Token specifying the name of the block.
- Token must be the same as for the preceding matching `LT_BEGIN_CONCURRENT.

**Negative exit codes for Runner termination**: `LT_END_GROUP_ERROR`.

## 13. Version Macros
 
### 13.1. `LT_RUNNER_VERSION`

**Value**:  
- LiteTest Runner's version as a literal string of type `char[n]`, where `n` is between 5 and 9 (including
  the terminating null character).
- Format: `M.m.p`, where `M`, `m`, and `p` are one or two digits.
- `M` is the major version, `m` is the minor version, and `p` is the patch version. 

**Examples**:
- `LT_RUNNER_VERSION` → `"1.0.9"`
- `LT_RUNNER_VERSION` → `"1.3.11"`
- `LT_RUNNER_VERSION` → `"12.05.18"`

### 13.2. `LT_VERSION_MAJOR(v)`

**v**: pointer to a version string.

**Value**:
- The major version in `v` cast to `int`.
- Value is `LT_INVALID_VERSION` (`(int)-2`) *if* `v` is an invalid version string.

**Examples**:
- `LT_VERSION_MAJOR("5.0.9")` → `(int)5`
- `LT_VERSION_MAJOR("5.000.9")` → `LT_INVALID_VERSION`
- 
### 13.3. `LT_VERSION_MINOR(v)`

**v**: pointer to a version string.

**Value**:  
- The minor version in `v` cast to `int`.
- Value is `LT_INVALID_VERSION` (`(int)-2`) *if* `v` is an invalid version string.
- 
**Examples**:
- `LT_VERSION_MINOR("5.00.9")` → `(int)0`
- `LT_VERSION_MINOR("5.1.001")` → `LT_INVALID_VERSION`
- 
### 13.4.`LT_VERSION_PATCH(v)`

**v**: pointer to a version string.

**Value**:  
- The patch version in `v` cast to `int`.
- Value is `LT_INVALID_VERSION` (`(int)-2`)` *if* `v` is an invalid version string.

**Examples**:
- `LT_VERSION_PATCH("5.0.12")` → `(int)12`
- `LT_VERSION_PATCH("5.000.9")` → `LT_INVALID_VERSION`

### 13.5.`LT_VERSION_NUM(v)`

**Value**:
- Representation of the version `v` cast to `int`.
- Value is `LT_INVALID_VERSION` (`-2`) *if* `v` is an invalid version string.

**v**: pointer to a version string.

**Examples**:
- `LT_RUNNER_VERSION` → `"1.0.9"`

### 13.6. `LT_VERSION_HEX(v)`

**v**: pointer to a version string.

**Value**:
- Hex representation of version `v` cast to `int`.
- Value is `LT_INVALID_VERSION` (`-2`) *if* `v` is an invalid version string.

**Examples**:
- `LT_RUNNER_VERSION` → `"1.0.9"`

### 13.7. `LT_VERSION_CMP(v1, v2)`

**v1**: pointer to a version string.  
**v2**: pointer to a version string.

**Value**:
- Integer result comparing version `v1` to `v2`:
  - `LT_EQUAL` (`0`) — equal
  - `LT_LESS` (`1`) — `v1` is less than `v2`
  - `LT_GREATER` (`1`) — `v1` is greater than `v2`
  - `LT_INVALID_VERSION` (`-2`)` — invalid `v1` or invalid `v2`
- Leading zeros in `M`, `m`, and `p` are ignored during comparison.

**Examples**:
- `LT_VERSION_CMP(LT_RUNNER_VERSION, "1.10.0")` → `LT_GREATER` (*if* `LT_RUNNER_VERSION` is `"1.10.6"`)
- `LT_VERSION_CMP(LT_RUNNER_VERSION, "1.10.0")` → `LT_LESS` (*if* `LT_RUNNER_VERSION` is `"1.8.0"`)
- `LT_VERSION_CMP(LT_RUNNER_VERSION, "1.10.0")` → `LT_EQUAL` (*if* `LT_RUNNER_VERSION` is `"1.10.0"`)
- `LT_VERSION_CMP("1.10.0x", "1.10.0")` → `LT_INVALID_VERSION`
- `LT_VERSION_CMP("1.10.0", "1.10y.0")` → `LT_INVALID_VERSION`

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
