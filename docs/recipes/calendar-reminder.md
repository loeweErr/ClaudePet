# Recipe: Calendar Reminder

> The cat warns you 5 minutes before a meeting starts. No native macOS notification — just `mochi` saying it.

**Loop**: Calendar query → upcoming event detected → `pet_say "5 分钟后开会喵"` + `pet_emote note count=4`.

## What you need

- ClaudePet installed
- A calendar MCP server. Common choices:
  - [Google Calendar MCP](https://github.com/google-calendar-mcp/server) (OAuth)
  - macOS Calendar via [`mcp-server-applescript`](https://github.com/applescript-mcp) (local, no OAuth)
  - Outlook/Exchange via the Graph MCP

## Claude Desktop config

```json
{
  "mcpServers": {
    "claude-pet": {
      "command": "/Applications/ClaudePet.app/Contents/MacOS/ClaudePet",
      "args": ["--mcp"]
    },
    "calendar": {
      "command": "npx",
      "args": ["-y", "google-calendar-mcp"],
      "env": {
        "GOOGLE_OAUTH_CLIENT_ID":     "<your client id>",
        "GOOGLE_OAUTH_CLIENT_SECRET": "<your client secret>"
      }
    }
  }
}
```

## Trigger phrase

Tell Claude once at the start of the day:

> Every 5 minutes, check my calendar. If a meeting is about to start in 5 minutes, have mochi remind me.

Claude will plan a polling routine and call:

1. `calendar_list_upcoming` (or equivalent) every 5 minutes
2. When a meeting matches the 5-minute window:
   - `pet_say { text: "5 分钟后：<meeting name>", duration: 4 }`
   - `pet_emote { kind: "note", count: 4 }`
   - Optionally `pet_meow` for emphasis

## Why it works

Calendar reminders from Apple's UI are easy to dismiss and forget. A talking cat with a particle effect breaks through habituation — and you can talk back to Claude immediately if you need to reschedule.

## Variations

- **Tone by meeting type**: read the title — if it contains "1:1" use `pet_say "和 <name> 的 1:1 ♡"`; if it's a "review" use `pet_say "review 准备好了吗?" + pet_emote sparkle`
- **Bond-aware urgency**: have Claude check `pet_status` first — if `bond < 8`, the cat gives a polite reminder; if `bond > 45` ("companion"), it nags more
- **Prep window**: 15 minutes before, `pet_say "准备一下吧"`; 5 minutes before, the louder reminder above
