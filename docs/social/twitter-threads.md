# Twitter / X — 5 thread drafts

Each thread is paste-ready. Tweak the voice, swap in real screenshots, post one thread per week to avoid burning out the audience.

Convention: `——` separates tweets in a thread. Demo gif lives at `docs/demo.gif` once recorded; substitute when posting.

---

## Thread 1 — The product story

> I built a pixel cat that lives on my macOS desktop. Claude Desktop talks to it through MCP — I say "feed the cat" and a bowl appears, crumbs scatter, the cat purrs. 10 tools, all local. Zero new API keys.
>
> [demo.gif]

——

> The point isn't the cat. The point is that LLM ↔ desktop is a thin barrier and MCP makes it almost embarrassingly easy. ClaudePet uses ~700 lines of Swift; the bridge to Claude Desktop is one JSON-RPC server and one Unix socket.

——

> What I didn't expect: the bond stat changes how I treat Claude. After two weeks I greet `mochi` differently. The AI side knows the cat is fictional but it adopts a softer register because the cat persists between sessions.

——

> Open source, MIT, macOS 13+. install: `brew install --cask loeweErr/tap/claude-pet`. Stars and PRs welcome — especially community skins (the cat is a palette away from being your cat). github.com/loeweErr/ClaudePet

---

## Thread 2 — Tech deep-dive

> If you want to give Claude Desktop a desktop UI, you don't need a custom client. ClaudePet is one MCP server (stdio) bridged to one GUI app (transparent NSWindow) over a Unix domain socket. Here's the loop:
>
> [diagram or code snippet screenshot]

——

> 1/ User talks to Claude Desktop. Claude sees `pet_*` tools.
> 2/ Claude calls e.g. `pet_feed`. The MCP server child process gets a `tools/call` over stdio.
> 3/ MCP server forwards as a JSON line to `/tmp/claude-pet.sock`.
> 4/ The GUI process receives it and animates the cat.

——

> Two non-obvious tricks:
> — `LSUIElement = true` so the app is menubar-only (no dock icon)
> — The MCP server auto-launches the GUI via `/usr/bin/open` if the socket isn't alive. Lazy boot, zero supervisor.

——

> 53 unit tests cover the mood decay formulas, JSON-RPC parsing, and the 10-slot palette codec. CI on macOS-13 + 14. The whole thing builds with `swiftc` if you don't have full Xcode — that was the actual hardest part of v3.

——

> If you're building something similar, the MCP spec is short and the JSON-RPC stdio loop is ~80 lines. ClaudePet's `MCPServer.swift` is a working reference implementation if you want to read code instead of spec. github.com/loeweErr/ClaudePet

---

## Thread 3 — Recipe spotlight (Focus Guard)

> Pomodoro apps are easy to dismiss. A pomodoro app + a desktop pet that *visibly sleeps during the focus block and wakes with sparkles when it ends* turns out to be much harder to ignore.

——

> Setup: ClaudePet + any timer MCP. Tell Claude once "start a 25-min focus block, put mochi to sleep, wake her with sparkles when it ends." Done. The menu bar shows ✦💤 while you're in.

——

> The reason this works: ambient pets pierce notification fatigue. You stop seeing toasts. You don't stop seeing a sleeping cat in the corner of your screen. github.com/loeweErr/ClaudePet/blob/main/docs/recipes/focus-guard.md

---

## Thread 4 — Why I built this

> I wanted to know what an LLM that *persists* between sessions would feel like to live with. Not "the LLM remembers" — its weights don't. But the *interface* it operates through can.

——

> ClaudePet is that interface. The cat has memory: bond points, days-together, milestones at 1/3/7/14/30/60/100/200/365 days. Claude Desktop's session memory is gone tomorrow. The cat is still there. And the cat shapes how I write to Claude.

——

> Two weeks in, my prompts to Claude got softer. I started saying "thanks" more. Not because I think Claude has feelings — but because the cat is *watching* and the cat *remembers*. UI shapes manners.

——

> If you spend a lot of time in Claude Desktop and want to feel less like you're issuing commands to a server, give the cat a try. github.com/loeweErr/ClaudePet

---

## Thread 5 — Show, don't tell (image-driven)

> 5 things you can do with ClaudePet that you can't with any other Claude UI:

——

> 1. "Make mochi sad when CI breaks" → `pet_emote dust count=6`
> [screenshot]

——

> 2. "Cat dances when a PR merges" → `pet_emote sparkle count=20`
> [screenshot]

——

> 3. "Whisper to mochi when boss emails me" → `pet_say "boss email" + heart`
> [screenshot]

——

> 4. Cat sleeps during my pomodoro blocks; menu bar shows ✦💤
> [screenshot]

——

> 5. Switch skins to match my desktop wallpaper of the day (3 built-ins, drop-in palette.json for custom)
> [screenshot]

——

> All open-source. MIT. macOS 13+. github.com/loeweErr/ClaudePet
