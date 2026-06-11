# LiteTest API Reference

This document defines the **public API** of LiteTest as declared in `litetest.h`.  
It includes public types, enums, macros, and functions.  
Internal implementation details are not included.

Copyright (c) 2026 paulsinclair51
SPDX-License-Identifier: MIT. For license details, see ../LICENSE.

## Overview

---

# 1. Public Types

(Extracted directly from `litetest.h`)

- `lt_result_t`  
- `lt_dirpath`  
- `lt_currentlevel`  
- `lt_currentresult`  
- `lt_maxparallel`  
- `lt_blockname`  
- `lt_iswritedirpath`  

---

# 2. Public Enums

As defined in `litetest.h`:

- Result codes  
- Fault types  
- Isolation modes  

---

# 3. Public Macros

## 3.1 Orchestrator Macros

- `LT_DECLARE_ORCHESTRATOR(funcname)`  
- `LT_INIT_ORCHESTRATOR(funcname, project, maxparallel)`  
- `LT_PARSE_ARGS(maxargs, defaultreportfilename)`  
- `LT_OPEN_REPORT(title)`  
- `LT_WRITE_RESULT(gtm, category)`  
- `LT_CLOSE_REPORT(notes)`  
- `LT_EXIT`  

## 3.2 Test Group Macros

- `LT_DECLARE_GROUP(funcname)`  
- `LT_INIT_GROUP(funcname, maxparallel)`  
- `LT_RETURN`  

## 3.3 Execution Macros

- `LT_GROUP(funcname, [include], [isolation])`  
- `LT_TEST(expression, [include], [isolation])`  

Include parameter:

- `0` — never execute  
- `1` — always execute  
- `2–9` — execute only when `-In` is provided and `n ≥ include`  
- `I` — execute only when `-I` is provided  

Isolation parameter:

- `0` — same thread  
- `1` — separate thread  
- `2` — separate process  

## 3.4 Concurrent Block Macros

- `LT_BEGIN_CONCURRENT(blockname)`  
- `LT_END_CONCURRENT(blockname)`  

---

# 4. Public Functions

As declared in `litetest.h`:

### Process and Runtime Helpers

- `int lt_execute(const char *commandline, int timeout, char *outbuf, size_t outsz, int *exit_code)`  
- `int lt_wait_until(int (*predicate)(void *ctx), void *ctx, int timeout_ms, int interval_ms)`  

### File and Filesystem Helpers

- `int lt_copyfile(const char *src, const char *dst)`  
- `int lt_mktempdir(const char *prefix, char *outpath, size_t outsz)`  

### Comparison and Matching Helpers

- `int lt_filecmp(FILE *f1, FILE *f2)`  
- `int lt_filecmpfilepath(FILE *f, const char *fp)`  
- `int lt_filepathcmp(const char *fp1, const char *fp2)`  
- `int lt_filepathcmpfile(const char *fp, FILE *f)`  
- `int lt_match(const char *text, const char *pattern)`  

### Environment Helpers

- `int lt_with_env(const char *name, const char *value, int (*fn)(void *), void *ctx)`  

---

# 5. Versioning

The public API follows the versioning rules described in the **LiteTest Contributor Guide**.

---

# 6. Notes

- All public API symbols are declared in `include/litetest.h`.  
- Inline documentation in the header is authoritative.  
