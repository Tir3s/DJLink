import 'package:cloud_firestore/cloud_firestore.dart';

enum ShoutoutStatus { pending, accepted, denied, banned }

class Shoutout {
  final String shoutoutId;
  final String eventId;
  final String audienceId;
  final String name;
  final String message;
  final double tipAmount;
  final ShoutoutStatus status;
  final DateTime timestamp;

  Shoutout({
    required this.shoutoutId,
    required this.eventId,
    required this.audienceId,
    required this.name,
    required this.message,
    this.tipAmount = 0.0,
    this.status = ShoutoutStatus.pending,
    required this.timestamp,
  });

  factory Shoutout.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Shoutout(
      shoutoutId: doc.id,
      eventId: data['event_id'] ?? '',
      audienceId: data['audience_id'] ?? '',
      name: data['name'] ?? '',
      message: data['message'] ?? '',
      tipAmount: (data['tip_amount'] ?? 0.0).toDouble(),
      status: statusFromString(data['status']),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'event_id': eventId,
      'audience_id': audienceId,
      'name': name,
      'message': message,
      'tip_amount': tipAmount,
      'status': statusToString(status),
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  static ShoutoutStatus statusFromString(String? status) {
    switch (status) {
      case 'accepted':
        return ShoutoutStatus.accepted;
      case 'denied':
        return ShoutoutStatus.denied;
      case 'banned':
        return ShoutoutStatus.banned;
      default:
        return ShoutoutStatus.pending;
    }
  }

  static String statusToString(ShoutoutStatus status) {
    switch (status) {
      case ShoutoutStatus.accepted:
        return 'accepted';
      case ShoutoutStatus.denied:
        return 'denied';
      case ShoutoutStatus.banned:
        return 'banned';
      case ShoutoutStatus.pending:
        return 'pending';
    }
  }
}
