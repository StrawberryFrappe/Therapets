import 'dart:math' as math;

import '../../models/telemetry_data.dart';

/// Estimates a normalized arm "height" in [0, 1] (0.5 = calibrated neutral)
/// from IMU telemetry, for driving the Orchestra instrument's pitch.
///
/// Two sensors cooperate into one number (the "cube" altitude):
///  - integrated linear acceleration -> true vertical displacement: responsive
///    and truthful for fast moves, but drifts over time;
///  - device attitude from the gravity vector (+ gyro rest detection):
///    drift-free but only a proxy for height (fooled by pure translation).
///
/// [HeightMode.fused] complementary-blends them (fast motion from integration,
/// slow drift-correction toward the angle anchor). [angleOnly] and [heightOnly]
/// expose each sensor alone (robust vs. truest — surfaced as an Advanced Setting).
///
/// FIRST CUT: the filter shape is in place and the invariants are tested, but
/// the numeric tunables and the pitch-axis convention below assume a rough
/// wrist mounting and MUST be validated/tuned on device. `angleOnly` is the
/// robust fallback if fused proves too noisy in the field.
enum HeightMode { fused, angleOnly, heightOnly }

class HeightEstimator {
  HeightMode mode;

  // --- Tunables (device-tuning pending) ---
  /// Low-pass factor isolating the gravity vector from linear acceleration.
  final double gravityAlpha;

  /// Per-sample velocity leak; bounds integration drift between rest resets.
  final double velocityLeak;

  /// Per-sample displacement leak (applied only while moving); stops `_disp`
  /// growing without bound during continuous play that never fully rests.
  final double dispLeak;

  /// Complementary gain pulling the fused estimate toward the angle anchor.
  final double complementaryK;

  /// Below this linear-accel magnitude (g) AND [restGyroThresh], treat as rest.
  final double restAccelThresh;

  /// Below this gyro magnitude (deg/s) contributes to the rest condition.
  final double restGyroThresh;

  /// Elevation (rad) that maps to a full half-range of the angle estimate.
  final double angleRangeRad;

  /// Vertical displacement (m) that maps to a full half-range of integration.
  final double heightRangeMeters;

  /// Horizontal linear-accel magnitude (g) that maps to full swing energy.
  final double swingFullScaleG;

  /// Envelope rise/fall rates for the swing energy (rises fast, falls slow).
  final double swingAttack;
  final double swingRelease;

  HeightEstimator({
    this.mode = HeightMode.fused,
    this.gravityAlpha = 0.9,
    this.velocityLeak = 0.98,
    this.dispLeak = 0.999,
    this.complementaryK = 0.02,
    this.restAccelThresh = 0.08,
    this.restGyroThresh = 15.0,
    this.angleRangeRad = math.pi / 2,
    this.heightRangeMeters = 0.6,
    this.swingFullScaleG = 0.8,
    this.swingAttack = 0.3,
    this.swingRelease = 0.05,
  });

  // Gravity estimate (g), low-pass of accel.
  double _gravX = 0, _gravY = 0, _gravZ = 0;
  bool _gravInit = false;

  // Neutral reference captured at calibrate().
  bool _calibrated = false;
  double _neutralPitch = 0;
  double _upX = 0, _upY = 0, _upZ = -1; // world "up" unit = -neutralGravityUnit

  // Integration state.
  double _vel = 0; // vertical velocity (m/s)
  double _disp = 0; // vertical displacement vs neutral (m)
  double _fusedNorm = 0.5;
  double _swingEnv = 0; // smoothed horizontal-swing energy, 0..1

  bool get isCalibrated => _calibrated;
  double get displacementMeters => _disp;
  double get verticalVelocity => _vel;

  /// Horizontal-swing energy in [0, 1] — how vigorously the arm is sweeping.
  /// Drives the choir's volume/gate; independent of [height] (pitch).
  double get swingEnergy => _swingEnv;

  static const double _g = 9.80665;

  // Guard the tunable denominators so a misconfigured 0/negative range can't
  // produce Infinity/NaN in the normalized output.
  double get _hRange => math.max(1e-6, heightRangeMeters);
  double get _aRange => math.max(1e-6, angleRangeRad);
  double get _swingRange => math.max(1e-6, swingFullScaleG);

