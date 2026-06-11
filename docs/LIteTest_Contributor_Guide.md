# LiteTest Contributor Guide

This guide describes how to contribute to LiteTest safely and consistently.

---

## 1. Branching and Workflow

- Create a feature branch for all work  
  Examples:  
  - `docs/update-user-guide`  
  - `feature/new-macro`  
  - `fix/guard-level-bug`  

- Do not commit directly to `main` without maintainer approval.  
- Keep commits focused and include clear commit messages.  

---

## 2. Versioning Policy

LiteTest uses semantic versioning:

- **Major** — incompatible API changes  
- **Minor** — backward‑compatible additions  
- **Patch** — bug fixes or implementation improvements  

When updating the version:

- Update `LT_VERSION` in `litetest.h`  
- Update `LT_VERSION_C` in `litetest.c`  

API compatibility rules:

- Public APIs are additive by default  
- Do not change existing signatures  
- Do not change return code meanings  
- New behavior must be opt‑in  
- Deprecate before removing  
- Provide migration guidance for major changes  

---

## 3. Testing

- Build and run tests from the repository root:

  ```sh
  make run
  ```

- Ensure report formatting changes are reflected in documentation examples.  
- Keep test code aligned with the current version of `litetest.h`.  

---

## 4. Documentation Rules

- README.md must remain short and onboarding‑focused  
- User Guide contains conceptual explanations and examples  
- API Reference contains public API definitions only  
- Framework documentation (internal) must not leak into public docs  
- Update documentation when modifying macros, behavior, or report format  

---

## 5. Code Style

- C99  
- POSIX.1‑2001 APIs only  
- Keep `litetest.h` self‑contained  
- Keep `litetest.c` implementation‑only  
- Avoid intermixing test code with helper logic inside test group functions  

---

## 6. Pull Requests

Before submitting a PR:

- Ensure tests pass  
- Update version numbers if needed  
- Update documentation as needed  
- Keep changes focused and well‑scoped  
