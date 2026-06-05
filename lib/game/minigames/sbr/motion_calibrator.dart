import 'dart:math' as math;

import '../../../services/device/device_service.dart';

/// Calibration state machine states.
enum CalibrationState {
  idle,
  calibratingLeft,
  calibratingRight,
  done,
}

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
  static double rollFromTelemetry(TelemetryData data) {
    return math.atan2(
          -data.ax,
          math.sqrt(data.ay * data.ay + data.az * data.az),
        ) *
        180.0 /
        math.pi;
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
    rightAngle = roll;

    // Ensure adequate separation between left and right calibration points
    if ((rightAngle - leftAngle).abs() < 5.0) {
      // Range too small, reject calibration and prompt restart
      state = CalibrationState.calibratingLeft;
      return false;
    }

    state = CalibrationState.done;
    return true;
  }

  // --- Mapping ---

  /// Maps a live roll angle to a screen X coordinate in [halfWidth, screenWidth - halfWidth].
  ///
  /// The left angle maps to halfWidth (left edge).
  /// The right angle maps to screenWidth - halfWidth (right edge).
  double mapAngleToScreenX(double rollAngle, double screenWidth, double bumperWidth) {
    final halfWidth = bumperWidth / 2.0;
    final range = screenWidth - bumperWidth;
    
    // t goes from 0.0 at leftAngle to 1.0 at rightAngle
    double t = (rollAngle - leftAngle) / (rightAngle - leftAngle);
    
    t = t.clamp(0.0, 1.0);

    return halfWidth + t * range;
  }
}
