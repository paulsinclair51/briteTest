# LiteTest Glossary Reference

This glossary defines generally used terms in the LiteTest documentation 
and terms often used in the testing domain. It is a companion document to the
LiteTest Documentation Guide.

<details>
<summary>`Click to view` sections are used throughout this document</summary>

#### Why Click to view?

- Keeps documents readable while accommodating large amounts of
  technical detail.

- Allows scanning the structure and expanding only what you need.

- Reduces visual noise and makes navigation easier.
</details>

### Copyright (c) 2026 Paul Sinclair

<details>
<summary>Click to view License</summary>

## License

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

## Preface

<details>
<summary>Click to view</summary>

This document is intended for LiteTest users and contributors who need
quick access to the definitions of terms used in LiteTest or to browse
through the terms.

<details>
<summary>Click to view Document Version History</summary>

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

The document's update version tracks updates to this document and does
not correspond to a minor or patch version. `u` increments whenever
this document is updated without a change to `M`, and it resets to `0`
when `M` is incremented.
</details>

<details>
<summary>Click to view Documentation</summary>

### Documentation

This section lists all LiteTest user and contributor documentation.

**User documentation**:

- **README.md** — Introduction to LiteTest.

- **LiteTest_Documentation_Guide.md**: Guide to the LiteTest documents and
  repository layout.

- **LiteTest_Glossary_Reference.md**: An alphabetically ordered list of terms
  generally used in LiteTest (emphasizing their specific meaning in
  LiteTest) and terms often used in the testing domain.

- **LiteTest_Runner_User_Guide.md**: Concepts, usage, and examples for
  the LiteTest Runner framework and API.

- **LiteTest_Runner_Reference.md**: Reference document for the
  LiteTest Runner API.

- **LiteTest_Test_User_Guide.md**: Concepts, usage, and examples for
  the LiteTest Test API.

- **LiteTest_Test_Reference.md**: Reference document for the LiteTest
  Test API.

**Contributor documentation**:

- **LiteTest_Contributor_Guide.md**: Versioning, documentation/coding
  guidelines, branching, testing, and CI/release checklists.

- **LiteTest_Runner_Internal_Guide.md**: Implementation concepts,
  architecture, and high-level design for the Runner API.

- **LiteTest_Runner_Internal_Reference.md**: Reference for the
  implementation of the Runner API.

- **LiteTest_Test_Internal_Guide.md**: Implementation concepts,
  architecture, and high-level design for the Test API.

- **LiteTest_Test_Internal_Reference.md**: Reference for the
  implementation of the Test API.
</details>

<details>
<summary>Click to view LiteTest Repository Layout</summary>

### LiteTest Repository Layout

This section shows the layout of the GitHub repository
`paulsinclair51/LiteTest` (core files and directories):

```text
.github/workflows/ci.yml
README.md
LICENSE
.gitignore
Makefile
build_test_litetest.ps1
build/                  # Build outputs and related artifacts.
docs/                   # User and contributor documentation.
    LiteTest_Documentation_Guide.md
    LiteTest_Glossary_Reference.md
    LiteTest_Runner_User_Guide.md
    LiteTest_Runner_Reference.md
    LiteTest_Contributor_Guide.md
    LiteTest_Runner_Internal_Guide.md
    LiteTest_Runner_Internal_Reference.md
    LiteTest_Test_Internal_Guide.md
    LiteTest_Test_Internal_Reference.md
examples/               # Usage examples.
include/                # Public API headers.
    litetest_runner.h
    litetest_test.h
reports/                # Generated report files (non-source).
scripts/                # Automation scripts.
    test/
src/                    # API source.
    litetest_runner.c
    litetest_test.c
tests/                  # Testing assets.
    src/                # Test source files.
        test_litetest.c
        test_orchestrator.c
        test_file_compare_helpers.c
        test_guard1.c
        test_guard2.c
    include/            # Test-only headers.
    control/            # Golden/baseline files for comparison.
    output/             # Retained test outputs needing review
                        # (e.g., copied report file to compare
                        # against control/)
                        # (mismatch/new); matched outputs
                        # removed by default (use -o to keep).
    input/              # Static test input files.
    tmp/                # Temporary test outputs; removed at run
                        # start for clean start; auto-deleted by
                        # test executable when it finishes (use -t
                        # to keep for debugging); user can
                        # manually remove as needed.
```
</details>
</details>

