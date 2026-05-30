# LiteTest

LiteTest is a lightweight C/C++ API and testing framework suitable for
embedding into other C/C++ projects. The API and framework are intentionally
minimal while still providing flexible and comprehensive testing capabilities.

LiteTest requires POSIX.1-2001 (IEEE Std 1003.1-2001) compatibilty
and a C99-compliant compiler. Linux, macOS, and the BSD family natively
meet these requirements. Windows requires a
POSIX compatibility layer such as Cygwin, MSYS2, or WSL.

LiteTest has been exercised in a POSIX environment; however, users must
confirm correct behavior in their own environment.

Copyright (c) 2026 paulsinclair51  
SPDX-License-Identifier: MIT.  
See the LICENSE file in the repository root for details.

## Comparison to Other Testing Frameworks



## Overview

The LiteTest API and framework are defined in [litetest.h](litetest.h) and [litetest.c](litetest.c).

### Key Points

1. A test executable is built from:

   - An orchestrator (`main`) function and optional test functions
     organized into one or more modules,

   - `litetest.h`, and `litetest.c`, `unistd.h`

   - Modules and include files from the feature/project/API under test.
   
2. The executable produces a report grouped by category, including
pass/fail/fault counts per category and totals across all categories.
Fail and fault messages are appeneded to the report.

4. The orchestrator and test functions may reside
in one module or multiple modules. **Recommended**: put
the orchestrator function in one module and each test function in its own module.

5. The test framework requires `unistd.h` for POSIX fork and signal capabilities.
   
### Test and Assert Macros

- LT_TEST(funcname)
- LT_ASSERT(assert_expr)
- LT_ASSERT_FAIL
- LT_ASSERT_FAULT
  
These macros provide multi-level signal
handling to capture faults (`SIGSEGV`, `SIGABRT`, `SIGBUS`). Faults
are counted without aborting execution, allowing the test suite to continue
and produce a complete test report with fault counts and messages for each fault.

Parallel execution of LT_TEST macros is enabled/disabled by the `maxparallel` parameter
for the LT_INIT_ORCHESTRATOR and LT_INIT_TEST macros. Up to `maxparallel` test functions
are started and when one finishes another is started.

LT_TEST macros can run in parallel as a group (that is, they are not started
until they can all start without exceeding `maxparallel`).
A gruop is bracketed by the LT_BEGIN_GROUP and LT_END_GROUP macros.

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

The tests directory in the `paulsinclair5/lubtype` GitHub repository
provides an example with an orchestrator module and test modules to test
the lubtype API. The modules include these two files:

```c
#include "lubtype.h"
#include "litetest.h"
```

### Example: LiteTest Self-Testing

The tests directory for this GitHbub repository provides an example
with an orchestrator module and test modules to self-test the LiteTest
API and framwork. The modules iheader include one header (since it is both
the header for API to be tested and the API for testing). 

```c
#include "litetest.h"
```

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

Results accumulate until `LT_WRITE_RESULT`, and then reset.
Totals accumulate across all tests and asserts.

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

Use `static` when the function is only referenced in the same module.

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

## Example Usage

The tests directory for this GitHbub repository  provides an self-test implementation of
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

```c
test_<testname> [-i] [PATH]
```

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
