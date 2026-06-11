# LiteTest Framework Reference

This document defines the internal framework of LiteTest.

This is not part of the public API and may change between versions with only a minor
or patch increase if the change does not affect the public API contract.

Copyright (c) 2026 paulsinclair51
SPDX-License-Identifier: MIT. For license details, see ../LICENSE.

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
