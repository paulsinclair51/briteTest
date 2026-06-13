# LiteTest Glossary

This glossary defines terms generally used in LiteTest and terms often used in
the testing domain. It is a companion document to the other LiteTest documents.

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

| Document | Date | LiteTest | Comment | Author/Editor |  
|----------|------------|----------------------------------------------------------|--------------------|  
| 1.0 | 2026‑06‑11 | 1.0.0 | Initial version. | Paul Sinclair |  

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

#### Documentation

<details>
<summary>Click to view</summary>

The user documentation for  LiteTest includes:

- **README** — Introduction to LiteTest.

- **LiteTest Documentation** — A list of the LifeTest documents for users and contributors plus the LiteTest repository layout (listing core files).

- **LiteTest Glossary** — An alphabetically-ordered list of terms generally used in LiteTest (emphasizing their specific meaning in LiteTest) and terms often used in the testing domain.

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
</details>

## Glossary

<details>
<summary>Click to view</summary>

Terms generally used in LiteTest (emphasizing their specific meaning in LiteTest)
and terms often used in the testing domain:

<details>
<summary>A: Click to view</summary>

- `API`: Application Programming Interface: public typedefs, structs, enum,
  macro, and functions that provide a well-defined service. For example,
  the LiteTest Runner API and the LiteTest Test API.
- `artifact`: A file or bundle of files produced by a GitHub Actions workflow
  and stored for later download (e.g., build outputs, logs, reports). For
  LiteTest, a test artifact is a specific kind of artifact that is produced
  by a LiteTest executable.
</details>

<details>
<summary>C: Click to view </summary>

- `command line` - A line of text entered into a shell that specifies an
  executable and optional arguments or flags (options). Use command-line
  when used as an adjective.
- `category`: For LiteTest, a labeled set of `LT_GROUP` and `LT_TEST` macros
  whose combined results are written by `LT_WRITE_RESULT` to the report with
  a specified category name.
- `CD (Continuous Delivery / Continuous Deployment)`: An automated practice that
  extends `CI` by packaging, releasing, or deploying software after it has passed
  all required tests. Continuous Delivery prepares release artifacts for manual
  approval, while Continuous Deployment automatically deploys every passing
  change to a target environment.
- `CI (Continuous Integration)`: An automated development practice where every
   change to a codebase is built and tested in a shared environment. A CI system
   runs workflows that compile the project, execute tests, validate formatting
   or static analysis rules, and produce artifacts such as logs or reports. CI
   helps detect errors early, ensures consistent build quality, and provides
   rapid feedback to developers. Use continuous-integration (or simply CI)
   when used as an adjective.
- `concurrent block`: For LiteTest, a set of tests bracketed by `LT_BEGIN_CONCURRENT` and
  `LT_END_CONCURRENT` macros.
- `contributor`: Any person or agent that may commit to LiteTesf `main`, The implementation changes
and documentation updates for a commit to `main` must conform to the LiteTest contribution
guidelines and muxt have approval by a designated approver or agent.
- `control file`: A previously generated file that can be compared to a newly
  generated file for differences. Differences (other than expected ones like
  timestamps) typically indicate a test failure. Sometimes the control file is
  out of date and must be replaced by promoting the new file.
- `customization function`: A function included in the LiteTest Runner API
   that can be used to help customize the orchestrator (main) function and test group
  functions.
</details>

<details>
<summary>D: Click to view</summary>

- `default report filename`: For LiteTest, the report filename
  used when only a directory path (or no `PATH`) is provided.
</details>

<details>
<summary>E: Click to view</summary>

- `executable`: For LiteTest, a compiled/linked program that
  contains the orchestrator, test groups, test expressions (and
  underlying functions), and the LiteTest APIs. It is run from
  a shell using a command line.
</details>

<details>
<summary>F: Click to view</summary>

- `fail`: For LiteTest, a counted test failure where the `test expression` for
   an `LT_TEST` macro evaluates to zero.
