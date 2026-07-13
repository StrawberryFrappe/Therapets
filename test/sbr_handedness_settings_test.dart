import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Therapets/game/game_settings.dart';
import 'package:Therapets/game/minigames/sbr/motion_calibrator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GameSettings.sbrHandedness = Handedness.left;
  });

  test('setSbrHandedness persists and load() restores it', () async {
    await GameSettings.setSbrHandedness(Handedness.right);
    expect(GameSettings.sbrHandedness, Handedness.right);

    // Simulate a fresh launch: drop the in-memory value, reload from prefs.
    GameSettings.sbrHandedness = Handedness.left;
    await GameSettings.load();
    expect(GameSettings.sbrHandedness, Handedness.right);
  });

  test('load() with nothing stored keeps the default (left)', () async {
    await GameSettings.load();
    expect(GameSettings.sbrHandedness, Handedness.left);
  });
}
