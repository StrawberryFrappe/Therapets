# Architecture Decision Records

This folder captures the **why** behind the significant technical choices in
Therapets — the decisions that aren't obvious from reading the code, and that a
future developer would otherwise have to reverse-engineer or rediscover the hard
way.

## What an ADR is

Each ADR is one file recording a single decision: the context that forced a
choice, the option taken, and the consequences (good and bad). ADRs are
**immutable once accepted** — if a decision changes, you don't edit the old
record, you write a new ADR that supersedes it and update the `Status` line of
the old one.

## Format

We use a lightweight [MADR](https://adr.github.io/madr/)-style template. Copy
[`0000-template.md`](0000-template.md), give it the next number, and fill it in.

Numbering is sequential (`0001`, `0002`, …). Filename:
`NNNN-short-kebab-title.md`.

## Status values

- **Proposed** — under discussion, rationale not yet confirmed by the decision owner.
- **Accepted** — the decision is in force.
- **Superseded by [ADR-NNNN]** — replaced by a later decision.
- **Deprecated** — no longer relevant, not replaced.

## Index

| ADR | Title | Status |
|-----|-------|--------|
| [0001](0001-native-authoritative-architecture.md) | Native-authoritative background architecture | Accepted |
| [0002](0002-shared-preferences-over-hive.md) | SharedPreferences JSON bundles over Hive | Accepted |
| [0003](0003-presence-detection-profiles.md) | Firmware-aware presence-detection profiles | Accepted |
| [0004](0004-provider-as-service-locator.md) | `provider` as service locator, not reactive state | Accepted |
| [0005](0005-no-permission-handler-native-permissions.md) | No `permission_handler`; native BLE-channel permissions | Accepted |
| [0006](0006-sticky-device-type-by-packet-size.md) | Device-type detection by BLE packet size | Accepted |
| [0007](0007-truthful-telemetry-with-ux-grace.md) | Truthful telemetry with bounded UX grace | Accepted |
| [0008](0008-push-only-cloud.md) | Push-only cloud (being revisited for allowlist) | Accepted |
| [0009](0009-three-branch-release-pipeline.md) | Three-branch release pipeline | Accepted |
| [0010](0010-corrupted-packet-heuristics.md) | Corrupted-packet rejection heuristics | Accepted |
| [0011](0011-game-allowlist-treatment-integration.md) | Game-allowlist via treatment-record fetch | Accepted |

> Candidate decisions still needing an ADR are tracked in the project
> `ROADMAP.md` (docs phase). Add rows here as they are written.
