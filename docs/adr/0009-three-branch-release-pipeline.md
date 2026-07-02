# 0009. Three-branch release pipeline (main / dev / unstable)

- **Status:** Accepted
- **Date:** 2026-05-24
- **Deciders:** Project owner (@StrawberryFrappe)

## Context

The project started with two branches: `main` as the stable build for test users
during development, and `dev` as the owner's working branch. Then the owner's phone
USB-C port broke, removing the ability to side-load builds over cable. A way to
test volatile, work-in-progress builds **over-the-air** became necessary. CI to
release from `main` already existed, so extending it to more channels was cheap.

## Decision

Run **three long-lived branches**, each mapped to a release channel via CI:

| Branch | Channel | Audience | Meaning |
|--------|---------|----------|---------|
| `main` | Stable | test users | vetted, stable releases |
| `dev` | Nightly | boss & coworkers | "should work, not fully sure" |
| `unstable` | Experimental | owner only | "go nuts" sandbox for active work (replaces USB side-loading) |

All three are **kept**, not stale. Work flows `unstable` → `dev` → `main`.

## Consequences

### Positive
- Owner can test experimental builds OTA without a working USB port.
- Boss/coworkers get nightly visibility; test users stay on stable.

### Negative / trade-offs
- Three branches to keep in sync; more merge/promote overhead than a single
  trunk.
- A newcomer may mistake `dev`/`unstable` for stale branches and try to delete
  them — they are the live pipeline.

## Alternatives considered

- **Single trunk + tags** — rejected: didn't give the owner an OTA channel for
  experimental builds after losing USB side-loading.

## References

- CI release workflow (`.github/workflows/`)
- `ROADMAP.md` — branch-strategy section
