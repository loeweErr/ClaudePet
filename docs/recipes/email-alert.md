# Recipe: VIP Email Alert

> The cat goes into "alert mode" — `pet_emote heart` and a bubble — when a specific sender's email lands. Quiet for everything else.

**Loop**: Mailbox poll → message from VIP detected → `pet_say "老板来邮件了"` + `pet_emote heart count=8`.

## What you need

- ClaudePet installed
- A mail MCP server:
  - [Gmail MCP](https://github.com/gmail-mcp/server)
  - [`mcp-server-imap`](https://github.com/imap-mcp) for any IMAP account (Fastmail, iCloud Mail, etc.)
  - macOS Mail.app via AppleScript MCP

## Claude Desktop config

```json
{
  "mcpServers": {
    "claude-pet": {
      "command": "/Applications/ClaudePet.app/Contents/MacOS/ClaudePet",
      "args": ["--mcp"]
    },
    "gmail": {
      "command": "npx",
      "args": ["-y", "gmail-mcp"],
      "env": {
        "GOOGLE_OAUTH_REFRESH_TOKEN": "<your refresh token>"
      }
    }
  }
}
```

## Trigger phrase

Once per day:

> Watch my Gmail inbox every 2 minutes. If anything arrives from boss@company.com or from a customer-success VIP, have mochi tell me with a heart particle. Ignore everything else.

Claude will:

1. Call `gmail_list_unread` (or whatever the server calls list)
2. Filter messages by sender against your VIP list (you can give Claude an explicit list, or let it learn over a few days)
3. For VIP hits:
   - `pet_say { text: "<sender> 来邮件: <subject>", duration: 5 }`
   - `pet_emote { kind: "heart", count: 8 }` — or `kind: "star"` for "important"

## Why it works

Email notifications create constant low-grade context switching. A cat that only reacts to *your* VIPs trains the right reflex: glance at the cat → either it's quiet (ignore inbox) or it's reacting (real signal).

## Variations

- **Tone-by-sender**: `boss@…` triggers `pet_emote star count=10` (urgent), `customer@…` triggers `pet_emote heart count=4` (warm)
- **Quiet hours**: tell Claude "between 22:00 and 08:00, log VIP mail but don't bother mochi" — Claude tracks and replays in the morning
- **Combine with calendar**: if a VIP email mentions "tomorrow at 3", chain in the calendar MCP to actually book the meeting
