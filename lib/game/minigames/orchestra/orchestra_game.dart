import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../../services/device/device_service.dart';

import '../../game_settings.dart';
import '../../pets/pet_stats.dart';
import 'cursor.dart';
import 'height_estimator.dart';
import 'music_scale.dart';
import 'pet_musician.dart';
import 'tone_player.dart';

/// Orchestra minigame — a "theremin-choir" played by arm movement.
/// - Horizontal swing sounds the choir and sets its volume (harder = louder).
/// - Arm height sets the pitch, soft-snapped to a musical scale.
/// - Pitch-lock freezes the note; Calibrate sets the neutral pose.
/// Height comes from [HeightEstimator] (accel+gyro fusion); pitch from
/// [MusicScale]. See docs/orchestra-redesign-proposal.md.
class OrchestraGame extends FlameGame {
  final DeviceService deviceService;
  final PetStats petStats;
  final VoidCallback onExit;
  final bool isDeviceConnected;

  // Musicians
  final List<PetMusician> _musicians = [];

  // Audio
  final TonePlayer _mainPlayer = TonePlayer();

  // Visual pitch indicator
  late MotionCursor _cursor;
  StreamSubscription<TelemetryData>? _telemetrySub;

  // Input model
  final HeightEstimator _height = HeightEstimator();
  final MusicScale _scale = MusicScale(
    scale: ScaleType.pentatonic,
    rootMidi: 57, // A3 — centered in the audible band so OCT-/OCT+ both work
    spanOctaves: 2,
    snapStrength: 0.85,
  );

  // Derived state
  double _currentFrequency = 220.0; // smoothed (glide) frequency actually sounded
  double _targetFrequency = 220.0; // raw target from height/lock
  double _currentPitchNorm = 0.5;
  double _currentVolume = 0.0;

  // Audio gate + change detection (avoid per-frame platform-channel spam)
  bool _gateOpen = false;
  double _lastSentFreq = -1;
  double _lastSentVol = -1;
  bool _cleanedUp = false;

  // Pitch lock
  bool _pitchLocked = false;
  double _lockedFrequency = 220.0;

  // Pitch band = exactly what TonePlayer can sound, so the note shown matches
  // what's heard (no silent second clamp collapsing distinct notes to one).
  double get _minFreq => TonePlayer.minFrequency;
  double get _maxFreq => TonePlayer.maxFrequency;

  // Sample timing for the estimator.
  DateTime? _lastSample;
  // Consecutive near-still samples before the first auto-calibration, so the
  // gravity baseline settles on a genuinely neutral pose.
  int _stillSamples = 0;
  // True when telemetry has gone quiet mid-play (BLE dropped) — stops the drone.
  bool _telemetryStale = false;

  // Bumped only on discrete UI-relevant state changes (calibrate, lock toggle,
  // scale/octave/span change, status hint change) — the Flutter overlay
  // listens to this instead of rebuilding every frame.
  final ValueNotifier<int> uiRevision = ValueNotifier(0);
  void _notifyUi() => uiRevision.value++;

  OrchestraGame({
    required this.deviceService,
    required this.petStats,
    required this.onExit,
    this.isDeviceConnected = false,
  });

  @override
  Color backgroundColor() => const Color(0xFF2D1B4E); // Deep purple stage

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _height.mode = GameSettings.orchestraHeightMode;
    _clampRangeToBand();

    _setupChorus();

    _cursor = MotionCursor(position: size / 2);
    add(_cursor);

