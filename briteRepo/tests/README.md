# `<repo>/briteRepo/tests/`

Directory containing script tests.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `<repo>/LICENSE`.

See `<repo>/README.md` for an introduction to the repository.

This directory stores tests for user-facing commands in `<repo>/briteRepo/bin/`.
These tests are intended to quickly verify key CLI behavior, exit codes,
and high-signal output contracts for the scripts.

## Files

**test_*.sh**: miscellaneous test helpers for policy, propagation, and
fixlocal core/remote/retention.

**test_\<bin_script\>.sh**: Smoke tests for a script in
`<repo>/briteRepo/bin/` covering help output, verified cleanup,
report summaries, and repository layout skip behavior.

**test_commit_lib.sh**: Smoke tests for `<repo>/briteRepo/bin/fixrepo`
covering help output, verified cleanup, report summaries, and script behavior
layout skip behavior.

**test_fixlocal_lib.sh**: Smoke tests for `<repo>/briteRepo/bin/fixrepo`
covering help output, verified cleanup, report summaries, and script behavior
layout skip behavior.

**test_report_helpers.sh**: Focused tests for
`<repo>/briteRepo/helpers/report_helpers.sh` covering exact deleted-report
tracking, read-only enforcement, exact staged-path persistence, and
local-only fallback when push is unavailable.
Included automatically by `test_scripts.sh`.

**test_scripts.sh**: Script-test orchestrator that runs all `test_*.sh`
scripts in this directory (except itself), with stop-on-failure and
continue-on-failure modes.

**README.md**: This directory guide.

## Subdirectories

None.

## Running Tests

From repository root:

```sh
make test-lsbranch
make test-gendocs
make test-fixrepo
make test-mkbranch
make test-pulldown
make test-pushup
make test-pushup-parent
make test-report-helpers
make test-all-scripts
```

Or run directly:

```sh
bash ./briteRepo/tests/test_lsbranch.sh
bash ./briteRepo/tests/test_gendocs.sh
bash ./briteRepo/tests/test_fixrepo.sh
bash ./briteRepo/tests/test_mkbranch.sh
bash ./briteRepo/tests/test_pulldown.sh
bash ./briteRepo/tests/test_retarget.sh
bash ./briteRepo/tests/test_undo.sh
bash ./briteRepo/tests/test_commit.sh
bash ./briteRepo/tests/test_report_helpers.sh
bash ./briteRepo/tests/test_scripts.sh
```
