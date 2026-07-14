# Access Control Tiers for Public Repository

#### Version: v1.0.0
#### Date: 2026-07-09
#### Copyright (c) 2026 Paul Sinclair

SPDX-License-Identifier: MIT

---

## Overview

briteTest is a **public open-source repository** with tiered access control. This document defines what each tier can read, write, and execute.

**Access Model:**
```
┌─────────────────────────────────────────────────────────┐
│ PUBLIC: Anyone on Internet                              │
│ • Read: docs/, src/, include/, examples/, README        │
│ • Clone, Fork, Download                                 │
│ • Cannot: Push, PR, Execute scripts, Access private     │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│ USERS: Read-Only Collaborators (invited, no payment)   │
│ • Read: All public content + docs/private/ (if granted) │
│ • Clone, Fork, Fork to personal repo                    │
│ • Cannot: Push, PR to this repo, Execute scripts        │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│ CONTRIBUTOR (C): Can submit PRs and create branches    │
│ • Read: All files                                       │
│ • Create: Branches, commits, PRs (from forks or branches)
│ • Cannot: Merge, Release, Direct push to main/v*.0     │
│ • Scripts: mkbranch, commit, syncfromremote, etc.      │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│ REVIEWER (R): Can review and provide feedback           │
│ • Read: All files                                       │
│ • Review: PRs, approve changes                          │
│ • Cannot: Merge to main/v*.0, Release                   │
│ • Scripts: mkfeedback (in addition to C)                │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│ APPROVER (A): Full control (merges, releases, etc.)    │
│ • Read: All files including .github/workflows configs  │
│ • Write: All branches including main, v*.0             │
│ • Merge: To protected branches (requires override)     │
│ • Release: Create tags and releases                    │
│ • Scripts: All scripts (requires override for protected)│
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│ MAINTAINER: Project owner (Paul Sinclair)              │
│ • Full access to all repository settings                │
│ • Can add/remove collaborators                          │
│ • Can change branch protection rules                    │
│ • Can modify repository settings                        │
└─────────────────────────────────────────────────────────┘
```

---

## Tier Definitions

### PUBLIC (Unauthenticated Users)

**Who:** Anyone on the Internet without a GitHub account (or viewing without authentication)

**Read Access:**
- ✅ README.md
- ✅ docs/md/ (all public documentation)
- ✅ docs/branding/ (logos, images)
- ✅ src/ (source code)
- ✅ include/ (public headers)
- ✅ examples/ (usage examples)
- ✅ LICENSE (MIT License)
- ✅ SECURITY.md (security policy)
- ✅ CODE_OF_CONDUCT.md (community standards)

**Cannot Access:**
- ❌ .github/workflows/ (automation, protected)
- ❌ config/ (internal configuration)
- ❌ scripts/ (automation scripts)
- ❌ logs/ (audit trails)
- ❌ config/contributors.md (team members, private)

**Capabilities:**
- ✅ Read repository content
- ✅ Clone repository
- ✅ Fork repository
- ✅ View issues and discussions
- ✅ Download as ZIP

**Cannot Do:**
- ❌ Push any changes
- ❌ Create pull requests
- ❌ Create branches
- ❌ Execute scripts
- ❌ Access GitHub Actions

---

### USERS (Read-Only Collaborators)

**Who:** Invited collaborators with "Pull" permission (no write access)

**Read Access:**
- ✅ All public files
- ✅ README.md, docs/, src/, include/
- ✅ Can see private repo content if invited

**Write Access:**
- ❌ Cannot push to any branch
- ❌ Cannot create branches
- ❌ Cannot create pull requests (can fork and PR from fork)

**Capabilities:**
- ✅ Clone repository
- ✅ Fork repository
- ✅ View all issues
- ✅ View discussions
- ✅ Create external PRs (from forked repo)
- ✅ Read documentation

**Cannot Do:**
- ❌ Push commits
- ❌ Create branches
- ❌ Merge PRs
- ❌ Execute scripts
- ❌ Access .github/workflows/
- ❌ Modify configuration

