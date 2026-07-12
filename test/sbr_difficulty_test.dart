import 'package:flutter_test/flutter_test.dart';
import 'package:Therapets/game/minigames/sbr/sbr_difficulty.dart';

void main() {
  group('SbrDifficultyConfig presets', () {
    SbrDifficultyConfig cfg(SbrDifficulty d) => SbrDifficultyConfig.presets[d]!;

    test('every difficulty has a preset', () {
      for (final d in SbrDifficulty.values) {
        expect(SbrDifficultyConfig.presets.containsKey(d), isTrue, reason: '$d');
      }
    });

    test('lives: easy/medium get more, hard & extreme floor at 3', () {
      expect(cfg(SbrDifficulty.easy).startingLives, greaterThan(cfg(SbrDifficulty.medium).startingLives));
      expect(cfg(SbrDifficulty.medium).startingLives, greaterThan(3));
      // Hard/extreme never drop below the base 3 lives.
      expect(cfg(SbrDifficulty.hard).startingLives, 3);
      expect(cfg(SbrDifficulty.extreme).startingLives, 3);
    });

    test('bumper width narrows monotonically easy -> extreme', () {
      expect(cfg(SbrDifficulty.easy).bumperWidthFactor, greaterThan(cfg(SbrDifficulty.medium).bumperWidthFactor));
      expect(cfg(SbrDifficulty.medium).bumperWidthFactor, greaterThan(cfg(SbrDifficulty.hard).bumperWidthFactor));
      expect(cfg(SbrDifficulty.hard).bumperWidthFactor, greaterThan(cfg(SbrDifficulty.extreme).bumperWidthFactor));
    });

    test('speed ramp + cap escalate with difficulty', () {
      expect(cfg(SbrDifficulty.easy).speedRamp, 1.0); // no ramp on easy
      expect(cfg(SbrDifficulty.medium).speedRamp, greaterThan(1.0));
      expect(cfg(SbrDifficulty.extreme).speedRamp, greaterThan(cfg(SbrDifficulty.hard).speedRamp));
      expect(cfg(SbrDifficulty.extreme).maxSpeedMultiplier, greaterThan(cfg(SbrDifficulty.easy).maxSpeedMultiplier));
    });

    test('helpful-brick bonus decreases with difficulty (more powerups on easy)', () {
      expect(cfg(SbrDifficulty.easy).helpfulBrickBonus, greaterThan(cfg(SbrDifficulty.medium).helpfulBrickBonus));
      expect(cfg(SbrDifficulty.medium).helpfulBrickBonus, greaterThan(cfg(SbrDifficulty.hard).helpfulBrickBonus));
      expect(cfg(SbrDifficulty.hard).helpfulBrickBonus, greaterThan(cfg(SbrDifficulty.extreme).helpfulBrickBonus));
    });

    test('coin multiplier mirrors Flappy 1/1/2/4', () {
      expect(cfg(SbrDifficulty.easy).coinMultiplier, 1.0);
      expect(cfg(SbrDifficulty.medium).coinMultiplier, 1.0);
      expect(cfg(SbrDifficulty.hard).coinMultiplier, 2.0);
      expect(cfg(SbrDifficulty.extreme).coinMultiplier, 4.0);
    });
  });
}
