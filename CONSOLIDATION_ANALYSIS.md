# Analysis: Consolidating Common Code in ck* Scripts

## Executive Summary

**Recommendation: KEEP SCRIPTS SELF-CONTAINED** (for now)

While there is ~70-80 lines of common boilerplate per script, consolidation would introduce **hidden coupling costs** that likely exceed the DRY maintenance benefits. Revisit this decision if you add 5+ validation scripts.

---

## Code Analysis

### Common Code Identified

**~210-240 total lines could be consolidated (~15% of total codebase):**

1. **Report generation infrastructure** (~15 lines/script)
   ```bash
   RUN_TS_FILE="$(date '+%Y%m%d-%H%M%S')"
   RUN_TS_DISPLAY="$(date '+%Y-%m-%d %H:%M:%S')"
   RUN_OUTPUT_FILE="$(mktemp)"
   REPORT_FILE/RUN_LOG_FILE=""
   ```

2. **Output capture function** (~3 lines, identical)
   ```bash
   setup_output_capture() {
     exec > >(tee "$RUN_OUTPUT_FILE") 2>&1
   }
   ```

3. **Trap handler for report writing** (~29-30 lines/script, 85% identical)
   - Differences: Script name in header, report file pattern, variable naming

4. **Repository discovery** (~8 lines/script)
   ```bash
   repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
   # Validate reports directory exists
   if [[ ! -d "$repo_root/reports" ]]; then...
   ```

5. **Argument parsing** (~10 lines/script, identical pattern)
   ```bash
   while [[ $# -gt 0 ]]; do
     case "$1" in
       -h|--help) usage; exit 0 ;;
   ```

6. **Exit code constants** (~3 lines, identical)
   ```bash
   readonly EXIT_OK=0
   readonly EXIT_VALIDATION=1
   readonly EXIT_USAGE=2
   ```

### Unique Code Per Script

| Script | Total | Validation Logic | % Common |
|--------|-------|------------------|----------|
| ckversions | 455 lines | ~300 lines (version extraction, consistency, branch policy) | 34% |
| ckdocs | 539 lines | ~400 lines (SVG, headings, details tags, TOC) | 26% |
| ckdirectory_guides | 641 lines | ~500 lines (files section, subdirs section, canonicalization) | 22% |
| **Total** | **1,635 lines** | **~1,200 lines** | **~27%** |

---

## Arguments FOR Consolidation

### Advantages

1. **DRY Principle**
   - Don't repeat the same 70-80 lines three times
   - Single source of truth for report generation pattern

2. **Easier Maintenance**
   - Bug fix in trap handler → fix once, benefit all three
   - Pattern improvements propagate automatically
   - Example: If we later want to add email notifications or Slack alerts, update helper once

3. **Consistency Guarantee**
   - Impossible to accidentally have different behavior between scripts
   - Ensures all future scripts use same pattern

4. **Easier to Add New Scripts**
   - New validation script → source helper, focus only on validation logic
   - No boilerplate to copy/paste

---

## Arguments AGAINST Consolidation

### Disadvantages (More Significant)

1. **Abstraction Complexity vs. Benefit**
   - Common code is **straightforward boilerplate**, not complex logic
   - Boilerplate is easier to understand when it's inline vs. buried in a helper
   - Current scripts are immediately readable: "These are self-contained validators"

2. **Parameterization Complexity**
   - Helper would need parameters for:
     - Script name (for report header: "# ckversions Report" vs "# ckdocs Report")
     - Report pattern (for cleanup: "versions-*.md" vs "docs-*.md" vs "directory_guides-*.md")
     - Variable names (`REPORT_FILE` vs `RUN_LOG_FILE`)
   - This adds complexity to the abstraction layer

3. **Coupling Risk**
   - If helper breaks, all three scripts break simultaneously
   - Currently: bug in ckversions only affects ckversions
   - Harder to debug issues: "Is the problem in my script or the helper?"

4. **Versioning & Testing Complexity**
   - Each script currently independently testable
   - With shared helper: need to test helper + all three scripts
   - Regression in helper could cascade

5. **Script Independence (Conceptual)**
   - These are conceptually three independent validators
   - Sharing code creates artificial dependency
   - Someone reading ckversions may not realize it depends on helper functions
   - Makes it harder to copy/adapt scripts to other projects

6. **Low Code Size Benefit**
   - Only saving ~240 lines total (~4.3 KB)
   - Marginal disk/performance benefit in 2026 world
   - Cognitive overhead of abstraction layer likely exceeds the savings

7. **Evolution Path**
   - ckdirectory_guides uses `RUN_LOG_FILE`, others use `REPORT_FILE`
   - Different variable naming suggests they might diverge further
   - If one validator needs special behavior, helper becomes bloated with conditionals

