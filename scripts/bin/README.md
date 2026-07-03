# scripts/bin/

Directory containing contributor command scripts.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `LICENSE` in the root directory.

See `README.md` in the root directory for an introduction to the project.

## Files

### Document and Brand Management

- **ckdirectory_guides**: Validate required directory guides across the repository.
- **gendocs**: Generate PDF and DOCX documentation.
- **genpngs**: Generate branding PNG images from SVG files.
- **replacephrases**: Apply configured phrase replacements in markdown files.
- **updatebrand**: Update branding text and regenerate related assets.

### Branch and Workflow Management

- **ckbranch**: Check branch and repository status.
- **ckbranch_history**: Query branch history log entries.
- **ckversions**: Validate version consistency across docs/include/src.
- **lsbranch**: List branches with filtering and formatting options.
- **mkbranch**: Create branches with policy validation.
- **mkclone**: Clone the repository with optional target naming.
- **mkcommit**: Commit and optionally push changes.
- **mkcopy**: Cherry-pick/copy commits from another branch.
- **mkfeedback**: View/respond to PR feedback workflows.
- **mkmerge**: Merge current branch to its base branch.
- **mkpullrequest**: Create or update a pull request.
- **mkrebase**: Rebase current branch to a new base branch.
- **mkrelease**: Create and publish releases.
- **mksync**: Fetch and pull latest changes.
- **mksyncup**: Merge base branch into current branch.
- **mktest**: Run tests and optional documentation checks.
- **mkundo**: Undo recent merge/release/commit operations.
- **rmbranch**: Remove local and/or remote branches.

## Subdirectories

- None.

## Adding Scripts to PATH

To make scripts available by name and persist for Bash, run from
anywhere inside this repository:

```sh
repo_root="$(git rev-parse --show-toplevel)"
repo_bin="$repo_root/scripts/bin"
line="export PATH=\"$repo_bin:\$PATH\""
grep -qxF "$line" ~/.bashrc || echo "$line" >> ~/.bashrc
source ~/.bashrc
```

If you run this outside a Git repository, set the repository root
explicitly:

```sh
repo_root="/absolute/path/to/briteTest"
repo_bin="$repo_root/scripts/bin"
line="export PATH=\"$repo_bin:\$PATH\""
grep -qxF "$line" ~/.bashrc || echo "$line" >> ~/.bashrc
source ~/.bashrc
```

## Script Usage

For a script's usage information, execute the script using the `-h` option. For example,

```sh
ckbranch -h
```

## Troubleshooting

If a script is not executable in your environment, run:

```sh
chmod +x scripts/bin/<script_name>
```
