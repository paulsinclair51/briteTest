# Implementation Verification and Consolidation Plan

#### Date: 2026-07-23
#### Scope: docs/*.md temporary documents and consolidation tracking

SPDX-License-Identifier: MIT

---

## Purpose

This document consolidates review of top-level `docs/*.md` files to determine:

1. What is actually implemented in the repository.
2. What should be implemented (or not implemented).
3. What must be documented in canonical docs under `docs/md/`.

This pass is review and planning only. Original documents remain in place.

---

## Verification Method

Implementation checks were validated against current repository artifacts:

- Scripts under `scripts/bin/` and helpers under `scripts/helpers/`
- Workflow files under `.github/workflows/`
- Role and contributor data in `config/contributors.md`
- Canonical documentation coverage in:
  - `docs/md/Contributor_Guide.md`
  - `docs/md/Contributor_Reference.md`

---

## Consolidated Verification Matrix

| Source Document(s) | Implementation Reality (Verified) | Keep/Implement Decision | Canonical Doc Target(s) | Planned Action |
|---|---|---|---|---|
| `obsolete/ACCESS_CONTROL_TIERS.md` | Access tiers and role concepts exist in policy/docs. Role checks exist in scripts (for example `scripts/helpers/ckrole.sh`, role-gated flows in `scripts/bin/mrgup`). | Keep concept; consolidate content into canonical docs. | `docs/md/Contributor_Guide.md`, `docs/md/Contributor_Reference.md` | Create merged access-control section updates, then archive or retire obsolete source doc. |
| `obsolete/PUBLIC_REPO_SECURITY.md` | Security and branch-protection concepts are reflected in guides/workflows. | Keep concept; consolidate normative policy text into canonical docs. | `docs/md/Contributor_Guide.md` | Extract enforceable policy statements and move to canonical sections. |
| `obsolete/SCRIPT_ACCESS_CONTROL.md` | Script RBAC is implemented in helper/script behavior (`ckrole.sh`, protected merge checks, review behavior). | Keep concept; consolidate script-level reference details. | `docs/md/Contributor_Reference.md` (primary), `docs/md/Contributor_Guide.md` (summary) | Merge command-level role tables and examples into reference doc. |
| `docs/GIT_HOOKS_WORKFLOW.md` | Redundant after canonical hook/workflow coverage was completed in `docs/md/Contributor_Guide.md` and `docs/md/Contributor_Reference.md`. | Retire redundant doc. | `docs/md/Contributor_Guide.md`, `docs/md/Contributor_Reference.md` | Completed: consolidated and removed redundant workflow document. |
| `obsolete/SETUP_FIRST_CLONE.md` | Onboarding guidance exists but has drift from current scripts. Current implementation uses `setupclone` and `scripts/helpers/install-git-hooks.sh` with `core.hooksPath`; `mkclone` now invokes `setupclone` directly. | Keep concept; reconcile onboarding docs with script behavior. | `docs/md/Guide.md`, `docs/md/Contributor_Guide.md`, `docs/md/Contributor_Reference.md` | Update canonical onboarding text to describe current setup behavior and retire obsolete onboarding guidance. |
| `docs/IMPLEMENTATION_PLAN_GIT_HOOKS.md` | Historical implementation plan document; not canonical runtime behavior spec. | Keep as temporary planning artifact. | Optional summary in `docs/md/Contributor_Reference.md` if still relevant | Mark as historical/plan and avoid treating as current truth source. |
| `docs/PHASE_4_TESTING_CHECKLIST.md` | Historical test checklist; may not represent current test harness layout/coverage exactly. | Keep as temporary test artifact. | `docs/md/Contributor_Reference.md` (if test workflows need canonical summary) | Validate checklist against current test scripts before migration. |
| `docs/IMPLEMENTATION_COMPLETE.md` | Historical completion report with formatting artifacts and point-in-time claims. | Keep temporarily only for traceability; do not use as normative documentation. | None required; optionally archive summary in reports/history docs | Replace with concise status note or archive later. |
| `docs/PROJECT_STATUS.md` | Historical status snapshot; not source of truth for current behavior. | Keep temporarily for audit/history only. | None required | Archive later after key facts are captured elsewhere. |
| `docs/SCM_REVIEW.md` | Design/review guidance; some recommendations are implemented, some are policy-level. | Keep as review artifact; integrate only approved normative rules. | `docs/md/Contributor_Guide.md` | Pull stable policy decisions into canonical guide; keep review as background. |
| `docs/WORKFLOW_ARCHITECTURE.md` | Architecture reference appears relevant to workflow structure and maintenance. | Keep concept; integrate concise maintainer-facing guidance where needed. | `docs/md/Contributor_Reference.md` | Move enduring maintenance rules/examples into reference doc. |

---

## Key Gaps Requiring Decision

### 1) Onboarding script/docs drift

Current evidence shows onboarding flow needed a command-path alignment:

