import 'dart:async';
import 'package:flutter/material.dart';
import 'package:Therapets/l10n/app_localizations.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../services/device/device_service.dart';
import '../../../services/device/bluetooth_service.dart' show ScanStatus;
import 'telemetry_terminal.dart';

/// A dialog for scanning and connecting to Bluetooth devices.
/// Shows a list of discovered devices when not connected, or a telemetry
/// terminal when connected.
class BluetoothScannerDialog extends StatefulWidget {
  final DeviceService device;
  final BluetoothDevice? connectedDevice;
  final String? persistedDeviceId;
  final VoidCallback onForget;
  final Future<void> Function(BluetoothDevice device) onConnect;
  const BluetoothScannerDialog({
    super.key,
    required this.device,
    required this.connectedDevice,
    required this.persistedDeviceId,
    required this.onForget,
    required this.onConnect,
  });

  @override
  State<BluetoothScannerDialog> createState() => _BluetoothScannerDialogState();
}

class _BluetoothScannerDialogState extends State<BluetoothScannerDialog> {
  bool _scanning = false;
  final Duration _scanTimeout = const Duration(seconds: 7);

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _stopScan();
    super.dispose();
  }

  Future<void> _startScan() async {
    if (_scanning) return;
    setState(() => _scanning = true);
    try {
      await widget.device.startScan(timeout: _scanTimeout);
    } catch (e) {
      debugPrint('startScan error: $e');
    }
  }

  /// Force a fresh scan even if a prior one left `_scanning` stuck true (e.g.
  /// the scan window elapsed with no results). Tapping the empty list calls
  /// this so the user is never stranded on "No devices found" with no retry.
  Future<void> _rescan() async {
    _scanning = false;
    await _startScan();
  }

  Future<void> _stopScan() async {
    try {
      await widget.device.stopScan();
    } catch (_) {}
    if (mounted) {
      setState(() => _scanning = false);
    }
  }

  String _statusMessage(ScanStatus status) {
    switch (status) {
      case ScanStatus.scanning:
        return 'Scanning for devices…';
      case ScanStatus.bluetoothOff:
        return 'Bluetooth is off. Turn it on and scan again.';
      case ScanStatus.permissionDenied:
        return 'Bluetooth permission denied. Grant Nearby devices / Location in system settings, then scan again.';
      case ScanStatus.error:
        return 'Scan failed. Tap scan to retry.';
      case ScanStatus.idle:
        return 'No devices found. Make sure the sensor is powered on and nearby, then scan again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(width: 2, color: Colors.black),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            const Text(
              'Scan for Devices',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Main content: terminal or scan results
            Expanded(
              child: widget.connectedDevice != null
                  ? TelemetryTerminal(device: widget.device, maxLines: 200)
                  : StreamBuilder<List<ScanResult>>(
                      stream: widget.device.foundDevices$,
                      builder: (ctx, snap) {
                        final found = snap.data ?? const [];
                        if (found.isEmpty) {
                          // Never show a silent empty list: surface why.
                          return StreamBuilder<ScanStatus>(
                            stream: widget.device.scanStatus$,
                            initialData: widget.device.scanStatus,
                            builder: (ctx2, ss) {
                              final status = ss.data ?? ScanStatus.idle;
                              final scanning = status == ScanStatus.scanning;
                              // The whole empty area is a rescan button: tap
                              // anywhere to retry. Disabled only while a scan is
                              // actively running.
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: scanning ? null : _rescan,
                                  splashColor: Colors.black26,
                                  highlightColor: Colors.black12,
                                  child: SizedBox.expand(
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (scanning)
                                              const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.black,
                                                    ),
                                              ),
                                            if (scanning)
                                              const SizedBox(height: 12),
                                            Text(
                                              _statusMessage(status),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                            ),
                                            if (!scanning) ...[
                                              const SizedBox(height: 12),
                                              const Text(
                                                'Tap anywhere to scan again',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }
                        return ListView.separated(
                          itemCount: found.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: Colors.black, thickness: 2),
                          itemBuilder: (ctx2, i) {
                            final r = found[i];
                            final idStr = r.device.remoteId.str;
                            final name = r.device.platformName.isNotEmpty
                                ? r.device.platformName
                                : idStr;
                            final shortId = idStr.length > 6
                                ? idStr.substring(idStr.length - 6)
                                : idStr;
                            return ListTile(
                              title: Text(
                                name,
                                style: const TextStyle(fontSize: 12),
                              ),
                              subtitle: Text(
                                'RSSI: ${r.rssi} dBm',
                                style: const TextStyle(fontSize: 10),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    width: 1,
                                    color: Colors.black,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  shortId,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              onTap: () async {
                                await _stopScan();
                                Navigator.of(context).pop();
                                await widget.onConnect(r.device);
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
            if (widget.connectedDevice != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: const BorderSide(width: 2, color: Colors.black),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onForget();
                },
                child: Text(
                  AppLocalizations.of(context)!.disconnectForget,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
