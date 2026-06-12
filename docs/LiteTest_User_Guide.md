# LiteTest User Guide

This guide explains how to use LiteTest effectively: concepts, workflow, execution model, examples, and practical usage patterns. It complements the **LiteTest API Reference**, which documents the public API in detail.

Copyright (c) 2026 paulsinclair51
SPDX-License-Identifier: MIT. For license details, see ../LICENSE.

---

## 1. Overview

LiteTest is built around three ideas:

1. **Test expressions** — C expressions wrapped with `LT_TEST`.
2. **Test group functions** — Functions that contain related tests.
3. **The orchestrator** — A `main` function that runs test groups and writes the report.

A typical test executable includes:

- An orchestrator (`main`)
- One or more test group functions
- `litetest.h` and `litetest.c`
- Project headers and sources under test

---

## 2. Execution Model

LiteTest runs test expressions and test group functions under a configurable isolation model:

- **Same‑thread execution** (default)
- **Thread‑isolated execution**
- **Process‑isolated execution**

The orchestrator and each test group function specify a `maxparallel` value that controls how many tests or groups may run concurrently.

Faults such as `SIGSEGV`, `SIGBUS`, `SIGILL`, and `SIGFPE` are detected and reported without aborting the test run.

---

## 3. Test Group Functions

A test group function:

- Is declared with `LT_DECLARE_GROUP`
- Begins with `LT_INIT_GROUP`
- Contains `LT_TEST` and/or `LT_GROUP` calls
- Ends with `LT_RETURN`

Example:

```c
static LT_DECLARE_GROUP(test_math)
{
  LT_INIT_GROUP(test_math, 1);

  LT_TEST(1 + 1 == 2, 1);
  LT_TEST(2 * 3 == 6, 1);

  LT_RETURN;
}
```

