/// Difficulty presets for SBR (brick-breaker).
///
/// SBR already ramps difficulty per level (grid grows, brick HP scales). These
/// presets set the *starting* conditions and stack on top of that curve; they do
/// not replace it. Ball base speed is intentionally the same (300) across all
/// levels — difficulty diverges via bumper width, lives, per-hit speed ramp and
/// how often helpful bricks spawn.
enum SbrDifficulty { easy, medium, hard, extreme }

/// Tuning parameters for a given SBR difficulty.
class SbrDifficultyConfig {
  /// Bumper width as a fraction of screen width. Narrower = harder.
  final double bumperWidthFactor;

  /// Lives the run starts with. Easy/medium get more; hard/extreme floor at 3.
  final int startingLives;

  /// Multiplicative ball-speed increase applied on each brick hit
  /// (1.0 = no ramp). Speeds long rallies up on higher difficulties.
  final double speedRamp;

  /// Cap on the ramped speed, as a multiplier of the ball's base speed (300).
  final double maxSpeedMultiplier;

  /// Added to the probability thresholds of helpful brick types
  /// (multiball/expand/exploding/glass/ghost). Positive = more powerups (easy),
  /// negative = fewer (extreme).
  final double helpfulBrickBonus;

  /// Silver coin reward multiplier (mirrors Flappy: 1/1/2/4 easy→extreme).
  final double coinMultiplier;

  const SbrDifficultyConfig({
    required this.bumperWidthFactor,
    required this.startingLives,
    required this.speedRamp,
    required this.maxSpeedMultiplier,
    required this.helpfulBrickBonus,
    required this.coinMultiplier,
  });

  static const Map<SbrDifficulty, SbrDifficultyConfig> presets = {
    SbrDifficulty.easy: SbrDifficultyConfig(
      bumperWidthFactor: 0.32,
      startingLives: 5,
      speedRamp: 1.0,
      maxSpeedMultiplier: 1.5,
      helpfulBrickBonus: 0.06,
      coinMultiplier: 1.0,
    ),
    SbrDifficulty.medium: SbrDifficultyConfig(
      bumperWidthFactor: 0.25,
      startingLives: 4,
      speedRamp: 1.004,
      maxSpeedMultiplier: 1.8,
      helpfulBrickBonus: 0.02,
      coinMultiplier: 1.0,
    ),
    SbrDifficulty.hard: SbrDifficultyConfig(
      bumperWidthFactor: 0.20,
      startingLives: 3,
      speedRamp: 1.008,
      maxSpeedMultiplier: 2.2,
      helpfulBrickBonus: 0.0,
      coinMultiplier: 2.0,
    ),
    SbrDifficulty.extreme: SbrDifficultyConfig(
      bumperWidthFactor: 0.15,
      startingLives: 3,
      speedRamp: 1.015,
      maxSpeedMultiplier: 2.8,
      helpfulBrickBonus: -0.02,
      coinMultiplier: 4.0,
    ),
  };
}
