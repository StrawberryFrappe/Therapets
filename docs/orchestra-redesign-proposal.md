# Orchestra Minigame — Redesign (chosen direction + build plan)

Status: **design agreed with owner (2026-07-12).** Branch `feat/orchestra-simplify`
off `unstable`. This document is the spec; the two pure signal modules are built
and tested; game/UI integration is deliberately left for a supervised session.

The old interaction (a 2-axis continuous tilt-theremin, one-shot calibration)
"went horrible". Owner constraints:
- Must feel like an **instrument**, not a rhythm/taiko game.
- Driven by **arm movement**. Tilt is vetoed ("we already have a game with tilt");
  binary shake is already Flappy Bird's mechanic.

---

## 1. The instrument — theremin-choir

The choir is silent until you move.

- **Horizontal swing = play + dynamics.** Sweep the arm side-to-side to sound the
  choir; harder swing = louder. The swing *sounds* the note, it does not pick it.
- **Arm height = pitch.** Raise/lower the arm to change pitch — continuous,
  bendable mid-swing (portamento). Pitch **soft-snaps** toward the nearest scale
  note so small wobble/drift stays in tune.
- **Pitch lock (screen, toggle).** Freeze the current note; altitude is ignored
  until you unlock. Play a steady note while focusing on the swing.
- **Calibrate button.** Hold the arm at your "neutral" pose and press; that sets
  the zero reference. Re-press anytime to kill accumulated drift.
- **Cube feedback.** Render a cube whose altitude = the height estimate. It shows
  where your pitch sits *and* doubles as a drift gauge — if it floats while you
  hold still, you can see it and recalibrate.

Pitch and volume are genuinely independent signals: pitch from *elevation*
(low-frequency), volume from the *swing* (higher-frequency horizontal
oscillation). A hard swing is loud but not high; raising the arm is high but
silent until you swing.

---

## 2. Height sensing — two sensors fused into one number

A single accelerometer cannot give robust absolute height. We fuse two signals:

- **Integrated linear acceleration → vertical displacement.** Truthful and
  responsive for fast moves, but **drifts**.
- **Attitude from the gravity vector (+ gyro).** **Drift-free**, but only a proxy
  for height (fooled by pure translation without rotation).

`HeightMode.fused` complementary-blends them: fast motion from integration, slow
drift-correction toward the angle anchor. Drift is bounded by four things:
1. **ZUPT** (zero-velocity updates) — velocity is snapped to 0 whenever the arm is
   near-rest; the pauses at each swing turnaround provide these resets for free.
2. **Calibrate button** — hard manual reset.
3. **Soft-snap to scale** — hides sub-note drift (a drift smaller than half a step
   resolves to the right note anyway).
4. **Velocity leak** — bleeds off integration error between rests.

**Sensor note:** the device *has a gyroscope* — `TelemetryData.gx/gy/gz` (deg/s),
currently unused by the game. The fusion needs it (attitude + rest detection).

**Advanced Setting — height mode:** `fused` (default) / `angleOnly` (robust,
drift-free, less "true") / `heightOnly` (truest, driftiest — mostly a diagnostic).
`angleOnly` is the safe fallback if fused proves noisy on device.

**Honest limits (validate on device):**
- The angle channel really tracks arm *angle*; it reads a pure vertical lift that
  doesn't rotate the wrist only weakly. Fusion leans on angle because it's the
  drift-free half.
- Vertical dead-reckoning (the `heightOnly` half) is intrinsically weak once ZUPT
  is aggressive — it accrues little displacement from realistic moves. Expected;
  it's why fused/angle carry the instrument.
- Wrist rotation *during* a swing pollutes the vertical/horizontal split. Assumes a
  roughly steady wrist; recalibrate fixes it.
- `TelemetryData.fromBytes` drops any packet with accel magnitude > 10g
  (`telemetry_data.dart:67`). A very hard swing could clip → dropout. Likely relax
  this for the game (out of scope here — flag).

---

