# LiteTest

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Latest Release](https://img.shields.io/github/v/release/paulsinclair51/LiteTest?display_name=tag)](https://github.com/paulsinclair51/LiteTest/releases)
[![CI](https://github.com/paulsinclair51/LiteTest/actions/workflows/ci.yml/badge.svg)](https://github.com/paulsinclair51/LiteTest/actions/workflows/ci.yml)

LiteTest is a lightweight Application Programming Interface (API) and framework for defining,
running, and reporting tests in C/C++ projects. It is implemented as a single `.h` and `.c` pair
with no external dependencies requiring only a POSIX.1‑2001 environment and a C99‑compliant compiler.

Copyright (c) 2026 paulsinclair51  
SPDX-License-Identifier: MIT. See `LICENSE` for details.

<details>
<summary><strong>📘  TABLE OF CONTENTS  📘</strong></summary>

- [Quick Start](#quick-start)
- [Documentation Scope](#documentation-scope)
- [Key Features](#key-features)
- [API Usage Requirements](#api-usage-requirements)
- [How LiteTest Compares](#how-litetest-compares)
- [Overview](#overview)
- [Core API Macros](#core-api-macros)
  - [Orchestrator (main) Function Macros](#orchestrator-main-function-macros)
  - [Test Group Function Macros](#test-group-function-macros)
  - [Test Group and Test Macros](#test-group-and-test-macros)
  - [Parallel Execution](#parallel-execution)
  - [Concurrent Block Macros](concurrent-block-macros)
  - [Isolation Modes and Fault Handling](#isolation-modes-and-fault-handling)
- [Customization](#customization)
- [Test Support Functions](#test-support-functions)
- [Modules (.c files)](#modules-c-files)
  - [Example: lubtype Testing](#example-lubtype-testing)
  - [Example: LiteTest Self-Testing](#example-litetest-self-testing)
- [Orchestrator (main) Function Template](#orchestrator-main-function-template)
- [Test Group Function Template](#test-grouo-function-template)
- [Example Usage](#example-usage)
- [Building the Test Executable](#building-the-test-executable)
  - [Linux / macOS](#linux--macos)
  - [Windows (POSIX Toolchain Required)](#windows-posix-toolchain-required)
- [Executable Usage](#executable-usage)
  - [PATH](#path)
  - [-I Option](#i-option)
  - [--help and -h Help Options](#help-and--h-help-options)
- [Common Pitfalls](#common-pitfalls)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [Example Test Report](#example-test-report)
- [Example Test Report for -I Option](#example-test-report-for--i-option)
- [Repository Layout](#repository-layout)
- [Further Reading](#further-reading)
- [Glossary](#glossary)
</details>

## Quick Start

LiteTest tests are C/C++ expressions/functions, and the orchestrator controls
reporting and execution.

1. To try LiteTest, copy 'litetest.h' and 'litetest.c' to your current directory:

```sh
cp /path/to/litetest.h .
cp /path/to/litetest.c .
```

2. Create a file named `test_quick.c` in the same directory.

3. Paste the code into `test_quick.c`:

<details>
<summary>💻 Click to view and copy code</summary>

```c
#include "litetest.h"

// A simple test group function.

static LT_DECLARE_GROUP(test_quick)
{
  LT_INIT_GROUP(test_quick, 1);

  int a = 2;
  int b = 2;

  // 4 test assertions.
  LT_TEST(a == b, 0);        // Pass
  LT_TEST(a + b == 4, 0);    // Pass
  LT_TEST(a - b == 1, 0);    // Fail
  LT_TEST(LT_FAULT(1), 0);   // Fault

  LT_RETURN;
}

// A simple orchestrator (main) function.

LT_DECLARE_ORCHESTRATOR(main)
{
  LT_INIT_ORCHESTRATOR(main, quick, 1);
  LT_PARSE_ARGS(2, "quick_test_report.txt");
  LT_OPEN_REPORT("Test Quick Report");

  // Single test category.
  LT_WRITE_RESULT(LT_GROUP(test_quick), "Quick tests");

  LT_CLOSE_REPORT("Note: This report is a very simple example of using LiteTest.\n"
                  "Note: Multiple test categories can be added using multiple\n"
                  "      test functions.\n"
                  "Note: Orchestrator (`main`) and test functions can be placed in\n"
                  "      individual modules (.c files).\n"
                  "Note: Parameters can be set to run tests in parallel, isolate\n"
                  "      a test to a separate thread or process, etc.\n"
                  "Note: The expression for LT_TEST can reference functions to\n"
                  "      provide a more complex test. A non-zero result indicates\n"
                  "      pass and a zero result indicates fail. If a fault occurs\n"
                  "      executing the expression, it is detected and counted in\n"
                  "      the report as a fault.\n"
                  "Note: Larger projects can place files in a more conventional\n"
                  "      layout (e.g., `include/` and `src/`, but this example keeps\n"
                  "      everything in your current directory for simplification.\n"
                  "Note: See README.md for LiteTest for additional API features.\n");
  LT_EXIT;
}
```
</details>

4. Build the executable `test_quick` in your current directory:

```sh
cc -std=c99 -Wall -Wextra -o test_quick test_quick.c litetest.c
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
LiteTest Report
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

This README serves as the introduction and usage guide to LiteTest. It focuses on concepts,
workflow, and practical examples to help you quickly integrate LiteTest into your project.

Detailed API behavior, macro semantics, and lower‑level implementation details are documented
directly in `include/litetest.h`.

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

LiteTest requires:

- POSIX.1‑2001 (IEEE Std 1003.1‑2001) compatibility.
- A C99‑compliant compiler.

Supported environments:

- Linux, macOS, BSD — fully compatible.
- Windows — requires a POSIX layer such as Cygwin, MSYS2, or WSL.

LiteTest has been exercised in POSIX environments; users should
validate behavior in their own systems.
</details>

## How LiteTest Compares

<details>
<summary>Click to view</summary>

| Framework     | Language / Style | Dependencies | Fault Isolation | Strengths | How LiteTest Differs |
|---------------|------------------|--------------|-----------------|-----------|------------------------|
| **Unity**     | C, macro‑heavy   | None         | No              | Widely used, simple API | LiteTest adds POSIX signal‑based fault isolation and category‑level reporting. |
| **cmocka**    | C, function‑based | None        | Yes (setjmp)    | Mature, feature‑rich | LiteTest is smaller, header‑driven, and easier to embed in small projects. |
| **Check**     | C, process‑based | POSIX tools  | Yes (fork)      | Strong isolation, fixtures | LiteTest avoids process spawning and keeps a minimal footprint. |
| **Criterion** | C, auto‑discovery | libc, POSIX | Yes             | Modern, fast, rich output | LiteTest is simpler, portable, and avoids auto‑discovery complexity. |
| **LiteTest**  | C99, macro‑driven | None        | Yes (POSIX signals) | Minimal, portable, easy to embed | Designed for small C projects needing fault isolation without heavy frameworks. |
</details>

## What LiteTest Does Not Provide

<details>
<summary>Click to view</summary>

LiteTest focuses on executing tests and reporting results. It does not:

- Generate test source files — users write their own test modules.
- Perform automatic test discovery — tests are invoked explicitly by the orchestrator or from within test functions.
- Provide mocking or stubbing frameworks — users implement their own mocking and stubbing.
- Include built‑in setup/teardown systems — users implement their own patterns as needed.
- Handle memory management or leak detection — external tools (e.g., Valgrind) must be used.
- Manage source control or repository structure — LiteTest does not define SCM workflows.
- Integrate with build systems or CI pipelines — users configure these as needed.
- Manage test artifacts such as expected‑output (“control”) files.
- Define or enforce directory layouts for tests or project structure.
- Promote output files to control files — users handle this workflow manually.
- Track versioning or history of test artifacts.
- Produce rich reporting formats such as JUnit XML or HTML output.
- Provide functionality outside the features explicitly described in this document.
</details>

## Overview

LiteTest is a lightweight C/C++ testing framework built around a simple execution model:
1. You write C test expressions (that typically invoke functions) for each test and wrap each
   of these expressions with the `LT_TEST` macro in a test group function.
2. You wrap each test grouo function name with the `LT_GROUP` macro in the orchestrator.
3. The orchestrator (`main`) function runs the test group functions and reports results.

The LiteTest API and framework files:

 - [`include/litetest.h`](include/litetest.h) — public API (typedefs, enums, constants, macros,
   function declarations, and static inline function definitions).
 - [`src/litetest.c`](src/litetest.c) — function definitions for the LiteTest framework.

A typical test executable includes:

- An orchestrator (`main`) function that opens the report, invokes test group functions,
  writes category results, and closes the report.
- Multiple test group functions that execute the tests.
- The LiteTest API and framework files (`litetest.h`, `litetest.c`). 
- The headers and source files for the project being tested.

Recommended: Put the orchestrator function in one source file and each test group function
in its own source file.
   
When executed, LiteTest produces a report summarizing tests by category, including:

- Pass/fail/fault counts per category.
- Totals across all categories.
- Notes describing each failure or fault.

## Core API Macros

### Orchestrator (`main`) Function Macros

- `LT_DECLARE_ORCHESTRATOR(funcname)[;]`
- `LT_INIT_ORCHESTRATOR(funcname, project, [maxparallel]);`
- `LT_PARSE_ARGS([maxargs], ["defaultreportfilename"]);`
- `LT_OPEN_REPORT(["title"]);`
- test group and test macros,
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

### Test Group Function Macros

- `LT_DECLARE_GROUP(funcname)[;]`
- `LT_INIT_GROUP(funcname, [maxparallel]);`
- test and test group macros.
- `LT_RETURN;`

Note:
- `funcname` must not be main and must be same for the first two macros when
  defining a test group function.
- For the first macro, a semicolon is required for a forward declaration;
  otherwise, omit the semicolon and follow with a definition in `{ }`.

### Test Group and Test Macros

- `LT_GROUP(funcname, [isolation])[;]`
- `LT_TEST(expression, [isolation])[;]`
- `LT_TEST_I(expression, [isolation])[;]`

The semicolon is omitted if used as an argument to the LT_WRITE_RESULT macro;
otherwise it is required.

`LT_TEST_I` is the same as `LT_TEST` except:

-  Only executes if injection is enabled (see [`-I` Option](#I-option)).
-  Result is counted as a pass/fail/fault and as an injected pass/fail/fault.

Special values that can be used in any expression:

- LT_PASS: returns 1.
- LT_FAIL: returns 0. Note this does force a fail. A fail occurs only if the test
  expression evaluates to 0.
- LT_FAULT(type): causes a fault of the specified type: 1 (`SIGSEGV`). 2 (`SIGABRT`), 3 (`SIGBUS`).
  For other values of type, LT_FAULT returns 0.

### Parallel Execution

Parallel execution of the test group and test macros is enabled/disabled by the
`maxparallel` parameter for the LT_INIT_ORCHESTRATOR and LT_INIT_GROUP
macros. Up to `maxparallel` test group and test macros are started and when one
finishes another is started.

### Concurrent Block Macros

The concurrent block macros ensure that all test macros inside it start together:

- The tests are bracketed with:
  - `LT_BEGIN_CONCURRENT(blockname)`
  - `LT_END_CONCURRENT(blockname)`
- Within a test group function, a concurrent block cannot be nested inside another
  concurrent block.

### Isolation Modes and Fault Handling

LiteTest supports two execution isolation modes that balance speed and fault‑isolation. Both modes run
tests in a single thread within each process; the difference is whether all test groups and tests run
inside one process or each runs in its own process.

`isolation`:
- 0 same thread (no parallelism)
- 1 separate thread
- 2 separate processx

Defaults:
- Tests and test groups not within a concurrent block: 0.
- Tests within a concurrent block: 1.

Invalid combinations are rejected.

A fault s handled as follows:

- The fault is recorded
- Execution continues
- The execution completes normally
- The final report includes fault counts and messages

This allows you to test low‑level or unsafe code without aborting the entire
test run.

1. Single‑Process Mode (default)

In this mode, all test groups and tests run sequentially inside a single process and a single thread.
This provides the fastest execution and the simplest debugging experience.

LiteTest installs a signal guard that can detect and report certain synchronous faults,
including:

- SIGSEGV (invalid memory access)
- SIGBUS  (bus error)
- SIGFPE  (arithmetic error)
- SIGILL  (illegal instruction)

These faults can be caught and reported without terminating the test run.

However, some failures cannot be isolated in a single process. If a test triggers one of the
following, the entire LiteTest process terminate:

- SIGABRT (abort(), assert() failures, malloc corruption)
- SIGKILL, SIGSTOP
- external termination signals (SIGTERM, SIGINT, SIGHUP)
- sanitizer aborts
- undefined behavior that escalates to process termination
- deadlocks, infinite loops, or resource exhaustion

Single‑process mode is ideal for everyday development and fast feedback, but it does not
provide complete fault isolation.

2. Process‑Isolated Mode (parallel or serial)

In this mode, each test group and test runs in its own child process. LiteTest monitors each child and
reports its result after the process exits.

Because each test group and test runs in a separate process, LiteTest can isolate:

- SIGABRT and all abort‑based failures
- memory corruption that triggers allocator aborts
- sanitizer aborts
- undefined behavior that terminates the process
- deadlocks (child can be killed)
- infinite loops (child can be timed out)
- resource exhaustion
- all synchronous faults (SIGSEGV, SIGBUS, SIGILL, SIGFPE)

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

Both modes use the same LT_GROUP, LT_TEST, and LT_TEST_I macros. The choice of isolation
mode affects only how test groups and tests are executed, not how they are written.

## Customization

Additional functions, macros, typedefs, and variables are
provided to support customization.

Examples include:

<details>
<summary>Click here for list</summary>

- `lt_executablename`
- `lt_result_t`
- `lt_dirpath`
- `LT_MAX_PATH_LEN`
- `lt_currentlevel`
- `lt_currentresult`
- `lt_maxparallel`
- `lt_blockname`
- `lt_iswritedirpath`
</details>

See [include/litetest.h](include/litetest.h) for documentation on the provided
customization functions.

## Test Support Functions

Additional functions are provided to support writing tests.

Examples of Process and runtime helpers include:

- `int lt_execute(const char *commandline, int timeout, char *outbuf, size_t outsz, int *exit_code)`
- `int lt_wait_until(int (*predicate)(void *ctx), void *ctx, int timeout_ms, int interval_ms)`

Examples of File and filesystem helpers include:

- `int lt_copyfile(const char *src, const char *dst)`
- `int lt_mktempdir(const char *prefix, char *outpath, size_t outsz)`
  
Examples of Comparison and matching helpers include:

- `int lt_filecmp(FILE *f1, FILE *f2)`
- `int lt_filecmpfilepath(FILE *f, const char *fp)`
- `int lt_filepathcmp(const char *fp1, const char *fp2)`
- `int lt_filepathcmpfile(const char *fp, FILE *f)`
- `int lt_match(const char *text, const char *pattern)`

Example of Environment helpers:

- `int lt_with_env(const char *name, const char *value, int (*fn)(void *), void *ctx)`

See [include/litetest.h](include/litetest.h) for documentation on the provided
test support functions.
  
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

<details>
<summary>💻 Click to view and copy</summary>

```c
LT_DECLARE_ORCHESTRATOR(main)
{
  LT_INIT_ORCHESTRATOR(main, project, [maxparallel]);
  LT_PARSE_ARGS([maxargs], ["defaultfilename"]);
  LT_OPEN_REPORT(["title"]);

  // Insert group/test/write calls here:
  //   LT_GROUP(funcname, [isolation]);
  //   LT_TEST(expression, [isolation]);
  //   LT_TEST_I(expression, [isolation]);
  //   LT_WRITE_RESULT(LT_GROUP(funcname, [isolation]), "category");
  //   LT_WRITE_RESULT(LT_TEST(expression, [isolation]), "category");
  // Group test/assert calls using:
  //   LT_BEGIN_CONCURRENT(groupname);
  //   LT_END_CONCURRENT(groupname);

  LT_CLOSE_REPORT(["notes"]);

  LT_EXIT;
}
```
</details>

`LT_WRITE_RESULT` writes one category and resets its counts. Totals accumulate
across the full run.

Optional typedefs, variables, functions, and code may be added to customize
or support testing. Added code may use test support functions. **Recommended**:
do not intermix code with the tests; such code is handled as if it occurs
before the tests.

Forward-declaration:

```c
LT_DECLARE_ORCHESTRATOR(main);
```

## Test Function Template

<details>
<summary>💻 Click to view and copy</summary>

```c
[static] LT_DECLARE_TEST(funcname)
{
  LT_INIT_TEST(funcname, [maxparallel]);

  // Insert test/group calls here:
  //   LT_TEST(expression, [isolation]);
  //   LT_TEST_I(expression, [isolation]);
  //   LT_GROUP(funcname, [isolation]);
  // Group test/assert calls using:
  //   LT_BEGIN_CONCURRENT(groupname);
  //   LT_END_CONCURRENT(groupname);

  LT_RETURN;
}
```
</details>

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

<details>
<summary>Click to view</summary>

- `test_litetest.c` defines the orchestrator (`main`) with two test
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
LiteTest project as a starting point for creating your Makefile in your
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

On Windows, use `build_test_litetest.ps1` to build and run the test executable:

```powershell
./build_test_litetest.ps1
.\test_litetest.exe
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
existing file is overwritten):

```sh
test_<testname> [-I] [PATH]
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

### `-I` Option

The `-I` option enables LT_TEST_I macros to execute,
Use it to exercise the LiteTest framework and verify report
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

## Repository Layout

GitHub repository: `paulsinclair51/LiteTest`

Repository layout (with core files listed):

```text
LiteTest/
|- .github/
|  \- workflows/
|     \- ci.yml
|- LICENSE
|- Makefile
|- README.md
|- build_test_litetest.ps1
|- build/
|- docs/
|- examples/
|- include/
|  \- litetest.h
|- reports/
|  |- litetest_test_report-i.txt
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

## Further Reading

- [include/README.md](include/README.md)
- [src/README.md](src/README.md)
- [tests/README.md](tests/README.md)
- [reports/README.md](reports/README.md)

## Glossary

- `API`: Application Programming Interface.
- `category`: A labeled set of LT_GROUP, LT_TEST, or LT_INJECT_TEST whose combined results are written by
  `LT_WRITE_RESULT` to the report with a specified category name.
- `control file`:  
- `default report filename`: The report filename LiteTest uses when only a
  directory path (or no `PATH`) is provided.
- `executable`: The compiled test program that runs the orchestrator and test
  functions.
- `fail`: A counted test failure where the LT_TEST or LT_INJECT_TEST
   expression evaluatess to false (i.e., zero).
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
- `test group`: a grouping of tests and optionally nested groups.
- `test group function`: A function declared with LiteTest group macros that contains
 tests or nested groups.
- `thread isolation`: Isolation mode where a test/assert call runs in a
separate thread.
- `test case`: This term is not used in LiteTest. In some contexts, it means
   a single individual test and, in other contexts, a set of tests, In LiteTest, the former
   is referred to as a test and the latter, as a test group.
- `test`: see test expression.
- `test expression`: An expression passed to an LT_TEST or
   LT_INJECT_TEST macro that can be cast to `int`; `0` means fail and any
   nonzero value means pass. The expression typically is a function call or
   contains function calls. A function could be in the project being tested or
   a testing function to implement the test.
- `testing artifact`:
- `testing function`; a user written function implement or help implement a test.
- `test suppport functions`: API functions provided to simplifying writing
   tests. See  [Test Support Functions](#test-support-functions).
- `title`: Optional report header text provided when opening the report.
