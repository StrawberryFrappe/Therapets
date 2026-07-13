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
- [x] **#3** Web game-allowlist → `TreatmentService` (turned out to be a full treatment record,
      not a bare game list). Fail-open/fail-closed gating, hide-not-disable UI, cached offline.
      **Real-device verification still outstanding.** See ADR-0011.
- [ ] **#2** M5 Stick S3 firmware/device verification pass. *Must-ship.*
- [ ] Robustness: silent notifications, slow/failing BLE detect, UI inconsistencies, background crash.
- [ ] Stretch: Orchestra minigame rework; full top-to-bottom bug hunt.
- [x] Confirm cloud host split: `.20` ThingsBoard (telemetry push) vs `.19` treatment/allowlist
      endpoint. Same device-token value for both. (ADR-0008 open question, resolved via ADR-0011.)
- [ ] Link the `docs/adr/` index into the Jekyll dev manual.
- [ ] Cloud-hardening usage-undercount fix (wakelock in `BleForegroundService.kt`) needs
      real-device `adb dumpsys power` verification — done via `flutter analyze`/build/test only.
- [ ] GitHub #30 — `pet_stats_bundle` written independently by native `checkPetCare()` and Dart
      `PetStats` (race risk).
- [ ] GitHub #31 — wire up the dead `requestBatteryOptimization` prompt (closes the harder
      full-Doze telemetry gap the wakelock fix alone doesn't cover).
- [ ] GitHub #32 — revive dead native `MissionManager.kt` scaffold; would let treatment-progress
      tracking survive the app being closed, same way `sync_status` telemetry already does.
- [ ] Confirm with coworker whether `patient_usage_time` (treatment endpoint) is derived
      server-side from telemetry, or needs an explicit write-back path (none exists/assumed).

## 3. History Log

