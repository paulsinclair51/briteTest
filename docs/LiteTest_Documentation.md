# LiteTest Documentation

This document lists LiteTest documents. It is a companion document to
the other LiteTest documents.

`Click to view` chapter, sections, and subsections:

<details>
<summary>Click to view Why Click to view?</summary>

- Keeps documents readable while still accommodating large amounts
  of technical detail.
  
- Collapsing sections allows scanning the structure and expanding only
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
   
| Document | Date | LiteTest | Comment | Author/Editor |  
|----------|------------|----------------------------------------------------------|--------------------|  
| 1.0 | 2026‑06‑11 | 1.0.0 | Initial version. | Paul Sinclair |  

The `Document` column tracks the version `M.u` (Major, update) of this LiteTest
document. The `LiteTest` column records the latest LiteTest version
at the time this document version was published.

The current LiteTest version is defined by the `LT_VERSION` macro in the LiteTest
Runner API, which specifies a string of the form `"M.m.p"` (Major, minor, patch).

The document’s `Major` version matches the LiteTest Runner's Major version.
The `update` version tracks updates to this document itself and does not
correspond to the LiteTest Runner's minor or patch versions. The update version
is incremented whenever this document is updated without a change to the major 
version, and it resets to `0` when the major version is incremented.
</details>

## Documentation

<details>
<summary>Click to view</summary>

The user documentation for LiteTest includes:

- `README.md` — Introduction to LiteTest.

- `LiteTest_Documentation.md` — A list of the LiteTest documents for users and contributors plus the LiteTest repository layout (listing core files).

- `LiteTest_Glossary.md` — An alphabetically-ordered list of terms generally used in LiteTest (emphasizing their specific meaning in LiteTest) and terms often used in the testing domain.

- `LiteTest_Runner_User_Guide.md` — Concepts, usage, and examples for the LiteTest Runner framework and API.

- `LiteTest_Runner_Reference.md` — Reference document for the LiteTest Runner API.

- `LiteTest_Test_User_Guide.md` — Concepts, usage, and examples for the LiteTest Test API.

- `LiteTest_Test_Reference.md` — Reference document for the LiteTest Test API.

The contributor documentation for the LiteTest implementation internals for the Runner API and
the Test API include:

- `LiteTest_Contributor_Guide.md` — Versioning, documentation/coding guidelines, branching, testing, and CI/release check lists.

- `LiteTest_Runner_Internal_Guide.md` — Implementation concepts, architecture, and high-level design for the Runner API.

- `LiteTest_Runner_Internal_Reference.md` — Reference for the implementation of the Runner API.
  
- `LiteTest_Test_Internal_Guide.md` — Implementation concepts, architecture, and high-level design for the Test API.

- `LiteTest_Test_Internal_Reference.md` — Reference for the implementation of the Test API.
</details>

## LiteTest Repository Layout

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
