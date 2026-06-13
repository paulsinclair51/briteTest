# LiteTest Documentation

This document lists LiteTest documents,
`Click to view` chapter, sections, and subsections:

<details>
<summary>Click to view</summary>

- Keeps documents readable while still accommodating large amounts
  of technical detail.
  
- Collapsing sections allows scanning the structure and expand only
  what you need.
  
- This keeps the document manageable, avoids overwhelming a reader
  with unrelated detail, and makes the document easier to navigate.
</details>

Copyright (c) 2026 paulsinclair.  
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

## Preface

<details>
<summary>Click to view</summary>

#### Document Version History

<details>
<summary>Click to view</summary>

| Document | Date       | LiteTest | Description                                   | Author/Editor    |
|----------|------------|----------------------------------------------------------|------------------|
| 1.0      | 2026‑06‑11 | 1.0.0    | Initial LiteTest Framework Reference.         | Paul Sinclair   |

The **Document** column tracks the version `M.u` (major, update) of this LiteTesf
Documentation document. The **LiteTest** column records the latest LiteTest version
at the time this document version was published.

The current LiteTest version is defined in `litetest.h` by the macro `LT_VERSION`,
which specifies a string of the form `"M.m.p"` (major, minor, patch).
`litetest.c` defines a matching version string `LT_VERSION_C`. For details, see
the public API and framework documentation.

The document’s major version must match the LiteTest
major version. The **update** version tracks updates to this document itself and
does not correspond to LiteTest minor or patch versions. The update version is
incremented whenever this document is updated without a change to the major version,
and it resets to `0` when the major version increases.
</details>

### Documentation

<details>
<summary>Click to view</summary>

The user documentation for the LiteTest includes:

- **README** — Introduction to LiteTest.

- **LiteTest Documentation** — A list of the LifeTezt documents.

- **LiteTest Glossary — An alphabetically-ordered list of LiteTest terms and their
  definitions/explanations.

- ** LiteTest Repository Layout —

- **LiteTest Runner User Guide** — Concepts, workflow, and examples for the
  Runner framework and API.

- **LiteTest Runner Reference** — Reference document for the Runne API.

- **LiteTest Test User Guide** — Concepts, workflow, examples for the Test API.

- **LiteTest Test Reference** — Reference document for the Test API .

The contributor documentation for the LiteTest internals for the Runner API and
the Test API include:

- **LiteTest Contributor Guide** — Versioning, documentation/coding
  guidelines, branching, testing, and CI/release check lists.

- **LiteTest Runner Internal Guide** — Concepts, workflow, examples for the Runner API.

- **LiteTest Runner Internal Reference** — Reference for the implementation for the
  Test API.
  
- **LiteTest Test Internal Guide** — Concepts, workflow, examples for the Test API.

- **LiteTest Test Internal Reference** — Reference for the implementation for the
  Test API.
</details>

### Repository Layout

<details>
<summary>Click to view</summary>
  
GitHub repository: `paulsinclair51/LiteTest`

Repository layout (listing core files):

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
</details>
</details>
<
