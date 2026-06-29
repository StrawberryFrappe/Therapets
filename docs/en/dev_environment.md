---
title: Development Environment
parent: Developer Docs
lang: en
nav_order: 2
description: "Setting up Flutter, generating Hive code, running, building, and project structure."
---

# Development Environment
{: .no_toc }

1. TOC
{:toc}

## Requirements

| Tool | Version |
|------|---------|
| Flutter | `stable` channel (tested with 3.44.x) |
| Dart SDK | `>=3.10.0 <4.0.0` |
| Java (JDK) | 17 (Android build) |
| Android SDK | API 34/35 |

## Getting started

```bash
# 1. Dependencies
flutter pub get

# 2. Generate Hive adapters (required!) — creates the *.g.dart files
dart run build_runner build --delete-conflicting-outputs

# 3. Run on a device/emulator
flutter devices
flutter run -d <device-id>
```

> Without the `build_runner` step the app **will not compile**: the Hive adapters
> (`pet_stats.g.dart`, `daily_missions.g.dart`) are generated, not versioned.
{: .warning }

## Building

```bash
# Release APK (signed if android/key.properties exists)
flutter build apk --release

# Other platforms
flutter build <android|ios|linux|macos|web|windows>

# Tests
flutter test
```

## Project structure

```text
lib/
├── main.dart                 # Entry point: bootstrap, theme, i18n
├── core/                     # AppBootstrapper, AppLifecycleManager
├── services/
│   ├── device/               # BLE: BluetoothService, DeviceService, processors
│   ├── cloud/                # CloudService, CloudEvent, EventQueue (ThingsBoard)
│   ├── notifications/        # PetNotificationService (foreground + locales)
│   ├── locale_service.dart   # i18n (es/en)
│   └── update_service.dart   # Update checker
├── game/
│   ├── virtual_pet_game.dart # Main game (Flame)
│   ├── pets/                 # Pet, PetStats, BobTheBlob
│   ├── items/                # FoodMenu, ClothingCatalog
│   ├── missions/             # Mission, daily_missions, MissionService
│   ├── models/               # TelemetryData
│   └── minigames/            # flappy_bird, orchestra, donut, sbr
├── screens/                  # UI: game_screen, settings, sensors, HUD, menus
└── l10n/                     # app_localizations* (generated from .arb)

android/app/src/main/kotlin/com/strawberryFrappe/sync_companion/
├── MainActivity.kt           # Flutter entry + MethodChannel
├── BleForegroundService.kt   # Persistent background BLE connection
├── MissionManager.kt         # Native mission evaluation
├── CloudManager.kt           # Native telemetry queuing
└── BootReceiver.kt           # Resumes service on boot
```

## App metadata

| Field | Value |
|-------|-------|
| `applicationId` | `com.strawberryFrappe.sync_companion` |
| Android label | `Therapets` |
| iOS name | `Sync Companion` |
| Version | see `version:` in `pubspec.yaml` (format `X.Y.Z+build`) |
| min/target/compile SDK | inherited from Flutter (`flutter.minSdkVersion`, etc.) |

## Key dependencies

`flutter_blue_plus` (BLE), `flame` + `flutter_cube` (2D/3D game), `hive` +
`shared_preferences` (persistence), `provider` (state), `dio`/`http` +
`connectivity_plus` (network), `flutter_foreground_task` (service), `mobile_scanner`
(QR), `audioplayers`, `wakelock_plus`, `package_info_plus`, `url_launcher`.

> **`permission_handler` is not used** (incompatibility with the Android embedding);
> permissions are requested using the platform's native prompts. `google_fonts`
> was replaced by the bundled `Monocraft.ttf` font.
{: .note }
