# LiteTest Contributor Guide

This document defines the contribution process, coding standards, documentation
rules, and versioning guidelines for LiteTest. It is intended for contributors
and maintainers working on the LiteTest framework, tools, and documentation.

Copyright (c) 2026 paulsinclair51.  
SPDX-License-Identifier: MIT.

<details>
<summary>Click to view</summary>

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

### Document Version History

<details>
<summary>Click to view</summary>

| Document | Date       | Description                          | Author/Editor  |
|----------|------------|--------------------------------------|----------------|
| 1.0      | 2026‑06‑11 | Initial LiteTest Contributor Guide.  | paulsinclair51 |

The **Document** column tracks the version `M.u` (major, update) of this
Contributor Guide. Unlike the Framework Reference, this document’s major version
does **not** need to match the LiteTest major version.

The **update** version tracks updates to this document itself and does not
correspond to LiteTest minor or patch versions. The update version is
incremented whenever this document is updated without a change to the major
version, and it resets to `0` when the major version increases.

</details>

### Documentation Style Guide

<details>
<summary>Click to view</summary>

## 1. Tone
- Technical, precise, and neutral.
- No marketing language.
- Prefer clarity over cleverness.

## 2. Formatting
- Use backticks for code identifiers.
- Use fenced code blocks for file trees, examples, and commands.
- Keep line lengths reasonable for GitHub rendering.

## 3. Writing Guidelines
- Define terms once, and then use them consistently.
- Avoid synonyms for technical concepts (e.g., always “update version,” never “revision”).
- Keep paragraphs short.
- Use lists for enumerations.

## 4. `Click to view`
- Use `Click to view` sections and subsections to keep the document readable while
  still accommodating large amounts of technical detail:
  - Collapsing sections allows readers to scan the structure and expand only what
    they need.
  - This keeps the document manageable, avoids overwhelming readers with unrelated
    detail, and makes the document easier to navigate.

## 5. Writing Style Consistency
To keep LiteTest documentation clear and easy to read, maintain **parallel
structure** within lists and related sentences. In practice:

- Start list items with the same part of speech (typically a verb).
- Keep grammatical patterns consistent across bullets.
- Avoid mixing styles such as “Keep paragraphs short” with “Using lists for enumerations.”
- Rewrite items as needed so the list reads smoothly and uniformly.

This guideline applies to all LiteTest documentation, including the User Guide,
API Reference, Framework Guide, and Framework Reference.
</details>

## Table of Contents

<details>
<summary>Click to view</summary>

- [**1. Overview**](#1-overview)
- [**2. Versioning Rules**](#2-versioning-rules)
- [**3. Testing Requirements**](#3-testing-requirements)
- [**4. Documentation Rules**](#4-documentation-rules)
- [**5. Code Style**](#5-code-style)
- [**6. Writing Style Consistency**](#6-writing-style-consistency)
- [**7. Pull Requests**](#7-pull-requests)
- [**Repository Layout**](#repository-layout)
- [**Glossary**](#glossary)

</details>

## 1. Overview

<details>
<summary>Click to view</summary>

This Contributor Guide defines the expectations and rules for contributing to
LiteTest. It covers versioning, testing, documentation, code style, and pull
request requirements.

Contributors should read this document before submitting changes to ensure
consistency across the LiteTest codebase and documentation.
</details>

## 2. Versioning Rules

<details>
<summary>Click to view</summary>

LiteTest uses semantic versioning: `M.m.p` (major, minor, patch).

### Patch
- Bug fixes or implementation improvements.

### Minor
- Additive changes to the public API.
- New behavior must be opt‑in.
- No breaking changes.

### Major
- Breaking changes to public APIs.
- Removal of deprecated features.
- Significant behavior changes.

### When updating the version:
- Update `LT_VERSION` in `litetest.h`.
- Update `LT_VERSION_C` in `litetest.c`.

### API compatibility rules:
- Public APIs are additive by default.
- Do not change existing signatures.
- Do not change return code meanings.
- Deprecate before removing.
- Provide migration guidance for major changes.
</details>

## 3. Testing Requirements

<details>
<summary>Click to view</summary>

- Build and run tests from the repository root:

```sh
make run
```

- Ensure report formatting changes are reflected in documentation examples.
- Keep test code aligned with the current version of `litetest.h`.
</details>

## 4. Documentation Rules

<details>
<summary>Click to view</summary>

- `README.md` must remain short and onboarding‑focused.
- The User Guide contains conceptual explanations and examples.
- The API Reference contains public API definitions only.
- Framework documentation (internal) must not leak into public docs.
- Update documentation when modifying macros, behavior, or report format.
</details>

## 5. Code Style

<details>
<summary>Click to view</summary>

- C99.
- POSIX.1‑2001 APIs only.
- Keep `litetest.h` self‑contained.
- Keep `litetest.c` implementation‑only.
- Avoid intermixing test code with helper logic inside test group functions.
</details>

## 6. Writing Style Consistency

<details>
<summary>Click to view</summary>

(See the full style rules in the Documentation Style Guide above.)

This section exists here to ensure contributors do not overlook the requirement
for parallel structure and consistent writing patterns across all LiteTest
documentation.
</details>

## 7. Pull Requests

<details>
<summary>Click to view</summary>

Before submitting a PR:

- Ensure tests pass.
- Update version numbers if needed.
- Update documentation as needed.
- Keep changes focused and well‑scoped.
</details>

## Repository Layout

<details>
<summary>Click to view</summary>

(Identical to the Framework Reference for consistency.)

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
|  \- litetest.h
|- reports/
|  |- litetest_test_report-I.txt
|  \- litetest_test_report.txt
|- scripts/
|- src/
|  \- litetest.c
|- tests/
|  |- test_litetest.c
|  |- test_orchestrator.c
|  |- test_guard1.c
|  \- test_guard2.c
```
</details>

## Glossary

<details>
<summary>Click to view</summary>

- **Contributor**: Anyone submitting code, documentation, or fixes to LiteTest.
- **Public API**: Functions, macros, and types intended for external use.
- **Internal API**: Framework‑only symbols not intended for external use.
- **Semantic Versioning**: Versioning scheme using `M.m.p`.
- **Test Group**: A function declared with `LT_DECLARE_GROUP`.
- **Test Expression**: Expression passed to `LT_TEST`.
- **Report Format**: The output structure produced by LiteTest test runs.
</details>
