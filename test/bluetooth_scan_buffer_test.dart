import 'package:flutter_test/flutter_test.dart';
import 'package:Therapets/services/device/scan_buffer.dart';

/// Minimal stand-in for a scan result. Mirrors the fields the real buffer keys
/// on (id / name / rssi) without pulling in platform `ScanResult`.
typedef FakeScan = ({String id, String name, int rssi});

String _idOf(FakeScan s) => s.id;
bool _isPriority(FakeScan s) => s.name == 'M5-IMU-Sensor';

void main() {
  group('upsertById', () {
    test('adds a new device', () {
      final list = <FakeScan>[];
      final changed = upsertById(list, (id: 'a', name: 'X', rssi: -40), _idOf);
      expect(changed, isTrue);
      expect(list, hasLength(1));
      expect(list.first.id, 'a');
    });

    test('updates existing device in place, preserving position', () {
      final list = <FakeScan>[
        (id: 'a', name: 'A', rssi: -40),
        (id: 'b', name: 'B', rssi: -50),
      ];
      upsertById(list, (id: 'a', name: 'A', rssi: -80), _idOf);
      expect(list, hasLength(2)); // no duplicate
      expect(list[0].id, 'a'); // still first
      expect(list[0].rssi, -80); // value replaced
      expect(list[1].id, 'b'); // untouched
    });

    test('keeps unnamed devices (no name filter)', () {
      final list = <FakeScan>[];
      upsertById(list, (id: 'ghost', name: '', rssi: -70), _idOf);
      expect(list, hasLength(1));
      expect(list.first.id, 'ghost');
    });
  });

  group('sortPriorityFirst', () {
    test('moves the priority device to the front', () {
      final list = <FakeScan>[
        (id: 'a', name: 'Headphones', rssi: -40),
        (id: 'b', name: 'M5-IMU-Sensor', rssi: -60),
        (id: 'c', name: 'Watch', rssi: -50),
      ];
      sortPriorityFirst(list, _isPriority);
      expect(list.first.name, 'M5-IMU-Sensor');
    });

    test('preserves relative order of non-priority devices', () {
      final list = <FakeScan>[
        (id: 'a', name: 'Headphones', rssi: -40),
        (id: 'c', name: 'Watch', rssi: -50),
      ];
      sortPriorityFirst(list, _isPriority);
      expect(list.map((e) => e.id).toList(), ['a', 'c']);
    });

    test('no-op when priority device absent', () {
      final list = <FakeScan>[
        (id: 'a', name: 'Headphones', rssi: -40),
        (id: 'c', name: 'Watch', rssi: -50),
      ];
      sortPriorityFirst(list, _isPriority);
      expect(list.map((e) => e.id).toList(), ['a', 'c']);
    });
  });
}
