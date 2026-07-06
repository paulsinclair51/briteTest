![Test Reference](/docs/branding/Test_Reference.png)

This document summarizes the public Test API declared in `include/testapi.h`.
It focuses on the helper-specific return conventions and the option structs used by the
comparison helpers.

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

This document is intended for users and contributors who need
a reference for the Test API.

For a list of other documents and the repository layout, see
the Documentation Guide.

For a glossary of terms, see the Glossary Reference.

A printer-friendly PDF file for this document is available.

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

1. [**Return Conventions**](#1-return-conventions)<br>
   1.1. [Return Styles](#11-return-styles)<br>
   1.2. [Assertion Guidance](#12-assertion-guidance)

2. [**Comparison Option Structs**](#2-comparison-option-structs)<br>
   2.1. [ra_path_compare_options_t](#21-ra_path_compare_optionst)<br>
   2.2. [ra_path_metadata_compare_options_t](#22-ra_path_metadata_compare_optionst)<br>
   2.3. [ra_json_compare_options_t](#23-ra_json_compare_optionst)<br>
   2.4. [ra_text_compare_options_t](#24-ra_text_compare_optionst)

3. [**Common Usage Patterns**](#3-common-usage-patterns)<br>
   3.1. [Compare Two Paths While Ignoring Timestamps](#31-compare-two-paths-while-ignoring-timestamps)<br>
   3.2. [Compare Path Metadata Including Modification Time](#32-compare-path-metadata-including-modification-time)<br>
   3.3. [Compare JSON While Ignoring Object Key Order](#33-compare-json-while-ignoring-object-key-order)<br>
   3.4. [Compare Text While Ignoring Whitespace and Line Endings](#34-compare-text-while-ignoring-whitespace-and-line-endings)

4. [**Convenience Forms**](#4-convenience-forms)
</details>

<details>
<summary><strong>1. Return Conventions</strong></summary>

## 1. Return Conventions

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;1.1. Return Styles</summary>

### 1.1. Return Styles

briteTest test helpers use three return styles:

- Structured helpers return `RA_OK`, `RA_MISMATCH`, `RA_TIMEOUT`, or an `RA_E*` error code.
- Predicate helpers return `1` for true or match, `0` for false or no match, and `-1` on invalid input or runtime error.
- Process helpers that model command completion return `0` for success, `1` for timeout, and `-1` for invalid input or setup failure.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;1.2. Assertion Guidance</summary>

### 1.2. Assertion Guidance

Use the helper family to decide what to check:

- File, JSON, metadata, and normalized-text comparisons should usually be checked against `RA_OK` or `RA_MISMATCH`.
- Existence, string, wildcard, and regex predicates should usually be checked against `1` or `0`.
- Command-execution helpers should usually be checked against `0` or `1`.
</details>
</details>

<details>
<summary><strong>2. Comparison Option Structs</strong></summary>

## 2. Comparison Option Structs

The comparison helpers use small option structs instead of mixed boolean and flag parameter lists.

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;2.1. `ra_path_compare_options_t`</summary>

### 2.1. `ra_path_compare_options_t`

Used by `ta_compare_paths_with_options`.

```c
typedef struct {
	int flags;
} ra_path_compare_options_t;
```

Supported flags:

- `RA_FILECMP_IGNORE_TRAILING_WHITESPACE`
- `RA_FILECMP_IGNORE_EMPTY_LINES`
- `RA_FILECMP_IGNORE_TIMESTAMPS`
- `RA_FILECMP_IGNORE_LINE_ENDINGS`
- `RA_FILECMP_CASE_INSENSITIVE`

Default initializer:

```c
#define RA_PATH_COMPARE_OPTIONS_INIT {0}
```
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;2.2. `ra_path_metadata_compare_options_t`</summary>

### 2.2. `ra_path_metadata_compare_options_t`

Used by `ta_compare_path_metadata`.

```c
typedef struct {
	int flags;
} ra_path_metadata_compare_options_t;
```

Supported flags:

- `RA_STATCMP_SIZE`
- `RA_STATCMP_PERMS`
- `RA_STATCMP_MTIME`
- `RA_STATCMP_OWNER`
- `RA_STATCMP_TYPE`

Default initializer:

```c
#define RA_PATH_METADATA_COMPARE_OPTIONS_INIT {0}
```

Passing `NULL` or the default initializer uses the common default metadata set: size, permissions, and type.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;2.3. `ra_json_compare_options_t`</summary>

### 2.3. `ra_json_compare_options_t`

Used by `ta_compare_json_with_limit`.

```c
typedef struct {
	size_t max_bytes;
	int ignore_key_order;
} ra_json_compare_options_t;
```

Default initializer:

```c
#define RA_JSON_COMPARE_OPTIONS_INIT {0, 0}
```

Use `ignore_key_order` when semantic JSON equality matters more than source ordering. Use `max_bytes` when the caller wants a tighter bound than the implementation default.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;2.4. `ra_text_compare_options_t`</summary>

### 2.4. `ra_text_compare_options_t`

Used by `ta_compare_text_normalized`.

```c
typedef struct {
	int ignore_whitespace;
	int ignore_line_endings;
} ra_text_compare_options_t;
```

Default initializer:

```c
#define RA_TEXT_COMPARE_OPTIONS_INIT {0, 0}
```
</details>
</details>

<details>
<summary><strong>3. Common Usage Patterns</strong></summary>

## 3. Common Usage Patterns
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.1. Compare Two Paths While Ignoring Timestamps</summary>

### 3.1. Compare Two Paths While Ignoring Timestamps

```c
const ra_path_compare_options_t options = {
	RA_FILECMP_IGNORE_TIMESTAMPS
};

RA_ASSERT(ta_compare_paths_with_options(expected_path, actual_path, &options) == RA_OK, 0);
```
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.2. Compare Path Metadata Including Modification Time</summary>

### 3.2. Compare Path Metadata Including Modification Time

```c
const ra_path_metadata_compare_options_t options = {
	RA_STATCMP_SIZE | RA_STATCMP_PERMS | RA_STATCMP_TYPE | RA_STATCMP_MTIME
};

RA_ASSERT(ta_compare_path_metadata(left_path, right_path, &options) == RA_OK, 0);
```
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.3. Compare JSON While Ignoring Object Key Order</summary>

### 3.3. Compare JSON While Ignoring Object Key Order

```c
const ra_json_compare_options_t options = {
	0,
	1
};

RA_ASSERT(ta_compare_json_with_limit(expected_json, actual_json, &options) == RA_OK, 0);
```
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.4. Compare Text While Ignoring Whitespace and Line Endings</summary>

### 3.4. Compare Text While Ignoring Whitespace and Line Endings

```c
const ra_text_compare_options_t options = {
	1,
	1
};

RA_ASSERT(ta_compare_text_normalized(left_text, right_text, &options) == RA_OK, 0);
```
</details>

<details>
<summary><strong>4. Convenience Forms</strong></summary>

## 4. Convenience Forms

- `ta_compare_paths` performs a byte-for-byte path comparison.
- `ta_compare_json` performs a strict JSON comparison using default limits.
- `ta_compare_file_lines` compares files line-by-line and returns `RA_OK` or
  `RA_MISMATCH`.

For the full declaration list and per-function comments, see `include/testapi.h`.
</details>
