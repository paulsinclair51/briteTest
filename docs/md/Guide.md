[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Latest Release](https://img.shields.io/github/v/release/paulsinclair51/briteTest?display_name=tag)](https://github.com/paulsinclair51/briteTest/releases)
[![CI](https://github.com/paulsinclair51/briteTest/actions/workflows/ci.yml/badge.svg)](https://github.com/paulsinclair51/briteTest/actions/workflows/ci.yml)

![briteTest Logo](/docs/branding/Guide.png)

#### Version: v1.0.0

briteTest is a lightweight, easy-to-use C/C++ framework for running unit and
command-line tests focused on clarity and reliability. It provides a simple
macro-based Runner API with customization macros and functions, a function-based Test API, fault-tolerant execution, clear reporting, comprehensive documentation,
and no external dependencies.

#### Copyright (c) 2026 Paul Sinclair

<details>
<summary><strong>License</strong></summary>

### License

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
<summary><strong>Preface</strong></summary>

## Preface

This document is intended for user and contributors who need guidance on using
briteTest including concepts and a quick start example. This also serves as the
`<repo>/README.md` for briteTest.

briteTest provides a Runner API and a Test API, each implemented with a single
`.h` / `.c` pair with no external dependencies and requiring only a POSIX.1‑2001
environment and a C99‑compliant compiler.

For a list of other documents and the repository layout, see
the Documentation Guide.

For a glossary of terms, see the Glossary Reference.

A printer-friendly PDF file for this document is available.

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;Document Version History</summary>

### Document Version History

| Version | Date | Comment | Author/Editor |
|----------|------|---------|---------------|
| v1.0.0 | 2026‑06‑11 | Initial version. | Paul Sinclair |
</details>
</details>

<details>
<summary><strong>Table of Contents</strong></summary>

## Table of Contents

1. [**Introduction**](#1-introduction)<br>
   1.1. [Key Strengths](#11-key-strength)<br>
   1.2. [Quick Start](#12-quick-start)<br>
   1.3. [Requirements](#13-requirements)<br>
   1.4. [Installation](#14-installation)<br>

2. [**Contributing**](#2-contributing)<br>
   2.1. [For Public Users](#21-for-public-users)<br>
   2.2. [For Contributors](#22-for-contributors)<br>

3. [**Runner Framework and API**](#3-test-runner-framework-and-api)<br>
   3.1. [What the Runner Framework and API Does](#31-what-the-runner-framework-and-api-does)<br>

4. [**Running Tests**](#4-running-tests)

5. [**Report Generation**](#5-report-generation)

6. [**Customization**](#6-customization)<br>

7. [**Test Report**](#7-test-report)

8. [**Advanced Features and Topics**](#8-advanced-features-and-topics)

9. [**Test Expressions**](#9-test-expressions)

10. [**Setup and Teardown**](#10-setup-and-teardown)

11. [**Test Groups**](#11-test-groups)

12. [**1Concurrent Tests**](#12-concurrent-tests)

13. [**Isolation**](#13-isolation)<br>

14.  [**Test API**](#14-test-api)<br>
[14.1 File Functions](#141-file-functions)<br>
[**14.2 Compare Functions**](#142-compare-functions)
</details>

<details>
<summary><strong>1. Introduction</strong></summary>

## 1. Introduction

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;1.1. Key Strengths</summary>

### 1.1. Key Strengths

- Lightweight design — minimal files, minimal API surface, easy to embed.
- Macro‑based Runner API — simple orchestration with predictable control flow.
- Function‑based Test API — tests are just C functions, easy to organize and debug.
- Fault‑tolerant execution — protects the test suite from crashes and undefined
  behavior.
- Parallel and concurrent test execution,
- Clear reporting — readable summaries of passes, failures, and faults.
- Pure C implementation.
- Minimal footprint (single header + source cor the ).
- Optional process‑isolated execution.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;1.2. Quick Start</summary>

### 1.2. Quick Start

A test executable consists of your tests as C/C++ expressions/functions, and the
orchestrator and test group functions you write using the Runner API that
manages the execution.

1. Copy 'runnerapi.h' and 'runnerapi.c' to your current directory:

```sh
cp /path/to/runnerapi.h .
cp /path/to/runnerapi.c .
```

2. Create a file named `test_quick.c` in the same directory.

3. Copy and paste the code into `test_quick.c`:

<details>
<summary>💻 Copy</summary>

```c
#include "runnerapi.h"

// A simple test group function.

static RA_DECLARE_GROUP(test_quick)
{
  RA_INIT_GROUP(test_quick, 1);

  int a = 2;
  int b = 2;

  // 4 test assertions.
  RA_TEST(a == b, , 0);        // Pass
  RA_TEST(a + b == 4, ,  0);    // Pass
  RA_TEST(a - b == 1, , 0);    // Fail
  RA_TEST(RA_FAULT(1), , 0);   // Fault

  RA_RETURN;
}

// A simple orchestrator (main) function.

RA_DECLARE_ORCHESTRATOR(main)
{
  RA_INIT_ORCHESTRATOR(main, quick, 1);
  RA_PARSE_ARGS(2, "quick_test_report.txt");
  RA_OPEN_REPORT("Test Quick Report");

  // Single test category.
  RA_WRITE_RESULT(RA_GROUP(test_quick), "Quick tests");

  RA_CLOSE_REPORT("Note: This report is a very simple examplexx.\n"
                  "Note: Multiple test categories can be added using multiple\n"
                  "      test functions.\n"
                  "Note: Orchestrator (`main`) and test functions can be placed in\n"
                  "      individual modules (.c files).\n"
                  "Note: Parameters can be set to run tests in parallel, isolate\n"
                  "      a test to a separate thread or process, etc.\n"
                  "Note: The expression for RA_TEST can reference functions to\n"
                  "      provide a more complex test. A non-zero result indicates\n"
                  "      pass and a zero result indicates fail. If a fault occurs\n"
                  "      executing the expression, it is detected and counted in\n"
                  "      the report as a fault.\n"
                  "Note: Larger projects can place files in a more conventional\n"
                  "      layout (e.g., `include/` and `src/`, but this example keeps\n"
                  "      everything in your current directory for simplification.\n"
                  "Note: See root README.md for for additional API features.\n");
  RA_EXIT;
}
```

</details>

4. Build the executable `test_quick` in your current directory:

```sh
cc -std=c99 -Wall -Wextra -o test_quick test_quick.c runnerapi.c
```

5. Run it:

```sh
./test_quick
```

6. View `quick_test_report.txt` in your current directory:

```sh
less quick_test_report.txt   # Press 'q' to quit
```

<details>
<summary>💻Example of the Report </summary>
Example of the report:

```text
Test Report
                             Pass   Fail     Fault
--------------------------------------------------
1. Orchestrator                 4
2. Guard 1 and 2                6
--------------------------------------------------
                       Total    10
```

</details>
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;1.3. Requirements</summary>

### 1.3. Requirements

Supported compilers, C standard level, and any platform notes.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;1.4. Installation</summary>

### 1.4. Installation

How to add the Runner API to your project, including copying the header, adding the
source file, or integrating via your build system.
</details>
</details>

<details>
<summary><strong>2. Contributing</strong></summary>

## 2. Contributing

briteTest welcomes feedback and contributions from the community. This section
explains how to engage with the project based on your interest level.

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;2.1. For Public Users</summary>

### 2.1. For Public Users

If you use briteTest and want to provide feedback, ask questions, or suggest features:

**Use [GitHub Discussions](../../discussions)**

- **Ask questions** about using briteTest
- **Suggest features** and improvements
- **Report bugs** and share workarounds
- **Share examples** and best practices

GitHub Discussions is the public engagement channel. All feedback is welcome and
will be reviewed by the maintainers.

**Follow releases:**

Subscribe to [releases](../../releases) to get notified about new versions and
improvements.

</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;2.2. For Contributors</summary>

### 2.2. For Contributors

To contribute code or documentation to briteTest:

1. **Request contributor access** via [GitHub Discussions](../../discussions)
   or contact the maintainers
2. **Review** the [Contributor Guide](./Contributor_Guide.md) for detailed
   requirements on:
   - Branching model and workflow
   - Coding standards
   - Documentation guidelines
   - Testing requirements
   - Pull request process

3. **Add to contributors list** — Once approved, you'll be added to
   `config/contributors.md` with one of these roles:
   - **C** (Contributor): Can create branches and submit changes
   - **R** (Reviewer): Can also review pull requests
   - **A** (Approver): Can merge changes and manage releases

**Pull requests are internal to contributors** — The development workflow
is visible only to contributors. Use GitHub Discussions for public feedback
on features or issues.

</details>
</details>

<details>
<summary><strong>3. Runner Framework and API</strong></summary>

## 3. Runner Framework and API

The Runner Framework (implemented using the Runner API) executes all test
expressions (that implement the tests), aggregates results, and produces
the report. This is the framework used by your test executable.

The Runner API provides typedefs, enums, macros, and functions for writing
tests. Developers use this API to express expected behavior, group related
tests, and define optional setup/teardown logic.

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.1. What the Runner Framework and API Does</summary>

### 3.1. What the Runner Framework and API Does

The Runner framework coordinates test execution from the orchestrator down to
individual test groups. It initializes the run, applies include and
concurrency settings, executes the requested groups, captures pass/fail/fault
results, and writes the final report.

The Runner API provides the macros and helper types used to define the
orchestrator, declare test groups, control execution flow, and handle fault
detection and reporting.
</details>
</details>

<details>
<summary><strong>4. Running Tests</strong></summary>

## 4. Running Tests

How to invoke the runner from `main()`, including optional parameters such as
output paths or configuration flags.
</details>

<details>
<summary><strong>5. Report Generation</strong></summary>

## 5. Report Generation

How briteTest collects pass/fail information and formats it for output.
</details>

<details>
<summary><strong>6. Customization</strong></summary>

## 6. Customization

Notes that you can build your own runner logic if you need custom ordering,
filtering, or integration behavior.
</details>

<details>
<summary><strong>7. Test Report</strong></summary>

## 7. Test Report

Describes the structure of the test report, failures, optional details, and
how to consume it in tooling or CI.
</details>

<details>
<summary><strong>8. Advanced Features and Topics</strong></summary>

## 8. Advanced Features and Topics

*Filtering tests and custom report writers are available in the User Guide.*
</details>

<details>
<summary><strong>9. Test Expressions</strong></summary>

## 9. Test Expressions

How to write a test expression for `RA_TEST(expr)` and how expressions are
evaluated.
</details>

<details>
<summary><strong>10. Setup and Teardown</strong></summary>

## 10. Setup and Teardown

Optional per‑group or per‑test initialization and cleanup helpers.
</details>

<details>
<summary><strong>11. Test Groups</strong></summary>

## 11. Test Groups

How to organize related tests into groups for readability and logical
structure.
</details>

<details>
<summary><strong>12. Concurrent Tests</strong></summary>

## 12. Concurrent Tests

How to mark tests as concurrent and how Runner Framework handles parallel execution
safely.
</details>

<details>
<summary><strong>13. Isolation</strong></summary>

## 13. Isolation

Isolation controls how much separation is used when running tests.

- **Same-thread execution** is the default and has the lowest overhead.
- **Thread-isolated execution** keeps tests separated without switching to a
  separate process.
- **Process-isolated execution** provides the strongest containment for
  faults, crashes, aborts, and other disruptive failures.

Use the lightest mode that still gives you the safety you need for the code
under test.
</details>

<details>
<summary><strong>14. Test API</strong></summary>

## 14. Test API

The Test API provides macros and functions for writing tests. Developers use
this API to express expected behavior, group related tests, and define optional
setup/teardown logic.

The Test API also includes execution/runtime, filesystem/path, environment,
process-result, string/text, extended file operation, JSON data extraction,
and resource management helpers.

See the Test Reference for a complete list of helpers provided by the API.

The following two sections provide examples of file and compare functions.

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;14.1. File Functions Examples</summary>

### 14.1. File Functions Examples

These helpers cover file and directory-related functions in the Test API.

Examples include:

- Filesystem predicates: `ta_exists`
- File and directory operations: `ta_copy_file`
- Temporary and cleanup helpers: `ta_make_temp_dir`
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;14.2. Compare Functions</summary>

### 14.2. Compare Functions

These helpers cover comparison and matching functions in the Test API.

Examples include:

- Path, file, and directory comparisons: `ta_compare_dirs`
- Metadata and binary comparisons: `ta_compare_path_metadata`
- JSON helpers: `ta_compare_json`
- Text and pattern helpers: `ta_compare_text_normalized`
</details>
</details>
