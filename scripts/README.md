# Branch Management Scripts

This directory contains utility scripts for managing Git branches with consistent naming conventions and detailed logging.

## Scripts

### mkbranch - Create a new branch
Creates a new branch from a base branch with optional remote push.

**Usage:**
```bash
scripts/mkbranch [OPTIONS] <branchname> <basebranchname>
```

**Examples:**
```bash
# Create patch branch (default type)
scripts/mkbranch fix-login-bug main

# Create with explicit type
scripts/mkbranch major/redesign-ui main

# Create and push to remote
scripts/mkbranch -r minor/add-logging develop

# Validate without creating
scripts/mkbranch -v patch/fix-memory-leak main
```

**Options:**
- `-l` - Create local branch only (default)
- `-r` - Create local branch and push to remote
- `-v` - Validate only (check if valid without creating)
- `-h` - Show help

**Type Prefix Behavior:**
- If no type prefix is specified, `patch/` is added automatically
- Example: `fix-bug` becomes `patch/fix-bug`
- Type validation is enforced in validate mode

### rmbranch - Remove a branch
Removes a branch locally and/or from remote with confirmation.

**Usage:**
```bash
scripts/rmbranch [OPTIONS] <branchname>
```

**Examples:**
```bash
# Remove local branch (with confirmation)
scripts/rmbranch patch/fix-bug

# Remove with force (no confirmation)
scripts/rmbranch -f patch/fix-bug

# Remove from remote only
scripts/rmbranch -r minor/old-feature

# Remove from both local and remote
scripts/rmbranch -a major/completed-refactor
```

**Options:**
- `-l` - Remove local branch only (default)
- `-r` - Remove branch from remote only
- `-a` - Remove from both local and remote
- `-f` - Force removal (no confirmation prompt)
- `-h` - Show help

**Type Validation:**
- If type prefix is specified, it must be valid (major/minor/patch/docs)
- The branch must exist with that exact type
- If no type is specified, no type validation is performed

## Branch Naming Convention

Branches follow the format: `<type>/<description>`

### Valid Types

| Type | Purpose | Examples |
|------|---------|----------|
| `major` | Major features or changes | `major/new-ui-system`, `major/core-refactor` |
| `minor` | Minor features or changes | `minor/add-logging`, `minor/optimize-parser` |
| `patch` | Bug fixes | `patch/fix-login-bug`, `patch/memory-leak` |
| `docs` | Documentation updates only | `docs/api-guide`, `docs/setup-instructions` |

### Default Type

When creating a branch without a type prefix, `patch` is used as the default:
- Input: `fix-critical-bug`
- Created: `patch/fix-critical-bug`

### Protected Branches

The following branches cannot be deleted:
- `main`
- `master`
- `develop`
- `development`

## Logging

All operations are logged to `logs/branch_history.md` with:
- Timestamp (YYYY-MM-DD HH:MM:SS)
- Operation status (SUCCESS/FAILED)
- Branch name
- Base branch (for creation operations)
- Detailed message

Example log entry:
```
- **2026-06-26 14:30:15** | Status: `SUCCESS` | Branch: `patch/fix-bug` | Base: `main` | Local branch created (mode: local)
```

## Quick Start

1. **Create a new feature branch:**
   ```bash
   scripts/mkbranch my-new-feature main
   # Creates: patch/my-new-feature
   ```

2. **Create with explicit type:**
   ```bash
   scripts/mkbranch major/redesign main
   # Creates: major/redesign
   ```

3. **Push to remote:**
   ```bash
   scripts/mkbranch -r patch/fix-bug develop
   ```

4. **Remove a branch:**
   ```bash
   scripts/rmbranch patch/fix-bug
   ```

5. **Validate branch before creating:**
   ```bash
   scripts/mkbranch -v major/big-feature main
   ```

## Help

For detailed help on any script:
```bash
scripts/mkbranch -h
scripts/rmbranch -h
```

## Exit Codes

### mkbranch
- `0` - Success
- `1` - Argument error
- `2` - Git operation failed
- `3` - Branch already exists
- `4` - Base branch doesn't exist
- `5` - Validation failed

### rmbranch
- `0` - Success
- `1` - Argument error
- `2` - Git operation failed
- `3` - Branch does not exist
- `4` - Branch is protected
- `5` - Operation cancelled
- `6` - Type mismatch
