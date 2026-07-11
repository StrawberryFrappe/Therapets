# 0008. Push-only cloud (telemetry out, nothing in)

- **Status:** Accepted — revised by [[ADR-0011]] (adds one read path for the game-allowlist; telemetry itself stays push-only)
- **Date:** 2026-05-20
- **Deciders:** Project owner (@StrawberryFrappe)

## Context

Cloud connectivity exists so healthcare professionals can monitor a user's therapy
via a web app. The app's job was simply to *report*: it never needed to know
anything back from the cloud, the same way the device doesn't know who is receiving
its bio data. Minimising moving parts mattered for a PoC on a deadline.

## Decision

The app is **push-only**: it sends telemetry to ThingsBoard over HTTP and there is
**no fetch/pull path**. Direction of knowledge is one-way (device → app → cloud →
clinician).

## Consequences

### Positive
- Much simpler: no polling, caching, auth-for-reads, or conflict handling.
- Clear data-flow direction; fewer failure modes.

### Negative / trade-offs
- Any feature needing server→app data requires building a fetch path from scratch
  (no adapter, no auth-for-reads exists yet).
- **This is now being revisited:** the web game-allowlist (future ADR, pending web
  API design) is the first server→app read, so a fetch/adapter path must be added.

### Open / unknown
- Two cloud hosts appear in play — `.20` (ThingsBoard telemetry, the code default)
  and `.19` (web platform, per WhatsApp). The reason for the split is **not known**
  to the owner (possibly organisational — a Conway's-law artifact). Confirm which
  host the allowlist read should target before building against it.

> **See [[ADR-0011]] for the resolution:** the allowlist read landed on `.19`
> using the same device-token value as ThingsBoard's `.20`. This ADR's original
> content is left as-written above per the immutable-ADR convention.

## Alternatives considered

- **Bidirectional sync from the start** — rejected as unnecessary complexity for
  what was a report-only PoC.

## References

- `lib/services/cloud/cloud_service.dart` (telemetry POST, no fetch path)
- Related: [[ADR-0007]]; [[ADR-0011]] (the allowlist/treatment read path this
  ADR anticipated); `ROADMAP.md` Phase 3