8. **Existing Pattern in Repo**
   - `/scripts/helpers/common.sh` has lightweight utility functions (output helpers, branch detection)
   - These are **generic utilities**, not **framework abstractions**
   - Current helper philosophy: "Small, focused, reusable utilities" not "boilerplate abstraction"

---

## Concrete Example: What Helper Would Look Like

```bash
# scripts/helpers/ck_report.sh
source_ck_report_helpers() {
  local script_name="$1"        # "ckversions", "ckdocs", etc.
  local report_pattern="$2"     # "versions", "docs", "directory_guides"
  local report_var_name="$3"    # "REPORT_FILE" or "RUN_LOG_FILE"
  
  # Initialize timestamps
  RUN_TS_FILE="$(date '+%Y%m%d-%H%M%S')"
  RUN_TS_DISPLAY="$(date '+%Y-%m-%d %H:%M:%S')"
  RUN_OUTPUT_FILE="$(mktemp)"
  
  setup_output_capture() {
    exec > >(tee "$RUN_OUTPUT_FILE") 2>&1
  }
  
  # The trap handler becomes complex here:
  # - How to reference $REPORT_FILE vs $RUN_LOG_FILE?
  # - How to handle different cleanup patterns?
  # - Need eval or indirect variable references (error-prone)
}

# Then in each script:
source ../helpers/ck_report.sh
source_ck_report_helpers "ckversions" "versions" "REPORT_FILE"
```

**Problem**: This abstraction is now **harder to read** than just having the code inline.

---

## Alternative Lightweight Approach (If You Proceed)

If you decide to consolidate, do it **minimally**:

```bash
# scripts/helpers/ck_report_setup.sh - Just helper functions, no abstraction

setup_ck_directories() {
  repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  if [[ ! -d "$repo_root/reports" ]]; then
    echo "ERROR: reports directory not found: $repo_root/reports" >&2
    exit 1
  fi
  printf '%s\n' "$repo_root"
}

create_ck_report() {
  local report_file="$1"
  local script_name="$2"
  local output_file="$3"
  local cleanup_pattern="$4"
  
  local exit_code="$?"
  {
    echo "# $script_name Report"
    echo "**Timestamp:** $RUN_TS_DISPLAY"
    # ... rest of report ...
  } > "$report_file"
  
  # Cleanup with provided pattern
  if [[ -f "$report_file" ]]; then
    for old in $cleanup_pattern; do
      [[ "$old" == "$report_file" ]] && continue
      rm -f "$old"
    done
  fi
}
```

**Pros**: Reusable functions without tight coupling
**Cons**: Still need parameters, arguably no cleaner than current approach

---

## Recommendation

### Keep Self-Contained Scripts IF:

✅ **You have 3 validators** (current state)
✅ **Changes are infrequent** to boilerplate
✅ **Scripts are stable** (unlikely to add 10+ more validators)
✅ **Each script might evolve differently** (e.g., ckversions might want different report format)

**Pros of current approach:**
- Maximize readability and independence
- Each script fully self-contained and copyable
- Minimal coupling risk
- Straightforward debugging

### Consolidate IF:

⚠️ You add 5+ more validation scripts
⚠️ You find yourself frequently maintaining the same boilerplate fix in 3+ places
⚠️ You want a standardized framework for validators

---

## Decision Matrix

| Scenario | Recommendation |
|----------|-----------------|
| 3 validators (current) | **KEEP SELF-CONTAINED** |
| 3 validators + frequent boilerplate changes | **WAIT, assess in 6 months** |
| 5+ validators | **START CONSOLIDATION** |
| 10+ validators | **MANDATORY CONSOLIDATION** |

---

## Action Items (Current)

**Today**: Keep as-is (self-contained scripts)

**If adding more validators (3, 4, 5 total)**: Add to `/scripts/helpers/ck_report_setup.sh` as **optional helper functions**, not required framework

**Example**:
```bash
# scripts/bin/ckfoo (new validator)
source ../helpers/ck_report_setup.sh

# Optional - use helper if you want consistency
repo_root="$(setup_ck_directories)" || exit 1

# Or inline if you prefer
# repo_root="$(cd "$(dirname "$0")/../.." && pwd)"

# ... rest of validation script
```

This gives you the **option** of consolidation without forcing it.

---

## Summary

The ~70-80 lines of common code are valuable for **understanding the pattern once**, but consolidating them would:
- Add abstraction complexity (parametrization, indirection)
- Create coupling between independent scripts
- Make debugging harder
- Violate the "each script is self-contained" principle

**The cost of the abstraction layer exceeds the DRY benefit** at the current scale (3 scripts, 27% common code).

**Revisit this decision at 5+ validators or when you find yourself making the same boilerplate fix across all scripts multiple times.**