**Use Case:** Technical readers, integrators, library users who want to stay informed

---

### CONTRIBUTOR (C)

**Invited collaborators with "Push" permission**

**Read Access:**
- ✅ All repository files
- ✅ .github/workflows/ (can read but not modify)
- ✅ config/ (can read)
- ✅ All documentation

**Write Access (Controlled by Scripts):**
- ✅ Create feature branches (via `mkbranch`)
- ✅ Create commits (via `commit`)
- ✅ Push to own branches
- ✅ Create pull requests

**Cannot:**
- ❌ Push directly to `main` (protected)
- ❌ Push directly to `v*.0` (protected)
- ❌ Execute `mergetoparent`, `mkrelease`, `fixrepo`
- ❌ Modify .github/workflows/
- ❌ Modify config/

**Scripts Available:**
- `mkbranch` - Create branches
- `commit` - Create commits
- `mkpullrequest` - Create PRs
- `make test-all-scripts` - Run script smoke tests
- `syncfromremote` - Sync with remote
- All utility scripts

**Use Case:** Active contributors writing code and documentation

---

### REVIEWER (R)

**Invited collaborators with "Maintain" permission**

**Read Access:**
- ✅ All files (including .github/workflows/)
- ✅ Full repository visibility

**Write Access (Controlled by Scripts):**
- ✅ All Contributor capabilities
- ✅ Provide review feedback (via `mkfeedback`)
- ✅ Create/update pull requests

**Cannot:**
- ❌ Merge to `main` (protected)
- ❌ Merge to `v*.0` (protected)
- ❌ Execute `mergetoparent`, `mkrelease`, `fixrepo`
- ❌ Modify .github/workflows/
- ❌ Create releases
- ❌ Direct push to protected branches

**Scripts Available:**
- All Contributor scripts
- `mkfeedback` - Review feedback
- `ckstyle` - Check code style

**Use Case:** Trusted team members who review PRs and maintain code quality

---

### APPROVER (A)

**Invited collaborators with "Admin" permission (or "Maintain" with script override)**

**Read Access:**
- ✅ All files including internal configuration
- ✅ Workflow configurations
- ✅ Audit logs
- ✅ Repository settings (visible)

**Write Access (Controlled by Scripts + Override):**
- ✅ All Reviewer capabilities
- ✅ Merge to `main` (requires `SCRIPT_OVERRIDE_CONFIRMED=true`)
- ✅ Merge to `v*.0` (requires `SCRIPT_OVERRIDE_CONFIRMED=true`)
- ✅ Create releases (requires override)
- ✅ Emergency repository repairs (requires override)

**Cannot (without Admin permission):**
- ❌ Change repository settings
- ❌ Modify branch protection rules
- ❌ Add/remove collaborators

**Scripts Available:**
- All Reviewer scripts
- `mergetoparent` (protected - requires override)
- `mkrelease` (protected - requires override)
- `fixrepo` (protected - requires override)

**Use Case:** Project maintainers, official contributors with merge authority

---

### MAINTAINER

**Repository owner (paulsinclair51)**

**Permissions:** Full GitHub admin permissions

**Capabilities:**
- ✅ All technical permissions (all scripts)
- ✅ Repository settings
- ✅ Branch protection rules
- ✅ Add/remove collaborators
- ✅ Manage GitHub Pages
- ✅ Manage secrets
- ✅ Delete repository

**Use Case:** Project lead, final decision maker

---

## File Access Matrix

### Public-Readable Files

