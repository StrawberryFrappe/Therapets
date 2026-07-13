import 'dart:async';

import 'package:flutter/material.dart';
import 'package:Therapets/l10n/app_localizations.dart';
import '../../../services/cloud/cloud_service.dart';

/// Cloud Sync settings section.
///
/// Displays the NATIVE (Kotlin) cloud queue state — the native side is the
/// sole telemetry publisher now, so this reads via CloudService's
/// MethodChannel bridge rather than the (now unused) Dart-side queue.
class CloudSyncSection extends StatefulWidget {
  final CloudService cloud;
  final String baseUrl;
  final String deviceToken;
  final VoidCallback onConfigure;
  final VoidCallback onFlushQueue;

  const CloudSyncSection({
    super.key,
    required this.cloud,
    required this.baseUrl,
    required this.deviceToken,
    required this.onConfigure,
    required this.onFlushQueue,
  });

  @override
  State<CloudSyncSection> createState() => _CloudSyncSectionState();
}

class _CloudSyncSectionState extends State<CloudSyncSection> {
  int _queueCount = 0;
  int _lastSyncMs = 0;
  String _lastError = '';
  bool _flushing = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _refresh();
    // Native queue can change in the background (auto-flush), so poll it
    // periodically rather than only on manual refresh.
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final count = await widget.cloud.nativeQueueCount();
    final lastSync = await widget.cloud.lastNativeSync();
    final lastError = await widget.cloud.lastNativeError();
    if (!mounted) return;
    setState(() {
      _queueCount = count;
      _lastSyncMs = lastSync;
      _lastError = lastError;
    });
  }

  Future<void> _handleFlush() async {
    if (_flushing) return;
    setState(() => _flushing = true);
    await widget.cloud.flushNativeQueue();
    widget.onFlushQueue();
    await _refresh();
    if (!mounted) return;
    setState(() => _flushing = false);
  }

  String _formatLastSync() {
    if (_lastSyncMs == 0) return AppLocalizations.of(context)!.notSet;
    final dt = DateTime.fromMillisecondsSinceEpoch(_lastSyncMs);
    return dt.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(width: 2, color: Colors.purple),
        color: Colors.purple.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.cloudSync, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text(AppLocalizations.of(context)!.pending(_queueCount),
                style: const TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border.all(width: 1, color: Colors.black26),
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.baseUrlLabel, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                Text(widget.baseUrl.isEmpty ? AppLocalizations.of(context)!.notSet : widget.baseUrl,
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(AppLocalizations.of(context)!.deviceTokenLabel, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                Text(widget.deviceToken.isEmpty ? AppLocalizations.of(context)!.notSet : widget.deviceToken,
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Text('Last sync:', style: TextStyle(fontSize: 9, color: Colors.grey)),
                Text(_formatLastSync(),
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Text('Last error:', style: TextStyle(fontSize: 9, color: Colors.grey)),
                Text(_lastError.isEmpty ? '-' : _lastError,
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade100,
                    foregroundColor: Colors.black,
                    side: const BorderSide(width: 1, color: Colors.black),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  onPressed: widget.onConfigure,
                  child: Text(AppLocalizations.of(context)!.configure, style: const TextStyle(fontSize: 9)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade100,
                    foregroundColor: Colors.black,
                    side: const BorderSide(width: 1, color: Colors.black),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  onPressed: _flushing ? null : _handleFlush,
                  child: Text(AppLocalizations.of(context)!.flushQueue, style: const TextStyle(fontSize: 9)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
