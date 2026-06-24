![Contributor Guide](branding/Contributor_Guide.png)

This document defines the contribution process, coding standards, documentation
rules, and versioning guidelines for BriteTest.

#### Copyright (c) 2026 Paul Sinclair

<details>
<summary>License</summary>

#### **License**

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
<summary>Preface</summary>

## Preface

This document is for contributors who need guidance on enhancing
and maintaining BriteTest.

For a list of other documents and the repository layout, see
the Documentation Guide (`Documentation_Guide.md`).

For a glossary of terms, see the Glossary Reference
(`Glossary_Reference.md`).

A printer-friendly PDF file for this document is available in `docs/pdf/`.

<details>
<summary>Document Version History</summary>

### Document Version History

| Document | Runner | Test | Date | Comment | Author/Editor |
|----------|------|--------|------|---------|---------------|
| 1.0 |1.0.0 | 1.0.0 | 2026‑06‑11 |  Initial version. | Paul Sinclair |

- The **Document** column records the document's version with the
  format `M.u` (Major, update).
- The **Runner** column records the Runner API version
  current at the time this document version was published and is
  defined by its `RA_VERSION` macro.
- The **Test** column records the Test API version current at
  the time this document version was published and is defined by its
  `TA_TEST_VERSION` macro.
- Both Runner and Test use the version format `"M.m.p"` (Major, minor,
  patch).
- `M` is the same for the Document, Runner, and Test versions.

The document's update version tracks released updates to this document and does
not correspond to a minor or patch version. `u` increments when document
changes are published in a release without a change to `M`, and it resets to
`0` when `M` is incremented.
</details>
</details>

<details>
<summary>Table of Contents</summary>

## Table of Contents