| File/Path | PUBLIC | USERS | C | R | A | Notes |
|-----------|--------|-------|---|---|---|-------|
| README.md | ✅ | ✅ | ✅ | ✅ | ✅ | Entry point |
| LICENSE | ✅ | ✅ | ✅ | ✅ | ✅ | MIT License |
| SECURITY.md | ✅ | ✅ | ✅ | ✅ | ✅ | Security policy |
| CODE_OF_CONDUCT.md | ✅ | ✅ | ✅ | ✅ | ✅ | Community guidelines |
| docs/md/*.md | ✅ | ✅ | ✅ | ✅ | ✅ | Documentation |
| src/ | ✅ | ✅ | ✅ | ✅ | ✅ | Source code |
| include/ | ✅ | ✅ | ✅ | ✅ | ✅ | Headers |
| examples/ | ✅ | ✅ | ✅ | ✅ | ✅ | Usage examples |

### Private/Restricted Files

| File/Path | PUBLIC | USERS | C | R | A | Notes |
|-----------|--------|-------|---|---|---|-------|
| .github/workflows/ | ❌ | ❌ | 🔍 | ✅ | ✅ | CI/CD configs (read-only for C) |
| config/contributors.md | ❌ | ❌ | ❌ | ❌ | ✅ | Team roster (private) |
| config/markdownlint.json | ❌ | ❌ | ❌ | 🔍 | ✅ | Linting config (read for R) |
| scripts/ | ❌ | ❌ | ✅ | ✅ | ✅ | Automation scripts |
| logs/ | ❌ | ❌ | ❌ | ❌ | ✅ | Audit trails (approver only) |
| build/ | ❌ | ❌ | ✅ | ✅ | ✅ | Build artifacts |
| reports/ | ❌ | ❌ | ✅ | ✅ | ✅ | Test reports |

Legend: ✅ = Read/Write, 🔍 = Read-Only, ❌ = No Access

---

## Write Access Control

### Protected Branches

**main branch:**
- Direct push: ❌ Blocked (all users)
- Merge via PR: ✅ Approvers only (via script override)
- Status checks: ✅ Required (15 workflows)
- Code review: ✅ Required (1+ approval)

**v*.0 branches (version branches):**
- Direct push: ❌ Blocked (all users)
- Merge via PR: ✅ Approvers only (via script override)
- Status checks: ✅ Required
- Code review: ✅ Required (1+ approval)

**Feature branches (mywork/*, dev/*, fix/*):**
- Direct push: ✅ Allowed for branch creator
- PR merge: ✅ Allowed by Reviewers/Approvers

### Script-Based Write Control

All write operations go through scripts, not direct git commands:

```bash
# Contributors can execute:
scripts/bin/mkbranch -r feature main          # ✅ Allowed
scripts/bin/commit -m "feat: add feature"   # ✅ Allowed
scripts/bin/mkpullrequest                      # ✅ Allowed
make test-all-scripts                               # ✅ Allowed

# Reviewers can additionally execute:
scripts/bin/mkfeedback                         # ✅ Allowed

# Approvers can execute (with override):
SCRIPT_OVERRIDE_CONFIRMED=true scripts/bin/mergetoparent feature main    # ✅ Allowed
SCRIPT_OVERRIDE_CONFIRMED=true scripts/bin/chtarget dev/parser-v1.0.0 v1.1.0 # ✅ Allowed
SCRIPT_OVERRIDE_CONFIRMED=true scripts/bin/mkrelease v1.0.0        # ✅ Allowed

# Direct git commands to protected branches blocked:
git push origin feature:main                   # ❌ Blocked by branch protection
git merge --no-ff main                         # ❌ Requires PR + review
```

---

## GitHub Configuration

### Required Branch Protection Rules

**For `main` branch:**

```yaml
Required status checks:
  - All 15 branch-validation-* workflows must pass
  
Required pull request reviews:
  - Minimum 1 approval required
  - Dismiss stale pull request approvals on push
  - Require review from code owners

Restrictions:
  - Allows only approvers to push
  - Block force pushes
  - Block deletions
  - Require branches to be up to date
```

**For `v*.0` branches (version):**

```yaml
Required status checks:
  - All 15 branch-validation-* workflows must pass
  
Required pull request reviews:
  - Minimum 1 approval required
  - Require review from code owners

Restrictions:
  - Allows only approvers to push
  - Block force pushes
  - Block deletions
  - Require branches to be up to date
```

### Recommended Additional Protections

- ✅ Enable GitHub Dependabot (dependency updates)
- ✅ Enable branch auto-deletion on PR merge
- ✅ Require commit signature verification (GPG)
- ✅ Require status checks to pass before merge
- ✅ Limit who can push to matching branches

---

## Inviting Collaborators

### How to Add as USER (Read-Only)

1. Go to Settings → Collaborators and teams
2. Click "Add people"
3. Enter GitHub username
4. Select **"Pull"** permission (read-only)
5. Send invitation

User can:
- ✅ Clone, fork, read
- ❌ Cannot push or create branches
- ❌ Cannot create PRs directly (can PR from fork)

### How to Add as CONTRIBUTOR

1. Go to Settings → Collaborators and teams
2. Click "Add people"
3. Enter GitHub username
4. Select **"Push"** permission
5. Send invitation
6. Add to `config/contributors.md` with role **C**

Contributor can:
- ✅ Create branches (via `mkbranch`)
- ✅ Push commits (via `commit`)
- ✅ Create PRs
- ❌ Cannot merge to main

### How to Add as REVIEWER

1. Go to Settings → Collaborators and teams
2. Add with **"Maintain"** permission
3. Add to `config/contributors.md` with role **R**
4. Update `.github/CODEOWNERS` if appropriate

Reviewer can:
- ✅ All Contributor actions
- ✅ Review and approve PRs
- ✅ Rebase branches
- ❌ Cannot merge to main (no Approver override)

### How to Add as APPROVER

1. Go to Settings → Collaborators and teams
2. Add with **"Maintain"** permission (or Admin for full control)
3. Add to `config/contributors.md` with role **A**
4. Document reason in commit message

Approver can:
- ✅ All Reviewer actions
- ✅ Merge to main/v*.0 (with override)
- ✅ Create releases
- ✅ Emergency repairs

---

## Access Audit

### Review Who Can Do What

```bash
# Show all collaborators and permissions:
# Settings → Collaborators and teams

# Show approvers:
grep ", A," config/contributors.md

# Show reviewers:
grep ", R," config/contributors.md

# Show contributors:
grep ", C," config/contributors.md

# View approver audit trail:
tail -20 logs/approver-audit.log
```

### Regular Audits

- **Monthly:** Review collaborator list for inactive members
- **Quarterly:** Audit approver actions for compliance
- **Annually:** Promote contributors → reviewers → approvers

---

## Transition Path

```
New User (Read-Only)
       ↓ (After 1-2 PRs proving competence)
Contributor (C)
       ↓ (After 6+ months, 20+ contributions)
Reviewer (R)
       ↓ (After 1+ year, trusted decision maker)
Approver (A)
```

---

## Related Documents

- [SCRIPT_ACCESS_CONTROL.md](./SCRIPT_ACCESS_CONTROL.md) - Script-level RBAC
- [PUBLIC_REPO_SECURITY.md](./PUBLIC_REPO_SECURITY.md) - Security guidelines
- [SECURITY.md](../.github/SECURITY.md) - Public security policy
- [CONTRIBUTING.md](./CONTRIBUTING.md) - How to contribute
- [config/contributors.md](../config/contributors.md) - Current team

---

## Summary

**briteTest's public repository access model:**

✅ **PUBLIC** - Anyone can read, clone, fork (no write)
✅ **USERS** - Read-only collaborators (invited)
✅ **CONTRIBUTOR (C)** - Can create branches and PRs (script-controlled)
✅ **REVIEWER (R)** - Can review and rebase (inherited + new scripts)
✅ **APPROVER (A)** - Can merge and release (override-protected)
✅ **MAINTAINER** - Full admin control (repository owner)

All write operations controlled by scripts, not direct git commands.

---

**Document Version:** v1.0.0  
**Last Updated:** 2026-07-09  
**Status:** Complete & Ready for Public Release
