# RFC 0002 — Cross-device state sync via iCloud KVS

- **Status**: Draft
- **Author**: loeweErr
- **Depends on**: RFC 0001 (only matters once there are ≥2 surfaces)

## Summary

Persist `PetState` (or a subset) in `NSUbiquitousKeyValueStore` so a user's bond / days-together / skin / personality follow them across devices.

## Motivation

If RFC 0001 ships, the worst possible UX is "your Mac cat has 87 days bond, your iPhone cat is a stranger." Worse: the user is incentivized to *not* use the iPhone version because it would dilute their bond.

iCloud KVS is small (1MB total, 1KB per key, 1024 keys) but **PetState's payload is <2KB** — fits easily.

## Sketch

- Replace the `UserDefaults` backing store in `PetState.load/save` with a layer that writes to **both** UserDefaults and `NSUbiquitousKeyValueStore`, reading the most recent timestamp on launch.
- Conflict resolution: last-write-wins by `lastTickAt`. Mood is continuous; small overlap windows merge gracefully.
- Skin id and personality id sync; the actual community-skin `palette.json` files don't (they're separate gallery installs per-device).
- New field: `state.deviceId: UUID` — so we can attribute "where the last interaction happened" without sending it.

## Open questions

- iCloud KVS requires the app to be signed with an iCloud entitlement. The current unsigned dev-build path breaks. Do we ship signed-only from this point on, or feature-detect at runtime?
- Multi-user iCloud accounts (family sharing): per-Apple-ID is the right granularity, but worth confirming.
- Privacy: the bond stat reads as quasi-emotional data. Even though it never leaves Apple's cloud, the framing in user-facing copy should be "your cat's notebook syncs with you" rather than anything spookier.

## Non-goals

- Sync of interaction *history* (every pet, every meow). Just persistent state.
- A server-side sync layer. CloudKit and KVS are sufficient; running infrastructure is not in scope for v3-era ClaudePet.