## 3. Scale system (data-driven)

A scale is just a set of allowed semitone offsets, so swapping is config, not code.

**Scale primer (the thing your teacher didn't lie about):**
- An **octave** = 12 semitones; note names repeat one octave up.
- **Diatonic** (major) = the 7-note do-re-mi-fa-sol-la-ti. Most songs live here.
  Downside for us: 7 notes/octave = thin height-slice per note + two half-steps
  that clash if you're slightly off.
- **Pentatonic** = 5 notes/octave — the diatonic set minus its two "trap" tones
  (the 4th and 7th). Property: **any notes played together sound consonant** — you
  can't hit a sour note. Fatter slice per note → drift-tolerant.
- **Chromatic** = all 12. This is where **sharps/flats (♯/♭)** live — they're the
  5 pitches between the diatonic 7 that fill the octave.

**Config (all owner-requested):**
- **Scale**: pentatonic ⇄ diatonic ⇄ chromatic, swappable.
- **Octave-shift**: slide the mapped window up/down in whole octaves (in-game
  range selector).
- **Span size**: how many octaves the arm sweep covers (adjustable — more octaves =
  more reach but thinner per-note slice).
- **Snap strength**: 0 = continuous theremin, 1 = hard snap; default ~0.85 soft.

**Default:** major pentatonic, ~2 octaves across the arm, octave-shift to reach the
rest. Multi-octave without cramming precision.

---

## 4. Controls summary

| Control | Where | Signal |
|---------|-------|--------|
| Sound + volume | arm | horizontal swing energy (band-passed) |
| Pitch | arm | fused arm-height → soft-snapped scale note |
| Pitch lock | in-game, toggle | freeze pitch, ignore height |
| Calibrate | in-game button | set neutral pose, zero drift |
| Scale / span size / octave-shift | in-game range selector | `MusicScale` config |
| Height mode (fused/angle/height) | Advanced Settings | `HeightEstimator.mode`, persisted |

---

## 5. Build plan (phased)

**Phase 0 — pure signal core  ✅ DONE (this branch, tested)**
- `lib/game/minigames/orchestra/music_scale.dart` — height→pitch mapping,
  scales, octave window, span, soft-snap. 9 unit tests.
- `lib/game/minigames/orchestra/height_estimator.dart` — accel+gyro fusion, 3
  modes, calibrate, ZUPT. 8 invariant tests (drift-bounding, calibration, per-mode).
- No game/UI touched. Filter tunables are first-cut, marked for on-device tuning.

**Phase 1 — swing/dynamics layer** (next; needs the game loop)
- Band-pass horizontal accel → swing energy → gate + volume. Feed `TonePlayer`.
- Decide sustain model (steady swing = steady note).

**Phase 2 — wire pitch into the game**
- Replace `OrchestraGame._onTelemetry` tilt mapping with
  `HeightEstimator` → `MusicScale` → frequency. Remove the old dual-axis tilt code.
- Render the altitude **cube** + nearest-note marker.

**Phase 3 — in-game controls**
- Pitch-lock toggle, calibrate button, range selector (scale / span / octave-shift).

**Phase 4 — Advanced Settings + persistence**
- Height-mode toggle (fused/angle/height) in Advanced Settings, persisted in
  `GameSettings` via SharedPreferences JSON (Hive forbidden). Add a persistence test.

**Phase 5 — on-device tuning**
- Tune the estimator constants (gravityAlpha, restThresholds, complementaryK,
  ranges) against the real sensor. Consider relaxing the 10g packet filter for the
  game. Confirm the `angleOnly` fallback path.

Each phase: `flutter test` + `flutter analyze` green before commit; game/UI phases
verified in-app before "done".

---

## 6. Out of scope / noticed (not this redesign)
- `tone_player.dart:83-105` regenerates the WAV buffer every `startTone`; cache it once.
- `pet_musician.dart:128` animates from `DateTime.now()` in `render` instead of
  accumulated `dt` — wall-clock rather than frame-based wobble.
