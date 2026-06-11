# LiteTest Framework Reference

This document defines the internal framework of LiteTest, a lightweight 
Application Programming Interface (API) and framework for defining, running,
and reporting tests in C/C++ projects.

Copyright (c) 2026 paulsinclair51.  
SPDX-License-Identifier: MIT.

<details>
<summary>Click to view</summary>

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

### Documentation

<details>
<summary>Click to view</summary>

For user documentation of the LiteTest API, see:

- **README.md** — Introduction and quick summary start to LiteTest.
- **LiteTest User Guide** — Concepts, workflow, examples.
- **LiteTest API Reference** — Public API types, enums, macros, and functions.

For contributor and maintainer documentation of the LiteTest framework,
additionally see:

- **LiteTest Contributor Guide** — Versioning, branching, testing, documentation rules.  
- **LiteTest Framework Guide** — Concepts, workflow, examples.
- **LiteTest API Reference** — Private (internal) framework types, enums, macros, functions, etc.

See [Repository Layout](#repository-layout) for locations of the above and the
LiteTest directories and files,
</details>

## Table of Contents

<details>
<summary>Click to view</summary>

- [1, Overview](#overview)
- [2, Internal Symbols Defined in `litetest.h`](#internal-symbols-defined-in-litetesth)
- [Repository Layout](#repository-layout)
- [Glossary](#glossary)
</details>

## 1, Overview

<details>
<summary>Click to view</summary>

This document is organized in a top‑down order (in contrast to the bottom‑up
order in `litetest.h` and `litetest.c`). This allows contributors to begin with
high‑level behavior and drill down into lower‑level detail.

In this document, a *symbol* refers to any named entity in the LiteTest framework, including:

- typedefs
- structs
- enums and enum values
- macros
- variables an
- functions

#### Public and Internal Name Conventsions

Any framework names that are public and visible to LiteTest API users are prefixed
with `lt_...` (typically, all lowercas) or `LT_..` (typically, all uppercase).

Any framework names that are internal (but technically visible to LiteTest API users)
follow the pattern `litetest_..._internal_t`, `litetest_..._internal`, or `LITETEST_..._INTERNAL`.
These names should not be referenced by API users.

In general, users of the API should not define names prefixed with `lt_`, `LT`, `litetest_`,
or `LITETEST`, or refereence names prefixed with `litetest_` or `LITETEST_`.

#### Why Internal Symbols Appear in the Header

Some internal symbols must appear in `litetest.h` because LiteTest relies on
macros that expand into code requiring access to internal types, constants, or
helper functions. These symbols must be visible to user code for the macros to
compile correctly, even though they are not intended for direct use.

Their visibility is an implementation requirement, not part of the public API
contract. Users should treat all such symbols as internal and avoid depending on
them, as they may change at any time.
</details>

## 2. Symbols Defined in `litetest.h`

<details>
<summary>Click to view</summary>

These may be used internally by `litetest.h` or `litestest.c`.

### 2.1. Types

<details>
<summary>Click to view</summary>

(Placeholder)

---
</details>

### 2.2. Structs

<details>
<summary>Click to view</summary>

(Placeholder)

---
</details>

### 2.3. Enums and Enum Values

<details>
<summary>Click to view</summary>

(Placeholder)

---
</details>

### 2.4. Global Variables

<details>
<summary>Click to view</summary>

(Placeholder)

---
</details>

### 2.5. Macros

<details>
<summary>Click to view</summary>

(Placeholder)

---
</details>

### 2.6. Functions

<details>
<summary>Click to view</summary>

(Placeholder)

These functions may be static, static inline, or (by default) extern.

---
</details>
</details>

## 3. Symbols Defined in `litetest.c`

<details>
<summary>Click to view</summary>

These symbols are local to `litetest.c` unless speified or defaulting to
extern. The names for symbols that local do not have to conform to the
internal name conventions and more natural names may be used.

### 3.1. Types

<details>
<summary>Click to view</summary>

(Placeholder)

---
</details>

### 3.2. Structs

<details>
<summary>Click to view</summary>

(Placeholder)

---
</details>

### 3.3. Enums and Enum Values

<details>
<summary>Click to view</summary>

(Placeholder)

---
</details>

### 3.4. Global Variables

<details>
<summary>Click to view</summary>

(Placeholder)

---
</details>

### 3.5. Macros

<details>
<summary>Click to view</summary>

(Placeholder)

---
</details>

### 3.6. Functions (declared as a forward reference) in `litetest.h`

<details>
<summary>Click to view</summary>

These fucctions are referenced internally by `litetest.h` but defined in `litetest.c`.
These functions are (by default) extern and must conform to the internal name conventions.

(Placeholder)

---
</details>

### 3.7. Functions (not declared in `liteTest.h`)

<details>
<summary>Click to view</summary>

These functions are local to `litetest.c` and defined as static.
Since these are local, these names do not have to conform to the
internal name conventions and more natural names may be used.

(Placeholder)

---
</details>
</details>

## 4. Execution Engine

<details>
<summary>Click to view</summary>

(Placeholder for execution helpers.)

---
</details>

## 5. Signal Handling

<details>
<summary>Click to view</summary>

(Placeholder for signal guard helpers.)

---
</details>

## 6. Process Management

<details>
<summary>Click to view</summary>

(Placeholder for fork/exec/wait logic.)

---
</details>

## 7. Thread Management

<details>
<summary>Click to view</summary>

(Placeholder for pthread logic.)

---
</details>

## 8. File and Path Support

<details>
<summary>Click to view</summary>

(Placeholder for filesystem support helpers.)

---
</details>

## 9. Matching and Comparison Support

<details>
<summary>Click to view</summary>

(Placeholder for comparison support helpers.)

---
</details>

## 10. Environment Support

<details>
<summary>Click to view</summary>

(Placeholder for environment support helpers.)

---
</details>

## Repository Layout

GitHub repository: `paulsinclair51/LiteTest`

Repository layout (listing core files):

<details>
<summary>Click to view</summary>

```text
LiteTest/
|- .github/
|  \- workflows/
|     \- ci.yml
|- README.md
|- LICENSE
|- Makefile
|- build_test_litetest.ps1
|- build/
|- docs/
|  \- LiteTest_API_User_Guide.md
|  \- LiteTest_API_Reference.md
|  \- LiteTest_Contributor_Guide.md
|  \- LiteTest_Framework_Guide.md
|  \- LiteTest_Framework_Reference.md
|- examples/
|- include/
|  \- litetest.h
|- reports/
|  |- litetest_test_report-I.txt
|  \- litetest_test_report.txt
|- scripts/
|- src/
|  \- litetest.c
|- tests/
|  |- test_litetest.c
|  |- test_orchestrator.c
|  |- test_guard1.c
|  \- test_guard2.c
```

Use this as a reference when adapting LiteTest into your own project structure.
</details>

## Glossary

<details>
<summary>Click to view</summary>

- `API`: Application Programming Interface.
- `category`: A labeled set of `LT_GROUP` and `LT_TEST` macro whose combined
             results are written by `LT_WRITE_RESULT` to the report with a
             specified category name.
- `control file`: A previously generated file that can be compared to a newly
                  generated file for differences (typically, if there are
                  differences (other than expected differences like a timestamp
                  change) this indicates a failure of the test. In some cases,
                  the control file is out-of-date and needs to be replaced
                  by promoting the new file to be the control file.
- `customization support functions`: API functions provided to support
   customizing the orchestrator and test group functions.
   See [Customization Support Functions](#customization-support-functions).
- `default report filename`: The report filename LiteTest uses when only a
  directory path (or no `PATH`) is provided.
- `executable`: The compiled test program that runs the orchestrator and test
  functions.
- `fail`: A counted test failure where the LT_TEST or LT_INJECT_TEST
   expression evaluates to false (i.e., zero).
- `fault`: A counted runtime fault captured by LiteTest guards (for example,
  invalid memory access).
- `Concurrent block`: A set of tests (LT_TEST and LT_INJECT_TEST macros)
   bracketed by `LT_BEGIN_CONCURRENT` and `LT_END_CONCURRENT;`.
- `group': see `test group`.
- `guard`: The protection mechanism used to catch runtime faults and continue
  test execution.
- `guard level`: The nesting depth of active guards while test groups and tests run.
- `inject mode (-i)`: Optional command-line flag that enables an LT_INJECT_TEST to
   be executed.
- `isolation`: Execution mode for LT_GROUP, LT_TEST, or LT_INJECT_TEST.
  `0` = same thread, `1` = separate thread, `2` = separate process.
- `maxargs`: The maximum number of command-line arguments accepted by
  orchestrator parsing. Optional arguments may be omitted.
  `LT_PARSE_ARGS` handles the first two arguments (executable name and optional
  `PATH`) when provided. Any additional arguments must be parsed by custom code
  added to the orchestrator.
- `maxparallel`: Upper bound on concurrent LT_GROUP, LT_TEST, LT_INJECT_TEST. Value set in
   LT_INIT_ORCHESTRATOR and LT_GROUP macros.
- `notes`: Optional text for LT_CLOSE_REPORT to append to the report before closing it.
- `orchestrator`: The `main` function that initializes LiteTest, runs groups or tests,
  and writes report output.
- `pass`: A counted successful test where the LT_TEST or LT_INJECT_TEST
   expression evaluates to true (i.e., non-zero).
- `PATH`: Optional command-line output destination; can be a report file path
  or directory path.
- `process isolation`: Isolation mode where a test group or test runs in a
  separate process.
- `project`: Project identifier used in orchestrator initialization and default
  report naming.
- `test group`: a grouping of `LT_TEST` and, optionally, `LT_GROUP` macros.
- `test group function`: A function declared with the `LT_DECLARE_GROUP` macro
   that contains 'LT_TEST' and 'LT_GROUP` macros.
- `thread isolation`: Isolation mode where a test/assert call runs in a
  separate thread.
- `test case`: This term is not used in LiteTest. In some contexts, it means
   a single individual test and, in other contexts, a set of tests, In LiteTest, the former
   is referred to as a test (or test expression) and the latter, as a test group.
- `test`: see test expression.
- `test expression`: An expression passed to an `LT_TEST` macro that can be cast
   to `int`; `0` means fail and a nonzero value means pass. The expression
   typically is a function call or contains function calls. A function could
   be in the project being tested or a testing function to implement the test.
- `testing artifact`: typically, a file generated by the test executable (e.g.,
   a test report) but also stdout and stderr output plus anything that is captured
   by the test executable or the LiteTest framework.
- `testing function`; a user written function to implement or help implement a
   test expression.
- `test support functions`: API functions provided to simplifying writing
   tests. See [Test Support Functions](#test-support-functions).
- `title`: Optional report header text provided when opening the report.
</details>
