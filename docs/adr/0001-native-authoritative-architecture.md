# 0001. Native-authoritative background architecture

- **Status:** Accepted
- **Date:** 2026-05-29
- **Deciders:** Project owner (@StrawberryFrappe)

## Context

Therapets must keep a BLE link alive, tally missions, decay pet stats, and push
cloud telemetry **while the app is backgrounded or the phone is idle** — the core
value of the product is passive, always-on companionship. Android aggressively
suspends the Flutter engine (Dart isolate) in the background: timers stop, streams
pause, and in-memory state is lost when the OS reclaims the process. Relying on
Dart to own this state meant missions and currency could silently reset, and
telemetry gaps appeared whenever the engine was torn down.

## Decision

The **Android native layer is the source of truth** for anything that must survive
Flutter engine suspension. A foreground service (`BleForegroundService.kt`) owns
the BLE connection, and the mission tally (`MissionManager.kt`) and cloud push
(`CloudManager.kt`) run natively in Kotlin. Flutter reads/mirrors this state for
UI but does not own it; persistence and minute-level aggregation happen natively.

## Consequences

### Positive
- Missions, currency, and telemetry survive backgrounding and process death.
- Cloud telemetry is pushed on a native schedule, independent of UI lifecycle.
- The foreground service satisfies Android's requirement for long-lived BLE work.

### Negative / trade-offs
- Logic is split across Dart and Kotlin; some state exists in two places and must
  be kept in sync (a class of bugs that does not exist in a pure-Dart app).
- Contributors must be comfortable in Kotlin + Android service lifecycle, not just
  Flutter.
- Testing the native path is harder than testing Dart.

## Alternatives considered

- **Pure-Dart with background isolates / WorkManager plugins** — rejected: Flutter
  background execution on Android is unreliable for continuous BLE and does not
  guarantee survival of in-memory tallies across process death.

## References

- `android/.../BleForegroundService.kt`, `MissionManager.kt`, `CloudManager.kt`
- Related: [[ADR-0002]] (persistence format the native layer writes/reads)
- `AGENTS.md` — Unified Sync State Vision; `FACTORY.md` — 2026-05-29 persistence overhaul
