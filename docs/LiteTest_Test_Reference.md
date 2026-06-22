![LiteTest Test Reference](branding/LiteTest_Test_Reference.png)

This document summarizes the public Test API declared in `include/litetest_test.h`.
It focuses on the helper-specific return conventions and the option structs used by the
comparison helpers.

#### Copyright (c) 2026 Paul Sinclair

<details>
<summary>License</summary>

#### **License**

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
<summary>Preface</summary>

## Preface

This document is intended for LiteTest users and contributors who need
quick access to the definitions of terms used in LiteTest or to browse
through the terms.

For a list of other LiteTest documents and the LiteTest repository layout, see
the LiteTest Documentation Guide.

For a glossary of terms, see the LiteTest Glossary Reference.
</details>

<details>
<summary>Document Version History</summary>

### Document Version History

| Document | Runner | Test | Date | Comment | Author/Editor |
|----------|------|--------|------|---------|---------------|
| 1.0 |1.0.0 | 1.0.0 | 2026‑06‑11 |  Initial version. | Paul Sinclair |

- The **Document** column records the document's version with the
  format `M.u` (Major, update).
- The **Runner** column records the LiteTest Runner API version
  current at the time this document version was published and is
  defined by its `LT_RUNNER_VERSION` macro.
- The **Test** column records the LiteTest Test API version current at
  the time this document version was published and is defined by its
  `LT_TEST_VERSION` macro.
- Both Runner and Test use the version format `"M.m.p"` (Major, minor,
  patch).
- `M` is the same for the Document, Runner, and Test versions.

The document's update version tracks released updates to this document and does
not correspond to a minor or patch version. `u` increments when document
changes are published in a release without a change to `M`, and it resets to
`0` when `M` is incremented.
</details>

<details>
<summary>TABLE OF CONTENTS</summary>

