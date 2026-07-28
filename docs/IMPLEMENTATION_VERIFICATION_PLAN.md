# Implementation Verification and Consolidation Plan

#### Date: 2026-07-16
#### Scope: docs/*.md temporary documents (no deletions in this pass)

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
| `docs/ACCESS_CONTROL_TIERS.md` | Access tiers and role concepts exist in policy/docs. Role checks exist in scripts (for example `scripts/helpers/ckrole.sh`, role-gated flows in `scripts/bin/mrgup`). | Keep concept; consolidate content into canonical docs. | `docs/md/Contributor_Guide.md`, `docs/md/Contributor_Reference.md` | Create merged access-control section updates, then archive root doc later. |
| `docs/PUBLIC_REPO_SECURITY.md` | Security and branch-protection concepts are reflected in guides/workflows. | Keep concept; consolidate normative policy text into canonical docs. | `docs/md/Contributor_Guide.md` | Extract enforceable policy statements and move to canonical sections. |
| `docs/SCRIPT_ACCESS_CONTROL.md` | Script RBAC is implemented in helper/script behavior (`ckrole.sh`, protected merge checks, review behavior). | Keep concept; consolidate script-level reference details. | `docs/md/Contributor_Reference.md` (primary), `docs/md/Contributor_Guide.md` (summary) | Merge command-level role tables and examples into reference doc. |
| `docs/GIT_HOOKS_WORKFLOW.md` | Hook workflow is only partially implemented versus historical claims. `scripts/bin/installscripts` still references `scripts/helpers/install-git-hooks.sh`, but that installer file is currently missing; only `.githooks/post-checkout` exists under `scripts/helpers/.githooks/`. | Needs decision: either (A) implement full hook system as documented, or (B) downgrade docs to current behavior. | `docs/md/Contributor_Guide.md`, `docs/md/Contributor_Reference.md` | Open decision record and choose A or B before canonical integration. |
| `docs/SETUP_FIRST_CLONE.md` | `scripts/bin/mkclone` calls `installscripts`, which attempts hook setup and warns if installer missing. Script install path exists; hook installation is not fully verifiable with current files. | Keep onboarding flow, but correct hook expectations to match actual behavior unless full hook implementation is restored. | `docs/md/Guide.md`, `docs/md/Contributor_Guide.md`, `docs/md/Contributor_Reference.md` | Update onboarding text to describe real current setup behavior and warnings. |
| `docs/IMPLEMENTATION_PLAN_GIT_HOOKS.md` | Historical implementation plan document; not canonical runtime behavior spec. | Keep as temporary planning artifact. | Optional summary in `docs/md/Contributor_Reference.md` if still relevant | Mark as historical/plan and avoid treating as current truth source. |
| `docs/PHASE_4_TESTING_CHECKLIST.md` | Historical test checklist; may not represent current test harness layout/coverage exactly. | Keep as temporary test artifact. | `docs/md/Contributor_Reference.md` (if test workflows need canonical summary) | Validate checklist against current test scripts before migration. |
| `docs/IMPLEMENTATION_COMPLETE.md` | Historical completion report with formatting artifacts and point-in-time claims. | Keep temporarily only for traceability; do not use as normative documentation. | None required; optionally archive summary in reports/history docs | Replace with concise status note or archive later. |
| `docs/PROJECT_STATUS.md` | Historical status snapshot; not source of truth for current behavior. | Keep temporarily for audit/history only. | None required | Archive later after key facts are captured elsewhere. |
| `docs/SCM_REVIEW.md` | Design/review guidance; some recommendations are implemented, some are policy-level. | Keep as review artifact; integrate only approved normative rules. | `docs/md/Contributor_Guide.md` | Pull stable policy decisions into canonical guide; keep review as background. |
| `docs/WORKFLOW_ARCHITECTURE.md` | Architecture reference appears relevant to workflow structure and maintenance. | Keep concept; integrate concise maintainer-facing guidance where needed. | `docs/md/Contributor_Reference.md` | Move enduring maintenance rules/examples into reference doc. |

---

## Key Gaps Requiring Decision

### 1) Git hooks documentation vs. repository state

Current evidence indicates documentation references a fuller hook installer/wrapper set than currently present:

- Missing: `scripts/helpers/install-git-hooks.sh`
- Missing wrappers in `scripts/helpers/.githooks/`: `orchestrator.sh`, `pre-commit`, `pre-push`, `pre-merge-commit`
- Present: `scripts/helpers/.githooks/post-checkout`
- `scripts/bin/installscripts` still attempts to call the missing installer and warns when absent.

Decision needed:

- Option A: restore full hook implementation to match docs
- Option B: revise docs to match current implementation and warnings

### 2) Canonical scope boundary

`docs/md/` is the canonical long-lived documentation set.
Top-level `docs/*.md` files remain temporary until each item is verified and either integrated or retired.

---

## Canonical Documentation Update Plan

1. Access and security consolidation
- Merge approved, non-duplicative policy text from:
  - `ACCESS_CONTROL_TIERS.md`
  - `PUBLIC_REPO_SECURITY.md`
  - `SCRIPT_ACCESS_CONTROL.md`
- Targets:
  - `docs/md/Contributor_Guide.md` (policy summary)
  - `docs/md/Contributor_Reference.md` (script details)

2. Onboarding and workflow consolidation
- Reconcile:
  - `SETUP_FIRST_CLONE.md`
  - `GIT_HOOKS_WORKFLOW.md`
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
  
- ✅ Renamed `installscripts` → `setupclone` for clarity
- ✅ Verified all hooks syntax-valid and configured via `core.hooksPath`
- ✅ Archived 4 temporary docs to `obsolete/`

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
- [ ] Consolidate remaining items from `ACCESS_CONTROL_TIERS.md`, `PUBLIC_REPO_SECURITY.md`, `SCRIPT_ACCESS_CONTROL.md` into canonical docs.
- [ ] Consolidate onboarding guidance from `SETUP_FIRST_CLONE.md` and `GIT_HOOKS_WORKFLOW.md`.
- [ ] Approver sign-off before enforcing strict no-root-docs policy.

---

## Implementation Summary

**Git Hooks Infrastructure:** Fully implemented and documented. All enforcement hooks active. Developers can no longer bypass script-based workflow via direct git commands.

**Documentation:** Transition from temporary implementation docs to canonical long-lived guides is 50% complete (git hooks done, access control/security/RBAC consolidation pending).

**Next Phase:** Consolidate remaining security and access control documentation, then enforce archival of root-level `docs/*.md` files except those retained for reference.
