# brand_history.md

This file defines the current or a change to brand name, brand
initials, and tagline for use by scripts/bin/updatebrand and
provides a history of changes.
 
Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `<repo>/LICENSE`.

See `<repo>/docs/md/Contributor_Guide.md` for details on changing the
brand name, brand initials, and tagline.

## Brand History

| Completed | Brand Name | Initials | Tagline |
|-----------|------------|----------|---------|
| 2026-07-03 15:35:15 | briteTest | bT | Catch it before it breaks. |
| 2026-05-24 15:30:45 | BriteTest | BT | Catch it before it breaks. |
| 2026-05-24 15:30:45 | LiteTest | LT | Catch it before it breaks. |

## Usage

To change the brand name or tagline,
- Add a new entry with no `Completed` date.
- Run `<repo>/scripts/bin/updatebrand`

updatebrand does the following if the first entry does not have `Completed`
date:
  - If `Initials` changed, update monogram `<repo>/docs/branding/Monogram.svg`
    files with `Initials` from the first entry.
  - If the `Brand Name` changed, updates logo `<repo>/docs/branding/Logo_with_*.svg`
    and `<repo>/docs/branding/<doctitle>.svg` files with the `Brand Name` from
    the first entry.
  - If the `Tagline` changed, updates `<repo>/docs/branding/Logo_with_Tagline.svg`
    with the `Tagline` from the first entry.
  - Regenerates `<repo>/docs/branding/*.png` files from the
   `docs/branding/*.svg` files.
  - Update `*.md` files in the repository replacing the last completed
    `Brand Name` with the `Brand Name` from the first entry.
  - Update `Completed` column for the first entry with the current date
    time.
