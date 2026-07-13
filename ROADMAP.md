# Therapets — Wind-Down Roadmap & Handoff Plan

> **Purpose.** Development is wrapping up. This file is the master plan to get the app
> into a shippable, documented, hand-off-ready state across multiple work sessions.
> It is the single source of truth for *what is left and in what order*.
>
> **Audience.** Us, session to session. A new developer should be able to read this +
> the docs site + the ADRs and pick up the project with minimal friction.
>
> **Status legend:** `[ ]` todo · `[~]` in progress · `[x]` done · `[!]` blocked (see note)
>
> _Last updated: 2026-07-12_

---

## Deadline sprint — Monday 2026-07-13 (single-day, owner-driven)

One waking day. **Mandatory before Monday night** — all require the S3 hardware, so they are
**owner-only, cannot be delegated to an agent:**

1. **SBR difficulty** — playtest each of the 4 levels on device. Extreme (0.15 bumper) under
   real IMU tilt is the risk. (Code done 2026-07-11; only the golden-path run is left.)
2. **Web allow-list** — drive the `TreatmentOverlay` HUD + an actually-filtered game menu on
   running hardware. Everything is unit-tested; nothing has been seen on a real app.
3. **Screen-off monitoring** — confirm telemetry/monitoring survives screen-off/Doze:
   `adb dumpsys power` wakelock check + the usage-undercount (wakelock) fix under real idle.
4. **(Maybe — only if it turns out needed) BLE robustness verify** on device. If not
   surfaced as needed → slips to Tuesday.

