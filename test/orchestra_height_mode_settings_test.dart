import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Therapets/game/game_settings.dart';
import 'package:Therapets/game/minigames/orchestra/height_estimator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GameSettings.orchestraHeightMode = HeightMode.fused;
  });

  test('setOrchestraHeightMode persists and load() restores it', () async {
    await GameSettings.setOrchestraHeightMode(HeightMode.angleOnly);
    expect(GameSettings.orchestraHeightMode, HeightMode.angleOnly);

    // Simulate a fresh launch: drop the in-memory value, reload from prefs.
    GameSettings.orchestraHeightMode = HeightMode.fused;
    await GameSettings.load();
    expect(GameSettings.orchestraHeightMode, HeightMode.angleOnly);
  });

  test('load() with nothing stored keeps the default (fused)', () async {
    await GameSettings.load();
    expect(GameSettings.orchestraHeightMode, HeightMode.fused);
  });
}
