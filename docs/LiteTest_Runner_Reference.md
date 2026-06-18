# LiteTest Runner Reference

This document provides a reference to the LiteTest Runner API. It includes types, structs, unions,
enums, macros, and functions. Additionally, it provides a reference to LiteTest framework concepts .

<details>
<summary>`Click to view` sections are used throughout this document</summary>

#### Why Click to view?

- Keeps documents readable while accommodating large amounts of
  technical detail.

- Allows scanning the structure and expanding only what you need.

- Reduces visual noise and makes navigation easier.
</details>

### Copyright (c) 2026 Paul Sinclair

<details>
<summary>Click to view License</summary>

## License

SPDX-License-Identifier: MIT

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
</details>

<details>
<summary>Click to view Preface</summary>

## Preface

This document is intended for LiteTest user and contributors who need
a reference for the LiteTest Runner framework and API.

For a list of other LiteTest documents and the repository layout, see
the LiteTest Documentation Guide (`LiteTest_Documentation_Guide.md`).

For a glossary of terms, see the LiteTest Glossary Reference
(`LiteTest_Glossary_Reference.md`).

<details>
<summary>Click to view Document Version History</summary>

### Document Version History

| Document | Runner | Test | Date | Comment | Author/Editor |
|----------|------|--------|------|---------|---------------|
| 1.0 |1.0.0 | 1.0.0 | 2026‑06‑11 |  Initial version. | Paul Sinclair |

- The **Document** column records the document's version with the
  format `M.u` (Major, update).
- The **Runner** column records the LiteTest Runner API version
  current at the time this document version was published and is
  defined by its `LT_RUNNER_VERSION` macro.
- The **Test** column records the LiteTest Test API version current at
  the time this document version was published and is defined by its
  `LT_TEST_VERSION` macro.
- Both the Runner API and Test API use the version format `"M.m.p"` (Major, minor,
  patch).
- `M` is the same for the Document, Runner, and Test versions.

The document's update version tracks updates to this document and does
not correspond to a minor or patch version. `u` increments whenever
this document is updated without a change to `M`, and it resets to `0`
when `M` is incremented.
</details>
</details>

<details>
<summary>Click to view Table of Contents</summary>

## Table of Contents

