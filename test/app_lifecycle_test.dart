import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Therapets/core/app_lifecycle_manager.dart';
import 'package:Therapets/game/pets/pet_stats.dart';
import 'package:Therapets/game/missions/mission_service.dart';
import 'package:Therapets/services/device/device_service.dart';
import 'package:Therapets/services/cloud/cloud_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('App Lifecycle Simulation', () {
    testWidgets('simulates rapid open and close (pause/resume)', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      
      final petStats = PetStats();
      final deviceService = DeviceService();
      final cloudService = CloudService();
      final missionService = MissionService(cloudService: cloudService);

      await tester.pumpWidget(
        MaterialApp(
          home: AppLifecycleManager(
            petStats: petStats,
            deviceService: deviceService,
            missionService: missionService,
            child: const Scaffold(
              body: Text('Test App'),
            ),
          ),
        ),
      );

      // Verify the app rendered
      expect(find.text('Test App'), findsOneWidget);

      // 1. Simulate user minimizing the app (Paused)
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      
      // Wait for async flush operations to complete
      await tester.pumpAndSettle();

      // 2. Simulate user immediately reopening the app (Resumed)
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pumpAndSettle();

      // 3. Do it rapidly in a loop to simulate spamming
      for (int i = 0; i < 5; i++) {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      }
      
      // Allow any pending async timers (like the 2-second BluetoothService native polling timer) to finish
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      
      // If we got here without throwing concurrent modification or unhandled exceptions,
      // it means the AppLifecycleManager successfully survived rapid open/close cycles!
      expect(true, isTrue);
    });
  });
}
