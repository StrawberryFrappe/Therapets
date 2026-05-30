import 'mission.dart';

/// Mission: Stay synced for a specific duration (in seconds).

class SyncDurationMission extends Mission {
  @override
  final String id = 'mission_sync_duration';

  final double targetDuration; // seconds

  double _currentDuration = 0.0;

  SyncDurationMission({
    required this.targetDuration,
    required this.goldReward,
    this.happinessReward = 0.05,
  });

  @override
  final int goldReward;
  @override
  final double happinessReward;

  double _progress = 0.0;

  bool _isClaimed = false;

  @override
  double get progress => _progress;
  @override
  set progress(double value) => _progress = value;
  @override
  bool get isCompleted => _progress >= 1.0;
  @override
  bool get isClaimed => _isClaimed;
  @override
  void markClaimed() => _isClaimed = true;
  @override
  void reset() {
    _progress = 0.0;
    _isClaimed = false;
    _currentDuration = 0.0;
  }

  @override
  void restoreState(double savedProgress, bool claimed) {
    _progress = savedProgress;
    _isClaimed = claimed;
  }

  @override
  String get title => 'Sync Master';

  @override
  String get description =>
      'Stay synced for ${(targetDuration / 60).ceil()} minutes today.';

  @override
  num get currentValue => (_currentDuration / 60).floor();

  @override
  num get targetValue => (targetDuration / 60).ceil();

  @override
  String get valueUnit => 'min';

  @override
  bool update(MissionContext ctx) {
    if (isCompleted || ctx.isDeviceSynced != true || ctx.dt == null)
      return false;

    double previousDuration = _currentDuration;
    _currentDuration += ctx.dt!;

    int prevMinutes = (previousDuration / 60).floor();
    int currMinutes = (_currentDuration / 60).floor();

    if (currMinutes > prevMinutes || _currentDuration >= targetDuration) {
      if (_currentDuration >= targetDuration) {
        progress = 1.0;
      } else {
        progress = (currMinutes / targetValue).clamp(0.0, 1.0);
      }
      return isCompleted && previousDuration < targetDuration;
    }

    // Also handle initial state loading or restoration where it should be updated but isn't passing a minute boundary
    if (progress == 0 && _currentDuration > 0) {
      progress = (currMinutes / targetValue).clamp(0.0, 1.0);
    }

    return false;
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'sync_duration',
    'targetDuration': targetDuration,
    'currentDuration': _currentDuration,
    'rewardGold': goldReward,
    'rewardHappiness': happinessReward,
    'progress': progress,
    'claimed': isClaimed,
  };

  factory SyncDurationMission.fromJson(Map<String, dynamic> json) {
    final mission = SyncDurationMission(
      targetDuration: (json['targetDuration'] as num).toDouble(),
      goldReward: json['rewardGold'] as int,
      happinessReward: (json['rewardHappiness'] as num?)?.toDouble() ?? 0.05,
    );
    mission._currentDuration =
        (json['currentDuration'] as num?)?.toDouble() ?? 0.0;
    mission.restoreState(
      (json['progress'] as num?)?.toDouble() ?? 0.0,
      json['claimed'] as bool? ?? false,
    );
    // Ensure progress is synced with minute logic on load
    mission.progress = (mission.currentValue / mission.targetValue).clamp(
      0.0,
      1.0,
    );
    return mission;
  }
}

/// Mission: Play any minigame.

class MinigamePlayMission extends Mission {
  @override
  final String id = 'mission_minigame_play';

  final int targetPlays;

  int _currentPlays = 0;

  MinigamePlayMission({this.targetPlays = 1, required this.goldReward});

  @override
  final int goldReward;

  double _progress = 0.0;

  bool _isClaimed = false;

  @override
  double get progress => _progress;
  @override
  set progress(double value) => _progress = value;
  @override
  bool get isCompleted => _progress >= 1.0;
  @override
  bool get isClaimed => _isClaimed;
  @override
  void markClaimed() => _isClaimed = true;
  @override
  void reset() {
    _progress = 0.0;
    _isClaimed = false;
    _currentPlays = 0;
  }

  @override
  void restoreState(double savedProgress, bool claimed) {
    _progress = savedProgress;
    _isClaimed = claimed;
  }

  @override
  double get happinessReward => 0.1;

  @override
  String get title => 'Game Time';

  @override
  String get description => 'Play any minigame $targetPlays time(s).';

  @override
  num get currentValue => _currentPlays;

  @override
  num get targetValue => targetPlays;

  @override
  bool update(MissionContext ctx) {
    if (isCompleted || ctx.minigameId == null) return false;

    _currentPlays++;
    progress = (_currentPlays / targetPlays).clamp(0.0, 1.0);
    return isCompleted;
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'minigame_play',
    'targetPlays': targetPlays,
    'currentPlays': _currentPlays,
    'rewardGold': goldReward,
    'progress': progress,
    'claimed': isClaimed,
  };

  factory MinigamePlayMission.fromJson(Map<String, dynamic> json) {
    final mission = MinigamePlayMission(
      targetPlays: json['targetPlays'] as int,
      goldReward: json['rewardGold'] as int,
    );
    mission._currentPlays = json['currentPlays'] as int? ?? 0;
    mission.restoreState(
      (json['progress'] as num?)?.toDouble() ?? 0.0,
      json['claimed'] as bool? ?? false,
    );
    return mission;
  }
}

/// Mission: Feed the pet.

class FeedPetMission extends Mission {
  @override
  final String id = 'mission_feed_pet';

  final int targetFeeds;

  int _currentFeeds = 0;

  FeedPetMission({this.targetFeeds = 3, required this.goldReward});

  @override
  final int goldReward;

  double _progress = 0.0;

  bool _isClaimed = false;

  @override
  double get progress => _progress;
  @override
  set progress(double value) => _progress = value;
  @override
  bool get isCompleted => _progress >= 1.0;
  @override
  bool get isClaimed => _isClaimed;
  @override
  void markClaimed() => _isClaimed = true;
  @override
  void reset() {
    _progress = 0.0;
    _isClaimed = false;
    _currentFeeds = 0;
  }

  @override
  void restoreState(double savedProgress, bool claimed) {
    _progress = savedProgress;
    _isClaimed = claimed;
  }

  @override
  double get happinessReward => 0.05;

  @override
  String get title => 'Yummy Time';

  @override
  String get description => 'Feed your pet $targetFeeds times.';

  @override
  num get currentValue => _currentFeeds;

  @override
  num get targetValue => targetFeeds;

  @override
  bool update(MissionContext ctx) {
    if (isCompleted || ctx.foodId == null) return false;

    _currentFeeds++;
    progress = (_currentFeeds / targetFeeds).clamp(0.0, 1.0);
    return isCompleted;
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'feed_pet',
    'targetFeeds': targetFeeds,
    'currentFeeds': _currentFeeds,
    'rewardGold': goldReward,
    'progress': progress,
    'claimed': isClaimed,
  };

  factory FeedPetMission.fromJson(Map<String, dynamic> json) {
    final mission = FeedPetMission(
      targetFeeds: json['targetFeeds'] as int,
      goldReward: json['rewardGold'] as int,
    );
    mission._currentFeeds = json['currentFeeds'] as int? ?? 0;
    mission.restoreState(
      (json['progress'] as num?)?.toDouble() ?? 0.0,
      json['claimed'] as bool? ?? false,
    );
    return mission;
  }
}
