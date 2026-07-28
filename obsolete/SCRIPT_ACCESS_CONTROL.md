# Script Access Control Documentation

#### Version: v1.0.0
#### Date: 2026-07-09
#### Copyright (c) 2026 Paul Sinclair

SPDX-License-Identifier: MIT

---

## Overview

briteTest implements a **Role-Based Access Control (RBAC)** system that restricts which scripts each user can execute based on their role. This prevents contributors and reviewers from accidentally (or intentionally) performing dangerous operations on protected branches.

The system is hierarchical:
- **Approver (A)** ⊃ **Reviewer (R)** ⊃ **Contributor (C)**

---

## Role Definitions

### Contributor (C)

**Permission Level:** Basic contributor access

**Can Execute:**
- `mkbranch` - Create new feature branches
- `mkclone` - Clone the repository
- `commit` - Create and sign commits
- `copyfix` - Cherry-pick fix commits between branches
- `mrgbranch` - Sync with remote repository
- `mrgdown` - Sync up with main branch
- `make test-all-scripts` - Run script smoke tests locally
- `undo` - Undo uncommitted changes
- `lsbranchlog` - Check branch history
- `lsbranch` - List branches
- Utility scripts: `gendocs`, `genpngs`, `setupclone`

**Cannot Execute:**
- Reviewer scripts (require R role)
- Approver scripts (require A role)
- Protected scripts: `mrgup`, `release`, `fixrepo`

**Use Cases:**
- Writing code and documentation
- Creating pull requests for review
- Syncing local branch with remote
- Running tests locally

---

### Reviewer (R)

**Permission Level:** Contributor + Code Review access

**Inherits:** All Contributor scripts

**Additional Scripts:**
- `feedback` - Provide code review feedback
- `review` - Create/update pull requests
- `ckstyle` - Check code style compliance

**Cannot Execute:**
- Approver scripts (require A role)
- Protected scripts: `mrgup`, `release`, `fixrepo`

**Use Cases:**
- Reviewing pull requests
- Providing feedback on code changes
- Rebasing work branches
- Checking code style before merge
- All contributor tasks

---

### Approver (A)

**Permission Level:** Full access (all scripts)

**Inherits:** All Reviewer + Contributor scripts

**Additional Scripts (Protected):**
- `mrgup` - Merge branches to protected branches (requires override)
- `release` - Create releases and tags (requires override)
- `fixrepo` - Repair repository state (requires override)
- `rebrand` - Update branding across repository
- `replacetext` - Replace text globally

**Protected Scripts:** Require explicit `SCRIPT_OVERRIDE_CONFIRMED=true` confirmation

**Use Cases:**
- Merging approved PRs to main/version branches
- Creating official releases
- Emergency repository repairs
- Updating project branding
- All reviewer and contributor tasks

---

## Protected Scripts

Protected scripts are dangerous operations that can affect the entire repository. Even approvers must explicitly confirm execution of these scripts.

### mrgup - Branch Merge Operation

**What it does:** Merges one branch into another (especially to protected branches)

**Why protected:** Can inadvertently merge untested or incomplete code to main

**Restrictions:**
- Only Approvers can execute
- Requires `SCRIPT_OVERRIDE_CONFIRMED=true`
- Audit logged with timestamp

**Example Usage:**
```bash
# Local execution (no override needed)
SCRIPT_OVERRIDE_CONFIRMED=true scripts/bin/mrgup feature main

# GitHub Actions (set via environment variable)
env:
  SCRIPT_OVERRIDE_CONFIRMED: 'true'
run: scripts/bin/mrgup feature main
```

### release - Create Release

**What it does:** Creates version tags and release commits

**Why protected:** Releasing wrong version or incomplete code affects users

**Restrictions:**
- Only Approvers can execute
- Requires `SCRIPT_OVERRIDE_CONFIRMED=true`
- Creates permanent tags that cannot be undone

