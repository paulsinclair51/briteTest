# `<repo>/briteRepo/helpers/`

Directory containing helper modules and Git hooks used by scripts in `briteRepo/bin/`.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `<repo>/LICENSE`.

See `<repo>/README.md` for an introduction to the repository.

## Internal use only

Helpers are internal implementation modules. They are not user-facing commands
and are not directly executable: none of them carry the executable bit, and each
one refuses to run outside a briteRepo command.

Two enforcement patterns are used:

- **Sourced libraries** (`branch_status.sh`, `ckstyle.sh`, `common.sh`,
  `common_utils.sh`, `git_helpers.sh`, `github_helpers.sh`, `health_report.sh`,
  `history_log.sh`, `pulldown_workflow.sh`, `push_command.sh`,
  `push_workflow.sh`, `report_helpers.sh`, `report_sync.sh`,
  `validation_helpers.sh`) exit with an error if executed instead of sourced.
- **Delegated command implementations** refuse to start unless the calling
  command identifies itself: `pushup_parent.sh` (`--pushup`) uses an entry-mode
  argument; `ckrole.sh`, `gendocx.sh`, and `genpdf.sh` require the caller to set
  `BRITEREPO_INTERNAL=1`.

A user-facing command owns its own usage text and argument validation; the
library it sources owns the work and reports failures back through exit codes.
`lsbranch` and `report` share `branch_status.sh`; `pulldown` and `pushup` share
`pulldown_workflow.sh`; `push` and `pushup` share `push_command.sh`. Commands
that must not inherit a library's function definitions call the library from a
subshell.

`install_git_hooks.sh` is the one documented exception: it is a setup utility
invoked by `briteRepo/bin/setupclone` and by the `post-checkout` hook, and it
may be run directly during clone repair.

## Files

### Core Helpers

**ckbranchname.sh**: Check the branch name.

**ckrole.sh**: Check role for the user.

**ckstyle.sh**: Internal style validation and report helper used by
`<repo>/briteRepo/bin/report`. Exposes `bt_ckstyle()`, validates documents,
headers, sources, scripts, directory guides, and version consistency, and
writes the latest `style-<datetime>.md` report.

**common.sh**: Shared output and branch-detection helpers.
- `bt_info()` - Print info message.
- `bt_success()` - Print success message.
- `bt_error_exit()` - Print error and exit.
- `bt_get_current_branch()` - Get the user-facing current branch name.
- `bt_get_current_branch_raw()` - Get the actual checked-out branch or HEAD.
- `bt_get_current_branch_for_repo()` - Get a normalized branch name for a repo path.
- `bt_is_internal_remote_copy()` - Detect an internal `r-<branch>` snapshot branch.
- `bt_is_current_internal_remote_copy()` - Detect the current internal snapshot.
- `ensure_hooks_installed()` - Verify/install Git hooks.

**common_utils.sh**: Shared utility helpers.

**git_helpers.sh**: Shared branch lookup and resolution helpers.
- Branch validation functions.
- Parent branch detection.
- Protected branch checks.

**github_helpers.sh**: Shared GitHub CLI pull-request lookup helpers.
- PR lookup and status functions.
- Status check validation.
- Approver verification.

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

**gendocx.sh**: Internal helper used by `gendocs` to generate DOCX files from
PDF sources. It is not a primary user-facing command.

**genpdf.sh**: Internal helper used by `gendocs` to generate PDF files from
Markdown sources. It is not a primary user-facing command.

### Utility Helpers

**health_report.sh**: Check report health.

**history_log.sh**: Shared branch-history markdown logging helpers.
- Log merge operations.
- Track branch modifications.

### Directory Guide

- **README.md**: This file.

## Subdirectories

**.githooks/**: Git hook files.