### Executed Tasks
- **[2026-05-23]**: Initialized Antigravity Modular Factory Workflow. Scaffolded `agents/` personas and established strict documentation/logging mandates. Created initial `FACTORY.md` and `docs/architecture.md`.
- **[2026-05-23]**: Implemented Native JSON Mission System (`MissionManager.kt`), added robust heuristic filters for corrupted BLE packets (IMU magnitude > 10g and IR delta > 20000), and introduced configurable disconnected cloud logging.
- **[2026-05-24]**: Resolved code review items (DeviceService compilation, BioSignalProcessor recovery threshold on baseline jumps, architecture diagram mapping, deprecated Flutter lifecycle state saving comments, and daily missions base-class method shadowing). Verified build and test compliance. Wrapped up and pushed all fixes to `unstable` branch.
- **[2026-05-24]**: Fixed additional code review issues: corrected unbounded BLE scanning, filter application, and reconnect backoff in `BleForegroundService.kt`; resolved `LateInitializationError` risk in `MissionService` when Hive `_box` is null; restored robust initialization chain in `AppBootstrapper`. Staged, reviewed, and ready to push.
- **[2026-05-24]**: Fixed CI failure on `main` branch caused by branch protection rules during version bump. Replaced direct `git push` with `peter-evans/create-pull-request` action in `release.yml` to automatically generate pull requests for version bumps.
- **[2026-05-24]**: Numbered Flappy Bob difficulty levels from 1 to 4 to prevent young players from feeling discouraged when selecting easier options. Updated English and Spanish `.arb` resources and associated Dart localization wrapper files.
- **[2026-05-24]**: Updated SBR minigame calibration flow: Reduced from 3 to 2 steps (Left/Right), mapped bumper edges perfectly to screen edges using linear interpolation, forced Bob's sprite as the ball regardless of connection state, and added visual UI assets for calibration poses.
- **[2026-05-24]**: Scaffolded Jekyll-based GitHub Pages usage manual in `/docs`, configured with Cayman theme, custom navigation header layout, and markdown pages for Welcome, BLE Setup, Daily Missions, and Pet Care.
- **[2026-05-24]**: Fixed SBR minigame mechanics by stopping the upward speed multiplier from compounding into bounce velocity, which was causing the ball to continuously gain speed. Swapped the flipped left/right instruction images in the calibration overlay.
- **[2026-05-25]**: Created `technical_writer` and `github_pages_specialist` agents, added them to `AGENTS.md`. Designed and implemented a beautiful glassmorphism-pastel jekyll layout from scratch. Translated and rewrote all manual pages in both Spanish and English, including detailed step-by-step guides for BLE sync state, daily missions grace windows, updates, telemetry calibration, and architecture diagrams rendered via dynamic Mermaid.js.
- **[2026-05-29]**: Audited and fixed data persistence bugs causing coins/stats to reset. Removed Hive dependencies entirely to eliminate race conditions and dual-store desync. Migrated to a unified SharedPreferences JSON atomic bundle architecture, and added native swipe-to-flush via `BleForegroundService.onTaskRemoved`.
- **[2026-06-04]**: Fixed native `CloudManager.kt` SharedPreferences file mismatch. Native code was reading `cloud_base_url` and `cloud_device_token` from `getDefaultSharedPreferences()` (wrong file), while Flutter UI writes them to `FlutterSharedPreferences` with `flutter.` key prefix. Added `flutterPrefs` handle to read config from correct file. Queue storage remains in default prefs to avoid cross-contamination.
- **[2026-07-02]**: Git cleanup for handoff. Closed stale bump PRs #23/#27; deleted 23 dead remote branches + 1 local, leaving only the `main`/`dev`/`unstable` release pipeline. Verified `copilot/fix-coin-and-missions-loss` (6 commits ahead) was superseded by the native persistence rewrite before deleting. Synced local `main`/`unstable`, pruned stale refs.
- **[2026-07-02]**: Seeded `docs/adr/` (index + MADR template) and wrote ADRs 0001–0010 capturing architectural decisions previously only in the owner's head: native-authoritative background, SharedPreferences-over-Hive, firmware-aware presence profiles, provider-as-service-locator, no-`permission_handler` native permission path (+ warning comment in `bluetooth_service.dart`), sticky device-type by packet size, truthful-telemetry-with-UX-grace, push-only cloud, three-branch pipeline, corrupted-packet heuristics. De-scoped README (features framing, OS-neutral quick start, corrected project structure). Synced `ROADMAP.md` progress.
- **[2026-07-02]**: Cloud-hardening pass, prompted by a coworker report that ~1hr of continuous device wear was logged as ~15min. Root cause: `BleForegroundService.kt`'s 1Hz sync tally ran on a `Handler.postDelayed` loop with no wakelock held anywhere, so it stalled on screen-off CPU idle. Fixed with a `PARTIAL_WAKE_LOCK` scoped to BLE-connected lifetime (acquire on GATT connect, release on disconnect/destroy, all release sites try/catch-wrapped after code review flagged a cross-thread double-release race). Also unified the two divergent cloud JSON envelopes (native `CloudManager.kt` vs Dart `cloud_service.dart`) into one shape (`{eventType, timestamp, payload}`) — **this did not merge event types**, `sync_status`/`mission_completed`/`minigame_played` remain separate POSTs, only the wrapper shape is now shared. Deleted a redundant, less-reliable Dart-side `sync_session` usage tracker (kept the pet-decay tick in the same code block). Removed the dead `flutter_foreground_task` plugin entirely (configured with `allowWakeLock: true` but `startService()` was never called anywhere — confirmed via grep). Filed GitHub #30/#31/#32 for bugs/follow-ups found along the way instead of only noting them in memory. `flutter analyze`/`build apk --debug` clean; not yet verified on real hardware (see `ROADMAP.md` Phase 3 / open questions).
- **[2026-07-02]**: Built the Phase 3 web-game-allowlist feature once the coworker sent the real endpoint (`GET /patients/treatment/by-device-token/:deviceToken`) — turned out to be a full treatment/prescription record (title, date range, status, daily usage target in seconds, enabled games), not a bare game list as originally scoped. Built `TreatmentService` (read-only, cached, 15min-throttled poll on bootstrap/resume) with an explicit fail-open/fail-closed policy confirmed with the owner: fail-open on any technical failure, fail-closed only when the backend positively reports a non-`"active"` treatment status. Backend's game-name vocabulary (`"flappy bob"`, `"block breaker"`, etc.) mapped to internal ids via a hardcoded table. `game_menu.dart` hides non-prescribed games entirely (owner's call). Added `TreatmentOverlay` HUD widget and `test/treatment_service_test.dart` covering the policy matrix against the coworker's exact sample payload. Full writeup in `docs/adr/0011-game-allowlist-treatment-integration.md`. Real-device verification still outstanding — flagged in `ROADMAP.md`.
- **[2026-07-12]**: Closed out ROADMAP §6 item 6.4 (Orchestra/Theremin in-game UI rebuild).
  Root cause of the "controls unreachable" report: the entire HUD (title, status hint,
  CALIB/LOCK/scale/octave/span, EXIT) was hand-painted Flame `Canvas` components with no
  `SafeArea` awareness, so the bottom control row could sit under the landscape gesture-nav bar
  — plus 100% hardcoded English, no l10n. Rebuilt as a Flutter widget overlay
  (`orchestra_screen.dart`, `MinigameScreen.overlay`, precedent from `flappy_bird_screen.dart`)
  inside `SafeArea`, with Material buttons and a `ValueListenableBuilder` on a new
  `OrchestraGame.uiRevision` notifier (fires only on real state transitions, not per-frame).
  Flame now renders stage visuals only (background, `MotionCursor`, `PetMusician`s) — no
  interactive canvas components remain. Added 12 EN/ES l10n keys for every control
  label/status hint; `flutter gen-l10n` re-run. `OrchestraGame` control methods
  de-privatized for the overlay to call; DSP/audio logic untouched. `flutter analyze` clean,
  `flutter test` 79/79 green, `cavecrew-reviewer` adversarial pass run before commit (see
  work.log for round count). No widget test added (no screen-widget-test precedent in this repo; `wakelock_plus` platform
  channel unmocked under `flutter test`) — flagged as an outstanding gap, same as the
  not-yet-verified-on-real-hardware caveat.
