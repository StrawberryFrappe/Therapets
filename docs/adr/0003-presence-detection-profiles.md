# 0003. Firmware-aware presence-detection profiles (strict by default)

- **Status:** Accepted
- **Date:** 2026-07-02
- **Deciders:** Project owner (@StrawberryFrappe)

## Context

Whether the pet reads as "synced" depends on detecting a human on the sensor.
Two firmware generations behave very differently:

- **Old (duty-cycle) firmware** ran the bio sensor 10s ON / 10s OFF to save
  battery, zeroing IR/Red during the OFF window. Presence detection needed wide
  grace windows, history voting, and long freshness bridges so the app didn't
  drop "synced" during every periodic blackout.
- **New (always-on) firmware** keeps sensors running continuously. The old
  duty-cycle cushions now *hurt*: they make presence laggy and would keep the
  history vote stuck at 100% "present" even off-body.

A single hard-coded set of thresholds cannot serve both without one of them
misbehaving.

## Decision

Encapsulate the duty-cycle-specific tuning knobs in a `PresenceProfile` with two
named constructors — `dutyCycle()` (wide cushions, matching the historical
constants exactly) and `alwaysOn()` (small cushion, no barrage vote, all-zero
frame means "absent"). The mode is selected per connected firmware. The default
posture is **strict** (always-on / real-time reaction); the wider **lenient**
duty-cycle profile is opt-in for the older battery-saving firmware.

Crucially, only duty-cycle-shaped knobs are gated by the profile. Genuine
sensor-quality safeguards — spike protection, finger hysteresis, sustained-sample
checks, physiological ranges, anti-freeze flush, BLE-disconnect freeze — remain
**unconditional** in the processors/aggregator regardless of profile.

## Consequences

### Positive
- New firmware gets near-real-time presence; old firmware keeps its blackout
  tolerance. Neither compromises the other.
- The strict/lenient split is one small, testable value object
  (`presence_profile.dart`, covered by `test/presence_mode_test.dart`).
- Safety invariants can't be accidentally weakened by the profile — they live
  outside it.

### Negative / trade-offs
- Presence tuning now has a mode dimension; a wrong profile selection produces
  either laggy or twitchy sync.
- Profile selection must track firmware capability correctly (couples app
  behaviour to firmware generation).

## Alternatives considered

- **One universal threshold set** — rejected: any single tuning is wrong for one
  of the two firmware behaviours.
- **Auto-adapting thresholds from observed signal** — rejected: more complex and
  harder to reason about than two explicit, firmware-keyed presets.

## References

- `lib/services/device/presence_profile.dart`; `test/presence_mode_test.dart`
- Related: [[ADR-0001]] (native sync ownership); Unified Sync State in `AGENTS.md`
- PR #29 (strict-by-default presence with lenient duty-cycle mode)
