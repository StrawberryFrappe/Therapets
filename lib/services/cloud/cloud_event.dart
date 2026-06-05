/// A timestamped event to be sent to the cloud.
class CloudEvent {
  final String id;
  final DateTime timestamp;
  final String eventType;
  final Map<String, dynamic> payload;
  int retryCount;

  CloudEvent({
    required this.id,
    required this.timestamp,
    required this.eventType,
    required this.payload,
    this.retryCount = 0,
  });

  /// Convert to JSON for HTTP payload
  Map<String, dynamic> toJson() => {
        'id': id,
        'ts': timestamp.millisecondsSinceEpoch,
        'type': eventType,
        'payload': payload,
        'retryCount': retryCount,
      };

  factory CloudEvent.fromJson(Map<String, dynamic> json) {
    return CloudEvent(
      id: json['id'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
      eventType: json['type'] as String,
      payload: json['payload'] as Map<String, dynamic>,
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }
}
