# PR description template — submitting ClaudePet to an awesome list

Adapt the snippet below to the receiving repo's conventions (some awesome lists want a single line, others a paragraph). Keep ClaudePet's pitch consistent across submissions so people who see it twice form a mental hook.

---

## Long form (paragraph + bullets)

> **Claude Pet** — A pixel cat that lives on your macOS desktop, controlled by Claude Desktop via MCP. Talk to Claude in natural language ("feed the cat", "let her sleep") and 10 `pet_*` tools drive a transparent overlay window with mood, hunger, energy, and bond stats. Zero extra API authorization — every conversation runs on Claude Desktop's authorized path.
>
> - macOS 13+, Swift, MIT
> - Install: `brew install --cask loeweErr/tap/claude-pet` or one-line installer
> - 4 starter recipes (Pomodoro, Calendar, Email, Git) for chaining with other MCP servers
> - Repo: <https://github.com/loeweErr/ClaudePet>

## Short form (single bullet)

> **[Claude Pet](https://github.com/loeweErr/ClaudePet)** — Pixel desktop cat for macOS, controlled by Claude Desktop via MCP. 10 `pet_*` tools, mood/bond/days-together stats, multi-skin. MIT.

## Single tweet-length form

> Claude Pet: pixel cat that lives on your macOS desktop, driven by Claude Desktop via MCP. https://github.com/loeweErr/ClaudePet

---

## Lists to submit to (manual)

- [ ] **GitHub MCP Registry** — submit at <https://github.com/mcp> (the official registry). Their submission flow is its own form, the long-form blurb above lines up with their fields.
- [ ] **`punkpeye/awesome-mcp-servers`** — open a PR adding ClaudePet under the most fitting category (likely "Lifestyle" or a new "Companion" category — leave a comment in the PR proposing the placement). Use the **short form**.
- [ ] **`hesreallyhim/awesome-claude-code`** — this list is Claude-ecosystem broad, ClaudePet fits the "Tools" or "Apps" section. Use the **short form**.
- [ ] **`appcypher/awesome-mcp-servers`** — same pattern as the punkpeye list, often distinct categorization. Use the **short form**.

For each PR, include:

1. The line/paragraph (above)
2. A small inline screenshot if the list allows it (use `docs/screenshots/hero.png`)
3. A link to a recipe doc as proof-of-utility (the [Focus Guard recipe](../../docs/recipes/focus-guard.md) reads well to outsiders)

## Acceptance target

Per the roadmap: at least **2 lists merged + 1 pending** counts as P2-1 done.

## Once merged

When a PR lands, edit this file to mark it done so future contributors see the trail. Optional: add a "As featured in: …" line to the main README's About section.