---

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
LT_DECLARE_ORCHESTRATOR(main)
{
  LT_INIT_ORCHESTRATOR(main, project, 1);
  LT_PARSE_ARGS(2, "report.txt");
  LT_OPEN_REPORT("Example Report");

  LT_WRITE_RESULT(LT_GROUP(test_math), "Math Tests");

  LT_CLOSE_REPORT(NULL);
  LT_EXIT;
}
```

---

## 5. Test Inclusion Control (`-I` / `-In`)

Each `LT_TEST` and `LT_GROUP` macro includes an optional **include parameter** that determines whether it executes based on command‑line options.

- `1` — always execute (default)  
- `2–9` — execute only when `-In` is provided and `n` is ≥ the include value  
- `I` — execute only when `-I` is provided  
- `0` — never execute  

This allows selective execution of test subsets.

---

## 6. Concurrent Blocks

Concurrent blocks ensure that all enclosed `LT_TEST` calls begin execution together:

```c
LT_BEGIN_CONCURRENT(block1);
LT_TEST(expr1, 1);
LT_TEST(expr2, 1);
LT_END_CONCURRENT(block1);
```

Concurrent blocks cannot be nested.

---

## 7. Isolation Modes

LiteTest supports:

### Same‑Thread Mode (default)
Fastest execution; faults are caught via signal guards.

### Thread‑Isolated Mode
Each test runs in a separate thread.

### Process‑Isolated Mode
Each test runs in a separate process. This isolates:

- Aborts  
- Memory corruption  
- Deadlocks  
- Infinite loops  
- Sanitizer aborts  

Recommended for CI and fault‑injection testing.

---

## 8. Building the Test Executable

### Linux / macOS

```sh
make run
```

To use gcc:

```sh
make CC=gcc run
```

### Windows (POSIX toolchain required)

Use MSYS2 UCRT64 or Clang64:

```powershell
./build_test_litetest.ps1
.\test_litetest.exe
```

---

## 9. Executable Usage

```
test_<name> [-I | -In] [PATH]
```

- If `PATH` is a file, the report is written to that file.  
- If `PATH` is a directory, the default report filename is used.  
- If omitted, the report is written to the current directory.  

Use `--help` or `-h` to display usage information.

---

## 10. Troubleshooting

- Missing POSIX APIs on Windows → use MSYS2 UCRT64 or Clang64  
- Report not found → check whether PATH was a file or directory  
- Paths with spaces → quote them  
- Unexpected behavior → ensure code and docs match the same LiteTest version  

---

## 11. Further Reading

See:

- **LiteTest API Reference** for detailed API semantics  
- **LiteTest Contributor Guide** for development and versioning rules  

## Glossary

<details>
<summary>Click to view</summary>

### General Terms

<details>
<summary>Click to view</summary>

- `API`: Application Programming Interface.
- `category`: A labeled set of `LT_GROUP` and `LT_TEST` macros whose combined
  results are written by `LT_WRITE_RESULT` to the report with a specified
  category name.
- `control file`: A previously generated file that can be compared to a newly
  generated file for differences. Differences (other than expected ones like
  timestamps) typically indicate a test failure. Sometimes the control file is
  out of date and must be replaced by promoting the new file.
- `customization support functions`: API functions provided to support
  customizing the orchestrator and test group functions.
- `default report filename`: The report filename LiteTest uses when only a
  directory path (or no `PATH`) is provided.
- `executable`: The compiled test program that runs the orchestrator and test
  functions.
- `fail`: A counted test failure where the `LT_TEST` or `LT_INJECT_TEST`
  expression evaluates to zero.
- `fault`: A counted runtime fault captured by LiteTest guards (e.g., invalid
  memory access).
- `Concurrent block`: A set of tests bracketed by `LT_BEGIN_CONCURRENT` and
  `LT_END_CONCURRENT`.
- `group`: See `test group`.
- `guard`: The protection mechanism used to catch runtime faults and continue
  test execution.
- `guard level`: The nesting depth of active guards while test groups and tests
  run.
- `inject mode (-i)`: Optional command‑line flag that enables an
  `LT_INJECT_TEST` to be executed.
- `isolation`: Execution mode for `LT_GROUP`, `LT_TEST`, or `LT_INJECT_TEST`.
  `0` = same thread, `1` = separate thread, `2` = separate process.
- `maxargs`: Maximum number of command‑line arguments accepted by orchestrator
  parsing. `LT_PARSE_ARGS` handles the first two arguments; additional arguments
  must be parsed by custom code.
- `maxparallel`: Upper bound on concurrent `LT_GROUP`, `LT_TEST`,
  `LT_INJECT_TEST`. Set in `LT_INIT_ORCHESTRATOR` and `LT_GROUP`.
- `notes`: Optional text appended to the report by `LT_CLOSE_REPORT`.
- `orchestrator`: The `main` function that initializes LiteTest, runs groups or
  tests, and writes report output.
- `pass`: A counted successful test where the expression evaluates to non‑zero.
- `PATH`: Optional command‑line output destination; may be a report file path or
  directory path.
- `process isolation`: Isolation mode where a test group or test runs in a
  separate process.
- `project`: Project identifier used in orchestrator initialization and default
  report naming.
- `test group`: A grouping of `LT_TEST` and optionally nested `LT_GROUP` macros.
- `test group function`: A function declared with `LT_DECLARE_GROUP` that
  contains `LT_TEST` and `LT_GROUP` macros.
- `thread isolation`: Isolation mode where a test/assert call runs in a
  separate thread.
- `test case`: Not used in LiteTest. In other contexts it may mean a single
  test or a set of tests; LiteTest uses “test expression” and “test group.”
- `test`: See `test expression`.
- `test expression`: An expression passed to an `LT_TEST` macro that can be cast
  to `int`; zero means fail, non‑zero means pass.
- `testing artifact`: A file or output generated by the test executable (e.g.,
  test report, stdout, stderr).
- `testing function`: A user‑written function used to implement or support a
  test expression.
- `test support functions`: API functions provided to simplify writing tests.
- `title`: Optional report header text provided when opening the report.
- `Public API`: Functions, macros, and types intended for external use.
- `Internal API`: Framework‑only symbols not intended for external use.
- `Semantic Versioning`: Versioning scheme using `M.m.p`.
- `Report Format`: The output structure produced by LiteTest test runs.
</details>

### User-Guide‑Specific Terms

<details>
<summary>Click to view</summary>

- TODO
</details>
</details>
