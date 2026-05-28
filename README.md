# LiteTest
LiteTest is an application programming interface (API) and testing framework for use
by a test orchestrator and its test category modules

Copyright (c) 2026 paulsinclair51
SPDX-License-Identifier: MIT For license details, see the LICENSE file in the paulsinclair51/lubtype repository root.

## Overview

LiteTest is a compact, POSIX‑aware C/C++ testing framework designed for orchestrators and
modular test categories. It’s intentionally minimal, signal‑safe, and built for embedding into
other C/C++ projects.

The test framework is defined in [litetest.h](litetest.h). Key points:
1. Provides the following test macros:
   - TEST(<assert_expr) where <assert_expre> is an expression that returns nonzero if test passed and 0 if test failed.
   - TESTS(func, inject) where function has the signature resuLt_t <funcname>(char inject),
   - TESTSMERGE(func1, func2, inject)
   - TEST_FAIL(inject)
   - TEST_FAULT(inject)
2. Provides the following orchestrator macros.
   - OPEN_REPORT
   - WRITE_CATEGORY(t, catname) where t is a TEST* macro and catname is string for category name.
   - CLOSE_REPORT
3, Provides the following test module macros:
   RETURN_RESULT
4. Each test.<cat>.c file has a `lt…result_t test_<cat>(char inject)` function.
   - The file may define other functions, macros, types, and variables for implementing tests.
   - The test_<cat function includes a test list of RUN, MERGE_RUN, INJECT_FAIL, and INJECT_FAULT macro refernces.
5. The test.<testsuite>.c file has a `main`function.
   - The file may define other functions, macros, types, and variables for implementing the orchestrator.
   - The  function `main` contains OPEN_REPORT followed by a list of REPORT macro references wrapped around a TEST* macro reference (e.g., REPORT(TEST(func, inject), REPORT(TESTS_MERGE(func1, func2, inject), and followed by CLOSE_REPORt.
6. The test macros provide signal handlers (`SIGSEGV`, `SIGABRT`, `SIGBUS`) to capture faults. Faults are counted as a `fault` rather than aborting execution, allowing the testing to continue.

## Adding a New Category Test Module

1. Create `test_<cat>.c` that defines function test_<cat>. Specify tests in the function using the test macros (TEST, RUN, RUN_AND_MERGE, INJECT_FAIL, and INJECT_FAULT.
2. In `test_<test_suite>.c:
a. Add a declare of the new test category function in the function declaraion section:
   `result_t test_<cat>(const char inject);`
b. Add a call in the write_report section:
   RUN_AND_REPORT("<category name>",  RUN(test_<cat>, inject));
6. Add the source to `TEST_SOURCES` in the Makefile (compiled once).
   
## Merging Results of SubCategory Test Modules

To merge the results of runs of two subcategory test modules for the result of the category:

  `MERGERUN_AND_REPORT("<category name>",
				              test_<cat_1>, test_<cat_2>, inject)));`

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
