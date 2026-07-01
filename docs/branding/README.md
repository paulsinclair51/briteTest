# docs/branding/

Directory containing assets for the brand name and monogram.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `LICENSE` in the root directory.

See `README.md` in the root directory for an introduction to the project.

## Files

- **`canary-live.svg`**: photo of a yellow canary with transparent background
   perched on partially removed branch.

- **`canary.svg`**: Canary accent: traced from canary-live.svg with canary
  yellow fill, added black dot eye, and overlaid triangle for beak.

- **`Monogram.svg`**: Monogram-only `bT` with canary accent perched on T in a
  rounded-square.

- **`Logo_with_BrandName.svg`**: monogram and brand name with transparent background.

- **`Logo_with_Tagline.svg`**: monogram, brand name, and tagline
  "Catch it before it breaks." with transparent background.

- **`<doctitle>.svg`**: monogram, brand name, and doctitle (for a document in `docs`)
  with transparent background.

- `*.png`: generated `.png` files corresponding to each `*.svg` file.

- **README.md**: This directory guide.

Note: The root `README.md` is a link to docs/md\/<brandname\>.md that uses
the `Logo_with_Brandname.png` generated from Logo_with_BrandName.svg`.

## Subdirectories

- None.

## Generation

Use `../../scripts/bin/genpng` to regenerate the PNG exports from the SVG sources.

Source-of-truth policy:

- `*.svg` files are the authoritative source for branding artwork.
- `*.png` files are generated artifacts converted from the SVG files.
- Do not edit PNG files directly; edit the corresponding SVG file and
  regenerate PNGs.

## Palette

- Charcoal: `#1F2430` (monogram rounded-square background)
- Canary Yellow: `#FFEB66` (canary body, `b` in the monogram)
- Near-white: `#F7F8FA` (`T` in the monogram)
- Black: `#000000` (eye)
- Beak: `#F4A300` (natural canary horn)

## Tracking Note

On 2026-06-20, the project owner selected the canary monogram as the preferred
logo, requested deleting alternate drafts, and requested a brighter yellow.
This change is user-directed to record partial human design authorship.

Selected tagline for the monogram logo: "Catch it before it breaks."

On 2026-06-20, the project owner requested additional bird-shape refinement:
the tail element was removed and the beak was changed to point straight out.

On 2026-06-20, the project owner requested canary-clarity refinements:
the beak was shortened, a crest was added, a perch line was added, a cheek
patch was added around the eye, and head/body proportions were adjusted.

On 2026-06-20, the short perch line was removed by request because the canary
is already visually perched on the top of the LT monogram.

On 2026-06-20, the beak color was changed from #D8A56A to #CFA07F (a slightly
pinkish natural horn tone, more realistic for a canary). Palette updated.

On 2026-06-20, the palette was cleaned up to reflect only colors actually in use.
Slate (#4A5568) and Signal Red (#E4572E) were removed from the palette.
The tagline text was changed from slate to charcoal (#1F2430) to simplify the
color set. Undocumented colors (#FCFCFD, #F7F8FA, #FFF5B5) were added to the palette.

On 2026-06-20, the crest and cheek patch were removed by request. #FFF5B5
removed from palette as it is no longer in use.

On 2026-06-20, PNG exports were added for SVG variants.
Use `scripts/bin/genpng` to regenerate them from the SVG sources.

On 2026-06-21, SVG and PNG files added for logo with document title.

On 2026-06-21, the beak color was changed from #CFA07F to #F4A300 for improved
contrast and visual clarity. Palette updated.
