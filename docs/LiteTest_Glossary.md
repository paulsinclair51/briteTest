# LiteTest Glossary

This glossry defines terms generally used in LiteTest and terms often used in
the testing domain. It is companion document to the other LiteTest documents.

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
| 1.0      | 2026‑06‑11 | 1.0.0    | Initial LiteTest Framework Reference.         | paulsinclair51   |

The **Document** column tracks the version `M.u` (major, update) of this Glossary
document. The **LiteTest** column records the latest LiteTest version
at the time this document version was published.

The current LiteTest version is defined in `litetest.h` by the macro `LT_VERSION`,
which specifies a string of the form `"M.m.p"` (major, minor, patch).
`litetest.c` defines a matching version string `LT_VERSION_C`. For details, see
the public API and framework documentation.

A **major LiteTest release requires a corresponding major update to this
document** and therefore the document’s major version must match the LiteTest
major version. The **update** version tracks updates to this document itself and
does not correspond to LiteTest minor or patch versions. The update version is
incremented whenever this document is updated without a change to the major version,
and it resets to `0` when the major version increases.
</details>

#### Documentation

<details>
<summary>Click to view</summary>

The user documentation for the LiteTest includes:

- **README** — Introduction to LiteTest.

- **LiteTest Runner User Guide** — Concepts, workflow, examples for the
  Runner framework and API.

- **LiteTest Runner Reference** — Reference document for the Runner API.

- **LiteTest Test User Guide** — Concepts, workflow, examples for the Test API.

- **LiteTest Test Reference** — Reference document for the runner API .

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

#### Repository Layout

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

## Glossary

<details>
<summary>Click to view</summary>

Terms generally used in LiteTest (emphazing their specific meaning in LiteTest)
and terms often used in the testing domain:

<details>
<summary>A: Click to viewA</summary>

- `API`: Application Programming Interface: public typedefs, structs, enum,
  macro, and functions that provide a well-defined service. For example,
  the LiteTest Runner API and the LiteTest Test API.
- `artifact`: A file or bundle of files produced by a workflow run and
  stored by GitHub Actions for later download or use. Artifacts typically
  include build outputs, test reports, logs, binaries, coverage data, or
  any files a workflow chooses to upload
</details>

<details>
<summary>C: Click to view </summary>

