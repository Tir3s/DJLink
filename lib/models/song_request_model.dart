import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestStatus { pending, accepted, declined, playing, played, banned }

class SongRequest {
  final String requestId;
  final String eventId;
  final String audienceId;
  final String songName;
  final String artistName;
  final double tipAmount;
  final String comment;
  final RequestStatus status;
  final DateTime timestamp;

  SongRequest({
    required this.requestId,
    required this.eventId,
    required this.audienceId,
    required this.songName,
    required this.artistName,
    this.tipAmount = 0.0,
    this.comment = '',
    this.status = RequestStatus.pending,
    required this.timestamp,
  });

  factory SongRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SongRequest(
      requestId: doc.id,
      eventId: data['event_id'] ?? '',
      audienceId: data['audience_id'] ?? '',
      songName: data['song_name'] ?? '',
      artistName: data['artist_name'] ?? '',
      tipAmount: (data['tip_amount'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      status: statusFromString(data['status']),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'event_id': eventId,
      'audience_id': audienceId,
      'song_name': songName,
      'artist_name': artistName,
      'tip_amount': tipAmount,
      'comment': comment,
      'status': statusToString(status),
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  static RequestStatus statusFromString(String? status) {
    switch (status) {
      case 'accepted':
        return RequestStatus.accepted;
      case 'declined':
        return RequestStatus.declined;
      case 'playing':
        return RequestStatus.playing;
      case 'played':
        return RequestStatus.played;
      case 'banned':
        return RequestStatus.banned;
      default:
        return RequestStatus.pending;
    }
  }

  static String statusToString(RequestStatus status) {
    switch (status) {
      case RequestStatus.accepted:
        return 'accepted';
      case RequestStatus.declined:
        return 'declined';
      case RequestStatus.playing:
        return 'playing';
      case RequestStatus.played:
        return 'played';
      case RequestStatus.banned:
        return 'banned';
      case RequestStatus.pending:
        return 'pending';
    }
  }
}

class TipTransaction {
  final String transactionId;
  final String requestId;
  final double amount;
  final DateTime timestamp;

  TipTransaction({
    required this.transactionId,
    required this.requestId,
    required this.amount,
    required this.timestamp,
  });

  factory TipTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TipTransaction(
      transactionId: doc.id,
      requestId: data['request_id'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'request_id': requestId,
      'amount': amount,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