**Backend-dependent → coworkers (Monday):** does `patient_usage_time` derive server-side from
telemetry or need an app write-back? No write-back exists today. (FACTORY #37/#38.)

**Overnight agent (separate session, code-only, no device, no backend)** — preps Monday so the
hardware time above is pure verify. Scope this era, strictly ordered: **(1) BLE robustness code
pass (priority, deadline-relevant); (2) Orchestra — diagnose+propose, implement only a low-risk
slice, ONLY if task 1 is done + green.** Separate branches off `unstable` (where current BLE +
SBR work lives), local commits, **no push.**
Owner reviews on wakeup. Brief lives in scratchpad this session.

Anything not above (docs drift, sticky-type fix, full bug hunt) → not deadline work; Tuesday+.

---

## 0. End-state vision (what "done" means)

The app is a Flutter virtual-pet companion driven by a BLE hardware sensor (M5Stick +
IMU + MAX30100 pulse-ox **or** GY906 IR-temp). It is **no longer in a development phase** —
it is a maintained product being handed off. "Done" for this wind-down:

1. New/current hardware (**M5 Stick S3**) is supported and verified.
2. A health professional can, from the web platform, define which minigames a given
   user (identified by device token) may play — the app respects that allow-list.
3. Minigames have difficulty where it makes sense; nothing in the app is visibly broken.
4. The app is robust: BLE finds the device quickly, coins/missions/telemetry survive
   backgrounding and app kills, notifications fire in the background, sync status is
   truthful, no background crashes.
5. Docs (README, user manual, dev/handoff manual, ADRs) are accurate and de-scoped from
   "in development" language. The decisions currently living only in the author's head
   are written down as ADRs.
6. Git is clean: no stale branches/PRs, clear history, a documented branch strategy.

---

## 1. Priority & sequencing

**Two deadlines (owner, 2026-07-02):**
- **~2–3 days** — the boss's user-facing must-ships: **#4 difficulty, #3 web allowlist,
  #2 S3 verify.** These come FIRST.
- **~6 days tops** — everything else: git cleanup, robustness, docs/ADRs, stretch.

So the must-ships are front-loaded; git cleanup and docs are deferred into the back half.
Git cleanup is *not* a prerequisite for the feature work — do a 10-min triage now if it
helps, but the full pass waits.

| Order | Phase | Must-ship? | Target | Size |
|------|-------|-----------|--------|------|
| 1 | #4 SBR difficulty selector | ✅ hard | day 1 | 1 session |
| 2 | #3 Web game-allowlist (build to the seam) | ✅ hard | days 1–3 | 2–3 sessions |
| 3 | #2 M5 Stick S3 verification pass | ✅ hard | day 3 | 1 session |
| — | *(above due ~day 2–3)* | | | |
| 4 | Git cleanup + branch-strategy doc | foundation | days 4–6 | 1 session |
| 5 | #5 Robustness — confirmed-live bugs | important | days 4–6 | 2–3 sessions |
| 6 | #1 Documentation + ADRs + README de-scope | important | days 4–6 | 2 sessions |
| 7 | Stretch — Orchestra rework + full bug hunt | nice-to-have | if time | open |

> Phase *numbers below still describe the same work* — just execute in the **Order** column
> above. Detail sections are unchanged; only the running order moved.

---

## 2. Conventions — where things go

Decided with the project owner. Keep new-dev-facing material free of our agentic-coding
workflow (a new dev may not use Claude Code the same way).

- **This file (`ROADMAP.md`)** — our cross-session working tracker. Check boxes as we go.
- **`FACTORY.md`** — existing agentic-factory backlog. Keep it in sync but do **not** make
  the new-dev handoff *depend* on understanding it.
- **`docs/adr/NNNN-title.md`** — Architecture Decision Records. Dev-facing, in-repo. This is
  where the "author's brain" decisions get written down. (Dir to be created in Phase 1/5.)
- **GitHub Issues** — discrete bugs and anything out-of-scope for the wind-down, so a new
  dev sees them on GitHub. Use `gh issue create`.
- **Docs site (`/docs`, Just the Docs, bilingual ES/EN)** — end-user + developer manual.
  Must be accurate before handoff; link ADRs from the dev section.

---

## 3. Phase detail

### Phase 1 — Git cleanup + planning foundation
Clean base first: unblocks everything and makes the repo legible to a new dev.

- [x] Inventory every remote branch and open PR. **DONE 2026-07-02.** Outcome:
  - Closed stale bump PRs #23 + #27.
  - Deleted 23 dead remote branches + 1 local; only `main`/`dev`/`unstable` remain.
    `copilot/fix-coin-and-missions-loss` (was 6 ahead) verified superseded by the
    native persistence rewrite (`MissionService.save` → `_enqueueSave` on `unstable`;
    currency-order + `detached`-flush moot under native authority) → deleted.
  - Local `main`/`unstable` synced; stale remote-tracking refs pruned.
- [x] Close stale PRs #23 and #27 with a one-line reason. **DONE.**
- [x] Delete confirmed-dead remote branches (keep `main`, `dev`, `unstable`). **DONE.**
- [x] Document the branch strategy — captured in **ADR-0009** (`docs/adr/`), incl. the
      broken-USB-C origin story. `main` = stable, `dev` = nightly, `unstable` = sandbox.
- [x] Create `docs/adr/` and seed ADR index. **DONE** — index + template + ADRs 0001–0010.
- [x] Refresh `FACTORY.md` backlog to reflect this roadmap. **DONE 2026-07-02.**

**Acceptance:** ✅ `git branch -a` shows only live branches; no stale open PRs; branch
policy written (ADR-0009); `docs/adr/` exists; `FACTORY.md` refreshed.

---

### Phase 2 — #4 SBR difficulty selector (hard must-ship) — **CODE DONE 2026-07-11**
Self-contained win. Copied the pattern already proven in Flappy Bird.

- [x] `SbrDifficulty` enum + `SbrDifficultyConfig` preset map (easy/medium/hard/extreme) in
      new `lib/game/minigames/sbr/sbr_difficulty.dart`, mirroring `flappy_difficulty.dart`.
- [x] SBR tunables factored into the config — **owner's chosen knobs:** bumper width
      (0.32→0.15), starting lives (5/4/3/3, **floored at 3** — hard/extreme never below the
      base), per-hit speed ramp + cap, helpful-brick spawn bonus (more powerups on easy).
      Ball base speed left at 300 for all; **stacks on top of** the existing per-level curve
      (grid/HP growth untouched). Coins mirror Flappy 1/1/2/4.
- [x] Difficulty picker UI in `sbr_screen.dart` — title/difficulty overlay before game build,
      1–4 `SegmentedButton` (star icons, numbered per FACTORY young-player note), choice
      persisted to SharedPreferences (`sbr_difficulty`). Game now built lazily on Start.
- [x] Strings: reused existing `gameSbr` + `difficultyEasy/Medium/Hard/Extreme` — no new
      difficulty strings needed. (A `sbrCalibrationStep` key was added for the separate
      calibration-overlay redesign, not this feature.)
- [x] `flutter test` green (57 pass; added `test/sbr_difficulty_test.dart` preset invariants).
      `flutter analyze` clean.
- [ ] **Manual golden-path run of SBR at each level — DEFERRED to owner's verification sweep.**
      Not driven on device yet; extreme (0.15 bumper) under IMU tilt needs a playtest.

**Acceptance:** ✅ 1–4 picker + measurably-different presets + ES/EN + tests. ⚠️ Manual
per-level playtest outstanding (owner sweep). Values are one-line tweaks in `sbr_difficulty.dart`.

---

### Phase 3 — #3 Web game-allowlist — **DONE 2026-07-02** (turned out bigger than planned)
**What actually landed vs. the original plan below:** the web API turned out to return a full
treatment/prescription record (title, date range, status, daily usage target, enabled games),
not a bare game list. Built `TreatmentService` (not `GameAllowlistService` — different name,
same intent) against the real shape. **Read `docs/adr/0011-game-allowlist-treatment-integration.md`
first** — it has the full picture, confirmed facts, and what's still open. Short version below.

**Confirmed (were open questions, now resolved):**
- Device token for this endpoint = same value as ThingsBoard's `cloud_device_token`.
- `usage_time` / `patient_usage_time` are **daily**, in **seconds**.
- Cloud host split: `.20` = ThingsBoard telemetry (push, unchanged), `.19` = this treatment
  endpoint (`GET /patients/treatment/by-device-token/:deviceToken`).

**What shipped:**
- [x] `TreatmentService` (`lib/services/treatment/treatment_service.dart`) — fetch + cache +
      throttled (15 min) re-poll on bootstrap/resume, backend-name→internal-id mapping table.
- [x] Fail-open/fail-closed policy, decided explicitly with owner (see ADR-0011): fail-open on
      any technical failure (network/no-token/cold-start/empty-list), fail-closed only when
      `status` is positively non-`"active"`.
- [x] Gating wired into `game_menu.dart` (filters, **hides** non-prescribed games entirely —
      owner's call, no "disabled by your therapist" UI was built) / `game_screen.dart`.
- [x] Allow-list cached in SharedPreferences, survives offline/relaunch.
- [x] `TreatmentOverlay` HUD widget showing title/dates/status/today's usage progress.
- [x] `test/treatment_service_test.dart` — fail-open/closed matrix + name-mapping edge cases
      against the coworker's exact sample payload.
- [ ] **Not done yet — do this first tomorrow:** real device/emulator verification. Everything
      above is unit-tested and `flutter analyze`/`build`/`flutter test` clean, but nobody has
      driven the actual HUD overlay or an actually-filtered game menu on a running app.
- [!] **Open, unconfirmed:** does the backend derive `patient_usage_time` from the
      `sync_status` telemetry the app already sends, or does the app need a write-back path
      that doesn't exist yet? If the progress bar looks frozen relative to real usage, this is
      the first thing to check with the coworker. (No write-back is assumed/built.)
- Deferred, tracked as GitHub issues: #30 (`pet_stats_bundle` dual-write bug found along the
  way), #31 (battery-optimization exemption prompt, closes the harder full-Doze telemetry
  gap), #32 (revive dead native `MissionManager.kt` scaffold so treatment tracking can survive
  the app being closed, same way `sync_status` already does — not done this session).

