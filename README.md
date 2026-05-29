# LiteTest

LiteTest is a C/C++ application programming interface (API) and testing framework for use
by a test orchestrator (main) function and optional test functions.

LiteTest is intentionally lightweight, signal‑safe (POSIX-aware), and built for embedding into
other C/C++ projects. The API is designed to be easy to use while still providing
comprehensive testing functionality and customization.  

The API and framework do not implement the actual tests/asserts; these must be provided
as part of implementing the test executable.

Copyright (c) 2026 paulsinclair51
SPDX-License-Identifier: MIT For license details, see the LICENSE file in the paulsinclair51/lubtype repository root.

## Overview

The API and test framework is defined in [litetest.h](litetest.h) and [litetest.h](litetest.c).

Key points:

1. An executable is built from the orchestrator (main) function, optional
test functions (func), litetest.c, and litetest.h plus modules and include
files from the feature/projecdt/API to be tested.
   
3. The executable generates a report file of results grouped into categories with
pass/fail/fault counts foe each category plus totals across categories.
For fail and faults, error messages are written to stdout (which is concatenated
to the report and then the stdout file is removed).

4. The orchestrator (main) function and optional test functions (func) may be defined
in a single module (.c file) or split across multiple modules. When there is one or more
test functions, the recommended best practice is to place the orchestrator (main)
function in one module and each test function in its own module.
   
6. The API provides the following test and assert macros:

   - LT_TEST(func)
   - LT_ASSERT(assert_expr)
   - LT_ASSERT_FAIL
   - LT_ASSERT_FAULT
  
   These macros provide multi-level signal handling (`SIGSEGV`,
   `SIGABRT`, `SIGBUS`) to capture faults. Faults are counted as a `fault`
    rather than aborting execution within the orchestrator (main),
    test function (func), or assert_exprr allowing testing to continue
    and a test report to be generated.

7. The API provides the following orchestrator (main) macros.

   - LT_DECLARE_MAIN(testsuite)
   - LT_INIT_TEST
   - LT_PARSE_ARGS
   - LT_OPEN_REPORT("reporttitle")
   - LT_WRITE_RESULT([t], "categoryname")
   - LT_CLOSE_REPORT
   - LT_RETURN_STATUS

5, The API provides the following test function (func) macros:

   - LT_DECLARE_FUNC(func)
   - LT_INIT_TEST
   - LT_RETURN_RESULT

6. The API proivdes utility functions, e.g.:

   - lt_current_guard_level, lt_current_result, lt_current_total
  
## Modules (.c files)

Include litetest.h and any needed feature/project/API/standard include files
in a module containing orchestrator (main) function or test fucntion (func).

For example to test the lubtype API:

```c
#include "lubtype.h"
#include "litetest.h"
```

For example, to have LiteTest test itself:

```c
#include "litetest.h"
```

/paulsinclair51/litetest/tests provides an implementation using the API and framework
to self-test the LiteTest API and framework. The implmeementation consists of
test orchestrator (main) function (defined in test_litetest.c) with two test
categories:

- "Orchestrator" (test_orchestrator.c defines the test_orchestrator function).

- "Guard" (test_guard1.c defines the test_guard1 function and
test_guard2.c defines the test_guard2 fucnction).

## Orchestrator (main) Function

```c
LT_DECLARE_MAIN(testsuite)
{
  LT_INIT_TEST;
  LT_PARSE_ARGS;
  LT_OPEN_REPORT("reporttitle");

  // Tests
  [[LT_TEST(func); | LT_ASSERT(asser_expr);]...
  LT_WRITE_RESULT([LT_TEST(func) | LT_ASSERT(asser_expr)], "categoryname")]...

  LT_CLOSE_REPORT;
}
```

Results are accumulated up to LT_WRITE_RESULT and then reset.
Totals are accumalated across all the tests.

Optional typedefs, variable, functions, code etc. may be
added to customize or support the testing. Added code may
use utility functions.

