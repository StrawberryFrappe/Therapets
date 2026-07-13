---
title: Android Native Layer
parent: Developer Docs
lang: en
nav_order: 4
description: "Kotlin background service, native mission/cloud management, and the MethodChannel bridge."
---

# Android Native Layer (Kotlin)
{: .no_toc }

1. TOC
{:toc}

Flutter is suspended when the app goes to the background, but BLE must stay
alive. For this reason, the connection and critical logic live in a **native
Kotlin service**. Files located at
`android/app/src/main/kotlin/com/strawberryFrappe/sync_companion/`.

## Components

| File | Role |
|------|------|
| `MainActivity.kt` | Flutter entry point; exposes `MethodChannel`/`EventChannel` to communicate with Dart. |
| `BleForegroundService.kt` | *Foreground* service that keeps the BLE connection alive and processes telemetry even when the UI is dead. |
| `MissionManager.kt` | Evaluates mission progress natively (survives Flutter suspension). |
| `CloudManager.kt` | Canonical offline queue: builds the `ts`/`values.payload` envelope, enqueues (dedup by `eventId`, cap 5000), sends in batches (≤50, `ts` order) with exponential backoff, and exposes count/last-sync/last-error to the UI. |
| `BootReceiver.kt` | Receives `BOOT_COMPLETED` and resumes the service when the phone boots. |

## Why native

- Android kills Flutter isolates in the background; a **foreground service**
  with a persistent notification is not killed.
- Per-minute telemetry aggregation and mission evaluation were moved to native
  to avoid losing data during long suspensions.

## Foreground service

Declared in `AndroidManifest.xml`:

```xml
<service android:name=".BleForegroundService"
         android:foregroundServiceType="dataSync"
         android:stopWithTask="false" />
```

- `stopWithTask="false"`: keeps running even if the user swipes the app away
  from recents.
- Service types: `dataSync` (native) and `connectedDevice` (`flutter_foreground_task`
  plugin).
- **Grace window (~15 s):** momentary bad readings do not drop the connection.
- **Corruption filters** equivalent to the Dart-side ones (magnitude, IR delta) to
  avoid contaminating aggregation.

## Dart ↔ Native bridge

```mermaid
sequenceDiagram
    participant N as BleForegroundService (Kotlin)
    participant M as MainActivity (MethodChannel/EventChannel)
    participant D as BluetoothService (Dart)
    N->>M: connection state, BPM, SpO2, human
    M-->>D: EventChannel (nativeConnected$, nativeBpm$, ...)
    D->>D: processor pre-seed, display status
    Note over D,N: SharedPreferences is shared memory<br/>(PetStats writes keys that the service reads)
```

- `DeviceService` listens to `nativeConnected$`, `nativeBpm$`, `nativeSpo2$`,
  `nativeHumanDetected$` and **prioritizes native state** because it survives
  UI restarts.
- On returning from the background, `DeviceService.onAppResumed()` re-hooks the
  `EventChannel` and requests the canonical state.

### Cloud-queue methods (MethodChannel `sync_companion/bluetooth`)

Added 2026-07-13 so the UI shows the real **native** queue (it previously showed the
Dart queue, which could read 0 while thousands of native events were pending):

| Method | Returns |
|--------|---------|
| `getCloudQueueCount` | `Int` — events pending in `CloudManager` |
| `getLastCloudSync` | `Long` — epoch ms of the last 2xx POST (0 if none) |
| `getLastCloudError` | `String` — last send error (`""` if none) |
| `flushCloudQueue` | triggers `CloudManager.flushQueue()` |

## Clinical vs. visual presence

`BleForegroundService` keeps **two** notions of presence (see
[ADR-0007](../adr/0007-truthful-telemetry-with-ux-grace.md)):

- **Clinical (no grace):** `instantaneousDetected` — a sustained in-range streak,
  without the 15 s window. Feeds **only** the `syncedSecondsThisMinute` tally that the
  backend turns into usage time.
- **Visual (15 s grace):** `humanDetected` — still feeds UI, pet-care and visual
  mission progress, so it doesn't flicker on momentary bad readings.

Visual smoothing must **not** inflate the clinical record.

## Shared memory via SharedPreferences

`PetStats._mirrorToPrefs()` writes individual keys
(`pet_hunger`, `pet_happiness`, `pet_last_update`, rates, threshold) **in addition to**
the JSON bundle, specifically so that the native Kotlin service can read and
update the pet state without Flutter running. See [Data Model](data_model.html).
