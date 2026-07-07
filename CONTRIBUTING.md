# Contributor Guide

## Branching model

This repository uses a release-oriented branching model with protected `main` and protected version branches.

### Protected branches

The following branches are protected:

- `main`
- Version branches matching `v<major>.<minor>.<patch>` (for example: `v1.0.0`, `v2.12.3`, `v99.99.0`)

These protected branches require pull requests and cannot be force-pushed or deleted.

## Branch naming conventions

### Contributor version branches (unprotected)

When contributing to a specific protected version branch, create your working branch from that version branch using one of these formats:

- `dev/<short_name>-<target_version>`
- `fix/<short_name>-<target_version>`

Where:

- `<short_name>` is a brief lowercase descriptor using letters, numbers, and hyphens.
- `<target_version>` is the exact version string of the protected base branch (for example `v1.2.3`).

Examples:

- `dev/auth-timeout-v1.4.2`
- `fix/ui-crash-v2.0.1`

### Other contributor branches

Contributor branches that are not based on `main` or a protected version branch have no enforced naming convention. However, these branches must not be pushed or merged into protected version branches.

## Base branch rules

- `main` is the base branch for version branch creation.
- A version branch PR should only accept changes from contributor branches that target the same version.

For example, a PR into `v1.7.0` must come from a branch ending in `-v1.7.0`.

## Pull request rules

- Use pull requests for all changes into protected branches.
- For PRs into a version branch `vX.Y.Z`, source branch must:
  - start with `dev/` or `fix/`
  - end with `-vX.Y.Z`

## Recommended workflow

1. Start from the target protected version branch:
   - `git checkout vX.Y.Z`
   - `git pull origin vX.Y.Z`
2. Create a contributor version branch:
   - `git checkout -b dev/<short_name>-vX.Y.Z`
3. Implement changes and push your branch.
4. Open a PR into `vX.Y.Z`.