    if (isDeviceConnected) {
      _telemetrySub = deviceService.telemetry$.listen(
        _onTelemetry,
        onError: (e) {
          print('[Orchestra] Telemetry error: $e');
          _markTelemetryStale();
        },
        onDone: _markTelemetryStale,
      );
      deviceService.requestNativeStatus();
    }
  }

  // Force the "signal lost" state and tell the overlay immediately, rather
  // than waiting on the per-frame watchdog in [update] — used when the
  // telemetry stream itself ends/errors (not just goes quiet mid-sample).
  void _markTelemetryStale() {
    _telemetryStale = true;
    _currentVolume = 0.0;
    _notifyUi();
  }

  // --- Control actions (called from the Flutter overlay in orchestra_screen.dart) ---

  /// True once the instrument has a real neutral pose and can be played.
  bool get isCalibrated => _height.isCalibrated;

  /// True while the pitch is frozen on [_lockedFrequency].
  bool get pitchLocked => _pitchLocked;

  void calibrate() {
    _height.calibrate();
    _notifyUi();
  }

  void toggleLock() {
    // Only meaningful once we have a real gesture-derived pitch.
    if (!_height.isCalibrated) return;
    _pitchLocked = !_pitchLocked;
    if (_pitchLocked) _lockedFrequency = _targetFrequency;
    _notifyUi();
  }

  // Audible MIDI band = TonePlayer's rate-bounded frequency range
  // (110 Hz ≈ MIDI 45, 1760 Hz = MIDI 93). Notes outside this get rate-clamped
  // to one pitch, so we never let a control combo push notes past it.
  static const int _bandMinMidi = 45;
  static const int _bandMaxMidi = 93;

  void cycleScale() {
    const values = ScaleType.values;
    _scale.scale = values[(values.indexOf(_scale.scale) + 1) % values.length];
    _notifyUi();
  }

  void shiftOctave(int delta) {
    _scale.octaveShift += delta;
    _clampRangeToBand();
    _notifyUi();
  }

  void cycleSpan() {
    _scale.spanOctaves = _scale.spanOctaves >= 3 ? 1 : _scale.spanOctaves + 1;
    _clampRangeToBand();
    _notifyUi();
  }

  // Clamp octaveShift so BOTH ends of the mapped range —
  // [effectiveRoot, effectiveRoot + spanOctaves*12] — stay in the audible band,
  // jointly with the current span (independent clamps let the combo escape).
  void _clampRangeToBand() {
    final span = _scale.spanOctaves.toInt();
    final lo = ((_bandMinMidi - _scale.rootMidi) / 12).ceil();
    final hi = ((_bandMaxMidi - _scale.rootMidi) / 12).floor() - span;
    _scale.octaveShift = _scale.octaveShift.clamp(lo, hi < lo ? lo : hi).toInt();
  }

  ScaleType get scaleType => _scale.scale;
  int get spanOctaves => _scale.spanOctaves.toInt();

  /// Which of the three status hints applies right now, else null when the
  /// instrument is fully playable. The overlay maps this to a localized
  /// string — no English baked in here.
  OrchestraStatus? get status {
    if (!isDeviceConnected) return OrchestraStatus.noDevice;
    if (_telemetryStale) return OrchestraStatus.signalLost;
    if (!_height.isCalibrated) return OrchestraStatus.calibrating;
    return null;
  }

  void _setupChorus() {
    _createRow(count: 6, yPos: size.y * 0.40, scale: 0.6, minPitch: 0.0, maxPitch: 0.4);
    _createRow(count: 5, yPos: size.y * 0.58, scale: 0.8, minPitch: 0.3, maxPitch: 0.7);
    _createRow(count: 4, yPos: size.y * 0.76, scale: 1.0, minPitch: 0.6, maxPitch: 1.0);
    addAll(_musicians);
  }

  void _createRow({
    required int count,
    required double yPos,
    required double scale,
    required double minPitch,
    required double maxPitch,
  }) {
    final rowWidth = size.x * 0.8;
    final spacing = rowWidth / (count + 1);
    final startX = (size.x - rowWidth) / 2 + spacing;

    for (int i = 0; i < count; i++) {
      final rowRange = maxPitch - minPitch;
      final petPitchCenter = minPitch + (rowRange * (i / (count - 1)));
      final petMin = (petPitchCenter - 0.15).clamp(0.0, 1.0);
      final petMax = (petPitchCenter + 0.15).clamp(0.0, 1.0);

      _musicians.add(PetMusician(
        petStats: petStats,
        pitch: petPitchCenter,
        minPitchRange: petMin,
        maxPitchRange: petMax,
        position: Vector2(startX + (spacing * i), yPos),
        size: Vector2(100, 116) * scale,
      ));
    }
  }

  /// Called by the overlay's Exit button.
  void exitGame() {
    cleanup();
    onExit();
  }

  // --- AUDIO ---

  void _updateAudio() {
    // Hysteresis so a swing envelope hovering near the threshold doesn't
    // chatter the tone on/off.
    final shouldPlay = _gateOpen ? _currentVolume > 0.03 : _currentVolume > 0.06;

    if (!shouldPlay) {
      if (_gateOpen) {
        _mainPlayer.stopTone();
        _gateOpen = false;
      }
    } else if (!_gateOpen) {
      _mainPlayer.startTone(_currentFrequency, _currentVolume);
      _gateOpen = true;
      _lastSentFreq = _currentFrequency;
      _lastSentVol = _currentVolume;
    } else if ((_currentFrequency - _lastSentFreq).abs() > 0.5 ||
        (_currentVolume - _lastSentVol).abs() > 0.01) {
      // Only cross the platform channel when something actually changed.
      _mainPlayer.setFrequency(_currentFrequency, _currentVolume);
      _lastSentFreq = _currentFrequency;
      _lastSentVol = _currentVolume;
    }

    for (final musician in _musicians) {
      musician.updateSingingState(_currentPitchNorm, _currentVolume);
    }
  }

  // --- INPUT ---

  void _onTelemetry(TelemetryData data) {
    final now = DateTime.now();
    final dt = _lastSample == null
        ? 0.02
        : (now.difference(_lastSample!).inMicroseconds / 1e6).clamp(0.001, 0.1);
    _lastSample = now;

    _height.update(data, dt);
    // Auto-calibrate once the arm has been reasonably still for a moment, so the
    // neutral pose isn't captured mid-motion. The CALIB button re-zeros later.
    if (!_height.isCalibrated) {
      // Require low rotation AND a plausible ~1g reading, so a garbage/zero
      // packet can't seed a bad neutral pose.
      final gyroStill = data.gx.abs() + data.gy.abs() + data.gz.abs() < 45;
      final gravitySane = data.magnitude > 0.5 && data.magnitude < 2.0;
      _stillSamples = (gyroStill && gravitySane) ? _stillSamples + 1 : 0;
      if (_stillSamples < 15) return;
      _height.calibrate();
      _notifyUi();
      return;
    }

    final h = _height.height;
    _currentPitchNorm = h;
    final freq = _pitchLocked ? _lockedFrequency : _scale.map(h).frequency;
    _targetFrequency = freq.clamp(_minFreq, _maxFreq);
    _currentVolume = _height.swingEnergy;

    // Vertical pitch indicator: high pitch = top of screen.
    _cursor.position = Vector2(size.x / 2, (1.0 - h) * size.y);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Watchdog: if telemetry has gone quiet (BLE dropped mid-play), stop the
    // note draining out — otherwise the last frame's volume drones forever.
    if (_lastSample != null) {
      final wasStale = _telemetryStale;
      final ageMs = DateTime.now().difference(_lastSample!).inMilliseconds;
      _telemetryStale = ageMs > 400;
      if (_telemetryStale) _currentVolume = 0.0;
      if (_telemetryStale != wasStale) _notifyUi();
    }
    // Glide the sounded pitch toward the target (portamento; also smooths the
    // discrete jumps at scale-snap boundaries).
    final t = (dt * 12.0).clamp(0.0, 1.0);
    _currentFrequency += (_targetFrequency - _currentFrequency) * t;
    _updateAudio();
  }

  /// Clean up all audio and subscriptions. Idempotent — it is called both from
  /// [exitGame] and from the screen's dispose().
  void cleanup() {
    if (_cleanedUp) return;
    _cleanedUp = true;
    _mainPlayer.stopTone();
    _mainPlayer.dispose();
    for (final musician in _musicians) {
      musician.stopSinging();
    }
    _telemetrySub?.cancel();
    _telemetrySub = null;
    uiRevision.dispose();
  }

  @override
  void onRemove() {
    cleanup();
    super.onRemove();
  }
}

/// Why the instrument can't be played yet, if at all. The Flutter overlay
/// (`orchestra_screen.dart`) maps each value to a localized string.
enum OrchestraStatus { noDevice, signalLost, calibrating }
