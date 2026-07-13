import 'dart:async';

import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

import '../../../services/device/device_service.dart';
import '../../game_settings.dart';
import '../donut/donut.dart';
import 'motion_calibrator.dart';

/// Full-screen overlay shown before the SBR game starts (when device is
/// connected) to calibrate the user's wrist tilt range.
///
/// Tap-to-confirm calibration logic:
/// Phase 1 – Left: user tilts wrist max left and taps.
/// Phase 2 – Right: user tilts wrist max right and taps.
///
/// The 3-D Donut is rendered behind the instructions so the user gets
/// immediate visual feedback that their movement is being tracked.
class CalibrationOverlay extends StatefulWidget {
  final DeviceService deviceService;
  final ValueChanged<MotionCalibrator> onCalibrationComplete;

  const CalibrationOverlay({
    super.key,
    required this.deviceService,
    required this.onCalibrationComplete,
  });

  @override
  State<CalibrationOverlay> createState() => _CalibrationOverlayState();
}

class _CalibrationOverlayState extends State<CalibrationOverlay> {
  final MotionCalibrator _calibrator = MotionCalibrator();
  StreamSubscription<TelemetryData>? _telemetrySub;

  double _latestRollAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _telemetrySub = widget.deviceService.telemetry$.listen(_onTelemetry);
    _calibrator.startLeftPhase();
  }

  @override
  void dispose() {
    _telemetrySub?.cancel();
    super.dispose();
  }

  void _onTelemetry(TelemetryData data) {
    _latestRollAngle = MotionCalibrator.rollFromTelemetry(
      data,
      handedness: GameSettings.sbrHandedness,
    );
  }

  void _handleTap() {
    setState(() {
      switch (_calibrator.state) {
        case CalibrationState.calibratingLeft:
          _calibrator.confirmLeft(_latestRollAngle);
          break;
        case CalibrationState.calibratingRight:
          if (!_calibrator.confirmRight(_latestRollAngle)) {
            // Calibration rejected due to narrow range, UI restarts naturally
            break;
          }
          _finishCalibration();
          break;
        default:
          break;
      }
    });
  }

  void _finishCalibration() {
    _telemetrySub?.cancel();
    widget.onCalibrationComplete(_calibrator);
  }
  
  String _getInstruction(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (_calibrator.state) {
      case CalibrationState.calibratingLeft:
        return loc.sbrCalibrationLeft;
      case CalibrationState.calibratingRight:
        return loc.sbrCalibrationRight;
      default:
        return '';
    }
  }

  /// Which reference pose matches each phase for the current handedness.
  ///
  /// The right-arm board is mirror-mounted: rotating the whole orthosis 180
  /// about the forearm's long axis puts the M5Stick back in the same
  /// position, so the pose that reaches a given sensor extreme is inverted
  /// (left-board palm-up ≡ right-board palm-down for the same reading) —
  /// confirmed by an on-device playtest. So the up/down asset pairing swaps
  /// per phase for `right`; the instruction text does not need to change,
  /// since "turn wrist max left/right" already means the same physical
  /// thing regardless of which board is worn.
  String _getImageAsset() {
    final isRight = GameSettings.sbrHandedness == Handedness.right;
    switch (_calibrator.state) {
      case CalibrationState.calibratingLeft:
        return isRight ? 'assets/images/armfacingdown.png' : 'assets/images/armfacingup.png';
      case CalibrationState.calibratingRight:
        return isRight ? 'assets/images/armfacingup.png' : 'assets/images/armfacingdown.png';
      default:
        return isRight ? 'assets/images/armfacingdown.png' : 'assets/images/armfacingup.png';
    }
  }

  /// 1-based step index for the current phase (Left = 1, Right = 2).
  int _getStepNumber() {
    switch (_calibrator.state) {
      case CalibrationState.calibratingRight:
        return 2;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // Plain dark background (donut is now a small corner indicator).
          const Positioned.fill(
            child: ColoredBox(color: Color(0xFF1A1A1A)),
          ),

          // Arm reference image from bottom — primary how-to cue, kept prominent.
          Positioned(
            bottom: -40,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.8,
                child: Transform(
                  alignment: Alignment.center,
                  // Base art depicts a left arm. Right-handed pose is
                  // already picked correctly by _getImageAsset(), but the
                  // pixels still need a horizontal flip so a real right arm
                  // doing that pose doesn't look like a mirrored left arm.
                  transform: Matrix4.diagonal3Values(
                    GameSettings.sbrHandedness == Handedness.right ? -1.0 : 1.0,
                    1.0,
                    1.0,
                  ),
                  child: Image.asset(
                    _getImageAsset(),
                    fit: BoxFit.contain,
                    height: MediaQuery.of(context).size.height * 0.4,
                  ),
                ),
              ),
            ),
          ),

          // Live 3-D donut: small tracking indicator pinned top-right.
          Positioned(
            top: 48,
            right: 20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 1.5),
                color: Colors.black26,
              ),
              clipBehavior: Clip.antiAlias,
              child: DonutGame(deviceService: widget.deviceService),
            ),
          ),

          // Structured instruction card.
          Align(
            alignment: const Alignment(0, -0.35),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 340),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    loc.sbrCalibrationStep(_getStepNumber(), 2),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getInstruction(context),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
