# LiteTest Runner Reference

This document provides a reference to the LiteTest Runner API. It includes types, structs, unions,
enums, macros, and functions. Additionally, it provides a reference to LiteTest framework concepts .

**Copyright (c) 2026 Paul Sinclair**

<details>
<summary>License</summary>

#### **License**

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
<summary>Preface</summary>

## Preface

This document is intended for LiteTest user and contributors who need
a reference for the LiteTest Runner framework and API.

For a list of other LiteTest documents and the repository layout, see
the LiteTest Documentation Guide (`LiteTest_Documentation_Guide.md`).

For a glossary of terms, see the LiteTest Glossary Reference
(`LiteTest_Glossary_Reference.md`).

<details>
<summary>Document Version History</summary>

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
<summary>Table of Contents</summary>

## Table of Contents

[**1. Introduction**](#1-introduction)<br>

[**2. Types**](#2-types)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**2.1. lt_result_t**](#21-lt_result_tt)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**2.2. lt_state_t**](#22-lt_stste_t)<br>


[**3. Enums**](#3-enums)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**3.1. lt_exit_code_t**](#31-lt_exit_code_t)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**3.2. lt_return_code_t**](#32-lt_return_code_t)<br>

[**4. Macros for Limits**](#4-macros-for-limits)<br>

[**5. Macros for the Orchestrator Function**](#5-macros-for-the-orchestrator-function)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**5.1. LT_DECLARE_ORCHESTRATOR**](#51-lt_declare_orchestratorfuncname)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**5.2. LT_INIT_ORCHESTRATOR**](#52-lt_init_orchestratorfuncname-id-project-size_t-maxparallel)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**5.3. LT_PARSE_ARGS**](#53-lt_parse_argssize_t-maxargs-char-customflags-char-defaultreportfilename)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**5.4. LT_OPEN_REPORT**](#54-lt_open_reportchar-title)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**5.5. LT_WRITE_RESULT**](#55-lt_write_resultgtm-char-category)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**5.6. LT_CLOSE_REPORT**](#56-lt_close_reportchar-notes)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**5.7. LT_EXIT**](#57-lt_exit)<br>

[**6. Macros for a Test Group Function**](#6-macros-for-a-test-group-function)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**6.1. LT_DECLARE_GROUP**](#61-lt_declare_groupfuncname)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**6.2. LT_INIT_GROUP**](#62-lt_init_groupfuncname-id-maxparallel)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**6.3. LT_RETURN**](#63-lt_return)<br>

[**7. Macros to Execute a Test Group or Test**](#7-macros-to-execute-a-test-group-or-test)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**7.1. LT_GROUP**](#71-lt_groupfuncname-id-include-isolation)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**7.2. LT_TEST**](#72-lt_testexpression-id-include-isolation)<br>

[**8. Macros for Concurrent Blocks**](#8-macros-for-concurrent-blocks)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**8.1. LT_BEGIN_CONCURRENT**](#81-lt_begin_concurrentblockname)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**8.2. LT_END_CONCURRENT**](#82-lt_end_concurrentblockname)<br>

[**9. Macros for Versioning**](#9-macros-for-versioning)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**9.1. LT_RUNNER_VERSION**](#91-lt_runner_version)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**9.2. LT_VERSION_MAJOR**](#92-lt_version_majorv)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**9.3. LT_VERSION_MINOR**](#93-lt_version_minorv)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**9.4. LT_VERSION_PATCH**](#94-lt_version_patchv)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**9.5. LT_VERSION_NUM**](#95-lt_version_numv)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**9.6. LT_VERSION_HEX**](#96-lt_version_hexv)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**9.7. LT_VERSION_CMP**](#97-lt_version_cmpv1-v2)<br>

[**10. Functions for Customization**](#10-functions-for-customization)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**10.1. LT_PRINT_ERR_HELP**](#101-lt_print_err_helpchar-err-char-help)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**10.2. lt_funcname**](#102-int-lt_funcnamechar-funcname-size_t-outlen)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**10.3. lt_print_note**](#103-int-lt_print_noteconst-char-notes)<br>

[**11. Test Command Line**](#11-test-command-line)<br>

[**12. Output and Golden Files**](#12-output-and-golden-files)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**12.1. Golden Files**](#121-golden-files)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[**12.2. Rationale for Design**](#122-rationale-for-design)
</details>

<details>
<summary>1. Introduction</summary>

## 1. Introduction

TODO: add introduction, common rules.
</details>

<details>
<summary>2. Types</summary>

## 2. Types

<details>
<summary>2.1. `lt_result_t`</summary>

### 2.1. `lt_result_t`

Type for result counters.

Note: A test group function or test with a fault sets its result with the fault count
set to SIZE_MAX to indicate a function-level fault.

See also:
- `lt_currentresult(void)` in Customization Helper Functions.
- `LT_GROUP(...)` notes on fault capture semantics and how function-level faults
  are represented.

```c
typedef struct
{ size_t pass;
  size_t fail;
  size_t fault;
  size_t injected_fail;
  size_t injected_fault;
} lt_result_t;
```
</details>

<details>
<summary>2.2 `lt_state_t`</summary>

### 2.2 `lt_state_t`

Type for maintaining the state of the orchestrator (main)
or a test function.

```c
typedef struct
{ size_t id;
  char *funcname;
  size_t current_level;
  size_t groupid;
  char *groupname;
  int isolation; // 0 none, 1 thread, 2 process.
  size_t category_id;
  size_t num_results_merged;
  size_t pass;
  size_t fail;
  size_t fault;
  size_t injected_fail;
  size_t injected_fault;
  size_t total_pass;
  size_t total_fail;
  size_t total_fault;
  size_t total_injected_fail;
  size_t total_injected_fault;
  lt_state_t parent;
  lt_state_t prev;
  lt_state_t next;
} lt_state_t;
```
</details>
</details>

<details>
<summary>3. Enums</summary>

## 3. Enums

<details>
<summary>3.1. `lt_exit_code_t`</summary>

### 3.1. `lt_exit_code_t`

Exit codes are grouped into classes:
- `LT_EXIT[_*]`  normal exit codes.
- `LT_TEST[_]*` test outcome codes.
- `LT_FATAL_USAGE[_*]` fatal usage codes (invalid arguments, invalid caller
   state, API misuse).
- `LT_FATAL_INTERNAL[_*]` fatal internal codes (assert/invariant/internal
   failures).
- `LT_FATAL_SYSTEM[_*]` fatal system codes (OS/runtime/resource failures).

Fatal codes indicate that the runner could not complete normal or test
execution.

`LT_FATAL_USAGE`, `LT_FATAL_INTERNAL`, and `LT_FATAL_SYSTEM` are
general codes for when a more specific code does not apply for the class.

```c
typedef enum
{
  // 0-99: Exit codes.
    LT_EXIT_OK = 0,
    
  // 0-99: Test outcome codes.
    LT_TEST_PASS = 0,
    LT_TEST_FAIL = 1,
    LT_TEST_FAULT = 2,
    LT_TEST_FAIL_FAULT = 3,

  // 100-199: Fatal usage codes.
  LT_FATAL_USAGE = 100,
    LT_FATAL_USAGE_INVALID_ARG = 101,
    LT_FATAL_USAGE_INVALID_STATE = 102,

  // 200-299: Fatal internal codes.
  LT_FATAL_INTERNAL = 200,
    LT_FATAL_INTERNAL_ASSERT = 201,
    LT_FATAL_INTERNAL_INVARIANT = 202,

  // 300-399: Fatal system codes.
  LT_FATAL_SYSTEM = 300,
    LT_FATAL_SYSTEM_OPEN = 301,
    LT_FATAL_SYSTEM_READ = 302,
    LT_FATAL_SYSTEM_WRITE = 303,
    LT_FATAL_SYSTEM_FORK = 304,
    LT_FATAL_SYSTEM_THREAD = 305
} lt_exit_code_t;
```
</details>

<details>
<summary>3.2. `lt_return_code_t`</summary>

### 3.1. `lt_return_code_t`

Return codes are for functions that return an integer (e.g., `int`) and
are grouped into classes:
- Success
- Compare
- Boolean
- `LT_INVALID[_*]` invalid usage codes (invalid arguments).
- `LT_SYSTEM[_*]` failed system codes (OS/runtime/resource failures).

`LT_INVALID` and `LT_SYSTEM`) are general codes for when a more specific
code does not apply for the class.

```c
typedef enum
{
  // Success
    LT_OK = 0,
    
  // Compare
    LT_LESS = -1,
    LT_EQUAL = 0,
    LT_GREATER = 1,
    
  // Boolean
    LT_FALSE = 0,
    LT_TRUE = 1,

  // -100 to -199: Invalid Usage.
    LT_INVALID = -100,
    LT_INVALID_ARG = -101,
    LT_INVALID_ARG_VERSION = -102,
    LT_INVALID_ARG_TOO_LONG = -103,

  // -300 to -399: Failed system call.
    LT_SYSTEM = -300,
    LT_SYSTEM_OPEN = -301,
    LT_SYSTEM_READ = -302,
    LT_SYSTEM_WRITE = -303,
    LT_SYSTEM_FORK = -304,
    LT_SYSTEM_THREAD = -305
} lt_return_code_t;
```
</details>
</details>

<details>
<summary>4. Macros for Limits</summary>

## 4. Macros for Limits

Maximum values for path length, filename length, and guard levels.

#define LT_MAX_PATH_LEN      ((size_t)4096)
#define LT_MAX_FILENAME_LEN  ((size_t)255)
#define LT_MAX_LEVEL         ((size_t)32)

Note: The limit of 32 levels in unlikely to be exceeded if there are 2 or
more `LT_GROUP` or `LT_TEST` macros at each level. It is expected that a level will generally have 2 or more per level.
</details>

<details>
<summary>5. Macros for the Orchestrator Function</summary>

## 5. Macros for the Orchestrator Function

Macros used to define or declare the Orchestrator (`main`) function

<details>
<summary>5.1. `LT_DECLARE_ORCHESTRATOR(funcname)[;]`</summary>

### 5.1. `LT_DECLARE_ORCHESTRATOR(funcname)[;]`

A semicolon is not allowed if the macro is followed by its definition `{...}` of the
orchestrator function; otherwise, it is required and indicates this is a declaration
and a forward-reference to the orchestrator function.

**funcname**:
- Token specifying `main`.

**Termination Exit Codes**:
- `LT_DECLARE_ORCHESTRATOR_ERROR`
</details>

<details>
<summary>5.2. `LT_INIT_ORCHESTRATOR(funcname, id, project, size_t maxparallel);`</summary>

### 5.2. `LT_INIT_ORCHESTRATOR(funcname, id, project, size_t maxparallel);`

**funcname**:
- Token specifying `main`.

**id**:
- A pointer to a string specifying only alphanumeric characters which is used
  to identify the orchestrator function.
- Default is `"o"` *if* `id` is NULL pointer or its string is empty.
- A short id (not exceeding 3 characters) is recommended.
- The id must be unique for the orchestrator and test group functions; a violation
  causes the test runner to terminate.

**project**:
- A token identifying the project.
- The token is used to generate a default report title if one is not set by the
  `LT_PARSE_ARGS(...)` macro.

**maxparallel**: Maximum number of `LT_GROUP` and `LT_TEST` macros that are
allowed to execute in parallel.

**Termination Exit Codes**:
- `LT_INIT_ORCHESTRATOR_ERROR`
</details>

<details>
<summary>5.3. `LT_PARSE_ARGS(size_t maxargs, char *customflags, char *defaultreportfilename);`</summary>

### 5.3. `LT_PARSE_ARGS(size_t maxargs, char *customflags, char *defaultreportfilename);`

**maxargs**:
- The maximum number arguments in the command line.
- The value must 2 or greater.
- The first 2 arguments and LiteTest flags are parsed by the macro.
- Additional arguments must be parsed by customization code.

**customflags**:
- A string of custom flags (e.g., "-l--file-Q").
- The macro causes the test runner to terminate if a non-LiteTest flag is not in the string.
- The actual parsing of these must be customization code.

**defaultreportfilename**:
- A string defining a default report file name without an extension. The extension
  is `.md` since the report uses Markdown Document formatting.
- The maximum length including a null terminator character is `MAX_FILENAME_LEN` (129),

**Termination Exit Codes**:
- `LT_ARG_ERROR`
- `LT_FLAG_ERROR`

See "Test Command Line" for details on command-line argument and flags.
</details>

<details>
<summary>5.4. `LT_OPEN_REPORT(char *title);`</summary>

### 5.4. `LT_OPEN_REPORT(char *title);`

**title**:
- A string defining the report title.
- If `title` is NULL or empty, a generated default report title
  "<project> Test Report" is used.
- The maximum length including a null terminator character is `MAX_TITLE_LEN` (129),

**Termination Exit Codes**:
- `LT_OPEN_ERROR`
</details>

<details>
<summary>5.5. `LT_WRITE_RESULT(gtm, char *category);`</summary>

### 5.5. `LT_WRITE_RESULT(gtm, char *category);`

**gtm**:
- A `LT_GROUP(...)` or `LT_TEST(,,,)` macro.

**category**:
- A pointer to a string with the name or description of the test category.
- The maximum length including a null terminator character is `MAX_CATEOGRY_LEN` (129).

**Termination Exit Codes**: `LT_WRITE_ERROR`.
</details>

<details>
<summary>5.6. `LT_CLOSE_REPORT(char *notes);`</summary>

### 5.6. `LT_CLOSE_REPORT(char *notes);`

**notes**:
- A string of note lines to append to the test report.
- Each note line must end with `'\n'` (newline).
- If `notes` is NULL or empty, there are no notes to append.
- The maximum length including a null terminator character is `MAX_NOTE_LEN` (10001).

**Termination Exit Codes**:
- `LT_CLOSE_ERROR`

The macro writes the totals, pre-defined explanatory notes, `notes`, notes from
the temporary notes file, and final summary line to the test report file, and then
closes the test report.
</details>

<details>
<summary>5.7. `LT_EXIT;`</summary>

### 5.7. `LT_EXIT;`

**Exit codes**:
- `LT_PASS` (0)
- `LT_FAIL` (1)
- `LT_FAULT` (2)
- `LT_FAIL_FAULT` (3)

**Termination Exit Codes**:
- `LT_EXIT_ERROR`
</details>
</details>

<details>
<summary>6. Macros for a Test Group Function</summary>

## 6. Macros for a Test Group Function

Macros used to define or declare a test group function.

<details>
<summary>6.1. `LT_DECLARE_GROUP(funcname)`</summary>

### 6.1. `LT_DECLARE_GROUP(funcname)`

**funcname**:
- Token specifying a function name other than `main`.

A semicolon is not allowed if the macro is followed by its definition `{...}` of the
test group function; otherwise, it is required and indicates this is a declaration
and a forward-reference to the test group function.

**Termination Exit Codes**:
- `LT_DECLARE_GROUP_ERROR`
</details>

<details>
<summary>6.2. `LT_INIT_GROUP(funcname, id, maxparallel)`</summary>

### 6.2. `LT_INIT_GROUP(funcname, id, maxparallel)`

**funcname**:
- The same token as the specified token for funcname in the preceding
  `LT_DECLARE_GROUP` macro defining the containing test group function.

**id**:
- A pointer to a string specifying only alphanumeric characters which is used to
  identify the test group function.
- Default is `"funcname"` *if* `id` is NULL pointer or its string is empty.
- A short id (not exceeding 3 characters) is recommended.
- `id` must be unique for the orchestrator and test group functions; a violation
  causes the test runner to terminate.

**maxparallel**:
- Maximum number of `LT_GROUP` and `LT_TEST` macros that are allowed
  to execute in parallel.

**Termination Exit Codes**:
- `LT_INIT_GROUP_ERROR`
</details>

<details>
<summary>6.3. `LT_RETURN`</summary>

### 6.3. `LT_RETURN`

**Termination Exit Codes**:
- `LT_RETURN_ERROR`
</details>
</details>

<details>
<summary>7. Macros to Execute a Test Group or Test</summary>

## 7. Macros to Execute a Test Group or a Test

- `LT_GROUP(funcname, id, [include], [isolation])[;]`
- `LT_TEST(expression, id, [include], [isolation])[;]`

A semicolon is not allowed if the macro is used as an argument to the
`LT_WRITE_RESULT` macro; otherwise, it is required.

**id**:
- A pointer to a string specifying only alphanumeric characters for the test group or test.
- The value must be unique within the containing orchestrator or test group function
- A short id (not exceeding 3 characters) is recommended or use the default.
- If `id` is a NULL pointer or its string is empty, default is `n`, where `n` is `1`
  for the first `LT_GROUP` or `LT_TEST` macro where `id` is NULL or empty, and incremented by 1 for each subsequent `LT_GROUP` and `LT_TEST` macro where `id`
  is a NULL pointer or its string is empty.
- See the `LT_ID` macro for obtaining the `id` for the next generated id.

**include**:
- A single character token or omit (defaults to `1`):
  - `0`   — Never execute. This is useful to disable a test (e.g., failing or
            faulting test for which the fix has been deferred).
  - `1`   — Always execute (e.g., smoke tests).
  - `2–9` — Execute only when the `-In` flag is specified in the test command line
            and n ≥ include.
  - `I`   — Execute only when the `-I` flag is specified in the test command line.
            This is useful for
            injecting a fail/fault for verifying behavior and report output if
            fails/faults were to occur. See also `LT_FAIL` and `LT_FAULT(type)`
            for simulating a fail or fault, respectively.

See "Test Command Line" for details on command line flags.

**isolation**:
- Single character token or omit (defaults to 0):
- `0` — Same thread.
- `1` — Separate thread.
- `2` — Separate process.

See "Isolation" in the LiteTest Runner Guide.

<details>
<summary>7.1. `LT_GROUP(funcname, id, [include], [isolation])[;]`</summary>

### 7.1. `LT_GROUP(funcname, id, [include], [isolation])[;]`

**Termination Exit Codes**:
- `LT_GROUP_ERROR`
</details>

<details>
<summary>7.2. `LT_TEST(expression, id, [include], [isolation])[;]`</summary>

### 7.2. `LT_TEST(expression, id, [include], [isolation])[;]`

**Termination Exit Codes**:
- `LT_TEST_ERROR`
</details>
</details>

<details>
<summary>8. Macros for Concurrent Blocks</summary>

## 8. Macros for Concurrent Blocks

<details>
<summary>8.1. `LT_BEGIN_CONCURRENT(blockname)`</summary>

### 8.1. `LT_BEGIN_CONCURRENT(blockname)`

**blockname**:
- Token specifying the name of the block.
- Token must be the same as for the subsequent matching `LT_END_CONCURRENT(blockname)`.

**Termination Exit Codes**:
- `LT_BEGIN_GROUP_ERROR`
</details>

<details>
<summary>8.2. `LT_END_CONCURRENT(blockname);`</summary>

### 8.2. `LT_END_CONCURRENT(blockname);`

**blockname**:
- Token specifying the name of the block.
- Token must be the same as for the preceding matching `LT_BEGIN_CONCURRENT(blockname)`.

**Termination Exit Codes**:
- `LT_END_GROUP_ERROR`
</details>
</details>

<details>
<summary>9. Macros for Versioning</summary>

## 9. Macros for Versioning

<details>
<summary>9.1. `LT_RUNNER_VERSION`</summary>

### 9.1. `LT_RUNNER_VERSION`

**Value**:
- LiteTest Runner's version as a literal string of type `char[n]`, where `n` is
  between 5 and 9 (including
  the terminating null character).
- Format: `M.m.p`, where `M`, `m`, and `p` are one or two digits.
- `M` is the major version, `m` is the minor version, and `p` is the patch version.

The major version is incremented for major additions, removal of deprecated features, or unavoidable incompatible API changes.

The minor version is incremented for backward-compatible additions or deprecating features.

The patch version is incremented for bug fixes or internal improvements.

**Examples**:
- `LT_RUNNER_VERSION` → `"1.0.9"`
- `LT_RUNNER_VERSION` → `"1.3.11"`
- `LT_RUNNER_VERSION` → `"12.05.18"`
</details>

<details>
<summary>9.2. `LT_VERSION_MAJOR(v)`</summary>

### 9.2. `LT_VERSION_MAJOR(v)`

**v**: pointer to a version string.

**Value**:
- The major version in `v` cast to `int`.
- Value is `LT_INVALID_VERSION` (`(int)-2`) *if* `v` is an invalid version string.

**Examples**:
- `LT_VERSION_MAJOR("5.0.9")` → `(int)5`
- `LT_VERSION_MAJOR("5.000.9")` → `LT_INVALID_VERSION`
</details>

<details>
<summary>9.3. `LT_VERSION_MINOR(v)`</summary>

### 9.3. `LT_VERSION_MINOR(v)`

**v**: pointer to a version string.

**Value**:
- The minor version in `v` cast to `int`.
- Value is `LT_INVALID_VERSION` (`(int)-2`) *if* `v` is an invalid version string.

**Examples**:
- `LT_VERSION_MINOR("5.00.9")` → `(int)0`
- `LT_VERSION_MINOR("5.1.001")` → `LT_INVALID_VERSION`
</details>

<details>
<summary>9.4. `LT_VERSION_PATCH(v)`</summary>

### 9.4. `LT_VERSION_PATCH(v)`

**v**: pointer to a version string.

**Value**:
- The patch version in `v` cast to `int`.
- Value is `LT_INVALID_VERSION` (`(int)-2`) *if* `v` is an invalid version string.

**Examples**:
- `LT_VERSION_PATCH("5.0.12")` → `(int)12`
- `LT_VERSION_PATCH("5.000.9")` → `LT_INVALID_VERSION`
</details>

<details>
<summary>9.5. `LT_VERSION_NUM(v)`</summary>

### 9.5. `LT_VERSION_NUM(v)`

**v**: pointer to a version string.

**Value**:
- Representation of the version `v` cast to `int`.
- Value is `LT_INVALID_VERSION` (`(int)-2`) *if* `v` is an invalid version string.

Form: MMmmpp for comparisons, e.g., 10000 for
version 1.0.0, 10200 for version 1.2.0, or 11212 for version 1.12.12.

**Examples**:
- `LT_VERSION_NUM("1.0.9")` → `(int)0x010009`
- `LT_VERSION_NUM("2.5.3")` → `(int)0x020503`
</details>

<details>
<summary>9.6. `LT_VERSION_HEX(v)`</summary>

### 9.6. `LT_VERSION_HEX(v)`

**v**:
- Pointer to a version string.

**Value**:
- Hex representation of version `v` cast to `int`.
- Value is `LT_INVALID_VERSION` ((int)`-2`) *if* `v` is an invalid version string.

Hexadecimal form 0xMMmmpp for display/debugging, e.g.,
0x010000 for version 1.0.0, 0x010200 for version 1.2.0,
or 0x011212 for version 1.12.12.

**Examples**:
- `LT_VERSION_HEX("1.0.9")` → `0x010009`
- `LT_VERSION_HEX("2.5.3")` → `0x020503`
</details>

<details>
<summary>9.7. `LT_VERSION_CMP(v1, v2)`</summary>

### 9.7. `LT_VERSION_CMP(v1, v2)`

**v1**:
- Pointer to a version string.

**v2**:
- Pointer to a version string.

**Value**:
- Integer (`int`) result comparing version `v1` to `v2`:
  - `LT_EQUAL` (`(int)0`) — equal
  - `LT_LESS` (`(int)-1`) — `v1` is less than `v2`
  - `LT_GREATER` (`(int)1`) — `v1` is greater than `v2`
  - `LT_INVALID_VERSION` (`(int)-2`) — invalid `v1` or invalid `v2`
- Leading zeros in `M`, `m`, and `p` are ignored during comparison.

**Examples**:
- `LT_VERSION_CMP(LT_RUNNER_VERSION, "1.10.0")` → `LT_GREATER` (*if* `LT_RUNNER_VERSION`
  is `"1.10.6"`)
- `LT_VERSION_CMP(LT_RUNNER_VERSION, "1.10.0")` → `LT_LESS` (*if* `LT_RUNNER_VERSION`
  is `"1.8.0"`)
- `LT_VERSION_CMP(LT_RUNNER_VERSION, "1.10.0")` → `LT_EQUAL` (*if* `LT_RUNNER_VERSION`
  is `"1.10.0"`)
- `LT_VERSION_CMP("1.10.0x", "1.10.0")` → `LT_INVALID_VERSION`
- `LT_VERSION_CMP("1.10.0", "1.10y.0")` → `LT_INVALID_VERSION`
</details>
</details>

<details>
<summary>10. Functions for Customization</summary>

## 10. Functions for Customization

<details>
<summary>10.1. `LT_PRINT_ERR_HELP(char *err, char help)`</summary>

### 10.1. `LT_PRINT_ERR_HELP(char *err, char help)`

Print err and help text to stdout.
- `err` is prefixed with `lt_err_prefix()`.
- Help text is formed using `lt_usage()` and `lt_help()`.

**err**
- Pointer to error string.

**help**
- 0: don't print help text.
- non-zero: print help text.

Note: Use `lt_set_err_prefix()` to set the prefix.

Note: Use `lt_set_usage()` and/or `lt_set_help()` to define the help text.
</details>

<details>
<summary>10.2. `int lt_funcname(char *funcname, size_t outlen)`</summary>

### 10.2. `int lt_funcname(char *funcname, size_t outlen)`
</details>

<details>
<summary>10.3. `int lt_print_note(const char *notes)`</summary>

### 10.3. `int lt_print_note(const char *notes)`

Opens a temporary file if not already open and writes the notes to the temporary file.

**notes**:
- A string of note lines to write to the temporary file.
- Each note line must end with `'\n'` (newline).
- If `notes` is NULL or empty, the temporary file is removed if it exists.
- The maximum length including a null terminator character is `MAX_NOTE_LEN` (10001).

**Return**:
- `LT_SUCCESS`
- `LT_NOTES_REMOVED`
- `LT_NOTES_OPEN_ERROR`
- `LT_PRINT_NOTE_ERROR`
</details>

<details>
<summary>`void lt_current_time(char *current_time, size_t size)`</summary>

### `void lt_current_time(char *current_time, size_t size)`

Get the current time as a formatted string.

**current_time**:
- Buffer to store the formatted time string.

**size** Size of the buffer.

Note: On error, current_time is set to "unknown time".
</details>

<details>
<summary>Customization: Get and set.</summary>

### Customization: Get and set.

`char *lt_executable_name(void)`
`void lt_set_executable_name(char *en)`
`char *lt_default_dirpath(void)`
`void lt_set_default_dirpath(char *dp)`
`char *lt_err_prefix(void)`
`void lt_set_err_prefix(char *pe)`
`char *lt_args_options(void)`
`void lt_set_args_options(char *ao)`
`char *lt_usage(void)`
`void lt_set_usage(char *u)`
`char *lt_help(void)`
`void lt_set_help(char *h)`
</details>

<details>
<summary>Customization Helper Functions</summary>

### Customization Helper Functions

`size_t lt_currentlevel(void)`
`lt_result_t lt_currentresult(void)`
`lt_total_t lt_currenttotal(void)`
`size_t lt_maxparallel(size@_t level)`
`size_t lt_currentparallel(void)`
`int lt_isisolated(void)`
`int lt_isthreadisolated(void)`
`int lt_isprocessisolated(void)`
`size_t lt_groupid(void)`
`char *lt_groupname(void)`

`char *lt_project(void)`
`size_t lt_maxargs(void)`
`char *lt_title(void)`
`size_t lt_categoryid(void)`
`char *lt_category(void)`
`char *lt_funcname(void)`
`char *lt_notes(void)`
`char *lt_assertexpression(void)`
`char lt_inject(void)`
`char lt_isolation(void)`
`char lt_orchestrator(void)`
`char lt_testfunction(void)`
`char lt_assert(void)`

`char *lt_dirpath(void)`
`char *lt_filepath(void)`
`char` *lt_filename(void)`

**Return**: 1 true, 0 false
`int lt_isfilename(char *name)`

**Return**: 1 true, 0 false, -1 not a directory path.
`int lt_isreaddirpath(char *path)`
`int lt_iswritedirpath(char *path)`

**Return** 1 true, 0 false, -1 not a file path.
`int lt_isreadfilepath(char *path)`
`int lt_iswritefilepath(char *path)`
</details>
</details>

<details>
<summary>11. Test Command Line</summary>

## 11. Test Command Line

TODO.
</details>

<details>
<summary>12. Output and Golden Files</summary>

## 12. Output and Golden Files

Named output files are captured as output files using their name.

A copy of `stdout` is captured as an output file named `stdout-<uid>` and a copy of
`stderr` is captured as an output file named `stderr-<uid>`.

`<uid>` is a unique id string for each captured output file within a test run. It
is used to avoid filename collisions when the same output name appears multiple times.

Temporary files are not captured.

A captured output file is copied to `tests/output/` subdirectory of the repository
root directory:
- If the output file name has the form <name>.<ext>, the `tests/output/` file is named
  <name>-<uid>.ext.
- If the output file name has the form <name> (with no extension), the `tests/output/`
  file is named <name>-<uid>.

A metadata file (in Markdown Document format) for each output file is also written
to `tests/output/`:
- If the output file name has the form <name>.<ext>, the `tests/output/` metadata file
  is named <name>-<uid>.ext.md.
- If the output file name has the form <name> (with no extension), the `tests/output/`
  file is named <name>-<uid>.md.

An output file and its metadata file in `tests/output/` may be copied (promoted) to the
`tests/golden/` subdirectory of the repository root directory. See the following section.

<details>
<summary>12.1. Golden Files</summary>

## 12.1. Golden Files

A metadata golden file having a name with the form <name>.<ext> applies to all
golden files named <name>-<uid>.ext and can be added manually or by customization
code added to the test runner.

A metadata golden file having a name with the form <name>.md applies to all golden
files named <name>-<uid> with no extension and can be added manually or by customization
code added to the test runner.

Golden files (located in the `tests/golden/`) are handled as follows:

- If the corresponding golden file with the same name does not exist,
  - If a metadata golden file <name>.ext or <name> exists and contains the line
    `##MATCH##`, comparison is skipped and a match is forced. If it contains
     the line `##MISMATCH##`, comparison is skipped and a mismatch is forced.
   - Otherwise, the output file is automatically
     copied (promoted) into the `tests/golden` directory and a match forced.
   - The test report notes that the file was promoted.
- If the corresponding golden file exists and contains the line `##MATCH##`, comparison
  is skipped and a match is forced.
- If the corresponding golden file exists and contains the line `##MISMATCH##`,
  comparison is skipped and a mismatch is forced.
- Otherwise, the output file is compared with its existing golden file of the same name
  in the `tests/golden` directory to determine whether they match.

If an output file does not match its golden file but inspection determines
the output is correct, update the golden file with a copy of the output.
Alternatively, remove the golden file so that the next run will
automatically promote the output.
</details>

<details>
<summary>12.2. Rationale for Design</summary>

### 12.2. Rationale for Design

LiteTest uses a parallel `tests/golden` directory with golden files that keep
the exact same filename as their corresponding test output. This design avoids
the common problems found in extension‑based naming schemes:

- **No filename collisions**
  Different outputs such as `foo.c` and `foo.h` remain distinct (`foo-<uid>.c` vs.
  `foo-<uid>.h`) instead of collapsing into a single `foo.golden`.

- **No special‑case rules**
  The golden filename is always identical to the output filename.

- **Preserves file type information**
  Because the original extension is retained, it is immediately clear whether a
  golden file contains text, Markdown Document, JSON, HTML, binary data, or
  anything else.

- **Simpler mental model**
  Developers do not need to remember naming conventions or extension‑replacement
  rules. Golden files simply live in a parallel directory and share the same
  name as the output they validate.
  </details>
  </details>
