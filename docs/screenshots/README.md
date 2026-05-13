# Screenshots checklist

Three images are referenced from the main README and need to be captured by hand. Save them at the exact filenames below — they are linked by relative path.

## 1. `hero.png`

**Goal**: a single image that explains the product in one frame.

- Composition: cat on desktop **+** menu bar ✦ status panel popped open
- Wallpaper: clean (solid color or soft gradient)
- Cat skin: `mochi` (the default) — viewers expect what the install gives them
- Cat pose: idle or wave (warm), not sleep
- Status panel should show recognizable values (mood reasonable, day count > 1, bond at least "familiar")

How to grab:
```bash
# Cmd+Shift+4 then space-click the popover (captures only it),
# or Cmd+Shift+5 → "Capture Selected Portion" with the cat + popover both in frame.
```

Recommended size: ≤ 1600px wide, PNG, < 800KB.

## 2. `skins.png`

**Goal**: show that the cat has personality variations.

- Three side-by-side captures of the same idle pose with skins `mochi`, `shadow`, `snow`
- Easiest path: take three small screenshots one at a time, then tile in Preview / Pixelmator
- Background: same wallpaper for all three; keep margins consistent
- Add a tiny caption under each (the skin id) for clarity — optional

Recommended size: ≤ 1600px wide, PNG, < 600KB.

## 3. `claude-desktop.png`

**Goal**: show the loop closing — user types → Claude calls a `pet_*` tool → cat reacts.

- Composition: Claude Desktop window on the left with a short conversation visible:
  - User: "feed the cat"
  - Claude: any short reply that mentions `pet_feed`
- Cat visible on the right side of frame in `eat` pose, ideally with crumb particles still in-flight
- Tool call expansion in Claude Desktop should be visible if possible (shows `pet_feed` was actually invoked)

Recommended size: ≤ 1600px wide, PNG, < 800KB.

## After capture

1. Drop the three PNGs in this directory.
2. Verify the README references at `docs/screenshots/{hero,skins,claude-desktop}.png` resolve on GitHub.
3. Optional: also commit a `hero.webp` for ~50% size savings — GitHub renders WebP fine.
