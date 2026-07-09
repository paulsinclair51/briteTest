![Contributor Guide](/docs/branding/Contributor_Guide.png)

#### Version: v1.1.0

This document defines the contribution process, coding standards, documentation
rules, versioning guidelines, branch management, and validation workflows for 
contributors, reviewers, and approvers.

#### Copyright (c) 2026 Paul Sinclair

SPDX-License-Identifier: MIT

---

## Preface

This document is for contributors, reviewers, and approvers who need guidance 
on enhancing and maintaining briteTest.

For detailed script reference information, see the [Contributor_Reference.md](./Contributor_Reference.md).

### Document Version History

| Version | Date | Comment | Author/Editor |
|----------|------|---------|---------------|
| v1.1.0 | 2026-07-09 | Added validation workflows section and git operations guide | Paul Sinclair |
| v1.0.0 | 2026-06-11 | Initial version. | Paul Sinclair |

---

## Table of Contents

1. [Introduction](#introduction)
2. [Branching Model Overview](#branching-model-overview)
3. [Validation Workflows](#validation-workflows)
4. [Git Operations and Branch Management](#git-operations-and-branch-management)
5. [Versioning Guidelines](#versioning-guidelines)
6. [Branding](#branding)
7. [Documentation Guidelines](#documentation-guidelines)
8. [Code Guidelines](#code-guidelines)
9. [Testing Requirements](#testing-requirements)
10. [CODEOWNERS and Review Routing](#codeowners-and-review-routing)
11. [Making Modifications in a Branch](#making-modifications-in-a-branch)
12. [Pull Request (PR)](#pull-request-pr)
13. [Release](#release)
14. [Protected Branches](#protected-branches)

---

## Introduction

This Contributor Guide defines the expectations and rules for contributing to briteTest. It covers branching, versioning, testing, documentation, code style, validation workflows, pull requests, and release requirements.

Contributors should read this document before submitting changes, reviewing, or approving to ensure consistency across the code and documentation.

---

## Branching Model Overview

This repository uses a release-oriented branching model with four branch types:

**Protected Branches** (Require PR, no force-push, no deletion):
- `main` - Production-ready code
- `v<M>.<m>.0` - Version/release branches (e.g., v1.0.0, v2.1.0)

**Unprotected Branches** (Direct commits allowed, PRs encouraged):
- `dev/<desc>-<version>` or `fix/<desc>-<version>` - Targeted branches
- `[<type>/]<description>` - Contributor branches

**Valid Merge Paths:**
- contributor → contributor ✓
- contributor → targeted ✓
- targeted → version ✓ (with approver)
- version → main ✓ (with approver)
- main → any ✗ (create FROM main only)

---

## Validation Workflows

briteTest uses 12+ automated GitHub Actions workflows providing defense-in-depth validation across all git operations.

### Workflow Summary Dashboard

| Workflow | Purpose | Trigger | When Blocks |
|----------|---------|---------|------------|
| branch-validation-pull-request.yml | Validates branch relationships, naming, roles | PR events | Invalid merge path |
| branch-validation-merge.yml | Post-merge compliance audit logging | Push to protected | Audit trail only |
| branch-validation-commit-message.yml | Enforces conventional commit format | PR events | Invalid format |
| branch-validation-author.yml | Verifies approved commit authors | PR events | Unknown author |
| branch-validation-gpg-signature.yml | Requires GPG signatures on protected branches | PR to main/version | Unsigned commits |
| branch-validation-rebase.yml | Monitors rebase operations | Push events | Audit trail only |
| branch-validation-force-push.yml | Audits force push attempts | Push events | Blocked by GitHub |
| branch-validation-cherry-pick.yml | Detects cherry-pick operations | Push events | Cherry-pick to protected |
| branch-validation-file-changes.yml | Prevents critical file modifications | PR events | LICENSE, workflows modified |
| branch-validation-large-files.yml | Detects and blocks files > 10MB | Push events | File exceeds limit |
| branch-validation-secrets.yml | Prevents API keys and credentials | PR events | Secrets detected |
| branch-validation-workflow.yml | Validates GitHub workflow syntax | PR modifying workflows | Invalid syntax |
| branch-validation-license-headers.yml | Ensures MIT license headers | PR events | Missing headers |
| branch-validation-code-quality.yml | Runs linting and format checks | PR events | Formatting issues |
| branch-validation-tags.yml | Validates tag naming conventions | Tag creation | Invalid tag format |

### Primary Prevention Layer

These workflows run **BEFORE merge** to prevent problems:

✓ **Valid commits:** Allowed to proceed
✗ **Invalid commits:** PR blocked until fixed

**Examples of blocked commits:**
- Merge with wrong branch path (contributor→main)
- Commit message format: "Add feature" (missing type: prefix)
- File modification: LICENSE
- Secret detected: AWS API key in code
- Large file: 15MB binary uploaded

### Secondary Audit Layer

These workflows run **AFTER merge** for compliance logging:

✓ **Purpose:** Audit trail, monitoring, compliance
⚠ **Note:** Cannot prevent already-merged changes, but logs violations

**Examples of audited operations:**
- Rebase on version branch
- Force push attempt (blocked by GitHub anyway)
- Cherry-pick to non-protected branch
- Invalid tag creation

### Handling Validation Failures

**When a validation fails:**

1. **Read error message** - Explains what's wrong and how to fix
2. **Fix locally** - Make the required changes
3. **Re-push** - GitHub automatically re-runs validations
4. **Verify passing** - Green checkmark on PR before requesting review

---

## Git Operations and Branch Management

### Creating Branches

```bash
scripts/bin/mkbranch -r <branch_name> [<base_branch>]
```

**Examples:**
```bash
scripts/bin/mkbranch -r mywork/feature main
scripts/bin/mkbranch -r dev/parser-fix-v1.0.0 v1.0.0
scripts/bin/mkbranch -r fix/memory-leak-v1.0.0 v1.0.0
```

**Branch Naming Rules:**
- **Contributor:** `[<type>/]<description>` (e.g., `dev/json-parser`)
- **Targeted:** `dev/<desc>-<version>` or `fix/<desc>-<version>`
- **Version:** `v<M>.<m>.0` (created by approvers only)

### Making Changes

```bash
git checkout mywork/feature
# Edit files...
git add .
git commit -m "feat: add new capability"
git push origin mywork/feature
```

**Commit Best Practices:**
- Keep commits focused and logical
- Use conventional commit format: `<type>: <description>`
- Valid types: feat, fix, docs, style, refactor, test, chore

### Rebasing Your Branch

```bash
git rebase main
git push --force-with-lease origin mywork/feature
```

⚠ **Never rebase protected branches** - GitHub blocks force pushes anyway

### Deleting Branches

```bash
scripts/bin/rmbranch <branch_name>
```

Protected branches (main, v*.0) cannot be deleted.

---

## Versioning Guidelines

Versioning format: `M.m.p` (major, minor, patch)

- **Patch (e.g., 1.0.1):** Bug fixes, improvements, doc corrections
- **Minor (e.g., 1.1.0):** New features, backward compatible
- **Major (e.g., 2.0.0):** Breaking changes, incompatibilities

**Versioned files:**
- `include/runnerapi.h`, `src/runnerapi.c`
- `include/testapi.h`, `src/testapi.c`
- `docs/md/*.md` (except README.md)

Run `scripts/bin/ckversions` to validate consistency.

---

## Branding

- **Brand name:** briteTest
- **Distinctive camelCase** aligns with `bT` monogram
- Update branding with: `scripts/bin/updatebrand`

---

## Documentation Guidelines

- Root `README.md` remains short and onboarding-focused
- Technical tone: precise, neutral, clear
- Use backticks for code identifiers
- Use fenced code blocks for examples
- Maintain parallel structure in lists
- Define terms once, use consistently

---

## Code Guidelines

- C99 standard
- POSIX.1-2001 APIs only
- Keep headers self-contained
- Add MIT license header to new files

---

## Testing Requirements

```bash
make run
```

- Ensure all tests pass before opening PR
- Update tests when code changes
- Include test coverage for new features

---

## CODEOWNERS and Review Routing

- **Default owner:** `paulsinclair51`
- CODEOWNERS affects who is **requested** for review
- CODEOWNERS does **not** block merges alone
- Blocking depends on branch protection rules

See `.github/CODEOWNERS` for details.

---

## Making Modifications in a Branch

1. Create focused, logically grouped changes
2. Update documentation in parallel with code
3. Update version numbers in versioned files
4. Follow code and documentation guidelines
5. Include test coverage
6. Verify tests pass: `make run`

---

## Pull Request (PR)

### Pre-PR Checklist

- [ ] Changes are focused and logically grouped
- [ ] Documentation updated
- [ ] Version numbers updated (if needed)
- [ ] License headers on new files
- [ ] Tests pass: `make run`
- [ ] Commits follow conventional format
- [ ] No secrets or credentials
- [ ] No files > 10MB
- [ ] No protected file modifications

### Opening and Reviewing

1. Push your branch to repository
2. Open PR on GitHub with clear title and description
3. Verify base branch is correct (PR should target version or contributor branch, NOT main)
4. GitHub runs validation workflows automatically
5. Reviewers examine for quality, correctness, standards
6. Address feedback and re-push
7. Once approved and checks pass, approver merges

---

## Release

1. **Prepare:** Summary of changes, verify versions, ensure compatibility
2. **Validate:** `make run`, check for stale references
3. **Commit:** Clear message with version updates and release notes
4. **Tag:** `git tag v1.2.3` and push
5. **Publish:** Create GitHub release with notes

---

## Protected Branches

Protected branches require:
- ✓ Pull request before merging
- ✓ Status checks pass
- ✓ Approvals from code owners
- ✗ No force pushes
- ✗ No direct commits
- ✗ No deletions

### Pre-commit Hook

Prevent accidental commits to protected branches:

```bash
mkdir -p .git/hooks
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
CURRENT=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT" == "main" ]] || [[ "$CURRENT" == v*.0 ]]; then
  echo "Error: Cannot commit to protected branch '$CURRENT'"
  exit 1
fi
EOF
chmod +x .git/hooks/pre-commit
```

---

## Related Documents

- [Contributor_Reference.md](./Contributor_Reference.md) - Script reference and tools
- [README.md](../../README.md) - Project overview
