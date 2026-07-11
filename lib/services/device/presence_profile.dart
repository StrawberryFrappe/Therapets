/// Tunable thresholds for human-presence detection that depend on whether the
/// connected device firmware duty-cycles its sensors.
///
/// Old firmware ran the bio sensor 10s ON / 10s OFF (zeroing IR/Red while OFF),
/// so the app needed wide grace windows, history voting and long freshness
/// bridges to avoid dropping "synced" during the periodic blackouts. New
/// firmware keeps the sensors always on, so those duty-cycle-shaped cushions
/// are removed and presence reacts in near real time.
///
/// Only the duty-cycle-specific knobs live here. Genuine sensor-quality
/// safeguards (spike protection, finger hysteresis, sustained-sample checks,
/// physiological ranges, anti-freeze flush, BLE-disconnect freeze) are kept
/// unconditionally in the processors/aggregator and are NOT gated by this.
class PresenceProfile {
  /// How long to hold the last-known-good state after human detection flips
  /// false, before dropping sync. Bridges sensor blackouts in lenient mode.
  final Duration graceWindow;

  /// Consecutive "no human" history samples (1 Hz) required before the grace
  /// window starts. Higher = more tolerant of momentary dropouts.
  final int noHumanDebounce;

  /// Fraction of the recent history window that must be "human present" for the
  /// device to read as synced (history "barrage" vote). `null` disables the
  /// vote entirely and keys sync off the live reading — used for always-on
  /// firmware where the history would otherwise stay 100% true off-body.
  final double? barrageRatio;

  /// How long a cached reading is considered fresh enough to display during a
  /// transmission pause.
  final Duration freshnessTimeout;

  /// Whether an all-zero sensor frame means "human absent right now" (always-on
  /// firmware) rather than a benign sleep blackout to be ignored (duty-cycle).
  final bool zeroMeansAbsent;

  /// Old battery-saving firmware: wide cushions tuned for the 10s/10s cycle.
  /// Values match the historical hard-coded constants exactly.
  const PresenceProfile.dutyCycle()
      : graceWindow = const Duration(seconds: 15),
        noHumanDebounce = 15,
        barrageRatio = 0.33,
        freshnessTimeout = const Duration(seconds: 60),
        zeroMeansAbsent = false;

  /// New always-on firmware: small cushion only (sensors are still low quality,
  /// so a brief debounce/grace remains — just no duty-cycle-sized windows).
  const PresenceProfile.alwaysOn()
      : graceWindow = const Duration(seconds: 2),
        noHumanDebounce = 2,
        barrageRatio = null,
        freshnessTimeout = const Duration(seconds: 5),
        zeroMeansAbsent = true;
}