**Example Usage:**
```bash
SCRIPT_OVERRIDE_CONFIRMED=true scripts/bin/release v1.2.0
```

### fixrepo - Repository Repair

**What it does:** Repairs repository health with safe cleanup and post-check verification

**Why protected:** Can change repository state and should be used carefully

**Restrictions:**
- Only Approvers can execute
- Requires `SCRIPT_OVERRIDE_CONFIRMED=true`
- Should only be used when repository integrity or cleanup issues need attention

**Example Usage:**
```bash
SCRIPT_OVERRIDE_CONFIRMED=true scripts/bin/fixrepo
```

---

## Hierarchy and Inheritance

The role hierarchy ensures users have all permissions from lower roles:

```
Approver (A)
    ↓ (includes all R permissions)
Reviewer (R)
    ↓ (includes all C permissions)
Contributor (C)
```

**Examples:**
- Approver can execute all scripts (17+)
- Reviewer can execute Contributor + Reviewer scripts (14)
- Contributor can execute only Contributor scripts (10)

---

## Access Control Enforcement

### How It Works

1. **Permission Check at Script Start**
   ```bash
   # Every script should start with:
   source scripts/helpers/rbac.sh
   enforce_script_access "$(basename "$0")"
   ```

2. **Role Lookup**
   - Checks `config/contributors.md` for user's role
   - Uses `GITHUB_ACTOR` (in GitHub) or `git config user.name` (locally)

3. **Permission Verification**
   - Compares user's role against script's allowed roles
   - Blocks execution if not authorized

4. **Protected Script Override**
   - For protected scripts, checks `SCRIPT_OVERRIDE_CONFIRMED=true`
   - Logs approver action to `logs/approver-audit.log`

### Example: Adding RBAC to a Script

```bash
#!/bin/bash

# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT

set -euo pipefail

# Source helper libraries
source scripts/helpers/common-utils.sh
source scripts/helpers/rbac.sh

# 1. Enforce access control
enforce_script_access "mkbranch"

# 2. Continue with script logic
log_info "Creating new branch..."
# ... rest of script
```

---

## Configuration

### Adding a User

Edit `config/contributors.md`:

```markdown
- username, role, email@example.com
```

**Example:**
```markdown
- paulsinclair51, A, 16927624+paulsinclair51@users.noreply.github.com
- alice, R, alice@example.com
- bob, C, bob@example.com
```

### Changing a User's Role

Edit `config/contributors.md` and change the role:

```markdown
# Before:
- alice, C, alice@example.com

# After (promote to Reviewer):
- alice, R, alice@example.com
```

Changes take effect immediately on next script execution.

### Adding a New Script

1. **Determine script purpose** - What does it do?
2. **Assign minimum role** - What's the least privilege needed?
3. **Edit `scripts/helpers/rbac.sh`** - Add to appropriate array
4. **Add RBAC check** - Start script with `enforce_script_access`

**Example: Add new script to Reviewer permissions**

Edit `scripts/helpers/rbac.sh`:
```bash
readonly REVIEWER_SCRIPTS=(
  "feedback"
  "review"
  "ckstyle"
  "mynewscript"    # ← Add here
)
```

---

## Usage Examples

### Example 1: Contributor Creating a Feature

```bash
# Alice is a Contributor (C)
# She can create branches and commits

# ✅ Allowed
scripts/bin/mkbranch -r alice/feature main
cd alice/feature
# ... make changes ...
scripts/bin/commit -m "feat: add new feature"
scripts/bin/mrgbranch

# ✗ Not allowed (requires Reviewer role)
scripts/bin/feedback  # Error: Permission denied

# ✗ Not allowed (requires Approver role)
scripts/bin/mrgup alice/feature main  # Error: Permission denied
```

### Example 2: Reviewer Checking Code

