import '../../../l10n/app_localizations.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../services/device/device_service.dart';
import '../../pets/pet_stats.dart';

import 'calibration_overlay.dart';
import 'motion_calibrator.dart';
import 'sbr_difficulty.dart';
import 'sbr_game.dart';

class SBRScreen extends StatefulWidget {
  final DeviceService deviceService;
  final PetStats petStats;
  final bool isDeviceConnected;
  final VoidCallback onGameOver;
  
  const SBRScreen({
    super.key,
    required this.deviceService,
    required this.petStats,
    required this.isDeviceConnected,
    required this.onGameOver,
  });

  @override
  State<SBRScreen> createState() => _SBRScreenState();
}

class _SBRScreenState extends State<SBRScreen> {
  SBRGame? _game;
  bool _calibrated = false;
  bool _showTitleScreen = true;
  SbrDifficulty _selectedDifficulty = SbrDifficulty.medium;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    widget.deviceService.registerMinigameStart();
    _loadDifficulty();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    widget.deviceService.registerMinigameEnd();
    super.dispose();
  }

  Future<void> _loadDifficulty() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('sbr_difficulty') ?? 'medium';
    if (!mounted) return;
    setState(() {
      _selectedDifficulty = SbrDifficulty.values.firstWhere(
        (d) => d.name == saved,
        orElse: () => SbrDifficulty.medium,
      );
    });
  }

  Future<void> _saveDifficulty(SbrDifficulty difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sbr_difficulty', difficulty.name);
  }

  SbrDifficultyConfig get _config =>
      SbrDifficultyConfig.presets[_selectedDifficulty]!;

  void _startGame() {
    setState(() {
      _showTitleScreen = false;
      _game = SBRGame(
        deviceService: widget.deviceService,
        petStats: widget.petStats,
        isDeviceConnected: widget.isDeviceConnected,
        difficultyConfig: _config,
        onGameOver: widget.onGameOver,
        onStateChanged: () {
          Future.microtask(() {
            if (mounted) setState(() {});
          });
        },
      );

      // If no device connected, skip calibration
      if (!widget.isDeviceConnected) {
        _calibrated = true;
      }
    });
  }

  void _onCalibrationComplete(MotionCalibrator calibrator) {
    setState(() {
      _calibrated = true;
      _game!.calibrator = calibrator;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Difficulty / start screen shown before the game is built.
    if (_showTitleScreen) return _buildTitleScreen(context);

    if (_game == null) return const Center(child: CircularProgressIndicator());

    // Show calibration overlay before the game if device is connected
    if (!_calibrated) {
      return CalibrationOverlay(
        deviceService: widget.deviceService,
        onCalibrationComplete: _onCalibrationComplete,
      );
    }
    
    return Stack(
      children: [
        // Game Engine
        GameWidget(game: _game!),
        
        // HUD Overlay
        Positioned(
          top: 40,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left HUD: Combo, Lives
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: ValueNotifier(_game!.combo), // Need to notify this properly, use stream or rebuild
                    builder: (context, combo, child) {
                      return Text(AppLocalizations.of(context)!.sbrCombo(_game!.combo), style: _hudStyle());
                    },
                  ),
                  Text(AppLocalizations.of(context)!.sbrLevel(_game!.currentLevel), style: _hudStyle()),
                ],
              ),
              
              // Right HUD: Score
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(AppLocalizations.of(context)!.scoreLabel(_game!.score), style: _hudStyle()),
                  Text(AppLocalizations.of(context)!.sbrLives(_game!.lives), style: _hudStyle(color: Colors.redAccent)),
                ],
              ),
            ],
          ),
        ),
        
        // Start Overlay
        if (!_game!.hasStarted && !_game!.isGameOver)
          Center(
            child: Text(
              AppLocalizations.of(context)!.sbrTapToStart,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(offset: Offset(2, 2), blurRadius: 4)],
              ),
            ),
          ),
          
        // Game Over Overlay
        if (_game!.isGameOver)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.gameOver,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(offset: Offset(2, 2), blurRadius: 4)],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.scoreLabel(_game!.score),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    shadows: [Shadow(offset: Offset(2, 2), blurRadius: 4)],
                  ),
                ),
              ],
            ),
          )
      ],
    );
  }
  
  TextStyle _hudStyle({Color color = Colors.white}) {
    return TextStyle(
      color: color,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      shadows: const [Shadow(offset: Offset(2, 2), blurRadius: 4, color: Colors.black)],
    );
  }

  String _difficultyLabel(SbrDifficulty d) {
    final l10n = AppLocalizations.of(context)!;
    switch (d) {
      case SbrDifficulty.easy:
        return l10n.difficultyEasy;
      case SbrDifficulty.medium:
        return l10n.difficultyMedium;
      case SbrDifficulty.hard:
        return l10n.difficultyHard;
      case SbrDifficulty.extreme:
        return l10n.difficultyExtreme;
    }
  }

  Widget _buildTitleScreen(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: const Color(0xFF222222),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(width: 2, color: Colors.white24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.gameSbr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Difficulty selector (numbered 1-4 per FACTORY young-player note).
              Text(
                _difficultyLabel(_selectedDifficulty),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<SbrDifficulty>(
                segments: const [
                  ButtonSegment<SbrDifficulty>(
                    value: SbrDifficulty.easy,
                    icon: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Icon(Icons.star, size: 16),
                    ),
                  ),
                  ButtonSegment<SbrDifficulty>(
                    value: SbrDifficulty.medium,
                    icon: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.star, size: 16), Icon(Icons.star, size: 16)]),
                    ),
                  ),
                  ButtonSegment<SbrDifficulty>(
                    value: SbrDifficulty.hard,
                    icon: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.star, size: 16), Icon(Icons.star, size: 16), Icon(Icons.star, size: 16)]),
                    ),
                  ),
                  ButtonSegment<SbrDifficulty>(
                    value: SbrDifficulty.extreme,
                    icon: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 0),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.dangerous, size: 16), Icon(Icons.dangerous, size: 16), Icon(Icons.dangerous, size: 16), Icon(Icons.dangerous, size: 16)]),
                    ),
                  ),
                ],
                selected: {_selectedDifficulty},
                onSelectionChanged: (selection) {
                  setState(() => _selectedDifficulty = selection.first);
                  _saveDifficulty(selection.first);
                },
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                showSelectedIcon: false,
              ),

              const SizedBox(height: 24),

              // Start button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  side: const BorderSide(width: 2, color: Colors.black),
                ),
                onPressed: _startGame,
                child: Text(
                  l10n.start,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  l10n.back,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
