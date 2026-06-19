# LiteTest Runner Internal Guide

This guide documents the internal architecture and design of the LiteTest Runner
API and framework. It is intended for maintainers and contributors working on the
implementation. It is companion document to the LiteTest Runner Internals
Reference document.

**Copyright (c) 2026 Paul Sinclair**

<details>
<summary>Click to view License</summary>

#### **License**

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
<summary>Click to view Preface</summary>

## Preface

This document is intended for contributors.

For a list of other LiteTest documents and the LiteTest repository layout, see
the LiteTest Documentation Guide.

For a glossary of terms, see the LiteTest Glossary Reference.
</details>

<details>
<summary>Click to view Document Version History</summary>

### Document Version History

<details>
<summary>Click to view</summary>

| Document | Date | Runner | Test | Comment | Author/Editor |
|----------|------|--------|------|---------|---------------|
| 1.0 | 2026‑06‑11 | 1.0.0 | 1.0.0 | Initial version. | Paul Sinclair |

- The `Document` column records the document's version and uses the version format `M.u` (Major, update).
- The `Runner` column records the LiteTest Runner API version current at the time this document version was published and is defined by its `LT_RUNNER_VERSION` macro.
- The `Test` column records the LiteTest Test API version current at the time this document version was published and is defined by its `LT_TEST_VERSION` macro.

Both Runner and Test versions specify a string of the form `"M.m.p"` (Major, minor, patch). `M` is the same for the document, Runner, and Test.

The document's `u` (update) version track updates to this document and does not correspond to a `m` (minor) or `p` (patch) version. `u` increments whenever this document is updated without a change to `M`, and it resets to `0` when `M` is incremented.
</details>
</details>
</details>

<details>
<summary>Click to view Table of Contents</summary>

## Table of Contents

<details>
<summary>Click to view</summary>

[**1. Introduction**](#1-introduction)  
[***1. Public and Internal Name Conventions](#1.1-public-and-internal-name-conventions)  
  - [Why Internal Symbols Appear in the Header](#why-internal-symbols-appear-in-the-header)


- [**Glossary**](#glossary)
</details>
</details>

<details>
<summary>Click to view 1. Introduction</summary>

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
</details>

LiteTest exposes some internal symbols in `litetest_runner.h` because the framework’s
macros expand into code that depends on internal types and helper functions.
These symbols must be visible to user code for the macros to compile correctly,
but they are not part of the public API and should not be used directly.

Their presence in the header reflects C implementation requirements, not intended
usage. Contributors may modify these symbols as needed, provided the public API
contract remains intact.

<details>
<summary>Click to view 1.1 Public and Internal Naming Conventions</summary>

### 1.1 Public and Internal Naming Conventions

<details>
<summary>Click to view</summary>

Any framework names that are public and visible to LiteTest API users are prefixed
with `lt_...` (typically lowercase) or `LT_...` (typically uppercase).

Any framework names that are internal (but technically visible to LiteTest API users)
follow the pattern `litetest_..._internal_t`, `litetest_..._internal`, or `LITETEST_..._INTERNAL`. These names should not be referenced by API users.

In general, users of the API should not define names prefixed with `lt_`, `LT`, `litetest_`,
or `LITETEST`, or reference names prefixed with `litetest_` or `LITETEST_`.
</details>
</details>
</details>

<details>
<summary>Click to view 2. Architecture Overview</summary>

## 2. Architecture Overview
- Process model  
- Thread model  
- Signal handling  
- Fault detection  
- Execution flow  

---
</details>

<details>
<summary>Click to view 3. Orchestrator Internals</summary>

## 3. Orchestrator Internals
- Initialization  
- Argument parsing  
- Report lifecycle  
- Category aggregation  

---
</details>

<details>
<summary>Click to view 4. Test Group Internals</summary>

## 4. Test Group Internals
- Group initialization  
- Execution scheduling  
- Result accumulation  

---
</details>

<details>
<summary>Click to view 5. Test Execution Engine</summary>

## 5. Test Execution Engine
- Expression evaluation  
- Isolation modes  
- Concurrency model  
- Error and fault propagation  

---
</details>

<details>
<summary>Click to view 6. Process‑Isolated Execution</summary>

## 6. Process‑Isolated Execution
- Child process creation  
- Monitoring and timeouts  
- Exit code interpretation  
- Fault mapping  

---
</details>

<details>
<summary>Click to view 7. Thread‑Isolated Execution</summary>

## 7. Thread‑Isolated Execution
- Thread creation  
- Synchronization  
- Fault boundaries  

---
</details>

<details>
<summary>Click to view 8. Signal Guard System</summary>

## 8. Signal Guard System
- Installed handlers  
- Supported signals  
- Fault classification  
- Recovery behavior  

---
</details>

<details>
<summary>Click to view 9. Report Generation Internals</summary>

## 9. Report Generation Internals
- Output formatting  
- Category totals  
- Fault messages  
- Notes and metadata  

---
</details>

<details>
<summary>Click to view 10. Internal State and Global Variables</summary>

## 10. Internal State and Global Variables
(Placeholder for internal state descriptions.)

---
</details>

<details>
<summary>Click to view 11. Error Handling and Safety Guarantees</summary>

## 11. Error Handling and Safety Guarantees
(Placeholder for internal error semantics.)

---
</details>

<details>
<summary>Click to view 12. Implementation Notes</summary>

## 12. Implementation Notes
- Portability considerations  
- POSIX dependencies  
- Platform differences  

---
</details>

<details>
<summary>Click to view 13. Future Improvements</summary>

## 13. Future Improvements
(Placeholder for roadmap items.)
</details>

<details>
<summary>Click to view Repository Layout</summary>

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
|  \- litetest_runner.h
|- reports/
|  |- litetest_test_report-I.txt
|  \- litetest_test_report.txt
|- scripts/
|- src/
|  \- litetest_runner.c
|- tests/
|  |- test_litetest.c
|  |- test_orchestrator.c
|  |- test_guard1.c
|  \- test_guard2.c
```

Use this as a reference when adapting LiteTest into your own project structure.
</details>
</details>

<details>
<summary>Click to view Glossary</summary>

## Glossary

<details>
<summary>Click to view</summary>

For general LiteTest terms, see the LiteTest Glossary document.

Runner‑Specific Terms:

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
</details>
