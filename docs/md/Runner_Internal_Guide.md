![Runner Internal Guide](/docs/branding/Runner_Internal_Guide.png)

This guide documents the internal architecture and design of the Runner Famework
and API. It complements the Runner Internal Reference.

#### Copyright (c) 2026 Paul Sinclair

<details>
<summary><strong>License</strong></summary>

### License

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
<summary><strong>Preface</strong></summary>

## Preface

This document is intended for contributors who need guidance for the
internals of the Runner Framework and API.

For a list of other documents and the repository layout, see
the Documentation Guide.

For a glossary of terms, see the Glossary Reference.

A printer-friendly PDF file for this document is available`.

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;Document Version History</summary>

### Document Version History

| Document | Runner | Test | Date | Comment | Author/Editor |
|----------|------|--------|------|---------|---------------|
| v1.0.0 | v1.0.0 | v1.0.0 | 2026‑06‑11 | Initial version. | Paul Sinclair |

- **Document**: A version of this document.
- **Runner**: The Runner API version current at the time of publication.
- **Test**: The Test API version current at the time of publication.

A version has the format `v<M>.<m>.<p>` where `<M>` is the major version,
`<m>` is the minor version, and `<p>` is the patch version.
</details>
</details>

<details>
<summary><strong>Table of Contents</strong></summary>

## Table of Contents

1. [**Introduction**](#1-introduction)  
   1.1. [Public and Internal Name Conventions](#1.1-public-and-internal-name-conventions)
     
    [**Glossary**](#glossary)
</details>

<details>
<summary><strong>1. Introduction</strong></summary>

## 1. Introduction

Basic concepts and high-level description of the framework internals and design goals.

In this document, a *symbol* refers to any named entity in the framework, including:

- typedefs
- structs
- enums and enum values
- macros
- variables
- functions

Some internal symbols in `runnerapi.h` are exposed because the API
macros expand into code that depends on internal types and helper functions.
These symbols must be visible to user code for the macros to compile correctly,
but they are not part of the public API and should not be used directly.

Their presence in the header reflects C implementation requirements, not intended
usage. Contributors may modify these symbols as needed, provided the public API
contract remains intact.

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;1.1. Public and Internal Naming Conventions</summary>

### 1.1. Public and Internal Naming Conventions

Any Runner API names that are public and visible to Runner API users are prefixed
with `ra_...` (typically lowercase) or `RA_...` (typically uppercase).

Any framework names that are internal (but technically visible to Bunner API users)
have the prefix `ra_internal_` or `RA_INTERNAL_`. These names should not be referenced
by Runner API users.

In general, users of the API should not define names prefixed with `ra_` or `RA_`,
`, or reference names prefixed with `ra_internal_` or `RA_INTERNAL_`.
</details><br>
</details>

<details>
<summary><strong>2. Architecture Overview</strong></summary>

## 2. Architecture Overview

- Process model  
- Thread model  
- Signal handling  
- Fault detection  
- Execution flow  
</details>

<details>
<summary><strong>3. Orchestrator Internals</strong></summary>

## 3. Orchestrator Internals

- Initialization  
- Argument parsing  
- Report lifecycle  
- Category aggregation  
</details>

<details>
<summary><strong>4. Test Group Internals</strong></summary>

## 4. Test Group Internals

- Group initialization
- Execution scheduling
- Result accumulation
</details>

<details>
<summary><strong>5. Test Execution Engine</strong></summary>

## 5. Test Execution Engine

- Expression evaluation  
- Isolation modes  
- Concurrency model  
- Error and fault propagation  
</details>

<details>
<summary><strong>6. Process-Isolated Execution</strong></summary>

## 6. Process-Isolated Execution

- Child process creation  
- Monitoring and timeouts  
- Exit code interpretation  
- Fault mapping  
</details>

<details>
<summary><strong>7. Thread-Isolated Execution</strong></summary>

## 7. Thread-Isolated Execution

- Thread creation  
- Synchronization  
- Fault boundaries  
</details>

<details>
<summary><strong>8. Signal Guard System</strong></summary>

## 8. Signal Guard System
- Installed handlers  
- Supported signals  
- Fault classification  
- Recovery behavior  
</details>

<details>
<summary><strong>9. Report Generation Internals</strong></summary>

## 9. Report Generation Internals

- Output formatting  
- Category totals  
- Fault messages  
- Notes and metadata  
</details>

<details>
<summary><strong>10. Internal State and Global Variables</strong></summary>

## 10. Internal State and Global Variables

(Placeholder for internal state descriptions.)
</details>

<details>
<summary><strong>11. Error Handling and Safety Guarantees</strong></summary>

## 11. Error Handling and Safety Guarantees

(Placeholder for internal error semantics.)
</details>

<details>
<summary><strong>12. Implementation Notes</strong></summary>

## 12. Implementation Notes

- Portability considerations  
- POSIX dependencies  
- Platform differences  
</details>

<details>
<summary><strong>13. Future Improvements</strong></summary>

## 13. Future Improvements

(Placeholder for roadmap items.)
</details>

<details>
<summary><strong>Glossary</strong></summary>

## Glossary

For general terms used the documentation, see the Glossary document.

Runner-Specific Terms:

- **Orchestrator Lifecycle**: The sequence of initialization, group execution,
  test execution, and report finalization performed by the briteTest framework.
- **Guard Behavior**: The mechanism briteTest uses to catch runtime faults
  (e.g., segmentation faults) and continue executing remaining tests.
- **Isolation Semantics**: The rules governing how tests and groups run in
  threads or processes to prevent interference and ensure fault containment.
- **Concurrency Model**: The framework's rules for running tests concurrently
  within `RA_BEGIN_CONCURRENT` / `RA_END_CONCURRENT` blocks.
- **Execution Phases**: The internal stages of orchestrator operation, including
  initialization, argument parsing, group dispatch, test dispatch, and report
  writing.
- **Fault Handling Model**: The framework's strategy for capturing and reporting
  faults without terminating the entire test run.
- **Control File Promotion**: The process of replacing an outdated control file
  with a newly generated file when differences are expected or intentional.
- **Nested Group Behavior**: The rules governing how groups may contain other
  groups and how isolation and concurrency propagate through nested structures.
- **Concurrent Block Behavior**: The semantics of executing multiple tests in
  parallel within a concurrent block, including ordering and isolation rules.
</details>
