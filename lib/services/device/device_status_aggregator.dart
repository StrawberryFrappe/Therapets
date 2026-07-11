import 'dart:async';
import 'dart:collection';

import 'device_service.dart';
import 'presence_profile.dart';

/// Aggregates raw device signals into high-level display status.
/// Handles grace periods, debouncing, and human detection history.
class DeviceStatusAggregator {
  final DeviceDisplayStatus Function() _baseStatusProvider;
  final DeviceDisplayStatus Function() _staleStatusProvider;
  final bool Function() _isHumanDetectedProvider;
  final bool Function() _isMinigameRunningProvider;
  final bool Function() _hasRecentTelemetryProvider;

  // Configuration — duty-cycle tuning. Defaults to always-on (strict).
  PresenceProfile _profile;
  set profile(PresenceProfile p) => _profile = p;
  Duration get _syncGracePeriod => _profile.graceWindow;
  int get _noHumanDebounceThreshold => _profile.noHumanDebounce;

  // State
  Timer? _syncGraceTimer;
  bool _inSyncGracePeriod = false;
  bool _wasHumanDetected = false;
  int _consecutiveNoHumanSamples = 0;
  final Queue<bool> _humanDetectionHistory = Queue<bool>();
  Timer? _historyTimer;

  final StreamController<DeviceDisplayStatus> _statusController = StreamController.broadcast();
  Stream<DeviceDisplayStatus> get status$ => _statusController.stream;

  DeviceDisplayStatus? _lastEmittedStatus;

  DeviceStatusAggregator({
    required DeviceDisplayStatus Function() baseStatusProvider,
    required DeviceDisplayStatus Function() staleStatusProvider,
    required bool Function() isHumanDetectedProvider,
    required bool Function() isMinigameRunningProvider,
    required bool Function() hasRecentTelemetryProvider,
    PresenceProfile? profile,
  })  : _baseStatusProvider = baseStatusProvider,
        _staleStatusProvider = staleStatusProvider,
        _isHumanDetectedProvider = isHumanDetectedProvider,
        _isMinigameRunningProvider = isMinigameRunningProvider,
        _hasRecentTelemetryProvider = hasRecentTelemetryProvider,
        _profile = profile ?? const PresenceProfile.alwaysOn() {
    _startHistoryTimer();
  }

  int _staleSeconds = 0;
  bool _lastRecordedState = false;

  void _startHistoryTimer() {
    _historyTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_hasRecentTelemetryProvider()) {
        _staleSeconds = 0;
        bool currentState = _isHumanDetectedProvider();
        
        // During grace period, use the last-known-good state to bridge IoT sleep gaps
        bool stateToRecord = _inSyncGracePeriod ? _lastRecordedState : currentState;
        _humanDetectionHistory.addLast(stateToRecord);

        // Update last recorded state ONLY when not in grace period
        if (!_inSyncGracePeriod) {
          _lastRecordedState = currentState;
        }
        if (_humanDetectionHistory.length > 60) {
          _humanDetectionHistory.removeFirst();
        }
        update();
      } else if (_humanDetectionHistory.isNotEmpty) {
        _staleSeconds++;
        // Case 3: Device Disconnects (BLE drops) -> Freeze history for 30s
        if (_staleSeconds > 30) {
          _humanDetectionHistory.clear();
        }
        update();
      }
    });
  }

  DeviceDisplayStatus get currentDisplayStatus {
    final base = _baseStatusProvider();
    if (base != DeviceDisplayStatus.connected && base != DeviceDisplayStatus.synced) {
      return base;
    }

    if (!_hasRecentTelemetryProvider()) {
      return _staleStatusProvider();
    }

    final humanDetectedReal = _isHumanDetectedProvider();
    final isDebouncing = _wasHumanDetected && !_inSyncGracePeriod && _consecutiveNoHumanSamples < _noHumanDebounceThreshold;
    final humanDetected = humanDetectedReal || isDebouncing;

    // History "barrage" vote bridges duty-cycle blackouts (lenient). When the
    // profile disables it (always-on/strict), key sync off the live reading —
    // the history would otherwise stay 100% true even when the device is off-body.
    bool barrageMet;
    if (_profile.barrageRatio == null) {
      barrageMet = true;
    } else {
      final activeSeconds = _humanDetectionHistory.where((detected) => detected).length;
      final windowSize = _humanDetectionHistory.length;
      final requiredSeconds = windowSize > 0 ? (windowSize * _profile.barrageRatio!).round() : 0;
      barrageMet = activeSeconds >= requiredSeconds;
    }

    if (_isMinigameRunningProvider() || (barrageMet && (humanDetected || (_inSyncGracePeriod && _wasHumanDetected)))) {
      return DeviceDisplayStatus.synced;
    }
    return DeviceDisplayStatus.connected;
  }

  void handleHumanDetectionChange(bool detected) {
    if (detected) {
      _syncGraceTimer?.cancel();
      _inSyncGracePeriod = false;
      _consecutiveNoHumanSamples = 0;
      _wasHumanDetected = true;
      update();
    } else {
      _consecutiveNoHumanSamples++;
      if (_wasHumanDetected && !_inSyncGracePeriod) {
        if (_consecutiveNoHumanSamples >= _noHumanDebounceThreshold) {
          _inSyncGracePeriod = true;
          _syncGraceTimer?.cancel();
          _syncGraceTimer = Timer(_syncGracePeriod, () {
            _inSyncGracePeriod = false;
            _wasHumanDetected = false;
            update();
          });
        }
      } else if (!_wasHumanDetected) {
        update();
      }
    }
  }

  void update() {
    final status = currentDisplayStatus;
    if (_lastEmittedStatus != status) {
      _lastEmittedStatus = status;
      _statusController.add(status);
    }
  }

  void reset() {
    _lastEmittedStatus = null;
    _inSyncGracePeriod = false;
    _wasHumanDetected = false;
    _consecutiveNoHumanSamples = 0;
    _humanDetectionHistory.clear();
    _syncGraceTimer?.cancel();
    _syncGraceTimer = null;
    _staleSeconds = 0;
    _lastRecordedState = false;
  }

  void dispose() {
    _syncGraceTimer?.cancel();
    _historyTimer?.cancel();
    _statusController.close();
  }
}