1. [**Introduction**](#1-introduction)

2. [**Versioning Rules**](#2-versioning-rules)

3. [**Testing Requirements**](#3-testing-requirements)

4. [**Documentation Rules**](#4-documentation-rules)

5. [**Code Style**](#5-code-style)

6. [**Writing Style Consistency**](#6-writing-style-consistency)

7. [**Pull Requests**](#7-pull-requests)

8. [**Branding**](#8-branding)<br>
   8.1. [Alternative Brand Descriptions](#81-alternative-brand-descriptons)<br>
   8.2. [Alternative Brand Names](#82-alternative-brand-names)<br>
   8.3. [Brand Rename Plan](#83-rename-plan)<br>

    [**Glossary**](#glossary)
</details>

<details>
<summary>1. Introduction</summary>

## 1. Introduction

This Contributor Guide defines the expectations and rules for contributing to
BriteTest. It covers versioning, testing, documentation, code style, and pull
request requirements.

Contributors should read this document before submitting changes to ensure
consistency across the codebase and documentation.
</details>

<details>
<summary>2. Versioning Rules</summary>

## 2. Versioning Rules

BriteTest uses semantic versioning:
- For .h and .c files: `M.m.p` (major, minor, patch).
- For .md files: `M.u` (major, update).

When to increment:

- Update:
  - Document updated.

- Patch:
  - Bug fixes or implementation improvements.

- Minor:
  - Minor additions to the APIs (e.g., new function or macro)
  - Minor additions to the BriteTest framework.
  - No breaking changes (syntax or behavior) to existing public APIs.
  - No breakind changes to the BriteTest framework
  - Minor refactorying of implementation.

- Major
  - Major additions to the BriteTest APIs.
  - Major additions to the BriteTest framework.
  - Significant refactoring of implementation.
  - The following require incrementing the Major version but should be
    avoided by having opt-in or other mechanism to maintain compatibility:
    - Breaking changes (syntax or behavior) to existing public APIs.
    - Breaking changes to the BriteTest framework.
  - If incremented, it must be updated for all files (.h, .c, and .md) to the
    same major value, even if the file was not otherwise modified or updated
    with update, minor, and patch reset to 0.

When updating the version for the Runner API:
- Update `RA_RUNNER_VERSION` in `runnerapi.h`.
- Update `RA_RUNNER_VERSION_C` in `runnerapi.c`.

When updating the version for the Test API:
- Update `RA_TEST_VERSION` in `testapi.h`.
- Update `RA_TEST_VERSION_C` in `testapi.c`.

When updating the version for a document:
- Add a new entry to the top of the Document Version History table only when
  the document changes are being published in a release.
- Increment `u` if the major version is not incremented.
- Reset the update value to `0` when the major version is incremented.

API compatibility rules:
- Public APIs are additive by default.
- Do not change existing signatures.
- Do not change return code meanings.
- Deprecate before removing.
- Provide migration guidance for major changes including how
  to opt-in for new features and behavior.
</details>

<details>
<summary>3. Testing Requirements</summary>

## 3. Testing Requirements

- Build and run tests from the repository root:

```sh
make run
```

- Ensure report formatting changes are reflected in documentation examples.
- Keep test code aligned with the current version of `runnerapi.h`.
</details>

<details>
<summary>4. Documentation Rules</summary>

## 4. Documentation Rules

- `README.md` must remain short and onboarding‑focused.
- A User Guide contains conceptual explanations and examples.
- A API Reference contains public API definitions only.
- An internal guide or reference must not leak into public docs.
- Update documentation when enhancing macros, behavior, or report format.
- For branding assets in `docs/branding/`: `BriteTest_*.svg` files are the source of truth and `BriteTest_*.png` files are generated from SVG using `scripts/genpng.sh`; do not directly edit branding PNG files.
</details>

<details>
<summary>5. Code Style</summary>

## 5. Code Style

- C99.
- POSIX.1‑2001 APIs only.
- Keep `runnerapi.h` self‑contained.
- Keep `runnerapi.c` implementation‑only.
- Avoid intermixing test code with helper logic inside test group functions.
</details>

<details>
<summary>6. Writing Style Consistency</summary>

## 6. Writing Style Consistency

(See the full style rules in the Documentation Style Guide above.)

This section exists here to ensure contributors do not overlook the requirement
for parallel structure and consistent writing patterns across all BriteTest
documentation in all types of files (e,g., ,md, .h, .c, .yml, ,sh, Makefile, etc.).

<details>
<summary>6. Documentation Style Guide</summary>

### 6.1 Documentation Style Guide

1. Tone
- Technical, precise, and neutral.
- No marketing language.
- Prefer clarity over cleverness.

2. Formatting
- Use backticks for code identifiers.
- Use fenced code blocks for file trees, examples, and commands.
- Keep line lengths reasonable for GitHub rendering.

3. Writing Guidelines
- Define terms once, and then use them consistently.
- Avoid synonyms for technical concepts (e.g., always “update version,” never “revision”).
- Keep paragraphs short.
- Use lists for enumerations.

4. `Click to view`
- Use `Click to view` sections and subsections to keep the document readable while
  still accommodating large amounts of technical detail:
  - Collapsing sections allows readers to scan the structure and expand only what
    they need.
  - This keeps the document manageable, avoids overwhelming readers with unrelated
    detail, and makes the document easier to navigate.

5. Writing Style Consistency
To keep BriteTest documentation clear and easy to read, maintain **parallel
structure** within lists and related sentences. In practice:

- Start list items with the same part of speech (typically a verb).
- Keep grammatical patterns consistent across bullets.
- Avoid mixing styles such as “Keep paragraphs short” with “Using lists for enumerations.”
- Rewrite items as needed so the list reads smoothly and uniformly.

This guideline applies to all BriteTest documentation (.md files).
</details>
</details>

<details>
<summary>7. Pull Requests</summary>

## 7. Pull Requests

Before submitting a PR:

- Ensure tests pass.
- Update version numbers if needed.
- Update documentation as needed.
- Keep changes focused and well‑scoped.
</details>

<details>
<summary>8. Branding</summary>

## 8. Branding

This chspter discusses the choices for a brand description and name.
<details>
<summary>8.1. Alternative Brand Descriptions</summary>

### 8.1. Alternative Brand Descriptions

Review: BriteTest is a lightweight framework for defining, running, and reporting tests in C/C++ projects. It provides a simple core macro-based Runner Application Programming Interface (API), a function-based Test API, fault‑tolerant execution, and clear reporting. It is ideal for small to medium C projects that need reliable testing without heavy tooling and dependencies. It can be used for unit and command-line testing.

Takeaway: Your description of BriteTest is solid, but it can be tightened, clarified, and made more parallel to the tone you’ve been using for LiteTest. Below is a refined version that reads cleaner, is more precise, and positions the framework more strongly.

---

⭐ Refined Review of BriteTest

BriteTest is a lightweight framework for defining, running, and reporting tests in C/C++ projects. It provides a compact macro‑based Runner API, a function‑driven Test API, fault‑tolerant execution, and clear, structured reporting. The framework is designed for small to medium C projects that need reliable automated testing without the overhead of large toolchains or external dependencies.

BriteTest supports both unit testing and command‑line driven testing, making it flexible enough for embedded utilities, libraries, and standalone executables.

Key strengths

• Lightweight design — minimal files, minimal API surface, easy to embed.
• Macro‑based Runner API — simple orchestration with predictable control flow.
• Function‑based Test API — tests are just C functions, easy to organize and debug.
• Fault‑tolerant execution — protects the test suite from crashes and undefined behavior.
• Clear reporting — readable summaries of passes, failures, and faults.

Takeaway: Here are three polished, README‑ready project descriptions under 350 characters, each with a slightly different tone. All stay formal and suitable for a title‑page abstract.

---

Option 1 — Concise & Technical

BriteTest is a lightweight C/C++ testing framework providing a macro‑based runner, function‑based tests, fault‑tolerant execution, and clear reporting. It enables reliable unit and command‑line testing without external tooling or heavy dependencies.

---

Option 2 — Clean & Professional

BriteTest is a compact C/C++ framework for defining, running, and reporting tests. It offers a simple macro runner, function‑style tests, robust fault handling, and readable output, ideal for small to medium projects needing dependable testing with minimal overhead.

---

Option 3 — More Emphasis on Purpose

BriteTest is a minimal C/C++ test framework designed for fast, reliable unit and command‑line testing. Its macro‑based runner, function‑driven tests, and fault‑tolerant execution provide clear reporting without the weight of large toolchains or dependencies.

Takeaway: Here are three polished, README‑ready project descriptions under 350 characters, each with a slightly different tone. All stay formal and suitable for a title‑page abstract.

---

Option 1 — Concise & Technical

BriteTest is a lightweight C/C++ testing framework providing a macro‑based runner, function‑based tests, fault‑tolerant execution, and clear reporting. It enables reliable unit and command‑line testing without external tooling or heavy dependencies.

---

Option 2 — Clean & Professional

BriteTest is a compact C/C++ framework for defining, running, and reporting tests. It offers a simple macro runner, function‑style tests, robust fault handling, and readable output, ideal for small to medium projects needing dependable testing with minimal overhead.

---

Option 3 — More Emphasis on Purpose

BriteTest is a minimal C/C++ test framework designed for fast, reliable unit and command‑line testing. Its macro‑based runner, function‑driven tests, and fault‑tolerant execution provide clear reporting without the weight of large toolchains or dependencies.

Takeaway: Here are three refined, README‑ready descriptions (≤350 characters) that subtly echo bright, clarity, lightness, and precision—without being cheesy or literal. Each keeps a formal tone suitable for a title‑page abstract.

---

Option 1 — “Bright + Clear” (clean, crisp)

BriteTest is a lightweight C/C++ testing framework focused on clarity and reliability. It provides a macro‑based runner, function‑style tests, fault‑tolerant execution, and clear reporting—ideal for projects that need dependable testing with minimal overhead.

---

Option 2 — “Bright + Minimal” (emphasizes lightness)

BriteTest is a minimal, fast C/C++ test framework offering a simple macro runner, function‑based tests, resilient execution, and clear, concise reports. It brings bright, low‑overhead testing to small and medium projects without external tooling.

---

Option 3 — “Bright + Purposeful” (subtle thematic resonance)

BriteTest is a lightweight C/C++ framework designed for clear, dependable testing. Its macro runner, function‑driven tests, and fault‑tolerant execution deliver bright, readable reports and reliable automation without heavy dependencies.

---

If you want, I can tune one further to feel more energetic, more formal, or more brand‑forward, such as emphasizing the “brite/bright” theme more strongly through tone or rhythm. You can choose one to refine: Option 1, Option 2, or Option_3.

Takeaway: Here are three polished, README‑ready project descriptions under 350 characters, each with a slightly different tone. All stay formal and suitable for a title‑page abstract.

---

Option 1 — Concise & Technical

BriteTest is a lightweight C/C++ testing framework providing a macro‑based runner, function‑based tests, fault‑tolerant execution, and clear reporting. It enables reliable unit and command‑line testing without external tooling or heavy dependencies.

---

Option 2 — Clean & Professional

BriteTest is a compact C/C++ framework for defining, running, and reporting tests. It offers a simple macro runner, function‑style tests, robust fault handling, and readable output, ideal for small to medium projects needing dependable testing with minimal overhead.

---

Option 3 — More Emphasis on Purpose

BriteTest is a minimal C/C++ test framework designed for fast, reliable unit and command‑line testing. Its macro‑based runner, function‑driven tests, and fault‑tolerant execution provide clear reporting without the weight of large toolchains or dependencies.

---

If you want, I can refine one further or tune it for marketing tone, academic tone, or ultra‑minimal length.

Takeaway: Here are three refined, README‑ready descriptions (≤350 characters) that subtly echo bright, clarity, lightness, and precision—without being cheesy or literal. Each keeps a formal tone suitable for a title‑page abstract.

---

Option 1 — “Bright + Clear” (clean, crisp)

BriteTest is a lightweight C/C++ testing framework focused on clarity and reliability. It provides a macro‑based runner, function‑style tests, fault‑tolerant execution, and clear reporting—ideal for projects that need dependable testing with minimal overhead.

---

Option 2 — “Bright + Minimal” (emphasizes lightness)

BriteTest is a minimal, fast C/C++ test framework offering a simple macro runner, function‑based tests, resilient execution, and clear, concise reports. It brings bright, low‑overhead testing to small and medium projects without external tooling.

---

Option 3 — “Bright + Purposeful” (subtle thematic resonance)

BriteTest is a lightweight C/C++ framework designed for clear, dependable testing. Its macro runner, function‑driven tests, and fault‑tolerant execution deliver bright, readable reports and reliable automation without heavy dependencies.

---

If you want, I can tune one further to feel more energetic, more formal, or more brand‑forward, such as emphasizing the “brite/bright” theme more strongly through tone or rhythm. You can choose one to refine: Option 1, Option 2, or Option_3.

Takeaway: Here are three more energetic, still‑formal, ≤350‑character README abstracts that weave in the brite/bright theme with momentum and confidence.

---

Option 1 — Energetic + Crisp

BriteTest is a fast, lightweight C/C++ testing framework built for clarity and momentum. Its macro runner, function‑based tests, and fault‑tolerant execution deliver bright, reliable reports with minimal overhead—ideal for projects that want testing that stays out of the way.

---

Option 2 — Energetic + Punchy

BriteTest brings bright, low‑overhead testing to C/C++ projects. With a simple macro runner, clean function‑style tests, resilient execution, and sharp reporting, it keeps test cycles quick and clear for teams that want speed without sacrificing reliability.

---

Option 3 — Energetic + Brand‑Forward

BriteTest is a lightweight C/C++ test framework engineered for bright, fast, dependable feedback. Its macro runner, function‑driven tests, and robust fault handling keep results clear and cycles tight—perfect for projects that value clarity and pace.

---

If you want, I can tune one to be more technical, more brand‑loud, or even tighter: Refine Option 1, Refine Option 2, or Refine Option 3.

I like this one since it invokes bright without being obvious by explicitly saying bright which is already in the brand name.

Got it — you’re gravitating toward the version that feels bright without literally saying it. That’s exactly the right instinct for a brand like BriteTest: let the tone carry the theme, not the wording.

Here’s a tightened, energetic version in that same style, still under 350 characters and keeping the “bright without saying bright” vibe:

---

Polished Energetic Abstract

BriteTest is a lightweight C/C++ testing framework built for clarity and speed. Its macro runner, function‑driven tests, and fault‑tolerant execution keep feedback sharp and cycles fast—ideal for projects that want dependable testing with minimal overhead.

---

Got it — you’re gravitating toward the version that feels bright without literally saying it. That’s exactly the right instinct for a brand like BriteTest: let the tone carry the theme, not the wording.

Here’s a tightened, energetic version in that same style, still under 350 characters and keeping the “bright without saying bright” vibe:

---

Polished Energetic Abstract

BriteTest is a lightweight C/C++ testing framework built for clarity and speed. Its macro runner, function‑driven tests, and fault‑tolerant execution keep feedback sharp and cycles fast—ideal for projects that want dependable testing with minimal overhead.

---

If you want, I can tune it to lean slightly more toward technical precision, brand voice, or even more energy.

Takeaway: Here is a technically precise, energetic refinement of Option 2. It keeps the “brite without saying bright” tone, removes soft language, and sharpens the engineering vocabulary—still under 350 characters.

---

Technically Precise Version

BriteTest is a compact C/C++ framework for defining, running, and reporting tests. It provides a macro‑driven runner, clean function‑style test definitions, resilient fault isolation, and clear output—well‑suited for small to medium projects requiring fast, dependable, low‑overhead testing.

---

If you want, I can tune it further toward even more technical rigor or more energetic tone depending on how you want the README to feel.


Here are my top three versions based on clarity, technical precision, energy, and how well they fit a README title‑page abstract. All three stay under 350 characters and keep the “brite without saying bright” tone.

---

⭐ Top Choice 1 — Technically Precise + Energetic

BriteTest is a compact C/C++ framework for defining, running, and reporting tests. It provides a macro‑driven runner, clean function‑style test definitions, resilient fault isolation, and clear output—well‑suited for small to medium projects requiring fast, dependable, low‑overhead testing.

---

⭐ Top Choice 2 — Clean, Energetic, Balanced

BriteTest is a compact C/C++ framework for defining, running, and reporting tests. It offers a simple macro runner, clean function‑style tests, robust fault handling, and clear output—ideal for small to medium projects that need fast, dependable testing with minimal overhead.

---

⭐ Top Choice 3 — Slightly More Dynamic

BriteTest is a lightweight C/C++ framework for defining, running, and reporting tests. Its macro runner, function‑driven tests, and fault‑tolerant execution deliver clear, reliable results—suited for small to medium projects that want fast, dependable testing without heavy tooling.

Here are three tightened, technically precise, energetic versions of your abstract that now explicitly convey ease of use without adding fluff or breaking the “brite‑without‑saying‑bright” tone. All stay under 350 characters.

---

⭐ Option A — Technical + Ease of Use (balanced)

BriteTest is a compact C/C++ framework for defining, running, and reporting tests. It provides an easy‑to‑use macro runner, clean function‑style test definitions, resilient fault isolation, and clear output—ideal for small to medium projects needing fast, dependable, low‑overhead testing.

---

⭐ Option B — More Energetic + Ease of Use

BriteTest is a compact C/C++ framework for defining, running, and reporting tests. Its easy‑to‑use macro runner, clean function‑style tests, robust fault isolation, and clear output make it well‑suited for small to medium projects that need fast, dependable testing with minimal overhead.

---

⭐ Option C — Most Technical + Ease of Use

BriteTest is a compact C/C++ framework for defining, running, and reporting tests. It offers an easy‑to‑use macro‑driven runner, concise function‑style test definitions, strong fault isolation, and clear reporting—ideal for small to medium projects requiring fast, reliable, low‑overhead testing.
</details>

<details>
<summary>8.2. Alternative Brand Names/summary>

### 8.2. Alternative Brand Names

TODO: add these to table.
- BriteTest (bT)
- CanaryRunner (CR)
- CanaryAssert (CA)
- CanaryProof (CP)
- CanaryTestRunner (CYR)
- OpenTest (OT)

These names are fallback options if a naming conflict requires a
brand/project rename.

These notes are an informal naming screen only. They are based on how generic,
descriptive, or commonly used the terms appear in software and testing. They
are not a trademark search or legal clearance.

| Name | Abbrev. | Informal conflict note | Likelihood |
|------|---------|------------------------|------------|
| LiteTest | LT | Clear and close to the project's lightweight positioning, but both `lite` and `test` are common software terms, so overlap with existing package or tool names is plausible. | Medium |
| CanaryTest | CT | Strong fit for the canary theme, but `canary` and `canary testing` are already common software terms, which makes the name less distinctive. | Higher |
| CoreTest | CT | Clear and technical, but both `core` and `test` are common product words and may overlap with existing tools or internal packages. | Medium |
| ClearTest | CT | Readable and descriptive, but the name is broad and likely to overlap with existing testing or QA branding. | Medium |
| TinyTest | TT | Good match for a lightweight framework, but it is fairly descriptive and similar in shape to other small-test framework names. | Medium |
| TraceTest | TT | More distinctive than generic `test` compounds, though `trace` is still a common engineering term. | Medium-Low |
| SwiftTest | ST | Memorable, but `Swift` has strong existing association with Apple's Swift ecosystem, which could create confusion. | Higher |
| QuickTest | QT | Familiar and easy to say, but `QuickTest` has long-standing use in software testing and QA tooling. | Higher |
| CompactTest | CT | Fits the lightweight positioning and is somewhat more distinctive than `CoreTest` or `ClearTest`, though still descriptive. | Medium-Low |
| PublicTest | PT | Descriptive and understandable, but `public` is a common language and API term, which makes the name fairly broad. | Medium |
| APITest | AT | Directly describes API testing, but the term is highly generic and already widely used across tools, articles, and packages. | Higher |
| FastTest | FT | Strong performance-oriented signal, but `fast` and `test` are both generic terms and likely to overlap with existing tooling names. | Medium-High |

 Preference among the candidates:

- `CompactTest (CT)` for a lower-conflict descriptive option.
- `TraceTest (TT)` for a more distinctive technical option.
- `CanaryTest (CT)` only if the canary theme is more important than name
- CanaryRunner
- CanaryAssert
- CanaryProof
- CanaryTestRunner (CTR)
</details>

 <details>
<summary>8.3. Brand Rename Plan</summary>

### 8.3. Brand Rename Plan

Fast low-risk rename plan:

1. Branch and freeze scope
- Create a dedicated rename branch.
- Restrict the change to naming and branding only.

2. Choose one approved replacement name
- Select one of the four preferred alternatives.
- Use the chosen name consistently across code, docs, and assets.

3. Update user-facing names first
- Update the project title in `README.md`.
- Update top-level headings in BriteTest documentation files.
- Add a temporary note in `README.md` that the project was renamed from BriteTest.

4. Update branding assets
- Duplicate existing branding files to the new naming scheme.
- Regenerate PNG files from SVG files.
- Keep old logo files temporarily for one release to avoid broken references.

5. Update generator and file references
- Update `scripts/genpdf` to use the new document branding file names.
- Update markdown image references to point to renamed branding files.
- Regenerate all PDFs and verify output paths.

6. Update source identifiers carefully
- Update only external identifiers that represent the project brand.
- Avoid changing public API symbols unless explicitly required.
- If API symbol changes are required, treat them as a major-version change.

7. Validate and test
- Run `make run`.
- Run full PDF generation and verify branding and title pages.
- Verify no stale references remain with a repository-wide text search.

8. Ship with rollback safety
- Commit the rename in one focused commit.
- Keep a rollback commit point before removing old compatibility references.
- In the next release, remove temporary compatibility references after verification.
</details>
</details>

<details>
<summary>Glossary</summary>

## Glossary

For a glossary of general BriteTest terms, see the Glossary Reference document.
For a glossary of terms, see the Glossary Reference
(`Glossary_Reference.md`).

Contributor‑Specific Terms:

- **Approver**: A contributor with commit access who reviews pull requests, enforces versioning rules, and ensures documentation consistency.
- **Breaking Change**: A change that alters public API behavior, removes or renames macros, changes return semantics, or requires a major version bump.
- **Contributor**: A person submitting code, documentation, fixes, or improvements to BriteTest.
- **Deprecation**: A public API element marked for removal in a future major version, requiring documentation updates and migration guidance.
- **Documentation Update**: Any change to released BriteTest documentation requires incrementing the update version or, if an API major version is incremented, incrementing the major version and resetting the update version to 0.
- **Internal API Change**: A change to an API's internals that does not affect public API users but may require updates to an Internal Guide or Internal Reference.
- **Major Increment**: A structural or conceptual overhaul of BriteTest that causes a breaking change.
- **Public API Change**: Any modification to the BriteTest Runner or Test API that requires a version bumpv.
- **Pull Request Scope**: A guideline requiring PRs to be focused, minimal, logically grouped, and not mixing unrelated changes.
- **Test Coverage Requirement**: The expectation that all changes to BriteTest include new tests (if adding behavior), updated tests (if modifying behavior), and no regressions.
</details>
