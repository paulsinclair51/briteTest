# LiteTest

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Latest Release](https://img.shields.io/github/v/release/paulsinclair51/LiteTest?display_name=tag)](https://github.com/paulsinclair51/LiteTest/releases)
[![CI](https://img.shields.io/badge/CI-pending-lightgrey)](https://github.com/paulsinclair51/LiteTest/actions)

LiteTest is a lightweight C/C++ API and framework designed for running tests. It provides a minimal but flexible testing capability.

Copyright (c) 2026 paulsinclair51  
SPDX-License-Identifier: MIT. See `LICENSE` for details.

## Table of Contents

- [Quick Start](#quick-start)
- [Documentation Scope](#documentation-scope)
- [Key Features](#key-features)
- [Requirements](#requirements)
- [How LiteTest Compares](#how-litetest-compares)
- [Overview](#overview)
- [Project Layout](#project-layout)
- [Modules (.c files)](#modules-c-files)
- [Orchestrator (`main`) Function Template](#orchestrator-main-function-template)
- [Test Function Template](#test-function-template)
- [Example Usage](#example-usage)
- [Building the Test Executable](#building-the-test-executable)
- [Executable Usage](#executable-usage)
- [Common Pitfalls](#common-pitfalls)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [Example Test Report](#example-test-report)
- [Example Test Report for -i Option](#example-test-report-for--i-option)
- [Further Reading](#further-reading)
- [Glossary](#glossary)

## Quick Start

Build and run the self-test from the repository root:

```sh
make -C tests run
```

See [Building the Test Executable](#building-the-test-executable) for platform-specific notes and options.

First successful run checklist:

- The test executable builds and runs without errors.
- A report file is written in `reports/` or at the `PATH` you provide.
- The report shows category-level counts and overall totals.

## Documentation Scope

This README is the primary onboarding guide. It focuses on workflow, usage,
and practical examples.

Detailed API behavior, full macro semantics, and lower-level implementation
details are documented in [include/litetest.h](include/litetest.h).

## Key Features

- Pure C implementation.

- Fault isolation using POSIX signals (SIGSEGV, SIGBUS, SIGABRT) with nested guard levels.

- Light footprint with one header and one module defining the API.

- Straightforward API — simple assertions, categories, and reporting so user can focus
  on writing the tests.

- Comprehensive reporting — pass/fail/fault counts per category and overall totals.

## Requirements

LiteTest requires:

- POSIX.1‑2001 (IEEE Std 1003.1‑2001) compatibility
- A C99‑compliant compiler

Supported environments:

- Linux, macOS, BSD — fully compatible
- Windows — requires a POSIX layer such as Cygwin, MSYS2, or WSL

LiteTest has been exercised in POSIX environments; users should
validate behavior in their own systems.

## How LiteTest Compares

| Framework | Language / Style | Dependencies | Fault Isolation | Strengths | How LiteTest Differs |
|-----------|------------------|--------------|-----------------|-----------|-----------------------|
| **LiteTest** | Pure C, minimal API | None (single .c/.h) | POSIX signals (`SIGSEGV`, `SIGBUS`, `SIGABRT`) with nested guards | Tiny, embeddable, safe for low‑level code, simple reporting | Designed for small C projects, embedded systems, and environments where external frameworks are too heavy |
| **GoogleTest (gtest)** | C++ (OOP, templates) | Large library, build system integration | No built‑in POSIX fault trapping | Feature‑rich, fixtures, matchers, parameterized tests | LiteTest is dramatically smaller, pure C, and dependency‑free |
| **Unity / CMock** | C, embedded‑focused | Small library | No multi‑level signal guards | Lightweight, good for microcontrollers | LiteTest adds POSIX fault handling and nested guard levels |
| **Check** | C with process forking | Requires linking to Check library | Fork‑based isolation | Good isolation, TAP output | LiteTest avoids forking and stays single‑process with `sigsetjmp`/`siglongjmp` guards |
| **CTest (CMake)** | Test runner only | Requires CMake | None (runs external binaries) | Integrates with CMake, dashboards | LiteTest provides assertions + reporting; CTest is only an executor |
| **Catch2 / doctest** | Modern C++ | Header‑only | No POSIX fault trapping | Very expressive syntax, rich features | LiteTest is pure C and suitable for environments avoiding C++ |

## Overview

Core LiteTest API files:
 - [include/litetest.h](include/litetest.h)
 - [src/litetest.c](src/litetest.c)

A test executable typically consists of:

- A test **orchestrator** (`main`) function and optional test functions
  organized into one or more modules,

- `litetest.h`, `litetest.c`, and `unistd.h`

- The modules and headers for the project under test.

The orchestrator and test functions may reside in one module or multiple modules.
Recommended: put the orchestrator function in one module and each test function
in its own module.
   
When executed, LiteTest produces a structured report grouped by category, including:

- Pass/fail/fault counts per category.
- Totals across all categories.
- Appended failure and fault.

### Orchestrator (`main`) Macros

- `LT_DECLARE_ORCHESTRATOR(funcname)[;]`
- `LT_INIT_ORCHESTRATOR(funcname, project, [maxparallel]);`
- `LT_PARSE_ARGS([maxargs], ["defaultreportfilename"]);`
- `LT_OPEN_REPORT(["title"]);`
- test and assert macros
- `LT_WRITE_RESULT([t], "category");`
- `LT_CLOSE_REPORT(["notes"]);`
- `LT_EXIT;`

Note:
- `funcname` must be main.
- `maxargs` must be 2 or greater. The first arg is the executable name.
  The second optional arg is `PATH`. Additional args are for customization
  and must be parsed by custom code added to the function.
- `t` is a test or assert macro.
- For the first macro, a semicolon is required for a forward declaration;
  otherwise, omit the semicolon and follow with a definition in `{ }`.

### Test Function Macros

- `LT_DECLARE_TEST(funcname)[;]`
- `LT_INIT_TEST(testname, [maxparallel]);`
- test and assert macros
- `LT_RETURN;`

Note:
- `funcname` must not be main and must be same for the first two macros when
  defining a test function.
- For the first macro, a semicolon is required for a forward declaration;
  otherwise, omit the semicolon and follow with a definition in `{ }`.

### Test and Assert Macros

- `LT_TEST(funcname, [isolation])[;]`
- `LT_ASSERT(expression, [isolation])[;]`
- `LT_INJECT_ASSERT(expression, [isolation])[;]`

The semicolon is omitted if used as an argument to the LT_WRITE_RESULT macro;
otherwise it is required.

`LT_INJECT_ASSERT` is the same as `LT_ASSERT` except:

-  It only executes if injection is enabled (see [`-i` Option](#i-option).
-  Result is counted as an injected pass/fail/fault.

Special values that can be used in any expression:

- LT_PASS: returns 1.
- LT_FAIL: returns 0.
- LT_FAULT(type): causes a fault of the specified type: 1 (`SIGSEGV`). 2 (`SIGABRT`), 3 (`SIGBUS`).
  For other values of type, LT_FAULT returns 0.

#### Fault Handling

LiteTest provides multi‑level signal guards to safely capture faults such as
`SIGSEGV` `SIGABRT`, and `SIGBUS`. When a fault occurs:

- The fault is recorded
- Execution continues
- The test suite completes normally
- The final report includes fault counts and messages

This allows you to test low‑level or unsafe code without aborting the entire
test run.

#### Parallel Execution

Parallel execution of the test/assert macros is enabled/disabled by the
`maxparallel` parameter for the LT_INIT_ORCHESTRATOR and LT_INIT_TEST
macros. Up to `maxparallel` test/assert macros are started and when one
finishes another is started.

#### Parallel Group Macros

A group ensures that all test/assert macros inside it start together:

- Groups are bracketed with:
  - `LT_BEGIN_GROUP(groupname)`
  - `LT_END_GROUP(groupname)`
- Within a test function, a group cannot be nested inside another group.

#### Isolation Levels

`isolation`:
- 0 same thread (no parallelism)
- 1 separate thread
- 2 separate process

Defaults:
- Non-grouped macros: 0.
- Grouped macros: 1.

Invalid combinations are rejected.

## Project Layout

Repository layout (abridged):

```text
LiteTest/
|- include/litetest.h
|- src/litetest.c
|- tests/
|  |- test_litetest.c
|  |- test_orchestrator.c
|  |- test_guard1.c
|  \- test_guard2.c
|- reports/
\- README.md
```

Use this as a reference when adapting LiteTest into your own project structure.

### Customization

Additional functions, macros, typedefs, and variables are
provided to support customization.

Examples include:

- `lt_executablename`
- `lt_result_t`
- `lt_dirpath`
- `LT_MAX_PATH_LEN`
- `lt_currentlevel`
- `lt_currentresult`
- `lt_maxparallel`
- `lt_isisolated`
- `lt_groupname`
- `lt_iswritedirpath`

See [include/litetest.h](include/litetest.h) for documentation on the provided utility functions.
  
## Modules (.c files)

Modules containing the orchestrator or test functions must include `litetest.h` and
any required project headers.

### Example: lubtype Testing 

The tests directory in the `paulsinclair51/lubtype` repository provides an
example orchestrator module and test modules for the lubtype API. The modules
include these two files:

```c
#include "lubtype.h"
#include "litetest.h"
```

### Example: LiteTest Self-Testing

The tests directory for this repository provides an example self-test for
the LiteTest API and framework.

```c
#include "litetest.h"
```

## Orchestrator (`main`) Function Template

```c
LT_DECLARE_ORCHESTRATOR(main)
{
  LT_INIT_ORCHESTRATOR(main, project, [maxparallel]);
  LT_PARSE_ARGS([maxargs], ["defaultfilename"]);
  LT_OPEN_REPORT(["title"]);

  // Insert test/assert/write calls here:
  //   LT_TEST(funcname, [isolation]);
  //   LT_ASSERT(expression, [isolation]);
  //   LT_WRITE_RESULT(LT_TEST(funcname, [isolation]), "category");
  //   LT_WRITE_RESULT(LT_ASSERT(expression, [isolation]), "category");
  // Group test/assert calls using:
  //   LT_BEGIN_GROUP(groupname);
  //   LT_END_GROUP(groupname);

  LT_CLOSE_REPORT(["notes"]);

  LT_EXIT;
}
```

`LT_WRITE_RESULT` flushes one category and resets its counts. Totals accumulate
across the full run.

Optional typedefs, variables, functions, and code may be added to customize
or support testing. Added code may use utility functions. **Recommended**:
do not intermix code with the tests; such code is handled as if it occurs
before the tests.

Forward-declaration:

```c
LT_DECLARE_ORCHESTRATOR(main);
```

## Test Function Template

```c
[static] LT_DECLARE_TEST(funcname)
{
  LT_INIT_TEST(funcname, [maxparallel]);

  // Insert test/assert calls here:
  //   LT_TEST(funcname, [isolation]);
  //   LT_ASSERT(expression, [isolation]);
  // Group test/assert calls using:
  //   LT_BEGIN_GROUP(groupname);
  //   LT_END_GROUP(groupname);

  LT_RETURN;
}
```

Use `static` when the function is only referenced in the same module.

Forward declaration:

```c
[static] LT_DECLARE_TEST(func);
```

Specify `static` if the above definition of the function specifies `static`.

Optional typedefs, variables, functions, and code may be added to customize
or support testing. Added code may use utility functions. **Recommended**:
do not intermix code with the tests; such code is handled as if it occurs
before the tests.

## Example Usage

The tests directory for this repository provides a self-test implementation of
the LiteTest API and framework. It includes:

- `test_litetest.c` defines the orchestrator (`main`) with two test
   categories "Orchestrator" and "Guard".

- `test_orchestrator.c` defines the test_orchestrator functions for
   testing the "Orchestrator" category.

- `test_guard1.c` defines the `test_guard1` function for testing part of
   the "Guard" category.

- `test_guard2.c` defines the `test_guard2` function for testing the other
   part of the "Guard" category.

The results of `test_guard1` and `test_guard2` are combined by the orchestrator
into a single result for the "Guard 1 and 2" category.

## Building the Test Executable

Modify a copy of an existing Makefile that builds a test executable for
a project to a Makefile for your project. For example, use the Makefile
for testing the lubtype project or the Makefile for self-testing this
LiteTest project as a starting point for creating your Makefile in your
project root directory.

#### Linux / macOS

This is the primary supported and currently validated environment.
Linux is the canonical path for building the test executable,
including GitHub Codespaces.

From the repository root:

```sh
make -C tests run
```

The Makefile builds and executes the executable writing the test report
in the reports directory with the default name `<project>_test_report.txt`.

The executable can then be executed directly (see
[Executable Usage](#executable-usage)).

To build with gcc instead of clang:

```sh
make -C tests CC=gcc run
```

#### Windows (POSIX Toolchain Required)

Use a POSIX‑capable toolchain such as MSYS2 UCRT64 or Clang64.

If you need the PowerShell path, refer to `build_test_litetest.ps1`. The
following is the expected command to run the script once it has been tested:

```powershell
./build_test_litetest.ps1
.\test_litetest.exe
```

A tested setup is MSYS2 UCRT64 with:

```powershell
pacman -S --needed base-devel mingw-w64-ucrt-x86_64-gcc
```

Ensure the MSYS2 `bin` directory is on `PATH` before running PowerShell.

Clang64 is also suitable if `cc`, `clang`, or `gcc` resolves to a
POSIX-capable compiler.

## Executable Usage

To execute the tests, run the test executable to produce the test report file (an
existing file is overwritten):

```sh
test_<testname> [-i] [PATH]
```

By default, if `PATH` is not specified, LiteTest writes the report to the
current working directory using the default report filename configured by your
test setup.

### PATH

You may override the output location using the PATH argument:

- `PATH` can point to either a report file or a directory. Quote it only when
  it contains spaces (for example, `"my reports/"`).

- If `PATH` is a file path (existing or new), LiteTest writes the report to
  that file.

- If `PATH` is a directory path, LiteTest writes the report in that directory
  using the default report filename configured by your test setup.

### `-i` Option

The `-i` option enables fail/fault assertions planted in the tests to inject a
fail or fault. Use it to exercise the LiteTest framework and verify report
formatting when failures and faults occur.

### `--help` and `-h` Help Options

You can display usage information at any time with the `--help` or `-h` option.
For example:

```sh
./test_litetest --help
```
This (or using -h instead of --help) prints a summary of all command-line
 options and usage details.

## Common Pitfalls

- If `PATH` contains spaces, quote it (for example, `"my reports/report.txt"`).
- Existing report files may be overwritten; use unique paths if you need history.
- On Windows, use a POSIX-capable toolchain (for example, MSYS2 UCRT64).
- Keep macro examples in your project aligned with the version of `litetest.h` in use.

## Troubleshooting

- Build fails with missing POSIX APIs on Windows: verify you are using a
  POSIX-capable toolchain (for example, MSYS2 UCRT64) and that its `bin`
  directory is on `PATH`.
- Report file not found where expected: confirm the current working directory
  and check whether `PATH` was passed as a file path or directory path.
- Output path with spaces fails: quote `PATH` (for example,
  `"my reports/report.txt"`).
- Unexpected behavior after macro updates: ensure code and docs match the same
  LiteTest version (`LT_VERSION` in `litetest.h` and `LT_VERSION_C` in
  `litetest.c`).

## Contributing

Contributions are welcome. Before opening a pull request:

- Create a feature branch for your work (for example, `docs/readme-update`).
- Update LT_VERSION in `litetest.h` and LT_VERSION_C in `litetest.c` if either is
  updated. Update major version for incompatible API changes. Update minor
  version for backward-compatible additions. Update patch version for bug
  fixes or internal improvements.
- Build and run tests from the repository root with `make -C tests run`.
- Keep documentation updates aligned with code and macro behavior.
- Prefer focused commits with clear commit messages.
- If report formatting changes, refresh the README report examples.
- Do not commit directly to `main` unless you have explicit maintainer approval.

Incompatible API changes: The naming conventions, error semantics, and
safety guarantees are part of the documented and stable API and must not
change without compelling justification and impact analysis. When possible,
provide a compatibility mechanism to preserve prior behavior (for example, a
feature flag or macro to enable/disable the new behavior).

## Example Test Report

```text
LiteTest Report
                             Pass   Fail     Fault
--------------------------------------------------
1. Orchestrator                 4
2. Guard 1 and 2                6
--------------------------------------------------
                      Total    10
```

## Example Test Report for -i Option

```text
LiteTest Report (-i)

                             Pass   Fail     Fault
--------------------------------------------------
1. Orchestrator                 4      1         1
2. Guard 1 and 2                6      2         1
--------------------------------------------------
                      Total    10      3         2
```

## Further Reading

- [include/README.md](include/README.md)
- [src/README.md](src/README.md)
- [tests/README.md](tests/README.md)
- [reports/README.md](reports/README.md)

## Glossary

- `API`: Application Programming Interface.
- `assertion expression`: An expression passed to an assert macro that can be
  converted to `int`; `0` means fail and any nonzero value means pass.
- `category`: A labeled group of test/assert results written by
  `LT_WRITE_RESULT`.
- `default report filename`: The report filename LiteTest uses when only a
  directory path (or no `PATH`) is provided.
- `executable`: The compiled test program that runs the orchestrator and test
  functions.
- `fail`: A counted assertion failure where the expression evaluates false (i.e.,
  zero).
- `fault`: A counted runtime fault captured by LiteTest guards (for example,
  invalid memory access).
- `group`: A bracketed set of test/assert calls between `LT_BEGIN_GROUP` and
  `LT_END_GROUP`.
- `guard`: The protection mechanism used to catch runtime faults and continue
  test execution.
- `guard level`: The nesting depth of active guards while tests/asserts run.
- `inject mode (-i)`: Optional command-line flag that enables injected
  fail/fault test paths.
- `isolation`: Execution mode for a test/assert call.
  `0` = same thread, `1` = separate thread, `2` = separate process.
- `maxargs`: The maximum number of command-line arguments accepted by
  orchestrator parsing. Optional arguments may be omitted.
  `LT_PARSE_ARGS` handles the first two arguments (executable name and optional
  `PATH`) when provided. Any additional arguments must be parsed by custom code
  added to the orchestrator.
- `maxparallel`: Upper bound on concurrent test/assert execution configured by
  orchestrator/test initialization macros.
- `notes`: Optional report text provided when closing the report.
- `orchestrator`: The `main` function that initializes LiteTest, runs tests,
  and writes report output.
- `pass`: A counted successful assertion where the expression evaluates true (i.e.,
  non-zero).
- `PATH`: Optional command-line output destination; can be a report file path
  or directory path.
- `process isolation`: Isolation mode where a test/assert call runs in a
  separate process.
- `project`: Project identifier used in orchestrator initialization and default
  report naming.
- `test function`: A function declared with LiteTest test macros that contains
  test and assert calls.
- `thread isolation`: Isolation mode where a test/assert call runs in a
  separate thread.
- `title`: Optional report header text provided when opening the report.
