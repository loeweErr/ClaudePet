# Contributing a skin

Welcome — and thanks for thinking about ClaudePet's wardrobe.

## Quick path

1. Fork `loeweErr/claude-pet-skins`
2. Create `skins/<your-id>/palette.json` (see `skins/example/palette.json` for the template)
3. Pick 10 hex colors that go well together; preview locally by symlinking your skin folder into `~/Library/Application Support/ClaudePet/skins/` and switching via the menu
4. Open a PR titled `Add <skin id>`

CI will run `python3 scripts/validate.py` against your palette. Green check = ready for review.

## Skin id rules

- Lowercase letters, digits, hyphens only — e.g. `twilight`, `sakura-cat`, `terminal-amber`
- Should hint at the look or vibe, not at the author's name
- Avoid clashes with built-in ids (`mochi`, `shadow`, `snow`) and ids already merged in the `skins/` directory

## Design tips

- The cat is 64×80 viewport units, drawn in big chunky rectangles. Subtle gradients won't read — bold, contrasty palettes look best
- The `iris` slot is the single most personality-defining color. Test it last and tune until the cat "looks at you"
- If you're recoloring an existing built-in, change `primary`, `primaryDark`, `primaryLight`, `iris`, and `accent` — leave `belly`, `cheek`, `cheekDeep`, `eye` near defaults to keep the rendering legible
- Want to share a screenshot? Run ClaudePet with your skin, screenshot the cat in idle, and add `skins/<your-id>/preview.png` (320×320) — README's preview table picks it up

## License

You must include a `license` field in `palette.json`. Default to **MIT** or **CC0** unless your art was derived from something with stricter terms.

## Style review

Maintainers may comment on color choices for accessibility (very low contrast → animation hard to read on most desktops) or category overlap (3 nearly-identical pastels already merged). Suggestions are advisory — most well-formed skins get merged.

## After merge

Your skin appears at the next sync of the in-app "浏览社区皮肤" gallery. It also becomes installable via the curl one-liner in the main README.
