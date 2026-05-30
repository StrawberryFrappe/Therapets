import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_event.dart';

/// Persistent queue for cloud events using SharedPreferences.
class EventQueue {
  static const String _prefKey = 'cloud_event_queue';
  List<CloudEvent> _events = [];

  /// Initialize the queue
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefKey);
    if (jsonStr != null) {
      try {
        final List<dynamic> list = jsonDecode(jsonStr);
        _events = list.map((e) => CloudEvent.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        print('[EventQueue] Error loading events: $e');
        _events = [];
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_events.map((e) => e.toJson()).toList());
    await prefs.setString(_prefKey, jsonStr);
  }

  /// Add an event to the queue
  Future<void> enqueue(CloudEvent event) async {
    _events.add(event);
    await _save();
  }
  
  /// Update an event (e.g., retry count)
  Future<void> update(CloudEvent event) async {
    // The event is modified in place, so we just need to save the list
    await _save();
  }

  /// Get all pending events (oldest first)
  List<CloudEvent> getAll() {
    return List.unmodifiable(_events);
  }

  /// Remove multiple events by their IDs
  Future<void> removeAll(Iterable<String> ids) async {
    final idsSet = ids.toSet();
    _events.removeWhere((e) => idsSet.contains(e.id));
    await _save();
  }

  /// Get the number of pending events
  int get count => _events.length;

  /// Check if queue is empty
  bool get isEmpty => _events.isEmpty;

  /// Clear all events (use with caution)
  Future<void> clear() async {
    _events.clear();
    await _save();
  }
}