<details>
<summary>Original plan going into this phase (kept for context, superseded by the above)</summary>

**Decision (owner):** the web platform will expose a JSON that lists the games a user
(device token) is allowed to play. The app **fetches** that list by device token; we likely
need an **adapter** to normalize whatever shape the web API returns. Build everything up to
the network seam so only the real request/parse needs filling in when the web details land.

- Define an `AllowedGames` model + `GameAllowlistService` with a clean interface:
  `Future<Set<GameId>> fetchAllowedGames(String deviceToken)`.
- Adapter seam behind an interface so the parser can be swapped once the web JSON shape is
  known.
- Localize new UI (e.g. "This game is disabled by your therapist").
- Two cloud hosts, reason for the split unconfirmed at the time.

</details>

**Acceptance:** ✅ gating works end-to-end against the real endpoint; allow-list cached
offline; ADR written (0011). ⚠️ Real-hardware verification still outstanding (see above).

**As a bonus/prerequisite this session:** a coworker-reported usage-undercount bug (1hr of
wear logging as ~15min) got fixed first, since it touched the same cloud-client code this
phase needed to build on — see `docs/adr/0011-...md`'s "Telemetry envelope" section and
`docs/telemetria.md` / `docs/en/telemetry.md` for the updated wire format. **Not yet verified
on real hardware either** — the wakelock fix needs an `adb dumpsys power` check on a device
under actual screen-off idle (steps are in the ADR/PR notes) before this can be called closed.

