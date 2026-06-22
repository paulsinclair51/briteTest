![BriteTest Runner Guide](branding/BriteTest_Runner_Guide.png)

This guide explains how to use the BriteTest Runner framework and Runner API
covering concepts, workflow, execution model, examples, and practical,usage
patterns. It complements the BriteTest Runner Reference, which documents
the Runner API in detail.

#### Copyright (c) 2026 Paul Sinclair

<details>
<summary>License</summary>

#### **License**

SPDX-License-Identifier: MIT

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
</details>

<details>
<summary>Preface</summary>

## Preface

This document is intended for BriteTest contributors who need
guidance on enhancing and maintaining BriteTest.

For a list of other BriteTest documents and the BriteTest repository layout, see
the BriteTest Documentation Guide.

For a glossary of terms, see the BriteTest Glossary Reference.

<details>
<summary>Document Version History</summary>

### Document Version History

| Document | Runner | Test | Date | Comment | Author/Editor |
|----------|------|--------|------|---------|---------------|
| 1.0 |1.0.0 | 1.0.0 | 2026‑06‑11 |  Initial version. | Paul Sinclair |

- The **Document** column records the document's version with the
  format `M.u` (Major, update).
- The **Runner** column records the BriteTest Runner API version
  current at the time this document version was published and is
  defined by its `BT_RUNNER_VERSION` macro.
- The **Test** column records the BriteTest Test API version current at
  the time this document version was published and is defined by its
  `BT_TEST_VERSION` macro.
- Both Runner and Test use the version format `"M.m.p"` (Major, minor,
  patch).
- `M` is the same for the Document, Runner, and Test versions.

The document's update version tracks released updates to this document and does
not correspond to a minor or patch version. `u` increments when document
changes are published in a release without a change to `M`, and it resets to
`0` when `M` is incremented.
</details>
</details>

<details>
<summary>Table of Contents</summary>

## Table of Contents

