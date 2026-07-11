import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum TreatmentFetchState { notFetched, loading, success, error }

class Treatment {
  final int id;
  final String title;
  final String description;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final int usageTimeSeconds; // daily quota, confirmed by owner
  final int patientUsageTimeSeconds; // today's usage so far, confirmed by owner
  final List<String> enabledGames;

  Treatment({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.usageTimeSeconds,
    required this.patientUsageTimeSeconds,
    required this.enabledGames,
  });

  factory Treatment.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());
    return Treatment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      startDate: parseDate(json['start_date']),
      endDate: parseDate(json['end_date']),
      status: json['status']?.toString() ?? '',
      usageTimeSeconds: (json['usage_time'] as num?)?.toInt() ?? 0,
      patientUsageTimeSeconds: (json['patient_usage_time'] as num?)?.toInt() ?? 0,
      enabledGames: (json['enabled_games'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'status': status,
        'usage_time': usageTimeSeconds,
        'patient_usage_time': patientUsageTimeSeconds,
        'enabled_games': enabledGames,
      };
}

/// Fetches the patient's active treatment (prescribed minigames + usage
/// target) from the professional's backend. Read-only — there's no
/// write-back endpoint; progress is assumed to be derived server-side from
/// the sync_status telemetry the app already sends.
class TreatmentService {
  static final TreatmentService _instance = TreatmentService._internal();
  factory TreatmentService() => _instance;
  TreatmentService._internal();

  // Separate host from the ThingsBoard cloud-telemetry relay in CloudService —
  // distinct backend, but confirmed to use the same cloud_device_token value.
  static const String _baseUrl = 'http://200.13.5.19:3000';
  static const String _prefKeyDeviceToken = 'cloud_device_token';
  static const String _cacheKey = 'treatment_cache_json';
  static const Duration _minRefreshInterval = Duration(minutes: 15);

  // Backend's display-name vocabulary doesn't match our internal game ids.
  static const Map<String, String> _backendToInternalId = {
    'donut': 'donut',
    'flappy bob': 'flappy_bird',
    'orchestra': 'orchestra',
    'block breaker': 'sbr',
  };

  final ValueNotifier<Treatment?> treatmentNotifier = ValueNotifier(null);
  final ValueNotifier<TreatmentFetchState> fetchStateNotifier =
      ValueNotifier(TreatmentFetchState.notFetched);

  DateTime? _lastSuccessfulFetch;

  /// Loads any cached treatment from disk. Never touches the network —
  /// safe to await during app bootstrap without risking a stalled launch.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        treatmentNotifier.value =
            Treatment.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[TreatmentService] Failed to load cache: $e');
    }
  }

  /// Fetches the current treatment from the backend. Throttled — skips the
  /// network call if the last successful fetch was recent, unless [force].
  Future<void> refresh({bool force = false}) async {
    if (!force &&
        _lastSuccessfulFetch != null &&
        DateTime.now().difference(_lastSuccessfulFetch!) < _minRefreshInterval) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceToken = prefs.getString(_prefKeyDeviceToken) ?? '';
      if (deviceToken.isEmpty) {
        // No token yet — leave whatever's cached in place.
        return;
      }

      fetchStateNotifier.value = TreatmentFetchState.loading;
      final url = Uri.parse('$_baseUrl/patients/treatment/by-device-token/$deviceToken');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final treatment = Treatment.fromJson(json);
        treatmentNotifier.value = treatment;
        fetchStateNotifier.value = TreatmentFetchState.success;
        _lastSuccessfulFetch = DateTime.now();
        // Cache-write failures shouldn't downgrade a genuinely successful fetch
        // to an error state — the in-memory notifiers above are already correct.
        try {
          await prefs.setString(_cacheKey, jsonEncode(treatment.toJson()));
        } catch (e) {
          debugPrint('[TreatmentService] Failed to persist cache: $e');
        }
      } else {
        fetchStateNotifier.value = TreatmentFetchState.error;
      }
    } catch (e) {
      debugPrint('[TreatmentService] refresh failed: $e');
      fetchStateNotifier.value = TreatmentFetchState.error;
    }
  }

  /// Maps backend `enabled_games` entries to internal game ids. Unrecognized
  /// or blank entries are dropped silently (logged) rather than crashing the
  /// filter — forward-compatible with backend typos or unseen game names.
  Set<String> _mapEnabledGames(List<String> backendNames) {
    final result = <String>{};
    for (final raw in backendNames) {
      final key = raw.trim().toLowerCase();
      if (key.isEmpty) continue;
      final id = _backendToInternalId[key];
      if (id == null) {
        debugPrint('[TreatmentService] Unrecognized game name from backend: "$raw"');
        continue;
      }
      result.add(id);
    }
    return result;
  }

  /// The game-id filter to apply to the game menu.
  /// - `null` = no filter, show every game (fail-open: no data yet, network
  ///   error, no token, or an empty/unrecognized enabled_games list).
  /// - empty set = show nothing (fail-closed: the backend positively
  ///   confirmed the treatment isn't active right now).
  /// - non-empty set = the prescribed games.
  Set<String>? get effectiveEnabledGameIds {
    final treatment = treatmentNotifier.value;
    if (treatment == null) return null;

    if (treatment.status.isNotEmpty && treatment.status != 'active') {
      return <String>{};
    }

    final mapped = _mapEnabledGames(treatment.enabledGames);
    if (mapped.isEmpty) return null;
    return mapped;
  }
}
