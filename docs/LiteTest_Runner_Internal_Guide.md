# LiteTest Runner Internal Guide

This guide documents the internal architecture and design of the LiteTest Runner
API and framework. It is intended for maintainers and contributors working on the
implementation. It is companion document to the LiteTest Runner Internals
Reference document.

Copyright (c) 2026 paulsinclair51.  
SPDX-License-Identifier: MIT.

<details>
<summary>Click to view</summary>

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

## Preface

### Document Version History

<details>
<summary>Click to view</summary>

| Document | Date       | LiteTest | Description                                   | Author/Editor    |
|----------|------------|----------------------------------------------------------|------------------|
| 1.0      | 2026‑06‑11 | 1.0.0    | Initial LiteTest Framework Reference.         | paulsinclair51   |

The **Document** column tracks the version `M.u` (major, update) of this Framework
Reference document. The **LiteTest** column records the latest LiteTest version
at the time this document version was published.

The current LiteTest version is defined in `litetest.h` by the macro `LT_VERSION`,
which specifies a string of the form `"M.m.p"` (major, minor, patch).
`litetest.c` defines a matching version string `LT_VERSION_C`. For details, see
the public API and framework documentation.

A **major LiteTest release requires a corresponding major update to this
document** and therefore the document’s major version must match the LiteTest
major version. The **update** version tracks updates to this document itself and
does not correspond to LiteTest minor or patch versions. The update version is
incremented whenever this document is updated without a change to the major version,
and it resets to `0` when the major version increases.
</details>

### Documentation

<details>
<summary>Click to view</summary>

For user documentation of the LiteTest API, see:

- **README.md** — Introduction to LiteTest.
- **LiteTest User Guide** — Concepts, workflow, examples.
- **LiteTest API Reference** — Public API types, enums, macros, and functions.

For contributor and maintainer documentation of the LiteTest framework,
additionally see:

- **LiteTest Contributor Guide** — Versioning, branching, testing, documentation rules.  
- **LiteTest Framework Guide** — Concepts, workflow, examples.
- **LiteTest Framework Reference** — Private (internal) framework types, enums, macros, functions, etc.