- `setupclone` is present and documents hook setup via `core.hooksPath`.
- `scripts/helpers/install-git-hooks.sh` exists and configures versioned hooks.
- `mkclone` now runs `scripts/bin/setupclone`, aligning clone setup with the canonical setup command.

Decision resolution:

- Implemented: `mkclone` invokes `setupclone` directly.

### 2) Canonical scope boundary

`docs/md/` is the canonical long-lived documentation set.
Top-level `docs/*.md` files remain temporary until each item is verified and either integrated or retired.

---

## Canonical Documentation Update Plan

1. Access and security consolidation
- Merge approved, non-duplicative policy text from:
  - `obsolete/ACCESS_CONTROL_TIERS.md`
  - `obsolete/PUBLIC_REPO_SECURITY.md`
  - `obsolete/SCRIPT_ACCESS_CONTROL.md`
- Targets:
  - `docs/md/Contributor_Guide.md` (policy summary)
  - `docs/md/Contributor_Reference.md` (script details)

2. Onboarding and workflow consolidation
- Reconcile:
  - `obsolete/SETUP_FIRST_CLONE.md`
- Targets:
  - `docs/md/Guide.md`
  - `docs/md/Contributor_Guide.md`
  - `docs/md/Contributor_Reference.md`

3. Historical/report artifacts handling
- Keep in place for now:
  - `IMPLEMENTATION_COMPLETE.md`
  - `IMPLEMENTATION_PLAN_GIT_HOOKS.md`
  - `PHASE_4_TESTING_CHECKLIST.md`
  - `PROJECT_STATUS.md`
- After consolidation, either archive or remove based on approver decision.

---

## Implementation Status (Updated: 2026-07-17)

### Git Hooks Item - ✅ FULLY RESOLVED

**Option A Selected and Implemented:**

- ✅ Created full hook enforcement system:
  - `orchestrator.sh` - Common enforcement logic
  - `pre-commit` - Blocks `git add`/`git commit`
  - `pre-push` - Blocks `git push`
  - `pre-merge-commit` - Blocks `git merge`
  - `post-checkout` - Auto-configures git identity (existing)
  
- ✅ Updated canonical documentation:
  - `docs/md/Contributor_Guide.md` - Section 4.5 expanded to 8 subsections
  - `docs/md/Contributor_Reference.md` - Section 2.5 with comprehensive reference
  
- ✅ `setupclone` established as the canonical setup command
- ✅ Verified all hooks syntax-valid and configured via `core.hooksPath`
- ✅ Archived 4 temporary docs to `obsolete/`

**Follow-up verification (2026-07-23):**

- ✅ Hook path/orchestrator resolution updated for `core.hooksPath` runtime.
- ✅ Canonical docs updated to `GIT_BYPASS_HOOKS` terminology.
- ✅ Redundant `docs/GIT_HOOKS_WORKFLOW.md` removed after consolidation.
- ✅ `scripts/bin/mkclone` now invokes `scripts/bin/setupclone` directly.

### Remaining Consolidation Items

The following documentation areas still require consolidation into canonical docs:

| Item | Status | Priority |
|------|--------|----------|
| Access control tiers | Not started | Medium |
| Public repo security | Not started | Medium |
| Script access control (RBAC) | Not started | Medium |
| Setup/first clone workflows | Not started | Low |
| Workflow architecture | Not started | Low |

---

## Next Review Checklist

**COMPLETED:**
- [x] Decide Option A vs Option B for Git hooks documentation/implementation alignment.
- [x] Verify each claim selected for migration with current scripts/workflows.
- [x] Draft canonical updates in `docs/md/Contributor_Guide.md` and `docs/md/Contributor_Reference.md`.
- [x] Archive temporary implementation documents to `obsolete/`.

**PENDING:**
- [ ] Run docs QA/style checks (can verify all links and formatting are correct).
- [ ] Consolidate remaining items from `obsolete/ACCESS_CONTROL_TIERS.md`, `obsolete/PUBLIC_REPO_SECURITY.md`, `obsolete/SCRIPT_ACCESS_CONTROL.md` into canonical docs.
- [ ] Consolidate remaining onboarding guidance from `obsolete/SETUP_FIRST_CLONE.md` into canonical docs.
- [x] Resolve onboarding script drift: `mkclone` now invokes `scripts/bin/setupclone`.
- [ ] Approver sign-off before enforcing strict no-root-docs policy.

---

## Implementation Summary

**Git Hooks Infrastructure:** Fully implemented and documented. All enforcement hooks active. Developers can no longer bypass script-based workflow via direct git commands.

**Documentation:** Transition from temporary implementation docs to canonical long-lived guides is in-progress (git hooks consolidated; access control/security/RBAC and onboarding consolidation pending).

**Next Phase:** Resolve onboarding script drift, consolidate remaining security/access-control/onboarding documentation, then complete approver sign-off.
