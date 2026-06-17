# LiteTest Runner Reference

This document provides a reference to the LiteTest Runner API. It includes types, structs, unions,
enums, macros, and functions.

Copyright (c) 2026 Paul Sinclair
SPDX-License-Identifier: MIT. For license details, see ../LICENSE.

## 1. Introduction


## 2. Types



## 3. Structs



## 4. Unions



## 5. Enums



## 6. Macros

## 6.1. Orchestrator Function Macros

Macros used to define or declare the Orchestrator (`main`) function.

### 6.1.1. `LT_DECLARE_ORCHESTRATOR(funcname)[;]`

A semicolon is not allowed if the macro is followed by its definition `{...}` of the
orchestrator function; otherwise, it is required and indicates this is a decalaration
and a forward-reference to tne orchestrator function.


### 6.1.2. `LT_INIT_ORCHESTRATOR(funcname, project, maxparallel);`


### 6.1.3. `LT_PARSE_ARGS(maxargs, defaultreportfilename);`


### 6.1.4. `LT_OPEN_REPORT(title);`


### 6.1.5. `LT_WRITE_RESULT(gtm, category);`


### 6.1.6. `LT_CLOSE_REPORT(notes, notes_file);`


### 6.1.7. `LT_EXIT;`


### 6.2 Test Group Function Macros

Macros used to define or declare a test group function.

### 6.3.1. `LT_DECLARE_GROUP(funcname)`

A semicolon is not allowed if the macro is followed by its definition `{...}` of the
test group function; otherwise, it is required and indicates this is a declaration
and a forward-reference to tne test group function.



### 6.3.2. `LT_INIT_GROUP(funcname, maxparallel)`


### 6.3.3. `LT_RETURN`


### 6.3 Execute Macros

- `LT_GROUP(funcname, [include], [isolation])[;]`
- `LT_TEST(expression, [include], [isolation][;])`

A semicolon is not allowed if the macro is used as an argument to LT_WRITE_RESULTS macro;
otherwise, it is required.

Include parameter:

- `0`   — Never execute.
- `1`   — Always execute. 
- `2–9` — Execute only when the `-In` flag is specified and n ≥ include.
- `I`   — Execute only when the `-I` flag is specified.

Isolation parameter:

- `0` — Same thread.
- `1` — Separate thread.
- `2` — Separate process.

#### 6.3.1 `LT_GROUP(funcname, [include], [isolation])[;]


#### 6.3.2 `LT_TEST(expression, [include], [isolation])[;])``


### 6.4 Concurrent Block Macros

#### 6.4.1 `LT_BEGIN_CONCURRENT(blockname)`


#### 6.4.2 `LT_END_CONCURRENT(blockname);`


### 6.5. Version Macros
 
#### 6.5.1 `LT_RUNNER_VERSION`


#### 6.5.2  `LT_VERSION_MAJOR(v)`


#### 6.5.3  `LT_VERSION_MINOR(v)`


#### 6.5.4 `LT_VERSION_PATCH(v)`


#### 6.5.4 `LT_VERSION_NUM(v)`


#### 6.5.4 `LT_VERSION_HEX(v)`


#### 6.5.5 `LT_VERSION_CMP(v1, v2)`


## 7. Customization Functions`

### 7.1 `LT_FUNCNAME`


## 7. Golden Files

- Each test output file is compared with its golden file of the same name
  in the `tests/golden` directory to determine whether they match.

- If no corresponding golden file exists, the output file is automatically
  copied (promoted) into the `tests/golden` directory and is treated as a match.
  The test report notes that the file was promoted.

- A golden file containing only the line `##MATCH##\n` skips comparison and
  forces a match.

- A golden file containing only the line `##MISMATCH##\n` skips comparison and
  forces a mismatch.

- If an output file does not match its golden file but inspection determines
  the output is correct, update the golden file with a copy of the output.
  Alternatively, remove the golden file so that the next run will
  automatically promote the output.

### 7.1 Rationale for Parallel Directory for Golden Files

LiteTest uses a parallel `tests/golden` directory with golden files that keep
the exact same filename as their corresponding test output. This design avoids
the common problems found in extension‑based naming schemes:

- **No filename collisions**  
  Different outputs such as `foo.c` and `foo.h` remain distinct (`foo.c` vs.
  `foo.h`) instead of collapsing into a single `foo.golden`.

- **No special‑case rules**  
  Files with or without extensions follow the same rule. The golden filename is
  always identical to the output filename.

- **Preserves file type information**  
  Because the original extension is retained, it is immediately clear whether a
  golden file contains text, JSON, HTML, binary data, or anything else.

- **Simpler mental model**  
  Developers do not need to remember naming conventions or extension‑replacement
  rules. Golden files simply live in a parallel directory and share the same
  name as the output they validate.

- **Identical filenames in different output directories**  
  The above approach does not directly address this situation. If it occurs, the
  conflict can be resolved by creating parallel subdirectories under `tests/golden`
  so that each output file has a unique corresponding location. This can be done
  through customization of your test runner or, when needed, by extending the
  Runner and Test API.

