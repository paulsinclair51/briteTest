# scripts/

Directory for automation scripts.

Copyright (c) 2026 Paul Sinclair   
SPDX-License-Identifier: MIT   
For license details, see `LICENSE` in the root directory.

See `README.md` in the root directory for an introduction to the project.

## Files

- **check_directory_readmes.sh**: Validate that subdirectories (except
  `../.github/`) contain `README.md` files that follow the standardized
  directory README format. Run `check_directory_readmes.sh` to validate
  locally.

- **check_major_release_consistency.sh**: Validate that docs markdown files
  (excluding `docs/README.md`), `include/*.h`, and `src/*.c` are aligned on
  the same major release value. Run `check_major_release_consistency.sh` to
  validate locally.

- **genalldocs.sh**: Generate all documentation PDFs by invoking `genpdf`
  once per document (`README.md` and `docs/*.md`) into `docs/pdf/`.
  Run `genalldocs.sh --help` for usage information.

- **genpdf**: Convert Markdown Documentation (`.md`) to Portable Document
  Format (`.pdf`), after removing lines with details/summary tags and applying
  formatting for PDF output. Run `genpdf --help` for usage information.

- **genpng.sh**: Generate all branding PNGs from `docs/branding/*.svg`.
  Run `genpng.sh --help` for usage information.

- **test_genpdf.sh**: Lightweight self-test for `genpdf`. Run
  `test_genpdf.sh --help` for usage information.

- **README.md**: This directory guide.

## Subdirectories

- None.
