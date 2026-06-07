# LiteTest

LiteTest is a lightweight C/C++ API and testing framework suitable for
embedding into other C/C++ projects. The API and framework are intentionally
minimal while still providing flexible and comprehensive testing capabilities.

LiteTest requires POSIX.1-2001 (IEEE Std 1003.1-2001) compatibility
and a C99-compliant compiler. Linux, macOS, and the BSD family natively
meet these requirements. Windows requires a
POSIX compatibility layer such as Cygwin, MSYS2, or WSL.

LiteTest has been exercised in a POSIX environment; however, users must
confirm correct behavior in their own environment.

Copyright (c) 2026 paulsinclair51  
SPDX-License-Identifier: MIT.  
See `LICENSE` for details.

## Test Framework Comparison

| Framework | Language / Style | Dependencies | Fault Isolation | Strengths | How LiteTest Differs |
|-----------|------------------|--------------|-----------------|-----------|-----------------------|
| **LiteTest** | Pure C, minimal API | None (single .c/.h) | POSIX signals (`SIGSEGV`, `SIGBUS`, `SIGABRT`) with nested guards | Tiny, embeddable, safe for low‑level code, simple reporting | Designed for small C projects, embedded systems, and environments where external frameworks are too heavy |
| **GoogleTest (gtest)** | C++ (OOP, templates) | Large library, build system integration | No built‑in POSIX fault trapping | Feature‑rich, fixtures, matchers, parameterized tests | LiteTest is dramatically smaller, pure C, and dependency‑free |
| **Unity / CMock** | C, embedded‑focused | Small library | No multi‑level signal guards | Lightweight, good for microcontrollers | LiteTest adds POSIX fault handling and nested guard levels |
| **Check** | C with process forking | Requires linking to Check library | Fork‑based isolation | Good isolation, TAP output | LiteTest avoids forking and stays single‑process with `sigsetjmp`/`siglongjmp` guards |
| **CTest (CMake)** | Test runner only | Requires CMake | None (runs external binaries) | Integrates with CMake, dashboards | LiteTest provides assertions + reporting; CTest is only an executor |
| **Catch2 / doctest** | Modern C++ | Header‑only | No POSIX fault trapping | Very expressive syntax, rich features | LiteTest is pure C and suitable for environments avoiding C++ |

## Overview

The LiteTest API and framework are defined in [include/litetest.h](include/litetest.h) and [src/litetest.c](src/litetest.c).

### Key Points

1. A test executable is built from:

   - An orchestrator (`main`) function and optional test functions
     organized into one or more modules,

   - `litetest.h`, and `litetest.c`, `unistd.h`

   - Modules and include files from the feature/project/API under test.
   
2. The executable produces a report grouped by category, including
pass/fail/fault counts per category and totals across all categories.
Fail and fault messages are appended to the report.

3. The orchestrator and test functions may reside
in one module or multiple modules. **Recommended**: put
the orchestrator function in one module and each test function in its own module.

4. The test framework requires `unistd.h` for POSIX fork and signal capabilities.

### Orchestrator (`main`) Macros

- `LT_DECLARE_ORCHESTRATOR(funcname)[;]`
- `LT_INIT_ORCHESTRATOR(funcname, testsuitename, [maxparallel]);`
- `LT_PARSE_ARGS(maxargs, ["defaultreportfilename"]);`
- `LT_OPEN_REPORT(["reporttitle"]);`
- test and assert macros
- `LT_WRITE_RESULT([t], "categoryname");`
- `LT_CLOSE_REPORT(["notes"]);`
- `LT_EXIT;`

Note:
- `funcname` must be main.
- `maxargs` must be 2 or greater. The first arg is the executable name.
  The second optional arg is `PATH`. Additional args are for customization
  and must be parsed by custom code added to the function.
- `t` is a test or assert macro.
- For the first macro, a semicolon is required for a forward declaration;
  otherwise, it is omitted if it's followed by a definition in {}.

### Test Function Macros

- `LT_DECLARE_TEST(funcname)[;]`
- `LT_INIT_TEST(testname, [maxparallel]);`
- test and assert macros
- `LT_RETURN;`

Note:
- `funcname` must not be main and must be same for the first two macros when
  defining a test function.
