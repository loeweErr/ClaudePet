# RFC 0005 — Streaming replies (typewriter bubble)

- **Status**: Draft
- **Author**: loeweErr

## Summary

When `pet_say` receives a long string, the speech bubble animates character-by-character ("typewriter") instead of appearing all at once. Optionally the TTS speaks at the same pace.

## Motivation

Today's bubble is a static box. For 5-character bubbles ("nya~") this is fine. For the 30-character cap a personality might allow ("年轻人啊…工作要紧也要喝水"), seeing the cat *type* feels meaningfully more alive — and naturally creates anticipation that aligns with the user actually reading.

This is also the cheap surrogate for "streaming model output" in environments where ClaudePet doesn't have actual stream access (the MCP `tools/call` returns a single string).

## Sketch

- Extend `pet_say` arguments with `stream: bool` (default false to preserve existing behavior) and `pace: number` (chars/sec, default 18 — roughly "polite typing").
- `PetView.bubbleText` becomes a setter on a new `BubbleAnimator` that owns a CADisplayLink-style ticker and renders prefix-up-to-now.
- TTS in streaming mode: AVSpeechSynthesizer doesn't natively offer mid-stream resume, but we can speak the full string normally — the visual stream just runs in parallel at a matched pace.
- A separate `pet_stream_say` tool could also work, but the boolean flag keeps the surface smaller.

## Open questions

- **Skip-to-end UX**: clicking the bubble while it streams should reveal the full text. The space bar gets re-purposed elsewhere on macOS, so click is cleaner.
- **Personality-driven pace**: an "elder" persona could stream slower than "anime." Maybe pace is a personality property, not a per-call argument.
- **Interruption**: if a second `pet_say` lands mid-stream, do we queue, interrupt, or merge? Probably interrupt-and-replace, like today's static bubble.

## Non-goals

- A token-by-token stream from the model itself. ClaudePet never sees the LLM's stream — that lives inside Claude Desktop. This RFC is about the visual treatment of finalized strings.
- Multiple simultaneous bubbles. One cat, one bubble.
