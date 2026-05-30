import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Therapets/game/pets/pet_stats.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PetStats Persistence and Logic', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('toJson and fromJson handle serialization correctly', () {
      final stats = PetStats();
      stats.hunger = 0.8;
      stats.happiness = 0.9;
      stats.addGold(150);
      stats.addSilver(300);

      final json = stats.toJson();
      
      final loadedStats = PetStats();
      loadedStats.rehydrateFromMap(json);

      expect(loadedStats.hunger, closeTo(0.8, 0.001));
      expect(loadedStats.happiness, closeTo(0.9, 0.001));
      expect(loadedStats.goldCoins, equals(150));
      expect(loadedStats.silverCoins, equals(300));
    });

    test('rehydrateFromMap safely casts integers and doubles', () {
      // Sometimes JSON parsing gives integers instead of doubles for whole numbers.
      // E.g., `1` instead of `1.0`
      final malformedJson = {
        'hunger': 1,
        'happiness': 0,
        'goldCoins': 10.5, // Should truncate or handle
        'silverCoins': 5,
        'lastUpdateMs': DateTime.now().millisecondsSinceEpoch
      };

      final stats = PetStats();
      stats.rehydrateFromMap(malformedJson);

      expect(stats.hunger, equals(1.0));
      expect(stats.happiness, equals(0.0));
      expect(stats.goldCoins, equals(10));
      expect(stats.silverCoins, equals(5));
    });

    test('bounds are enforced on stats', () {
      final stats = PetStats();
      
      stats.hunger = 1.5;
      expect(stats.hunger, equals(1.0));
      
      stats.hunger = -0.5;
      expect(stats.hunger, equals(0.0));
      
      stats.happiness = 2.0;
      expect(stats.happiness, equals(1.0));
      
      stats.happiness = -1.0;
      expect(stats.happiness, equals(0.0));
    });

    test('applyBackgroundUpdates calculates synced decay correctly', () {
      final stats = PetStats();
      stats.hunger = 1.0;
      stats.happiness = 0.5;
      stats.hungerDecayRate = 0.1; // 10% per second
      stats.happinessGainRate = 0.05; // 5% per second
      stats.happinessDecayRate = 0.2; // 20% per second
      
      // Simulate 2 seconds of background time
      final now = DateTime.now();
      stats.rehydrateFromMap({
        'lastUpdateMs': now.subtract(const Duration(seconds: 2)).millisecondsSinceEpoch
      });

      stats.applyBackgroundUpdates(wasDeviceSynced: true);

      // Hunger decays by 0.2 (2 * 0.1)
      expect(stats.hunger, closeTo(0.8, 0.001));
      
      // Happiness ALWAYS decays in background initially
      expect(stats.happiness, closeTo(0.1, 0.001));

      // Buffer gains by 0.1 (2 * 0.05)
      expect(stats.happinessBuffer, closeTo(0.1, 0.001));
    });

    test('applyBackgroundUpdates calculates unsynced decay correctly', () {
      final stats = PetStats();
      stats.hunger = 1.0;
      stats.happiness = 1.0;
      stats.hungerDecayRate = 0.1;
      stats.happinessDecayRate = 0.2;
      
      // Simulate 2 seconds of background time
      final now = DateTime.now();
      stats.rehydrateFromMap({
        'lastUpdateMs': now.subtract(const Duration(seconds: 2)).millisecondsSinceEpoch
      });

      stats.applyBackgroundUpdates(wasDeviceSynced: false);

      // Hunger decays by 0.2
      expect(stats.hunger, closeTo(0.8, 0.001));
      
      // Happiness decays by 0.4
      expect(stats.happiness, closeTo(0.6, 0.001));
    });

    test('loadFromPrefs and save() correctly atomic-bundles to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'pet_stats_bundle': '{"hunger":0.4,"happiness":0.6,"goldCoins":10,"silverCoins":20}'
      });

      final stats = PetStats();
      await stats.loadFromPrefs(isDeviceSynced: false);
      stats.markReady(); // Allow saving

      expect(stats.hunger, closeTo(0.4, 0.001));
      expect(stats.goldCoins, equals(10));

      stats.addGold(5);
      await stats.save();

      // Verify the bundle was updated in prefs
      final prefs = await SharedPreferences.getInstance();
      final bundleStr = prefs.getString('pet_stats_bundle');
      expect(bundleStr, isNotNull);
      expect(bundleStr, contains('"goldCoins":15'));
    });
  });
}
