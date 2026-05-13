# QA Report — v3.x Build Verification

Last run: 2026-05-13 on macOS 13 (Ventura) / arm64, Swift 5.8.1, CommandLineTools-only (no full Xcode).

## Pass

| Item | Notes |
|---|---|
| Compile from `Sources/ClaudePet/*.swift` | 609 KB binary, 0 errors. Only `[String:Any]` inference warnings in `MCPServer.swift` (cosmetic). |
| GUI launch via `open ClaudePet.app` | PID assigned, no crash from new init (`SkinManager.activate` / `HotKeyManager.enable` / `applyLaunchAtLogin`). |
| Unix domain socket | `/tmp/claude-pet.sock` created and accepts connections. |
| MCP `initialize` | Returns `serverInfo`, `protocolVersion`, `instructions`. |
| MCP `tools/list` | 10 tools advertised (`pet_status`, `pet_say`, `pet_meow`, `pet_feed`, `pet_pet`, `pet_play`, `pet_wave`, `pet_sleep`, `pet_wake`, `pet_emote`). |
| `tools/call pet_status` | Returns mood / hunger / energy / bond / pose / interaction counts. |
| `tools/call pet_emote` | Particle emission confirmed via response. |
| `tools/call pet_say` | Bubble + TTS path. Personality `replyCharLimit` is applied to the bubble (long text is truncated for display); the IPC response echoes the original text, which is the correct contract. |
| State persistence | UserDefaults blob under `com.local.ClaudePet` / key `com.claude.pet.state.v2`, 758 bytes — contains the new personality fields. |
| Launch-at-login default | `state.launchAtLogin = false`; `applyLaunchAtLogin()` no-ops on first launch, no SMAppService side effects. Toggling via panel was not exercised here. |

## Fixed in this commit

`install.sh` only passed `-framework AppKit -framework Foundation` to `swiftc`. The code now uses three more system frameworks via `import`:

- `AVFoundation` — `PetAudio` (AVSpeechSynthesizer + AVAudioPlayer)
- `ServiceManagement` — `SMAppService.mainApp` (launch-at-login)
- `Carbon.HIToolbox` — `HotKeyManager` (global hot keys)

Swift's autolinker picks these up in practice (verified on this machine), but explicit `-framework` flags are safer across toolchain variants. Updated `install.sh:109–113` accordingly.

## Not exercised here

These need either user interaction or a different host:

| Item | Why not | How to verify |
|---|---|---|
| Hot keys `⌃⌥P` / `⌃⌥H` / `⌃⌥F` | Need real key events | Press them on the desktop |
| Launch-at-login registration | Default off; toggling persists to SMAppService | Toggle in the panel, then check `~/Library/LaunchAgents` for the Login Item record |
| Personality preset switching | Requires GUI sheet editor | Open status panel → personality editor |
| Skin switching (mochi / dark / pastel + community) | Requires GUI menu | Right-click cat → Skin → choose |
| `Tests/ClaudePetTests/*.swift` (5 suites) | XCTest framework not available in CommandLineTools-only | Run `swift test` on a machine with full Xcode |

## How to repro

```bash
git fetch origin && git checkout main && git pull
pkill -f "ClaudePet.app/Contents/MacOS/ClaudePet" 2>/dev/null; sleep 1

swiftc -O -target arm64-apple-macos13 \
  -framework AppKit -framework Foundation -framework AVFoundation \
  -framework ServiceManagement -framework Carbon \
  -o ClaudePet-bin Sources/ClaudePet/*.swift

mkdir -p ClaudePet.app/Contents/MacOS ClaudePet.app/Contents/Resources
cp ClaudePet-bin ClaudePet.app/Contents/MacOS/ClaudePet
cp Resources/meow.m4a ClaudePet.app/Contents/Resources/meow.m4a
open ClaudePet.app && sleep 2

printf '{"jsonrpc":"2.0","id":1,"method":"initialize"}\n{"jsonrpc":"2.0","id":2,"method":"tools/list"}\n{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"pet_status","arguments":{}}}\n' \
  | ./ClaudePet.app/Contents/MacOS/ClaudePet --mcp
```

Expect three JSON-RPC responses on stdout.

## Caveat: macOS overwrite-running-binary trap

If a previous `ClaudePet` instance (GUI or `--mcp` child spawned by Claude Desktop) is still running when you `cp` a new build over the same path, new processes exec'd from that path will fail silently (no output, exit ≈ 1s). Always `pkill` first, then `cp`.
