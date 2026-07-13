# 0007. Truthful telemetry with a bounded UX grace window

- **Status:** Accepted
- **Date:** 2026-05-15
- **Deciders:** Project owner (@StrawberryFrappe)

## Context

Therapets supports **therapeutic processes**, so the usage/telemetry data a
healthcare professional sees must be as **truthful** as possible — fabricated or
smoothed-over data could mislead a real clinical decision. At the same time the
sensors are PoC-grade and intermittently unreliable (dropouts, duty-cycle
blackouts, noisy frames), and a UI that flickers "disconnected" on every hiccup is
a bad experience. These two goals pull in opposite directions.

## Decision

Adopt a **Unified Sync State** model that separates *display smoothing* from
*recorded truth*:

- The **UI** may hold a last-known-good state through short grace windows (e.g. a
  grace period on bad readings / sensor sleep, a brief freeze on BLE disconnect) so
  it doesn't thrash on transient noise.
- **Cloud / mission history never fabricates data.** During a gap it logs the real
  outcome (e.g. `false` / no reading) — it never back-fills or fakes a value to
  keep a streak alive. Smoothing is a presentation concern only; the recorded
  record stays honest.

## Consequences

### Positive
- Clinicians get trustworthy data; streaks/missions can't be inflated by sensor
  smoothing.
- Users get a stable, non-flickering UI despite flaky sensors.

### Negative / trade-offs
- Two notions of "current state" (displayed vs. recorded) must be kept distinct in
  code — conflating them reintroduces either flicker or dishonest data.
- Grace-window durations are tuning constants that interact with the presence
  profiles ([[ADR-0003]]).

## Alternatives considered

- **Smooth everything (incl. recorded data)** — rejected: dishonest for a clinical
  context.
- **Show raw state with no smoothing** — rejected: unusable UX given PoC sensors.

## Addendum (2026-07-13) — enforced in the native sync tally

The native per-minute sync tally previously incremented on the **grace-smoothed**
presence (`humanDetected`, 15 s hold), which let visual smoothing leak into the
recorded record — a violation of this ADR. The tally now increments on a **no-grace
clinical presence** (`instantaneousDetected`), while the grace-smoothed value stays
for UI / pet-care / mission-visual only. See `docs/capa_nativa.md` "Presencia clínica
vs. visual". Net effect: recorded synced minutes may read slightly lower than before,
but are honest.

## References

- `AGENTS.md` — Unified Sync State Vision
- Related: [[ADR-0003]] (presence profiles), [[ADR-0008]] (push-only cloud)
