![Documentation Guide](branding/Documentation_Guide.png)

This document is a guide to the BriteTest documentation and
repository layout.

#### Copyright (c) 2026 Paul Sinclair

<details>
<summary>License</summary>

#### **License**

SPDX-License-Identifier: MIT

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
</details>

<details>
<summary>Preface</summary>

## Preface

This document is for users and contributors who need
a guide to the documentation and repository layout.

A printer-friendly PDF file for this document is available in `docs/pdf/`.

<details>
<summary>Document Version History</summary>
 
### Document Version History

| Document | Runner | Test | Date | Comment | Author/Editor |
|----------|------|--------|------|---------|---------------|
| 1.0 | 1.0.0 | 1.0.0 | 2026‑06‑11 | Initial version. | Paul Sinclair |

- The **Document** column records the document's version with the
  format `M.u` (Major, update).
- The **Runner** column records the Runner API version
  current when this document was released and is
  defined by its `RA_VERSION` macro.
- The **Test** column records the Test API version current
  when this document was released and is defined by its
  `TA_VERSION` macro.
- Both the Runner and Test API use the version format `"M.m.p"` (Major, minor,
  patch).
- `M` is the same for the Document, Runner, and Test versions.

The document's update version tracks released updates to this document and does
not correspond to a minor or patch version. `u` increments when document
changes are released without a change to `M`, and it resets to
`0` when `M` is incremented.
</details>
</details>

<details>
<summary>Table of Contents</summary>

## Table of Contents

1. [Introduction](#1-introduction)

2. [Documents](#2-documents)

3. [Repository Layout](#3-repository-layout)
</details>

<details>
<summary>1. Introduction</summary>

## 1. Introduction

The  documentation consists of documents for:

- **Users**: Public-facing framework and API documents.

- **Contributors**; Guide and API internal documents.

Document types:

- **README**: Introduction or description.

- **Guide**: Usage information.

- **Reference**: Reference companion to a guide.

Document formats:

- **.md**: Markdown documentation format for online viewing.

- **.pdf**: Portable Document Format for printing. A BriteTest .pdf file is generated
  from a BriteTest .md file using genpdf in the scripts directory of the repository
  root.
</details>

<details>
<summary>2. Documents</summary>

## 2. Documents

The following are the user and contributor documents.

**User documentation**:

- **README.md** — Introduction to BriteTest.

- **Documentation_Guide.md**: A guide to documents and the
  repository layout.

- **Glossary_Reference.md**: An alphabetically ordered list of terms
  generally used in the documentation (emphasizing their specific meaning in
  BriteTest) and terms often used in the testing domain.

- **Runner_Guide.md**: Concepts, usage, and examples for
  the Runner Framework and API.

- **Runner_Reference.md**: Reference document for the
  Runner API.

- **Test_Guide.md**: Concepts, usage, and examples for
  the Test API.

- **Test_Reference.md**: Reference document for the Test API.

**Contributor documentation**:

- **README.md**: Directory description, one for each subdirectory.

- **Contributor_Guide.md**: Versioning, documentation/coding
  guidelines, branching, testing, and CI/release checklists.

- **Runner_Internal_Guide.md**: Implementation concepts,
  architecture, and high-level design for the Runner API.

- **Runner_Internal_Reference.md**: Reference for the
  implementation of the Runner API.

- **Test_Internal_Guide.md**: Implementation concepts,
  architecture, and high-level design for the Test API.

- **Test_Internal_Reference.md**: Reference for the
  implementation of the Test API.
</details>

<details>
<summary>3. Repository Layout</summary>

## 3. Repository Layout

The following shows the layout of the GitHub repository
(core files and directories):

```text
.github/workflows/ci.yml
README.md
LICENSE
.gitignore
Makefile
build_test_runner.ps1
build/                  # Build outputs and related artifacts.
config/                 # Repository configuration files.
    markdownlint.json
docs/                   # User and contributor documentation.
    *.md
    pdf/                # Generated `*.pdf` files.
    docx/               # Generated `*.docx` files.
examples/               # Usage examples.
include/                # Public API `.h` headers.
    runnerapi.h
    testapi.h
reports/                # Generated report files.
scripts/                # Automation scripts.
    check_directory_readmes.sh
    genpdf
    test_genpdf.sh
src/                    # API `.c` sources.
    runnerapi.c
    testapi.c
tests/                  # Testing assets.
    golden/             # Golden/baseline files for comparison.
    include/            # Test `.h` headers.
    input/              # Test input files.
    output/             # Captured test outputs to compare against golden/.
    src/                # Test `.c` source files.
    tmp/                # Temporary test outputs.
```
</details>
