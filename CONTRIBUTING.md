# Contributor Guide

## Branching model

This repository uses a release-oriented branching model with protected `main` and `version` branches with unprotected 'targeted' and
'contributor` branches.

### Protected Branches

The following branches are protected:

- `main` branch
- `version` branches with names matching `v<M>.<m>.0`.
  For example,  `v1.0.0`, `v2.12.3`, `v99.99.0`.

These branches require pull requests and cannot be force-pushed or
deleted. A `version` branch must be created by an approver.

## Unproteted Branches

These branches can be created by a contributor.

### `targeted` Branches

When implementing a contributing for a specific `version` branch,
create your working `targeted` branch from that branch using one
of these formats:

- `dev/<short_name>-<target_version>`
- `fix/<short_name>-<target_version>`

Where:

- `<short_name>` is a brief lowercase descriptor using letters,
  numbers, and hyphens.
- `<target_version>` is the name of the base `version` bramch
   (for example. `v1.2.0`).

Examples: 

- `dev/auth-timeout-v1.4.0`
- `fix/ui-crash-v2.0.0`

If the contribution is re-target to a later `version` branch, rename
and rebase the branch to the new target `version` branch.

### `contributor` Branches

Contributor branches that are not based on `main` or `version` branch
and with branch name using one of these formats:

- `dev/<short_name>`
- `fix/<short_name>`

However, these branches must not be pushed or merged into protected
version branches.

## Base Branch Rules

- `main` is the base branch for `version` branch creation.
- A `version` branch PR should only accept changes from
  `targeted` branches that target the same `version` branch.

For example, a PR into `v1.7.0` must come from a `targeted` branch
ending in `-v1.7.0`.

## Pull Request Rules

- Use pull requests for all changes into `main` and `version` branches.
- For PRs into a `version` branch, source branch must:
  - start with `dev/` or `fix/`
  - end with `-v<M>.<m>.0` where v<M>.<m>.0 is name of the 'version'
    branch.

## Recommended workflow

1. Start from the `version` branch:
   - `git checkout v<M>.<m>.0`
   - `git pull origin v<M>.<m>.0`
2. Create a `targeted` version branch:
   - `git checkout -b dev/<short_name>-v<M>.<m>.0`
3. Implement changes and push your branch.
4. Open a PR into `v<M>.<m>.0`.

