# RFC 0003 — Neighbors

- **Status**: Draft
- **Author**: loeweErr

## Summary

Your friend's cat shows up on your desktop for a brief visit, says hi (e.g. waves, emits a heart), then leaves. Asynchronous, opt-in, no persistent multiplayer.

## Motivation

The cat is currently a solo experience. A small social loop — "your friend's mochi-equivalent showed up" — would create a reason to talk about ClaudePet that isn't about ClaudePet ("guess whose cat just visited?").

It's also a low-stakes way for the user to learn about a friend's existence in the same ecosystem without exchanging contact info beyond a friend code.

## Sketch

- **Friend code**: 8-char alphanumeric, generated on first opt-in. Shared by user, e.g. "add me — `mochi-x7q2`."
- **Storage**: ephemeral. A tiny relay server keeps a queue of pending visits (sender → recipient code), no message body. ClaudePet polls every few minutes when online.
- **Visit**: friend's cat sprite walks in from screen edge (skin pulled from public registry by their declared skin id; fallback to mochi if private), does a wave, emits a heart, walks out. ~6 seconds total.
- **Outbound trigger**: user right-clicks → 邻居… → enters friend code → sends. Friend's cat shows up next time their app is open.
- **Privacy**: only the friend code travels. No PII, no IP logging beyond standard CDN edge logs.

## Open questions

- **Cost / hosting**: the relay needs to be online. Free tier of any serverless platform handles low volume; if ClaudePet grows we need an actual cost model. Plain-text bandwidth is trivial; the operational cost is the bigger issue.
- **Abuse**: spam visits ("ten thousand cats appear at once"). Rate-limit per-friend-pair to 1 visit / hour, hard cap per recipient to N visits / day.
- **Discovery**: do we surface "friends-of-friends" or keep it strictly explicit-add? Strictly explicit feels right.
- **Could this be peer-to-peer instead of a relay?** macOS firewall + NAT make it harder than it sounds. Probably not worth the complexity unless someone strongly wants it.

## Non-goals

- Chat between users. Visits are non-verbal.
- Real-time presence ("I see you're online now"). The relay is queue-based.
- A "feed" of recent visits. The pet's interaction is the medium, not a notification list.