```bash
# Bob is a Reviewer (R)
# He can review and manage PR workflows, but not merge to main

# ✅ Allowed (inherited from Contributor)
scripts/bin/mkbranch -r bob/fix main

# ✅ Allowed (Reviewer script)
scripts/bin/feedback

# ✅ Allowed (Reviewer script)
scripts/bin/review

# ✗ Not allowed (requires Approver role)
scripts/bin/mrgup v1.0.0 main  # Error: Permission denied
```

### Example 3: Approver Merging and Releasing

```bash
# Paul is an Approver (A)
# He can do everything, but protected scripts need override

# ✅ Allowed (inherited from Reviewer)
scripts/bin/mkbranch -r paul/hotfix v1.0.0

# ✅ Allowed (protected script with override)
SCRIPT_OVERRIDE_CONFIRMED=true scripts/bin/mrgup paul/hotfix v1.0.0

# ✅ Allowed (protected script with override)
SCRIPT_OVERRIDE_CONFIRMED=true scripts/bin/retarget dev/parser-v1.0.0 v1.1.0

# ✅ Allowed (protected script with override)
SCRIPT_OVERRIDE_CONFIRMED=true scripts/bin/release v1.0.1

# ✗ Not allowed (no override confirmation)
scripts/bin/mrgup main v1.0.0  # Error: Protected script requires override
```

---

## Audit Trail

All approver actions on protected scripts are logged to `logs/approver-audit.log`:

```
[AUDIT] 2026-07-09 15:23:45 Approver paulsinclair51 approved: merge (merge feature to main)
[AUDIT] 2026-07-09 15:25:12 Approver paulsinclair51 approved: release (create release v1.0.1)
[AUDIT] 2026-07-09 15:30:00 Approver paulsinclair51 approved: fixrepo (emergency repair)
```

**Audit Log Fields:**
- Timestamp: When the action was performed
- Username: Which approver approved
- Script name: What script was executed
- Operation: What the script did

**Access Audit Log:**
```bash
# View recent approver actions
tail -20 logs/approver-audit.log

# Search for specific approver
grep "paulsinclair51" logs/approver-audit.log

# Find all releases
grep "release" logs/approver-audit.log
```

---

## Permission Check Functions

The RBAC system provides several functions for checking permissions:

### get_user_role()

Get the role for a user

```bash
role=$(get_user_role "paulsinclair51")
echo "Role: $role"  # Output: Role: A
```

### can_execute_script()

Check if user can execute a script

```bash
if can_execute_script "alice" "mrgup"; then
  echo "Alice can execute mrgup"
else
  echo "Alice cannot execute mrgup"
fi
```

### is_protected_script()

Check if a script is protected

```bash
if is_protected_script "mrgup"; then
  echo "This script requires override"
fi
```

### enforce_script_access()

Enforce permission (used at script start)

```bash
enforce_script_access "mkbranch"  # Exits if user not authorized
```

### request_approver_override()

Request approver confirmation for protected script

```bash
request_approver_override "mrgup" "merge hotfix to main"
# Exits unless SCRIPT_OVERRIDE_CONFIRMED=true
```

### print_role_capabilities()

Display what a role can do

```bash
print_role_capabilities "R"
# Shows all Reviewer capabilities
```

### whoami_script()

Display current user's permissions

```bash
whoami_script
# Shows current user, role, and capabilities
```

---

## Troubleshooting

### "Permission denied: user cannot execute script"

**Problem:** User tried to execute a script they don't have permission for

**Solution:** Check user's role in `config/contributors.md`
```bash
# View user's role and capabilities
whoami_script

# Check what role can execute the script
print_role_capabilities "A"  # View Approver permissions
print_role_capabilities "R"  # View Reviewer permissions
print_role_capabilities "C"  # View Contributor permissions
```

**Example:**
```bash
# Alice (Contributor) tries to merge:
alice$ scripts/bin/mrgup feature main
✗ Permission denied: alice (C) cannot execute mrgup

# Solution: Only Approvers can merge
# Alice needs to ask an Approver to merge for her
```

