import 'package:flutter_test/flutter_test.dart';
import 'package:Therapets/game/minigames/sbr/motion_calibrator.dart';
import 'package:Therapets/game/models/telemetry_data.dart';

void main() {
  group('MotionCalibrator.rollFromTelemetry handedness', () {
    const data = TelemetryData(ax: 0.4, ay: 0.1, az: 0.9, gx: 0, gy: 0, gz: 0);

    test('left (default) matches original -ax convention', () {
      final withDefault = MotionCalibrator.rollFromTelemetry(data);
      final withExplicitLeft = MotionCalibrator.rollFromTelemetry(
        data,
        handedness: Handedness.left,
      );
      expect(withDefault, withExplicitLeft);
      expect(withDefault, lessThan(0)); // -ax with ax > 0 gives a negative roll
    });

    test('right is the exact negation of left for the same raw reading', () {
      final left = MotionCalibrator.rollFromTelemetry(data, handedness: Handedness.left);
      final right = MotionCalibrator.rollFromTelemetry(data, handedness: Handedness.right);
      expect(right, -left);
    });
  });

  group('MotionCalibrator.mapAngleToScreenX', () {
    test('still maps correctly regardless of which handedness produced the calibration angles', () {
      final calibrator = MotionCalibrator()
        ..leftAngle = -30.0
        ..rightAngle = 30.0;
      expect(calibrator.mapAngleToScreenX(-30.0, 300.0, 40.0), closeTo(20.0, 0.001));
      expect(calibrator.mapAngleToScreenX(30.0, 300.0, 40.0), closeTo(280.0, 0.001));
      expect(calibrator.mapAngleToScreenX(0.0, 300.0, 40.0), closeTo(150.0, 0.001));
    });
  });
}
