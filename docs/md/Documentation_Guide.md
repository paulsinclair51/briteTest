![Documentation Guide](../branding/Documentation_Guide.png)

This document is a guide to the briteTest documentation and
repository layout.

#### Copyright (c) 2026 Paul Sinclair

<details>
<summary><strong>License</strong></summary>

### License

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
<summary><strong>Preface</strong></summary>

## Preface

This document is for users and contributors who need
a guide to the documentation and repository layout.

A printer-friendly PDF file for this document is available in `docs/pdf/`.

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;Document Version History</summary>
 
### Document Version History

| Document | Runner | Test | Date | Comment | Author/Editor |
|----------|------|--------|------|---------|---------------|
| 1.0.0 | 1.0.0 | 1.0.0 | 2026-06-11 | Initial version. | Paul Sinclair |

- The **Document** column records the document's version.
- The **Runner** column records the Runner API version
  current at the time this version of the document was published.
- The **Test** column records the Test API version current at
  the time this version of the document was published.

A version has the format `M.m.p` (Major, minor, patch) where `M` is the
major version, `m` is the minor version, and `p` is the patch version.
`p` increments when the document is updated without a change to `M` or `m`,
and resets to 0 when `M` or `m` increases. The first table entry is the most
recent version for this document at the time this document was published.
</details><br>
</details>

<details>
<summary><strong>Table of Contents</strong></summary>

## Table of Contents

1. [Introduction](#1-introduction)

2. [Documents](#2-documents)

3. [Repository Layout](#3-repository-layout)
</details>

<details>
<summary><strong>1. Introduction</strong></summary>

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

- **.pdf**: Portable Document Format for printing. A briteTest .pdf file is generated
  from a briteTest .md file using genpdf in the scripts directory of the repository
  root.
</details>

<details>
<summary><strong>2. Documents</strong></summary>

## 2. Documents

The following are the user and contributor documents.

**User documentation**:

- **README.md** -- Introduction to briteTest.

- **Documentation_Guide.md**: A guide to documents and the
  repository layout.

- **Glossary_Reference.md**: An alphabetically ordered list of terms
  generally used in the documentation (emphasizing their specific meaning in
  briteTest) and terms often used in the testing domain.

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
<summary><strong>3. Repository Layout</strong></summary>

## 3. Repository Layout

The following shows the layout of the GitHub repository
(core files and directories):

```text
.github/workflows/ci.yml
.vscode/
.gitignore
build_test_runner.ps1
LICENSE
Makefile
README.md
build/                  # Build outputs and related artifacts.
config/                 # Repository configuration files.
    contributors.md     # List of authorized contributors.
    markdownlint.json   # Customize lint behavior.
docs/                   # User and contributor documentation.
    branding/           # Monograms, logos, and document logos.
    md/                 # `*.md` files (base documentation).
    pdf/                # `*.pdf` files generated from `*.md` files.
    docx/               # `*.docx` files generated from `*.pdf` files.
examples/               # Usage examples.
include/                # Public API `.h` headers.
    runnerapi.h         # Declare Runner API
    testapi.h           # Declare Test API
reports/                # Generated report files.
scripts/                # Automation script assets.
    bin/                # Scripts (e.g., gendocs, mkbranch).
    helpers/            # Helper scripts for bin/scripts/*.
    tests/              # Test scripts for testing bin/scripts.
src/                    # API `.c` sources.
    runnerapi.c         # Definition of Runner API.
    testapi.c           # Definition of Test API.
tests/                  # Testing assets.
    golden/             # Golden/baseline files for comparison.
    include/            # Test `.h` headers.
    input/              # Test input files.
    output/             # Captured test outputs to compare against golden/.
    src/                # Test `.c` source files.
    tmp/                # Temporary test outputs.
```
</details>