- `command-line' - A input line to a shell that specifies an executable with
  optional or required arguments and flags.
- `category`: A labeled set of `LT_GROUP` and `LT_TEST` macros whose combined
  results are written by `LT_WRITE_RESULT` to the report with a specified
  category name.
- `Concurrent block`: A set of tests bracketed by `LT_BEGIN_CONCURRENT` and
  `LT_END_CONCURRENT`.
- `control file`: A previously generated file that can be compared to a newly
  generated file for differences. Differences (other than expected ones like
  timestamps) typically indicate a test failure. Sometimes the control file is
  out of date and must be replaced by promoting the new file.
- `customization support functions`: Runner API functions provided to support
  customizing the orchestrator and test group functions.
</details>

<details>
<summary>D: Click to view</summary>

- `default report filename`: The report filename LiteTest uses when only a
  directory path (or no `PATH`) is provided.
</details>

<details>
<summary>E: Click to view</summary>

- `executable`: The compiled test program that includes the orchestrator (main)
  function, group  functions, test expression implementations, the LiteTest
  Runner API implementation, and the LiteTest Test API implementation. An
  executable is executed using a command-line input to a shell.
</details>

<details>
<summary>F: Click to view</summary>

- `fail`: A counted test failure where the `LT_TEST` or `LT_INJECT_TEST`
  expression evaluates to zero.
- `fault`: A counted runtime fault captured by LiteTest guards (e.g., invalid
  memory access).
</details>

<details>
<summary>G: Click to view</summary>

- `group`: See `test group`.
- `guard`: The protection mechanism used to catch runtime faults and continue
  test execution.
- `guard level`: The nesting depth of active guards for test groups and tests
  expressions.
</details>

<details>
<summary>I: Click to view</summary>

- `include (-I)` flag: Optional command‑line flag that enables an
  `LT_TEST` with an argument value of `I` to be executed. Default is
  skip `LT_TEST` if it has argument value of `I`.
- `include (-I<n>)` flag: Optional command‑line flag that enables an
  `LT_TEST` with an argument value of `<m>` between 1 and 9 to execute
  if <m> is between 1 and `<n>`. `<n>` must be between 1 and 9.
  Default for `<n>` is 9 if this flag is not specified and, for `<m>`
  is 1. If `<m>` is 0, `LT_TEST` is not enabled (i.e., it is skipped).
  At most one -`-I<n>` flas specified for command-line.
- `isolation`: Execution mode for `LT_GROUP`, `LT_TEST`, or `LT_INJECT_TEST`.
  `0` = same thread, `1` = separate thread, `2` = separate process.
</details>

<details>
<summary>M: Click to view</summary>

- `maxargs`: Maximum number of command‑line arguments accepted by orchestrator
  parsing. `LT_PARSE_ARGS` handles the first two arguments; additional arguments
  must be parsed by custom code.
- `maxparallel`: Upper bound on concurrent `LT_GROUP`, `LT_TEST`,
  `LT_INJECT_TEST`. Set in `LT_INIT_ORCHESTRATOR` and `LT_GROUP`.
- `notes`: Optional text appended to the report by `LT_CLOSE_REPORT`.
- `orchestrator`: The `main` function that initializes LiteTest, runs groups or
  tests, and writes report output.
</details>

<details>
<summary>P: Click to view</summary>

- `pass`: A counted successful test where the expression evaluates to non‑zero.
- `PATH`: Optional command‑line output destination; may be a report file path or
  directory path.
- `process isolation`: Isolation mode where a test group or test runs in a
  separate process.
- `project`: Project identifier used in orchestrator initialization and default
  report naming.
</details>

<details>
<summary>R: Click to view</summary>

- `Report Format`: The output structure produced by LiteTest test runs.
</details>

<details>
<summary>S: Click to view</summary>

- `semantic versioning`: A versioning scheme for artifacts. For example,
   in LiteTest, `M.m.p` (for `.h` and `.c` files) or `M.u` (document
  `.md` files) where M, m, p, and u are one or two digits and M
  indicates the major release, m indicates the minor release, p
  indicates the patch version, and u the document update version.
- `shell`: a command-line interface that allows a user or script to submit
  command lines. Examples inlude PowerShell (`pwsh` or `powershell.exe`),
  bash, sh, and cmd.ext).
</details>
  

<details>
<summary>T: Click to view</summary>

- `test group`: A grouping of `LT_TEST` and optionally nested `LT_GROUP` macros.
- `test group function`: A function declared with `LT_DECLARE_GROUP` that
  contains `LT_TEST` and `LT_GROUP` macros.
- `thread isolation`: Isolation mode where a test/assert call runs in a
  separate thread.
- `test case`: Not used in LiteTest. In other contexts, it may mean a single
  test or a set of tests; LiteTest uses `test expression` for an individual
  test and `test group` for a set of test expressions.
- `test`: See `test expression`.
- `test expression`: An expression passed to an `LT_TEST` macro that can be cast
  to `int`; zero means fail, non‑zero means pass. A test expression and its
  underlying functions are user written. The LiteTest Test API is provided to
  help simplify writing these text expressions and functions.
- `testing artifact`: A file or output generated by the test executable (e.g.,
  test report, stdout, stderr).
- `testing function`: A user‑written function used in implementing a
  test expression.
- `test helper function`: A LiteTest Test API function provided to simplify
  writing the implementation for a test texpressions.
- `title`: Optional report header text provided when opening the report.
</details>
</details>
