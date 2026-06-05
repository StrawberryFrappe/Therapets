import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Therapets/services/cloud/event_queue.dart';
import 'package:Therapets/services/cloud/cloud_event.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EventQueue Persistence and Logic', () {
    late EventQueue queue;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      queue = EventQueue();
    });

    test('init loads empty queue from fresh prefs', () async {
      await queue.init();
      expect(queue.isEmpty, isTrue);
      expect(queue.count, equals(0));
    });

    test('enqueue adds to list and saves to prefs', () async {
      await queue.init();
      
      final event = CloudEvent(
        id: 'test-id-1',
        timestamp: DateTime.now(),
        eventType: 'test_event',
        payload: {'key': 'value'},
      );

      await queue.enqueue(event);

      expect(queue.count, equals(1));
      expect(queue.getAll().first.id, equals('test-id-1'));

      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('cloud_event_queue');
      expect(jsonStr, isNotNull);
      expect(jsonStr, contains('test-id-1'));
    });

    test('init rehydrates from existing prefs', () async {
      final eventJson = {
        'id': 'test-id-2',
        'ts': DateTime.now().millisecondsSinceEpoch,
        'type': 'test_event',
        'payload': {},
        'retryCount': 0,
      };
      
      SharedPreferences.setMockInitialValues({
        'cloud_event_queue': jsonEncode([eventJson])
      });

      await queue.init();
      expect(queue.count, equals(1));
      expect(queue.getAll().first.id, equals('test-id-2'));
    });

    test('removeAll deletes specific events', () async {
      await queue.init();
      
      await queue.enqueue(CloudEvent(
        id: '1', timestamp: DateTime.now(), eventType: 'test', payload: {}
      ));
      await queue.enqueue(CloudEvent(
        id: '2', timestamp: DateTime.now(), eventType: 'test', payload: {}
      ));
      await queue.enqueue(CloudEvent(
        id: '3', timestamp: DateTime.now(), eventType: 'test', payload: {}
      ));

      expect(queue.count, equals(3));

      await queue.removeAll(['1', '3']);

      expect(queue.count, equals(1));
      expect(queue.getAll().first.id, equals('2'));
    });
    
    test('update saves changes in place', () async {
      await queue.init();
      
      final event = CloudEvent(
        id: '1', timestamp: DateTime.now(), eventType: 'test', payload: {}
      );
      await queue.enqueue(event);
      
      // Modify and update
      event.retryCount = 4;
      await queue.update(event);
      
      // Load from fresh queue to verify prefs persistence
      final queue2 = EventQueue();
      await queue2.init();
      
      expect(queue2.getAll().first.retryCount, equals(4));
    });
  });
}
