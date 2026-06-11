# LiteTest

LiteTest is a lightweight Application Programming Interface (API) and framework 
for defining, running, and reporting tests in C/C++ projects. It provides a simple
core macro-driven API, fault‑tolerant execution, and clear reporting — ideal
for small to medium C projects that need reliable testing without heavy 
tooling and dependencies.

LiteTesf is implemented as a single .h / .c pair with no external dependencies
requiring only a POSIX.1‑2001 environment and a C99‑compliant compiler.

Copyright (c) 2026 paulsinclair51.  
SPDX-License-Identifier: MIT.

<details>
<summary><strong>Click to view</strong></summary>

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

## Table of Contents

<details>
<summary><strong>Click to view</strong></summary>

- [Quick Start](#quick-start)
- [Documentation Scope](#documentation-scope)
- [Key Features](#key-features)
- [API Usage Requirements](#api-usage-requirements)
- [How LiteTest Compares](#how-litetest-compares)
- [What LiteTest Does Not Provide](#what-litetest-does-not-provide)
- [Overview](#overview)
- [Core API Macros](#core-api-macros)
  - [Macros for the Orchestrator (main) Function](#macros-for-the-orchestrator-main-function)
  - [Macros for a Test Group Function](#macros-for-a-test-group-function)
  - [Macros for Executing a Test Group Function or Test Expression](#macros-for-executing-a-test-group-function-or-test-expression)
    - [Parallel Execution](#parallel-execution)
  - [Macros for Concurrent Execution](#macros-for-concurrent-execution)
  - [Isolation Modes and Fault Handling](#isolation-modes-and-fault-handling)
- [Customization Support API](#customization-support-api)
- [Test Support API](#test-support-api)
- [Repository Layout](#repository-layout)
- [Further Reading](#further-reading)
- [Glossary](#glossary)
</details>

## Quick Start

A test executable onsists of your tests as C/C++ expressions/functions, and the
orchestrator and test group functions you write using the LiteTest API that
mamnages the execution.

To try LiteTest, simply follow these 6 steps:

<details>
<summary><strong>Click to view</strong></summary>

1, copy 'litetest.h' and 'litetest.c' to your current directory:

```sh
cp /path/to/litetest.h .
cp /path/to/litetest.c .
```

2. Create a file named `test_quick.c` in the same directory.

3. Copy and paste the code into `test_quick.c`:

<details>
<summary>💻 Click to view and copy</summary>

```c
#include "litetest.h"

// A simple test group function.

static LT_DECLARE_GROUP(test_quick)
{
  LT_INIT_GROUP(test_quick, 1);

  int a = 2;
  int b = 2;

  // 4 test assertions.
  LT_TEST(a == b, , 0);        // Pass
  LT_TEST(a + b == 4, ,  0);    // Pass
  LT_TEST(a - b == 1, , 0);    // Fail
  LT_TEST(LT_FAULT(1), , 0);   // Fault

  LT_RETURN;
}

// A simple orchestrator (main) function.

LT_DECLARE_ORCHESTRATOR(main)
{
  LT_INIT_ORCHESTRATOR(main, quick, 1);
  LT_PARSE_ARGS(2, "quick_test_report.txt");
  LT_OPEN_REPORT("Test Quick Report");

  // Single test category.
  LT_WRITE_RESULT(LT_GROUP(test_quick), "Quick tests");

  LT_CLOSE_REPORT("Note: This report is a very simple example of using LiteTest.\n"
                  "Note: Multiple test categories can be added using multiple\n"
                  "      test functions.\n"
                  "Note: Orchestrator (`main`) and test functions can be placed in\n"
                  "      individual modules (.c files).\n"
                  "Note: Parameters can be set to run tests in parallel, isolate\n"
                  "      a test to a separate thread or process, etc.\n"
                  "Note: The expression for LT_TEST can reference functions to\n"
                  "      provide a more complex test. A non-zero result indicates\n"
                  "      pass and a zero result indicates fail. If a fault occurs\n"
                  "      executing the expression, it is detected and counted in\n"
                  "      the report as a fault.\n"
                  "Note: Larger projects can place files in a more conventional\n"
                  "      layout (e.g., `include/` and `src/`, but this example keeps\n"
                  "      everything in your current directory for simplification.\n"
                  "Note: See README.md for LiteTest for additional API features.\n");
  LT_EXIT;
}
```
</details>

4. Build the executable `test_quick` in your current directory:

```sh
cc -std=c99 -Wall -Wextra -o test_quick test_quick.c litetest.c
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

<details>
<summary>💻 Click to view</summary>

```text
LiteTest Report
                             Pass   Fail     Fault
--------------------------------------------------
1. Orchestrator                 4
2. Guard 1 and 2                6
--------------------------------------------------
                      Total    10
```
</details>
</details>

## Documentation

For user documentation of the LiteTest API, see:

- **README.md** — Introduction and quick summary atart to LiteTest.
- **LiteTest User Guide** — Concepts, workflow, examples.
- **LiteTest API Reference** — Public API types, enums, macros, and functions.

for contributor and maintainer documentation of the LiteTest framework,
additionally see:

- **LiteTest Contributor Guide** — Versioning, branching, testing, documentation rules.  
- **LiteTest Framesork Guide** — Concepts, workflow, examples.
- **LiteTest API Reference** — Private (internal) framework types, enums, macros, functions, etc.

See [Repository Layout](#repository-layout) for locations of the above and the
LiteTest directories and files,

## Key Features

- Pure C implementation  
- Minimal footprint (single header + source)  
- Fault detection using POSIX signals  
- Optional process‑isolated execution  
- Parallel and concurrent test execution  
- Clear pass/fail/fault reporting  
- Simple API based on macros and test group functions  