### "Protected script requires SCRIPT_OVERRIDE_CONFIRMED=true"

**Problem:** Approver forgot to set override flag for protected script

**Solution:** Add environment variable before script execution

```bash
# Local execution:
SCRIPT_OVERRIDE_CONFIRMED=true scripts/bin/mrgup feature main

# GitHub Actions workflow:
env:
  SCRIPT_OVERRIDE_CONFIRMED: 'true'
run: scripts/bin/mrgup feature main
```

### "User not in contributors list"

**Problem:** User's GitHub login not found in `config/contributors.md`

**Solution:** 
1. Add user to `config/contributors.md`
2. Or use default role (Contributor) until added

```bash
# config/contributors.md
- newuser, C, newuser@example.com
```

---

## Best Practices

### 1. Always Use Scripts for Protected Operations

✅ **Good:**
```bash
SCRIPT_OVERRIDE_CONFIRMED=true scripts/bin/mrgup feature main
# Audit logged, validated, reversible
```

❌ **Bad:**
```bash
git push -f origin feature:main
# No validation, no audit trail, dangerous
```

### 2. Promote Users to Reviewer Before Approver

```bash
# Step 1: Start as Contributor
- alice, C

# Step 2: After proving competence, promote to Reviewer
- alice, R

# Step 3: After trusted experience, promote to Approver
- alice, A
```

### 3. Require Override Confirmation for Protected Scripts

```bash
# Good: Explicit confirmation
SCRIPT_OVERRIDE_CONFIRMED=true scripts/bin/release v1.0.0

# Bad: No confirmation (will fail)
scripts/bin/release v1.0.0
```

### 4. Review Audit Logs Regularly

```bash
# Weekly approver action review
grep "merge\|release" logs/approver-audit.log | tail -20
```

### 5. Document Role Changes

When changing a user's role, document why:

```bash
# Example commit message:
# docs: promote alice from Contributor to Reviewer

# After 6 months of contributions, alice has proven
# competence with code review and is ready for
# Reviewer role responsibilities.
```

---

## Integration with GitHub Actions

Protected scripts in GitHub Actions require environment variable:

```yaml
name: Release

on:
  workflow_dispatch:

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Create release
        env:
          SCRIPT_OVERRIDE_CONFIRMED: 'true'
        run: scripts/bin/release v1.0.0
```

---

## Security Considerations

### 1. Role Downgrades Prevent Accidents

Users downgraded from Approver to Reviewer lose access to dangerous scripts automatically.

### 2. Audit Trails Provide Accountability

All protected script executions are logged with timestamp and approver name.

### 3. Protected Scripts Prevent Muscle Memory Mistakes

Requiring explicit confirmation prevents approvers from accidentally executing dangerous commands.

### 4. Layered Permissions Reduce Surface Area

Limiting permissions to what each role needs reduces risk of privilege abuse.

---

## Related Documents

- [Contributor_Guide.md](./docs/md/Contributor_Guide.md) - Contributor workflow guide
- [Contributor_Reference.md](./docs/md/Contributor_Reference.md) - Script reference
- [WORKFLOW_ARCHITECTURE.md](./docs/WORKFLOW_ARCHITECTURE.md) - Workflow system design
- [config/contributors.md](./config/contributors.md) - Current contributors list

---

## Summary

The Script Access Control system provides:

✅ **Role-based permissions** - Limit access by role (C, R, A)
✅ **Hierarchical access** - Approvers inherit all lower permissions
✅ **Protected scripts** - Critical operations require explicit confirmation
✅ **Audit trails** - All approver actions logged
✅ **Easy management** - Update permissions in one file
✅ **Prevents accidents** - Can't directly use git commands on protected branches
✅ **Educates team** - Clear role responsibilities
✅ **Scalable** - Easy to add users and scripts

---

**Document Version:** v1.0.0  
**Last Updated:** 2026-07-09  
**Status:** Complete & Production Ready