- [1. Return Conventions](#1-return-conventions)
  - [1.1 Return Styles](#11-return-styles)
  - [1.2 Assertion Guidance](#12-assertion-guidance)
- [2. Comparison Option Structs](#2-comparison-option-structs)
  - [2.1 lt_path_compare_options_t](#21-lt_path_compare_optionst)
  - [2.2 lt_path_metadata_compare_options_t](#22-lt_path_metadata_compare_optionst)
  - [2.3 lt_json_compare_options_t](#23-lt_json_compare_optionst)
  - [2.4 lt_text_compare_options_t](#24-lt_text_compare_optionst)
  - [3. Common Usage Patterns](#3-common-usage-patterns)
  - [3.1 Compare Two Paths While Ignoring Timestamps](#31-compare-two-paths-while-ignoring-timestamps)
  - [3.2 Compare Path Metadata Including Modification Time](#32-compare-path-metadata-including-modification-time)
  - [3.3 Compare JSON While Ignoring Object Key Order](#33-compare-json-while-ignoring-object-key-order)
  - [3.4 Compare Text While Ignoring Whitespace and Line Endings](#34-compare-text-while-ignoring-whitespace-and-line-endings)
  - [4. Convenience Forms](#4-convenience-forms)
</details>

<details>
<summary>1. Return Conventions</summary>

## 1. Return Conventions
</details>

<details>
<summary>1.1 Return Styles</summary>

### 1.1 Return Styles

LiteTest test helpers use three return styles:

- Structured helpers return `LT_OK`, `LT_MISMATCH`, `LT_TIMEOUT`, or an `LT_E*` error code.
- Predicate helpers return `1` for true or match, `0` for false or no match, and `-1` on invalid input or runtime error.
- Process helpers that model command completion return `0` for success, `1` for timeout, and `-1` for invalid input or setup failure.
</details>

<details>
<summary>1.2 Assertion Guidance</summary>

### 1.2 Assertion Guidance

Use the helper family to decide what to check:

- File, JSON, metadata, and normalized-text comparisons should usually be checked against `LT_OK` or `LT_MISMATCH`.
- Existence, string, wildcard, and regex predicates should usually be checked against `1` or `0`.
- Command-execution helpers should usually be checked against `0` or `1`.
</details>

<details>
<summary>2. Comparison Option Structs</summary>

## 2. Comparison Option Structs

The comparison helpers use small option structs instead of mixed boolean and flag parameter lists.
</details>

<details>
<summary>2.1 `lt_path_compare_options_t`</summary>

### 2.1 `lt_path_compare_options_t`

Used by `lt_compare_paths_with_options`.

```c
typedef struct {
	int flags;
} lt_path_compare_options_t;
```

Supported flags:

- `LT_FILECMP_IGNORE_TRAILING_WHITESPACE`
- `LT_FILECMP_IGNORE_EMPTY_LINES`
- `LT_FILECMP_IGNORE_TIMESTAMPS`
- `LT_FILECMP_IGNORE_LINE_ENDINGS`
- `LT_FILECMP_CASE_INSENSITIVE`

Default initializer:

```c
#define LT_PATH_COMPARE_OPTIONS_INIT {0}
```
</details>

<details>
<summary>2.2 `lt_path_metadata_compare_options_t`</summary>

### 2.2 `lt_path_metadata_compare_options_t`

Used by `lt_compare_path_metadata`.

```c
typedef struct {
	int flags;
} lt_path_metadata_compare_options_t;
```

Supported flags:

- `LT_STATCMP_SIZE`
- `LT_STATCMP_PERMS`
- `LT_STATCMP_MTIME`
- `LT_STATCMP_OWNER`
- `LT_STATCMP_TYPE`

Default initializer:

```c
#define LT_PATH_METADATA_COMPARE_OPTIONS_INIT {0}
```

Passing `NULL` or the default initializer uses the common default metadata set: size, permissions, and type.
</details>

<details>
<summary>2.3 `lt_json_compare_options_t`</summary>

### 2.3 `lt_json_compare_options_t`

Used by `lt_compare_json_with_limit`.

```c
typedef struct {
	size_t max_bytes;
	int ignore_key_order;
} lt_json_compare_options_t;
```

Default initializer:

```c
#define LT_JSON_COMPARE_OPTIONS_INIT {0, 0}
```

Use `ignore_key_order` when semantic JSON equality matters more than source ordering. Use `max_bytes` when the caller wants a tighter bound than the implementation default.
</details>

<details>
<summary>2.4 `lt_text_compare_options_t`</summary>

### 2.4 `lt_text_compare_options_t`

Used by `lt_compare_text_normalized`.

```c
typedef struct {
	int ignore_whitespace;
	int ignore_line_endings;
} lt_text_compare_options_t;
```

Default initializer:

```c
#define LT_TEXT_COMPARE_OPTIONS_INIT {0, 0}
```
</details>

<details>
<summary>3. Common Usage Patterns</summary>

## 3. Common Usage Patterns
</details>

<details>
<summary>3.1 Compare Two Paths While Ignoring Timestamps</summary>

### 3.1 Compare Two Paths While Ignoring Timestamps

```c
const lt_path_compare_options_t options = {
	LT_FILECMP_IGNORE_TIMESTAMPS
};

LT_ASSERT(lt_compare_paths_with_options(expected_path, actual_path, &options) == LT_OK, 0);
```
</details>

<details>
<summary>3.2 Compare Path Metadata Including Modification Time</summary>

### 3.2 Compare Path Metadata Including Modification Time

```c
const lt_path_metadata_compare_options_t options = {
	LT_STATCMP_SIZE | LT_STATCMP_PERMS | LT_STATCMP_TYPE | LT_STATCMP_MTIME
};

LT_ASSERT(lt_compare_path_metadata(left_path, right_path, &options) == LT_OK, 0);
```
</details>

<details>
<summary>3.3 Compare JSON While Ignoring Object Key Order</summary>

### 3.3 Compare JSON While Ignoring Object Key Order

```c
const lt_json_compare_options_t options = {
	0,
	1
};

LT_ASSERT(lt_compare_json_with_limit(expected_json, actual_json, &options) == LT_OK, 0);
```
</details>

<details>
<summary>3.4 Compare Text While Ignoring Whitespace and Line Endings</summary>

### 3.4 Compare Text While Ignoring Whitespace and Line Endings

```c
const lt_text_compare_options_t options = {
	1,
	1
};

LT_ASSERT(lt_compare_text_normalized(left_text, right_text, &options) == LT_OK, 0);
```
</details>

<details>
<summary>4. Convenience Forms</summary>

## 4. Convenience Forms

- `lt_compare_paths` performs a byte-for-byte path comparison.
- `lt_compare_json` performs a strict JSON comparison using default limits.
- `lt_compare_file_lines` compares files line-by-line and returns `LT_OK` or
  `LT_MISMATCH`.

For the full declaration list and per-function comments, see `include/litetest_test.h`.
</details>
