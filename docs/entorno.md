---
title: Entorno de Desarrollo
parent: Para Desarrolladores
lang: es
nav_order: 2
description: "Configurar Flutter, generar código Hive, ejecutar, compilar y estructura del proyecto."
---

# Entorno de Desarrollo
{: .no_toc }

1. TOC
{:toc}

## Requisitos

| Herramienta | Versión |
|-------------|---------|
| Flutter | canal `stable` (probado con 3.44.x) |
| Dart SDK | `>=3.10.0 <4.0.0` |
| Java (JDK) | 17 (build Android) |
| Android SDK | API 34/35 |

## Puesta en marcha

```bash
# 1. Dependencias
flutter pub get

# 2. Generar adaptadores Hive (¡obligatorio!) — crea los *.g.dart
dart run build_runner build --delete-conflicting-outputs

# 3. Ejecutar en un dispositivo/emulador
flutter devices
flutter run -d <device-id>
```

> Sin el paso de `build_runner` la app **no compila**: los adaptadores Hive
> (`pet_stats.g.dart`, `daily_missions.g.dart`) se generan, no están versionados.
{: .warning }

## Compilar

```bash
# APK de release (firmado si existe android/key.properties)
flutter build apk --release

# Otras plataformas
flutter build <android|ios|linux|macos|web|windows>

# Pruebas
flutter test
```

## Estructura del proyecto

```text
lib/
├── main.dart                 # Entrada: bootstrap, tema, i18n
├── core/                     # AppBootstrapper, AppLifecycleManager
├── services/
│   ├── device/               # BLE: BluetoothService, DeviceService, procesadores
│   ├── cloud/                # CloudService, CloudEvent, EventQueue (ThingsBoard)
│   ├── notifications/        # PetNotificationService (foreground + locales)
│   ├── locale_service.dart   # i18n (es/en)
│   └── update_service.dart   # Comprobación de actualizaciones
├── game/
│   ├── virtual_pet_game.dart # Juego principal (Flame)
│   ├── pets/                 # Pet, PetStats, BobTheBlob
│   ├── items/                # FoodMenu, ClothingCatalog
│   ├── missions/             # Mission, daily_missions, MissionService
│   ├── models/               # TelemetryData
│   └── minigames/            # flappy_bird, orchestra, donut, sbr
├── screens/                  # UI: game_screen, settings, sensores, HUD, menús
└── l10n/                     # app_localizations* (generado desde .arb)

android/app/src/main/kotlin/com/strawberryFrappe/sync_companion/
├── MainActivity.kt           # Entrada Flutter + MethodChannel
├── BleForegroundService.kt   # Conexión BLE persistente en 2.º plano
├── MissionManager.kt         # Evaluación de misiones en nativo
├── CloudManager.kt           # Encolado de telemetría en nativo
└── BootReceiver.kt           # Reanuda el servicio al arrancar
```

## Metadatos de la app

| Dato | Valor |
|------|-------|
| `applicationId` | `com.strawberryFrappe.sync_companion` |
| Etiqueta Android | `Therapets` |
| Nombre iOS | `Sync Companion` |
| Versión | ver `version:` en `pubspec.yaml` (formato `X.Y.Z+build`) |
| min/target/compile SDK | heredados de Flutter (`flutter.minSdkVersion`, etc.) |

## Dependencias clave

`flutter_blue_plus` (BLE), `flame` + `flutter_cube` (juego 2D/3D), `hive` +
`shared_preferences` (persistencia), `provider` (estado), `dio`/`http` +
`connectivity_plus` (red), `flutter_foreground_task` (servicio), `mobile_scanner`
(QR), `audioplayers`, `wakelock_plus`, `package_info_plus`, `url_launcher`.

> **No** se usa `permission_handler` (incompatibilidad con el embedding de Android);
> los permisos se solicitan con los prompts nativos de la plataforma. `google_fonts`
> fue reemplazado por la fuente empaquetada `Monocraft.ttf`.
{: .note }