  /// Capture the current arm pose as neutral and zero the integrators.
  /// No-op until at least one sample has seeded the gravity estimate.
  void calibrate() {
    if (!_gravInit) return;
    _neutralPitch = math.atan2(_gravX, _gravZ);
    final mag = math.sqrt(_gravX * _gravX + _gravY * _gravY + _gravZ * _gravZ);
    if (mag > 1e-6) {
      _upX = -_gravX / mag;
      _upY = -_gravY / mag;
      _upZ = -_gravZ / mag;
    }
    _vel = 0;
    _disp = 0;
    _fusedNorm = 0.5;
    _swingEnv = 0;
    _calibrated = true;
  }

  /// Feed one telemetry sample. [dt] is elapsed seconds since the last sample.
  void update(TelemetryData d, double dt) {
    if (!_gravInit) {
      _gravX = d.ax;
      _gravY = d.ay;
      _gravZ = d.az;
      _gravInit = true;
    } else {
      _gravX = gravityAlpha * _gravX + (1 - gravityAlpha) * d.ax;
      _gravY = gravityAlpha * _gravY + (1 - gravityAlpha) * d.ay;
      _gravZ = gravityAlpha * _gravZ + (1 - gravityAlpha) * d.az;
    }
    if (!_calibrated) return;

    // Linear acceleration = measured - gravity (g units).
    final linX = d.ax - _gravX;
    final linY = d.ay - _gravY;
    final linZ = d.az - _gravZ;
    final linMag = math.sqrt(linX * linX + linY * linY + linZ * linZ);
    final gyroMag = math.sqrt(d.gx * d.gx + d.gy * d.gy + d.gz * d.gz);
    final atRest = linMag < restAccelThresh && gyroMag < restGyroThresh;

    // Vertical linear accel toward neutral "up", in m/s^2.
    final dotUp = linX * _upX + linY * _upY + linZ * _upZ;
    final vertAccel = dotUp * _g;

    // Horizontal component (perpendicular to "up") drives the swing energy.
    final hX = linX - dotUp * _upX;
    final hY = linY - dotUp * _upY;
    final hZ = linZ - dotUp * _upZ;
    final horizMag = math.sqrt(hX * hX + hY * hY + hZ * hZ);
    final swingTarget = (horizMag / _swingRange).clamp(0.0, 1.0);
    final k = swingTarget > _swingEnv ? swingAttack : swingRelease;
    _swingEnv += k * (swingTarget - _swingEnv);

    if (atRest) {
      _vel = 0; // zero-velocity update: the drift killer
    } else {
      _vel = _vel * velocityLeak + vertAccel * dt;
      // Leak displacement while moving so it can't grow unbounded during
      // continuous play; a true rest still freezes it (this branch is skipped).
      _disp = _disp * dispLeak + _vel * dt;
    }

    // Complementary fuse: integrate, then correct toward the angle anchor.
    final anchor = _angleNorm();
    _fusedNorm += (_vel * dt) / (2 * _hRange);
    _fusedNorm = (1 - complementaryK) * _fusedNorm + complementaryK * anchor;
    _fusedNorm = _fusedNorm.clamp(0.0, 1.0);
  }

  double _angleNorm() {
    final pitch = math.atan2(_gravX, _gravZ);
    var elevation = pitch - _neutralPitch;
    // Unwrap across the atan2 branch cut so a wrist rotation past ±pi doesn't
    // glitch the estimate by a full 2*pi jump.
    if (elevation > math.pi) {
      elevation -= 2 * math.pi;
    } else if (elevation < -math.pi) {
      elevation += 2 * math.pi;
    }
    return (0.5 + 0.5 * elevation / _aRange).clamp(0.0, 1.0);
  }

  double _heightNorm() => (0.5 + 0.5 * _disp / _hRange).clamp(0.0, 1.0);

  /// Current normalized height in [0, 1] (0.5 = neutral) for the active mode.
  double get height {
    if (!_calibrated) return 0.5;
    switch (mode) {
      case HeightMode.angleOnly:
        return _angleNorm();
      case HeightMode.heightOnly:
        return _heightNorm();
      case HeightMode.fused:
        return _fusedNorm;
    }
  }
}
