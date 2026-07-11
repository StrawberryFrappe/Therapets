# 0006. Device-type detection by BLE packet size ("sticky" type)

- **Status:** Accepted
- **Date:** 2026-05-01
- **Deciders:** Project owner (@StrawberryFrappe)

## Context

The app supports two hardware variants that stream different data:
- **GY906** (IR temperature) — 14-byte packets
- **MAX30100** (pulse oximeter) — 16-byte packets

Both use the same firmware family and BLE service. Making the device advertise or
report its own identity (a handshake / self-identification exchange) was more work
and complexity than the deadline allowed.

## Decision

Infer device type from the **BLE payload size**: 14 bytes → GY906, 16 bytes →
MAX30100. The detected type is **sticky** — once inferred it is latched rather than
re-evaluated every packet, to avoid flapping.

## Consequences

### Positive
- No firmware-side identification protocol to design, version, or maintain.
- Trivial, zero-config detection on the app side.

### Negative / trade-offs
- Purely heuristic: any future variant with a colliding packet size would be
  misidentified.
- **Known bug:** swapping a temperature device for a pulse device (or vice-versa)
  sometimes needs a second connection attempt because the type stays sticky from
  the previous session. Deferred, tracked in memory as `device-switch-sticky-type`.

## Alternatives considered

- **Device self-identification handshake** — rejected under deadline pressure as
  too much firmware + protocol complexity for a two-variant PoC.

## References

- `lib/services/device/` (packet parsing / type detection)
- Deferred bug: `device-switch-sticky-type` (memory)
