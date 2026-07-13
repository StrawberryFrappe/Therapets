import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Therapets/l10n/app_localizations.dart';

import '../../../screens/minigame_screen.dart';
import '../../../services/device/device_service.dart';
import '../../pets/pet_stats.dart';
import 'music_scale.dart';
import 'orchestra_game.dart';

/// Screen wrapper for the Orchestra minigame. All interactive chrome (title,
/// status hint, calibrate/lock/scale/octave/span controls, exit) lives here
/// as real Flutter widgets in a [MinigameScreen.overlay] — not hand-drawn in
/// the Flame canvas — so it gets [SafeArea] insets, proper touch targets,
/// theming and localization for free. The Flame layer underneath only draws
/// the stage: background, the pitch cursor, and the singing pets.
class OrchestraScreen extends StatefulWidget {
  final DeviceService deviceService;
  final PetStats petStats;
  final bool isDeviceConnected;

  const OrchestraScreen({
    super.key,
    required this.deviceService,
    required this.petStats,
    this.isDeviceConnected = false,
  });

  @override
  State<OrchestraScreen> createState() => _OrchestraScreenState();
}

class _OrchestraScreenState extends State<OrchestraScreen> {
  late final OrchestraGame _game;

  @override
  void initState() {
    super.initState();

    _game = OrchestraGame(
      deviceService: widget.deviceService,
      petStats: widget.petStats,
      isDeviceConnected: widget.isDeviceConnected,
      onExit: () {
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MinigameScreen(
      config: const MinigameConfig(
        title: 'Pet Theremin',
        keepScreenOn: true,
        forcedOrientations: [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
      ),
      gameWidget: GameWidget(game: _game),
      overlay: SafeArea(child: _OrchestraHud(game: _game)),
      onDispose: () {
        // Force cleanup of game audio before disposing
        _game.cleanup();
      },
    );
  }
}

/// The overlay HUD: top bar (exit + title), centered status hint, and a
/// bottom control bar. Only the pieces that actually change (status hint,
/// bottom bar labels) rebuild, driven by [OrchestraGame.uiRevision].
class _OrchestraHud extends StatelessWidget {
  final OrchestraGame game;

  const _OrchestraHud({required this.game});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 8,
          left: 8,
          child: _TopBar(game: game),
        ),
        Positioned(
          top: 8,
          left: 0,
          right: 0,
          child: Center(
            child: ValueListenableBuilder<int>(
              valueListenable: game.uiRevision,
              builder: (context, _, __) => _StatusHint(status: game.status),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          left: 0,
          right: 0,
          child: Center(
            child: ValueListenableBuilder<int>(
              valueListenable: game.uiRevision,
              builder: (context, _, __) => _ControlBar(game: game),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final OrchestraGame game;

  const _TopBar({required this.game});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HudCard(
          child: IconButton(
            icon: const Icon(Icons.close),
            color: Colors.black87,
            tooltip: l10n.exit,
            onPressed: game.exitGame,
          ),
        ),
        const SizedBox(width: 8),
        _HudCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            l10n.gameOrchestra,
            style: const TextStyle(
              fontFamily: 'Monocraft',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusHint extends StatelessWidget {
  final OrchestraStatus? status;

  const _StatusHint({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final text = switch (status!) {
      OrchestraStatus.noDevice => l10n.orchestraHintNoDevice,
      OrchestraStatus.signalLost => l10n.orchestraHintSignalLost,
      OrchestraStatus.calibrating => l10n.orchestraHintCalibrating,
    };
    return _HudCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  final OrchestraGame game;

  const _ControlBar({required this.game});

  String _scaleLabel(AppLocalizations l10n) {
    switch (game.scaleType) {
      case ScaleType.pentatonic:
        return l10n.orchestraScalePentatonic;
      case ScaleType.diatonic:
        return l10n.orchestraScaleDiatonic;
      case ScaleType.chromatic:
        return l10n.orchestraScaleChromatic;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _HudCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FilledButton.tonal(
            onPressed: game.calibrate,
            child: Text(l10n.orchestraCalibrate),
          ),
          FilledButton.tonal(
            onPressed: game.isCalibrated ? game.toggleLock : null,
            child: Text(game.pitchLocked ? l10n.orchestraLocked : l10n.orchestraLock),
          ),
          OutlinedButton(
            onPressed: game.cycleScale,
            child: Text(_scaleLabel(l10n)),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward),
            tooltip: l10n.orchestraOctaveDown,
            onPressed: () => game.shiftOctave(-1),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_upward),
            tooltip: l10n.orchestraOctaveUp,
            onPressed: () => game.shiftOctave(1),
          ),
          OutlinedButton(
            onPressed: game.cycleSpan,
            child: Text(l10n.orchestraSpanLabel(game.spanOctaves)),
          ),
        ],
      ),
    );
  }
}

/// Shared translucent light card so HUD pieces read clearly over the stage
/// without going full-opaque and hiding the gameplay behind them.
class _HudCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const _HudCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );
  }
}
