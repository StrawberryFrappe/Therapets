# BLE Robustness Pass — Handoff

Branch: `feat/ble-robustness-pass` (off `unstable`). Not pushed. No PR.
Scope lock: BLE scan / connect / reconnect path only. No hardware verification was
possible — this doc is the on-device checklist for the owner.

Gates at handoff: `flutter analyze` clean, `flutter test` = 57/57 pass.

---

## What changed and why

### 1. "Scan failed. Tap scan to retry" on a fresh scan
**File:** `lib/services/device/bluetooth_service.dart` — `startScan()`

Root cause: the service never called `FlutterBluePlus.stopScan()` before starting.
`flutter_blue_plus` throws *"Another scan is already in progress"* if a prior scan
is still active at the plugin level (e.g. a scanner dialog was closed without a clean
stop, or a previous scan errored mid-flight leaving the plugin scanning). That throw
was caught and surfaced to the user as `ScanStatus.error` → "Scan failed."

Fix: best-effort `await FlutterBluePlus.stopScan()` immediately before `startScan()`
to clear any lingering plugin-level scan. No-op when nothing is scanning.

### 2. Failed scan burned the 5s debounce → tap-to-retry silently swallowed
**File:** `lib/services/device/bluetooth_service.dart` — `startScan()`

Root cause: `_lastScanStart = now` was set *before* the Bluetooth/permission check
and before the actual scan started. So a start that never happened (BT off, perms
denied, plugin throw) still armed the 5-second debounce. The user grants the
permission, taps scan again within 5s, and `startScan()` early-returns silently.

Fix: the debounce timestamp is now set only *after* `FlutterBluePlus.startScan()`
succeeds. A failed start no longer blocks the next retry.

### 3. No way to rescan — dialog was single-shot
**File:** `lib/screens/settings/widgets/bluetooth_scanner_dialog.dart`

Root cause: `_scanning` was set true on open and never reset. The status text told
the user to "scan again" but there was no button, and the stuck flag made
`_startScan()` early-return anyway. If the initial 7s scan missed the sensor, the
user was stranded on "No devices found" until they closed and reopened the dialog.

Fix: the whole empty-list area is now a tappable rescan button (`Material` + `InkWell`,
ripple feedback, "Tap anywhere to scan again" hint). Tap calls `_rescan()` which
force-resets `_scanning` and restarts. Disabled only while a scan is actively running.

### 4. Reconnect backoff overflowed after ~31 failed attempts → tight loop
**File:** `android/.../BleForegroundService.kt` — `scheduleFallbackReconnect()`

Root cause: `1 shl reconnectAttempts`. Kotlin's `shl` masks the shift count to 5 bits,
so `1 shl 31` is negative and larger counts wrap. Unbounded, after ~31 consecutive
failed reconnects the computed delay goes negative, `postDelayed()` fires immediately,
and the service spins a tight scan/reconnect loop that drains the battery. Reachable
on a long walk-away with the sensor powered off (~20 min of continuous failures).

Fix: clamp the exponent — `val exp = min(reconnectAttempts, 5)`. 2^5 already exceeds
the 30s ceiling, so backoff behaviour below the cap is unchanged; it just no longer
overflows. `reconnectAttempts` still resets to 0 on a successful connect.

---

## On-device verification checklist (owner, on the S3)

Do these on real hardware — none could be verified here.

**A. Scan reliability (fixes 1, 2, 3)**
- [ ] Open the scanner dialog cold (app fresh). Sensor powered on & nearby → it should
      list within a few seconds. Note **time-to-appear**.
- [ ] Close the dialog mid-scan, immediately reopen it. Should **not** show
      "Scan failed." (Was the "Another scan in progress" throw.) Repeat 3–4x fast.
- [ ] Let a scan run to empty (sensor off / far). Confirm the empty area now says
      "Tap anywhere to scan again" and **tapping it re-triggers a scan** with a visible
      ripple. Power the sensor on, tap to rescan → it should appear.
- [ ] Turn Bluetooth OFF, tap scan → "Bluetooth is off" message. Turn BT on, tap scan
      again **immediately** (within 5s) → it must actually scan, not silently do nothing.
- [ ] Deny BT permission, then grant it, then tap scan within 5s → must scan (debounce
      no longer eaten by the denied attempt).

**B. Connect (both sensor variants)**
- [ ] Connect to the **temperature** sensor variant → telemetry flows, notification
      shows "Connected".
- [ ] Forget, connect to the **pulse/PPG** sensor variant → BPM/SpO2 telemetry flows.
- [ ] Note: swapping directly temp↔pulse without forgetting may still need a 2nd try —
      see out-of-scope note below; not addressed here.

**C. Reconnect after walk-away (fix 4)**
- [ ] Connect, then walk out of range (or power the sensor off). Notification →
      "Disconnected". Walk back / power on → it should reconnect on its own.
- [ ] Leave the sensor off for **20–30 minutes** while connected-then-lost, then power
      it on. It must still reconnect promptly and must **not** have been hammering BLE
      the whole time (check battery/heat). This exercises the backoff-overflow fix.

---

## Proposals NOT implemented (risk / ambiguity — owner's call)

### P1. `disconnectGatt()` calls `stopSelf()` on the device-switch path — likely the
"needs a 2nd try" swap bug
`connectToDevice()` (BleForegroundService.kt ~L402) calls `disconnectGatt()` when a
GATT is already open, to tear down before connecting to a different device.
`disconnectGatt()` does `prefs.remove(PREF_SAVED_ID)`, `stopForeground(true)`,
`stopSelf()` — then `connectToDevice()` continues and re-saves the id and connects.
Racing `stopSelf()` against the fresh `connectGatt()` can kill the service mid-switch,
which matches the known "swap temp↔pulse needs a 2nd try" symptom. The normal
walk-away reconnect path does **not** hit this (it uses `g.close(); scheduleReconnect()`,
not `disconnectGatt()`), so it's specifically the switch case.
Why not fixed: this overlaps the deferred sticky-device-type bug that was explicitly
out of scope, and a correct fix (separate "disconnect to switch" from "disconnect to
stop") needs device testing to validate. Recommend: add a `stopService: Boolean = true`
param to `disconnectGatt()`, pass `false` from the switch path.

### P2. `_autoReconnect()` is an unbounded loop and ignores `forget()`
`bluetooth_service.dart` `_autoReconnect(id)` loops `while (_connected == null)` with
no attempt cap. It only runs when the native service is NOT running, but if the saved
device is gone forever it scans every ~12s indefinitely. Worse, `forget()` clears the
saved id but does not cancel an in-flight `_autoReconnect`, which keeps scanning for
the forgotten device (captured `id` param). Why not fixed: needs a cancellation token /
generation counter; low frequency (native path is the norm) so deferred to avoid churn
in the connect flow without hardware to test the cancel path.

### P3. `connect()` optimistically emits `connected=true`
`bluetooth_service.dart` `connect()` sets `_connected = device` and emits
`nativeConnected$ = true` before the native GATT actually connects; the immediate
`requestNativeStatus` usually still reports disconnected, so the UI can flicker
connected→disconnected→connected. Cosmetic; real status arrives via broadcast. Left
as-is to avoid changing perceived-latency behaviour without a device to A/B it.

---

## Out of scope — noticed, not touched
- Sticky `DeviceType` swap bug in `device_service.dart` (deferred per project memory).
  P1 above is the likely native-side contributor; both need the owner's decision.
- `isScanning` in the native service is read/written across the binder-thread
  `scanCallback` and the main-looper handler without synchronization. Theoretical
  visibility race; not observed to cause issues. Left alone.
