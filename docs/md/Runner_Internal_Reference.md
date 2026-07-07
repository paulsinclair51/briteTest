![Runner Internal Reference](/docs/branding/Runner_Internal_Reference.png)

#### Version: 1.0.0

This document provides a reference to the briteTestRunner API internals.
It includes types, structs, unions, enums, macros, and functions.

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

This document is intended for contributors who need a reference for the
internals of the Runner Framework and API.

For a list of other documents and the repository layout, see
the Documentation Guide.

For a glossary of terms, see the Glossary Reference.

A printer-friendly PDF file for this document is available.

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;Document Version History</summary>

### Document Version History

| Version | Date | Comment | Author/Editor |
|----------|------|---------|---------------|
| v1.0.0 | 2026‑06‑11 | Initial version. | Paul Sinclair |
</details>
</details>

<details>
<summary><strong>Table of Contents</strong></summary>

## Table of Contents

1. [**Introduction**](#1-introduction)  
   1.1. [Public and Internal Name Conventions](#public-and-internal-name-conventions)  

2. [**Symbols Defined in `runnerapi.h`**](#2-symbols-defined-in-britetesth)  
   2.1. [Types](#21-types)  
   2.2. [Structs](#22-structs)  
   2.3. [Enums and Enum Values](#23-enums-and-enum-values)  
   2.4. [Global Variables](#24-global-variables)  
   2.5. [Macros](#25-macros)  
   2.6. [Functions](#26-functions)

3. [**Symbols Defined in `runnerapi.c`**](#3-symbols-defined-in-britetestc)  
   3.1. [Types](#31-types)  
   3.2. [Structs](#32-structs)  
   3.3. [Enums and Enum Values](#33-enums-and-enum-values)  
   3.4. [Global Variables](#34-global-variables)  
   3.5. [Macros](#35-macros)  
   3.6. [Functions (declared as a forward reference) in `runnerapi.h`](#36-functions-declared-as-a-forward-reference-in-britetesth)  
   3.7. [Functions (not declared in `runnerapi.h`)](#37-functions-not-declared-in-britetesth)

4. [**Execution Engine**](#4-execution-engine)

5. [**Signal Handling**](#5-signal-handling)

6. [**Process Management**](#6-process-management)

7. [**Thread Management**](#7-thread-management)

8. [**File and Path Support**](#8-file-and-path-support)

9. [**Matching and Comparison Support**](#9-matching-and-comparison-support)

10. [**Environment Support**](#10-environment-support)

    [**Glossary**](#glossary)
</details>

<details>
<summary><strong>1. Introduction</strong></summary>

## 1. Introduction

briteTest's internal architecture consists of several cooperating subsystems,
including the implementation of API macros and functions, the execution engine,
guard/fault handling, isolation support, file/path utilities, matching/comparison
helpers, and environment support. These components work together to run test
groups and test expressions reliably across threads and processes while capturing
faults and producing structured reports.

The remainder of this document describes each internal symbol used to implement
these subsystems, organized from high-level behavior down to low-level details.

In this document, a *symbol* refers to any named entity in the briteTest framework, including:

- typedefs
- structs
- enums and enum values
- macros
- variables
- functions

This document is organized by the named entities in the briteTest Runner
implementation. Each symbol (type, macro, function, etc.) is described individually, including its purpose, behavior, and usage. It serves as
the reference companion to the briteTest Framework Guide, defining the
framework's components precisely while the Guide explains their design
and interaction.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;1.1. Public and Internal Naming Conventions</summary>

###1.2. Public and Internal Naming Conventions

Any framework names that are public and visible to briteTest API users are prefixed
with `ra_...` (typically lowercase) or `RA_...` (typically uppercase).

Any framework names that are internal (but technically visible to briteTest API users)
follow the pattern `britetest_..._internal_t`, `britetest_..._internal`, or `BRITETEST_..._INTERNAL`.
These names should not be referenced by API users.

In general, users of the API should not define names prefixed with `ra_`, `BT`, `britetest_`,
or `BRITETEST`, or reference names prefixed with `britetest_` or `BRITETEST_`.
</details>

<details>
<summary><strong>2. Symbols Defined in `runnerapi.h`</strong></summary>

## 2. Symbols Defined in `runnerapi.h`

These are used by `runnerapi.h` and `runnerapi.c`, and are public or internal
based on their name per the naming conventions.

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;2.1. Types</summary>

### 2.1. Types

These typedefs declare fundamental internal types used throughout the briteTest framework.

<details>
<summary>ra_resubt_t</summary>

#### ra_resubt_t

**Declaration**
```c
typedef struct
{ size_t pass;
  size_t fail;
  size_t fault;
  size_t injected_fail;
  size_t injected_fault;
} ra_resubt_t;
```

**Description**  
Result counters produced by test execution and propagated through group and
orchestrator aggregation logic.

**Usage Notes**  
- `fault == SIZE_MAX` is a sentinel meaning a function-level fault was captured.
- Function-level fault sentinel values are introduced by the signal-guard path.
- This sentinel is distinct from ordinary fault counts returned by test logic.
- Related helpers include `ra_currentresult(void)` and result-merging macros.

**Example**
```c
ra_resubt_t result = {0, 0, 0, 0, 0};
```
</details><br>
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;2.2. Structs</summary>

### 2.2. Structs

<details>
<summary>struct <StructName></summary>

#### struct <StructName>

**Declaration**
```c
typedef struct <StructName> {
    <field-type> <field-name>;
    ...
} <StructName>;
```

**Description**  
Explain the purpose of this struct, what data it aggregates, and how it participates in the briteTest execution model.

**Fields**
- `<field-name>` -- description  
- `<field-name>` -- description  

**Usage Notes**  
- Ownership or lifetime rules  
- Whether fields must be initialized by the user or framework

**Example**
```c
<StructName> s = { ... };
```
</details><br>
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;2.3. Enums and Enum Values</summary>

### 2.3. Enums and Enum Values

<details>
<summary>enum <EnumName></summary>

#### enum <EnumName>

**Declaration**
```c
typedef enum <EnumName> {
    <ENUM_VALUE_1>,
    <ENUM_VALUE_2>,
    ...
} <EnumName>;
```

**Description**  
Explain what conceptual category this enum models and how the values are used by the framework.

**Values**
- `<ENUM_VALUE_1>` -- meaning  
- `<ENUM_VALUE_2>` -- meaning  

**Usage Notes**  
- Any ordering assumptions  
- Whether values map to external formats (strings, logs, etc.)

**Example**
```c
<EnumName> mode = <ENUM_VALUE_1>;
```
</details><br>
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;2.4. Global Variables</summary>

### 2.4. Global Variables

<details>
<summary><VariableName></summary>

#### <VariableName>

**Declaration**
```c
extern <type> <VariableName>;
```

**Description**  
Explain the purpose of this global variable, what state it represents, and how it is used by the briteTest framework.

**Usage Notes**  
- Whether the variable is read-only or writable  
- Whether users are expected to modify it  
- Thread-safety considerations  
- Lifetime and initialization rules  

**Example**
```c
if (<VariableName> == ...) {
    ...
}
```
</details><br>
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;2.5. Macros</summary>

### 2.5. Macros

<details>
<summary><MACRO_NAME></summary>

#### <MACRO_NAME>

**Definition**
```c
#define <MACRO_NAME>(...) <expansion>
```

**Description**  
Describe the purpose of this macro, what it expands to conceptually, and how it fits into the briteTest orchestration or test definition model.

**Parameters**
- `<param>` -- meaning and constraints  
- `<param>` -- meaning  

**Usage Notes**  
- Side effects  
- Evaluation rules (e.g., multiple evaluation hazards)  
- Whether arguments must be constant expressions

**Example**
```c
<MACRO_NAME>(arg1, arg2);
```
</details><br>
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;2.6. Functions</summary>

### 2.6. Functions

The functions in this section may be `static`, `static inline`, or (by default) `extern`,
depending on how they are used within the framework.

<details>
<summary><FunctionName>()</summary>

#### <FunctionName>()

**Signature**
```c
<return-type> <FunctionName>(<parameters>);
```

**Description**  
Explain what this function does, when it is called, and how it interacts with the briteTest runtime.

**Parameters**
- `<param-name>` -- meaning, constraints, ownership  
- `<param-name>` -- meaning  

**Return Value**  
Describe what is returned and under what conditions.

**Errors / Preconditions**  
- Preconditions the caller must satisfy  
- Error conditions or undefined behavior cases

**Usage Notes**  
- Thread safety  
- Lifetime rules  
- Interaction with other briteTest components

**Example**
```c
<return-type> result = <FunctionName>(...);
```
</details><br>
</details>

<details>
<summary><strong>3. Symbols Defined in `runnerapi.c`</strong></summary>

## 3. Symbols Defined in `runnerapi.c`

These symbols are local to `runnerapi.c` unless specified or defaulting to
extern. Symbols that are local do not have to conform to the internal naming
conventions and more natural names may be used.

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.1. Types</summary>

### 3.1. Types

(Placeholder)
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.2. Structs</summary>

### 3.2. Structs

(Placeholder)
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.3. Enums and Enum Values</summary>

### 3.3. Enums and Enum Values

(Placeholder)
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.4. Global Variables</summary>

### 3.4. Global Variables

(Placeholder)
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.5. Macros</summary>

### 3.5. Macros

(Placeholder)
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.6. Functions (declared as a forward reference) in `runnerapi.h`</summary>

### 3.6. Functions (declared as a forward reference) in `runnerapi.h`

These functions are referenced internally by `runnerapi.h` but defined in `runnerapi.c`.
These functions are (by default) extern and must conform to the internal name conventions.

(Placeholder)
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.7. Functions (not declared in `runnerapi.h`)</summary>

### 3.7. Functions (not declared in `runnerapi.h`)

These functions are local to `runnerapi.c` and defined as static.
Since these are local, these names do not have to conform to the
internal name conventions and more natural names may be used.

(Placeholder)
</details><br>
</details>

<details>
<summary><strong>4. Execution Engine</strong></summary>

## 4. Execution Engine

(Placeholder for execution helpers.)
</details>

<details>
<summary><strong>5. Signal Handling</strong></summary>

## 5. Signal Handling

(Placeholder for signal guard helpers.)
</details>

<details>
<summary><strong>6. Process Management</strong></summary>

## 6. Process Management

(Placeholder for fork/exec/wait logic.)
</details>

<details>
<summary><strong>7. Thread Management</strong></summary>

## 7. Thread Management

(Placeholder for pthread logic.)
</details>

<details>
<summary><strong>8. File and Path Support</strong></summary>

## 8. File and Path Support

(Placeholder for filesystem support helpers.)
</details>

<details>
<summary><strong>9. Matching and Comparison Support</strong></summary>

## 9. Matching and Comparison Support

(Placeholder for comparison support helpers.)
</details>

<details>
<summary><strong>10. Environment Support</strong></summary>

## 10. Environment Support

(Placeholder for environment support helpers.)
</details>

<details>
<summary><strong>Repository Layout</strong></summary>

## Repository Layout
  
GitHub repository: `paulsinclair51/briteTest`

Repository layout (listing core files):

```text
briteTest/
|- .github/
|  \- workflows/
|     \- ci.yml
|- README.md
|- LICENSE
|- Makefile
|- build_test_britetest.ps1
|- build/
|- docs/
|  \- briteTest_API_User_Guide.md
|  \- briteTest_API_Reference.md
|  \- Contributor_Guide.md
|  \- briteTest_Framework_Guide.md
|  \- briteTest_Framework_Reference.md
|- examples/
|- include/
|  \- runnerapi.h
|- reports/
|  |- test_report-I.txt
|  \- test_report.txt
|- scripts/
|- src/
|  \- runnerapi.c
|- tests/
|  |- test_runner.c
|  |- orchestrator_tests.c
|  |- guard1_tests.c
|  \- guard2_tests.c
```

Use this as a reference when adapting briteTest into your own project structure.
</details>

<details>
<summary><strong>Glossary</strong></summary>

## Glossary
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;Framework-Specific Terms</summary>

### Framework-Specific Terms

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
