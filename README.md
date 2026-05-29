# LiteTest

LiteTest is a lightweight C/C++ application programming interface (API) and testing framework
designed for a test orchestrator (`main`) function and optional test functions. It is
POSIX-aware, signal‑safe, and suitable for embedding into
other C/C++ projects. The API and framework is intentionally minimal while still providing 
comprehensive testing capabilites.  

LiteTest does not implement the actual tests or assertions itself; these must supplied
by the test executable.

Copyright (c) 2026 paulsinclair51
SPDX-License-Identifier: MIT
See the LICENSE file in the repository root for details.

## Overview

The API and test framework is defined in [litetest.c](litetest.c) and [litetest.h](litetest.h).

### Key Points

1. A test executable is built from:

   - The orchestrator (`main`) function.

   - Optional test functions.

   - `litetest.c`, and `litetest.h`.

   - Modules and include files from the feature/project/API under test.
   
2. The executable produces a report grouped by category, including
pass/fail/fault counts per category and totals across all categories.
Error messages for fails and faults are appeneded to the report.

4. The orchestrator and test functions may be reside
in one module or multiple modules. **Recommended**: place
the orchestrator in one module and each test function in its own module.
   
### Test and Assert Macros

- LT_TEST(func)
- LT_ASSERT(assert_expr)
- LT_ASSERT_FAIL
- LT_ASSERT_FAULT
  
These macros provide multi-level (up to 32) signal handling (`SIGSEGV`,
`SIGABRT`, `SIGBUS`) to capture faults. Faults are counted
without aborting execution, allowing test suite to continue
and produce a complete test report.

### Orchestrator (`main`) Macros

- LT_DECLARE_MAIN
- LT_INIT_TEST(testsuite)
- LT_PARSE_ARGS
- LT_OPEN_REPORT("reporttitle")
- LT_WRITE_RESULT([t], "categoryname")
- LT_CLOSE_REPORT
- LT_RETURN_STATUS

### Test Function Macros

- LT_DECLARE_FUNC(func)
- LT_INIT_TEST
- LT_RETURN_RESULT

### Utility Functions

Examples include:

- lt_current_guard_level
- lt_current_result
- lt_current_total

See [litetest.h](litetest.h) for documention on the provided utitily functions.
  
## Modules (.c files)

Modules containing the orchestrator or test functions must include `litetest.h` and
any required project headers.

### lubtype Testing Example

Include these two files:

```c
#include "lubtype.h"
#include "litetest.h"
```

`/paulsinclair5/lubtype/test` provides an example with a test orchestrator
(`test_lubtype.c`) and test categories (`test.charclass.c`, `test_count.c`,
`test_compare.c`, etc.). Currently, this repository is private.

### LiteTest Self-Testing Example

```c
#include "litetest.h"
```

`/paulsinclair51/litetest/tests` provides an self-testimplementation of
the LiteTest API and framework. It includes:

- `test_litetest.c` with two test categories "Orchestrator" and "Guard".

- `test_orchestrator.c` defines the test_orchestrator function for the
"Orchestrator catagory.

- `test_guard1.c` defines the `test_guard1` function for the "Guard" category.

- `test_guard2.c` defines the `test_guard2` function for the "Guard category.

The result of test_guard1 and test_guard2 are combined by the orchestrator
into a single result for the "Guard" category.

## Orchestrator (`main`) Function Template

```c
LT_DECLARE_MAIN(testsuite)
{
  LT_INIT_TEST(testname);
  LT_PARSE_ARGS;
  LT_OPEN_REPORT("reporttitle");

  // Tests
  [[LT_TEST(func); | LT_ASSERT(assert_expr);]...
  LT_WRITE_RESULT([LT_TEST(func) | LT_ASSERT(assert_expr)], "categoryname")]...

  LT_CLOSE_REPORT;
}
```

Results accumulated until `LT_WRITE_RESULT` and then reset.
Totals are accumulated across all tests and asserts.

Optional typedefs, variable, functions, code etc. may be
added to customize or support the testing. Added code may
use utility functions.

Forward-declaration:

```c
LT_DECLARE_MAIN(testsuite);
```

## Test Function Template

```c
[static] LT_DECLARE_FUNC(func)
{
  LT_INIT_TEST(testname);

  // Tests
  [LT_TEST(func); | LT_ASSERT(assert_expr);]...

  LT_RETURN_RESULT;
}
```

Use `static` if the function is only referenced in the same module.

Forward declaration:

```c
[static] LT_DECLARE_FUNC(func);
```

Specify `static` if the above definition of the function specifies `static`.

## Building the Test Executable

Modify a copy of an existing MakeFile to build a test executable for
a project using the modules and includes needed for that project.

### Example: Building the lubtype Test Executable

See the Makefile in the repository `paulsinclair51/lubtype/`
(currently private) to build ah test executable for the lubtype API.

### Example: Building the LiteTest SeLf-Test Executable

The LiteTest repository root directory contains a Makefile to build
and execute the exectable test_litetest to self-test LiteTest.

Npte: For other test executables,

#### Linux / macOS

This is the primary supported and currently validated environment.
Linux is the canonical path for building the test executable,
including GitHub Codespaces.

From the repository root:

```sh
make -C tests run

The Makefile builds and executes the executable test_litetest writing the test report
to the /paulsinclair51/LiteTest/reports directory as LiteTest_test_report.txt file).

The executable can then be executed directly (see
[Executable Usage](#executable-usage-readme)).

To build with gcc instead of clang:

```sh
make -C tests CC=gcc run
```

#### Windows (POSIX Toolchain Required)

Use a POSIX‑capable toolchain such as MSYS2 UCRT64 or Clang64. The test
framework depends on POSIX signals and `setjmp`.

For an untested (due to toolchain not yet being installe), refer to
the build_test_litetest.ps1 powershell script. The following is the
expected command to run the script once it has been tested:

```powershell
./build_test_litetest>.ps1
.\test_litetest>.exe
```

A tested setup is MSYS2 UCRT64 with:

```powershell
pacman -S --needed base-devel mingw-w64-ucrt-x86_64-gcc
```

Ensure the MSYS2 `bin` directory is on `PATH` before running PowerShell.

If you prefer Clang, MSYS2 Clang64 is also suitable with the corresponding
Clang toolchain packages, as long as `cc`, `clang`, or `gcc` resolves to the
POSIX-capable compiler in that environment.

## Executable Usage

To execute the tests, run the test executable:

`test_<test> [-i] [PATH]`

PATH:

PATH specifies a file path or a directory path. It may be optionally quoted (with ") or is required to be quoted if it contains spaces or other characters that requiring the path to be quoted.

= If `PATH` is a file path to an existing or nonexistent file, the test report is written to that file.

- If `PATH` is a directory path (with or without a trailing separator) to an existing directory, the report is written to the file in that directory with filename <test>_test_report.txtfilename.

- If `PATH` is omitted, the test report is written to the file in the current working directory with filenaem <test>_test_report.txt.

The default filename is `<test>name>_test_report.txt` where <testname> is the testname
specified for `LT_INIT_TEST` in the orchestrator `main` function.

The -i options indicates fail/fault asserts planted in the tests are to inject
a fail/fault. This useful to verify test report formatting when fails and faults occur.

An existing report file is overwritten.

### Help Option

You can display usage information at any time with the `--help` or `-h` option.
For example:

```sh
./test_litetest [-h | --help]
```
This prints a summary of all command-line options and usage details.

## Example Test Report

todo.

## Example Test Report for -i Option

todo.