- `fault`: For LiteTest, a counted runtime fault captured by LiteTest
  guards (e.g., invalid memory access). See also guard, isolation,
  thread isolation, and process isolation.
- `fault type`: For LiteTest, the various types of faults (e.g., `SIGSEGV`,`SIGBUS`,
  `SIGABRT`) that can occur or be injected.
</details>

<details>
<summary>G: Click to view</summary>

- `group`: See test group.
- `guard`: For LiteTest, the protection mechanism used to catch runtime
  faults and continue test execution. See also fault, isolation, thread
  isolation, and process isolation.
- `guard handler`: For LiteTest, a function that is used to capture faults.
- `guard level`: For LiteTest, the nesting depth of active guards for test groups and tests
  expressions.
</details>

<details>
<summary>I: Click to view</summary>

- `-I`: For LiteTest, an optional command‑line flag that enables an
  `LT_TEST` macro with an argument value of `I` to be executed. Default is to
  skip the `LT_TEST` macro if it has an argument value of `I`.
- `-I<n>`: For LiteTest, an optional command‑line flag that enables an
  `LT_TEST` macro with an argument value of <m> between 1 and 9 to execute
  if <m> is between 1 and <n>. <n> must be between 1 and 9.
  Default for <n> is 9 if this flag is not specified and, for <m>
  is 1. If <m> is 0, the `LT_TEST` macro is not enabled (i.e., it is skipped).
  At most one `-I<n>` flag specified for a command line.
- `isolation` or `isolation mode`: For LiteTest, an execution mode
   for `LT_GROUP` and `LT_TEST` macros: `0` = same thread, `1` =
   separate thread, `2` = separate process.
</details>

<details>
<summary>J: Click to view</summary>

- `job`: A unit of work within a workflow. A job runs a series of steps
  in a specified environment (such as a container or virtual
  machine). Jobs may run sequentially or in parallel, depending on their
  dependencies.
</details>

<details>
<summary>M: Click to view</summary>

- `maxargs`: For LiteTest, the maximum number of command‑line arguments allowed
  by the `LT_PARSE_ARGS` macro. Note that the `LT_PARSE_ARGS` macro only parses the
  first two arguments; additional arguments must be parsed by custom code.
- `maxparallel`: For LiteTest, the upper bound on concurrent `LT_GROUP` and
  `LT_TEST` macros. That is, when the number of macros executing is `maxparallel`,
  the next macro to execute is delayed until one of the executing macros finishes.
 `maxparallel` is a parameter for the `LT_INIT_ORCHESTRATOR` and `LT_GROUP` macros.
</details>

<details>
<summary>N: Click to view</summary>
  
- `notes`: For LiteTest, a string parameter for the `LT_CLOSE_REPORT` macro. The
  `LT_CLOSE_REPORT` macro appends the string (which must include `\n` at the end
  of each line in the string) if the string is not NULL or empty.
</details>

<details>
<summary>O: Click to view</summary>

- `orchestrator`: See orchestrator (`main`) function.
- `orchestrator (main) function` or simply `orchestrator function`: The `main`
  function of a LiteTest executable (i.e., the test runner) that uses `LT_GROUP`
  macros to execute sets of tests (i.e., a  test group) or `LT_TEST`
  macros to execute a specific test (i.e., a test expression).
</details>

<details>
<summary>P: Click to view</summary>

- `pass`: A counted successful test where the expression evaluates to non‑zero.
- `PATH`: Optional command‑line argument indicating the output destination;
   may be a report file path or directory path. Argument must be quoted if it
   contains spaces.
- `process guard`: The guard used for process isolation can
   capture all signals but increases the time to run the tests. For
   already proven tests, use thread guards; otherwise, use process guards.
- `process isolation`: Isolation mode where a test group or test expression runs in a
  separate process.
- `project`: a single-token project identifier used in orchestrator initialization and default
  report naming.
</details>

<details>
<summary>R: Click to view</summary>