- **[2026-07-12]**: Closed out ROADMAP §6 items 6.1/6.3/6.5/6.6 (6.7 dropped, owner call). **6.1** — audited the 20 hardcoded Orchestra/Theremin tuning constants (`orchestra_game.dart`, `height_estimator.dart`, `tone_player.dart`); verdict is audit-only, none are good player-facing settings (DSP internals, not tunable-by-design), no new UI added. **6.3** — renamed all user-visible "Orchestra" strings to "Theremin" (`orchestra_screen.dart`, `orchestra_game.dart`, both `.arb` files, `game_menu.dart`, the settings-page height-sensing card), left every internal identifier (`OrchestraGame`/`OrchestraScreen`, `orchestraHeightMode`, the `'orchestra'` routing string, directory name) untouched; also filled in a previously-missing ES `gameOrchestraDesc` key found along the way. **6.5** — fixed the wrong-sensor-button bug: `device_service.dart` had two speculative `_deviceType = DeviceType.max30100` writes (native-BPM listener + post-connect re-verify block) that raced ahead of the correct packet-size sniff, locking GY906 (temperature) devices to the pulse-oximeter UI if a native BPM value arrived before the first raw packet. Removed both; the packet-size sniff (14 vs 16 bytes) is now the sole `_deviceType` writer. Not yet re-verified on real GY906 hardware — folded into the existing Phase 6 S3 sticky-type re-test item. **6.6** — stripped hardcoded `Colors.grey[900]` off 3 Advanced Settings cards + the Raw Data Terminal button (was rendering near-illegible dark cards against the app's light theme), and localized the page's 7 hardcoded-English strings via new EN/ES `AppLocalizations` keys. `flutter analyze` clean, `flutter test` 79/79 green, reviewed clean by `cavecrew-reviewer` before commit.
