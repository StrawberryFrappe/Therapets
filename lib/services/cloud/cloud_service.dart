import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_event.dart';
import 'event_queue.dart';

/// Service for sending events to ThingsBoard cloud.
/// Events are queued locally and flushed when connectivity is available.
class CloudService {
  CloudService();

  final EventQueue _queue = EventQueue();
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // Native (Kotlin) cloud queue bridge — the native side is the sole
  // publisher of telemetry now; this channel just lets the UI inspect it.
  static const MethodChannel _nativeChannel = MethodChannel('sync_companion/bluetooth');

  // Configurable cloud settings (can be changed in Advanced Settings)
  String _baseUrl = 'http://200.13.5.20:8080';
  String _deviceToken = '';

  // Preference keys
  static const String _prefKeyBaseUrl = 'cloud_base_url';
  static const String _prefKeyDeviceToken = 'cloud_device_token';

  // Hosts allowed to use plain http. Any other host must use https.
  // Single source of truth for the §10 config validation rule.
  static const Set<String> _allowedHttpHosts = {'200.13.5.20'};

  bool _isInitialized = false;
  bool _isFlushing = false;

  /// Get current base URL
  String get baseUrl => _baseUrl;

  /// Get current device token
  String get deviceToken => _deviceToken;

  /// Get current endpoint URL (full URL for display)
  String get endpointUrl => '$_baseUrl/api/v1/$_deviceToken/telemetry';

  /// Initialize the cloud service
  Future<void> init() async {
    if (_isInitialized) return;

    await _loadConfig();
    await _queue.init();

    // Listen for connectivity changes to auto-flush
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    // Attempt initial flush logic only if configured
    if (_isConfigured) {
      await flushQueue();
    }

    _isInitialized = true;
  }

  /// Check if cloud service is configured with valid credentials
  bool get _isConfigured => _baseUrl.isNotEmpty && _deviceToken.isNotEmpty;

  /// Load configuration from shared preferences
  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to hardcoded IP if not set
    _baseUrl = prefs.getString(_prefKeyBaseUrl) ?? 'http://200.13.5.20:8080';
    _deviceToken = prefs.getString(_prefKeyDeviceToken) ?? '';
  }

  /// Validate a candidate base URL against the http allowlist.
  /// Returns null when valid, otherwise a human-readable error message.
  static String? validateBaseUrl(String baseUrl) {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || uri.host.isEmpty) {
      return 'Invalid base URL';
    }
    if (uri.scheme == 'http' && !_allowedHttpHosts.contains(uri.host)) {
      return 'Plain http is only allowed for the default server; use https for other hosts';
    }
    return null;
  }

  /// Update cloud configuration
  Future<void> updateConfig({String? baseUrl, String? deviceToken}) async {
    if (baseUrl != null) {
      final error = validateBaseUrl(baseUrl);
      if (error != null) {
        throw ArgumentError(error);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    if (baseUrl != null) {
      _baseUrl = baseUrl;
      await prefs.setString(_prefKeyBaseUrl, baseUrl);
    }
    if (deviceToken != null) {
      _deviceToken = deviceToken;
      await prefs.setString(_prefKeyDeviceToken, deviceToken);
    }
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(ConnectivityResult result) {
    final hasConnection = result != ConnectivityResult.none;
    if (hasConnection && !_queue.isEmpty && _isConfigured) {
      flushQueue();
    }
  }

  /// Log an event to be sent to the cloud
  Future<void> logEvent(String eventType, Map<String, dynamic> payload, {DateTime? timestamp}) async {
    // Ignore if not configured, but log for debugging
    if (!_isConfigured) {
      print('[CloudService] Dropping event "$eventType": cloud service not configured');
      return;
    }

    final event = CloudEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: timestamp ?? DateTime.now(),
      eventType: eventType,
      payload: payload,
    );

    await _queue.enqueue(event);

    // Try to flush immediately if we have connectivity
    final connectivity = await _connectivity.checkConnectivity();
    final hasConnection = connectivity != ConnectivityResult.none;
    if (hasConnection) {
      flushQueue();
    }
  }

  /// Flush all queued events to the cloud
  Future<void> flushQueue() async {
    if (_isFlushing || _queue.isEmpty || !_isConfigured) return;
    _isFlushing = true;

    try {
      final events = _queue.getAll();
      final keysToRemove = <String>[];

      for (final event in events) {
        final success = await _sendEvent(event);
        if (success) {
          keysToRemove.add(event.id);
        } else {
          // Increment retry count
          event.retryCount++;
          if (event.retryCount >= 5) {
            // Drop after 5 failed attempts
            keysToRemove.add(event.id);
            print('CloudService: Dropping event ${event.id} after 5 retries');
          } else {
            await _queue.update(event);
          }
          // Stop on first failure to preserve order
          break;
        }
      }

      if (keysToRemove.isNotEmpty) {
        await _queue.removeAll(keysToRemove);
      }
    } finally {
      _isFlushing = false;
    }
  }

  /// Send a single event to ThingsBoard
  Future<bool> _sendEvent(CloudEvent event) async {
    if (!_isConfigured) return false;
    
    try {
      final url = Uri.parse('$_baseUrl/api/v1/$_deviceToken/telemetry');

      // eventId is derived from eventType + timestamp, both of which are
      // persisted on the queued CloudEvent and untouched by retries (only
      // retryCount is mutated), so it stays stable across retries without
      // needing a dedicated queue field.
      final tsMs = event.timestamp.millisecondsSinceEpoch;
      final eventId = '${event.eventType}-$tsMs';

      final body = jsonEncode({
        'ts': tsMs,
        'values': {
          'payload': {
            'eventId': eventId,
            'eventType': event.eventType,
            ...event.payload,
          },
        },
      });

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('CloudService: Sent event ${event.eventType}');
        return true;
      } else {
        print('CloudService: Failed to send event: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('CloudService: Error sending event: $e');
      return false;
    }
  }

  /// Get current queue size (for debugging/UI)
  int get pendingEventCount => _queue.count;

  /// Number of events queued in the native (Kotlin) cloud queue.
  /// Returns 0 if the native service isn't running or the call fails.
  Future<int> nativeQueueCount() async {
    try {
      final count = await _nativeChannel.invokeMethod<int>('getCloudQueueCount');
      return count ?? 0;
    } catch (e) {
      print('CloudService: nativeQueueCount failed: $e');
      return 0;
    }
  }

  /// Epoch ms of the last successful native cloud POST, 0 if none/unavailable.
  Future<int> lastNativeSync() async {
    try {
      final ts = await _nativeChannel.invokeMethod<int>('getLastCloudSync');
      return ts ?? 0;
    } catch (e) {
      print('CloudService: lastNativeSync failed: $e');
      return 0;
    }
  }

  /// Last native cloud sync error text, '' if none/unavailable.
  Future<String> lastNativeError() async {
    try {
      final err = await _nativeChannel.invokeMethod<String>('getLastCloudError');
      return err ?? '';
    } catch (e) {
      print('CloudService: lastNativeError failed: $e');
      return '';
    }
  }

  /// Trigger a flush of the native cloud queue.
  Future<void> flushNativeQueue() async {
    try {
      await _nativeChannel.invokeMethod('flushCloudQueue');
    } catch (e) {
      print('CloudService: flushNativeQueue failed: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
