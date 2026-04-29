import 'package:cloud_firestore/cloud_firestore.dart';

class BanList {
  final String banId;
  final String djId;
  final String audienceId;
  final String reason;
  final DateTime dateBanned;

  BanList({
    required this.banId,
    required this.djId,
    required this.audienceId,
    required this.reason,
    required this.dateBanned,
  });

  factory BanList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BanList(
      banId: doc.id,
      djId: data['dj_id'] ?? '',
      audienceId: data['audience_id'] ?? '',
      reason: data['reason'] ?? '',
      dateBanned: (data['date_banned'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'dj_id': djId,
      'audience_id': audienceId,
      'reason': reason,
      'date_banned': Timestamp.fromDate(dateBanned),
    };
  }
}
