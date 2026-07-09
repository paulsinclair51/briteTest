![Contributor Guide](/docs/branding/Contributor_Guide.png)

#### Version: v1.3.0

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
| v1.3.0 | 2026-07-09 | Consolidated access control and public security guidance into contributor docs | Paul Sinclair |
| v1.2.0 | 2026-07-09 | Added troubleshooting FAQ, GPG setup guide, and team onboarding checklist | Paul Sinclair |
| v1.1.0 | 2026-07-09 | Added validation workflows section and git operations guide | Paul Sinclair |
| v1.0.0 | 2026-06-11 | Initial version. | Paul Sinclair |

---

## Table of Contents

1. [Introduction](#introduction)
2. [Access Control & Roles](#access-control--roles)
3. [Public Repository Security](#public-repository-security)
4. [Branching Model Overview](#branching-model-overview)
5. [Validation Workflows](#validation-workflows)
6. [Git Operations and Branch Management](#git-operations-and-branch-management)
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

---

## Access Control & Roles

briteTest uses a six-tier access model so contributors can work in a public repository
without giving every collaborator the same GitHub or script privileges. Repository-tier
access is documented here, and script-level RBAC details are maintained in
[Contributor_Reference.md](./Contributor_Reference.md#script-based-access-control).

### Tier Summary

| Tier | Who | Typical GitHub Permission | Core Capabilities | Key Restrictions |
|------|-----|---------------------------|-------------------|------------------|
| `PUBLIC` | Anyone who can view the public project | None | Read public docs/source, clone, fork, download | No collaborator access, no branch creation, no script execution |
| `USERS` | Invited read-only collaborators | `Pull` | Read repository content, follow issues/discussions, fork for external PRs | No direct push, no branch creation, no local RBAC privileges |
| `C` | Contributors | `Push` | Create branches, commit, push to work branches, open PRs | No protected-branch pushes, no reviewer/approver scripts |
| `R` | Reviewers | `Maintain` | All contributor actions plus reviews, rebases, PR updates | No protected-branch pushes, no protected scripts |
| `A` | Approvers | `Maintain` or `Admin` | All reviewer actions plus merge/release/recovery operations | Protected scripts require explicit override confirmation |
| `MAINTAINER` | Repository owner/administrators | `Admin` | All repository, security, and settings administration | Expected to use branch protection and audit controls consistently |

### File Access Matrix

Use the following shorthand: `R` = readable, `RW` = editable through the normal
workflow, `RW*` = editable only through protected approver workflow, `-` = not part
of the assigned access path.

| File or Path | PUBLIC | USERS | C | R | A | MAINTAINER |
|--------------|--------|-------|---|---|---|------------|
| `README.md`, `LICENSE`, `CODE_OF_CONDUCT.md`, `.github/SECURITY.md` | R | R | R | R | R | RW |
| `docs/md/`, `docs/branding/`, `src/`, `include/`, `examples/` | R | R | RW | RW | RW | RW |
| `scripts