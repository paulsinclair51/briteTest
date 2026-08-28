# Implementation Verification and Consolidation Plan

#### Date: 2026-07-24
#### Scope: Remaining required work and optional follow-on improvements

SPDX-License-Identifier: MIT

---

## Purpose

This document tracks only work that is still pending or intentionally optional.
Historical consolidation tracking has been removed from this plan.

---

## Current State

- Canonical contributor and security/process documentation is under `docs/md/`.
- Top-level `docs/` policy is enforced as README-only.
- Obsolete top-level planning/review artifacts have been retired.
- SCM controls are operationally strong.
- Repository documentation/style conformance remediation is still in progress.

---

## Required Next Actions

1. Complete documentation/style remediation from latest validation output.
   - Latest run: `briteRepo/bin/ckstyle`
   - Latest report: `reports/guidelines/ckstyle-20260724-030122.md`

2. Re-run style validation until clean.
   - Success condition: no remaining conformance issues in current scope.

3. Keep canonical docs aligned with actual script/workflow behavior.
   - Update canonical docs when enforcement behavior changes.
   - Avoid reintroducing temporary top-level docs outside approved policy.

4. Complete pull-request trigger verification for branch validation workflows.
   - Retry draft PR creation from branch `mywork/pr-trigger-smoke-2` after
     transient GitHub API/GraphQL failures are resolved.
   - Confirm `.github/workflows/branch-validation-pull-request.yml` runs
     automatically on PR open/update events.
   - Confirm `.github/workflows/branch-name-validation.yml` remains
     manual-only (`workflow_dispatch`) to avoid duplicate automatic checks.
   - Record the verification outcome (run link/result) in the next status
     update.

---

## Completion Criteria (Required Track)

- `ckstyle` passes for the selected validation scope.
- No policy drift between canonical docs and implemented behavior.
- `docs/` top-level remains compliant with README-only policy.

---

## Optional Future Security Hardening (Non-Blocking)


- Add Dependabot update automation for supported ecosystems.
- Add CodeQL workflow coverage for additional static security analysis.
- Reassess protected-file patterns and secret-detection patterns quarterly.

---

## Optional Future Workflow Enhancements (Non-Blocking)

- Evaluate selective parallel execution for independent validation checks to
  reduce workflow wall-clock time.
- Maintain and periodically refresh workflow runtime baselines per validation
  family (PR-blocking vs audit).
- Consolidate repeated workflow snippets into reusable helper routines where it
  improves maintainability without reducing clarity.

---

## Optional Future RBAC Unification Plan (Non-Blocking)

### Objective

Unify script authorization checks behind shared helper entrypoints while
preserving current behavior and exit-code semantics.

### Current Baseline

- Role checks are enforced in active scripts (for example via `ckrole.sh`
  and script-local checks).
- Shared helper framework exists in `briteRepo/helpers/rbac.sh` but is not
  consistently used as the single enforcement path.

### Migration Principles

1. Preserve behavior first: no role-policy expansion during refactor.
2. Migrate script-by-script with parity tests.
3. Keep existing exit codes/messages stable for callers and tests.
4. Prefer feature-flag-style rollout over big-bang replacement.

### Phased Rollout

1. Policy Contract Freeze
- Document canonical role matrix, protected-operation rules, and owner-override
  semantics in one source of truth.

2. Helper Hardening
- Finalize `rbac.sh` helper contract (`enforce_script_access`,
  protected-operation checks, audit hooks).
- Add non-interactive tests for helper functions and role-resolution edge cases.

3. Pilot Migration
- Migrate 2-3 high-impact scripts first (recommended: `mrgup`, `release`,
  `rmbranch`).
- Compare before/after behavior using scripted role fixtures.

4. Incremental Adoption
- Migrate remaining role-gated scripts in small batches.
- Keep compatibility wrappers during transition where necessary.

5. Consolidation
- Remove duplicated script-local role logic only after parity is proven.
- Update canonical docs and script help text to match final enforcement model.

### Test Gate (Required Per Batch)

- Positive and negative role-path tests for C/R/A users.
- Protected-operation tests with and without required approvals/overrides.
- Identity resolution tests (`GITHUB_ACTOR`, `gh`, `git config user.name`).
- Exit code and message regression checks against existing script tests.

### Rollback Criteria

Rollback a migration batch immediately if any of the following occurs:
- Protected operations become less restrictive than baseline behavior.
- Existing script smoke tests fail on authorization paths.
- Exit-code compatibility breaks for supported workflows.

### Completion Criteria

- All role-gated scripts call shared RBAC helpers for authorization.
- Script-local duplicated role checks are removed or reduced to wrappers.
- Canonical docs (`docs/md/Contributor_Guide.md`,
  `docs/md/Contributor_Reference.md`) reflect final behavior.
