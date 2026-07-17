# Public Repository Security Guide

#### Version: v1.0.0
#### Date: 2026-07-09
#### Copyright (c) 2026 Paul Sinclair

SPDX-License-Identifier: MIT

---

## Overview

This guide covers security best practices for briteTest as a **public open-source repository**. It covers branch protection, secret management, code quality, and vulnerability handling.

---

## Branch Protection Rules

### Required GitHub Configuration

#### main Branch

**Status Checks:**
- ✅ All 15 `branch-validation-*` workflows must pass
- ✅ Require status checks to pass before merging
- ✅ Require branches to be up to date before merging

**Pull Request Reviews:**
- ✅ Require at least 1 approval
- ✅ Dismiss stale pull request approvals when new commits pushed
- ✅ Require code owner approval (via `.github/CODEOWNERS`)
- ✅ Require review from designated code owners

**Restrictions:**
- ✅ Restrict who can push to matching branches (Approvers only)
- ✅ Block force pushes
- ✅ Block deletions
- ✅ Require linear history (if desired)

**Auto-merge:**
- ✅ Allow auto-merge (GitHub actions can merge when ready)

**Dismissal:**
- ✅ Enforce dismissal of stale reviews when new commits are pushed

#### Version Branches (v*.0)

**Same rules as main:**
- ✅ All status checks must pass
- ✅ At least 1 approval required
- ✅ Code owner review required
- ✅ Only Approvers can push
- ✅ No force pushes or deletions

---

## Secret Management

### Secrets That Must NEVER Be Committed

#### API Keys & Tokens

```yaml
GitHub Personal Access Tokens:
  Format: ghp_[0-9a-zA-Z]{36,255}
  Example: ghp_1234567890abcdefghijklmnopqrstuvwxyz

GitHub OAuth Tokens:
  Format: gho_[0-9a-zA-Z]{36,255}
  Example: gho_1234567890abcdefghijklmnopqrstuvwxyz

AWS Access Keys:
  Format: AKIA[0-9A-Z]{16}
  Example: AKIAIOSFODNN7EXAMPLE

AWS Secret Access Keys:
  Pattern: aws_secret_access_key or aws_secret_key
```

#### Cryptographic Material

```yaml
RSA Private Keys:
  Pattern: -----BEGIN RSA PRIVATE KEY-----
  
SSH Private Keys:
  Pattern: -----BEGIN OPENSSH PRIVATE KEY-----
  
PGP Private Keys:
  Pattern: -----BEGIN PGP PRIVATE KEY BLOCK-----
```

#### Credentials

```yaml
Database Passwords:
  Pattern: password[=:].*
  
API Passwords:
  Pattern: apikey or api_key or api_password
  
Database URLs:
  Pattern: mongodb://user:pass@host
           postgres://user:pass@host
```

### Automated Detection

**Workflow:** `branch-validation-secrets.yml`
- Scans every PR for secret patterns
- Blocks merge if secrets detected
- Provides remediation instructions

**Patterns Checked:**
- Private keys (RSA, SSH, PGP)
- AWS credentials
- GitHub tokens
- Generic API keys
- Password assignments

### If Secrets Are Committed

**IMMEDIATE ACTIONS:**
1. **Do NOT merge the PR** - Secrets are already exposed
2. **Rotate the secret immediately** - Regenerate API key, change password
3. **Remove from history:**
   ```bash
   git filter-repo --path <file>  # Remove from all commits
   git push -f origin main        # Force push (approver override)
   ```
4. **Audit logs** - Check if secret was used
5. **Report incident** - Document in security log

**Prevention:**
- Use GitHub's secret scanning
- Configure pre-commit hooks (see CONTRIBUTING.md)
- Never paste secrets in issues or PRs
- Use environment variables, not hardcoded values

---

## Code Quality & Security Scanning

### Enabled Workflows

**Validation Workflows (10 Prevention):**
- ✅ branch-validation-pull-request
- ✅ branch-validation-commit-message
- ✅ branch-validation-gpg-signature
- ✅ branch-validation-file-changes
- ✅ branch-validation-secrets
- ✅ branch-validation-code-quality
- ✅ branch-validation-large-files
- ✅ branch-validation-license-headers
- ✅ branch-validation-workflow
- ✅ branch-validation-author

**Audit Workflows (5 Compliance):**
- ✅ branch-validation-merge
- ✅ branch-validation-rebase
- ✅ branch-validation-force-push
- ✅ branch-validation-cherry-pick
- ✅ branch-validation-tags

### Recommended Additional Scanning

**Dependabot (Dependency Updates):**
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: pip
    directory: "/"
    schedule:
      interval: weekly
```

**CodeQL (Security Analysis):**
```yaml
# .github/workflows/codeql-analysis.yml
name: CodeQL Analysis
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: github/codeql-action/init@v2
      - uses: github/codeql-action/analyze@v2
