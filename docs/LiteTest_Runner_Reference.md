# LiteTest Runner Reference

This document defines the **public API** for the LiteTest Runner as declared in `litetest_runner.h`.  
It includes public types, enums, macros, and functions.  
Internal implementation details are not included.

Copyright (c) 2026 Paul Sinclair
SPDX-License-Identifier: MIT. For license details, see ../LICENSE.

## Overview

---

# 1. Public Types

(Extracted directly from `litetest_runner.h`)

- `lt_result_t`  
- `lt_dirpath`  
- `lt_currentlevel`  
- `lt_currentresult`  
- `lt_maxparallel`  
- `lt_blockname`  
- `lt_iswritedirpath`  

---

# 2. Public Enums

As defined in `litetest_runner.h`:

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

As declared in `litetest_runner.h`:

### Process and Runtime Helpers

- `int lt_execute_command(const char *command_line, int timeout_ms, char *output_buffer, size_t output_buffer_size, int *exit_code)`  
- `int lt_wait_for_condition(int (*condition)(void *callback_context), void *callback_context, int timeout_ms, int poll_interval_ms)`  

### File and Filesystem Helpers

- `int lt_copy_file(const char *source_path, const char *destination_path)`  
- `int lt_make_temp_dir(const char *prefix, char *out_path, size_t out_path_size)`  

### Comparison and Matching Helpers

- `int lt_compare_files(FILE *left_file, FILE *right_file)`  
- `int lt_compare_file_to_path(FILE *file, const char *path)`  
- `int lt_compare_paths(const char *left_path, const char *right_path)`  
- `int lt_compare_path_to_file(const char *path, FILE *file)`  
- `int lt_match(const char *text, const char *pattern)`  

### Environment Helpers

- `int lt_with_environment_variable(const char *variable_name, const char *temporary_value, int (*callback)(void *callback_context), void *callback_context)`  

---

# 5. Versioning

The public API follows the versioning rules described in the **LiteTest Contributor Guide**.

---

# 6. Notes

- All public API symbols are declared in `include/litetest_runner.h`.  
- Inline documentation in the header is authoritative.  
