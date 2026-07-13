import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:Therapets/game/minigames/sbr/motion_calibrator.dart';
import 'package:Therapets/game/models/telemetry_data.dart';

TelemetryData _accel(double ax, double ay, double az) =>
    TelemetryData(ax: ax, ay: ay, az: az, gx: 0, gy: 0, gz: 0);

void main() {
  group('MotionCalibrator.rollFromTelemetry (2-axis azimuth)', () {
    test('left is the gravity azimuth atan2(ax, az) in degrees', () {
      final data = _accel(0.4, 0.1, 0.9);
      final expected = math.atan2(0.4, 0.9) * 180.0 / math.pi;
      expect(MotionCalibrator.rollFromTelemetry(data), closeTo(expected, 1e-9));
    });

    test('default handedness is left', () {
      final data = _accel(0.4, 0.1, 0.9);
      expect(
        MotionCalibrator.rollFromTelemetry(data),
        MotionCalibrator.rollFromTelemetry(data, handedness: Handedness.left),
      );
    });

    test(
        'a mirror-mounted right board reading maps to the SAME physical angle '
        'as the left board (handedness symmetry)', () {
      // 180° rotation about the forearm long axis (Y) flips X and Z.
      for (final t in [0.0, 0.2, 0.5, 0.8, 1.0]) {
        final theta = -80.0 + t * 160.0; // sweep -80°..80°
        final rad = theta * math.pi / 180.0;
        final ax = math.sin(rad);
        final az = math.cos(rad);

        final left = MotionCalibrator.rollFromTelemetry(
          _accel(ax, 0.0, az),
          handedness: Handedness.left,
        );
        final right = MotionCalibrator.rollFromTelemetry(
          _accel(-ax, 0.0, -az), // same pose, mirror board
          handedness: Handedness.right,
        );

        // Equal modulo the 360° wrap.
        final diff = ((left - right + 540.0) % 360.0) - 180.0;
        expect(diff, closeTo(0.0, 1e-6),
            reason: 'left=$left right=$right at theta=$theta');
      }
    });

    test('does NOT saturate near ±90° — sensitivity stays ~1°/°', () {
      // Long axis Y ⇒ ax=sinθ, az=cosθ ⇒ azimuth should equal θ exactly.
      // Seed prev at θ = -90° (one step before the loop start).
      double prev = MotionCalibrator.rollFromTelemetry(
        _accel(math.sin(-90.0 * math.pi / 180.0), 0.0,
            math.cos(-90.0 * math.pi / 180.0)),
      );
      for (double theta = -89.0; theta <= 89.0; theta += 1.0) {
        final rad = theta * math.pi / 180.0;
        final roll = MotionCalibrator.rollFromTelemetry(
          _accel(math.sin(rad), 0.0, math.cos(rad)),
        );
        expect(roll, closeTo(theta, 1e-6));
        final slope = (roll - prev); // per 1° step
        expect(slope, closeTo(1.0, 1e-6)); // uniform, never collapses
        prev = roll;
      }
    });
  });

  group('MotionCalibrator.confirmRight', () {
    test('unwraps the right angle across the ±180° seam into the true arc', () {
      final c = MotionCalibrator()..leftAngle = 170.0;
      final ok = c.confirmRight(-170.0);
      expect(ok, isTrue);
      expect(c.rightAngle, closeTo(190.0, 1e-9)); // 20° arc, not 340°
      expect((c.rightAngle - c.leftAngle).abs(), closeTo(20.0, 1e-9));
    });

    test('rejects a span narrower than 5°', () {
      final c = MotionCalibrator()..leftAngle = 10.0;
      expect(c.confirmRight(13.0), isFalse);
      expect(c.state, CalibrationState.calibratingLeft);
    });

    test('narrowRange flags a usable-but-tight span without rejecting it', () {
      final c = MotionCalibrator()..leftAngle = 0.0;
      expect(c.confirmRight(8.0), isTrue); // accepted
      expect(c.narrowRange, isTrue); // but flagged
      final wide = MotionCalibrator()..leftAngle = 0.0;
      expect(wide.confirmRight(40.0), isTrue);
      expect(wide.narrowRange, isFalse);
    });
  });

  group('MotionCalibrator.mapAngleToScreenX', () {
    test('maps calibrated endpoints to screen edges and center to middle', () {
      final c = MotionCalibrator()
        ..leftAngle = -30.0
        ..rightAngle = 30.0;
      expect(c.mapAngleToScreenX(-30.0, 300.0, 40.0), closeTo(20.0, 0.001));
      expect(c.mapAngleToScreenX(30.0, 300.0, 40.0), closeTo(280.0, 0.001));
      expect(c.mapAngleToScreenX(0.0, 300.0, 40.0), closeTo(150.0, 0.001));
    });

    test('handedness offset cancels: mirrored calibration yields same mapping',
        () {
      // Left board span.
      final left = MotionCalibrator()
        ..leftAngle = -30.0
        ..rightAngle = 30.0;
      // Same physical span on the mirror board = +180° on every angle.
      final right = MotionCalibrator()
        ..leftAngle = 150.0
        ..rightAngle = 210.0;
      for (final live in [-30.0, -10.0, 0.0, 15.0, 30.0]) {
        expect(
          right.mapAngleToScreenX(live + 180.0, 300.0, 40.0),
          closeTo(left.mapAngleToScreenX(live, 300.0, 40.0), 1e-6),
        );
      }
    });

    test('unwraps a live angle across the ±180° seam', () {
      final c = MotionCalibrator()
        ..leftAngle = 170.0
        ..rightAngle = 190.0; // spans the seam
      // Live reading reported as -175° is physically 185° → t = 0.75.
      expect(c.mapAngleToScreenX(-175.0, 300.0, 40.0),
          closeTo(c.mapAngleToScreenX(185.0, 300.0, 40.0), 1e-6));
    });
  });
}