---

### Phase 4 — #5 Robustness (confirmed-live / unverified bugs)
Targeted fixes for what the owner confirmed still reproduces or hasn't verified. The broad
"top-to-bottom bug hunt" is Phase 7.

- [ ] **BLE detect slow/fails.** Audit scan start/timeout/filters in
      `lib/services/device/bluetooth_service.dart` and native
      `android/app/.../BleForegroundService.kt` (FACTORY notes prior fixes to "unbounded
      scanning" and reconnect backoff — verify they hold; check scan filters aren't too
      strict for the S3 advertising name/UUID).
- [ ] **Notifications silent unless app open.** Verify the foreground-service notification
      channel + `pet_notification_service.dart` fire from native while backgrounded; check
      Android 13+ `POST_NOTIFICATIONS` runtime grant path (note: project forbids
      `permission_handler` — uses platform prompts).
- [ ] **Background crash.** Reproduce, capture `adb logcat` stack, fix. Suspect areas:
      Flutter engine suspension vs native `BleForegroundService`/`CloudManager`/
      `MissionManager` lifecycle.
- [ ] **UI inconsistencies.** Enumerate concrete cases (screenshot/notes) before fixing —
      turn each into a checklist item or GitHub issue.
- [ ] Re-verify the "believed-fixed" ones instead of trusting them:
      coins/missions persistence (FACTORY says fixed 2026-05-29) and background telemetry
      delivery (cloud-cred file fix 2026-06-04). Add/keep persistence tests green.
- [ ] Test: `flutter test` (persistence suite is mandatory before any push per AGENTS.md).

**Acceptance:** each confirmed bug has a repro→fix→verify note; persistence + lifecycle
tests pass; notifications fire backgrounded on a real device.

---

### Phase 5 — #1 Documentation + ADRs + README de-scope
Make the docs trustworthy and write down the tribal knowledge.

- [ ] **README:** remove "Development Status / Stage 5 / stage history" framing; replace with
      a maintained-product overview. Fix the `flutter run` quick-start (currently PowerShell
      block — owner is on Linux; make it OS-neutral).
- [ ] **Validate the docs site** (`/docs`, ES + EN) against current code — architecture
      diagram, BLE packet protocol, native layer, data model, telemetry/cloud, i18n. Fix
      drift. (Owner cannot personally vouch for its current accuracy.)
