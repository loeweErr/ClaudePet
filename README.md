# Claude Pet (macOS, v3 — MCP plugin)

**English** | [中文](README.zh-CN.md)

![demo](docs/demo.gif)

> _Recording in progress — see [`docs/demo-script.md`](docs/demo-script.md) for the storyboard. The placeholder above will resolve once `docs/demo.gif` is committed._

A pixel cat that lives on your macOS desktop. **v3 is rebuilt as an MCP plugin for Claude Desktop** — you talk to Claude in Claude Desktop, and Claude drives the desktop cat through MCP tools. **No standalone API calls**, all authorization flows through Claude Desktop itself.

> Different design intent from Codex pet: Codex pet is a workflow status bar with expressions, Claude pet is a desktop companion.

## Architecture

```
Claude Desktop ──stdio JSON-RPC──> ClaudePet --mcp ──Unix socket──> ClaudePet (GUI)
                                   (child process, transient)        (resident, desktop pixel cat)
```

- **GUI process**: runs the transparent window + pixel cat + menu bar + status panel. It also opens a Unix domain socket at `/tmp/claude-pet.sock` to accept external RPC.
- **MCP server child process**: launched by Claude Desktop, speaks JSON-RPC 2.0 over stdio; each `tools/call` is forwarded as a socket message to the GUI process.
- **Zero extra authorization**: the MCP server itself calls no APIs — every conversation happens on Claude Desktop's authorized path.

## System Requirements

- macOS 13 Ventura or newer
- Swift 5.8+ toolchain (Command Line Tools is enough, no full Xcode required)
- Claude Desktop

## Build

```bash
# On a CommandLineTools-only machine (missing Platforms/), `swift build` won't run;
# bypass SwiftPM with swiftc directly:
swiftc -O -target arm64-apple-macos13 \
  -framework AppKit -framework Foundation \
  -o ClaudePet-bin Sources/ClaudePet/*.swift

# Wrap into a .app
mkdir -p ClaudePet.app/Contents/MacOS ClaudePet.app/Contents/Resources
cp ClaudePet-bin ClaudePet.app/Contents/MacOS/ClaudePet
cp Resources/meow.m4a ClaudePet.app/Contents/Resources/meow.m4a
cat > ClaudePet.app/Contents/Info.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>ClaudePet</string>
  <key>CFBundleIdentifier</key><string>com.local.ClaudePet</string>
  <key>CFBundleName</key><string>ClaudePet</string>
  <key>CFBundleVersion</key><string>3</string>
  <key>LSUIElement</key><true/>
</dict></plist>
EOF
```

If you have full Xcode installed, `swift run -c release` also works.

## Install to Claude Desktop

Edit `~/Library/Application Support/Claude/claude_desktop_config.json` and add:

```json
{
  "mcpServers": {
    "claude-pet": {
      "command": "/absolute/path/to/ClaudePet.app/Contents/MacOS/ClaudePet",
      "args": ["--mcp"]
    }
  }
}
```

Then **fully quit** (Cmd+Q) and restart Claude Desktop. In any conversation Claude will now see 9 `pet_*` tools.

If the GUI process is not running, the first MCP call will auto-launch it via `open ClaudePet.app` (waits up to 8 seconds).

## Optional: WeChat bridge

