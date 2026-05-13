# RFC 0006 — Observability dashboard

- **Status**: Draft
- **Author**: loeweErr

## Summary

A small in-app dashboard ("This week with mochi") showing interaction counts, mood-over-time, model usage if you're on a paid Claude plan, and milestone history.

## Motivation

The cat already tracks `totalPets`, `totalTreats`, `totalPlays`, plus the bond curve and milestones. Today this only surfaces as small numbers in the status panel. Surfaced as a *chart*, the same data becomes a small reward loop — users come back partly to see how the past week looked.

It's also the closest ClaudePet gets to "how am I using Claude this week" — the cat is a proxy for sessions started, work blocks completed, tasks invoked. That framing is more emotionally legible than "47 API calls."

## Sketch

- New right-click menu item: **数据 (Dashboard)** → opens a borderless window (450×500 ish).
- Internal SwiftUI views — fine for a focused secondary surface; doesn't justify a third-party charting dep.
- **Sections** (each a stacked card):
  - 这周共度 — bar chart of "interactions per day" (sum of pets + treats + plays + waves)
  - 心情曲线 — line chart of hunger / happiness / energy over the week (sampled hourly from on-tick state writes)
  - 用量 — current 5h window's `pet_*` tool calls vs the model's windowLimit; weekly Opus minutes if relevant
  - 里程碑 — list of `state.shownMilestones` with the days, and a "next milestone in N days" tease
- **Storage**: today's PetState doesn't keep a time series — only point-in-time values. New ring-buffer field `state.history: [HistorySample]` with last 168 hourly samples (1 week) = ~3KB serialized.

## Open questions

- Should the dashboard ever expose anything to Claude (as a `pet_dashboard_summary` tool)? Probably yes — "what's the trend this week?" is a natural Q&A.
- Privacy: even though state is local, surfacing model usage minutes can feel surveilling. Make the model-usage card opt-in.
- Export: a "save week as PNG" button would make the dashboard tweet-friendly. Cheap addition once charts render.

## Non-goals

- A real telemetry pipeline. Everything stays in `PetState`.
- Predictive analytics ("your mood will dip Wednesday"). The cat is a mirror, not a forecaster.
