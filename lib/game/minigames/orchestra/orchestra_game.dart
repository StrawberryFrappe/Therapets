import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
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
    rootMidi: 48, // C3
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

    add(TitleDisplay(game: this));
    add(StatusHint(game: this));
    add(ExitButton(onTap: _handleExit, game: this));
    _addControls();

    if (isDeviceConnected) {
      _telemetrySub = deviceService.telemetry$.listen(
        _onTelemetry,
        onError: (e) => print('[Orchestra] Telemetry error: $e'),
      );
      deviceService.requestNativeStatus();
    }
  }

  void _addControls() {
    // A row of tap controls along the bottom of the stage.
    const w = 76.0;
    const h = 34.0;
    const gap = 6.0;
    final y = size.y - h - 8;
    var x = 8.0;
    void place(String Function() label, VoidCallback onPressed) {
      add(LabelButton(
        label: label,
        onPressed: onPressed,
        position: Vector2(x, y),
        size: Vector2(w, h),
      ));
      x += w + gap;
    }

    place(() => 'CALIB', _height.calibrate);
    place(() => _pitchLocked ? 'LOCKED' : 'LOCK', _toggleLock);
    place(() => _scaleLabel, _cycleScale);
    place(() => 'OCT-', () => _shiftOctave(-1));
    place(() => 'OCT+', () => _shiftOctave(1));
    place(() => _spanLabel, _cycleSpan);
  }

  // --- Control actions ---

  void _toggleLock() {
    // Only meaningful once we have a real gesture-derived pitch.
    if (!_height.isCalibrated) return;
    _pitchLocked = !_pitchLocked;
    if (_pitchLocked) _lockedFrequency = _targetFrequency;
  }

  // Audible MIDI band = TonePlayer's rate-bounded frequency range
  // (110 Hz ≈ MIDI 45, 1760 Hz = MIDI 93). Notes outside this get rate-clamped
  // to one pitch, so we never let a control combo push notes past it.
  static const int _bandMinMidi = 45;
  static const int _bandMaxMidi = 93;

  void _cycleScale() {
    const values = ScaleType.values;
    _scale.scale = values[(values.indexOf(_scale.scale) + 1) % values.length];
  }

  void _shiftOctave(int delta) {
    _scale.octaveShift += delta;
    _clampRangeToBand();
  }

  void _cycleSpan() {
    _scale.spanOctaves = _scale.spanOctaves >= 3 ? 1 : _scale.spanOctaves + 1;
    _clampRangeToBand();
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

  String get _scaleLabel {
    switch (_scale.scale) {
      case ScaleType.pentatonic:
        return 'PENTA';
      case ScaleType.diatonic:
        return 'DIA';
      case ScaleType.chromatic:
        return 'CHROM';
    }
  }

  String get _spanLabel => '${_scale.spanOctaves.toInt()}OCT';

  /// A hint shown when the instrument can't be played yet, else null.
  String? get statusHint {
    if (!isDeviceConnected) return 'Connect a device in Settings to play';
    if (_telemetryStale) return 'Signal lost — reconnect the device';
    if (!_height.isCalibrated) return 'Hold still — calibrating…';
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

  void _handleExit() {
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
      final ageMs = DateTime.now().difference(_lastSample!).inMilliseconds;
      _telemetryStale = ageMs > 400;
      if (_telemetryStale) _currentVolume = 0.0;
    }
    // Glide the sounded pitch toward the target (portamento; also smooths the
    // discrete jumps at scale-snap boundaries).
    final t = (dt * 12.0).clamp(0.0, 1.0);
    _currentFrequency += (_targetFrequency - _currentFrequency) * t;
    _updateAudio();
  }

  /// Clean up all audio and subscriptions. Idempotent — it is called both from
  /// the in-game EXIT button and from the screen's dispose().
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
  }

  @override
  void onRemove() {
    cleanup();
    super.onRemove();
  }
}

/// Title display
class TitleDisplay extends PositionComponent {
  final OrchestraGame game;

  TitleDisplay({required this.game}) : super(position: Vector2(0, 20));

  @override
  void render(Canvas canvas) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '🎵 Pet Orchestra 🎵',
        style: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: 'Monocraft',
          shadows: [Shadow(offset: Offset(2, 2), blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((game.size.x - textPainter.width) / 2, 0));
  }
}

/// Centered hint shown while the instrument can't be played (no device yet,
/// or still calibrating). Renders nothing once playable.
class StatusHint extends PositionComponent {
  final OrchestraGame game;

  StatusHint({required this.game});

  @override
  void render(Canvas canvas) {
    final hint = game.statusHint;
    if (hint == null) return;
    final tp = TextPainter(
      text: TextSpan(
        text: hint,
        style: const TextStyle(
          color: Color(0xFFFFE082),
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Monocraft',
          shadows: [Shadow(offset: Offset(1, 1), blurRadius: 3)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset((game.size.x - tp.width) / 2, game.size.y * 0.28),
    );
  }
}

/// A small tap button rendering a dynamic label.
class LabelButton extends PositionComponent with TapCallbacks {
  final String Function() label;
  final VoidCallback onPressed;
  final Color color;

  LabelButton({
    required this.label,
    required this.onPressed,
    this.color = const Color(0xFF5C6BC0),
    Vector2? position,
    Vector2? size,
  }) : super(position: position, size: size ?? Vector2(76, 34));

  @override
  void render(Canvas canvas) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(6),
    );
    canvas.drawRRect(rrect, Paint()..color = color);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: label(),
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'Monocraft',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset((size.x - tp.width) / 2, (size.y - tp.height) / 2));
  }

  @override
  void onTapUp(TapUpEvent event) => onPressed();
}

/// Exit button component
class ExitButton extends PositionComponent with TapCallbacks {
  final VoidCallback onTap;
  final OrchestraGame game;

  ExitButton({required this.onTap, required this.game})
      : super(size: Vector2(80, 40), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = Vector2(60, 50);
  }

  @override
  void render(Canvas canvas) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(8),
    );
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFFE57373));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'EXIT',
        style: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Monocraft',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size.x - textPainter.width) / 2, (size.y - textPainter.height) / 2),
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    onTap();
  }
}
