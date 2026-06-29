# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]
- **Documentation Overhaul**: Rebuilt the GitHub Pages manual on the Just the Docs
  theme (dark mode, search, auto sidebar). Added a complete bilingual (ES/EN) manual
  covering both end users and developers: install, BLE pairing, pet care, store,
  wardrobe, missions, minigames, sensors, settings, plus a full handoff reference
  (architecture, BLE packet protocol, native Android layer, telemetry/cloud, data
  model, CI/CD, extending the app, i18n). Embedded real app screenshots.
- **Architectural & Code Audit Remediation**:
  - **Native Mission System**: Created `MissionManager.kt` to evaluate missions based on JSON configuration directly from Native Android to ensure survival during Flutter Engine suspension.
  - **Offline Cloud Logs**: Configurable offline cloud logging inside `BleForegroundService.kt` to ensure disconnected time logs continuously if `enable_disconnected_cloud_logs` is enabled.
  - **Corrupted Packet Filter**: Implemented heuristic filters based on impossible IMU magnitude (>10g) and physiological bounds (|delta| > 20,000 for IR data) across Native Kotlin and Flutter Dart layers.

## [1.0.0] - 2026-01-12

### Added
- **Phase 1: Connection Stability**
  - Persistent BLE connection with foreground service.
  - Robust reconnection logic and background stability.
- **Phase 2: Virtual Pet**
  - Interactive virtual pet with happiness and hunger stats.
  - Basic "feeding" interaction.
- **Phase 3: Telemetry Minigames**
  - **Flappy Bird**: Controlled by device shake/motion.
  - **Donut Viewer**: 3D model rotation controlled by device tilt (IMU).
  - **Pet Orchestra**: Theremin-style audio game controlled by roll/pitch.
- **Phase 4: Cloud & Missions**
  - Daily mission system (e.g., "Walk 10 min").
  - Cloud synchronization with Thingsboard (HTTPS).
  - Offline event queueing with Hive.
  - Advanced settings for Cloud and Dev Tools.

### Changed
- Refactored `DeviceService` to be the central hub for high-level motion events.
- Organized services into `device`, `cloud`, and `notifications` directories.