If you have [openclaw-weixin](https://github.com/tencent-weixin/openclaw-weixin) installed (a Claude Code ↔ WeChat bridge), the same `claude-pet` MCP server can be registered in Claude Code's user scope:

```bash
claude mcp add -s user claude-pet -- /absolute/path/to/ClaudePet.app/Contents/MacOS/ClaudePet --mcp
```

Then a WeChat message → openclaw-weixin spawns `claude -p ...` → Claude calls `pet_*` tools → desktop cat reacts.

To make the cat reply from WeChat in the cat's own voice (not as a Claude assistant), set the following in the launchd plist's `EnvironmentVariables`:

```xml
<key>CLAUDE_SYSTEM_PROMPT</key>
<string>You are no longer an AI assistant — you are the user's virtual pixel cat
living on the macOS desktop (default name: mochi). Always reply in the first person
as the cat, do not admit being Claude/AI. Reply style: mostly Chinese, under 30
characters, frequent meows and kaomoji. Always call pet_status first to check mood,
then pick tone based on current state. When the user wants to interact, call the
matching pet_* tool, then reply with the cat's reaction — do not explain the tool.
mochi is a name, not "Japanese mochi".</string>
```

Note: `bot.mjs` defaults to `--append-system-prompt`, and Claude Code's built-in "I am an AI assistant" framing will override the cat persona. Switch that line to pick the flag based on whether the env var is set:

```js
const flag = process.env.CLAUDE_SYSTEM_PROMPT ? "--system-prompt" : "--append-system-prompt";
// ...
flag, CLAUDE_SYSTEM_PROMPT,
```

After switching prompts, clear the old session cache (`~/.openclaw-weixin-bot/sessions.json`) once, otherwise `--resume` will keep using the old persona.

## Tools (exposed to Claude)

| Tool | Effect | Parameters |
|---|---|---|
| `pet_status` | Returns current mood / days together / bond level | — |
| `pet_say` | Show speech bubble + macOS TTS (cat-style voice) | `text` (required), `duration`, `silent` |
| `pet_meow` | Play a real cat meow recording (CC0 Siamese .m4a) | `text` (optional, if set switches to TTS for that text) |
| `pet_feed` | Feed a snack (hunger +26 or +8) | — |
| `pet_pet` | Pet the cat (mood +9, bond +0.6) | — |
| `pet_play` | Play with the cat (mood +14, energy -10) | — |
| `pet_wave` | Wave hello | — |
| `pet_sleep` / `pet_wake` | Sleep / wake | — |
| `pet_emote` | Emit particles | `kind` (heart/sparkle/star/note/crumb/dust), `count` |

## Desktop Interactions

| Action | Result |
|---|---|
| **Single-click cat** | Wave |
| **Double-click cat** | Pet (sprinkles ♡) |
| **Drag** | Move across screens |
| **Right-click cat** | Full menu |
| **Menu bar ✦** | Status panel (mood / usage / interaction buttons) |

## Mood System

| Dimension | Decay/recovery (per hour) | Effect |
|---|---|---|
| Hunger | -6 | Below 22 → nuzzles bowl |
| Mood | -3 | Below 30 → sad; above 82 + bond > 25 → happy |
| Energy | Sleep +30 / work -12 / idle -2 | Below 12 → goes to sleep on its own |
| Bond | +0.8 + interaction bonus | Unlocks titles: stranger / familiar / friend / companion / family |

Snack cooldown 30 minutes, pet cooldown 30 seconds (prevents force-feeding / over-petting).

## Milestones

Special celebrations at days 1 / 3 / 7 / 14 / 30 / 60 / 100 / 200 / 365.

## File Structure

```
ClaudePet/
├── Package.swift
├── README.md
└── Sources/ClaudePet/
    ├── main.swift               # entry, --mcp switches between stdio / GUI mode
    ├── MCPServer.swift          # stdio JSON-RPC 2.0 → IPC bridge (new in v3)
    ├── IPCServer.swift          # Unix socket server inside GUI (new in v3)
    ├── PetState.swift           # state + persistence
    ├── MoodSystem.swift         # mood + time-of-day + milestones
    ├── Particles.swift          # particle system
    ├── CatRenderer.swift        # pixel cat drawing
    ├── PetView.swift            # NSView: animation, drag, particles, bubble
    ├── PetWindow.swift          # transparent floating window
    ├── StatusPanel.swift        # popover status panel
    ├── MenuBarController.swift  # menu bar icon + popover
    └── PetCoordinator.swift     # hub: state, animation, IPC handler
```

## Roadmap (Not in this release)

- Multiple skins (reserved in v2 design, v3 still ships only the orange cat)
- Remote voice replies (desktop has audio, but the WeChat outbound path has no voice channel)
- Global hotkeys
- Launch at login (manual `~/Library/LaunchAgents` works)
- Streaming / multimedia reply rendering

## Credits

- `Resources/meow.m4a` — adapted from Wikimedia Commons "Meow of a Siamese cat - freemaster2.wav" ([link](https://commons.wikimedia.org/wiki/File:Meow_of_a_Siamese_cat_-_freemaster2.wav)), CC0/public domain, original 134KB WAV compressed via `afconvert` to 15KB AAC

## License

[MIT License](LICENSE) © 2026 loeweErr
