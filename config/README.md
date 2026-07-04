# config/

Directory containing repository configuration files.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `LICENSE` in the root directory.

See `README.md` in the root directory for an introduction to the project.

## Files

- **contributors.md**: Specifies the current contributors and whether they
  are also a reviewer or approver. See this file for details.

- **markdownlint.json**: Markdown lint configuration for this repository.
  Used by `make lint-md` in the project `Makefile`. See below for details.

- **README.md**: This directory guide.

## Subdirectories

- None.

## `markdownlint.json` Settings

Modifying or adding settings in this file should be avoided.

This configuration file customizes markdownlint behavior with the following
settings:

- **MD001 (heading increment)**: Disabled (default is enabled). Allows
  non-sequential heading level increments. This supports documentation that
  intentionally uses custom heading depth for visual structure.

- **MD041 (first-line heading)**: Disabled (default is enabled). Allows
  markdown files that intentionally do not start with a level-1 heading on the
  first line. Titles are provided by `docs/branding/<title>.svg` files.

- **MD013 (line length)**: Sets maximum line length to 120 characters (default
  is 80). Exempts code blocks and tables from the line-length rule. This is needed
  because the project includes extensive C code examples and documentation that
  would be unreadably fragmented at 80 characters, and code formatting should
  follow language conventions rather than markdown line-length limits.

- **MD029 (ordered list prefix)**: Disabled (default is enabled). Allows ordered
  lists to use flexible numbering instead of requiring all lists to start
  with `1.`. This provides flexibility in documentation structure where
  automatic numbering isn't desired.

- **MD033 (no HTML)**: Disabled (default is enabled). Allows embedded HTML
  in markdown files. This is needed for documentation that uses HTML tags
  `<details>...</details>` and `<summary>...</summary>` for collapsible
  sections, `<br>` for line breaks, and `&nbsp;` for no-breaking space to
  improve readability and navigation of lengthy guides. Use of HTML in documentation beyond these should be avoided.
