# Demo Recording Script

A 20–30 second clip for the README hero animation. Goal: a stranger scrolling past on social media should understand "this is a desktop cat that Claude controls" within the first 5 seconds.

## Setup checklist

- macOS desktop is clean (hide other windows / use a fresh Space)
- Wallpaper is calm and not distracting (a solid color or soft gradient works best)
- Claude Desktop is running and `claude-pet` MCP is registered
- ClaudePet GUI is already open with the cat visible
- Mood is fresh: hunger ≥ 60, mood ≥ 70 so the cat has lively idle animation
- Recording tool: macOS built-in (Cmd+Shift+5) or [Kap](https://getkap.co/) for direct GIF export
- Frame: capture an area that includes the cat **and** the menu bar ✦ icon **and** part of the Claude Desktop window

## Shot list (~25 seconds)

| t (s) | Action | What viewer sees |
|---|---|---|
| 0–2 | Idle | Pixel cat sits / breathes on the wallpaper. Caption overlay (optional): "ClaudePet — a cat in your menu bar" |
| 2–6 | In Claude Desktop type: `给猫喂点零食吧` (or English: `feed the cat a snack`) | Claude responds, calls `pet_feed`, cat shuffles toward the bowl, eats, **crumb particles** sprinkle |
| 6–10 | **Double-click the cat** | Cat reacts, **♡ heart particles** float up |
| 10–14 | Click the menu bar **✦** | Status panel pops out — show mood / hunger / days-together / bond level |
| 14–18 | Close the panel, back in Claude Desktop type: `让猫睡觉吧` (or `make the cat sleep`) | `pet_sleep` is called, cat curls up, **z z z** animation |
| 18–25 | Cat sleeps, slow zoom-out / fade. Final frame: cat sleeping + caption "Driven by Claude Desktop via MCP" |

## Export targets

- Primary: `docs/demo.gif` — width 800px, ≤ 5MB (GIF size budget for GitHub README)
- Backup: `docs/demo.mp4` — full-quality 1080p, useful for Twitter / Product Hunt
- If GIF >5MB, use [gifski](https://gif.ski/) at 12–15 fps with palette optimization

## Tips

- Pre-warm: trigger `pet_feed` once before recording so Claude Desktop has the tool warmed up — eliminates startup delay
- Mouse: hide the cursor when not interacting (Cmd+Shift+5 → Options → "Show Mouse Pointer" off)
- Captions: keep ≤ 4 words, sans-serif, white with subtle shadow. Avoid covering the cat
- Audio: GIF has no audio, but for the .mp4 version keep the meow + TTS audible — adds personality

## After recording

1. Place the final file at `docs/demo.gif`
2. Verify the README placeholder at `![demo](docs/demo.gif)` near the top of `README.md` and `README.zh-CN.md` renders correctly on GitHub
3. Optional: open a PR titled `docs: add demo gif` so it shows up cleanly in history
