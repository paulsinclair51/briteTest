# Brand Name and Tagline

This file defines the current brand name and tagline (logos) for use by
scripts/updatelogos and provides a history of changes.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `LICENSE` in the root directory.

See `docs/Contributor_Guide.md` for details on changing the brand name and tsgline.

## 1. Introduction

Special lines in this file:

- **Replacement line**: "- Replace: old_phrase = new_phrase" (allowed,
  case-sensitive). Insert this line for each name/phrase change before the
  latest completion line with additional commentary for the change, then run
  scripts/updatelogos to update the logos in the documentation.

- **Completion line**: "Completed: datetime.".
  scripts/updatelogos inserts a completion line before the first replacement
  line.

## 2. Change History

### Rename Brand to briteTest
- Replace: BriteTest = briteTest

### Rename Brand to BriteTest
Completed: 2026-06-20 18:00:00.
- Replace: LiteTest = BriteTest

### Initial Definitions
Completed: 2026-06-01 12:20:34.
- Brandname: LiteTest
- Tagline: Catch it before it breaks.
