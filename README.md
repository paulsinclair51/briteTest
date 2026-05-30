# LiteTest

LiteTest is a lightweight C/C++ application programming interface (API) and testing framework
suitable for embedding into other C/C++ projects. The API and framework is intentionally minimal while still providing comprehensive testing capabilites.

API macros simplify developing a test orchestrator (`main`) function 
and optional test functions by abstracting the management of running tests
and report generation so you can focus on the actual tests for your project.

It is POSIX-aware so that it handle faults (`SIGSEGV`, `SIGABRT`, `SIGBUS`) without terminating,

Note that LiteTest does not implement the actual tests or assertions itself; these must be supplied
as part ot the test executable.

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

5. The test framework depends on POSIX signals, `sigaction`, `sigsetjmp`, `siglongjmp`,
and` sigjmp_buf` for capturing faults.
   
### Test and Assert Macros

- LT_TEST(funcname)
- LT_ASSERT(assert_expr)
- LT_ASSERT_FAIL
- LT_ASSERT_FAULT
  
These macros provide multi-level (default maximum of 4 levels) signal
handling to capture faults (`SIGSEGV`, `SIGABRT`, `SIGBUS`). Faults
are counted without aborting execution, allowing test suite to continue
and produce a complete test report.

Future enhancment: parallel execution of LT_TEST. Allow up to a settable
maximum of LT_TEST macros to execute (when one finishes, another is started.

Future enhancement: group a set of LT_TEST macros to run in parallel. The
number of LT_Test macros in a set must not exceed the maximum that are allowed
to execute in parallel

### Orchestrator (`main`) Macros

- LT_DECLARE_MAIN_ORCHESTRATOR
- LT_INIT_ORCHESTRATOR(testsuite, maxparallel)
- LT_PARSE_ARGS("defaultreportfilename", "tempfilename")
- LT_OPEN_REPORT("reporttitle")
- LT_WRITE_RESULT([t], "categoryname")
- LT_CLOSE_REPORT
- LT_RETURN_STATUS

### Test Function Macros

- LT_DECLARE_FUNCTION(funcname)
- LT_INIT_TEST(testname, maxparallel)
- LT_RETURN_RESULT

### Parallel Group Macros

- LT_BEGIN_GROUP(groupname)
- LT_END_GROUP(groupname)

### Utility Functions

Examples include:

- lt_currentlevel
- lt_currentresult
- lt_currenttotal
- lt_maxparallel(level)
- lt_currentparallel
- lt_groupid
- lt_groupname
- lt_ispathdir
- lt_ispathfile
- lt_ispathfilename
- lt_dirpath
- lt_filepath
- lt_filename
- lt_tempfilepath
- lt_tempfilename
- lt_testsuite
- lt_categoryname
- lt_funcname
- lt_testname
- lt_reporttitle
- lt_assertexpr

See [litetest.h](litetest.h) for documention on the provided utitily functions.
  
## Modules (.c files)

Modules containing the orchestrator or test functions must include `litetest.h` and
any required project headers.

### Example: lubtype Testing 

Include these two files:

```c
#include "lubtype.h"
#include "litetest.h"
```

`/paulsinclair5/lubtype/tests` provides an example with an orchestrator
(`test_lubtype.c`) and test modules (`test.charclass.c`, `test_count.c`,
`test_compare.c`, etc.). Currently, this repository is private.

### Example: LiteTest Self-Testing

```c
#include "litetest.h"
```

`/paulsinclair51/litetest/tests` provides an self-test implementation of
the LiteTest API and framework. It includes:

- `test_litetest.c` defines the orchestrator (`main`) with two test
   categories "Orchestrator" and "Guard".

- `test_orchestrator.c` defines the test_orchestrator functions for
   testing the "Orchestrator" catagory.

- `test_guard1.c` defines the `test_guard1` function for testing part of
   the "Guard" category.

- `test_guard2.c` defines the `test_guard2` function for testing the other
   part of the "Guard" category.

The result of test_guard1 and test_guard2 are combined by the orchestrator
into a single result for the "Guard" category.

## Orchestrator (`main`) Function Template

```c
LT_DECLARE_MAIN_ORCHESTRATOR
{
  LT_INIT_TEST(testname, maxparallel);
  LT_PARSE_ARGS("defaultfilename", "tempfilename");
  LT_OPEN_REPORT("reporttitle");

  // Tests
  // Insert here expanding:
  // [[LT_TEST(func); | LT_ASSERT(assertexpr);]...
  // LT_WRITE_RESULT([LT_TEST(funcname) | LT_ASSERT(assertexpr)], "categoryname")]...
  // with your funcames. assertexprs, categorynames.

  LT_CLOSE_REPORT;
}
```

Results accumulated until `LT_WRITE_RESULT` and then reset.
Totals are accumulated across all tests and asserts.

Optional typedefs, variable, functions, code etc. may be
added to customize or support testing. Added code may
use utility functions. **Recommmended**: do not intermix
code with the tests (such code is handled as if it occurs
before the tests).

Forward-declaration:

```c
LT_DECLARE_MAIN_OCHESTRATOR(testsuite);
```

## Test Function Template

```c
[static] LT_DECLARE_FUNCTION(func)
{
  LT_INIT_TEST(testname);

  // Tests
  // Insert here expanding: [LT_TEST(funcname); | LT_ASSERT(assertexpr);]...
  // your funcname and assertexprs.

  LT_RETURN_RESULT;
}
```

Use `static` if the function is only referenced in the same module.

Forward declaration:

```c
[static] LT_DECLARE_FUNC(func);
```

Specify `static` if the above definition of the function specifies `static`.

Optional typedefs, variable, functions, code etc. may be
added to customize or support testing. Added code may
use utility functions. **Recommmended**: do not intermix
code with the tests (such code is handled as if it occurs
before the tests).

## Building the Test Executable

Modify a copy of an existing MakeFile that builds a test executable for
a project to a Makefile for your project. For example, use the Makefile
for testing the lubtype project or the Makefile for self-testing this
LiteTest project as a starting point for creating your Makefile in hour
project root directory.

#### Linux / macOS

This is the primary supported and currently validated environment.
Linux is the canonical path for building the test executable,
including GitHub Codespaces.

From the repository root:

```sh
make -C tests run

The Makefile builds and executes the executable writing the test report
in the reports directory with the default name <testsuite>_test_report.txt.

The executable can then be executed directly (see
[Executable Usage](#executable-usage-readme)).

To build with gcc instead of clang:

```sh
make -C tests CC=gcc run
```

#### Windows (POSIX Toolchain Required)

Use a POSIX‑capable toolchain such as MSYS2 UCRT64 or Clang64.

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

Clang64 is also suitable with if `cc`, `clang`, or `gcc` resolves to a
POSIX-capable compiler.

## Executable Usage

To execute the tests, run the test executable to produce the test report file (an
existing file is overwritten):

`test_<test> [-i] [PATH]`

By default if PATH is not specified, the executable writes the report
to `<testsuite>_test_report.text` in the current working directory using
the testsuite that is specified by LT_INIT_ORCHESTRATOR macro in the orchestrator
(`main`) function.

### PATH
You may override the output locaction using the PATH argument:

- PATH specifies a file path or a directory path. It may be optionally quoted (with ") or is required to be quoted if it contains spaces or other characters that require the path to be quoted.

= If `PATH` is a file path to an existing or nonexistent file, the test report is written to that file.

- If `PATH` is a directory path (with or without a trailing separator) to an existing directory, the report is written to the file in that directory with filename`<test>_test_report.txt`.

### -i Option

The -i options indicates fail/fault asserts planted in the tests are to inject
a fail/fault. This useful to test the LiteTest frammwork and verify test report
formatting when fails and faults occur.

### --help and -h Help Options

You can display usage information at any time with the `--help` or `-h` option.
For example:

```sh
./test_litetest --help
```
This (or using -h instead of --help) prints a summary of all command-line options and usage details.

## Example Test Report

todo.

## Example Test Report for -i Option

todo.
