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

50| <details>
51| <summary>Document Version History</summary>
52| 
53| ### Document Version History
54| 
55| | Document | Runner | Test | Date | Comment | Author/Editor |
56| |----------|------|--------|------|---------|---------------|
57| | 1.0 |1.0.0 | 1.0.0 | 2026‑06‑11 |  Initial version. | Paul Sinclair |
58| 
59| - The **Document** column records the document's version with the
60|   format `M.u` (Major, update).
61| - The **Runner** column records the Runner API version
62|   current at the time this document version was published and is
63|   defined by its `RA_VERSION` macro.
64| - The **Test** column records the Test API version current at
65|   the time this document version was published and is defined by its
66|   `TA_TEST_VERSION` macro.
67| - Both Runner and Test use the version format `"M.m.p"` (Major, minor,
68|   patch).
69| - `M` is the same for the Document, Runner, and Test versions.
70| 
71| The document's update version tracks released updates to this document and does
72| not correspond to a minor or patch version. `u` increments when document
73| changes are published in a release without a change to `M`, and it resets to
74| `0` when `M` is incremented.
75| </details>
76| </details>
77| 
78| <details>
79| <summary>Table of Contents</summary>
80| 
81| ## Table of Contents
82| 
83| 1. [**Introduction**](#1-introduction)
84| 
85| 2. [**Versioning Rules**](#2-versioning-rules)
86| 
87| 3. [**Testing Requirements**](#3-testing-requirements)
88| 
89| 4. [**Documentation Rules**](#4-documentation-rules)
90| 
91| 5. [**Code Style**](#5-code-style)
92| 
93| 6. [**Writing Style Consistency**](#6-writing-style-consistency)
94| 
95| 7. [**Pull Requests**](#7-pull-requests)
96| 
97| 8. [**Branding**](#8-branding)<br>
98|    8.1. [Alternative Brand Descriptions](#81-alternative-brand-descriptons)<br>
99|    8.2. [Alternative Brand Names](#82-alternative-brand-names)<br>
100|    8.3. [Brand Replacement Workflow](#83-brand-replacement-workflow)<br>
101| 
102| 9. [**Glossary**](#9-glossary)
103| </details>
104| 
105| <details>
106| <summary>1. Introduction</summary>
107| 
108| ## 1. Introduction
109| 
110| This Contributor Guide defines the expectations and rules for contributing to
111| BriteTest. It covers versioning, testing, documentation, code style, and pull
112| request requirements.
113| 
114| Contributors should read this document before submitting changes to ensure
115| consistency across the codebase and documentation.
116| </details>
117| 
118| <details>
119| <summary>2. Versioning Rules</summary>
120| 
121| ## 2. Versioning Rules
122| 
123| BriteTest uses semantic versioning:
124| - For .h and .c files: `M.m.p` (major, minor, patch).
125| - For .md files: `M.u` (major, update).
126| 
127| When to increment:
128| 
129| - Update:
130|   - Document updated.
131| 
132| - Patch:
133|   - Bug fixes or implementation improvements.
134| 
135| - Minor:
136|   - Minor additions to the APIs (e.g., new function or macro)
137|   - Minor additions to the BriteTest framework.
138|   - No breaking changes (syntax or behavior) to existing public APIs.
139|   - No breakind changes to the BriteTest framework
140|   - Minor refactorying of implementation.
141| 
142| - Major
143|   - Major additions to the BriteTest APIs.
144|   - Major additions to the BriteTest framework.
145|   - Significant refactoring of implementation.
146|   - The following require incrementing the Major version but should be
147|     avoided by having opt-in or other mechanism to maintain compatibility:
148|     - Breaking changes (syntax or behavior) to existing public APIs.
149|     - Breaking changes to the BriteTest framework.
150|   - If incremented, it must be updated for all files (.h, .c, and .md) to the
151|     same major value, even if the file was not otherwise modified or updated
152|     with update, minor, and patch reset to 0.
153| 
154| When updating the version for the Runner API:
155| - Update `RA_RUNNER_VERSION` in `runnerapi.h`.
156| - Update `RA_RUNNER_VERSION_C` in `runnerapi.c`.
157| 
158| When updating the version for the Test API:
159| - Update `RA_TEST_VERSION` in `testapi.h`.
160| - Update `RA_TEST_VERSION_C` in `testapi.c`.
161| 
162| When updating the version for a document:
163| - Add a new entry to the top of the Document Version History table only when
163|   the document changes are being published in a release.
164| - Increment `u` if the major version is not incremented.
165| - Reset the update value to `0` when the major version is incremented.
166| 
167| API compatibility rules:
168| - Public APIs are additive by default.
169| - Do not change existing signatures.
170| - Do not change return code meanings.
171| - Deprecate before removing.
172| - Provide migration guidance for major changes including how
173|   to opt-in for new features and behavior.
174| </details>
175| 
176| <details>
177| <summary>3. Testing Requirements</summary>
178| 
179| ## 3. Testing Requirements
180| 
181| - Build and run tests from the repository root:
182| 
183| ```sh
184| make run
185| ```
186| 
187| - Ensure report formatting changes are reflected in documentation examples.
188| - Keep test code aligned with the current version of `runnerapi.h`.
189| </details>
190| 
191| <details>
192| <summary>4. Documentation Rules</summary>
193| 
194| ## 4. Documentation Rules
195| 
196| - `README.md` must remain short and onboarding‑focused.
197| - A User Guide contains conceptual explanations and examples.
198| - A API Reference contains public API definitions only.
199| - An internal guide or reference must not leak into public docs.
200| - Update documentation when enhancing macros, behavior, or report format.
201| - For branding assets in `docs/branding/`: `BriteTest_*.svg` files are the source of truth and `BriteTest_*.png` files are generated from SVG using `scripts/genpng.sh`; do not directly edit brand[...]
202| </details>
203| 
204| <details>
205| <summary>5. Code Style</summary>
206| 
207| ## 5. Code Style
208| 
209| - C99.
210| - POSIX.1‑2001 APIs only.
211| - Keep `runnerapi.h` self‑contained.
212| - Keep `runnerapi.c` implementation‑only.
213| - Avoid intermixing test code with helper logic inside test group functions.
214| </details>
215| 
216| <details>
217| <summary>6. Writing Style Consistency</summary>
218| 
219| ## 6. Writing Style Consistency
220| 
221| (See the full style rules in the Documentation Style Guide above.)
222| 
223| This section exists here to ensure contributors do not overlook the requirement
224| for parallel structure and consistent writing patterns across all BriteTest
225| documentation in all types of files (e,g., ,md, .h, .c, .yml, ,sh, Makefile, etc.).
226| 
227| <details>
228| <summary>6. Documentation Style Guide</summary>
229| 
230| ### 6.1 Documentation Style Guide
231| 
232| 1. Tone
233| - Technical, precise, and neutral.
234| - No marketing language.
235| - Prefer clarity over cleverness.
236| 
237| 2. Formatting
238| - Use backticks for code identifiers.
239| - Use fenced code blocks for file trees, examples, and commands.
240| - Keep line lengths reasonable for GitHub rendering.
241| 
242| 3. Writing Guidelines
243| - Define terms once, and then use them consistently.
244| - Avoid synonyms for technical concepts (e.g., always "update version," never "revision").
245| - Keep paragraphs short.
246| - Use lists for enumerations.
247| 
248| 4. `Click to view`
249| - Use `Click to view` sections and subsections to keep the document readable while
250|   still accommodating large amounts of technical detail:
251|   - Collapsing sections allows readers to scan the structure and expand only what
252|     they need.
253|   - This keeps the document manageable, avoids overwhelming readers with unrelated
254|     detail, and makes the document easier to navigate.
255| 
256| 5. Writing Style Consistency
257| To keep BriteTest documentation clear and easy to read, maintain **parallel
258| structure** within lists and related sentences. In practice:
259| 
260| - Start list items with the same part of speech (typically a verb).
261| - Keep grammatical patterns consistent across bullets.
262| - Avoid mixing styles such as "Keep paragraphs short" with "Using lists for enumerations."
263| - Rewrite items as needed so the list reads smoothly and uniformly.
264| 
265| This guideline applies to all BriteTest documentation (.md files).
266| </details>
267| </details>
268| 
269| <details>
270| <summary>7. Pull Requests</summary>
271| 
272| ## 7. Pull Requests
273| 
274| Before submitting a PR:
275| 
276| - Ensure tests pass.
277| - Update version numbers if needed.
278| - Update documentation as needed.
279| - Keep changes focused and well‑scoped.
280| </details>
281| 
282| <details>
283| <summary>8. Branding</summary>
284| 
285| ## 8. Branding
286| 
287| This chapter discusses the choices for a brand description and name.
288| <details>
289| <summary>8.1. Alternative Brand Descriptions</summary>
290| 
291| ### 8.1. Alternative Brand Descriptions
292| 
293| BriteTest is a lightweight framework for defining, running, and reporting
294| tests in C/C++ projects. It provides a simple core macro-based Runner
295| Application Programming Interface (API), a function-based Test API,
296| fault‑tolerant execution, and clear reporting. It is ideal for small to
297| medium C projects that need reliable testing without heavy tooling and
298| dependencies. It can be used for unit and command-line testing.
299| 
300| Tghtened, clarified, and made more parallel to the tone you've been using
301| for LiteTest. Below is a refined version that reads cleaner, is more precise,
302| and positions the framework more strongly.
303| 
304| 
305| BriteTest is a lightweight framework for defining, running, and reporting tests
306| in C/C++ projects. It provides a compact macro‑based Runner API, a function‑driven
307| Test API, fault‑tolerant execution, and clear, structured reporting. The framework
308| is designed for small to medium C projects that need reliable automated testing
309| without the overhead of large toolchains or external dependencies.
310| 
311| BriteTest supports both unit testing and command‑line driven testing, making it
312| flexible enough for embedded utilities, libraries, and standalone executables.
313| 
314| under 350 characters, each with a slightly different tone. All stay formal and
315| suitable for a title‑page abstract.
316| 
317| ---
318| 
319| Option 1 — Concise & Technical
320| 
321| BriteTest is a lightweight C/C++ testing framework providing a macro‑based runner, function‑based tests, fault‑tolerant execution, and clear reporting. It enables reliable unit and command​‑line testing for small to medium C projects without heavy tooling dependencies.
322| 
323| ---
324| 
325| Option 2 — Clean & Professional
326| 
327| BriteTest is a compact C/C++ framework for defining, running, and reporting tests. It offers a simple macro runner, function‑style tests, robust fault handling, and readable output, ideal for small to medium C projects that need light‑weight, reliable testing.
328| 
329| ---
330| 
331| Option 3 — More Emphasis on Purpose
332| 
333| BriteTest is a minimal C/C++ test framework designed for fast, reliable unit and command‑line testing. Its macro‑based runner, function‑driven tests, and fault‑tolerant execution provide strong fundamentals for small to medium C projects without heavy dependencies.
334| 
335| </details>
336| 
337| <details>
338| <summary>8.2. Alternative Brand Names</summary>
339| 
339| ### 8.2. Alternative Brand Names
340| 
341| TODO: add these to table.
342| - briteTest (bT)
343| - CanaryRunner (CR)
343| - CanaryAssert (CA)
344| - CanaryProof (CP)
345| - CanaryTestRunner (CYR)
346| - OpenTest (OT)
347| 
348| These names are fallback options if a naming conflict requires a
349| brand/project rename.
350| 
351| These notes are an informal naming screen only. They are based on how generic,
352| descriptive, or commonly used the terms appear in software and testing. They
353| are not a trademark search or legal clearance.
354| 
355| | Name | Abbrev. | Informal conflict note | Likelihood |
356| |------|---------|------------------------|------------|
357| | LiteTest | LT | Clear and close to the project's lightweight positioning, but both `lite` and `test` are common software terms, so overlap with existing package or tool names is plausible. | Medium |
358| | briteTest | bT | Strong fit for the project brand with canary monogram, distinctive camelCase format, and clear semantic meaning. Low conflict likelihood. | Low |
359| | CanaryTest | CT | Strong fit for the canary theme, but `canary` and `canary testing` are already common software terms, which makes the name less distinctive. | Higher |
360| | CoreTest | CT | Clear and technical, but both `core` and `test` are common product words and may overlap with existing tools or internal packages. | Medium |
360| | ClearTest | CT | Readable and descriptive, but the name is broad and likely to overlap with existing testing or QA branding. | Medium |
361| | TinyTest | TT | Good match for a lightweight framework, but it is fairly descriptive and similar in shape to other small-test framework names. | Medium |
362| | TraceTest | TT | More distinctive than generic `test` compounds, though `trace` is still a common engineering term. | Medium-Low |
363| | SwiftTest | ST | Memorable, but `Swift` has strong existing association with Apple's Swift ecosystem, which could create confusion. | Higher |
364| | QuickTest | QT | Familiar and easy to say, but `QuickTest` has long-standing use in software testing and QA tooling. | Higher |
365| | CompactTest | CT | Fits the lightweight positioning and is somewhat more distinctive than `CoreTest` or `ClearTest`, though still descriptive. | Medium-Low |
366| | PublicTest | PT | Descriptive and understandable, but `public` is a common language and API term, which makes the name fairly broad. | Medium |
367| | APITest | AT | Directly describes API testing, but the term is highly generic and already widely used across tools, articles, and packages. | Higher |
368| | FastTest | FT | Strong performance-oriented signal, but `fast` and `test` are both generic terms and likely to overlap with existing tooling names. | Medium-High |
369| 
370| Preference among the candidates:
371| 
372| - `briteTest (bT)` for strong brand alignment and low naming conflict.
373| - `CompactTest (CT)` for a lower-conflict descriptive option.
373| - `TraceTest (TT)` for a more distinctive technical option.
374| - `CanaryTest (CT)` only if the canary theme is more important than name.
375
</details>

<details>
<summary>8.3. Brand Name and Tagline Replacement Workflow</summary>

### 8.3. Brand Name and Tagline Replacement Workflow

This workflow describes how to replace the brand name, tagline and other phrases
throughout the repository (docs, branding, and logos) using automated scripts.

#### Prerequisites

The replacement workflow depends on two configuration files and two scripts:

- **Configuration**: `docs/branding/brand.md`
  - Defines old-to-new phrase replacements.
  - Format: `**Replace**: old_phrase = new_phrase`
  - For a brand name change,it abbreviations is auto-generated from the
    first letter of each word.
  - Example: `LiteTest = briteTest` generates replacements for both 
   "LiteTest" → "briteTest" (phrase) and "LT" → "bT" (abbreviation)

- **Scripts**:
  - `scripts/updatelogos`: Updates SVG files in `docs/branding/` with phrase and abbreviation replacements, then regenerates PNG files
  - `scripts/replacephrases`: Updates markdown files (`*.md`) in `docs/` with phrase replacements only

#### Workflow Steps

1. Choose a replacement brand name and/or tagline plus any other phrases to
   be Initial definitions.

2. Update the brand configuration file `docs/branding/brand.md` to define
   the replacement (see this file for examples of previous changes):
```
### <change title>
<Reason for the change.>

 - **Replace**: old_phrase = new_phrase
...

   - The file supports multiple replacements (one per line).
   - Each replacement is validated to prevent circular references (an old phrase cannot match any new phrase).

3. Update SVG files and regenerate PNG files:
   - Run the `updatelogos` script:
```bash
scripts/updatelogos
```
   - The script performs the following:
     - Parses `docs/branding/brand.txt` for phrase and abbreviation replacements.
     - Applies **both phrase and abbreviation replacements** to all SVG files in `docs/branding/`, including tagline SVGs.
     - Regenerates all PNG files from the updated SVGs using `scripts/genpng.sh`.
     - Validates the configuration to prevent infinite loops (circular references).
     - Generates a detailed report of replacements and file modifications.
   - Review the output and documentation for accuracy, then commit the changes.

4. Update project identifier and repository name (optional:
   - Update references in CI/CD workflows, and external links.

5. Validate and test
  - Run `make run` to ensure tests pass.
  - Run `make pdf` or the PDF generation script to verify branding updates in generated documents.
  - Perform a repository-wide text search for stale old-brand references.
  - Verify that all SVG taglines have been updated correctly.

6. Commit and ship
   - Commit SVG/PNG changes with a clear commit message.
   - Commit markdown changes with a clear commit message.
   - Optionally, add a note to `README.md` in root directory documenting the brand transition.
   - Consider a separate release or major version bump if the rename is significant.
</details>
</details>

<details>
<summary>9. Glossary</summary>

## 9. Glossary

For a glossary of general BriteTest terms, see the Glossary Reference document.
For a glossary of terms, see the Glossary Reference (`Glossary_Reference.md`).

Contributor‑Specific Terms:

- **Approver**: A contributor with commit access who reviews pull requests, enforces versioning rules, and ensures documentation consistency.
- **Breaking Change**: A change that alters public API behavior, removes or renames macros, changes return semantics, or requires a major version bump.
- **Contributor**: A person submitting code, documentation, fixes, or improvements to BriteTest.
- **Deprecation**: A public API element marked for removal in a future major version, requiring documentation updates and migration guidance.
- **Documentation Update**: Any change to released BriteTest documentation requires incrementing the update version or, if an API major version is incremented, incrementing the major version and [...]
- **Internal API Change**: A change to an API's internals that does not affect public API users but may require updates to an Internal Guide or Internal Reference.
- **Major Increment**: A structural or conceptual overhaul of BriteTest that causes a breaking change.
- **Public API Change**: Any modification to the BriteTest Runner or Test API that requires a version bumpv.
- **Pull Request Scope**: A guideline requiring PRs to be focused, minimal, logically grouped, and not mixing unrelated changes.
- **Test Coverage Requirement**: The expectation that all changes to BriteTest include new tests (if adding behavior), updated tests (if modifying behavior), and no regressions.
</details>