<details>
<summary>Table of Contents</summary>

##Table of Contents

- [1. Introduction](#1-introduction)
- [2. Glossary](#2-glossary)

</details>

## 1. Introduction

The glossary defines generally used terms in LiteTest documentation and terms
often used in the testing domain.

Note: '(LiteTest)' indicates the definition of a term that
has a specific meaning for LiteTest which may differ from the
meaning of the term in the testing domain or other contexts.

Note: For specific API macros and functions not included in the glossary, refer
to the LiteTest Runner or Test API Reference document for information.
u
x
## 2. Glossary

<details>
<summary>Click to view</summary>

<details>
<summary>A: Click to view</summary>

- **API**: Application Programming Interface: public typedefs,
  structs, enums, macros, and functions that provide a well-defined
  service. For example, the LiteTest Runner API and the LiteTest Test
  API.
- **artifact**: A file or bundle of files produced by a GitHub Actions
  workflow and stored for later download (e.g., build outputs, logs,
  reports). See also test artifact.
</details>

<details>
<summary>B: Click to view</summary>

_No terms currently defined._
</details>

<details>
<summary>C: Click to view </summary>

- **category**: (LiteTest) A named set of `LT_GROUP` and `LT_TEST`
  macros whose combined results are written by `LT_WRITE_RESULT` to
  the report with a specified category name.
- **CD (Continuous Delivery/Deployment)**: Automated practices that
  extend CI (Continuous Integration) by packaging, releasing, or
  deploying software after it has passed all required tests.
  Continuous Delivery prepares release artifacts for manual approval,
  while Continuous Deployment automatically deploys every passing
  change to a target environment. Use continuous-delivery,
  continuous-deployment, or CI when used as an adjective.
- **CI (Continuous Integration)**: An automated practice where every
  change to a codebase is built and tested in a shared environment. A
  CI system runs workflows that compile the project, execute tests,
  validate formatting or static analysis rules, and produce artifacts
  such as logs or reports. CI helps detect errors early, ensures
  consistent build quality, and provides rapid feedback to developers.
  Use continuous-integration or CI when used as an adjective.
- **command line**: A line of text entered into a shell that specifies
  an executable and optional arguments or flags (options). Use
  command-line when used as an adjective.
- **concurrent block**: (LiteTest) A set of tests bracketed by
  `LT_BEGIN_CONCURRENT` and `LT_END_CONCURRENT` macros.
- **contributor**: (LiteTest) Any person or agent that may commit to
  LiteTest `main`. The implementation changes and documentation
  updates for a commit to `main` must conform to the LiteTest
  contribution guidelines and must have approval by a designated
  approver or agent.
- **control file**: A previously generated file that can be compared
  to a newly generated file for differences. Differences (other than
  expected ones like timestamps) typically indicate a test failure.
  Sometimes the control file is out of date and must be replaced by
  promoting the new file.
- **customization function**: (LiteTest) A Runner API function that
  can be used to help customize the orchestrator (main) function and
  test group functions.
</details>

<details>
<summary>D: Click to view</summary>

- **default report filename**: (LiteTest) The report filename used
  when only a directory path (or no `PATH`) is provided.
</details>

<details>
<summary>E: Click to view</summary>

- **executable**: A compiled/linked program, for example, one that
  contains, for LiteTest, the orchestrator, test groups, test
  expressions (and underlying functions), and the LiteTest APIs. It is
  run from a shell using a command line.
</details>

<details>
<summary>F: Click to view</summary>

- **fail**: (LiteTest) A counted failure where the test expression for
  an `LT_TEST` macro evaluates to zero.
- **fault**: (LiteTest) A counted test group or test fault (e.g.,
  invalid memory access) captured by a LiteTest guard. See also fault
  type, guard, `LT_FAULT`, and isolation.
- **fault type**: (LiteTest) The various types of faults (e.g.,
  `SIGSEGV`, `SIGBUS`, `SIGABRT`) that can occur or be injected. See
  also fault, `LT_FAULT` and `-I`.
- **framework**: (LiteTest) Guidelines, templates, APIs, tools, and
  documentation for a class of projects that simplify development
  within that class. For example, the LiteTest framework simplifies
  test development.
</details>

<details>
<summary>G: Click to view</summary>

- **group**: See test group.
- **guard**: (LiteTest) The protection mechanism used to catch faults
  and continue test execution. See also fault, fault type, isolation,
  isolation mode, thread isolation, and process isolation.
- **guard level**: (LiteTest) The nesting depth of active guards for
  test groups and test expressions.
</details>

<details>
<summary>H: Click to view</summary>

_No terms currently defined._
</details>

<details>
<summary>I: Click to view</summary>

- **`-I`**: (LiteTest) An optional command‑line flag that enables an
  `LT_TEST` macro with an argument value of `I` to be executed.
  Typically used to inject a fail or fault into a run of a test
  executable. Default is to skip the `LT_TEST` macro if it has an
  argument value of `I`. See also fault, `LT_FAIL`, and `LT_FAULT`.
- **`-I<n>`**: (LiteTest) An optional command‑line flag that enables
  an `LT_TEST` macro with an argument value of `<m>` between 1 and 9
  to execute if `<m>` is between 1 and `<n>`. `<n>` must be between 1
  and 9. Default for `<n>` is 9 if this flag is not specified and, for
  `<m>` is 1. If `<m>` is 0, the `LT_TEST` macro is not enabled (i.e.,
  it is skipped). At most one `-I<n>` flag specified for a command
  line.
- **isolation**: A mechanism that prevents failures and faults in one
  component from affecting other components of an executable or
  system.
- **isolation mode**: (LiteTest) An execution mode for `LT_GROUP` and
  `LT_TEST` macros: `0` = same thread, `1` = separate thread, `2` =
  separate process.
</details>

<details>
<summary>J: Click to view</summary>

- **job**: A unit of work within a workflow. A job runs a series of
  steps in a specified environment (such as a container or virtual
  machine). Jobs may run sequentially or in parallel, based on their
  dependencies.
</details>

<details>
<summary>K: Click to view</summary>

_No terms currently defined._
</details>

<details>
<summary>L: Click to view</summary>

- **LiteTest framework**: (LiteTest) Guidelines, templates, APIs,
  tools, and documentation for building and running LiteTest test
  executables.
- **LiteTest Runner API**: (LiteTest) An API that helps simplify
  implementing a test runner.
- **LiteTest Test API**: (LiteTest) An API that helps simplify
  implementing tests.
- **`litetest_*`**: (LiteTest) A prefix for internal names. Do not
  define, declare or use names with this prefix.
- **`LITETEST_*`**: (LiteTest) A prefix for internal names. Do not
  define, declare or use names with this prefix.
- **`lt_*`**: (LiteTest) Prefix for LiteTest Runner and Test API
  functions, typedefs, structs, and variable names. See LiteTest
  Runner API Reference and LiteTest Test API Reference.
- **`LT_*`**: (LiteTest) Prefix for LiteTest Runner and Test API
  macros and enum values. See LiteTest Runner API Reference and
  LiteTest Test API Reference.
- **`LT_GROUP`**: (LiteTest) A Runner API macro that executes a test
  group function with a given isolation mode, maxparallel, and other
  parameters. See LiteTest Runner API Reference.
- **`LT_TEST`**: (LiteTest) A Runner API macro that executes a test
  expression with a given isolation mode and other parameters. See
  LiteTest Runner API Reference.
- **`LT_FAIL`**: (LiteTest) A macro that returns 0. Typically used in
  the `LT_TEST` macro to conditionally inject a fail. See also `-I`.
- **`LT_FAULT`**: (LiteTest) A macro that injects (signals) a fault.
  Typically used in the `LT_TEST` macro to conditionally inject a
  fault. See also fault, `-I`, and LiteTest Runner API Reference.
</details>

<details>
<summary>M: Click to view</summary>

- **`maxargs`**: (LiteTest) The maximum number of command‑line
  arguments allowed by the `LT_PARSE_ARGS` macro. This macro parses
  only the first two arguments; additional arguments require custom
  code.
- **`maxparallel`**: (LiteTest) The upper bound on concurrent
  `LT_GROUP` and `LT_TEST` macros. That is, when the number of macros
  executing equals `maxparallel`, the next macro to execute is delayed
  until one of the executing macros finishes. `maxparallel` is a
  parameter for the `LT_INIT_ORCHESTRATOR` and `LT_GROUP` macros.
</details>

<details>
<summary>N: Click to view</summary>

- **`notes`**: (LiteTest) A string parameter for the `LT_CLOSE_REPORT`
  macro. This macro appends the string (which must include `\n` at the
  end of each line in the string) if the string is not NULL or empty.
  Alternatively or in addition, notes can be appended from a file
  containing notes.
</details>

<details>
<summary>O: Click to view</summary>

- **orchestrator**: (LiteTest) See orchestrator (`main`) function.
- **orchestrator function**: (LiteTest) See orchestrator (`main`)
  function.
- **orchestrator (`main`) function**: (LiteTest) The `main` function
  of a LiteTest executable (i.e., the test runner) that uses
  `LT_GROUP` macros to execute sets of tests (i.e., a test group) or
  `LT_TEST` macros to execute a specific test (i.e., a test
  expression).
</details>

<details>
<summary>P: Click to view</summary>

- **pass**: (LiteTest) A counted success where the test expression for
  an `LT_TEST` macro evaluates to non-zero.
- **PATH**: (LiteTest) Optional command‑line argument indicating the
  output destination; may be a report file path or directory path.
  Argument must be quoted if it contains spaces.
- **process guard**: (LiteTest) The guard used for process isolation.
  Unlike thread guards, a process guard can capture all signals but
  increases test execution time. For proven tests, use thread guards;
  otherwise, use process guards.
- **process isolation**: (LiteTest) An isolation mode where a test
  group or test expression runs in a separate process. See also
  isolation mode.
- **project**: (LiteTest) A single-token project identifier used in
  orchestrator initialization and default report naming.
</details>

<details>
<summary>Q: Click to view</summary>

_No terms currently defined._
</details>

<details>
<summary>R: Click to view</summary>

- **report**: See test report.
- **report header**: (LiteTest) Lines of text written at the beginning
  of a test report that include the report title, a timestamp, etc.
- **runner**: (LiteTest) See test runner.
- **runner**: (GitHub) A machine or environment that executes the jobs
  defined in a GitHub Actions workflow. A runner provides the
  operating system, tools, and runtime needed to perform workflow
  steps such as building, testing, or packaging a project. GitHub
  provides hosted runners, and users may also configure self‑hosted
  runners.
</details>

<details>
<summary>S: Click to view</summary>

- **semantic versioning**: A versioning scheme for artifacts. For
  example, in LiteTest, `M.m.p` (for `.h` and `.c` files) or `M.u`
  (document `.md` files) where M, m, p, and u are one or two digits
  and M indicates the major release, m indicates the minor release, p
  indicates the patch version, and u the document update version.
- **shell**: A command-line interface that allows a user or script to
  submit command lines. Examples include `pwsh`, `powershell.exe`,
  `bash`, `sh`, `zsh`, and `cmd.exe`.
- **step**: An individual action within a job. A step may run a shell
  command, execute a script, or invoke a reusable action. Steps run in
  order and share the job’s execution environment.
</details>

<details>
<summary>T: Click to view</summary>

- **test**: See test expression.
- **test artifact**: (LiteTest) A specific kind of artifact, i.e.,
  file or output generated by a LiteTest executable (for example, a
  test report, `stdout`, and `stderr`).
- **test case**: This term is not used in LiteTest. In other contexts,
  it may mean a single test or a set of tests; LiteTest uses test
  expression for an individual test and test group for a set of test
  expressions.
- **test expression**: (LiteTest) An expression that is an argument of
  an `LT_TEST` macro that can be cast to `int`; zero means fail,
  non‑zero means pass. A test expression and its underlying functions
  are user-written. The LiteTest Test API is provided to help simplify
  writing a test expression and its underlying functions.
- **test group**: (LiteTest) A grouping of `LT_TEST` macros and
  optionally `LT_GROUP` macros.
- **test group function**: (LiteTest) A function declared with a
  `LT_DECLARE_GROUP` macro and followed by a function body in `{ }`.
- **test function**: (LiteTest) A user‑written function used in
  implementing a test expression.
- **test helper function**: (LiteTest) A Test API function that helps
  simplify implementing a test expression.
- **test report**: (LiteTest) A file written by a LiteTest executable
  that records the results of a test run, including pass/fail counts,
  faults, and optional notes. See also report header, title, and
  notes.
- **test runner**: (LiteTest) An executable that runs a set of tests.
- **test suite**: A complete set of tests for a project or a subset of
  tests for a project. LiteTest uses the term test group if it is a
  subset of the tests for a project. LiteTest does not use the term
  *test suite* since whether a set of tests is *complete* for a
  project is not well-defined.
- **testing artifact**: (LiteTest) See test artifact.
- **thread guard**: (LiteTest) The guard used for thread isolation. A
  thread guard can only reliably capture synchronous signals
  (`SIGSEGV`, `SIGBUS`, `SIGFPE`, and `SIGILL`). Other signals
  (`SIGABRT`, `SIGKILL`, `SIGSTOP`, `SIGTERM`, `SIGINT`, `SIGHUP`,
  `SIGQUIT`, `SIGPIPE`, `SIGALRM`, `SIGCHLD`, `SIGUSR1`, and
  `SIGUSR2`) cause the executable to terminate. A process guard can
  capture all signals but increases the time to run the tests. For
  already proven tests, use thread guards; otherwise, use process
  guards.
- **thread isolation**: (LiteTest) An isolation mode where a test
  group or test expression executes in a separate thread. See also
  isolation mode.
- **title**: (LiteTest) An optional report header text provided when
  opening the report with an `LT_OPEN_REPORT` macro.
</details>

<details>
<summary>U: Click to view</summary>

_No terms currently defined._
</details>

<details>
<summary>V: Click to view</summary>

_No terms currently defined._
</details>

<details>
<summary>W: Click to view</summary>

- **workflow**: A defined sequence of automated steps executed by a CI
  (continuous‑integration) system. In GitHub Actions, a workflow is
  triggered by an event (such as a push, pull request, or scheduled
  run) and runs one or more jobs that perform tasks like building,
  testing, or packaging a project. Workflows may produce artifacts
  such as logs, reports, or build outputs.
</details>

<details>
<summary>X: Click to view</summary>

_No terms currently defined._
</details>

<details>
<summary>Y: Click to view</summary>

_No terms currently defined._
</details>

<details>
<summary>Z: Click to view</summary>

_No terms currently defined._
</details>

</details>
