# 0011. Game-allowlist via treatment-record fetch (revises ADR-0008)

- **Status:** Accepted
- **Date:** 2026-07-02
- **Deciders:** Project owner (@StrawberryFrappe), coworker (backend/web platform)

## Context

`ROADMAP.md` Phase 3 called for a health professional to define, from the web
platform, which minigames a patient (identified by device token) may play. The
plan going in was a simple `GET` returning a game list, keyed by device token,
against one of two known cloud hosts (`.19` web platform vs `.20` ThingsBoard —
see [[ADR-0008]]'s open question).

Same session, a separate problem surfaced first: a coworker reported ~1 hour of
device wear logging as ~15 minutes of usage. That turned into a cloud-hardening
pass (wakelock fix in `BleForegroundService.kt`, unified telemetry envelope —
see "Telemetry envelope" below) that had to land before the allowlist work,
since both touch the same cloud-client code.

When the coworker finally sent the real endpoint, it wasn't a bare game list —
it was a full treatment/prescription record:

```
GET http://200.13.5.19:3000/patients/treatment/by-device-token/:deviceToken
```
```json
{
  "id": 4, "title": "tratamiento de ortesis", "description": "...",
  "start_date": "2026-03-15", "end_date": "2026-03-31", "status": "active",
  "usage_time": 7200, "patient_usage_time": 0,
  "enabled_games": ["donut", "flappy bob"]
}
```

## Decision

Built a `TreatmentService` (`lib/services/treatment/treatment_service.dart`) —
this is the "game-allowlist" work the roadmap anticipated, but scoped to the
actual endpoint shape rather than the originally-guessed bare game list. It:

- Fetches from `.19` (confirmed by owner: same device-token value as
  ThingsBoard's `.20` — **resolves the ADR-0008 host-split open question for
  this read path**; `.20` still owns telemetry push).
- Read-only, polls (bootstrap + app-resume, throttled to 15 min) — no
  write-back endpoint exists or is assumed.
- Caches the last successful fetch to `SharedPreferences` for offline/cold-start.
- Maps the backend's display-name vocabulary (`"flappy bob"`, `"block
  breaker"`, etc. — confirmed by coworker as the full set, alongside `"donut"`,
  `"orchestra"`) to internal game ids via a hardcoded table — names don't
  match 1:1.
- Encodes a fail-open/fail-closed policy in one place
  (`effectiveEnabledGameIds`), decided explicitly with the owner rather than
  assumed:
  - **Fail-open** (show every game) on: no data yet, network error, no device
    token, or an empty/fully-unrecognized `enabled_games` list. None of these
    are a clinical signal — don't let a technical hiccup block therapy access.
  - **Fail-closed** (show no games) when `status` is present and not
    `"active"` — this *is* a clinical signal, the professional's system
    positively saying the treatment isn't active right now.
- `GameMenu` (`lib/screens/widgets/menus/game_menu.dart`) **hides** non-
  prescribed games entirely rather than showing them greyed out (owner's
  call — simpler, matches "filter which games are selectable" literally).

**Confirmed by owner post-implementation** (were open questions during
planning, now settled):
- `usage_time` / `patient_usage_time` are **daily**, in **seconds** (not a
  whole-treatment-window total). `TreatmentOverlay`'s progress display and
  code comments were updated to say "today" rather than staying neutral.
- The `:deviceToken` path segment is the same value as the ThingsBoard device
  token already stored under the `cloud_device_token` SharedPreferences key.

### Telemetry envelope (separate but adjacent decision, same session)

While hardening the cloud path for the usage-undercount bug, the two
independent cloud clients — native `CloudManager.kt` and Dart
`cloud_service.dart` — were unified onto one JSON envelope:

```json
{"eventType": "sync_status", "timestamp": 1751462400000, "payload": {...}}
```

**This does not merge event types.** `sync_status` and `mission_completed`
(and `minigame_played`) remain separate events, each sent as its own POST —
only the *wrapper shape* both clients produce is now consistent (previously
native sent a flat `{eventType: payload}` while Dart sent a ThingsBoard-shaped
`{ts, values: {telemetry: "<json-string>"}}` with special-cased key names).
See `docs/telemetria.md` / `docs/en/telemetry.md` for the current wire format.
The redundant Dart-side `sync_session` event (a third, less reliable usage
tracker) was deleted — native `sync_status` is now the sole usage-truth.

## Consequences

### Positive
- ADR-0008's "push-only" gap is closed for exactly one read path, without
  making the whole cloud integration bidirectional — telemetry stays push-only,
  the treatment fetch is a narrow, well-scoped addition.
- Fail-open/fail-closed policy is centralized and explicit, not scattered
  ad-hoc checks — easy to audit, easy to extend when the mission system is
  revisited (see below).
- Allow-list is cached offline (`ROADMAP.md` Phase 3 acceptance criterion met).

### Negative / trade-offs
- Naming diverges from what `ROADMAP.md` originally sketched
  (`GameAllowlistService`/`AllowedGames`/`fetchAllowedGames`) — the actual
  code is `TreatmentService`/`Treatment`/`effectiveEnabledGameIds`, because the
  real endpoint returns much more than a game list. Anyone searching the
  roadmap's exact names won't find them; **this ADR is the bridge.**
- `GameMenu`'s filter is read once when the menu dialog opens, not reactive —
  if a resume-triggered refresh changes the treatment while the menu is
  already open, it won't update until the menu is reopened. Accepted: the menu
  is a short-lived dialog, treatments don't change second-to-second.
- No write-back path exists for `patient_usage_time` — it's assumed the
  backend derives it from the `sync_status` telemetry already being sent.
  **Unconfirmed.** If wrong, the progress bar in `TreatmentOverlay` will show
  server-side data that never moves regardless of app usage.
- Native `MissionManager.kt`'s headless scaffold (dead — see GitHub #32) is
  NOT wired to this treatment data. Treatment-progress display only works
  while the app is in the foreground. Feeding it into the headless native
  path (so progress tracking, not just telemetry, survives the app being
  closed) is deferred — tracked in GitHub #32.

### Open / unknown (carried forward)
- Whether `patient_usage_time` is truly server-derived from telemetry, or
  needs an explicit push — no write-back endpoint has been given. If the
  progress bar looks frozen relative to real usage, this is the first thing
  to check with the coworker.
- Real-device/emulator verification of the HUD overlay and menu filtering
  hasn't happened yet — implementation was verified via unit tests
  (`test/treatment_service_test.dart`) against the coworker's exact sample
  payload, plus a mock-HTTP-server request-shape check, not an on-device run.

## Alternatives considered

- **Wait for a formal `GameAllowlistService` design before touching anything**
  — rejected; the coworker's endpoint was already in hand and "he can adapt to
  whatever," so building against the real shape now was lower-risk than
  guessing further and reworking later.
- **Show non-prescribed games greyed-out with a "not in your plan" message**
  — rejected in favor of hiding entirely; owner's call, simpler and matches
  the roadmap's literal framing. Revisit if patients find silently-missing
  games confusing.

## References

- `lib/services/treatment/treatment_service.dart`, `treatment_overlay.dart`
- `lib/screens/widgets/menus/game_menu.dart`, `game_screen.dart`
- `test/treatment_service_test.dart`
- Related: [[ADR-0008]] (revised by this ADR for the read path), [[ADR-0007]]
  (truthful telemetry — same honesty principle applied to fail-open/closed)
- GitHub #30 (`pet_stats_bundle` dual-write), #31 (battery-opt exemption
  follow-up), #32 (revive `MissionManager.kt` for headless treatment tracking)
- `ROADMAP.md` Phase 3
