# RFC 0001 — iOS / iPadOS port

- **Status**: Draft
- **Author**: loeweErr

## Summary

Port mochi to iOS / iPadOS so the cat lives across your devices. Same state, same skin, same bond — different surface.

## Motivation

The macOS pet is a window onto a pet that "lives" there. As soon as the user has more than one device, the illusion breaks: the cat is on the laptop, not the phone. Today the cat is half-real; on iOS it could be all-real.

Secondary: iOS reaches an audience that doesn't open Claude Desktop on Mac — phone-first users. The mood-system and bond-stat experience may translate even without the desktop overlay.

## Sketch

- **Surface**: a SwiftUI app + a Live Activity for the lock screen / Dynamic Island. The cat doesn't need to be a full-screen presence; even a 32px lock-screen avatar that reflects mood is enough.
- **Code share**: the mood / state / palette / personality types are pure value types — extract into a `ClaudePetCore` Swift Package consumed by both targets. The current `Sources/ClaudePet/` becomes the macOS app target.
- **No Carbon hot keys, no transparent NSWindow.** iOS is a different UI paradigm — the pet is more "watch-app vibes" than "free-floating desktop sprite."
- **MCP on iOS**: iOS has no stdio MCP child process model. Bridge via a remote MCP server (cloud-hosted, your Claude Desktop sees both your local cat and the remote one) or via the Claude API on-device.

## Open questions

- Is the lock screen the right primary surface, or a home-screen widget?
- Does the pet have its own mood on iOS, or does it sync the *same* mood as the Mac (one cat, two windows onto it)? RFC 0002 partially addresses this.
- App Store policy: a "virtual pet that the AI controls" might fall under entertainment vs utility — not blocking, but affects review.
- Pricing: free, freemium with paid skins, or tip-jar?

## Non-goals

- Android port (different audience, different platform conventions; not in scope until iOS shows traction).
- Full Mac-feature parity on iOS (drag-around window, AppleScript). iOS is its own product.
