# LiteTest
LiteTest is an application programming interface (API) and testing framework for use
by a test orchestrator and its test category modules

Copyright (c) 2026 paulsinclair51
SPDX-License-Identifier: MIT For license details, see the LICENSE file in the paulsinclair51/lubtype repository root.

## Overview

LiteTest is a compact, POSIX‑aware C/C++ testing framework designed for orchestrators and
modular test categories. It’s intentionally minimal, signal‑safe, and built for embedding into
other C/C++ projects.

The API and test framework is defined in [litetest.h](litetest.h) and [litetest.h](litetest.c). Key points:

1. Provides the following test and assert macros:

   - LT_TEST(func)
   - LT_ASSERT(assert_expr)
   - LT_ASSERT_FAIL
   - LT_ASSERT_FAULT

3. Provides the following orchestrator macros.

   - LT_DECLARE_MAIN(testsuite)
   - LT_OPEN_REPORT("reporttitle")
   - LT_WRITE_RESULT([t], "categoryname")
   - LT_CLOSE_REPORT
   - LT_RETURN_STATUS

3, Provides the following test function macros:

   - LT_DECLARE_FUNC(func)
   - LT_INIT_TEST;
   - LT_RETURN_RESULT

4. Utility functions:

   - lt_current_guard_level, lt_current_result, lt_current_total, etc.

5. The test and assert macros provide signal handlers (`SIGSEGV`,
`SIGABRT`, `SIGBUS`) to capture faults. Faults are counted as a `fault`
rather than aborting execution, allowing testing to continue.

6. The orchestrator (main) function and the optional test functions (func) may be defined
in a single module (.c file) or split across multiple modules. When there is one or more
test functions, the recommended best practice is to place the main function in one module
and each test function in its own module.
   
## Orchestrator



To merge the results of subcategory test and assert functions for the result
in the orchestration (main) function:

  `{`LT_TEST(func);` | `LT_ASSERT(asser_expr);`}...`
  `LT_WRITE_RESULT(, "categoryname")`

or

  `{`LT_TEST(func);` | `LT_ASSERT(asser_expr);`}...`
  `LT_WRITE_RESULT(`LT_TEST(func);` | `LT_ASSERT(asser_expr);`, "categoryname")`

  

To merge the results of three subcategory test modules for the result of the category:

  `MERGERUN_AND_REPORT("<category name>",
				          MERGE(
                  MERGE(RUN(test_<cat_1>, inject),
                        RUN(test_<cat_2>, inject)},
								            RUN(test_<cat_3>, inject));`

Continue pattern to merge more results.

## Orchestor API

## Testing with a Guard

### TEST

### RUN

## Example Self-Test litetest API and Framework

/paulsinclair51/litetest/tests provides an example for using the API framework
with a test orchestrator (test_litetest.c) with two test categories
(test_orchestrator.c and test_guards.c) that tests self-tests the litetest
API and framework.

## Example Test lubtype API

/paulsinclair5/lubtype/test provides an example with a test orchestrator
(test_lubtype.c) and test categories (test.charclass.c, test_count.c,
test_compare.c, et.)

## Building and Running

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
