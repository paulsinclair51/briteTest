# scripts/

Directory containing scripts.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `LICENSE` in the root directory.

For a script's usage information, execute the script using the `-h' option. For example,
```sh
ckbranch -h
```
See `README.md` in the root directory for an introduction to the project.

## Files

### Document and Brand Management:

- **ckdirectory_guides.sh**: Verifies that a subdirectory has the expected README.md
  directory guide and it conforms to the guidelines.

- **genalldocs.sh**: Regenerates all PDF and docx documentation in one command.
  
- **gendocx**: Generates DOCX documentation from PDF sources.

- **genpdf**: Builds PDF documentation from markdown sources with formatting and asset handling.

- **genpng.sh**: Regenerates branding PNG images from SVG sources in `docs/branding`.

- **replace_phrases.py**: Replaces phrases across markdown files using a replacement mapping.

- **replacephrases**: Convenience wrapper script to run `replace_phrases.py` with repository defaults.

- **test_genpdf.sh**: Runs validation tests for the `genpdf` workflow.

- **updatelogos**: Updates branding text/abbreviations in SVG logos, regenerates PNGs, and refreshes
  docs text.

### Branch Management:

- **branch**: Provides shared branch utility logic used by branch-management scripts.

- **ckversions.sh**: Verifies consistent versions across `docs/*.md` (excluding the `docs/README.md`
  directory guide),`include/*.h`, and `src/*.c` files.

- **ckbranch**: Validates branch naming, type rules, and branch-state consistency.

- **ckbranch_history**: Validates and audits branch history logging for correctness and completeness.

- **lsbranch**: Lists and summarizes branches with workflow-relevant metadata.

- **mkbranch**: Creates a new branch from a base branch with naming/type validation.

- **mkclone**: Creates a working clone/setup for repository workflows.

- **mkcommit**: Creates standardized commits with consistent messaging conventions.

- **mkcopy**: Cherry-picks/copies commits from the current branch to a target branch.

- **mkfeedback**: Helps process pull-request review feedback and coordinate follow-up updates.

- **mkmerge**: Performs guided merge operations with workflow checks and safeguards.

- **mkpullrequest**: Creates or updates a GitHub pull request for the current branch.

- **mkrebase**: Cnange tbe base branch of a branch to be another branch. For example,
  change feature-a based on v2.1.0 to be based on v2.2.0 (retarget the feature to a
  later minor release).

- **mkrelease**: Performs release workflow steps including version/tag/release handling.

- **mksync**: Synchronizes branch state with configured upstream/downstream refs.

- **mksyncup**: Synchronizes current branch changes upstream with optional automation steps.

- **mktest**: Runs tests and validation checks (including optional docs regeneration).

- **mkundo**: Safely undoes the most recent merge, release, or commit operation.

- **rmbranch**: Removes local and/or remote branches with validation and safeguards.

### Miscellaneous:

- **README.md**: This directory guide.

## Subdirectories

- None.
