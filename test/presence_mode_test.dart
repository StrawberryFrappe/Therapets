import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Therapets/services/device/bio_signal_processor.dart';
import 'package:Therapets/services/device/temperature_signal_processor.dart';
import 'package:Therapets/services/device/device_service.dart';
import 'package:Therapets/services/device/device_status_aggregator.dart';
import 'package:Therapets/services/device/presence_profile.dart';

void main() {
  group('PresenceProfile — aggregator cushion', () {
    DeviceStatusAggregator build(PresenceProfile profile, {required bool Function() human}) {
      return DeviceStatusAggregator(
        baseStatusProvider: () => DeviceDisplayStatus.connected,
        staleStatusProvider: () => DeviceDisplayStatus.waiting,
        isHumanDetectedProvider: human,
        isMinigameRunningProvider: () => false,
        hasRecentTelemetryProvider: () => true,
        profile: profile,
      );
    }

    test('strict: drops to connected within the small grace window after human lost', () {
      fakeAsync((async) {
        bool human = true;
        final agg = build(const PresenceProfile.alwaysOn(), human: () => human);
        agg.handleHumanDetectionChange(true);
        expect(agg.currentDisplayStatus, DeviceDisplayStatus.synced);

        // Human lost: 2-sample debounce then 2s grace.
        human = false;
        agg.handleHumanDetectionChange(false);
        agg.handleHumanDetectionChange(false);
        expect(agg.currentDisplayStatus, DeviceDisplayStatus.synced, reason: 'grace still holding');

        async.elapse(const Duration(seconds: 3));
        expect(agg.currentDisplayStatus, DeviceDisplayStatus.connected);
        agg.dispose();
      });
    });

    test('lenient: bridges the 10s blackout — still synced at 3s, drops by 16s', () {
      fakeAsync((async) {
        bool human = true;
        final agg = build(const PresenceProfile.dutyCycle(), human: () => human);
        agg.handleHumanDetectionChange(true);
        // Let the 1 Hz history fill with "present" so the barrage vote is satisfied.
        async.elapse(const Duration(seconds: 5));
        expect(agg.currentDisplayStatus, DeviceDisplayStatus.synced);

        // Human lost: needs 15-sample debounce before the 15s grace starts.
        human = false;
        for (var i = 0; i < 15; i++) {
          agg.handleHumanDetectionChange(false);
        }

        async.elapse(const Duration(seconds: 3));
        expect(agg.currentDisplayStatus, DeviceDisplayStatus.synced, reason: 'lenient bridges the gap');

        async.elapse(const Duration(seconds: 13)); // total 16s > 15s grace
        expect(agg.currentDisplayStatus, DeviceDisplayStatus.connected);
        agg.dispose();
      });
    });
  });

  group('PresenceProfile — zero frame handling', () {
    test('bio strict: a 0/0 frame is a real absence and clears the cached reading', () {
      final p = BioSignalProcessor(); // alwaysOn (default)
      p.preSeed(75, 98);
      expect(p.lastValidBioData, isNotNull);

      p.process(0, 0);
      expect(p.lastValidBioData, isNull);
      p.dispose();
    });

    test('bio lenient: a 0/0 frame is a benign sleep gap and keeps the cached reading', () {
      final p = BioSignalProcessor(profile: const PresenceProfile.dutyCycle());
      p.preSeed(75, 98);
      expect(p.lastValidBioData, isNotNull);

      p.process(0, 0);
      expect(p.lastValidBioData, isNotNull);
      p.dispose();
    });

    test('temperature strict: a 0 frame clears the cached reading', () {
      final p = TemperatureSignalProcessor(); // alwaysOn (default)
      p.process(15408); // ~35°C, in range
      expect(p.lastValidData, isNotNull);

      p.process(0);
      expect(p.lastValidData, isNull);
      p.dispose();
    });

    test('temperature lenient: a 0 frame keeps the cached reading', () {
      final p = TemperatureSignalProcessor(profile: const PresenceProfile.dutyCycle());
      p.process(15408);
      expect(p.lastValidData, isNotNull);

      p.process(0);
      expect(p.lastValidData, isNotNull);
      p.dispose();
    });
  });
}
