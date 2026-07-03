import 'package:flutter_test/flutter_test.dart';
import 'package:Therapets/services/treatment/treatment_service.dart';

void main() {
  group('Treatment.fromJson', () {
    test('parses the coworker-provided sample payload', () {
      final treatment = Treatment.fromJson({
        'id': 4,
        'title': 'tratamiento de ortesis',
        'description': 'tratamiento de uso ortesico de prueba',
        'start_date': '2026-03-15',
        'end_date': '2026-03-31',
        'status': 'active',
        'usage_time': 7200,
        'patient_usage_time': 0,
        'enabled_games': ['donut', 'flappy bob'],
      });

      expect(treatment.id, 4);
      expect(treatment.status, 'active');
      expect(treatment.usageTimeSeconds, 7200);
      expect(treatment.patientUsageTimeSeconds, 0);
      expect(treatment.enabledGames, ['donut', 'flappy bob']);
      expect(treatment.startDate, DateTime.parse('2026-03-15'));
    });
  });

  group('TreatmentService.effectiveEnabledGameIds', () {
    test('maps backend names to internal ids for an active treatment', () {
      final service = TreatmentService();
      service.treatmentNotifier.value = Treatment.fromJson({
        'id': 4,
        'title': 't',
        'description': '',
        'start_date': '2026-03-15',
        'end_date': '2026-03-31',
        'status': 'active',
        'usage_time': 7200,
        'patient_usage_time': 0,
        'enabled_games': ['donut', 'flappy bob'],
      });

      expect(service.effectiveEnabledGameIds, {'donut', 'flappy_bird'});
    });

    test('all four backend names map correctly', () {
      final service = TreatmentService();
      service.treatmentNotifier.value = Treatment.fromJson({
        'id': 1,
        'title': 't',
        'description': '',
        'start_date': null,
        'end_date': null,
        'status': 'active',
        'usage_time': 0,
        'patient_usage_time': 0,
        'enabled_games': ['donut', 'flappy bob', 'orchestra', 'block breaker'],
      });

      expect(service.effectiveEnabledGameIds, {'donut', 'flappy_bird', 'orchestra', 'sbr'});
    });

    test('drops stray empty and unrecognized entries without crashing', () {
      final service = TreatmentService();
      service.treatmentNotifier.value = Treatment.fromJson({
        'id': 1,
        'title': 't',
        'description': '',
        'start_date': null,
        'end_date': null,
        'status': 'active',
        'usage_time': 0,
        'patient_usage_time': 0,
        'enabled_games': ['donut', '', 'not_a_real_game'],
      });

      expect(service.effectiveEnabledGameIds, {'donut'});
    });

    test('fails open (null) when no treatment has been fetched yet', () {
      final service = TreatmentService();
      service.treatmentNotifier.value = null;
      expect(service.effectiveEnabledGameIds, isNull);
    });

    test('fails open (null) when enabled_games is empty or fully unrecognized', () {
      final service = TreatmentService();
      service.treatmentNotifier.value = Treatment.fromJson({
        'id': 1,
        'title': 't',
        'description': '',
        'start_date': null,
        'end_date': null,
        'status': 'active',
        'usage_time': 0,
        'patient_usage_time': 0,
        'enabled_games': ['', 'unknown_game'],
      });

      expect(service.effectiveEnabledGameIds, isNull);
    });

    test('fails closed (empty set) when status is present and not active', () {
      final service = TreatmentService();
      service.treatmentNotifier.value = Treatment.fromJson({
        'id': 1,
        'title': 't',
        'description': '',
        'start_date': null,
        'end_date': null,
        'status': 'paused',
        'usage_time': 0,
        'patient_usage_time': 0,
        'enabled_games': ['donut', 'flappy bob'],
      });

      expect(service.effectiveEnabledGameIds, isEmpty);
    });
  });
}
