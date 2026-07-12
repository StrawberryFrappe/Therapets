import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:Therapets/game/minigames/orchestra/height_estimator.dart';
import 'package:Therapets/game/models/telemetry_data.dart';

// Synthetic sample. Gravity is expressed in g; a resting device reads ~1g.
TelemetryData s(double ax, double ay, double az,
        {double gx = 0, double gy = 0, double gz = 0}) =>
    TelemetryData(ax: ax, ay: ay, az: az, gx: gx, gy: gy, gz: gz);

void feed(HeightEstimator e, TelemetryData d, int n, {double dt = 0.01}) {
  for (var i = 0; i < n; i++) {
    e.update(d, dt);
  }
}

// Seed the gravity estimate at neutral (flat, gravity on +Z) and calibrate.
HeightEstimator seeded(HeightMode mode) {
  final e = HeightEstimator(mode: mode);
  feed(e, s(0, 0, 1), 60);
  e.calibrate();
  return e;
}

void main() {
  group('HeightEstimator', () {
    test('uncalibrated reports neutral (0.5) in every mode', () {
      for (final m in HeightMode.values) {
        final e = HeightEstimator(mode: m);
        expect(e.height, 0.5);
        feed(e, s(0, 0, 1), 5); // seeds gravity but no calibrate()
        expect(e.isCalibrated, isFalse);
        expect(e.height, 0.5);
      }
    });

    test('calibrate() with no samples is a safe no-op', () {
      final e = HeightEstimator();
      e.calibrate();
      expect(e.isCalibrated, isFalse);
    });

    test('angleOnly: raising (tilting toward +X) increases height, monotonic',
        () {
      final neutral = seeded(HeightMode.angleOnly);
      expect(neutral.height, closeTo(0.5, 1e-6));

      double heightAtTilt(double theta) {
        final e = seeded(HeightMode.angleOnly);
        feed(e, s(math.sin(theta), 0, math.cos(theta)), 80);
        return e.height;
      }

      final small = heightAtTilt(math.pi / 6);
      final big = heightAtTilt(math.pi / 4);
      expect(small, greaterThan(0.55));
      expect(big, greaterThan(small)); // more tilt -> higher pitch
    });

    test('angleOnly: returning to neutral restores ~0.5', () {
      final e = seeded(HeightMode.angleOnly);
      feed(e, s(math.sin(math.pi / 4), 0, math.cos(math.pi / 4)), 80);
      expect(e.height, greaterThan(0.6));
      feed(e, s(0, 0, 1), 80);
      expect(e.height, closeTo(0.5, 0.05));
    });

    test('fused: a constant accel bias does NOT run away (drift bounded)', () {
      final e = seeded(HeightMode.fused);
      // 0.05g steady bias — below the rest threshold, so ZUPT + the angle
      // anchor must keep the estimate pinned near neutral.
      feed(e, s(0, 0, 1.05), 300);
      expect((e.height - 0.5).abs(), lessThan(0.15));
    });

    test('heightOnly: raising then holding raises height, rest freezes it', () {
      final e = seeded(HeightMode.heightOnly);
      expect(e.height, closeTo(0.5, 1e-6));
      // Raise and hold a new steady pose (az settles to 0.2). Height climbs
      // while accelerating, then the hold becomes a rest and ZUPT freezes it.
      feed(e, s(0, 0, 0.2), 120);
      final rest1 = e.height;
      expect(rest1, greaterThan(0.5));
      feed(e, s(0, 0, 0.2), 60);
      expect(e.height, closeTo(rest1, 1e-9)); // frozen at rest
    });

    test('calibrate() re-zeros after a move', () {
      final e = seeded(HeightMode.heightOnly);
      feed(e, s(0, 0, 0.2), 120);
      expect(e.height, greaterThan(0.5));
      e.calibrate(); // gravity already settled at the held pose
      expect(e.height, closeTo(0.5, 1e-6));
    });

    test('swingEnergy: horizontal sweeping raises it, resting decays it', () {
      final e = seeded(HeightMode.fused);
      expect(e.swingEnergy, closeTo(0.0, 1e-9));
      // Sweep: oscillate horizontal accel (X) around zero.
      for (var i = 0; i < 60; i++) {
        e.update(s(i.isEven ? 0.6 : -0.6, 0, 1), 0.01);
      }
      expect(e.swingEnergy, greaterThan(0.3));
      // Stop: energy bleeds off.
      feed(e, s(0, 0, 1), 120);
      expect(e.swingEnergy, lessThan(0.1));
    });

    test('swingEnergy: pure vertical motion barely registers as swing', () {
      final e = seeded(HeightMode.fused);
      for (var i = 0; i < 40; i++) {
        e.update(s(0, 0, i.isEven ? 0.4 : 1.6), 0.01); // vertical only
      }
      expect(e.swingEnergy, lessThan(0.2));
    });

    test('mode selects a different signal from the same state', () {
      final e = seeded(HeightMode.angleOnly);
      // Tilt gradually so the per-step motion stays below the rest threshold:
      // the angle estimate rises but displacement stays ~0.
      for (var i = 1; i <= 40; i++) {
        final th = (math.pi / 4) * i / 40;
        e.update(s(math.sin(th), 0, math.cos(th)), 0.01);
      }
      feed(e, s(math.sin(math.pi / 4), 0, math.cos(math.pi / 4)), 40);
      final angle = e.height;
      e.mode = HeightMode.heightOnly;
      final displacement = e.height;
      expect(angle, greaterThan(0.6));
      expect(displacement, closeTo(0.5, 0.1));
      expect((angle - displacement).abs(), greaterThan(0.05));
    });
  });
}