To have a forward reference to the orchestrator (main) function:

```c
LT_DECLARE_MAIN(testsuite);
```

## Test Function (func)

```c
[static] LT_DECLARE_FUNC(func)
{
  LT_INIT_TEST;

  // Tests
  [LT_TEST(func); | LT_ASSERT(asser_expr);]...

  LT_RETURN_RESULT;
}
```

Specify static if the function is only referenced in the same module.

To have a forward reference to the test test function (func):

```c
[static] LT_DECLARE_FUNC(func);
```

Specify static if the above defintion of the function specifies static.

## Testing with a Guard

### TEST

### RUN

## Example Test lubtype API

/paulsinclair5/lubtype/test provides an example with a test orchestrator
(test_lubtype.c) and test categories (test.charclass.c, test_count.c,
test_compare.c, et.). Currently, repository is private.

## Building and Executing

### Linux / macOS

This is the primary supported and currently validated test environment.
In practice, Linux is the canonical path for running the test suite,
including GitHub Codespaces.

From this directory:

```sh
make
make run
./test_lubtype --help
```

Or from the repository root:

```sh
make -C tests run
./tests/test_lubtype --help
```

To build with gcc instead of clang:

```sh
make -C tests CC=gcc run
```

### Windows (POSIX Toolchain)

From this directory:

```powershell
./build_test_<api>.ps1
.\test_<api>.exe
```

On Windows, the test runner currently requires a POSIX-capable C toolchain
because the test framework uses POSIX signal and setjmp APIs.
Use a toolchain such as MSYS2 UCRT64 or Clang64 and ensure `cc`, `clang`,
or `gcc` is on `PATH` before running the PowerShell script.

Windows build documentation and the helper script
`build_test_lubtype.ps1` are provided for convenience, but this Windows
path has not been tested in this repository because the required toolchain
has not been set up in the current environment.

A tested setup is MSYS2 UCRT64 with these packages installed:

```powershell
pacman -S --needed base-devel mingw-w64-ucrt-x86_64-gcc
```

Then run PowerShell from an environment where the MSYS2 UCRT64 `bin`
directory is on `PATH`, or launch PowerShell from the MSYS2 UCRT64 shell
after exporting that toolchain path into the session.

If you prefer Clang, MSYS2 Clang64 is also suitable with the corresponding
Clang toolchain packages, as long as `cc`, `clang`, or `gcc` resolves to the
POSIX-capable compiler in that environment.

### Makefile Targets

| Target  | Description                              |
|---------|------------------------------------------|
| `all`   | Build the `test_<api>` executable      |
| `run`   | Build and run the test suite             |
| `clean` | Remove object files and the executable   |

By default, running the test suite writes `<api>_test_report.txt` and `<api>pe_test_report-i.txt` in the current working directory. You can control the output location with the optional PATH argument (see below).

### Executable Usage

To execute the tests, run the test executable:

`test_<test> [-i] [PATH]`

1. If `PATH` is a file path to an existing or nonexistent file, the test report is written to that file.
2. If `PATH` is a directory path (with or without a trailing separator) to an existing directory, the report is written to the file in that directory with a default filename.
3. If `PATH` is omitted, the test report is written to the file in the current working directory with a default filename.
4. The default filename is <test>_test_report.txt or <test>_test_report-i.txt if the -i option is specified.
5. The -i options indicates to inject fails/fault tests to verify test report formatting when fails and faults occur.
6. An existing report file is overwritten.

You can display usage information at any time with the `--help` or `-h` option:

```sh
./test_lubtype [-h | --help]
```
This prints a summary of all command-line options and usage details.

## Viewing Formatted README

To view the formatted README.md while editing in VS Code:

- Open README.md and press Ctrl+Shift+V.
- For side-by-side editor + preview, press Ctrl+K then V.
- To revert to unformatted viewing, close and reopen.

For repository formatted viewing, open the README on GitHub after committing changes.
