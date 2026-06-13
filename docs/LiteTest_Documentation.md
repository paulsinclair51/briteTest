o# LiteTest Documentation

This document lists LiteTest documents,
`Click to view` chapter, sections, and subsections:

<details>
<summary>Click to view Why Click to view?</summary>

- Keeps documents readable while still accommodating large amounts
  of technical detail.
  
- Collapsing sections allows scanning the structure and expand only
  what you need.
  
- This keeps the document manageable, avoids overwhelming a reader
  with unrelated detail, and makes the document easier to navigate.
</details>

Copyright (c) 2026 Paul Sinclair.  
SPDX-License-Identifier: MIT.

<details>
<summary>Click to view license</summary>

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

#### Document Version History

<details>
<summary>Click to view</summary>

| Document | Date       | LiteTest | Description                                   | Author/Editor      |
|----------|------------|----------------------------------------------------------|--------------------|
| 1.0      | 2026‑06‑11 | 1.0.0    | Initial version.                              | Paul Sinclair      |

The **Document** column tracks the version `M.u` (Major, update) of this LiteTesf
document. The **LiteTest** column records the latest LiteTest version
at the time this document version was published.

The current LiteTest version is defined by the LiteTest Runner API `LT_VERSION` macro,
which specifies a string of the form `"M.m.p"` (Major, minor, patch).

The document’s **Major** version matches the LiteTest Runner's Major version.
The **update** version tracks updates to this document itself and does not
correspond to the LiteTest Runner's minor or patch versions. The update version
is incremented whenever this document is updated without a change to the major 
version, and it resets to `0` when the major version is incremented.
</details>

## Documentation

<details>
<summary>Click to view</summary>

The user documentation for  LiteTest includes:

- **README** — Introduction to LiteTest.

- **LiteTest Documentation** — A list of the LifeTest documents for users and contributors plus the LiteTest repository layout (listing core files).

- **LiteTest Glossary — An alphabetically-ordered list of terms used in the LiteTest documentation with their specific definitions/explanations in the LiteTest context.

- **LiteTest Runner User Guide** — Concepts, usage, and examples for the LiteTest Runner framework and API.

- **LiteTest Runner Reference** — Reference document for the LiteTest Runner API.

- **LiteTest Test User Guide** — Concepts, usage, and examples for the LiteTest Test API.

- **LiteTest Test Reference** — Reference document for the LiteTest Test API .

The contributor documentation for the LiteTest implementation internals for the Runner API and
the Test API include:

- **LiteTest Contributor Guide** — Versioning, documentation/coding guidelines, branching, testing, and CI/release check lists.

- **LiteTest Runner Internal Guide** — Implementation concepts, architecture, and high-level design for the Runner API.

- **LiteTest Runner Internal Reference** — Reference for the implementation of the Test API.
  
- **LiteTest Test Internal Guide** — Implementation concepts, architecture, and high-level design for the Test API.

- **LiteTest Test Internal Reference** — Reference for the implementation of the Test API.
</details>

## Repository Layout

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
|  |- LiteTest_Documentation.md
|  |- LiteTest_Glossary.md
|  |- LiteTest_Repository_Layout.md 
|  |- LiteTest_Runner_User_Guide.md
|  |- LiteTest_Runner_Reference.md
|  |- LiteTest_Contributor_Guide.md
|  \- LiteTest_Runner_Internal_Guide.md
|  \- LiteTest_Runner_Internal_Reference.md
|  \- LiteTest_Test_Internal_Guide.md
|  \- LiteTest_Test_Internal_Reference.md
|- examples/
|- include/
|  |- litetest_runner.h
|  \- litetest_test.h
|- reports/
|  |- litetest_test_report-I.txt
|  \- litetest_test_report.txt
|- scripts/
|- src/
|  |- litetest_runner.c
|  \- litetest_test.c
|- tests/
|  |- test_litetest.c
|  |- test_orchestrator.c
|  |- test_guard1.c
|  \- test_guard2.c
```
</details>