- [x] **Write ADRs** (`docs/adr/`) — **DONE 2026-07-02**, rationale captured from owner:
  - `0001` Native-authoritative architecture (Kotlin source of truth).
  - `0002` SharedPreferences JSON bundles over Hive (cross-language + corruption).
  - `0003` Firmware-aware presence profiles (strict-by-default / lenient duty-cycle).
  - `0004` `provider` as service locator, not reactive state (streams/Flame own state).
  - `0005` No `permission_handler`; native BLE-channel permissions (+ code warning added).
  - `0006` Sticky device-type by packet size (avoided a self-ID handshake; known swap bug).
  - `0007` Truthful telemetry + bounded UX grace (clinical honesty vs PoC sensor flakiness).
  - `0008` Push-only cloud (simplicity; being revisited for the allowlist read; two-host
    `.19`/`.20` split reason unknown — flagged as open).
  - `0009` Three-branch pipeline (broken USB-C → OTA nightly/experimental channels).
  - `0010` Corrupted-packet heuristics (IMU > 10g; IR |Δ| > 20000).
  - **Pending:** game-allowlist ADR — write during Phase 3 once web API is designed.
  - *Note:* `flutter.`-prefix credential gotcha lives in ADR-0002 (not its own ADR).
- [x] **README:** de-scoped — removed Stage-5 framing → Features section; OS-neutral quick
      start; Project Structure updated to match real `lib/` tree. **DONE.**
- [ ] Link the ADR index (`docs/adr/`) from the dev docs section of the Jekyll manual.

**Acceptance:** README reads as a finished product; docs match code; all listed ADRs exist
and are linked; a new dev can onboard from docs alone. (Jekyll-manual link-in still pending —
deployed docs intentionally untouched this session.)

---

### Phase 6 — #2 M5 Stick S3 verification (hard must-ship, do near end)
Owner tested S3 today and it worked; this is a verification/guard pass, not new build.

- [ ] Diff `artifacts/M5StickS3_new/*` firmware vs `artifacts/M5StickC_old/*`; document
      what changed and which `.ino` variant is the shipping one (battery / no_dutycycle /
      original) for each sensor.
- [ ] Confirm the app's BLE scan filter + packet-size sticky detection work with the S3's
      advertised name/service across both sensor variants.
- [ ] Full manual smoke: pair, telemetry, both sensors, minigames, cloud push, notifications,
      background survival — on S3 hardware.
- [ ] Re-test the device-switch sticky-type bug (swap temp↔pulse) now that both devices are
      on hand (see memory `device-switch-sticky-type`).
- [ ] Document the flashing procedure (Arduino/PlatformIO, board, libs) in the docs.

**Acceptance:** S3 verified end-to-end on hardware; firmware variants documented; flashing
steps written; sticky-type swap re-tested.

---

### Phase 7 — Stretch (nice-to-have)
- [ ] **Orchestra rework.** Owner: the movement-based cursor + gesture-as-orders attempt
      "went horrible"; it's the biggest thing that works badly. Redesign the interaction
      (`lib/game/minigames/orchestra/`) — simpler, reliable mapping — or scope it down.
- [ ] **Full top-to-bottom bug hunt.** Systematic pass across all screens/services (owner
      explicitly wants this — later, not now). File findings as GitHub issues.

---

## 4. Open questions / blockers (chase these)

- [x] **Web API for the game allow-list** (Phase 3) — **RESOLVED 2026-07-02.** It's a
      treatment-record `GET` endpoint, not a bare game list. See `docs/adr/0011-...md`.
- [x] **Cloud host `.19` vs `.20`** — **RESOLVED 2026-07-02.** `.20` = ThingsBoard telemetry,
      `.19` = the treatment/allowlist endpoint. Same device-token value for both.
- [ ] **New, from this session:** does the treatment endpoint's `patient_usage_time` get
      derived server-side from telemetry, or does the app need to push progress somewhere?
      No write-back exists/assumed today. *→ ask coworkers.*
