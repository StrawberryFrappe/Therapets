import 'package:shared_preferences/shared_preferences.dart';

import '../services/device/presence_profile.dart';

/// Which presence-detection profile to use, based on the connected device's
/// firmware. See [PresenceProfile].
enum PresenceMode {
  /// New always-on firmware (default). Small cushion, real-time presence.
  strict,

  /// Old battery-saving firmware that duty-cycles the sensor 10s ON / 10s OFF.
  lenient,
}

/// Runtime game settings that are persisted to SharedPreferences.
class GameSettings {
  static double sbrUpwardSpeedMultiplier = 1.5;

  /// App-wide presence mode. Defaults to [PresenceMode.strict] (always-on
  /// firmware); flip to lenient for devices still on the old duty-cycle build.
  static PresenceMode presenceMode = PresenceMode.strict;

  static const _prefsKey = 'sbr_upward_speed_multiplier';
  static const _presenceModeKey = 'presence_mode';

  /// Resolve the current mode to its tuning profile.
  static PresenceProfile get presenceProfile => presenceMode == PresenceMode.lenient
      ? const PresenceProfile.dutyCycle()
      : const PresenceProfile.alwaysOn();

  /// Load persisted settings. Call once at app start or when needed.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    sbrUpwardSpeedMultiplier = prefs.getDouble(_prefsKey) ?? sbrUpwardSpeedMultiplier;
    final modeName = prefs.getString(_presenceModeKey);
    presenceMode = PresenceMode.values.firstWhere(
      (m) => m.name == modeName,
      orElse: () => presenceMode,
    );
  }

  /// Persist and apply multiplier.
  static Future<void> setSbrUpwardSpeedMultiplier(double v) async {
    sbrUpwardSpeedMultiplier = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefsKey, v);
  }

  /// Persist and apply the presence mode.
  static Future<void> setPresenceMode(PresenceMode mode) async {
    presenceMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_presenceModeKey, mode.name);
  }
}