- `report`: See test report.
- `report format`: The output structure produced by LiteTest test runs.
- `report header`: Lines of text written at the beginning of a test report that
   include the report title, a timestamp, etc.
- `runner`: For LiteTest, see test runner. For GitHub, A machine or
  environment that executes the jobs defined in a GitHub Actions workflow.
  A runner provides the operating system, tools, and runtime needed to
  perform workflow steps such as building, testing, or packaging a project.
  GitHub provides hosted runners, and users may also configure self‑hosted
  runners.
</details>

<details>
<summary>S: Click to view</summary>

- `semantic versioning`: A versioning scheme for artifacts. For example,
   in LiteTest, `M.m.p` (for `.h` and `.c` files) or `M.u` (document
  `.md` files) where M, m, p, and u are one or two digits and M
  indicates the major release, m indicates the minor release, p
  indicates the patch version, and u the document update version.
- `shell`: A command-line interface that allows a user or script to submit
  command lines. Examples include `pwsh`, `powershell.exe`,
  `bash`, `sh`, `zsh`, and `cmd.exe`.
- `step`: An individual action within a job. A step may run a shell command,
  execute a script, or invoke a reusable action. Steps run in order and share
  the job’s execution environment.
</details>

<details>
<summary>T: Click to view</summary>

- `test`: See test expression.
- `test artifact` or `testing artifact`: For LiteTest, a specific kind of
  artifact, i.e., file or output generated by a LiteTest executable (for
  example, a test report, stdout, and stderr).
- `test case`: This term is not used in LiteTest. In other contexts, it
  may mean a single test or a set of tests; LiteTest uses test expression (or
  simply test) for an individual test and `test group` for a set of test expressions.
- `test expression`: An expression that is an argument of an `LT_TEST` macro
   that can be cast to `int`; zero means fail, non‑zero means pass. A test
   expression and its underlying functions are user written. The LiteTest Test
   API is provided to help simplify writing a text expression and underlying functions.
- `test group`: A grouping of `LT_TEST` macros and optionally `LT_GROUP` macros.
- `test group function`: A function declared with a `LT_DECLARE_GROUP` macro
  and followed by function body in `{ }`.
- `test function`: A user‑written function used in implementing a
  test expression.
- `test helper function`: A LiteTest Test API function provided to help simplify
  writing the implementation of a test expression.
- `test runner`: an executable that executes (runs) a set of tests.
- `test suite`: a complete set of tests for a project or a subset of tests for
  a project. LiteTest uses the term test group if it is a subset of the
  tests for a project. LiteTest doesn't use the term test suite or specify
  a term for a complete set of tests for a project since whether a set of tests
  is complete or not for a project is not well-defined.
- `testing artifact`: See test artifact.
- `thread guard`: The guard used for thread isolation. A thread guard
  can only reliably capture synchronouse signals (`SIGSEGV`, `SIGBUS`,
  `SIGFPE`, and `SIGILL`). Other signals (`SIGABRT`, `SIGKILL`, `SIGSTOP`,
  `SIGTERM`, `SIGINT`, 'SIGHUP`, 'SIGQUIT`,  `SIGPIPE`, `SIGALRM`,
  `SIGCHLD`, `SIGUSR1`, and `SIGUSR2`) cause the executable to terminate.
  A process guard can capture all signals but increases the time to
  run the tests. For already proven tests, use thread guards; otherwise,
  use process guards.
- `thread isolation`: Isolation mode where a test group or test expression
  executes in a separate thread.
- `title`: For LiteTest, optional report header text provided when opening
  the report with an `LT_OPEN_REPORT` macro.

<details>
<summary>W: Click to view</summary>

- `workflow`: A defined sequence of automated steps executed by a
  CI (continuous‑integration) system. In GitHub Actions, a workflow
  is triggered by an event (such as a push, pull request, or scheduled
  run) and runs one or more jobs that perform tasks like building,
  testing, or packaging a project. Workflows may produce artifacts
  such as logs, reports, or build outputs.
</details>
</details>
