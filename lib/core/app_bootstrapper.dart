


import 'package:flutter/foundation.dart';


import '../game/missions/mission_service.dart';
import '../game/pets/pet_stats.dart';
import '../services/cloud/cloud_service.dart';
import '../services/device/device_service.dart';
import '../services/locale_service.dart';
import '../services/notifications/pet_notification_service.dart';

/// Result of the bootstrap process.
class BootstrapResult {
  final LocaleService localeService;
  final CloudService cloudService;
  final DeviceService deviceService;
  final MissionService missionService;
  final PetStats petStats;
  final PetNotificationService notificationService;

  BootstrapResult({
    required this.localeService,
    required this.cloudService,
    required this.deviceService,
    required this.missionService,
    required this.petStats,
    required this.notificationService,
  });
}

/// Orchestrates the app startup sequence.
/// Ensures all services are initialized in the correct order.
class AppBootstrapper {
  static Future<BootstrapResult> init() async {
    debugPrint('[Bootstrapper] STARTING');

    // 1. Initialize Services (Leaf dependencies first)
    final localeService = LocaleService();
    try {
      await localeService.init().timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('[Bootstrapper] LocaleService init failed: $e');
    }

    final cloudService = CloudService();
    try {
      await cloudService.init().timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('[Bootstrapper] CloudService init failed: $e');
    }

    final deviceService = DeviceService();
    try {
      await deviceService.init().timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('[Bootstrapper] DeviceService init failed: $e');
    }

    // 2. Load PetStats from SharedPreferences
    final petStats = PetStats();
    final isSynced = deviceService.currentDisplayStatus == DeviceDisplayStatus.synced;
    await petStats.loadFromPrefs(isDeviceSynced: isSynced);
    petStats.markReady();

    // 3. Initialize Services that depend on others
    final missionService = MissionService(cloudService: cloudService);
    try {
      await missionService.init(petStats).timeout(const Duration(seconds: 5));
      
      // Rehydrate background progress for missions (e.g. sync duration)
      final lastUpdateMs = petStats.lastUpdateTime.millisecondsSinceEpoch;
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsedSec = (now - lastUpdateMs) / 1000.0;
      final isSynced = deviceService.currentDisplayStatus == DeviceDisplayStatus.synced;
      
      await missionService.rehydrateBackgroundProgress(elapsedSec, isSynced);
    } catch (e) {
      debugPrint('[Bootstrapper] MissionService init failed: $e');
    }

    final notificationService = PetNotificationService(localeService: localeService);

    debugPrint('[Bootstrapper] COMPLETE');

    return BootstrapResult(
      localeService: localeService,
      cloudService: cloudService,
      deviceService: deviceService,
      missionService: missionService,
      petStats: petStats,
      notificationService: notificationService,
    );
  }

}