```

**SAST (Static Application Security Testing):**
- Consider adding cppcheck for C/C++ analysis
- Add shellcheck for shell script analysis

---

## Vulnerability Reporting

### Security Policy (.github/SECURITY.md)

When going public, create `.github/SECURITY.md`:

```markdown
# Security Policy

## Reporting Security Vulnerabilities

**DO NOT** create a public GitHub issue for security vulnerabilities.

Instead, email: 16927624+paulsinclair51@users.noreply.github.com

Please include:
1. Description of the vulnerability
2. Steps to reproduce
3. Potential impact
4. Suggested fix (if you have one)

Response timeline:
- Initial response: Within 48 hours
- Security fix: Within 7 days
- Public disclosure: Coordinated with reporter

## Scope

This security policy applies to:
- Source code in src/ and include/
- Build scripts and automation
- Documentation that affects security

## Out of Scope

- Documentation typos or clarity issues
- Feature requests or enhancement suggestions
- General code quality improvements
```

---

## File Protection

### Critical Files (Cannot be modified via PR)

**Protected from modification:**
- `LICENSE` - MIT License
- `.github/SECURITY.md` - Security policy
- `.github/CODEOWNERS` - Code ownership
- `.github/workflows/*.yml` - CI/CD workflows
- `config/contributors.md` - Team roster (read/write requires Approver)

**Protection Mechanism:**
- Workflow: `branch-validation-file-changes.yml`
- Blocks PRs that modify protected files
- Requires special approval for changes

### License Headers

**All source files must have MIT header:**

```c
// Copyright (c) 2026 Paul Sinclair
// SPDX-License-Identifier: MIT
// For license details, see '<repo>/LICENSE'.
```

**Check:** `branch-validation-license-headers.yml`

---

## Code of Conduct

Create `.github/CODE_OF_CONDUCT.md`:

```markdown
# Code of Conduct

## Our Pledge

We are committed to providing a welcoming and inspiring community for all.

## Our Standards

Examples of behavior that contributes to creating a positive environment include:
- Being respectful of differing opinions
- Providing constructive feedback
- Focusing on what is best for the community
- Showing empathy towards other community members

## Unacceptable Behavior

Examples of unacceptable behavior include:
- Harassment or discrimination
- Abusive language or personal attacks
- Trolling or insulting comments
- Publishing others' private information without consent

## Enforcement

Violations should be reported to: 16927624+paulsinclair51@users.noreply.github.com

Responses to code of conduct violations will be proportionate and fair.
```

---

## Signing Commits

### Require GPG Signatures on Protected Branches

**GitHub Setting:**
- Go to Settings → Branches → main
- Enable "Require signed commits"

**Why:**
- Proves commit came from verified contributor
- Prevents impersonation
- Provides non-repudiation

**Setup (Linux/Mac):**
```bash
# Generate GPG key
gpg --full-generate-key

# List your keys
gpg --list-secret-keys

# Add to git
git config --global user.signingkey <KEY_ID>
git config --global commit.gpgsign true

# Sign commits
git commit -S -m "message"
```

**Verification:**
```bash
# Verify signature
git verify-commit <commit>

# Show signatures
git log --show-signature
```

---

## Large File Protection

### File Size Limits

**Soft Limit (1 MB):** Warning but allowed
**Hard Limit (10 MB):** Rejected by workflow

**Checked by:** `branch-validation-large-files.yml`

**Why:**
- Keeps repository small and fast
- Prevents accidental binary commits
- Ensures clones are reasonable size

**Alternatives for Large Files:**
- Use GitHub Releases for binaries
- Use git-lfs for media
- Host documentation PDFs separately

---

## Workflow Protection

### GitHub Actions Workflows Are Protected

**Cannot be modified via normal PRs** - Requires Approver

**Why:**
- Workflows control CI/CD security
- Malicious workflow could exfiltrate secrets
- Modifications tracked and audited

**How to Update:**
1. Create PR with workflow changes
2. Explain what changed and why
3. Approver reviews workflow diff carefully
4. Requires override: `SCRIPT_OVERRIDE_CONFIRMED=true`
5. Audit logged to `logs/approver-audit.log`

---

## Author Verification

### Commits Must Come From Authorized Users

**Checked by:** `branch-validation-author.yml`

**Verification:**
- Commit author matches GitHub user
- Author is in `config/contributors.md`
- Email is verified on GitHub

**Why:**
- Prevents impersonation
- Ensures only team can commit
- Provides accountability

---

## Release Security

### Creating Releases

**Process:**
```bash
# 1. Tag the release
SCRIPT_OVERRIDE_CONFIRMED=true scripts/bin/release v1.0.0

# 2. GitHub automatically creates release page
# 3. Add release notes
# 4. Attach binaries (if applicable)
# 5. Publish
```

**Security Considerations:**
- Release tags are permanent (cannot be deleted)
- Should tag stable, tested versions only
- Include security advisory notes if fixing vulnerabilities
- Sign release commits with GPG

---

## Dependency Security

### Third-Party Dependencies

**briteTest Policy:**
- **NO external dependencies** (by design)
- C99 standard library only
- POSIX.1-2001 APIs only
- Reduces attack surface

**Verification:**
- Check `include/` for external includes
- Check `src/` for external libraries
- Review all new dependencies in PRs

### Supply Chain Security

- Maintain git history integrity
- Verify all commits
- Use signed tags for releases
- Document all dependencies clearly

---

## Access Control Reminders

### Public Tier
- ✅ Can read all public files
- ❌ Cannot commit, push, or execute scripts
- ✅ Can fork and create external PRs

### User Tier (Read-Only)
- ✅ Can clone and fork
- ❌ Cannot push or create PRs
- Use case: Technical readers, library users

### Contributor (C)
- ✅ Can create branches and PRs
- ❌ Cannot merge to main
- ❌ Cannot execute protected scripts

### Reviewer (R)
- ✅ Can review and approve
- ✅ Can rebase branches
- ❌ Cannot merge to main
- ❌ Cannot execute protected scripts

### Approver (A)
- ✅ Can merge (with override confirmation)
- ✅ Can create releases (with override confirmation)
- ✅ Can execute all scripts
- ✅ Audit logged

### Maintainer
- ✅ Full repository control
- ✅ Can change settings
- ✅ Can add/remove collaborators

See [ACCESS_CONTROL_TIERS.md](./ACCESS_CONTROL_TIERS.md) for details.

---

## Audit & Compliance

### Audit Trails

All important actions are logged:
- **Approver actions:** `logs/approver-audit.log`
- **GitHub Actions:** Settings → Actions → Audit log
- **Workflows:** View run logs for each workflow
- **Git:** `git log --all --oneline`

### Regular Reviews

- **Weekly:** Check failed CI/CD runs
- **Monthly:** Review collaborator access
- **Quarterly:** Audit approver actions
- **Annually:** Security assessment

### Compliance Documentation

Maintain records of:
- Who has access and why
- All approver decisions
- Security incidents
- Vulnerability fixes
- Policy changes

---

## Incident Response

### Security Incident Steps

1. **Identify** - Detect the issue
2. **Contain** - Stop further exposure
3. **Assess** - Determine scope and impact
4. **Remediate** - Fix the vulnerability
5. **Recover** - Restore normal operations
6. **Review** - Prevent recurrence

### Example: Exposed API Key

1. **Identify:** Key found in code
2. **Contain:** Block PR from merging
3. **Assess:** Check git logs for commits
4. **Remediate:** Rotate key, remove from history
5. **Recover:** Force push (approver override)
6. **Review:** Add to pre-commit hooks

---

## Security Checklist for Release

Before releasing to public:

- ✅ All secrets removed from repository
- ✅ No exposed credentials in git history
- ✅ LICENSE file present (MIT)
- ✅ SECURITY.md policy in place
- ✅ CODE_OF_CONDUCT.md available
- ✅ CONTRIBUTING.md written
- ✅ Branch protection rules configured
- ✅ All workflows passing
- ✅ No large files checked in
- ✅ All commits signed (optional but recommended)
- ✅ CODEOWNERS configured
- ✅ Dependabot enabled (if using dependencies)
- ✅ README.md updated with links to docs
- ✅ Issues and discussions enabled
- ✅ Repository description and topics set

---

## Related Documents

- [ACCESS_CONTROL_TIERS.md](./ACCESS_CONTROL_TIERS.md) - Access control model
- [CONTRIBUTING.md](./CONTRIBUTING.md) - How to contribute
- [SCRIPT_ACCESS_CONTROL.md](./SCRIPT_ACCESS_CONTROL.md) - Script-level RBAC
- [.github/SECURITY.md](../.github/SECURITY.md) - Public security policy

---

## Summary

**briteTest's security model for public repository:**

✅ **Branch Protection** - Protected main/v*.0 branches
✅ **Secret Detection** - Automated scanning blocks secrets
✅ **Code Quality** - 15 validation workflows
✅ **Access Control** - Role-based, script-controlled writes
✅ **Audit Trails** - All important actions logged
✅ **Vulnerability Policy** - Responsible disclosure
✅ **Compliance** - MIT license, code of conduct
✅ **Dependency Security** - No external dependencies (by design)

---

**Document Version:** v1.0.0  
**Last Updated:** 2026-07-09  
**Status:** Complete & Ready for Public Release
