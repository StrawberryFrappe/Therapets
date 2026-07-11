# 0005. No `permission_handler`; permissions via the native BLE channel

- **Status:** Accepted
- **Date:** 2026-07-02
- **Deciders:** Project owner (@StrawberryFrappe)

## Context

BLE on Android 12+ needs runtime permissions (`BLUETOOTH_SCAN`,
`BLUETOOTH_CONNECT`, plus `ACCESS_FINE_LOCATION` on older APIs). The common
approach is the `permission_handler` plugin, but it caused **Android embedding
compatibility problems** in this project. The app already owns a native BLE layer
([[ADR-0001]]) that has to be running for the permissions to matter anyway.

## Decision

Remove `permission_handler`. Request runtime permissions through the **existing
native method channel** (`sync_companion/bluetooth`): Dart calls
`performRequestPermissions()` → native `requestPermissions`, and reads back a
status map keyed by `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT`. The manifest declares
the full permission set (with `neverForLocation` on scan and the foreground-service
types). Denied/required states have dedicated l10n strings.

## Consequences

### Positive
- No plugin embedding-compatibility breakage.
- Permission flow lives next to the native service that actually uses it.

### Negative / trade-offs
- **Non-standard.** A new contributor won't recognise the pattern and may reach
  for `permission_handler` out of habit.

> ⚠️ **Do NOT re-add `permission_handler`.** It was removed for embedding
> compatibility; reintroducing it risks the same build/runtime break. Extend the
> native channel instead. (Mirror this warning as a comment in
> `bluetooth_service.dart` near `performRequestPermissions`.)

## Alternatives considered

- **`permission_handler` plugin** — the removed approach; caused embedding issues.

## References

- `lib/services/device/bluetooth_service.dart:407` (`performRequestPermissions`)
- `lib/services/device/device_service.dart:372` (passthrough)
- `android/app/src/main/AndroidManifest.xml` (permission + foreground-service decls)
- `pubspec.yaml:32` (removal note)
