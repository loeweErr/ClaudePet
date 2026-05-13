# RFC 0004 — AppleScript + Shortcuts integration

- **Status**: Draft
- **Author**: loeweErr

## Summary

Expose the same `pet_*` surface as AppleScript commands and Shortcuts actions. Anything an MCP tool call can do, an Automator / Shortcuts / Stream Deck button should do too — locally, no Claude required.

## Motivation

ClaudePet's value today is gated on having Claude Desktop running. Plenty of users would happily *automate* the cat from their existing macOS productivity stack — Hammerspoon, BetterTouchTool, Shortcuts, Raycast — if there were a hook.

Side effect: this also gives sophisticated users an escape hatch when an MCP tool isn't quite the right surface for their use case.

## Sketch

### AppleScript

- Declare a small AppleScript dictionary (`sdef` file in the .app bundle).
- Commands map 1:1 to the existing IPC handler in `PetCoordinator`:
  ```applescript
  tell application "ClaudePet"
    pet
    feed
    emote kind "sparkle" count 12
    say "hello" duration 4 silent false
  end tell
  ```
- Implementation: an `NSScriptCommand` subclass per tool, each invoking the same IPC handler the MCP server uses today.

### Shortcuts

- Provide an `AppIntent` per tool (iOS 16 / macOS 13+ API).
- A Shortcuts user can drag "Pet · feed" into a flow.
- Bonus: the personality config could expose intents too ("ClaudePet · set personality preset").

### Raycast

- After AppIntent support is in, the Raycast Shortcuts plugin picks them up automatically. No bespoke Raycast extension needed.

## Open questions

- Should we expose `pet_status` as a Shortcuts action that returns the mood as a structured value? Useful for "if mochi is hungry, show me a feeding reminder."
- Sandboxing: AppleScript scripting requires the app to declare `NSAppleScriptEnabled` in Info.plist. Already required for some MCP setups; verify.
- Surface conflict: if a Shortcut calls `feed` while Claude is mid-`pet_say`, the IPC handler is the single point of truth — it serializes naturally, but worth testing.

## Non-goals

- A scripting-only ClaudePet variant (the MCP surface stays primary).
- Cross-app drag-and-drop of cat as data (cute, complex, out of scope).