- For the first macro, a semicolon is required for a forward declaration;
  otherwise, it is omitted if it is followed by a definition in `{ }`.

### Test and Assert Macros

- `LT_TEST(funcname, [isolation])[;]`
- `LT_ASSERT(assertexpr, [isolation])[;]`
- `LT_ASSERT_FAIL([isolation])[;]`
- `LT_ASSERT_FAULT([isolation])[;]`

The semicolon is omitted if used as an argument to the LT_WRITE_RESULT macro;
otherwise it is required.

### Faults
  
These macros provide multi-level signal handling to capture faults
(`SIGSEGV`, `SIGABRT`, `SIGBUS`). Faults are counted without aborting
execution, allowing the test suite to continue and produce a complete
and produce a complete test report with fault counts and messages for
each fault.

### Parallel Execution

Parallel execution of the test/assert macros is enabled/disabled by the
`maxparallel` parameter for the LT_INIT_ORCHESTRATOR and LT_INIT_TEST
macros. Up to `maxparallel` test/assert macros are started and when one
finishes another is started.

###  Parallel Group Execution

Test/assert macros can run in parallel as a group (that is, they
are not started until they can all start without exceeding `maxparallel`).
A group is bracketed using the followug macros:

- `LT_BEGIN_GROUP(groupname, [isolation])`
- `LT_END_GROUP(groupname);`

A group cannot be nested in a group within a test function.

### Test Isolation

For non-grouped test/assert macro, the `isolation` parameter 
indicates whether the macro runs in the same thread as the calling
function (no parallelism), a separate thread, or a separate process:

   `Isolation`: 0 (none), 1 (thread), 2 (process)

For a test/assert macro not in a group, the default is 0 (none).

For a test/assert macro in a group, `isolation` must be 1 (thread) or 2 (process)
with a default of 1 (thread).

Other combinations are invalid.

### Miscellaneous

Miscellaneous functions, macros, typedefs, and variables.
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

See [include/litetest.h](include/litetest.h) for documention on the provided utility functions.
  
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
API and framwork. The modules include one header (since it is both
the header for the API to be tested and the API for testing). 

```c
#include "litetest.h"
```

## Orchestrator (`main`) Function Template

```c
LT_DECLARE_ORCHESTRATOR(main)
{
  LT_INIT_ORCHESTRATOR(testsuitename, maxparallel);
  LT_PARSE_ARGS("defaultfilename", "tempfilename");
  LT_OPEN_REPORT("reporttitle");

  // Tests
  // Insert here expanding:
  // [[LT_TEST(func, isolation); | LT_ASSERT(assertexpr, isolation);]...
  // LT_WRITE_RESULT([LT_TEST(funcname, isolation) | LT_ASSERT(assertexpr, isolation)], "categoryname")]...
  // with your funcames. assertexprs, categorynames.

  LT_CLOSE_REPORT;

  LT_EXIT;
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
LT_DECLARE_ORCHESTRATOR(main);
```

## Test Function Template

```c
[static] LT_DECLARE_TEST(funcname)
{
  LT_INIT_TEST(testname, maxparallel);

  // Tests
  // Insert here expanding:
  //   [LT_TEST(funcname, isolation); | LT_ASSERT(assertexpr, isolation);]...
  // your funcname and assertexprs.

  LT_RETURN;
}
```

Use `static` when the function is only referenced in the same module.

Forward declaration:

```c
[static] LT_DECLARE_TEST(func);
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
```

The Makefile builds and executes the executable writing the test report
in the reports directory with the default name <testsuite>_test_report.txt.

The executable can then be executed directly (see
[Executable Usage](#executable-usage)).

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
./build_test_litetest.ps1
.\test_litetest.exe
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
to `<testsuite>_test_report.txt` in the current working directory using
the testsuite that is specified by the LT_INIT_ORCHESTRATOR macro in the orchestrator
(`main`) function.

### PATH

You may override the output locaction using the PATH argument:

- PATH specifies a file path or a directory path. The path may optionally be quoted (with ") or is required to be quoted if it contains spaces or other characters that require the path to be quoted.

- If `PATH` is a file path to an existing or nonexistent file, the test report is written to that file.

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
This (or using -h instead of --help) prints a summary of all command-line
 options and usage details.

## Example Test Report

todo.

## Example Test Report for -i Option

todo.
