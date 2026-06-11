# LiteTest Framework Reference

This document defines the internal framework of LiteTest, a lightweight 
Application Programming Interface (API) and framework for defining, running,
and reporting tests in C/C++ projects.

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
- [Documentation](#documentation)
- [Why Internal Symbols Appear in the Header](#why-internal-symbols-appear-jn-the-header)
- [Repository Layout](#repository-layout)
- [Glossary](#glossary)
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
## Overview

This document is organized in a top-down order (in contrast to the bottom=up order in `litetest.h`
and `litetest.c`. This allows a contributors to begin with high-level behavior and
drill down into lower-level detail.

In this document, a *symbol* refers to any named entity in the LiteTest framework, including:

- typedefs
- structs
- enums and enum constants
- macros
- variables
- functions

Any frameworl names that are technically visible to LiteTest API users follow the pattern
`litetest_..._internal_t`, `litetest_..._internal`, or `LITETEST_..._INTERNAL`.
These names are only for internal use and should not be referenced by API users.

In general, users of the API should not define names prefixed with `lt_`, `LT`, `litetest_`,
or `LITETEST`, or use names prefixed with `litetest_` or `LITETEST_`.

### Why Internal Symbols Appear in the Header

Some internal symbols must appear in `litetest.h` because LiteTest relies on
macros that expand into code requiring access to internal types, constants, or
helper functions. These symbols must be visible to user code for the macros to
compile correctly, even though they are not intended for direct use.

Their visibility is an implementation requirement, not part of the public API
contract. Users should treat all such symbols as internal and avoid depending on
them, as they may change at any time.

### Internal Symbols in the Header (for guide)

LiteTest exposes some internal symbols in `litetest.h` because the framework’s
macros expand into code that depends on internal types and helper functions.
These symbols must be visible to user code for the macros to compile correctly,
but they are not part of the public API and should not be used directly.

Their presence in the header reflects implementation requirements, not intended
usage. Contributors may modify these symbols as needed, provided the public API
contract remains intact.


## Internal Symbols Defined in `litetest.h`

These  may be used internally by `litetest.h` or `litestest.c`.

---

### 1.1. Types

(Placeholder)

---

### 1.2. Structs

(Placeholder)

---

### 1.3. Enums and Enum Constants

(Placeholder)

---

### 1.4. Global Variables

(Placeholder)

---

### 1.5. Macros

(Placeholder)

---

### 1.6. Functions

(Placeholder)

These functions may be static, static inline, or (by default) extern.

---

## Internal Symbols Defined in `litetest.c`

### 2.1. Types

(Placeholder)

---

### 2.2. Structs

(Placeholder)

---

### 2.3. Enums and Enum Constants

(Placeholder)

---


### 2.4. Global Variables

(Placeholder)

---

### 2.5. Macros

(Placeholder)

---

### 2.6. Functions Declared (as a forward reference) in `litetest.h`

These are used internally by `litetest.h` but defined in `litetest.c`.
These functions are (by default) extern.

(Placeholder)

---

### 2.7. Functions (not declared in `liteTest.h`)

(Placeholder)

These functions are static.

---
## 3. Execution Engine Internals

(Placeholder for internal execution helpers.)

---

## 4. Signal Handling Internals

(Placeholder for signal guard helpers.)

---

## 5. Process Management Internals

(Placeholder for fork/exec/wait logic.)

---

## 6. Thread Management Internals

(Placeholder for pthread logic.)

---

## 7. File and Path Utilities

(Placeholder for internal filesystem helpers.)

---

## 8. Matching and Comparison Utilities

(Placeholder for internal comparison helpers.)

---

## 9. Environment Utilities

(Placeholder for internal environment helpers.)

---