- [ ] **New, from this session:** real-device verification pending for both the wakelock fix
      (usage-undercount bug) and the treatment/game-allowlist feature — neither has been run
      on actual hardware yet, only unit-tested + `flutter build` verified.

_(Branch strategy resolved: `main` stable / `dev` nightly / `unstable` experimental sandbox
— documented in Phase 1.)_

## 5. Guardrails (from AGENTS.md — do not violate)
- Run `flutter test` and keep persistence tests green **before** any commit/push.
- Local storage = SharedPreferences atomic JSON bundles. **Hive forbidden.**
- No `permission_handler`; use platform prompts.
- State management = `provider`.

---

## 6. Orchestra/Theremin + Advanced Settings — backlog register (2026-07-12)

Owner playtest on latest `unstable` build surfaced 7 distinct issues. **Investigation only —
not fixed this session.** Deliberately split into separate items so each can be picked up in
its own session/dynamic-workflow slice instead of one broad sweep (risk of context corruption /
agentic drift given how many unrelated files this touches). Supersedes/details the terse
"Orchestra rework" stretch bullet in Phase 7 above.

- [x] **6.1 — Orchestra settings audit — DONE 2026-07-12.** Confirmed all 20 constants below are
  still live (MIDI root/span/snap, freq clamp band, audio gate hysteresis, change-detection
  thresholds, auto-calibrate hysteresis, telemetry watchdog, glide factor in `orchestra_game.dart`;
  complementary-filter/swing constants in `height_estimator.dart`; buffer/rate bounds in
  `tone_player.dart`). **Verdict: audit-only, no new UI added.** All 20 are DSP/audio-engine
  internals (filter coefficients, hysteresis bands, buffer sizes, watchdog timers) — none read as
  a genuine player-facing setting the way `orchestraHeightMode` (`settings_page.dart`, the one
  existing control) does; exposing them would let a player break the instrument into an unusable
  state, not tune it. Closed as audit-complete; revisit only if a specific control is requested.
  - `orchestra_game.dart:42-46` — `MusicScale` root MIDI (57) / span octaves (2) / snap
    strength (0.85)
  - `orchestra_game.dart:151-152` — frequency clamp band (MIDI 45–93)
  - `orchestra_game.dart:245` — audio gate hysteresis (0.03/0.06)
  - `orchestra_game.dart:257-258` — change-detection thresholds (0.5 Hz / 0.01 vol)
  - `orchestra_game.dart:285-288` — auto-calibrate hysteresis (45°/s gyro, 0.5–2.0g, 15-sample)
  - `orchestra_game.dart:310` — telemetry stale watchdog (400ms)
  - `orchestra_game.dart:315` — glide factor (dt×12.0)
  - `height_estimator.dart:60-73` — gravityAlpha/velocityLeak/dispLeak/complementaryK/swing
    attack-release/angle+height range constants
  - `tone_player.dart:26-32` — sample rate, buffer duration, base freq, playback-rate bounds

- [!] **6.2 — Orchestra input latency — DEFERRED, moved to GitHub issue #39.** Owner call
  2026-07-12: not blocking (nothing breaks, just feels slow), boss won't care — pull off the
  active queue, leave for a later batch/next person. Pipeline trace + file:line detail kept
  here (not duplicated in the public issue): `device_service.dart:241-248` telemetry stream →
  `orchestra_game.dart:272-301 _onTelemetry` (per BLE packet, ~50-100ms typical) →
  `height_estimator.dart:125-173 update(dt)` (gravity LPF α0.9, complementary fusion K0.02,
  swing attack/release 0.3/0.05) → `music_scale.dart:115-140 map(h)` (snap 0.85) →
  `orchestra_game.dart:304-318 update(dt)` per-frame glide (dt×12.0) + hysteresis →
  `tone_player.dart:50-54 _run()` Future-chain-serialized platform channel calls
  (`_doStart` at 68-82). Needs on-device latency measurement before touching anything.

