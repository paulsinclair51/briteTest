![Contributor Guide](/docs/branding/Contributor_Guide.png)

This document defines the contribution process, coding standards, documentation
rules, and versioning guidelines for contributors, reviewers, and approvers.

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

This document is for contributors, reviewers, and approvers who need guidance
on enhancing and maintaining briteTest.

For a list of other documents and the repository layout, see
the Documentation Guide.

For a glossary of terms, see the Glossary Reference.

A printer-friendly PDF file for this document is available in `docs/pdf/`.

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;Document Version History</summary>

### Document Version History

| Document | Runner | Test  | Date       | Comment          | Author/Editor |
| -------- | ------ | ----- | ---------- | ---------------- | ------------- |
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

1. [**Introduction**](#1-introduction)

2. [**Versioning Guidelines**](#2-versioning-guidelines)<br>
   2.1. [When to Change Version](#21-when-to-change-version)<br>
   2.2. [Continuous Integration (CI) Version Checks](#22-continuous-integration-ci-version-checks)<br>
   2.3. [Incompatible Change](#23-incompatible-change)<br>
   2.4. [Examples](#24-examples)<br>

3. [**Branding**](#3-branding)<br>
   3.1. [Current Branding](#31-current-branding)<br>
   3.2. [Alternative Brand Names](#32-alternative-brand-names)<br>
   3.3. [How to Update Branding](#33-how-to-update-branding)<br>

4. [**Documentation Guidelines**](#4-documentation-guidelines)

5. [**Code Guidelines**](#5-code-guidelines)

6. [**Testing Requirements**](#6-testing-requirements)

7. [**Making Modifications in a Branch**](#7-making-modifications-in-a-branch)

8. [**Pull Request (PR)**](#8-pull-request-pr)

9. [**Release**](#9-release)

10. [**Protected Branches**](#10-protected-branches)

11. [**Glossary**](#11-glossary)

</details>

<details>
<summary><strong>1. Introduction</strong></summary>

## 1. Introduction

This Contributor Guide defines the expectations and rules for contributing to
briteTest. It covers versioning, testing, documentation, code style, pull
request, and release requirements.

The config/contributors.md file defines the contributors and which contributors
are also reviewers or approvers. Contributors should read this document before
submitting changes, reviewing, or approving to ensure consistency across the
code and documentation.
</details>

<details>
<summary><strong>2. Versioning Guidelines</strong></summary>

## 2. Versioning Guidelines

Versioning is used for API `.h` and `.c` files, and documentation (`.md`,
`.pdf`, and `.docx`) files and has the format:

  `M.m.p` (major, minor, patch).

<details>
<summary>2.1. When to Change Version</summary>

### 2.1. When to Change Version

- Patch:
  - Bug fixes, implementation improvements, documentation corrections.
  - No changes to the APIs (e.g., new API function or macro).
  - No changes to the Runner Framework.

- Minor:
  - Minor additions to the APIs (e.g., new function or macro).
  - Minor additions to the Runner Framework.
  - Minor refactoring of implementation.
  - The changes must not introduce an incompatible change.
    See the **Incompatible Change** section.
  - If incremented or reset to 0, it must be updated for all versioned files
    (`.h`, `.c`, `.md`, `.pdf`, and `.docx`) to the same minor value
    (even if the file was not otherwise modified) with patch reset to 0.

- Major:
  - Major additions to the APIs.
  - Major additions to the Runner Framework.
  - Significant refactoring of the implementation.
  - Changes introducing incompatibilities with previously
    released versions. See the **Incompatible Change** section.
  - If incremented, it must be updated for all versioned files (`.h`,
    `.c`, `.md`, `.pdf`, and `.docx`) to the same major value (even if
    the file was not otherwise modified) with minor and patch reset to 0.

When changing the version for a file:

- Increment `p` if the major and minor versions are not changed.
- Reset `p` to `0` when the major or minor version is changed.
- For the `include/runnerapi.h` file, update the `RA_VERSION` macro.
- For the `src/runnerapi.c` file, update the `ra_internal_version` function.
- For the `include/testapi.h` file, update the `TA_VERSION` macro.
- For the `src/testapi.c` file, update the `ta_internal_version` function.
- For a document, add a new entry to the top of the `Document Version History` table.

Note: A major or minor release includes all the versioned files. A patch
release is for an individual versioned file.
</details>

<details>
<summary>2.2. Continuous Integration (CI) Version Checks</summary>

### 2.2. Continuous Integration (CI) Version Checks

Version consistency is enforced by the CI
pipeline on all pull requests (PR) and commits to the `main` branch:

- The `ckversions` script validates that major and minor versions are
  consistent across all versioned files:
  - API headers: `include/runnerapi.h`, `include/testapi.h`
  - API implementations: `src/runnerapi.c`, `src/testapi.c`
  - Documentation: `docs/md/*.md` (excluding `README.md`)

- For branches with patch-only changes, `ckversions` confirms that only the
  patch version differs across files.

- For branches with minor or major version changes, `ckversions` confirms
  that all versioned files have been updated to the same major.minor values.

- If version consistency fails, the CI workflow blocks the PR merge.
  Contributors must update version numbers to match the policy and
  re-push their changes.

See the `scripts/bin/ckversions` script for details on version validation logic.
</details>

<details>
<summary>2.3. Incompatible Change</summary>

### 2.3. Incompatible Change

An incompatible change is a change to the APIs or the Runner Framework
that requires a user to modify their code such as changes to:

- API signatures including removal of a signature.
- API or Runner Framework behavior.
- Exit and return code meanings.

Preferably, an incompatible change should be avoided by having opt-in or other
mechanism to maintain compatibility.

An actual incompatible change is expected to be rare. Before requesting
such a change, consult with reviewers and approvers to confirm the change
is truly required and cannot be avoided.

A request for an incompatible change requires special handling:

- **Contributor:** Provide written justification in the PR description for the
  change and why it cannot be avoided. State whether it was documented as
  deprecated (if the change removes an API declaration) or as an upcoming change
  in a previous major or minor release. Provide migration guidance for the change.

- **Reviewers:** Examine the justification and the change together.
  Reviewers verify that:
  - The justification is clear.
  - The change is needed and technically sound.
  - The change is documented or communicated appropriately to users.

- **Approver:** After reviewer feedback is addressed, the approver makes the final
  decision whether to approve the PR. If not approved, approver provides guidance
  on whether the change is rejected or is deferred to a later major release
  (e.g., to allow for a deprecation or upcoming change notice in the next major
  or minor release).

</details>

<details>
<summary>2.4. Examples</summary>

### 2.4. Examples

The following examples illustrate common scenarios and the appropriate version
change:

#### Example 1: Bug Fix to runnerapi.c

**Change**:

- Fix a segmentation fault in `ra_internal_runner_run_test` when a
  callback returns an error code.

**Files Modified**:

- `src/runnerapi.c`

**Versioning:**

- Current version: 1.0.2
- New version: 1.0.3
- Reason: Bug fix with no API signature or behavior changes.
- Action: Increment patch version in `src/runnerapi.c` only.
- CI Check: `ckversions` confirms runnerapi.h remains 1.0.0 (no change),
  runnerapi.c becomes 1.0.3 (patch bump).

#### Example 2: Documentation Update for testapi.h

**Change**:

- Clarify docstring for `ta_read_file` function and update the Test
  API Reference document with additional usage examples.

**Files Modified**:

- `include/testapi.h`, `docs/md/Test_API_Reference.md`

**Versioning**:

- Current version: 1.0.0
- New version: 1.0.1
- Reason: Documentation corrections only; no API changes.
- Action: Increment patch version in both files and add entry to Document
  Version History table.
- CI Check: `ckversions` confirms both testapi.h and the document have
  patch 1.0.1.

#### Example 3: New Test Helper Function

**Change**:

- Add a new public function `ta_compare_xml` to the Test API for
  comparing XML documents.

**Files Modified**:

- `include/testapi.h`, `src/testapi.c`,
  `docs/md/Test_API_Reference.md`

**Versioning**:

- Current version: 1.0.1
- New version: 1.1.0
- Reason: New function is a backward-compatible minor addition to the API.
- Action:
  - Update `TA_VERSION` macro in `include/testapi.h` to 1.1.0.
  - Update `ta_internal_version` function in `src/testapi.c` to 1.1.0.
  - Update document to 1.1.0 and add entry to Document Version History table.
  - Because minor version changed, all versioned files must sync. For example,
    increment `docs/md/Contributor_Guide.md` to 1.1.0 even though it was not
    modified.
- CI Check: `ckversions` confirms all files have major.minor 1.1 with patch 0.

#### Example 4: Incompatible API Change (Requires Special Handling)

**Change**:

- Modify the signature of `ta_execute_command` to accept a timeout
  structure instead of milliseconds. This is a breaking change needed
  to support microsecond precision in a future integration.

**Files Modified**:

- `include/testapi.h`, `src/testapi.c`,
  `docs/md/briteTest.md` (aka root README.md), `docs/md/Test_API_Guide.md`,
  `docs/md/Test_API_Reference.md`, `docs/md/Test_Internal_Guide.md`,
  `docs/md/Test_Internal_Reference.md`

**Versioning**:

- Current version: 1.1.0
- Proposed version: 2.0.0
- Reason: Breaking change requires major version bump per guidelines.
- Justification (in PR): The `ta_execute_command` signature change is
  necessary to support sub-millisecond precision required by the upcoming
  real-time test harness feature. Migration path: user code using
  `ta_execute_command(cmd, 1000, ...)` should be updated to use the new
  struct-based timeout. A migration guide is included in
  docs/Migration_Guide_1.1_to_2.0.md detailing the transition steps and
  providing helper macros for compatibility. A notice of this change
  and migration guide was included in docs/briteTest.md (aka root README.md)
  version 1.1.0.
- Action:
  - Update major version to 2.0.0 in all versioned files (resetting minor
    and patch to 0).
  - Include migration documentation.
  - Reference the PR justification in release notes.
- CI Check: `ckversions` confirms all files have major 2.0.0.

</details>
</details>

<details>
<summary><strong>3. Branding</strong></summary>

## 3. Branding

This chapter discusses the choices for the brand name and description
plus how to update the branding.

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.1. Current Branding</summary>

### 3.1. Current Branding

- Brand name: briteTest

- Description (GitHub limit: 350 characters or less):

```text
briteTest is a lightweight, easy-to-use C/C++ framework for running unit and
command-line tests focused on clarity and reliability. It provides a simple
macro-based Runner API with customization macros and functions, a function-based Test API, fault-tolerant execution, clear reporting, comprehensive documentation,
and no external dependencies.
```

Why this brand name:

- The name is a relatively low-risk branding choice because its distinctive
  camelCase form and specific presentation reduce the chance of a brand name
  conflict.
- The `briteTest` camelCase form is distinctive and aligns with the `bT`
  branding monogram used in project visuals.
- The uppercase `T` is intentional: it represents the canary theme, with the
  canary perched on the `T` in the `bT` monogram, echoing the
  canary-in-a-coal-mine analogy as an early warning signal in testing.
- The name is easy to recognize, pronounce, and remember while still
  signaling software testing intent.
- The lowercase/uppercase contrast in `briteTest` helps the name stand out
  from other test-framework names.
- Generic `Runner` and `Test` API names reduce coupling to the project
  brand and make a future brand rename less disruptive.

Why this description:

- It states scope and usage clearly: lightweight C/C++ unit and command-line
  testing.
- It names the two core interfaces used throughout the docs: Runner API and
  Test API.
- It emphasizes practical value for adopters: fault-tolerant execution, clear
  reporting, comprehensive documentation, and no external dependencies.

</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.2. Alternative Brand Names</summary>

### 3.2. Alternative Brand Names

These names are options if a naming conflict requires a brand/project rename.

These notes are an informal naming screen only. They are based on how generic,
descriptive, or commonly used the terms appear in software and testing. They
are not a trademark search or legal clearance.

The preferred naming style is camelCase; however, PascalCase
(UpperCamelCase) may be an acceptable alternative.

#### Fallback

Brand names that are acceptable if the brand name briteTest cannot be used.

| Name | Initial | Reason |
| ------ | --------- | -------- |
| BriteTest | BT | Strong fit for the project brand and clear connection to the canary monogram. |
| liteTest | lT | Clear fit for the lightweight positioning, though still somewhat generic. |
| compactTest | cT | Good match for the lightweight position and slightly more distinctive than other descriptive alternatives. |
| tinyTest | tT | Good thematic fit for a small, lightweight framework, though still descriptive. |

#### Deprioritized

Brand names usable in theory but weaker than the current preferred/fallback
options.

| Name | Initial | Reason |
| ------ | --------- | -------- |
| openTest | oT | Readable, but built from broad software terms that are more likely to overlap with existing names. |
| canaryRunner | cR | Strong theme match, but `canary` is already common software terminology and reduces distinctiveness. |
| CanaryTestRunner | CTR | Explicit and descriptive, but long and composed of highly generic testing terms. |
| canaryTestRunner | cTR | Similar to `CanaryTestRunner`, with camelCase branding potential, but still fairly generic. |
| canaryTestrunner | cTr | Slightly more distinctive in presentation, but still closely tied to common `canary` and `test runner` terminology. |
| clearTest | cT | Readable and descriptive, but broad enough to risk overlap with existing testing or QA branding. |
| fastTest | fT | Strong performance signal, but both `fast` and `test` are generic software terms. |

#### Rejected

Brand names with strong likely confusion or established association.

| Name | Initial | Reason |
| ------ | --------- | -------- |
| canaryTest | cT | Too close to common `canary testing` terminology to be distinctive. |
| swiftTest | sT | Likely to be confused with Apple's Swift ecosystem. |
| quickTest | qT | Already strongly associated with established testing and QA tooling. |

</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.3. How to Update Branding</summary>

### 3.3. How to Update Branding

This workflow describes how to update the brand name, initials, and/or tagline
using `scripts/bin/updatebrand`.

#### Workflow Steps

1. Add a pending row in `logs/brand_history.md`:

   - The first row with an empty **Completed** value is treated as the pending
     brand change.
   - The next row below it with a non-empty **Completed** value is treated as
     the previous (current) brand values.
   - Fill in **Brand Name**, **Initials**, and **Tagline** in the pending row.

2. Run a dry run first:

```bash
scripts/bin/updatebrand -d
```

- This shows planned replacements without modifying files.
- A dry-run log is written to:
     `logs/updatebrand-log-dry-run-YYYYMMDD-HHMMSS.md`.

3. Apply the change:

```bash
scripts/bin/updatebrand
```

- The script updates matching `docs/branding/*.svg` values.
- The script regenerates PNG files using `scripts/bin/genpngs` when SVG
     files changed.
- The script updates matching `*.md`, `*.c`, and `*.h` files for brand-name
     replacement.
- The script marks the pending Brand History row completed with the current
     date/time.
- A run log is written to:
     `logs/updatebrand-log-YYYYMMDD-HHMMSS.md`.
- `logs/updatebrand-log-dry-run-YYYYMMDD-HHMMSS.md` files are deleted if
     `updatebrand` is successful.

4. Review and validate:

   - Review `git diff` and the generated update log.
   - Run the project validation steps required for your change (for example,
     `make run` and documentation generation checks).
   - Review `docs/md/*.md` files (valid logo and use of brand name).

5. Commit and open a PR:

   - Commit branding updates (SVG, PNG, docs, source/header updates, and
     `logs/brand_history.md`) with a clear message.
   - Open a PR with a short summary of the brand transition.

</details>
</details>

<details>
<summary><strong>4. Documentation Guidelines</strong></summary>

## 4. Documentation Guidelines

This section exists here to ensure contributors do not overlook the requirement
for parallel structure and consistent writing patterns across all documentation
in all types of files (e.g., `.md`, `.h`, `.c`, `.yml`, `.dh`, `Makefile`, etc.).

#### 1. General

- Root `README.md` must remain short and onboarding-focused.
- A User Guide contains conceptual explanations and examples.
- An API Reference contains public API definitions only.
- An internal guide or reference must not leak into public docs.
- Update documentation when enhancing macros, behavior, or report format.
- For branding assets in `docs/branding/`: `*.svg` files are the source of
     truth and `*.png` files are generated from SVG using `scripts/bin/genpngs`.

#### 2. Tone

- Technical, precise, and neutral.
- Minimal marketing language.
- Prefer clarity over cleverness.

#### 3. Formatting

- Use backticks for code identifiers.
- Use fenced code blocks for file trees, examples, and commands.
- Keep line lengths reasonable for GitHub rendering.
- Use boldface for a term or phrase when defining it.
- Conform to formatting styles existing in the documentation.

#### 4. Writing Guidelines

- Define terms once, and then use them consistently.
- Avoid synonyms for technical concepts (e.g., always "update version,"
     never "revision").
- Keep paragraphs short.
- Use lists for enumerations.

#### 5. Collapsible Sections in `.md` Files

- Use collapsible chapters, sections and subsections to keep the document
  readable while still accommodating large amounts of technical detail.
- Collapsing sections allows readers to scan the structure and expand
  only what they need.
- This keeps the document manageable, avoids overwhelming readers with
  unrelated detail, and makes the document easier to navigate.

#### 6. Style Consistency

To keep documentation clear and easy to read, maintain **parallel
structure** within lists and related sentences:

- Start list items with the same part of speech (typically a verb).
- Keep grammatical patterns consistent across bullets.
- Avoid mixing styles such as "Keep paragraphs short" with "Using lists
  for enumerations."
- Rewrite items as needed so the list reads smoothly and uniformly.

This guideline applies to all documentation (`.md` files).
</details>

<details>
<summary><strong>5. Code Guidelines</strong></summary>

## 5. Code Guidelines

- C99.
- POSIX.1-2001 APIs only.
- Keep `runnerapi.h` and `testapi.h` each self-contained.
- Keep `runnerapi.c` and `testapi.c` implementation-only.

</details>

<details>
<summary><strong>6. Testing Requirements</strong></summary>

## 6. Testing Requirements

- Build and run tests from the repository root:

```sh
make run
```

- Ensure report formatting changes are reflected in documentation examples.
- Keep test code aligned with the current version of `runnerapi.h` and
  `testapi.h`.

</details>

<details>
<summary><strong>7. Making Modifications in a Branch</strong></summary>

## 7. Making Modifications in a Branch

- Define modifications that are focused (not mixing unrelated changes),
  logically grouped, and well-scoped.
- Define an appropriate name for your changes to use as the branch name.
- Obtain preliminary approval and target release for the modifications
  and branch name.
- Create a branch using your branch name.
- Modify the code in the branch as needed.
- Modify the documentation in the branch as needed in parallel with any
  code changes.
- Ensure the modifications in the branch are still focused (not mixing
  unrelated changes), logically grouped, and well-scoped.
- Ensure modifications follow the Documentation Guidelines and the Code
  Guidelines.
- Ensure version numbers are updated for modified versioned files as
  needed per the Versioning Guidelines.
- Include test coverage for new behavior and modifications.
- Ensure tests pass: run `make run` from the repository root.

</details>

<details>
<summary><strong>8. Pull Request (PR)</strong></summary>

## 8. Pull Request (PR)

A **Pull Request (PR)** is a formal proposal to merge your code changes
into the `main` branch of the repository. It's the mechanism that
enables code review, quality assurance, and collaborative development
before changes become part of the official codebase.

### Pull Request Workflow

#### Step 1: Prepare Your Changes

Before submitting a PR:

- Ensure changes for the PR are focused (not mixing unrelated changes),
  logically grouped, and well-scoped.
- Update documentation as needed in parallel with code changes.
- Ensure changes follow the Documentation Guidelines and Code Guidelines.
- Update version numbers of modified versioned files as needed per the
  Versioning Guidelines.
- Include test coverage for new behavior and modifications.
- Ensure tests pass: run `make run` from the repository root.

#### Step 2: Create the Pull Request

- Push your branch to the repository
- Open a PR on GitHub with a clear title and description
- Reference any related issues or discussions
- Ensure the PR scope is minimal and logically grouped

#### Step 3: Code Review and Approval

- An **approver** (contributor with commit access) and, optionally, other
  contributors review the PR to verify:
  - Tests pass and there are no regressions,
  - Versioning rules are enforced,
  - Documentation consistency is maintained,
  - Changes align with code and contribution guidelines,
  - An approver or a reviewer may request changes.
- The approver does one of the following:
  - Approves the PR for the next release - continue with Step 4.
  - Rejects the PR.
  - Defers the PR for a subsequent release. The contributor may resubmit the PR
    after the next release is committed or when advised by the approver.

#### Step 4: Merge into Main

- Once approved, the PR is merged into the `main` branch.
- Changes are now part of the official codebase but not yet released.
- The branch can be deleted after merging.

### Versioning Checklists

Use this checklist to ensure version numbers are correct before opening a PR:

**Before Opening the PR:**

- [ ] I have identified which versioned files I modified (API headers `.h`, API
      implementations `.c`, documentation `.md`).
- [ ] I have determined the appropriate version change (patch, minor, or major)
      per the Versioning Guidelines.
- [ ] I have updated the version numbers in all affected files:
  - [ ] For patch changes: incremented patch only in the modified file(s).
  - [ ] For minor changes: updated all versioned files to the same major.minor
        with patch reset to 0.
  - [ ] For major changes: updated all versioned files to the same major
        value with minor and patch reset to 0.
- [ ] I have verified version consistency locally by running:
      `scripts/bin/ckversions`
- [ ] For documentation files, I have added a new entry to the top of the
      Document Version History table with today's date and a brief comment.
- [ ] If I am making an exception to the versioning guidelines, I have
      included written justification in my PR description.

**In the PR Description:**

- [ ] PR title and description clearly describe the change.
- [ ] If versioning is non-standard or requires an exception, I have
      explained why and which guideline is being deviated from.
- [ ] If this is a minor or major release, I have summarized the impact
      on users and any migration requirements.

**During Review:**

- [ ] Reviewers will verify version changes align with the guidelines
      during code review.
- [ ] CI will automatically run `ckversions` and report consistency
      errors.
- [ ] If CI or reviewers request version updates, I will make the
      corrections and re-push.

**Approver Verification:**

- [ ] Approver confirms CI version check passed.
- [ ] Approver confirms version numbers align with the Versioning
      Guidelines and PR justification (if any).

</details>

<details>
<summary><strong>9. Release</strong></summary>

## 9. Release

A **Release** is the act of publishing a specific version for public use.
It packages approved and merged changes into a versioned, immutable
snapshot that users can download and depend on.

### Release Workflow

#### Step 1: Prepare the Release

Before releasing:

- Prepare a preliminary release note for users that summarizes the changes.
- Verify if release qualifies as a major, minor, or patch.
- Verify modified versioned files have the correct versions consistently
  across all files per the Versioning Guidelines.
- Ensure API compatibility guidelines are followed.
- Document all breaking changes with migration guidance.
- Test thoroughly.
- Finalize a clear and concise release note.

#### Step 2: Validate Changes

- Run `make run` to ensure all tests pass
- Run `make pdf` to verify branding updates in generated documents
- Perform repository-wide text search for stale old-version references
- Ensure all changes align with API compatibility guidelines:
  - Do not change API signatures.
  - Do not change API behavior.
  - Do not change exit and return code meanings.
  - Deprecate before removing.
  - Provide migration guidance for major changes.

#### Step 3: Create Release Commit

- Create a commit with clear message documenting the release.
- Include version updates for all files.
- Include updated documentation and version history tables.
- Optionally, update `README.md` with release notes.

#### Step 4: Tag and Publish

- Tag the commit with the new version (e.g., `v1.2.3`).
- Push the tag to the repository.
- Create a GitHub release with the release note.
- Make the release publicly available for download.

</details>

<details>
<summary><strong>10. Protected Branches</strong></summary>

## 10. Protected Branches

This section explains how to set up a pre-commit hook to prevent accidental commits
to protected branches.

### What are Protected Branches?

Protected branches are critical branches that should not receive
direct commits. The branch management scripts (`mkbranch` and
`rmbranch`) prevent deletion of:

- `main`

### Setting Up a Pre-commit Hook

A pre-commit hook prevents commits to these protected branches
before they're pushed to the remote.

#### 1. Create the hook file

Create `.git/hooks/pre-commit` in your repository:

```bash
touch .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

#### 2. Add the hook script

Edit `.git/hooks/pre-commit` and add:

```bash
#!/usr/bin/env bash

# Pre-commit hook to prevent commits to protected branches
# This hook runs before every commit to check the current branch

PROTECTED_BRANCHES=("main" "master" "develop" "development")

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Check if current branch is protected
for protected in "${PROTECTED_BRANCHES[@]}"; do
  if [[ "$CURRENT_BRANCH" == "$protected" ]]; then
    echo "Error: You are trying to commit to the protected branch '$CURRENT_BRANCH'"
    echo "Please create a feature branch using: scripts/bin/mkbranch -r <branchname> $CURRENT_BRANCH"
    exit 1
  fi
done

exit 0
```

#### 3. Make it executable

```bash
chmod +x .git/hooks/pre-commit
```

### Alternative: Shared Hook Setup

For teams, you can store hooks in version control and set them up automatically:

#### 1. Create a hooks directory in your repository

```bash
mkdir -p .githooks
```

#### 2. Create the pre-commit hook

Save the script above to `.githooks/pre-commit` and make it executable:

```bash
chmod +x .githooks/pre-commit
```

#### 3. Configure Git to use this directory

```bash
git config core.hooksPath .githooks
```

Or configure it globally for your user:

```bash
git config --global core.hooksPath ~/.githooks
```

#### 4. Commit the hooks directory

```bash
git add .githooks/
git commit -m "Add pre-commit hooks for protected branches"
```

### How It Works

When you try to commit on a protected branch:

```bash
$ git commit -m "some change"
Error: You are trying to commit to the protected branch 'main'
Please create a feature branch using: scripts/bin/mkbranch -r <branchname> main
```

The commit is rejected, and you must:

1. Switch to or create a feature branch.
2. Make your changes on that branch.
3. Create a pull request for review.

### Recommended Workflow

1. **Create a feature branch:**

   ```bash
   scripts/bin/mkbranch -r my-feature main
   ```

2. **Make your changes:**

   ```bash
   git add .
   git commit -m "Add my feature"
   ```

3. **Push to remote:**

   ```bash
   git push origin patch/my-feature
   ```

4. **Create a pull request** on GitHub/GitLab

5. **After approval, merge and clean up:**

   ```bash
   scripts/bin/rmbranch -a patch/my-feature
   ```

### Troubleshooting

#### Hook is not running

Check that:

- The hook file is executable: `ls -la .git/hooks/pre-commit`
- The shebang line is correct: `#!/usr/bin/env bash`
- Git hooks are enabled in your repository

### Need to bypass the hook (not recommended)

Use the `--no-verify` flag to skip hooks:

```bash
git commit --no-verify -m "message"
```

**Note:** This should only be used in emergencies and is not
recommended for shared repositories.

### Additional Server-Side Protection

For maximum protection, configure branch protection rules in
your repository settings:

1. Go to Repository Settings -> Branches
2. Add a branch protection rule for `main`, `master`, `develop`, etc.
3. Enable:
   - Require pull request reviews
   - Require status checks to pass
   - Dismiss stale pull request approvals
   - Require branches to be up to date before merging

This prevents any direct pushes to protected branches, even if
someone bypasses the local hook.
</details>

<details>
<summary><strong>11. Glossary</strong></summary>

## 11. Glossary

For a glossary of terms generally used in the documentation, see
the Glossary Reference.

Contributor-Specific Terms:

- **Approver**: A contributor with commit access who reviews pull requests,
  enforces versioning rules, and ensures documentation consistency.
- **Breaking Change**: A change that alters public API behavior, removes or
  renames macros, changes return semantics, or requires a major version bump.
- **Contributor**: A person submitting code, documentation, fixes, or
  improvements.
- **Deprecated**: A public API element marked for removal in a future major
  version, requiring documentation updates and migration guidance.
- **Documentation Update**: Any modification to versioned documentation requires
  incrementing the update version or, if an API major version is incremented,
  incrementing the major version per the Versioning Guidelines.
- **Internal API Change**: A change to an API's internals that does not affect
  public API users but may require updates to an Internal Guide or Internal
  Reference.
- **Major Increment**: A structural or conceptual overhaul that causes a
  breaking change.
- **Public API Change**: Any modification to the Runner Framework/API or the
  Test API that requires a major version bump.
- **Pull Request**: A formal proposal to merge changes into a target branch
  for review and approval.
- **Release**: A published, versioned snapshot of the project made available
  to users.
- **Test Coverage Requirement**: The expectation that all code changes include
  new tests (if adding behavior), updated tests (if modifying behavior), and no
  regressions.
- **Versioned Files**: Files that include a version and version history.

</details>
