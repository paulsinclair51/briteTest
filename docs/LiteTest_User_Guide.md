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
