# 0002. SharedPreferences JSON bundles over Hive

- **Status:** Accepted
- **Date:** 2026-05-29
- **Deciders:** Project owner (@StrawberryFrappe)

## Context

The app needs durable local storage for pet stats, currency, missions, inventory,
and settings. An earlier iteration used Hive. Two forces made that painful:

1. **Cross-language access.** Under the native-authoritative model ([[ADR-0001]]),
   the Kotlin foreground service must read and write the same persisted state as
   Dart. Hive's Dart-specific binary boxes are not readily shared with native code;
   Android `SharedPreferences` is a first-class platform store both sides can reach.
2. **Partial-write / corruption risk.** Interrupted saves (app killed mid-write)
   could leave stored state inconsistent.

## Decision

Persist state as **atomic JSON bundles in `SharedPreferences`**. Hive is removed
and forbidden. Writes are hardened against partial writes and concurrent saves
(queued saves rather than fire-and-forget). Native code accesses the same
`SharedPreferences` store, respecting Flutter's key prefixing convention.

## Consequences

### Positive
- Single store readable by both Dart and Kotlin — no bridge needed for state.
- JSON bundles are human-inspectable and trivial to migrate/version.
- No native binary dependency to build or maintain.

### Negative / trade-offs
- `SharedPreferences` is not a database: no queries, no indexing; fine at this
  data scale but would not suit large or relational data.
- JSON (de)serialization is manual per model.
- **Key-prefix gotcha:** Flutter's `shared_preferences` stores keys under a
  `flutter.` prefix in the `FlutterSharedPreferences` file. Native code reading
  those keys must account for this (see 2026-06-04 cloud-credential fix).

## Alternatives considered

- **Hive** — the prior choice; rejected for the cross-language and corruption
  reasons above.
- **SQLite/Drift** — rejected: heavier than needed for the current data volume and
  still awkward to share with the native layer.

## References

- `lib/game/pets/pet_stats.dart` (`saveToPrefs`), `lib/game/missions/mission_service.dart`
- Related: [[ADR-0001]]
- `FACTORY.md` — 2026-05-29 Hive removal, 2026-06-04 credential key-prefix fix
