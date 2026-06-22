# BriteTest

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Latest Release](https://img.shields.io/github/v/release/paulsinclair51/BriteTest?display_name=tag)](https://github.com/paulsinclair51/BriteTest/releases)
[![CI](https://github.com/paulsinclair51/BriteTest/actions/workflows/britetest_ci.yml/badge.svg)](https://github.com/paulsinclair51/BriteTest/actions/workflows/britetest_ci.yml)

BriteTest is a lightweight Application Programming Interface (API) and framework for defining,
running, and reporting tests in C/C++ projects. It is implemented as a single `.h` and `.c` pair
with no external dependencies requiring only a POSIX.1‑2001 environment and a C99‑compliant compiler.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT. See `LICENSE` for details.

<details>
<summary><strong>📘  TABLE OF CONTENTS  📘</strong></summary>

- [Quick Start](#quick-start)
- [Documentation Scope](#documentation-scope)
- [Key Features](#key-features)
- [API Usage Requirements](#api-usage-requirements)
- [How BriteTest Compares](#how-britetest-compares)
- [What BriteTest Does Not Provide](#what-britetest-does-not-provide)
- [Overview](#overview)
- [Core API Macros](#core-api-macros)
  - [Macros for the Orchestrator (main) Function](#macros-for-the-orchestrator-main-function)
  - [Macros for a Test Group Function](#macros-for-a-test-group-function)
  - [Macros for Executing a Test Group Function or Test Expression](#macros-for-executing-a-test-group-function-or-test-expression)
    - [Parallel Execution](#parallel-execution)
  - [Macros for Concurrent Execution](#macros-for-concurrent-execution)
  - [Isolation Modes and Fault Handling](#isolation-modes-and-fault-handling)
- [Customization Support API](#customization-support-api)
- [Test Support API](#test-support-api)
- [Headers (.h) and Sources (.c)](#headers-h-and-sources-c)
- [Orchestrator (main) Function Template](#orchestrator-main-function-template)
- [Test Group Function Template](#test-group-function-template)
- [Example of Using the BriteTest API](#example-of-using-the-britetest-api)
- [Building the Test Executable](#building-the-test-executable)
  - [Linux / macOS](#linux--macos)
  - [Windows (POSIX Toolchain Required)](#windows-posix-toolchain-required)
- [Executable Usage](#executable-usage)
  - [PATH](#path)
  - [`-I` and `-In` Option](#i-option-and-in-option)
  - [--help and -h Help Options](#help-and--h-help-options)
- [Common Mistakes](#common-mistakes)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [Example Test Report](#example-test-report)
- [Example Test Report for -I Option](#example-test-report-for--i-option)
- [Repository Layout](#repository-layout)
- [Further Reading](#further-reading)
- [Glossary](#glossary)
</details>

## Quick Start

BriteTest tests are C/C++ expressions/functions, and the orchestrator controls
reporting and execution.

1. To try BriteTest, copy 'britetest_runner.h' and 'britetest_runner.c' to your current directory:

```sh
cp /path/to/britetest_runner.h .
cp /path/to/britetest_runner.c .
```

2. Create a file named `test_quick.c` in the same directory.

3. Copy and paste the code into `test_quick.c`:

<details>
<summary>💻 Click to view and copy</summary>

```c
#include "britetest_runner.h"

// A simple test group function.

static BT_DECLARE_GROUP(test_quick)
{
  BT_INIT_GROUP(test_quick, 1);

  int a = 2;
  int b = 2;

  // 4 test assertions.
  BT_TEST(a == b, , 0);        // Pass
  BT_TEST(a + b == 4, ,  0);    // Pass
  BT_TEST(a - b == 1, , 0);    // Fail
  BT_TEST(BT_FAULT(1), , 0);   // Fault

  BT_RETURN;
}

// A simple orchestrator (main) function.

BT_DECLARE_ORCHESTRATOR(main)
{
  BT_INIT_ORCHESTRATOR(main, quick, 1);
  BT_PARSE_ARGS(2, "quick_test_report.txt");
  BT_OPEN_REPORT("Test Quick Report");

  // Single test category.
  BT_WRITE_RESULT(BT_GROUP(test_quick), "Quick tests");

  BT_CLOSE_REPORT("Note: This report is a very simple example of using BriteTest.\n"
                  "Note: Multiple test categories can be added using multiple\n"
                  "      test functions.\n"
                  "Note: Orchestrator (`main`) and test functions can be placed in\n"
                  "      individual modules (.c files).\n"
                  "Note: Parameters can be set to run tests in parallel, isolate\n"
                  "      a test to a separate thread or process, etc.\n"
                  "Note: The expression for BT_TEST can reference functions to\n"
                  "      provide a more complex test. A non-zero result indicates\n"
                  "      pass and a zero result indicates fail. If a fault occurs\n"
                  "      executing the expression, it is detected and counted in\n"
                  "      the report as a fault.\n"
                  "Note: Larger projects can place files in a more conventional\n"
                  "      layout (e.g., `include/` and `src/`, but this example keeps\n"
                  "      everything in your current directory for simplification.\n"
                  "Note: See README.md for BriteTest for additional API features.\n");
  BT_EXIT;
}
```
</details>

4. Build the executable `test_quick` in your current directory:

```sh
cc -std=c99 -Wall -Wextra -o test_quick test_quick.c britetest_runner.c
```

5. Run it:

```sh
./test_quick
```

6. View `quick_test_report.txt` in your current directory:

```sh
less quick_test_report.txt   # Press 'q' to quit
```

Example of the report:

<details>
<summary>💻 Click to view</summary>

```text
BriteTest Report
                             Pass   Fail     Fault
--------------------------------------------------
1. Orchestrator                 4
2. Guard 1 and 2                6
--------------------------------------------------
                      Total    10
```
</details>

See the [Core API Macros](#core-api-macros) and other sections for more detail.

See [Building the Test Executable](#building-the-test-executable) for
platform-specific notes and options.

## Documentation Scope

This README serves as the introduction and usage guide to BriteTest. It focuses on concepts,
workflow, and practical examples to help you quickly integrate BriteTest into your project.

Detailed API behavior, macro semantics, and lower‑level implementation details are documented
directly in `include/britetest_runner.h`.

## Key Features

<details>
<summary>Click to view</summary>

- Pure C implementation.
- Fault handling with nested guard levels.
- Minimal footprint — a single header and source file define the entire API.
- Straightforward API: simple assertions, categories, and reporting so you can focus on writing tests.
- Comprehensive reporting: pass/fail/fault counts per category and overall totals.
- Test support functions that simplify writing and organizing tests.
</details>

## API Usage Requirements

<details>
<summary>Click to view</summary>

BriteTest requires:

- POSIX.1‑2001 (IEEE Std 1003.1‑2001) compatibility.
- A C99‑compliant compiler.

Supported environments:

- Linux, macOS, BSD — fully compatible.
- Windows — requires a POSIX layer such as Cygwin, MSYS2, or WSL.

BriteTest has been exercised in POSIX environments; users should
validate behavior in their own systems.
</details>

## How BriteTest Compares

<details>
<summary>Click to view</summary>

| Framework     | Language / Style | Dependencies | Fault Isolation | Strengths | How BriteTest Differs |
|---------------|------------------|--------------|-----------------|-----------|------------------------|
| **Unity**     | C, macro‑heavy   | None         | No              | Widely used, simple API | BriteTest adds POSIX signal‑based fault isolation and category‑level reporting. |
| **cmocka**    | C, function‑based | None        | Yes (setjmp)    | Mature, feature‑rich | BriteTest is smaller, header‑driven, and easier to embed in small projects. |
| **Check**     | C, process‑based | POSIX tools  | Yes (fork)      | Strong isolation, fixtures | BriteTest avoids process spawning and keeps a minimal footprint. |
| **Criterion** | C, auto‑discovery | libc, POSIX | Yes             | Modern, fast, rich output | BriteTest is simpler, portable, and avoids auto‑discovery complexity. |
| **BriteTest**  | C99, macro‑driven | None        | Yes (POSIX signals) | Minimal, portable, easy to embed | Designed for small C projects needing fault isolation without heavy frameworks. |
</details>

## What BriteTest Does Not Provide

<details>
<summary>Click to view</summary>

BriteTest focuses on executing tests and reporting results. It does not:

- Generate test source files — users write their own test modules.
- Perform automatic test discovery — tests are invoked explicitly by the orchestrator or from within test functions.
- Provide mocking or stubbing frameworks — users implement their own mocking and stubbing.
- Include built‑in setup/teardown systems — users implement their own patterns as needed.
- Handle memory management or leak detection — external tools (e.g., Valgrind) must be used.
- Manage source control or repository structure — BriteTest does not define SCM workflows.
- Integrate with build systems or CI pipelines — users configure these as needed.
- Manage test artifacts such as expected‑output (“control”) files.
- Define or enforce directory layouts for tests or project structure.
- Promote output files to control files — users handle this workflow manually.
- Track versioning or history of test artifacts.
- Produce rich reporting formats such as JUnit XML or HTML output.
- Provide functionality outside the features explicitly described in this document.
</details>

## Overview

BriteTest is a lightweight C/C++ testing framework built around a simple execution model:
1. You write C test expressions (that typically invoke functions) for each test and wrap each
   of these expressions with the `BT_TEST` macro in a test group function.
2. You wrap each test group function name with the `BT_GROUP` macro in the orchestrator.
3. The orchestrator (`main`) function runs the test group functions and reports results.

The BriteTest Runner API files:

 - [`include/britetest_runner.h`](include/britetest_runner.h) — public API (typedefs, enums, constants, macros,
   function declarations, and static inline function definitions).
 - [`src/britetest_runner.c`](src/britetest_runner.c) — function definitions for the BriteTest framework.

The BriteTest Test API files:

 - [`include/britetest_test.h`](include/britetest_test.h) — test support/helper function declarations.
 - [`src/britetest_test.c`](src/britetest_test.c) — test support/helper function definitions.

A typical test executable includes:

- An orchestrator (`main`) function that opens the report, invokes test group functions,
  writes category results, and closes the report.
- Multiple test group functions that execute the tests.
- The BriteTest Runner API files (`britetest_runner.h`, `britetest_runner.c`).
- The BriteTest Test API files (`britetest_test.h`, `britetest_test.c`).
- The headers and source files for the project being tested.

main()
 ├── test_group1()
 │     ├── test1
 │     ├── test2
 │     └── ...
 └── test_group2()
       ├── ...

Recommended: Put the orchestrator function in one source file and each test group function
in its own source file.
   
When executed, BriteTest produces a report summarizing tests by category, including:

- Pass/fail/fault counts per category.
- Totals across all categories.
- Notes describing each failure or fault.

## Core API

The core API is set of macros used to define the orchestrator and test group
functions. These macros fall into 3 types:

| Type | Purpose | Naming Pattern |
| --- | --- | --- |
| **Orchestrator** | Define and run the test runner | ``BT_DECLARE_*``, ``BT_INIT_*``, ``BT_*`` |
| **Test Group Functions** | Define test group functions | ``BT_DECLARE_GROUP``, ``BT_INIT_GROUP``, ``BT_RETURN`` |
| **Execution** | Execute groups or test expressions | ``BT_GROUP``, ``BT_TEST`` |

### Macros for the Orchestrator (`main`) Function

- `BT_DECLARE_ORCHESTRATOR(funcname)[;]`
- `BT_INIT_ORCHESTRATOR(funcname, project, maxparallel);`
- `BT_PARSE_ARGS(maxargs, defaultreportfilename);`
- `BT_OPEN_REPORT(title]);`
- test group and test expression macros,
- `BT_WRITE_RESULT(gtm, category);`
- `BT_CLOSE_REPORT(notes]);`
- `BT_EXIT;`

Note:
- `funcname` must be main.
- `maxargs` must be 2 or greater. The first arg is the executable name.
  The second optional arg is `PATH`. Additional args are for customization
  and must be parsed by custom code added to the function.
- `gtm` is an `BT_GROUP` or `BT_TEST` macro.
- For the first macro, a semicolon is required for a forward declaration;
  otherwise, omit the semicolon and follow with a definition in `{ }`.

### Macros for a Test Group Function

- `BT_DECLARE_GROUP(funcname)[;]`
- `BT_INIT_GROUP(funcname, maxparallel);`
- test expression and test group macros.
- `BT_RETURN;`

Note:
- `funcname` must not be main and must be same for the first two macros when
  defining a test group function.
- For the first macro, a semicolon is required for a forward declaration;
  otherwise, omit the semicolon and follow with a definition in `{ }`.

### Macros for Executing a Test Group Function or Test Expression

- `BT_GROUP(funcname, [include], isolation)[;]`
- `BT_TEST(expression, [include], isolation)[;]`

When an  `BT_GROUP `or `BT_TEST` macro is passed as the first argument to BT_WRITE_RESULT,
omit the trailing semicolon. Otherwise, a semicolon is required.

`funcname`: name of the group function to execute.

`expression`: Test expression which is cast to int. If `expression` returns 0, test failed;
              otherwise, test passed. If a fault is captured, the test faulted.
            
`include`:

This parameter controls whether a test group or test expression executes
based on the test executable's `-I` or `-In` option (see [`-I` and `-In` Option](#i-and-in-option)):

- 0 — do not execute.
- 1 — always execute.
- 2 – 9 — execute only when the user specifies an `-In` option and the value is less than or
-         equal to n (a single non-zero digit).
- I — execute only when the user specifies `-I` without a digit (valid only for BT_TEST),
      Result is counted as an injected pass/fail/fault as well as the usual
      a pass/fail/fault count.
- omitted — defaults to `1`.

For `isolation`, see [Isolation Modes and Fault Handling](isolation-modes-and-fault-handling).

Special values that can be used in any expression:

- `BT_PASS`: returns 1.
- `BT_FAIL`: returns 0. Note this does force a fail. A fail occurs only if the test
  expression evaluates to 0.
-` BT_FAULT(type)`: causes a fault of the specified type: 1 (`SIGSEGV`). 2 (`SIGABRT`), 3 (`SIGBUS`).
  For other values of type, BT_FAULT returns 0.

#### Parallel Execution

BriteTest starts up to `maxparallel` test group functions or test expressions concurrently.
When one finishes, another begins, until all are complete. `maxparallel` is set by the
`BT_INIT_ORCHESTRATOR` and `BT_INIT_GROUP` macros.

###  Macros for Concurrent Execution

The concurrent block macros ensure that all `BT_TEST` macros inside it start together:

- The `BT_TEST` macros are bracketed with:
  - `BT_BEGIN_CONCURRENT(blockname)`
  - `BT_END_CONCURRENT(blockname)`
- Within a test group function body, a concurrent block cannot be nested inside
  concurrent block.

### Isolation Modes and Fault Handling

BriteTest supports two execution isolation modes that balance speed and fault‑isolation. Both modes run
tests in a single thread within each process; the difference is whether all test groups and tests run
inside one process or each runs in its own process.

| Mode | Speed | Isolation | Best Use |
| --- | --- | --- | --- |
| 0 – Same thread | Fastest | Low | Local dev |
| 1 – Thread | Fast | Medium | Concurrent tests |
| 2 – Process | Slower | Full | CI, fault injection |

`isolation`:
- 0 same thread (no parallelism)
- 1 separate thread
- 2 separate process

Defaults:
- Tests and test groups not within a concurrent block: 0.
- Tests within a concurrent block: 1.

Invalid combinations are rejected.

A fault is handled as follows:

- The fault is recorded
- Execution continues
- The execution completes normally
- The final report includes fault counts and messages

This allows you to test low‑level or unsafe code without aborting the entire
test run.

1. Single‑Process Mode (default)

In this mode, all test groups and tests run sequentially inside a single process and a single thread.
This provides the fastest execution and the simplest debugging experience.

BriteTest installs a signal guard that can detect and report certain synchronous faults,
including:

- `SIGSEGV` (invalid memory access)
- `SIGBUS`  (bus error)
- `SIGFPE`  (arithmetic error)
- `SIGILL`  (illegal instruction)

These faults can be caught and reported without terminating the test run.

However, some failures cannot be isolated in a single process. If a test triggers
one of the following, the entire BriteTest process terminates:

- `SIGABRT` (abort(), assert() failures, malloc corruption).
- `SIGKILL`, `SIGSTOP`.
- External termination signals `(SIGTERM`, `SIGINT`, `SIGHUP`)
- Sanitizer aborts.
- Undefined behavior that escalates to process termination.
- Deadlocks, infinite loops, or resource exhaustion.

Single‑process mode is ideal for everyday development and fast feedback, but it does not
provide complete fault isolation.

2. Process‑Isolated Mode (parallel or serial)

In this mode, each test group function and test expression runs in its own child process. BriteTest monitors each child and
reports its result after the process exits.

Because each test group function and test expression runs in a separate process, BriteTest can isolate:

- `SIGABRT` and all abort‑based failures.
- Memory corruption that triggers allocator aborts.
- Sanitizer aborts.
- Undefined behavior that terminates the process.
- Deadlocks (child can be timed out and then killed).
- Infinite loops (child can be timed out and then killed).
- Resource exhaustion.
- All synchronous faults (`SIGSEGV`, `SIGBUS`, `SIGILL`, `SIGFPE`).

A failure in one test group cannot affect any other test group or the test runner itself.

Process‑isolated mode is recommended for:

- CI environments
- fault‑injection testing
- untrusted or experimental code
- tests that may hang, abort, or corrupt memory
- running test groups in parallel

Summary:

| Mode              | Execution                     | Isolation Strength                     | Best For                    |
|-------------------|-------------------------------|----------------------------------------|-----------------------------|
| Single‑Process    | One process, one thread       | Partial (cannot isolate aborts/hangs)  | Fast local runs, debugging  |
| Process‑Isolated  | One process per test group    | Full (survives all faults)             | CI, fault injection, parallel runs |

Both modes use the same `BT_GROUP` and `BT_TEST` macros. The choice of isolation
mode affects only how test group functions and test expressions are executed,
not how they are written.

## Customization Support API

Additional functions, macros, typedefs, and variables are provided to support customization.

Examples include:

<details>
<summary>Click here to view</summary>

- `bt_executablename`
- `bt_resubt_t`
- `bt_dirpath`
- `BT_MAX_PATH_LEN`
- `bt_currentlevel`
- `bt_currentresult`
- `bt_maxparallel`
- `bt_blockname`
- `bt_iswritedirpath`
</details>

See [include/britetest_runner.h](include/britetest_runner.h) for documentation on the provided
customization functions.

## Test Support API

Additional functions are provided to support writing tests.

<details>
<summary>Click here to viewt</summary>

Examples of Process and runtime helpers include:

- `int bt_execute_command(const char *command_line, int timeout_ms, char *output_buffer, size_t output_buffer_size, int *exit_code)`
- `int bt_wait_for_condition(int (*condition)(void *callback_context), void *callback_context, int timeout_ms, int poll_interval_ms)`

Examples of File and filesystem helpers include:

- `int bt_copy_file(const char *source_path, const char *destination_path)`
- `int bt_make_temp_dir(const char *prefix, char *out_path, size_t out_path_size)`
  
Examples of Comparison and matching helpers include:

- `int bt_compare_files(FILE *left_file, FILE *right_file)`
- `int bt_compare_file_to_path(FILE *file, const char *path)`
- `int bt_compare_paths(const char *left_path, const char *right_path)`
- `int bt_compare_path_to_file(const char *path, FILE *file)`
- `int bt_match(const char *text, const char *pattern)`

Example of Environment helpers:

- `int bt_with_environment_variable(const char *variable_name, const char *temporary_value, int (*callback)(void *callback_context), void *callback_context)`
</details>

See [include/britetest_test.h](include/britetest_test.h) for documentation on the provided
test support functions.
  
## Headers (.h) and Sources (.c)

Source files containing the orchestrator or test group functions must include `britetest_runner.h` and
any required project headers.

Example: Testing lubtype Project

The `tests` directory in the `paulsinclair51/lubtype` repository provides an
example orchestrator and test group source (.c) files for the lubtype API. Each
source file includes these two headers:

```c
#include "lubtype.h"
#include "britetest_runner.h"
```

Example: Self-Testing BriteTest Project

The `tests` directory for this repository provides an example self-test for
the BriteTest API and framework.

```c
#include "britetest_runner.h"
```

## Orchestrator (`main`) Function Template

<details>
<summary>💻 Click to view and copy</summary>

```c
BT_DECLARE_ORCHESTRATOR(main)
{
  BT_INIT_ORCHESTRATOR(main, project, [maxparallel]);
  BT_PARSE_ARGS([maxargs], ["defaultfilename"]);
  BT_OPEN_REPORT(["title"]);

  // Insert group/test/write calls here:
  //   BT_GROUP(funcname, [isolation]);
  //   BT_TEST(expression, [isolation]);
  //   BT_TEST_I(expression, [isolation]);
  //   BT_WRITE_RESULT(BT_GROUP(funcname, [isolation]), "category");
  //   BT_WRITE_RESULT(BT_TEST(expression, [isolation]), "category");
  // Group test/assert calls using:
  //   BT_BEGIN_CONCURRENT(groupname);
  //   BT_END_CONCURRENT(groupname);

  BT_CLOSE_REPORT(["notes"]);

  BT_EXIT;
}
```
</details>

`BT_WRITE_RESULT` writes one category and resets its counts. Totals accumulate
across the full run.

Optional typedefs, variables, functions, and code may be added to customize
or support testing. Added code may use test support functions (see
[Test Support API](#test-support-api)) and customization support functions
(see [Customization Support API](#customization-support-api)).

**Recommended**: do not intermix code with the tests; such code is handled
as if it occurs before the tests.

Forward-declaration:

```c
BT_DECLARE_ORCHESTRATOR(main);
```

## Test Group Function Template

<details>
<summary>💻 Click to view and copy</summary>

```c
[static] BT_DECLARE_GROUP(funcname)
{
  BT_INIT_GROUP(funcname, [maxparallel]);

  // Insert test/group calls here:
  //   BT_TEST(expression, [isolation]);
  //   BT_TEST_I(expression, [isolation]);
  //   BT_GROUP(funcname, [isolation]);
  // Group test/assert calls using:
  //   BT_BEGIN_CONCURRENT(groupname);
  //   BT_END_CONCURRENT(groupname);

  BT_RETURN;
}
```
</details>

Use `static` when the function is only referenced in the same module.

Forward declaration:

```c
[static] BT_DECLARE_GROUP(func);
```

Specify `static` if the above definition of the function specifies `static`.

Optional typedefs, variables, functions, and code may be added to customize
or support testing.  Added code may use test support functions (see
[Test Support API](#test-support-api)) and customization suport functions
(see [Customization Support API](#customization-support-api)).

**Recommended**: do not intermix code with the tests; such code is
handled as if it occurs before the tests.

## Example of Using the BriteTest API

The `tests` directory for this repository provides a self-test implementation of
the BriteTest API and framework. It includes:

<details>
<summary>Click to view</summary>

- `test_britetest.c` defines the orchestrator (`main`) with two test
   categories "Orchestrator" and "Guard".

- `test_orchestrator.c` defines the test_orchestrator function for
   testing the "Orchestrator" category.

- `test_guard1.c` defines the `test_guard1` function for testing part of
   the "Guard" category.

- `test_guard2.c` defines the `test_guard2` function for testing the other
   part of the "Guard" category.
</details>

The results of `test_guard1` and `test_guard2` are combined by the orchestrator
into a single result for the "Guard 1 and 2" category.

## Building the Test Executable
 
Modify a copy of an existing Makefile that builds a test executable for
a project to a Makefile for your project. For example, use the Makefile
for testing the lubtype project or the Makefile for self-testing this
BriteTest project as a starting point for creating your Makefile in your
project root directory.

#### Linux / macOS

This is the primary supported and currently validated environment.
Linux is the canonical path for building the test executable,
including GitHub Codespaces.

From the repository root:

```sh
make run
```

The Makefile builds and executes the executable writing the test report
in the reports directory with the default name `<project>_test_report.txt`.

The executable can then be executed directly (see
[Executable Usage](#executable-usage)).

To build with gcc instead of clang:

```sh
make CC=gcc run
```

#### Windows (POSIX Toolchain Required)

Use a POSIX‑capable toolchain such as MSYS2 UCRT64 or Clang64.

On Windows, use `build_test_britetest.ps1` to build and run the test executable:

```powershell
./build_test_britetest.ps1
.\test_britetest.exe
```

A common setup is MSYS2 UCRT64 with:

```powershell
pacman -S --needed base-devel mingw-w64-ucrt-x86_64-gcc
```

Ensure the MSYS2 `bin` directory is on `PATH` before running PowerShell.

Clang64 is also suitable if `cc`, `clang`, or `gcc` resolves to a
POSIX-capable compiler.

## Executable Usage

To execute the tests, run the test executable to produce the test report file (an
existing writable file is overwritten):

```sh
test_<testname> [-I|-In] [PATH]
```

By default, if `PATH` is not specified, BriteTest writes the report to the
current working directory using the default report filename configured by
your test setup.

### PATH

You may override the output location using the PATH argument:

- `PATH` can point to either a report file or a directory. Quote it only when
  it contains spaces (for example, `"my reports/"`).

- If `PATH` is a file path (existing or new), BriteTest writes the report to
  that file.

- If `PATH` is a directory path, BriteTest writes the report in that directory
  using the default report filename configured by your test setup.

### `-I` and `-In` Option

The  `-I` and `-In` options control which tests execute based on the `include`
parameter of the `BT_GROUP` and `BT_TEST` macros. `n` is a single non-zero digit.
Only one of these forms may be specified.

- Use `-In` to enable `BT_GROUP` and `BT_TEST` macros that have an `include` argument
  that is a non-zero digit less than or equal to `n`.

- Use `-I` to enable `BT_TEST` macros that have an `include`  argument that is `I`. This
  can be used to exercise the BriteTest framework and verify report formatting
  (typically, these `BT_TEST` macros have a test expression that is coded to
  cause a failures or a fault.

- If neither option is provided, all  `BT_GROUP` and `BT_TEST` macros with an `include`
  argument that is `1` – `9` execute by default.

See [Macros for Executing a Test Group Function or Test Expression](#macros-for-executing-a-test-group-function-or-test-expression) for the `include` parameter and its interaction with the `-I` and `-In` options.

### `--help` and `-h` Help Options

You can display usage information at any time with the `--help` or `-h` option.
For example:

```sh
./test_britetest --help
```
This (or using -h instead of --help) prints a summary of all command-line
options and usage details.

## Common Mistakes

- If `PATH` contains spaces, quote it (for example, `"my reports/report.txt"`).
- Existing report files may be overwritten; use unique paths if you need history.
- On Windows, use a POSIX-capable toolchain (for example, MSYS2 UCRT64).
- Keep macro examples in your project aligned with the version of `britetest_runner.h` in use.

## Troubleshooting

- Build fails with missing POSIX APIs on Windows: verify you are using a
  POSIX-capable toolchain (for example, MSYS2 UCRT64) and that its `bin`
  directory is on `PATH`.
- Report file not found where expected: confirm the current working directory
  and check whether `PATH` was passed as a file path or directory path.
- Output path with spaces fails: quote `PATH` (for example,
  `"my reports/report.txt"`).
- Unexpected behavior after macro updates: ensure code and docs match the same
  BriteTest version (`BT_VERSION` in `britetest_runner.h` and `BT_VERSION_C` in
  `britetest_runner.c`).

## Contributing

Contributions are welcome. Before opening a pull request:

- Create a feature branch for your work (for example, `docs/readme-update`).

- Update `BT_VERSION` in `britetest_runner.h` and `BT_VERSION_C` in `britetest_runner.c` if either is
  updated. Update major version for incompatible API changes. Update minor
  version for backward-compatible additions. Update patch version for bug
  fixes or implementation improvements.

- Build and run tests from the repository root with `make run`.

- Keep documentation updates aligned with code and macro behavior.

- Prefer focused commits with clear commit messages.

- If report formatting changes, refresh the README report examples.

- Do not commit directly to `main` unless you have explicit maintainer approval.

Incompatible API changes: The naming conventions, error semantics, and
safety guarantees are part of the documented and stable API and must not
change without compelling justification and impact analysis. When possible,
provide a compatibility mechanism to preserve prior behavior (for example, a
feature flag or macro to enable/disable the new behavior).

API compatibility policy:

- Treat published APIs as additive by default. Add new symbols for new behavior
  instead of changing existing signatures.
- Keep existing return code meanings stable. New error codes may be added, but
  existing codes and semantics must remain backward compatible.
- Keep default behavior backward compatible. New behavior should be opt-in via
  explicit flags, options, or macros.
- Deprecate before removing. Reserve removals or incompatible changes for major
  version updates with migration guidance.
- Preserve documented ownership, timeout, path, and thread-safety semantics
  unless a major version explicitly revises them.
- Maintain compatibility tests so previously supported call patterns continue
  to pass as new features are introduced.

## Example Test Report

```text
BriteTest Report
                             Pass   Fail     Fault
--------------------------------------------------
1. Orchestrator                 4
2. Guard 1 and 2                6
--------------------------------------------------
                      Total    10
```

## Example Test Report for -i Option

```text
BriteTest Report (-i)

                             Pass   Fail     Fault
--------------------------------------------------
1. Orchestrator                 4      1         1
2. Guard 1 and 2                6      2         1
--------------------------------------------------
                      Total    10      3         2
```

## Repository Layout

GitHub repository: `paulsinclair51/BriteTest`

Repository layout (with core files listed):

<details>
<summary>Click to view</summary>

```text
BriteTest/
|- .github/
|  \- workflows/
|     \- britetest_ci.yml
|- LICENSE
|- Makefile
|- README.md
|- build_test_britetest.ps1
|- build/
|- docs/
|- examples/
|- include/
|  \- britetest_runner.h
|- reports/
|  |- britetest_test_report-i.txt
|  \- britetest_test_report.txt
|- scripts/
|- src/
|  \- britetest_runner.c
|- tests/
|  |- test_britetest.c
|  |- test_orchestrator.c
|  |- test_guard1.c
|  \- test_guard2.c
```
<details>
<summary>Click to view</summary>k

Use this as a reference when adapting BriteTest into your own project structure.

## Further Reading

- [include/README.md](include/README.md)
- [src/README.md](src/README.md)
- [tests/README.md](tests/README.md)
- [reports/README.md](reports/README.md)

## Glossary

<details>
<summary>Click to view</summary>

- `API`: Application Programming Interface.
- `category`: A labeled set of `BT_GROUP` and `BT_TEST` macro whose combined
             results are written by `BT_WRITE_RESULT` to the report with a
             specified category name.
- `control file`: A previously generated file that can be compared to a newly
                  generated file for differences (typically, if there are
                  differences (other than expected differences like a timestamp
                  change) this indicates a failure of the test. In some cases,
                  the control file is out-of-date and needs to be replaced
                  by promoting the new file to be the control file.
- `customization suppport functions`: API functions provided to support
   customizing the orchestrator and test group functions.
   See [Customization Support Functions](#customization-support-functions).
- `default report filename`: The report filename BriteTest uses when only a
  directory path (or no `PATH`) is provided.
- `executable`: The compiled test program that runs the orchestrator and test
  functions.
- `fail`: A counted test failure where the BT_TEST or BT_INJECT_TEST
   expression evaluates to false (i.e., zero).
- `fault`: A counted runtime fault captured by BriteTest guards (for example,
  invalid memory access).
- `Concurrent block`: A set of tests (BT_TEST and BT_INJECT_TEST macros)
   bracketed by `BT_BEGIN_CONCURRENT` and `BT_END_CONCURRENT;`.
- `group': see `test group`.
- `guard`: The protection mechanism used to catch runtime faults and continue
  test execution.
- `guard level`: The nesting depth of active guards while test groups and tests run.
- `inject mode (-i)`: Optional command-line flag that enables an BT_INJECT_TEST to
   be executed.
- `isolation`: Execution mode for BT_GROUP, BT_TEST, or BT_INJECT_TEST.
  `0` = same thread, `1` = separate thread, `2` = separate process.
- `maxargs`: The maximum number of command-line arguments accepted by
  orchestrator parsing. Optional arguments may be omitted.
  `BT_PARSE_ARGS` handles the first two arguments (executable name and optional
  `PATH`) when provided. Any additional arguments must be parsed by custom code
  added to the orchestrator.
- `maxparallel`: Upper bound on concurrent BT_GROUP, BT_TEST, BT_INJECT_TEST. Value set in
   BT_INIT_ORCHESTRATOR and BT_GROUP macros.
- `notes`: Optional text for BT_CLOSE_REPORT to append to the report before closing it.
- `orchestrator`: The `main` function that initializes BriteTest, runs groups or tests,
  and writes report output.
- `pass`: A counted successful test where the BT_TEST or BT_INJECT_TEST
   expression evaluates to true (i.e., non-zero).
- `PATH`: Optional command-line output destination; can be a report file path
  or directory path.
- `process isolation`: Isolation mode where a test group or test runs in a
  separate process.
- `project`: Project identifier used in orchestrator initialization and default
  report naming.
- `test group`: a grouping of `BT_TEST` and, optionally, `BT_GROUP` macros.
- `test group function`: A function declared with the `BT_DECLARE_GROUP` macro
   that contains 'BT_TEST' and 'BT_GROUP` macros.
- `thread isolation`: Isolation mode where a test/assert call runs in a
  separate thread.
- `test case`: This term is not used in BriteTest. In some contexts, it means
   a single individual test and, in other contexts, a set of tests, In BriteTest, the former
   is referred to as a test (or test expression) and the latter, as a test group.
- `test`: see test expression.
- `test expression`: An expression passed to an `BT_TEST` macro that can be cast
   to `int`; `0` means fail and a nonzero value means pass. The expression
   typically is a function call or contains function calls. A function could
   be in the project being tested or a testing function to implement the test.
- `testing artifact`: typically, a file generated by the test executable (e.g.,
   a test report) but also stdout and stderr output plus anything that is captured
   by the test executable or the BriteTest framework.
- `testing function`; a user written function to implement or help implement a
   test expression.
- `test support functions`: API functions provided to simplifying writing
   tests. See [Test Support Functions](#test-support-functions).
- `title`: Optional report header text provided when opening the report.
</details>