- [x] **6.3 — Rename display "Orchestra" → "Theremin" — DONE 2026-07-12.** Renamed:
  `orchestra_screen.dart:48` title, `orchestra_game.dart:351` in-game title text,
  `l10n/app_en.arb`/`app_es.arb` `gameOrchestra` (also added the previously-missing ES
  `gameOrchestraDesc`), `game_menu.dart` menu entry label, plus the "Orchestra Height Sensing"
  card title/description in `settings_page.dart` (now localized, see 6.6 — landed as "Theremin
  Height Sensing" / "Detección de Altura del Theremín"). `flutter gen-l10n` re-run. Kept as-is
  (internal): `OrchestraGame`/`OrchestraScreen` classes, `orchestraHeightMode` field,
  `'orchestra'` game-ID routing string, directory name, `HeightMode`/`ScaleType` enums.

- [ ] **6.4 — Orchestra UI rebuild from scratch.** Owner's judgment: patch-level fixes aren't
  enough, the interaction/UI needs a redesign (echoes existing Phase 7 note: movement-cursor +
  gesture-as-orders "went horrible"). Own phase, sequenced **after** 6.1/6.2 are scoped (redesign
  should account for which settings become real controls and what the latency budget is).

- [x] **6.5 — Advanced Settings: wrong sensor button shown — FIXED 2026-07-12, unverified on
  hardware.** Root cause confirmed: two premature `_deviceType = DeviceType.max30100` writes in
  `device_service.dart` (one in the native-BPM listener, one in `init()`'s post-connect re-verify
  block) raced ahead of the correct packet-size sniff (`:252-258`, 16 bytes→max30100 /
  14 bytes→gy906), so a GY906 (temp) device receiving a native BPM value before its first raw
  packet got locked to `max30100`. Neither write was needed — `_tryPreSeed()`, the only thing
  those callbacks feed, never reads `_deviceType`. Both removed; packet-size sniff is now the
  sole source of truth, matching the field's own "sticky - determined by first packet" comment.
  `flutter analyze`/`flutter test` (79 tests) clean. **Not yet re-tested on real GY906 hardware**
  — do this during the Phase 6 S3 verification pass (device-switch sticky-type re-test item).

- [x] **6.6 — Advanced Settings: black cards clash + English-only — DONE 2026-07-12.** Removed
  hardcoded `Colors.grey[900]` from the 3 Cards (SBR Upward Speed / Lenient Sensor Mode /
  Theremin Height Sensing) and the Raw Data Terminal button (+ its paired
  `foregroundColor: Colors.white`) — all now inherit the app's default light theme, consistent
  with the rest of the page. Localized the 7 hardcoded-English strings via 7 new
  `AppLocalizations` keys (EN + ES) in `app_en.arb`/`app_es.arb`, `flutter gen-l10n` re-run.

- [ ] **6.7 — SBR minigame assumes left-arm play, no handedness option.** Fixed sign convention,
  not configurable: `motion_calibrator.dart:36` (`-data.ax` hardcoded roll sign), `:49-50`
  `confirmLeft` / `:54-66` `confirmRight` two-phase calibration, `:74-84` `mapAngleToScreenX`
  (left→left edge, right→right edge); `calibration_overlay.dart:14-15,59-60,63-66` (UI prompts
  "tilt wrist max left" then "max right"); `sbr_game.dart:87-94 _onTelemetry` applies roll→screenX
  with no inversion. Confirmed no existing handedness/invert/mirror setting anywhere in `lib/`
  (`game_settings.dart` only has `sbrUpwardSpeedMultiplier`, `orchestraHeightMode`). Fix shape:
  add a handedness field to `GameSettings` + invert the roll sign / swap calibration-phase
  labels in `motion_calibrator.dart`. Medium, 1 session, needs device testing both-handed.

**Acceptance for this register:** each item above is independently pickable in its own
session/workflow slice; none has been implemented yet. Owner to prioritize/sequence at next
review — not implied to follow the 6.1→6.7 order above.