See [Repository Layout](#repository-layout) for locations of the above documents and the
LiteTest directories and files.

#### Documentation Style Guide

<details>
<summary>Click to view</summary>

1. Tone
   - Technical, precise, and neutral.
   - No marketing language.
   - Prefer clarity over cleverness.

2. Formatting
   - Use backticks for code identifiers.
   - Use fenced code blocks for file trees, examples, and commands.
   - Keep line lengths reasonable for GitHub rendering.

3. Writing Guidelines
   - Define terms once, and then use them consistently.
   - Avoid synonyms for technical concepts (e.g., always “update version,” never “revision”).
   - Keep paragraphs short.
   - Use lists for enumerations.

4. `Click to view`
   - Use `Click to view` sections and subsections to keep the document readable while
     still accommodating large amounts of technical detail:
    - Collapsing sections allows readers to scan the structure and expand only what
      they need.
    - This keeps the document manageable, avoids overwhelming readers with unrelated
      detail, and makes the document easier to navigate.

5. Writing Style Consistency: To keep LiteTest documentation clear and easy to read, maintain **parallel
   structure** within lists and related sentences. In practice:
   - Start list items with the same part of speech (typically a verb).
   - Keep grammatical patterns consistent across bullets.
   - Avoid mixing styles such as “Keep paragraphs short” with “Using lists for enumerations.”
   - Rewrite items as needed so the list reads smoothly and uniformly.
</details>
</details>

## Table of Contents

<details>
<summary>Click to view</summary>

- [**1. Introduction**](#1-introduction)  
  - [Public and Internal Name Conventions](#public-and-internal-name-conventions)  
  - [Why Internal Symbols Appear in the Header](#why-internal-symbols-appear-in-the-header)

- [**Repository Layout**](#repository-layout)

- [**Glossary**](#glossary)
</details>


## 1. Introduction

Basic concepts and high‑level description of the framework internals and design goals.

<details>
<summary>Click to view</summary>

In this document, a *symbol* refers to any named entity in the LiteTest framework, including:

- typedefs
- structs
- enums and enum values
- macros
- variables
- functions
</details>

LiteTest exposes some internal symbols in `litetest.h` because the framework’s
macros expand into code that depends on internal types and helper functions.
These symbols must be visible to user code for the macros to compile correctly,
but they are not part of the public API and should not be used directly.

Their presence in the header reflects C implementation requirements, not intended
usage. Contributors may modify these symbols as needed, provided the public API
contract remains intact.

#### Public and Internal Naming Conventions

<details>
<summary>Click to view</summary>

Any framework names that are public and visible to LiteTest API users are prefixed
with `lt_...` (typically lowercase) or `LT_...` (typically uppercase).

Any framework names that are internal (but technically visible to LiteTest API users)
follow the pattern `litetest_..._internal_t`, `litetest_..._internal`, or `LITETEST_..._INTERNAL`.
These names should not be referenced by API users.

In general, users of the API should not define names prefixed with `lt_`, `LT`, `litetest_`,
or `LITETEST`, or reference names prefixed with `litetest_` or `LITETEST_`.
</details>
</details>

## 2. Architecture Overview
- Process model  
- Thread model  
- Signal handling  
- Fault detection  
- Execution flow  

---

## 3. Orchestrator Internals
- Initialization  
- Argument parsing  
- Report lifecycle  
- Category aggregation  

---

## 4. Test Group Internals
- Group initialization  
- Execution scheduling  
- Result accumulation  

---

## 5. Test Execution Engine
- Expression evaluation  
- Isolation modes  
- Concurrency model  
- Error and fault propagation  

---

## 6. Process‑Isolated Execution
- Child process creation  
- Monitoring and timeouts  
- Exit code interpretation  
- Fault mapping  

---

## 7. Thread‑Isolated Execution
- Thread creation  
- Synchronization  
- Fault boundaries  

---

## 8. Signal Guard System
- Installed handlers  
- Supported signals  
- Fault classification  
- Recovery behavior  

---

## 9. Report Generation Internals
- Output formatting  
- Category totals  
- Fault messages  
- Notes and metadata  

---

## 10. Internal State and Global Variables
(Placeholder for internal state descriptions.)

---

## 11. Error Handling and Safety Guarantees
(Placeholder for internal error semantics.)

---

## 12. Implementation Notes
- Portability considerations  
- POSIX dependencies  
- Platform differences  

---

## 13. Future Improvements
(Placeholder for roadmap items.)

## Repository Layout

<details>
<summary>Click to view</summary>
  
GitHub repository: `paulsinclair51/LiteTest`

Repository layout (listing core files):

```text
LiteTest/
|- .github/
|  \- workflows/
|     \- ci.yml
|- README.md
|- LICENSE
|- Makefile
|- build_test_litetest.ps1
|- build/
|- docs/
|  \- LiteTest_API_User_Guide.md
|  \- LiteTest_API_Reference.md
|  \- LiteTest_Contributor_Guide.md
|  \- LiteTest_Framework_Guide.md
|  \- LiteTest_Framework_Reference.md
|- examples/
|- include/
|  \- litetest.h
|- reports/
|  |- litetest_test_report-I.txt
|  \- litetest_test_report.txt
|- scripts/
|- src/
|  \- litetest.c
|- tests/
|  |- test_litetest.c
|  |- test_orchestrator.c
|  |- test_guard1.c
|  \- test_guard2.c
```

Use this as a reference when adapting LiteTest into your own project structure.
</details>

## Glossary

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

### Framework‑Specific Terms

<details>
<summary>Click to view</summary>

- **Orchestrator Lifecycle**: The sequence of initialization, group execution,
  test execution, and report finalization performed by the LiteTest framework.
- **Guard Behavior**: The mechanism LiteTest uses to catch runtime faults
  (e.g., segmentation faults) and continue executing remaining tests.
- **Isolation Semantics**: The rules governing how tests and groups run in
  threads or processes to prevent interference and ensure fault containment.
- **Concurrency Model**: The framework’s rules for running tests concurrently
  within `LT_BEGIN_CONCURRENT` / `LT_END_CONCURRENT` blocks.
- **Execution Phases**: The internal stages of orchestrator operation, including
  initialization, argument parsing, group dispatch, test dispatch, and report
  writing.
- **Fault Handling Model**: The framework’s strategy for capturing and reporting
  faults without terminating the entire test run.
- **Control File Promotion**: The process of replacing an outdated control file
  with a newly generated file when differences are expected or intentional.
- **Nested Group Behavior**: The rules governing how groups may contain other
  groups and how isolation and concurrency propagate through nested structures.
- **Concurrent Block Behavior**: The semantics of executing multiple tests in
  parallel within a concurrent block, including ordering and isolation rules.
</details>
