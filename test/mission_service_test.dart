import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Therapets/game/missions/mission_service.dart';
import 'package:Therapets/game/missions/mission.dart';
import 'package:Therapets/game/missions/daily_missions.dart';
import 'package:Therapets/game/pets/pet_stats.dart';
import 'package:Therapets/services/cloud/cloud_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MissionService Persistence and Logic', () {
    late MissionService missionService;
    late PetStats petStats;
    late CloudService cloudService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      cloudService = CloudService(); // Usually mocked, but basic instance is fine
      petStats = PetStats();
      missionService = MissionService(cloudService: cloudService);
    });

    test('init generates fresh missions if no bundle exists', () async {
      await missionService.init(petStats);
      expect(missionService.isInitialized, isTrue);
      expect(missionService.activeMissions, isNotEmpty);
      expect(missionService.activeMissions.length, equals(3));
    });

    test('loadMissions successfully rehydrates from SharedPreferences bundle', () async {
      // Simulate an existing mission bundle
      final lastResetMs = DateTime.now().millisecondsSinceEpoch;
      final bundle = {
        'lastResetMs': lastResetMs,
        'missions': jsonEncode([
          {
            'type': 'sync_duration',
            'targetDuration': 7200.0, // 120 mins
            'currentDuration': 3600.0, // 60 mins
            'rewardGold': 50,
            'rewardHappiness': 0.05,
            'progress': 0.5,
            'claimed': false,
          }
        ]),
      };
      SharedPreferences.setMockInitialValues({
        'mission_bundle': jsonEncode(bundle)
      });

      await missionService.init(petStats);

      expect(missionService.activeMissions.length, equals(1));
      expect(missionService.activeMissions.first.progress, closeTo(0.5, 0.001));
      expect(missionService.activeMissions.first.isCompleted, isFalse);
    });

    test('update advances progress and triggers save', () async {
      await missionService.init(petStats);
      
      // Get the sync mission
      final syncMission = missionService.activeMissions.whereType<SyncDurationMission>().first;
      
      // Update with synced device, enough to pass a minute boundary
      // Default target is 7200s (120 mins)
      await missionService.update(MissionContext(dt: 61.0, isDeviceSynced: true));

      // 1 minute / 120 minutes = 0.00833
      expect(syncMission.progress, closeTo(1 / 120, 0.001));

      // Verify that the save was enqueued and updated SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final bundleStr = prefs.getString('mission_bundle');
      expect(bundleStr, isNotNull);
    });

    test('rehydrateBackgroundProgress properly credits background time', () async {
      await missionService.init(petStats);
      
      final syncMission = missionService.activeMissions.whereType<SyncDurationMission>().first;
      expect(syncMission.progress, equals(0));

      // Simulate 120 seconds of background sync (2 minutes)
      await missionService.rehydrateBackgroundProgress(120.0, true);

      // Target is 120 minutes, 2 minutes complete = 2/120 = 1/60
      expect(syncMission.progress, closeTo(2 / 120, 0.001));
    });
  });
}
