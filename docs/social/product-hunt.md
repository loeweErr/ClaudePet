# Product Hunt — launch checklist + copy

A Product Hunt launch is a single-day window — most upvotes happen in the first 4 hours after midnight Pacific. Plan accordingly.

## Pre-launch (T - 7 days)

- [ ] Recruit a "hunter" (someone with reputation on PH) to submit, or self-submit and accept lower visibility
- [ ] Pick the launch date — **avoid Sunday/Monday** (Tue–Thu reach the most upvotes)
- [ ] Draft tagline + description (templates below)
- [ ] Have **5 assets ready**:
  - logo (240×240, transparent PNG)
  - thumbnail (1270×760)
  - 3 product screenshots (1270×760 each — use `docs/screenshots/{hero,skins,claude-desktop}.png`)
  - **demo gif** (the one from `docs/demo-script.md`)
- [ ] Line up 5–10 friends ready to comment on launch day (PH downranks accounts that only upvote-and-leave; comments help)
- [ ] Post a "launching tomorrow" tweet/小红书 with PH link (use the "ship" feature for this)

## Pre-launch (T - 1 day)

- [ ] Confirm timezone — Product Hunt day starts at **00:00 PT**. Set an alarm.
- [ ] Final draft of maker comment (template below) — paste it as the first comment in the first minute
- [ ] Verify all links open: GitHub repo, brew tap, install.sh
- [ ] If a demo deserves a video, embed a 30s YouTube/Vimeo URL in the listing

## Launch day (T)

- [ ] **00:00 PT** — submission goes live (auto-published if scheduled)
- [ ] **00:01 PT** — paste the maker comment
- [ ] **00:00–04:00 PT** — actively respond to every comment
- [ ] **08:00 PT** — push social once: short tweet + 小红书 + LinkedIn if applicable, all linking to the PH page (not GitHub — direct PH traffic is what counts)
- [ ] **18:00 PT** — gentle "thank you" reply to the top 5 commenters
- [ ] Don't recruit upvotes from your network in a coordinated way — PH detects and penalizes this

## Post-launch (T + 1)

- [ ] Pin the PH link to the GitHub README under "As featured in" if ranked top 5
- [ ] Reply to remaining comments within 24h
- [ ] Add an "as seen on Product Hunt" badge to the README if you ranked

## Copy templates

### Tagline (60 char max)

> A pixel cat that lives on your macOS desktop, driven by Claude

### Description (260 char max)

> Talk to Claude Desktop in natural language ("feed the cat", "let her sleep") and 10 MCP tools drive a transparent overlay cat with mood, hunger, energy, and bond stats. Open source, MIT, macOS 13+. Zero extra API auth.

### Maker's first comment (paste at 00:01 PT)

> Hey PH 👋 — I'm <name>, the maker.
>
> ClaudePet is a small Swift app that turns Claude Desktop into a window onto a desktop pet. The cat has bond points, days-together milestones, and 10 `pet_*` tools Claude can call ("feed the cat", "play with her", "make her sleep when I'm in a focus block").
>
> Two things I'm proud of:
>
> 1. **Zero new API surface.** ClaudePet uses Claude Desktop's existing authorization. There's no API key step. The "AI" experience is whichever model you're already paying for.
>
> 2. **Skins are palette JSON.** No PNG art needed. A new look = 10 hex codes. Three are bundled, community PRs welcome.
>
> Try it: `brew install --cask loeweErr/tap/claude-pet` (macOS 13+).
>
> Source: <https://github.com/loeweErr/ClaudePet>
>
> Happy to answer anything in the thread!

### Topics (PH categories)

- Productivity
- Mac
- Open Source
- Artificial Intelligence
- Developer Tools

### Pricing

- Free / open-source

## After launching

If the launch surfaces strong feedback (UI changes wanted, a category of skin people ask for, an MCP combo that wasn't on the recipe list), open a `feedback-from-PH` issue and triage. PH is a one-shot — feedback you collect is the actual long-term return.
