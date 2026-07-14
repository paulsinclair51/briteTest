![Contributor Guide](/docs/branding/Contributor_Guide.png)

#### Version: v1.0.0

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

For an in-depth analysis of the SCM system, see [SCM_REVIEW.md](../SCM_REVIEW.md).

### Document Version History

| Version | Date | Comment | Author/Editor |
|----------|------|---------|---------------|
| v1.0.0 | 2026-07-13 | Current v1.0.0 development guide; refreshed script coverage to match current `scripts/bin/` set (including `rmclone` and `fixrepo` clone-path checks). | Paul Sinclair |

---

## Table of Contents

1. [Introduction](#introduction)
2. [Branching Model Overview](#branching-model-overview)
3. [Validation Workflows](#validation-workflows)
4. [Git Operations and Branch Management](#git-operations-and-branch-management)
5. [Access Control & Roles](#access-control--roles)
6. [Public Repository Security](#public-repository-security)
7. [GPG Signing Setup](#gpg-signing-setup)
8. [Versioning Guidelines](#versioning-guidelines)
9. [Branding](#branding)
10. [Documentation Guidelines](#documentation-guidelines)
11. [Code Guidelines](#code-guidelines)
12. [Testing Requirements](#testing-requirements)
13. [CODEOWNERS and Review Routing](#codeowners-and-review-routing)
14. [Making Modifications in a Branch](#making-modifications-in-a-branch)
15. [Pull Request (PR)](#pull-request-pr)
16. [Release](#release)
17. [Protected Branches](#protected-branches)
18. [Troubleshooting FAQ](#troubleshooting-faq)
19. [Team Onboarding Checklist](#team-onboarding-checklist)

---

## Introduction

This Contributor Guide defines the expectations and rules for contributing to briteTest. It covers branching, versioning, testing, documentation, code style, validation workflows, pull requests, and release requirements.

Contributors should read this document before submitting changes, reviewing, or approving to ensure consistency across the code and documentation.

### Current Scripts (scripts/bin)

The current executable script set is maintained in `scripts/bin/README.md`.

- **Setup/installation:** `installscripts`
- **Document/brand:** `ckstyle`, `gendocs`, `genpngs`, `replacephrases`, `updatebrand`
- **Repository/fork/clone:** `mkfork`, `mkclone`, `rmclone`, `fixrepo`
- **Branch/workflow:** `ckbranch_history`, `chcurrent`, `lsbranch`, `mkbranch`, `commit`, `copyfix`, `mkfeedback`, `mergetoparent`, `mkpullrequest`, `chtarget`, `mkrelease`, `syncfromremote`, `syncfromparent`, `undo`, `rmbranch`

---

## Branching Model Overview

This repository uses a release-oriented branching model with four branch types:

**Protected Branches** (Require PR, no force-push, no deletion):
- `main` - Production-ready code (remote-only; use `origin/main` for Git commands)
- `v<M>.<m>.0` - Version/release branches (e.g., v1.0.0, v2.1.0)

**Unprotected Branches** (Direct commits allowed, PRs encouraged):
- `dev/<desc>-<version>` or `fix/<desc>-<version>` - Targeted branches
- `[<type>/]<description>` - Contributor branches

**Valid Merge Paths:**
- contributor → contributor ✓
- contributor → targeted ✓
- targeted → version ✓ (with approver)
- version → main ✓ (with approver, via `origin/main`)
- main → any ✗ (reference `origin/main` only; do not create a local `main`)

---

## Validation Workflows

briteTest uses 15 automated GitHub Actions workflows providing defense-in-depth validation across all git operations.

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
git rebase origin/main
git push --force-with-lease origin mywork/feature
```

⚠ **Never rebase protected branches** - GitHub blocks force pushes anyway

### Deleting Branches

```bash
scripts/bin/rmbranch <branch_name>
```

Protected branches (`main` as the remote-only base and `v*.0`) cannot be deleted.

### Setting Up Pre-commit Hooks

Prevent accidental commits to protected branches:

```bash
mkdir -p .git/hooks
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
CURRENT=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT" == "main" ]] || [[ "$CURRENT" == v*.0 ]]; then
  echo "❌ Error: Cannot commit directly to protected branch '$CURRENT'"
  echo "Create a feature branch: scripts/bin/mkbranch -r <name> $CURRENT"
  exit 1
fi
EOF
chmod +x .git/hooks/pre-commit
```

---

## Access Control & Roles

briteTest uses a six-tier access model for public repository safety:

| Tier | Core Capabilities | Restrictions |
|------|-------------------|--------------| 
| **PUBLIC** | Read, clone, fork | No write access |
| **USERS** (read-only collaborator) | Read all repository content | No push, PR, or script execution |
| **CONTRIBUTOR (C)** | Create branches, commit, open PRs, run contributor scripts | Cannot merge/release/protected-script operations |
| **REVIEWER (R)** | All contributor actions plus review/rebase workflows | Cannot run approver-only scripts |
| **APPROVER (A)** | Merge, release, run protected scripts with override confirmation | Must follow audit and override controls |
| **MAINTAINER** | Repository admin and access management | Responsible for governance and audits |

**Write access is script-controlled** (`mkbranch`, `commit`, `mkpullrequest`, `mergetoparent`, `chtarget`, `mkrelease`) rather than direct protected-branch git operations.

### Identity Prerequisites for Role-Gated Scripts

Role-gated scripts (for example `mergetoparent` and `mkrelease`) require a
resolvable GitHub login that matches an entry in `config/contributors.md`.

Configure at least one of these identity sources:

- `GITHUB_ACTOR` set to your GitHub login
- `gh auth login` completed in your environment
- `git config user.name <github-login>` using your GitHub login (not display name)

If identity cannot be resolved, role checks fail by design.

---

## Public Repository Security

Security controls expected for contributor workflows:

- **Branch protection:** `main` and `v*.0` require PRs, reviews, and status checks.
- **Secret prevention:** never commit credentials, tokens, or keys; use repository secret scanning and validation workflows.
- **Critical file protection:** avoid direct changes to protected areas (`.github/workflows/`, policy/security files) unless explicitly required and approved.
- **Signed provenance:** use GPG signing for protected-branch commits.
- **Vulnerability reporting:** report security concerns via the repository security policy (`.github/SECURITY.md`) rather than public issue disclosure.
- **Auditability:** approver-level actions and protected operations must remain traceable through workflow/script logs.

Keep this section aligned with repository policy whenever workflows or branch protections change.

---

## GPG Signing Setup

For commits to protected branches (main and version branches), GPG signatures are required.

### Linux/Mac Setup

**1. Generate GPG Key**

```bash
gpg --gen-key
```

Respond to prompts:
- Kind: RSA and RSA (default)
- Size: 4096 bits (recommended)
- Valid for: 2y (or as desired)
- Name: Your name
- Email: Your GitHub email
- Comment: (optional)

**2. List Your Keys**

```bash
gpg --list-secret-keys --keyid-format=long
```

Output looks like:
```
sec   rsa4096/3AA5C34371567BD2 2016-03-10 [SC] [expires: 2017-03-10]
      27D6D3E4F2B0D16F
uid                 [ultimate] Hubot <hubot@example.com>
ssb   rsa4096/42B6315D7637C87E 2016-03-10 [E] [expires: 2017-03-10]
```

Your key ID is after `rsa4096/` - in this example: `3AA5C34371567BD2`

**3. Configure Git**

```bash
# Set key ID for all commits
git config --global user.signingkey 3AA5C34371567BD2

# Sign commits by default
git config --global commit.gpgsign true
```

**4. Add to GitHub**

```bash
# Export public key
gpg --armor --export 3AA5C34371567BD2
```

Copy the output and add to GitHub:
- Go to Settings → SSH and GPG keys
- Click "New GPG key"
- Paste the key
- Confirm

### Windows Setup

**1. Install GPG**

Download from https://www.gnupg.org/download/

**2. Generate Key**

Use Windows PowerShell:
```powershell
gpg --gen-key
```

Follow same steps as Linux/Mac (above)

**3. Configure Git**

Tell Git to use gpg.exe:
```powershell
git config --global gpg.program "C:\Program Files (x86)\GNU\GnuPG\bin\gpg.exe"
git config --global user.signingkey <YOUR_KEY_ID>
git config --global commit.gpgsign true
```

### Signing Commits

Once configured, commits are automatically signed:

```bash
git commit -m "feat: add feature"  # Automatically signed
```

Or sign manually:

```bash
git commit -S -m "feat: add feature"
```

### Troubleshooting GPG

**Error: "gpg failed to sign"

Try:
```bash
# Reload GPG agent
gpg-connect-agent updatestartuptty /bye

# Or restart agent
killall gpg-agent
```

**Key not found**

Verify key exists:
```bash
gpg --list-secret-keys
```

**GitHub doesn't show verified badge**

- Verify public key is added to GitHub
- Verify commit email matches GitHub account email
- Wait a few seconds (GitHub takes time to verify)

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

Use `make test-all-scripts` before PRs, and verify versioned file edits in `git diff`.

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

The protected base branch is `origin/main`; version branches are local protected branches.
Neither may receive direct commits.
Updates are made through `scripts/bin/mergetoparent` only:

- Use `scripts/bin/syncfromparent` (or equivalent) in the source branch first
- Resolve conflicts in the source branch before running `mergetoparent`
- Merge to protected parent using `mergetoparent`
- When the parent is protected, approver role is required

---

## Troubleshooting FAQ

### Validation Failures

**Q: "Commit message format is invalid"

**A:** Use conventional format: `<type>: <description>`
```bash
# ❌ Wrong
git commit -m "Add new feature"

# ✅ Correct
git commit -m "feat: add new feature"
```

Valid types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

**Q: "File size exceeds 10MB"

**A:** Don't commit large binary files. Use Git LFS instead:
```bash
# Install Git LFS
git lfs install

# Track large files
git lfs track "*.bin"
git add .gitattributes
```

**Q: "Protected file cannot be modified"

**A:** Don't modify LICENSE, SECURITY.md, or .github/workflows/ unless approved.
For legitimate changes, contact the repository owner.

**Q: "Secrets detected in code"

**A:** Remove credentials immediately:
```bash
# Remove the file from history
git filter-repo --path <file> --invert-paths

# Rotate/regenerate the credential
# (password, API key, token, etc.)
```

**Q: "License headers missing"

**A:** Add MIT license header to new source files:
```c
// Copyright (c) 2026 Paul Sinclair
// SPDX-License-Identifier: MIT
```

### Git Operations

**Q: "I accidentally committed to main"

**A:** Don't panic. Contact repository owner. Main is protected so direct commits should fail.

**Q: "Role-gated script says it cannot determine GitHub login identity"

**A:** Configure one of the supported identity sources:
```bash
# Option 1: Environment identity
export GITHUB_ACTOR=<your-github-login>

# Option 2: GitHub CLI authentication
gh auth login

# Option 3: Git identity mapped to GitHub login
git config user.name <your-github-login>
```

**Q: "How do I undo the last commit?"

**A:** If not pushed:
```bash
git reset --soft HEAD~1  # Keep changes
git reset --hard HEAD~1  # Discard changes
```

**Q: "How do I update my branch with latest main?"

**A:**
```bash
git fetch origin
git rebase origin/main
git push --force-with-lease origin <branch>
```

**Q: "Can I delete a branch?"

**A:** Use the safe deletion script:
```bash
scripts/bin/rmbranch <branch_name>
```

Protected branches (main, v*.0) cannot be deleted.

### Merge and Reviews

**Q: "PR is blocked by validation checks"

**A:** Look at the failing check:
1. Click on the red X next to the workflow
2. Read the error message
3. Fix locally
4. Re-push (validation runs automatically)

**Q: "Reviewer requested changes, what do I do?"

**A:**
1. Read the review comments
2. Make the requested changes
3. Commit and push
4. Comment: "Updated. Ready for re-review."
5. Re-request review

**Q: "My PR has been merged, how do I get local changes?"

**A:**
```bash
git fetch origin
git pull origin main  # or version branch
```

---

## Team Onboarding Checklist

For new contributors to briteTest:

### Before First Commit

- [ ] **Read the Contributor Guide** (this document)
- [ ] **Read Contributor Reference** for script details
- [ ] **Clone the repository**
  ```bash
  git clone https://github.com/paulsinclair51/briteTest.git
  cd briteTest
  ```
- [ ] **Set up Git configuration**
  ```bash
  git config user.name "your-github-login"
  git config user.email "your.email@example.com"
  ```
- [ ] **Authenticate GitHub CLI (recommended for role-gated scripts)**
  ```bash
  gh auth login
  ```
- [ ] **Set up GPG signing** (see [GPG Signing Setup](#gpg-signing-setup) section)
- [ ] **Set up pre-commit hook** (see [Setting Up Pre-commit Hooks](#setting-up-pre-commit-hooks) section)
- [ ] **Verify Git configuration**
  ```bash
  git config --global --list
  ```

### First Contribution

- [ ] **Pick a task** (start with something small)
- [ ] **Create a branch**
  ```bash
  scripts/bin/mkbranch -r mywork/description main
  ```
- [ ] **Make changes**
  ```bash
  git checkout mywork/description
  # Edit files...
  ```
- [ ] **Test locally**
  ```bash
  make run  # Ensure all tests pass
  ```
- [ ] **Check branch naming**
  ```bash
  bash scripts/helpers/ckbranchname.sh mywork/description
  # Should return exit code 4 (contributor branch)
  ```
- [ ] **Commit with conventional format**
  ```bash
  git add .
  git commit -m "feat: add new feature"
  # Will be GPG signed automatically
  ```
- [ ] **Push your branch**
  ```bash
  git push origin mywork/description
  ```
- [ ] **Open a Pull Request on GitHub**
  - Go to https://github.com/paulsinclair51/briteTest
  - Click "New Pull Request"
  - Select your branch as source
  - Select main (or appropriate base branch) as target
  - Fill in title and description
  - Submit
- [ ] **Wait for validation**
  - GitHub runs 15+ workflows automatically
  - All should pass with green checkmarks
  - If any fail, fix locally and re-push
- [ ] **Request review**
  - Assign reviewer if applicable
  - Request review from `@paulsinclair51`
- [ ] **Respond to feedback**
  - Read review comments
  - Make requested changes
  - Re-push
  - Re-request review
- [ ] **Celebrate merge**
  - Once approved and checks pass, approver merges
  - Your contribution is now in the codebase!

### Quick Reference

Common commands:
```bash
# Create branch
scripts/bin/mkbranch -r mywork/feature main

# Switch to branch
git checkout mywork/feature

# Make changes and commit
git add .
git commit -m "feat: description"

# Push to GitHub
git push origin mywork/feature

# Validate branch name
bash scripts/helpers/ckbranchname.sh mywork/feature

# Run tests
make run

# Delete branch
scripts/bin/rmbranch mywork/feature
```

### Getting Help

- **This guide:** `docs/md/Contributor_Guide.md`
- **Script reference:** `docs/md/Contributor_Reference.md`
- **SCM deep dive:** `docs/SCM_REVIEW.md`
- **Issue:** Open an issue on GitHub
- **Question:** Start a discussion on GitHub Discussions

---

## Related Documents

- [Contributor_Reference.md](./Contributor_Reference.md) - Script reference and tools
- [SCM_REVIEW.md](../SCM_REVIEW.md) - Detailed SCM system analysis
- [README.md](../../README.md) - Project overview
