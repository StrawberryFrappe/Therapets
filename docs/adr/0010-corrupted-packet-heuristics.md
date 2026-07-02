# 0010. Corrupted-packet rejection heuristics

- **Status:** Accepted
- **Date:** 2026-05-15
- **Deciders:** Project owner (@StrawberryFrappe)

## Context

The BLE link and PoC-grade sensors occasionally deliver garbage frames (bit
errors, partial reads). Because human presence/quality detection needs a
**somewhat lengthy observation window** to lock on, a few corrupt frames slipping
through can poison that window and hurt detection consistency. Cheap physical
sanity checks can discard obviously-impossible readings before they reach the
detection logic.

## Decision

Reject frames that fall outside physically plausible bounds — values "no human
would ever produce" — before they enter presence/quality processing. Current
heuristics:

- **IMU:** discard if acceleration magnitude > **10 g**.
- **IR temperature:** discard if the frame-to-frame delta is implausibly large
  (|Δ| > **20000** raw units).

These are guards against corruption, not clinical thresholds.

## Consequences

### Positive
- Detection windows stay clean; consistency improves without lengthening them.
- Very cheap (simple range/delta comparisons).

### Negative / trade-offs
- Magic-number thresholds tuned empirically; a genuinely extreme-but-real reading
  could be dropped (acceptable trade-off given the sensor grade).
- Values are not centrally documented outside this ADR — keep them in sync with
  the code if changed.

## Alternatives considered

- **Trust all frames** — rejected: corrupt frames degraded detection consistency.
- **Checksums / CRC in firmware** — more robust but more firmware work than the
  PoC warranted.

## References

- `lib/services/device/` (packet parsing / spike protection)
- Related: [[ADR-0003]] (unconditional sensor-quality safeguards), [[ADR-0007]]
