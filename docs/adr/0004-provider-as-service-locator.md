# 0004. `provider` used as a service locator, not for reactive state

- **Status:** Accepted
- **Date:** 2026-07-02
- **Deciders:** Project owner (@StrawberryFrappe)

## Context

The app has a handful of long-lived services (device, cloud, missions, pet stats,
notifications, locale) that UI screens need to reach. It also needs live UI
updates as sensor data and pet state change. These are two separate needs:
*locating* a service vs. *reacting* to changing state.

## Decision

Use the `provider` package purely as a **dependency-injection / service-locator**
container. `main.dart` wires services into a `MultiProvider` with `Provider.value`
(plain injection, no rebuild-on-change). Screens fetch them with
`context.read<T>()`. **Live state does not flow through provider** — it flows
through service **streams** (`telemetry$`, `events$`, …) and the Flame game loop.
The one exception is `LocaleService`, injected as a `ChangeNotifierProvider`
because language changes genuinely need to rebuild the widget tree.

## Consequences

### Positive
- Simple, explicit access to services from anywhere in the tree.
- State stays in the services that own it (and, for background-critical state, in
  the native layer per [[ADR-0001]]) — provider isn't a second source of truth.

### Negative / trade-offs
- **Easy to misread.** A dev expecting bloc/riverpod-style reactive `provider`
  will look for `Consumer`/`watch` everywhere and find almost none. The pattern is
  "provider = locator, streams = state" — do not "fix" it by moving state into
  `ChangeNotifier`s.

## Alternatives considered

- **Riverpod / Bloc** — heavier; the stream-based services already provide
  reactivity, so a full reactive state framework would be redundant.
- **`get_it`** — a pure locator would work, but `provider` was already present and
  covers the one reactive case (`LocaleService`) too.

## References

- `lib/main.dart:89` (MultiProvider), `lib/services/locale_service.dart`
- Related: [[ADR-0001]]
