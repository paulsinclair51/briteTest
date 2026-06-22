# BriteTest Logo

This folder contains SVG and PNG logo assets for BriteTest using a canary theme.

## Files

- `canary.svg`: Traced standalone canary silhouette as vector artwork.
- `canary2.svg`: Standalone canary silhouette with legs and feet accented in the beak palette.
- `BriteTest_Logo.svg`: Monogram-only LT logo with canary accent.
- `BriteTest_Logo.png`: Monogram-only LT logo with canary accent (PNG export).
- `BriteTest_Logo_with_BriteTest.svg`: LT monogram with canary accent and BriteTest
  wordmark.
- `BriteTest_Logo_with_BriteTest.png`: LT monogram with canary accent and BriteTest
  wordmark (PNG export).
- `BriteTest_Logo_with_Tagline.svg`: LT monogram with canary accent, BriteTest, and tagline
  "Catch it before it breaks."
- `BriteTest_Logo_with_Tagline.png`: LT monogram with canary accent, BriteTest, and tagline (PNG export).

## Generation

Use `../../scripts/genpng.sh` to regenerate the PNG exports from the SVG sources.

Source-of-truth policy:

- `BriteTest_*.svg` files are the authoritative source for branding artwork.
- `BriteTest_*.png` files are generated artifacts exported from the SVG files.
- Do not edit branding PNG files directly; edit the corresponding SVG file and regenerate PNGs.

## Palette

- Background: `#FCFCFD` (off-white)
- Charcoal: `#1F2430` (monogram, text, eye, wing cutout)
- Near-white: `#F7F8FA` (LT strokes)
- Canary Yellow: `#FFEB66` (body, crest, head)
- Beak: `#CFA07F` (natural canary horn)

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

On 2026-06-20, PNG exports were added for all three logo variants.
Use `scripts/genpng.sh` to regenerate them from the SVG sources.