[**1. Introduction**](#1-introduction)
</details>

<details>
<summary>1. Introduction</summary>

## 1. Introduction

BriteTest is built around three ideas:

1. **Test expressions**:C expressions wrapped with `BT_TEST`.
2. **Test group functions**:Functions that contain related tests.
3. **The orchestrator**: A `main` function that runs test groups and writes the
   report.

A typical test executable includes:

- An orchestrator (`main`)
- One or more test group functions
- `britetest_runner.h` and `britetest_runner.c`
- Project headers and sources under test
</details>

<details>
<summary>2. Execution Model</summary>

## 2. Execution Model

BriteTest runs test expressions and test group functions under a configurable
isolation model:

- **Same‑thread execution** (default)
- **Thread‑isolated execution**
- **Process‑isolated execution**

The orchestrator and each test group function specify a `maxparallel` value that
controls how many tests or groups may run concurrently.

Faults such as `SIGSEGV`, `SIGBUS`, `SIGILL`, and `SIGFPE` are detected and
reported without aborting the test run.
</details>

<details>
<summary>3. Test Group Functions</summary>

## 3. Test Group Functions

A test group function:

- Is declared with `BT_DECLARE_GROUP`
- Begins with `BT_INIT_GROUP`
- Contains `BT_TEST` and/or `BT_GROUP` calls
- Ends with `BT_RETURN`

Example:

```c
static BT_DECLARE_GROUP(test_math)
{
  BT_INIT_GROUP(test_math, 1);

  BT_TEST(1 + 1 == 2, 1);
  BT_TEST(2 * 3 == 6, 1);

  BT_RETURN;
}
```
</details>

<details>
<summary>4. Orchestrator (`main`) Function</summary>

## 4. Orchestrator (`main`) Function

The orchestrator:

- Declares and initializes the test runner
- Parses command‑line arguments
- Opens the report
- Executes test groups
- Writes category results
- Closes the report

Example:

```c
BT_DECLARE_ORCHESTRATOR(main)
{
  BT_INIT_ORCHESTRATOR(main, project, 1);
  BT_PARSE_ARGS(2, "report.txt");
  BT_OPEN_REPORT("Example Report");

  BT_WRITE_RESULT(BT_GROUP(test_math), "Math Tests");

  BT_CLOSE_REPORT(NULL);
  BT_EXIT;
}
```
</details>

<details>
<summary>5. Test Inclusion Control (`-I` / `-In`)</summary>

## 5. Test Inclusion Control (`-I` / `-In`)

Each `BT_TEST` and `BT_GROUP` macro includes an optional **include parameter** that determines whether it executes based on command‑line options.

- `1` — always execute (default)  
- `2–9` — execute only when `-In` is provided and `n` is >= the include value  
- `I` — execute only when `-I` is provided  
- `0` — never execute  

This allows selective execution of test subsets.
</details>

<details>
<summary>6. Concurrent Blocks</summary>

## 6. Concurrent Blocks

Concurrent blocks ensure that all enclosed `BT_TEST` calls begin execution together:

```c
BT_BEGIN_CONCURRENT(block1);
BT_TEST(expr1, 1);
BT_TEST(expr2, 1);
BT_END_CONCURRENT(block1);
```

Concurrent blocks cannot be nested within a test function.
</details>

<details>
<summary>7. Isolation Modes</summary>

## 7. Isolation Modes

BriteTest supports:
</details>

<details>
<summary>Same‑Thread Mode (default)</summary>

### Same‑Thread Mode (default)
Fastest execution; faults are caught via signal guards.
</details>

<details>
<summary>Thread‑Isolated Mode</summary>

### Thread‑Isolated Mode
Each test runs in a separate thread.
</details>

<details>
<summary>Process‑Isolated Mode</summary>

### Process‑Isolated Mode
Each test runs in a separate process. This isolates:

- Aborts  
- Memory corruption  
- Deadlocks  
- Infinite loops  
- Sanitizer aborts  

Recommended for CI and fault‑injection testing.
</details>

<details>
<summary>8. Building the Test Executable</summary>

## 8. Building the Test Executable
</details>

<details>
<summary>Linux / macOS</summary>

### Linux / macOS

```sh
make run
```

To use gcc:

```sh
make CC=gcc run
```
</details>

<details>
<summary>Windows (POSIX toolchain required)</summary>

### Windows (POSIX toolchain required)

Use MSYS2 UCRT64 or Clang64:

```powershell
./build_test_britetest.ps1
.\test_britetest.exe
```
</details>

<details>
<summary>9. Executable Usage</summary>

## 9. Executable Usage

```
test_<name> [-I | -In] [PATH]
```

- If `PATH` is a file, the report is written to that file.  
- If `PATH` is a directory, the default report filename is used.  
- If omitted, the report is written to the current directory.  

Use `--help` or `-h` to display usage information.
</details>

<details>
<summary>10. Troubleshooting</summary>

## 10. Troubleshooting

- Missing POSIX APIs on Windows → use MSYS2 UCRT64 or Clang64  
- Report not found → check whether PATH was a file or directory  
- Paths with spaces → quote them  
- Unexpected behavior → ensure code and docs match the same BriteTest version  
</details>

<details>
<summary>11. Further Reading</summary>

## 11. Further Reading

See:

- **BriteTest Runner Reference** for detailed API semantics.
- **BriteTest Contributor Guide** for development and versioning rules.
</details>

<details>
<summary>Quick Start</summary>

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
<summary>💻 and copy</summary>

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

```text
BriteTest Report
                             Pass   Fail     Fault
--------------------------------------------------
1. Orchestrator                 4
2. Guard 1 and 2                6
--------------------------------------------------
                      Total    10
```

See the [Core API Macros](#core-api-macros) and other sections for more detail.

See [Building the Test Executable](#building-the-test-executable) for
platform-specific notes and options.

<details>
<summary>Key Features</summary>

## Key Features

- Pure C implementation.
- Fault handling with nested guard levels.
- Minimal footprint — a single header and source file define the entire API.
- Straightforward API: simple assertions, categories, and reporting so you can focus on writing tests.
- Comprehensive reporting: pass/fail/fault counts per category and overall totals.
- Test support functions that simplify writing and organizing tests.
</details>

<details>
<summary>API Usage Requirements</summary>

## API Usage Requirements

BriteTest requires:

- POSIX.1‑2001 (IEEE Std 1003.1‑2001) compatibility.
- A C99‑compliant compiler.

Supported environments:

- Linux, macOS, BSD — fully compatible.
- Windows — requires a POSIX layer such as Cygwin, MSYS2, or WSL.

BriteTest has been exercised in POSIX environments; users should
validate behavior in their own systems.
</details>

<details>
<summary>How BriteTest Compares</summary>

## How BriteTest Compares

| Framework     | Language / Style | Dependencies | Fault Isolation | Strengths | How BriteTest Differs |
|---------------|------------------|--------------|-----------------|-----------|------------------------|
| **Unity**     | C, macro‑heavy   | None         | No              | Widely used, simple API | BriteTest adds POSIX signal‑based fault isolation and category‑level reporting. |
| **cmocka**    | C, function‑based | None        | Yes (setjmp)    | Mature, feature‑rich | BriteTest is smaller, header‑driven, and easier to embed in small projects. |
| **Check**     | C, process‑based | POSIX tools  | Yes (fork)      | Strong isolation, fixtures | BriteTest avoids process spawning and keeps a minimal footprint. |
| **Criterion** | C, auto‑discovery | libc, POSIX | Yes             | Modern, fast, rich output | BriteTest is simpler, portable, and avoids auto‑discovery complexity. |
| **BriteTest**  | C99, macro‑driven | None        | Yes (POSIX signals) | Minimal, portable, easy to embed | Designed for small C projects needing fault isolation without heavy frameworks. |
</details>

<details>
<summary>What BriteTest Does Not Provide</summary>

## What BriteTest Does Not Provide

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

<details>
<summary>Introduction</summary>

## Introduction

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
 |- test_group1()
 |    |- test1
 |    |- test2
 |    `- ...
 `- test_group2()
  `- ...

Recommended: Put the orchestrator function in one source file and each test group function
in its own source file.
   
When executed, BriteTest produces a report summarizing tests by category, including:

- Pass/fail/fault counts per category.
- Totals across all categories.
- Notes describing each failure or fault.
</details>

<details>
<summary>Core API</summary>

## Core API

The core API is set of macros used to define the orchestrator and test group
functions. These macros fall into 3 types:

| Type | Purpose | Naming Pattern |
| --- | --- | --- |
| **Orchestrator** | Define and run the test runner | ``BT_DECLARE_*``, ``BT_INIT_*``, ``BT_*`` |
| **Test Group Functions** | Define test group functions | ``BT_DECLARE_GROUP``, ``BT_INIT_GROUP``, ``BT_RETURN`` |
| **Execution** | Execute groups or test expressions | ``BT_GROUP``, ``BT_TEST`` |
</details>

<details>
<summary>Macros for the Orchestrator (`main`) Function</summary>

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
</details>

<details>
<summary>Macros for a Test Group Function</summary>

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
</details>

<details>
<summary>Macros for Executing a Test Group Function or Test Expression</summary>

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
</details>

<details>
<summary>Parallel Execution</summary>

#### Parallel Execution

BriteTest starts up to `maxparallel` test group functions or test expressions concurrently.
When one finishes, another begins, until all are complete. `maxparallel` is set by the
`BT_INIT_ORCHESTRATOR` and `BT_INIT_GROUP` macros.
</details>

<details>
<summary> Macros for Concurrent Execution</summary>

###  Macros for Concurrent Execution

The concurrent block macros ensure that all `BT_TEST` macros inside it start together:

- The `BT_TEST` macros are bracketed with:
  - `BT_BEGIN_CONCURRENT(blockname)`
  - `BT_END_CONCURRENT(blockname)`
- Within a test group function body, a concurrent block cannot be nested inside
  concurrent block.
</details>

<details>
<summary>Isolation Modes and Fault Handling</summary>

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
</details>

<details>
<summary>BriteTest Runner Customization</summary>

## BriteTest Runner Customization

Typedefs, enums for exit code and return codes, macros for limits, and functions are provided in the BriteTest Runner API to support customization of the orchestrator and test group functions..

Examples include:

- `bt_executablename`
- `bt_resubt_t`
- `bt_dirpath`
- `BT_MAX_PATH_LEN`
- `bt_currentlevel`
- `bt_currentresult`
- `bt_maxparallel`
- `bt_blockname`
- `bt_iswritedirpath`

`bt_resubt_t` carries pass/fail/fault and injected-fault counters for a test or
group. A function-level fault is represented by setting the fault count to
`SIZE_MAX`.

See the BriteTest Runner Reference for details on each of these.
</details>

<details>
<summary>BriteTest Test API</summary>

## BriteTest Test API

Typedefs, struct, enums, variables, and Functions are provided to support
writing tests.

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
</details>

See the BriteTest Test Reference for details on each of these.
  
<details>
<summary>Headers (.h) and Sources (.c)</summary>

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
</details>

<details>
<summary>Orchestrator (`main`) Function Template</summary>

## Orchestrator (`main`) Function Template

<details>
<summary>💻 and copy</summary>

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

<details>
<summary>Test Group Function Template</summary>

## Test Group Function Template

<details>
<summary>💻 and copy</summary>

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

<details>
<summary>Example of Using the BriteTest API</summary>

## Example of Using the BriteTest API

The `tests` directory for this repository provides a self-test implementation of
the BriteTest API and framework. It includes:

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

<details>
<summary>Building the Test Executable</summary>

## Building the Test Executable
 
Modify a copy of an existing Makefile that builds a test executable for
a project to a Makefile for your project. For example, use the Makefile
for testing the lubtype project or the Makefile for self-testing this
BriteTest project as a starting point for creating your Makefile in your
project root directory.
</details>

<details>
<summary>Linux / macOS</summary>

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
</details>

<details>
<summary>Windows (POSIX Toolchain Required)</summary>

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
</details>

<details>
<summary>Executable Usage</summary>

## Executable Usage

To execute the tests, run the test executable to produce the test report file (an
existing writable file is overwritten):

```sh
test_<testname> [-I|-In] [PATH]
```

By default, if `PATH` is not specified, BriteTest writes the report to the
current working directory using the default report filename configured by
your test setup.
</details>

<details>
<summary>PATH</summary>

### PATH

You may override the output location using the PATH argument:

- `PATH` can point to either a report file or a directory. Quote it only when
  it contains spaces (for example, `"my reports/"`).

- If `PATH` is a file path (existing or new), BriteTest writes the report to
  that file.

- If `PATH` is a directory path, BriteTest writes the report in that directory
  using the default report filename configured by your test setup.
</details>

<details>
<summary>`-I` and `-In` Option</summary>

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
</details>

<details>
<summary>`--help` and `-h` Help Options</summary>

### `--help` and `-h` Help Options

You can display usage information at any time with the `--help` or `-h` option.
For example:

```sh
./test_britetest --help
```
This (or using -h instead of --help) prints a summary of all command-line
options and usage details.
</details>

<details>
<summary>Common Mistakes</summary>

## Common Mistakes

- If `PATH` contains spaces, quote it (for example, `"my reports/report.txt"`).
- Existing report files may be overwritten; use unique paths if you need history.
- On Windows, use a POSIX-capable toolchain (for example, MSYS2 UCRT64).
- Keep macro examples in your project aligned with the version of `britetest_runner.h` in use.
</details>

<details>
<summary>Troubleshooting</summary>

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
</details>

<details>
<summary>Example Test Report</summary>

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
</details>

<details>
<summary>Example Test Report for -i Option</summary>

## Example Test Report for -i Option

```text
BriteTest Report (-i)

                             Pass   Fail     Fault
--------------------------------------------------
1. Orchestrator                 4      1         1
2. Guard 1 and 2                6      2         1
--------------------------------------------------
                      Total    10      3         2
</details>

<details>
<summary>Further Reading</summary>

## Further Reading

- [include/README.md](include/README.md)
- [src/README.md](src/README.md)
- [tests/README.md](tests/README.md)
- [reports/README.md](reports/README.md)


**
 * @section Overview Overview
 *
 * @note In the following, testing the BriteTest itself is used as an example of
 *       using the BriteTest framework and API with test modules test_guards_1.c,
 *       test_guards_2.c, and test_orchestrator.c, and test orchestrator
 *       test_britetest.c in the repository tests directory.
 */
 
/**
 * @subsection KeyPoints Key Points
 *
 * 1. A test executable is built from:
 *
 *   - An orchestrator (main) function and optional test functions
 *     organized into one or more modules,
 *
 *   - britetest_runner.h, and britetest_runner.c, unistd.h
 *
 *   - Modules and include files from the feature/project/API under test.
 *   
 * 2. The executable produces a report grouped by category, including
 *    pass/fail/fault counts per category and totals across all categories.
 *    Fail and fault messages are appended to the report.
 *
 * 3. The orchestrator and test functions may reside in one module
 *    or multiple modules. Recommended: put the orchestrator function
 *    in one module and each test function in its own module.
 *
 * 4. The test framework requires unistd.h for POSIX fork and signal capabilities.
 */

/**
 * @subsection OrchestratorMacros Orchestrator Function Macros
 *
 * Macros for use in the orchestrator (main) function:
 *
 * - BT_DECLARE_ORCHESTRATOR(funcname)[;]
 * - BT_INIT_ORCHESTRATOR(funcname, testsuitename, [maxparallel]);
 * - BT_PARSE_ARGS([maxargs], ["defaultreportfilename"]);
 * - BT_OPEN_REPORT(["reporttitle"]);
 * - test and assert macros
 * - BT_WRITE_RESULT([t], "categoryname");
 * - BT_CLOSE_REPORT(["notes"]);
 * - BT_EXIT;
 *
 * @note funcname must be main.
 * @note maxargs must be 2 or greater. The first arg is the executable name.
 *       The second optional arg is PATH. Additional args are for customization
 *       and must be parsed by custom code added to the function.
 * @note t is a test or assert macro.
 * @note For the first macro, a semicolon is required for a forward declaration;
 *       otherwise, it is omitted if is it followed by a definition in { }.
 */

/**
 * @subsection TestFunctionMacros Test Function Macros
 *
 * Macros for use in a test function:
 *
 * - BT_DECLARE_TEST(funcname)[;]
 * - BT_INIT_TEST(funcname, [maxparallel]);
 * - test and assert macros
 * - BT_RETURN;
 *
 * @note funcname must not be main and must be same for the first two macros when
 *       defining a test function.
 * @note For the first macro, a semicolon is required for a forward declaration;
 *       otherwise, it is omitted if it is followed by a definition in {}.
 */

/**
 * @subsection TestAndAssertMacros Test and Assert Macros
 *
 * - BT_TEST(funcname, [isolation])[;]
 * - BT_ASSERT(expression, [isolation])[;]
 * - BT_INJECT_ASSERT(expression, [isolation])[;]
 *
 * The semicolon is omitted if used as an argument to the BT_WRITE_RESULT macro;
 * otherwise it is required.
 *
 * BT_INJECT_ASSERT is the same as BT_ASSERT except:
 *
 * - Only executes if injection is enabled (see @ref iOption `-i` Option.
 * - Result is counted as an injected pass/fail/fault.
 *
 * Special values that can be used in any expression:
 *
 * - BT_PASS: returns 1.
 * - BT_FAIL: returns 0.
 * - BT_FAULT(type): causes a fault of the specified type:
 *.                  1 (`SIGSEGV`). 2 (`SIGABRT`), 3 (`SIGBUS`).
 * 
 * For other values of type, BT_FAULT returns 0.
 */

/**
 * @subsubsection FaultHandling Fault Handling
 *
 * BriteTest provides multi‑level signal guards to safely capture faults such as
 * `SIGSEGV` `SIGABRT`, and `SIGBUS`. When a fault occurs:
 *
 * - The fault is recorded
 * - Execution continues
 * - The test suite completes normally
 * - The final report includes fault counts and messages
 *
 * This allows you to test low‑level or unsafe code without aborting the entire
 * test run.
 */

/**
 * @subsubsection ParallelExecution Parallel Execution

Parallel execution of the test/assert macros is enabled/disabled by the
`maxparallel` parameter for the BT_INIT_ORCHESTRATOR and BT_INIT_TEST
macros. Up to `maxparallel` test/assert macros are started and when one
finishes another is started.
 */

/**
 * @subsubsection ParallelGroupMacros Parallel Group Macros

A group ensures that all test/assert macros inside it start together:

- Groups are bracketed with:
  - `BT_BEGIN_GROUP(groupname)`
  - `BT_END_GROUP(groupname)`
- Within a test function, a group cannot be nested inside another group.

 */

/**
 * @subsubsection Isolation Levels
 *
`isolation`:
- 0 same thread (no parallelism)
- 1 separate thread
- 2 separate process

Defaults:
- Non-grouped macros: 0.
- Grouped macros: 1.

 * Invalid combinations are rejected.
 */
 
/** old
 * @subsubsection ParallelExecution Parallel Execution
 *
 * Parallel execution of the test/assert macros is enabled/disabled by the
 * maxparallel parameter for the BT_INIT_ORCHESTRATOR and BT_INIT_TEST
 * macros. Up to maxparallel test/assert macros are started and when one
 * finishes another is started.
 *
 * @subsubsection ParallelGroupExecution Parallel Group Execution
 *
 * Test/assert macros can run in parallel as a group (that is, they
 * are not started until they can all start without exceeding maxparallel).
 * A group is bracketed using the followug macros:
 *
 * - BT_BEGIN_GROUP(groupname, [isolation])
 * - BT_END_GROUP(groupname);
 *
 * @note A group cannot be nested in a group within a test function.
 *
 * @subsubsection TextIsolation Test Isolation
 *
 * For non-grouped test/assert macro, the isolation parameter 
 * indicates whether the macro runs in the same thread as the calling
 * function (no parallelism), a separate thread, or a separate process:
 *
 *     Isolation: 0 (none), 1 (thread), 2 (process)
 *
 * @note For a test/assert macro not in a group, the default is 0 (none).
 *
 * @note For a test/assert macro in a group, isolation must be 1 (thread)
 *       or 2 (process) with a default of 1 (thread).
 */

/**
 * @subsection Miscellaneous
 * 
 * Miscellaneous functions, macros, typedefs, and variables.
 * Examples include:
 *
 * - bt_executablename
 * - bt_resubt_t
 * - bt_dirpath
 * - BT_MAX_PATH_LEN
 * - bt_currentlevel
 * - bt_currentresult
 * - bt_maxparallel
 * - bt_isisolated
 * - bt_groupname
 * - bt_iswritedirpath
 */

/**
 * @section HeaderUsage Header Usage
 * 
 * In the test orchestrator source file (e.g., test_britetest.c),
 * include the following:
 *
 * @code
#include "britetest_runner.h"
 * @endcode
 *
 * Use the orchestrator macros, variables and functions in the test
 * orchestrator logic plus the BT_TEST macro to execute test functions.
 * 
 * In the test* modules (e.g., test_guards_1.c, test_guards_2.c, and
 * test_orchestrator.c):
 *
 * @code
 #undef BT_ORCHESTRATOR
 #include "britetest_runner.h"
 * @endcode
 *
 * Use the BT_TEST, BT_ASSERT_FAIL, and BT_ASSERT_FAULT macros in
 * the test function to execute tests.
 *
 * @note Other veriations are possible in the test orchestrator and test functions.
 */

/**
 * @section BuildingTestExecutable Building a Test Executable
 * 
 * - Linux/macOS: make
 * 
 *   Defaults to use Makefile in the current directory.
 * 
 * - Windows PowerShell: `.\build_test_lubtype.ps1`
 */
 
/**
 * @section NameConventions Naming Conventions
 *
 * BriteTest - Repository name (case-jnsensitive.
 *
 * britetest_runner.h and britetest_runner.c - filenames.
 * 
 * Public API:
 *
 * 1. bt_* - functions, typedefs, and variables.
 * 2. BT_* - macros, constants, and enum values.
 * 
 * Internal and private to the BriteTest framework:
 *
 * 1. britetest_* - functions, typedefs, and variables.
 * 2. BRITETEST_* - Internal macros, constants, and enum values.
 *
 * These conventions are designed to provide a clean public API, strong
 * namespace isolation, and predictable behavior when BriteTest is embedded
 * into a larger C/C++ project.
 *
 * @example Public API Names
 *
 * 1. Utility macros: BT_TOK_PASTE, BT_TOK_STR, BT_RESULT, BT_TOTAL
 *    BT_STATIC_ASSERT
 * 2. Version macros: BT_VERSION, BT_VERSION_EQ, BT_VERSION_AT_LEAST
 * 4. Utility functions: bt_current_level.
 *
 * @example Public typedef Name
 *
 * bt_resubt_t, bt_state_t
 *
 * @example Private Variable Names
 *
 * britetest_resubt_internal, britetest_total_internal
 */

/**
 *
 * @section FaultGuarding Fault Guarding
 *
 * The test framework uses multi-level fault guarding to handle
 * faults (i.e., segmentation fault, bus error, or abort) during
 * test execution.
 * 
 * A test/assert macro wraps a guard around its argument, enabling
 * detection of a fault not handled at a lower level by the
 * argument rather than aborting. This allows counting pass,
 * fail, and fault without aborting due to a fault.
 * 
 * A fault detected by BT_TEST represents a fault 
 * in the use of the testing framework or in the testing framework
 * itself, and not in the feature being tested. Such a fault is
 * expected to be rare but guarding avoids a fault terminating
 * execution.
 */
</details>
