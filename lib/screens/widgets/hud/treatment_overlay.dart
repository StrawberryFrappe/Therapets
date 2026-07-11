import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/treatment/treatment_service.dart';

/// HUD badge showing the patient's active treatment (if any) and usage
/// progress. Stays invisible when there's no treatment data yet, rather than
/// showing an empty/broken card.
class TreatmentOverlay extends StatefulWidget {
  const TreatmentOverlay({super.key});

  @override
  State<TreatmentOverlay> createState() => _TreatmentOverlayState();
}

class _TreatmentOverlayState extends State<TreatmentOverlay>
    with SingleTickerProviderStateMixin {
  late TreatmentService _service;
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _service = context.read<TreatmentService>();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '${h}h ${m}m';
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '?';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Treatment?>(
      valueListenable: _service.treatmentNotifier,
      builder: (context, treatment, _) {
        if (treatment == null) return const SizedBox.shrink();

        final progress = treatment.usageTimeSeconds > 0
            ? (treatment.patientUsageTimeSeconds / treatment.usageTimeSeconds).clamp(0.0, 1.0)
            : 0.0;

        return TapRegion(
          onTapOutside: (_) {
            if (_isExpanded) _toggleExpanded();
          },
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              GestureDetector(
                onTap: _toggleExpanded,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xE6FFFFFF),
                    shape: BoxShape.circle,
                    border: Border.all(width: 2, color: Colors.black),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 2,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                        ),
                      ),
                      const Icon(Icons.medical_services, size: 14, color: Colors.black),
                    ],
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Visibility(
                    visible: _controller.status != AnimationStatus.dismissed,
                    child: child!,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    alignment: Alignment.topRight,
                    child: Container(
                      width: 260,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(width: 2, color: Colors.black),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            treatment.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const Divider(thickness: 2),
                          if (treatment.description.isNotEmpty) ...[
                            Text(
                              treatment.description,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            '${_formatDate(treatment.startDate)} — ${_formatDate(treatment.endDate)}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text('Status: ${treatment.status}', style: const TextStyle(fontSize: 11)),
                          const SizedBox(height: 8),
                          // usage_time / patient_usage_time are confirmed daily quotas, in seconds.
                          Text(
                            'Today: ${_formatDuration(treatment.patientUsageTimeSeconds)} / ${_formatDuration(treatment.usageTimeSeconds)}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                              minHeight: 6,
                            ),
                          ),
                          ValueListenableBuilder<TreatmentFetchState>(
                            valueListenable: _service.fetchStateNotifier,
                            builder: (context, state, _) {
                              if (state != TreatmentFetchState.error) {
                                return const SizedBox.shrink();
                              }
                              return const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Could not refresh — showing last known info',
                                  style: TextStyle(fontSize: 10, color: Colors.orange),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
