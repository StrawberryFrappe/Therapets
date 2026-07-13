import 'dart:math' as math;

import '../../../services/device/device_service.dart';

/// Calibration state machine states.
enum CalibrationState {
  idle,
  calibratingLeft,
  calibratingRight,
  done,
}

/// Which arm's orthosis/board the player is wearing. The right-arm board is
/// mirror-mounted relative to the left-arm one (rotating the whole orthosis
/// 180° about the forearm's long axis puts the M5Stick back in the same
/// position/orientation) — so the raw roll-axis accelerometer reading is
/// sign-flipped between the two boards for the same physical wrist angle.
enum Handedness { left, right }

/// Processes IMU telemetry during a calibration phase to determine
/// the user's comfortable tilt range.
///
/// Usage:
///   1. Call [startLeftPhase] to begin collecting left samples.
///   2. Feed each [TelemetryData] packet via [rollFromTelemetry].
///   3. Call [confirmLeft] then [confirmRight] to lock in bounds.
///   4. Use [mapAngleToScreenX] to convert live roll angles to bumper X.
class MotionCalibrator {
  CalibrationState state = CalibrationState.idle;

  /// The roll angle (degrees) when the user turns their wrist max left.
  double leftAngle = 0.0;

  /// The roll angle (degrees) when the user turns their wrist max right.
  double rightAngle = 0.0;

  // --- Helpers ---

  /// Computes the roll angle in degrees from raw telemetry.
  /// Roll = rotation around the axis running along the forearm.
  ///
  /// Uses the full gravity **azimuth** in the plane perpendicular to the
  /// forearm long axis — `atan2(ax, az)` — instead of the old single-axis
  /// projection `atan2(ax, sqrt(ay²+az²))`. The single-axis form saturated
  /// near ±90° (sensitivity → 0), so on the mirror-mounted right board the
  /// wrist range of motion collapsed into a few noisy degrees and the bumper
  /// glued to an edge. The azimuth is uniformly sensitive over a full ±180°.
  ///
  /// AXIS CHOICE IS A BEST GUESS pending on-device validation (issue #44):
  /// the forearm long axis is assumed to be Y, so gravity trades between the
  /// X and Z axes as the wrist rolls. If hardware shows the long axis is X or
  /// Z instead, swap the two axes fed to [math.atan2].
  ///
  /// [handedness] compensates for the mirrored right-arm board (see
  /// [Handedness]). A 180° rotation about the forearm axis flips both X and Z,
  /// i.e. a constant +180° azimuth offset — which [mapAngleToScreenX]
  /// normalization absorbs, so left and right are now truly symmetric.
  static double rollFromTelemetry(
    TelemetryData data, {
    Handedness handedness = Handedness.left,
  }) {
    double deg = math.atan2(data.ax, data.az) * 180.0 / math.pi;
    if (handedness == Handedness.right) {
      deg += 180.0;
      if (deg > 180.0) deg -= 360.0;
    }
    return deg;
  }

  // --- State transitions ---

  void startLeftPhase() {
    state = CalibrationState.calibratingLeft;
  }

  void confirmLeft(double roll) {
    leftAngle = roll;
    state = CalibrationState.calibratingRight;
  }

  bool confirmRight(double roll) {
    // Unwrap onto the same 360° branch as leftAngle so a ±180° seam between
    // the two calibration poses yields the true arc, not a ~360° artifact.
    while (roll - leftAngle > 180.0) roll -= 360.0;
    while (roll - leftAngle < -180.0) roll += 360.0;
    rightAngle = roll;

    // Ensure adequate separation between left and right calibration points.
    // Kept low so limited-ROM therapy users are not rejected; UI can surface
    // [narrowRange] as a soft "try a wider tilt" hint instead.
    if ((rightAngle - leftAngle).abs() < 5.0) {
      // Range too small, reject calibration and prompt restart
      state = CalibrationState.calibratingLeft;
      return false;
    }

    state = CalibrationState.done;
    return true;
  }

  /// True when the calibrated span is usable but suspiciously narrow, so
  /// small tilts translate to large bumper jumps. UI may warn without forcing
  /// a recalibration (limited-ROM patients legitimately hit small spans).
  bool get narrowRange => (rightAngle - leftAngle).abs() < 15.0;

  // --- Mapping ---

  /// Maps a live roll angle to a screen X coordinate in [halfWidth, screenWidth - halfWidth].
  ///
  /// The left angle maps to halfWidth (left edge).
  /// The right angle maps to screenWidth - halfWidth (right edge).
  double mapAngleToScreenX(double rollAngle, double screenWidth, double bumperWidth) {
    final halfWidth = bumperWidth / 2.0;
    final range = screenWidth - bumperWidth;

    // Unwrap the live angle onto the calibrated branch so a ±180° azimuth
    // seam between leftAngle/rightAngle doesn't cause the bumper to jump.
    double a = rollAngle;
    final mid = (leftAngle + rightAngle) / 2.0;
    while (a - mid > 180.0) a -= 360.0;
    while (a - mid < -180.0) a += 360.0;

    // t goes from 0.0 at leftAngle to 1.0 at rightAngle
    double t = (a - leftAngle) / (rightAngle - leftAngle);

    t = t.clamp(0.0, 1.0);

    return halfWidth + t * range;
  }
}
