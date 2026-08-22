# `<repo>/scripts/helpers/`

Directory containing helper modules and Git hooks used by scripts in `scripts/bin/`.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `<repo>/LICENSE`.

See `<repo>/README.md` for an introduction to briteTest.

## Files

### Core Helpers

**ckbranchname.sh**: Check the branch name.

**ckrole.sh**: Check role for the user.

**ckstyle.sh**: Internal style validation and report helper used by
`<repo>/scripts/bin/report`. Exposes `bt_ckstyle()`, validates documents,
headers, sources, scripts, directory guides, and version consistency, and
writes the latest `style-<datetime>.md` report.

**common.sh**: Shared output and branch-detection helpers.
- `bt_info()` - Print info message
- `bt_success()` - Print success message
- `bt_error_exit()` - Print error and exit
- `bt_get_current_branch()` - Get current branch name
- `ensure_hooks_installed()` - Verify/install Git hooks

**common_utils.sh**: Shared utility helpers.

**git_helpers.sh**: Shared branch lookup and resolution helpers.
- Branch validation functions
- Parent branch detection
- Protected branch checks

**github_helpers.sh**: Shared GitHub CLI pull-request lookup helpers.
- PR lookup and status functions
- Status check validation
- Approver verification

**install_git_hooks.sh**: Install git hooks.

**push_workflow.sh**: Shared branch publication and push-report workflow.

- Accepts prerequisite-validated context from `push` or the pushup engine.
- Checks remote state and writes push or push-preview reports.

**pushup_parent.sh**: Internal push-up engine used only by `pushup` to
validate policy and prepare the local parent commit before publication.

**rbac.sh**: check rbac.

**report_helpers.sh**: report geneation helpers.

**report_sync.sh**: sync reports.

**validation_helpers.sh**: validation helpers.

### Documentation Generation

**gendocx.sh**: Generate DOCX files from PDF sources.

**genpdf.sh**: Generate PDF files from Markdown sources.

### Utility Helpers

**health_report.sh**: Check report health.

**history_log.sh**: Shared branch-history markdown logging helpers.
- Log merge operations.
- Track branch modifications.

### Directory Guide

- **README.md**: This file.

## Subdirectories

**.githooks/**: Git hook files.
