# Recipe: Focus Guard

> Pair ClaudePet with a Pomodoro / focus-timer MCP so the cat sleeps during your focus blocks and celebrates at the end.

**Loop**: Pomodoro starts → `pet_sleep` (cat curls up, ✦💤 in menu bar). Pomodoro ends → `pet_wake` + `pet_emote sparkle count=12` (cat stretches, sparkles).

## What you need

- ClaudePet installed and visible in `tools/list` ([install instructions](../../README.md#install-to-claude-desktop))
- A Pomodoro / timer MCP server. Any of these works:
  - [`@modelcontextprotocol/server-pomodoro`](https://www.npmjs.com/package/@modelcontextprotocol/server-pomodoro)
  - Your own shell script that simply emits start/stop signals
  - Even a manual `say "start focus"` in chat — Claude can drive both tools without a third party

## Claude Desktop config

```json
{
  "mcpServers": {
    "claude-pet": {
      "command": "/Applications/ClaudePet.app/Contents/MacOS/ClaudePet",
      "args": ["--mcp"]
    },
    "pomodoro": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-pomodoro"]
    }
  }
}
```

## Trigger phrase

Say something like:

> Start a 25-minute focus block. Put the cat to sleep until it ends, then wake her up with sparkles.

Claude will:

1. Call `pomodoro_start` (or whatever your timer tool exposes) with `25m`
2. Call `pet_sleep` — `mochi` curls up, status bar shows `✦💤`
3. When the timer expires, your timer MCP fires (or Claude polls), and Claude calls `pet_wake` followed by `pet_emote { kind: "sparkle", count: 12 }`

## Why it works

The cat-as-status-indicator turns Claude into a proactive focus partner without any custom UI: you can see at a glance from the menu bar whether you're "in" a block (`✦💤`) or free (`✦`).

## Variations

- **Long-break upgrade**: after 4 cycles, `pet_say "做得好~ 去喝水吧 ♡"` and `pet_emote heart count=8`
- **Strict mode**: combine with a website-blocker MCP — same trigger sleeps the cat AND blocks distraction sites
- **Co-op**: replace `pet_sleep` with `pet_say "我陪你 ✦"` if you prefer the cat to stay visible as company instead of curling up