[**1. Introduction**](#1-introduction)

[**2. Types**](#2-types)

[**3. Structs**](#3-structs)

[**4. Unions**](#4-unions)

[**5. Macros for Limits**](#5-macros-for=limits)

[**6. Macros for Exit Codes**](#6-macros-for-exit-codes)

[**7. Macros for Return Codes**](#7-macros-for-return-codes)
</details>

<details>
<summary>Click to view 1. Introduction</summary>

## 1. Introduction

TODO: add introduction, common rules.
</details>

<details>
<summary>Click to view 2. Types</summary>

## 2. Types

TODO.
</details>

<details>
<summary>Click to view 3. Structs</summary>

## 3. Structs

TODO.
</details>

<details>
<summary>Click to view 4. Unions</summary>

## 4. Unions

TODO.
</details>
  
<details>
<summary>Click to view 5. Enums</summary>

## 5. Enums

TODO.
</details>
  
<details>
<summary>Click to view 6. Macros for Limits</summary>

## 6. Macros for Limits

TODO.
</details>
  
<details>
<summary>Click to view 7. Macros for Exit Codes</summary>

## 7. Macros for Exit Codes

TODO.
</details>
  
<details>
<summary>Click to view 8. Macros for Return Codes</summary>

## 8. Macros for Return Codes

TODO.
</details>
  
<details>
<summary>Click to view 9. Macros for the Orchestrator Function</summary>

## 9. Macros for the Orchestrator Function

Macros used to define or declare the Orchestrator (`main`) function

### 9.1. `LT_DECLARE_ORCHESTRATOR(funcname)[;]`

A semicolon is not allowed if the macro is followed by its definition `{...}` of the
orchestrator function; otherwise, it is required and indicates this is a declaration
and a forward-reference to the orchestrator function.

**funcname**: Token specifying `main`.

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

**gtm**: A `LT_GROUP(...)` or `LT_TEST(,,,)` macro.

**category**; A pointer to a string with the name or description of the test category. Maximum length including
              null terminator character is `MAX_CATEOGRY_LEN` (129).

**Negative exit codes for Runner termination**: `LT_WRITE_ERROR`.

### 9.6. `LT_CLOSE_REPORT(char *notes, size_t maxlen);`

**notes**:
- A string of note lines to append to the test report.
- Each note line must end with `'\n'` (newline).
- NULL or 0-length `notes` indicate no notes to append.

**maxlen**: Maximum length for `notes` to avoid a missing null terminator issues.

**Negative exit codes for Runner termination**: `LT_CLOSE_ERROR`.

The macro writes the totals, pre-defined explanatory notes, `notes`, notes from the temporary notes file to the
test report file, and then closes the test report.

### 9.7. `LT_EXIT;`

**Exit codes**: `LT_PASS` (0), `LT_FAIL` (1), `LT_FAULT` (2), `LT_FAIL_FAULT` (3).

**Negative exit codes for Runner termination**: `LT_EXIT_ERROR`.
</details>
  
<details>
<summary>Click to view 10. Macros for a Test Group Function</summary>

## 10. Macros for a Test Group Function

Macros used to define or declare a test group function.

### 10.1. `LT_DECLARE_GROUP(funcname)`

**funcname**: Token specifying a function name other than `main`.

A semicolon is not allowed if the macro is followed by its definition `{...}` of the
test group function; otherwise, it is required and indicates this is a declaration
and a forward-reference to the test group function.

**Negative exit codes for Runner failure**: `LT_DECLARE_GROUP_ERROR`.

### 10.2. `LT_INIT_GROUP(funcname, maxparallel)`

**funcname**: the same token as the specified token for funcname in the orecedubg `LT_DECLARE_GROUP`
macro defining the containing test group function.

**maxparallel**: maximum number of `LT_GROUP` and `LT_TEST` macros that are allowed to execute in parallel.

**Negative exit codes for Runner termination**: `LT_INIT_GROUP_ERROR`.

### 10.3. `LT_RETURN`

**Negative exit codes for Runner termination**: `LT_RETURN_ERROR`.
</details>
  
<details>
<summary>Click to view 11. Macros to Execute a Test Group or Test</summary>

## 11. Macros to Execute a Test Group or a Test

- `LT_GROUP(funcname, [include], [isolation])[;]`
- `LT_TEST(expression, [include], [isolation][;])`

A semicolon is not allowed if the macro is used as an argument to the `LT_WRITE_RESULTS` macro;
otherwise, it is required.

**include**: single character token or omit (defaults to `1`).

- `0`   — Never execute. This useful to disable a test (e.g., failing or faulting test for which the fix has been deferred).
- `1`   — Always execute (e.g., smoke tests).
- `2–9` — Execute only when the `-In` flag is specified in the test command line and n ≥ include.
- `I`   — Execute only when the `-I` flag is specified in the test command line. This is usefull for
          injecting a fail/fault for verifying behavior and report output if fails/faults were to occur.
          See also `LT_FAIL` and `LT_FAULT(type)` for simulating a fail or fault, respectively.

See "Test Command Line" for details on command line flags.

**isolation**: single character token or omit (defaults to 0):

- `0` — Same thread.
- `1` — Separate thread.
- `2` — Separate process.

See "Isolation" in the LiteTest Runner Guide.

### 11.1. `LT_GROUP(funcname, [include], [isolation])[;]

**Negative exit codes for Runner termination**: `LT_GROUP_ERROR`.

### 11.2. `LT_TEST(expression, [include], [isolation])[;])``

**Negative exit codes for Runner termination**: `LT_TEST_ERROR`.
</details>
  
<details>
<summary>Click to view 12. Macros for Concurrent Blocks</summary>

## 12. Macros for Concurrent Blocks

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
</details>
  
<details>
<summary>Click to view 13. Macros for Versioning</summary>

## 13. Macros for Versioning
 
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
</details>
  
<details>
<summary>Click to view 14. Functions for Customizations</summary>
  
## 14. Functions for Customization

## 14.1. `int lt_funcname(char *funcname, size_t outlen)`

## 14.2. `int lt_print_note(const char *notes, size_t maxlen)`

Opens a temporary temporary file if not already open and writes the notes to the the temporary file.

**notes**:
- A string of note lines to write to the temporary file.
- Each note line must end with `'\n'` (newline).
- NULL or 0-length `notes` indicate no notes to append.

**maxlen**: Maximum length for `notes` to avoid missing null terminator issues.

*Return**: `LT_SUCCESS`, `LT_NOTES_OPEN_ERROR`, `LT_PRINT_NOTE_ERROR`.

## 14.3. `lt_remove_notes()`

Force a close and remove the temporary notes file. LT_EXIT macro does this automactically.

**Return**: `LT_SUCCESS`, `LT_NOTES_REMOVE_ERROR`.
</details>
  
<details>
<summary>Click to view 15. Test Command Line</summary>

## 15. Test Command Line

TODO.
</details>
  
<details>
<summary>Click to view 16. Golden Files</summary>

## 16. Golden Files

Golden files (located in the `tests/golden/` subdirectory of the repository root directory) are handled as follows:

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
  </details>
