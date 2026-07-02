# Therapets Factory State

## 1. Project State
- **Status:** Wind-down / handoff preparation
- **Current Objective:** Hand the project to a new developer with minimal friction. Master plan lives in `ROADMAP.md`; tribal-knowledge decisions captured as ADRs in `docs/adr/`.
- **Last Sync:** 2026-07-02

## 2. Full Backlog
- [x] Migrate Cloud pushes (Thingsboard HTTP) and Mission tallies to Native to survive Flutter Engine suspension.
- [x] Audit `BleForegroundService` stability and 15-second grace window logic.
- [x] Implement robust error handling for `bio_signal_processor.dart` when receiving corrupted BLE packets.
- [x] Create dedicated agents for technical documentation and github pages optimization.
- [x] Redesign Jekyll-based usage manual with a premium multilingual glassmorphism/pastel design, comprehensive guides, and Mermaid.js diagrams.
- [x] Fix native CloudManager SharedPreferences file mismatch preventing cloud telemetry delivery.
- [x] Presence detection: strict-by-default with opt-in lenient duty-cycle profile (PR #29).
- [x] Git cleanup: close stale PRs, delete dead branches, keep `main`/`dev`/`unstable` pipeline.
- [x] Seed `docs/adr/` and write ADRs 0001–0010 for undocumented architectural decisions.
- [x] De-scope README (remove staging language, OS-neutral quick start, fix project structure).
- [ ] **#4** SBR minigame difficulty selector (copy Flappy difficulty pattern). *Must-ship.*
- [ ] **#3** Web game-allowlist: fetch/adapter path + token-gated minigame access. *Must-ship, blocked on web API design.*
- [ ] **#2** M5 Stick S3 firmware/device verification pass. *Must-ship.*
- [ ] Robustness: silent notifications, slow/failing BLE detect, UI inconsistencies, background crash.
- [ ] Stretch: Orchestra minigame rework; full top-to-bottom bug hunt.
- [ ] Confirm cloud host split: `.20` ThingsBoard vs `.19` web platform (ADR-0008 open question).
- [ ] Link the `docs/adr/` index into the Jekyll dev manual.

## 3. History Log

### Executed Tasks
- **[2026-05-23]**: Initialized Antigravity Modular Factory Workflow. Scaffolded `agents/` personas and established strict documentation/logging mandates. Created initial `FACTORY.md` and `docs/architecture.md`.
- **[2026-05-23]**: Implemented Native JSON Mission System (`MissionManager.kt`), added robust heuristic filters for corrupted BLE packets (IMU magnitude > 10g and IR delta > 20000), and introduced configurable disconnected cloud logging.
- **[2026-05-24]**: Resolved code review items (DeviceService compilation, BioSignalProcessor recovery threshold on baseline jumps, architecture diagram mapping, deprecated Flutter lifecycle state saving comments, and daily missions base-class method shadowing). Verified build and test compliance. Wrapped up and pushed all fixes to `unstable` branch.
- **[2026-05-24]**: Fixed additional code review issues: corrected unbounded BLE scanning, filter application, and reconnect backoff in `BleForegroundService.kt`; resolved `LateInitializationError` risk in `MissionService` when Hive `_box` is null; restored robust initialization chain in `AppBootstrapper`. Staged, reviewed, and ready to push.
- **[2026-05-24]**: Numbered Flappy Bob difficulty levels from 1 to 4 to prevent young players from feeling discouraged when selecting easier options. Updated English and Spanish `.arb` resources and associated Dart localization wrapper files.
- **[2026-05-24]**: Updated SBR minigame calibration flow: Reduced from 3 to 2 steps (Left/Right), mapped bumper edges perfectly to screen edges using linear interpolation, forced Bob's sprite as the ball regardless of connection state, and added visual UI assets for calibration poses.
- **[2026-05-24]**: Scaffolded Jekyll-based GitHub Pages usage manual in `/docs`, configured with Cayman theme, custom navigation header layout, and markdown pages for Welcome, BLE Setup, Daily Missions, and Pet Care.
- **[2026-05-24]**: Fixed SBR minigame mechanics by stopping the upward speed multiplier from compounding into bounce velocity, which was causing the ball to continuously gain speed. Swapped the flipped left/right instruction images in the calibration overlay.
- **[2026-05-25]**: Created `technical_writer` and `github_pages_specialist` agents, added them to `AGENTS.md`. Designed and implemented a beautiful glassmorphism-pastel jekyll layout from scratch. Translated and rewrote all manual pages in both Spanish and English, including detailed step-by-step guides for BLE sync state, daily missions grace windows, updates, telemetry calibration, and architecture diagrams rendered via dynamic Mermaid.js.
- **[2026-05-29]**: Audited and fixed data persistence bugs causing coins/stats to reset. Removed Hive dependencies entirely to eliminate race conditions and dual-store desync. Migrated to a unified SharedPreferences JSON atomic bundle architecture, and added native swipe-to-flush via `BleForegroundService.onTaskRemoved`.
- **[2026-06-04]**: Fixed native `CloudManager.kt` SharedPreferences file mismatch. Native code was reading `cloud_base_url` and `cloud_device_token` from `getDefaultSharedPreferences()` (wrong file), while Flutter UI writes them to `FlutterSharedPreferences` with `flutter.` key prefix. Added `flutterPrefs` handle to read config from correct file. Queue storage remains in default prefs to avoid cross-contamination.
- **[2026-07-02]**: Git cleanup for handoff. Closed stale bump PRs #23/#27; deleted 23 dead remote branches + 1 local, leaving only the `main`/`dev`/`unstable` release pipeline. Verified `copilot/fix-coin-and-missions-loss` (6 commits ahead) was superseded by the native persistence rewrite before deleting. Synced local `main`/`unstable`, pruned stale refs.
- **[2026-07-02]**: Seeded `docs/adr/` (index + MADR template) and wrote ADRs 0001–0010 capturing architectural decisions previously only in the owner's head: native-authoritative background, SharedPreferences-over-Hive, firmware-aware presence profiles, provider-as-service-locator, no-`permission_handler` native permission path (+ warning comment in `bluetooth_service.dart`), sticky device-type by packet size, truthful-telemetry-with-UX-grace, push-only cloud, three-branch pipeline, corrupted-packet heuristics. De-scoped README (features framing, OS-neutral quick start, corrected project structure). Synced `ROADMAP.md` progress.
