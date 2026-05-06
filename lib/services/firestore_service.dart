import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/event_model.dart';
import '../models/song_request_model.dart';
import '../models/ban_list_model.dart';
import '../models/shoutout_model.dart';

class RequestBlockedException implements Exception {
  final String message;

  RequestBlockedException(this.message);

  @override
  String toString() => message;
}

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  static const String _joinCodeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  Future<String> createEvent(Event event) async {
    const maxAttempts = 8;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final code = _generateJoinCode();
      final docRef = _firestore.collection('events').doc(code);
      final existing = await docRef.get();
      if (existing.exists) {
        continue;
      }

      await docRef.set(event.toFirestore());
      return code;
    }

    throw Exception('Failed to generate a unique join code.');
  }

  String _generateJoinCode({int length = 6}) {
    return List.generate(
      length,
      (_) => _joinCodeChars[_random.nextInt(_joinCodeChars.length)],
    ).join();
  }

  Future<Event?> getEvent(String eventId) async {
    DocumentSnapshot doc = await _firestore
        .collection('events')
        .doc(eventId)
        .get();
    return doc.exists ? Event.fromFirestore(doc) : null;
  }

  Stream<List<Event>> getDjEvents(String djId) {
    return _firestore
        .collection('events')
        .where('dj_id', isEqualTo: djId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<Event>> getLiveEvents() {
    bool isSameDay(DateTime a, DateTime b) {
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }

    return _firestore.collection('events').snapshots().map((snapshot) {
      final now = DateTime.now();
      final events = snapshot.docs.map((doc) => Event.fromFirestore(doc)).where(
        (event) {
          if (now.isAfter(event.endTime)) {
            return false;
          }
          if (event.status == EventStatus.active) {
            return true;
          }
          if (event.status == EventStatus.ended) {
            return false;
          }
          return isSameDay(event.date.toLocal(), now);
        },
      ).toList();

      events.sort((a, b) => a.startTime.compareTo(b.startTime));
      return events;
    });
  }

  Stream<List<Event>> getUpcomingEvents() {
    return _firestore
        .collection('events')
        .where('status', isEqualTo: 'scheduled')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<Event>> getDiscoverEvents() {
    return _firestore
        .collection('events')
        .where('status', whereIn: ['scheduled', 'active'])
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();
          return snapshot.docs
              .map((doc) => Event.fromFirestore(doc))
              .where((event) => !now.isAfter(event.endTime))
              .toList();
        });
  }

  Stream<List<Event>> getAllEvents() {
    return _firestore
        .collection('events')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList(),
        );
  }

  Future<void> updateEventStatus(String eventId, EventStatus status) async {
    await _firestore.collection('events').doc(eventId).update({
      'status': Event.statusToString(status),
    });
  }

  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }

  Future<String> submitSongRequest(SongRequest request) async {
    final event = await getEvent(request.eventId);
    if (event == null) {
      throw Exception('Event not found.');
    }

    final isBanned = await isAudienceBannedForDj(
      djId: event.djId,
      audienceId: request.audienceId,
    );

    if (isBanned) {
      throw RequestBlockedException(
        'You are banned from sending song requests to this DJ.',
      );
    }

    DocumentReference docRef = await _firestore
        .collection('song_requests')
        .add(request.toFirestore());
    return docRef.id;
  }

  Stream<List<SongRequest>> getEventRequests(String eventId) {
    return _firestore
        .collection('song_requests')
        .where('event_id', isEqualTo: eventId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SongRequest.fromFirestore(doc))
              .toList(),
        );
  }

  Future<List<SongRequest>> getEventRequestsOnce(String eventId) async {
    final snapshot = await _firestore
        .collection('song_requests')
        .where('event_id', isEqualTo: eventId)
        .get();
    return snapshot.docs.map((doc) => SongRequest.fromFirestore(doc)).toList();
  }

  Stream<List<SongRequest>> getPendingRequests(String eventId) {
    return _firestore
        .collection('song_requests')
        .where('event_id', isEqualTo: eventId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SongRequest.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> updateRequestStatus(
    String requestId,
    RequestStatus status,
  ) async {
    await _firestore.collection('song_requests').doc(requestId).update({
      'status': SongRequest.statusToString(status),
    });
  }

  Stream<List<SongRequest>> getAudienceRequests(String audienceId) {
    return _firestore
        .collection('song_requests')
        .where('audience_id', isEqualTo: audienceId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SongRequest.fromFirestore(doc))
              .toList(),
        );
  }

  Future<Map<String, String>> getUserDisplayNames(
    Iterable<String> userIds,
  ) async {
    final ids = userIds.where((id) => id.isNotEmpty).toSet().toList();
    if (ids.isEmpty) return {};

    final Map<String, String> result = {};

    for (var i = 0; i < ids.length; i += 10) {
      final end = (i + 10 < ids.length) ? i + 10 : ids.length;
      final chunk = ids.sublist(i, end);

      final snapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final username = (data['username'] as String?)?.trim();
        final displayName = (data['display_name'] as String?)?.trim();
        final stageName = (data['stage_name'] as String?)?.trim();
        final name = (displayName?.isNotEmpty ?? false)
            ? displayName!
            : (username?.isNotEmpty ?? false)
            ? username!
            : (stageName?.isNotEmpty ?? false)
            ? stageName!
            : '';

        if (name.isNotEmpty) {
          result[doc.id] = name;
        }
      }
    }

    return result;
  }

  Stream<List<SongRequest>> getAudienceRequestsForEvent(
    String audienceId,
    String eventId,
  ) {
    return _firestore
        .collection('song_requests')
        .where('audience_id', isEqualTo: audienceId)
        .where('event_id', isEqualTo: eventId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SongRequest.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> recordTip(TipTransaction tip) async {
    await _firestore.collection('tip_transactions').add(tip.toFirestore());
  }

  Future<double> getEventTips(String eventId) async {
    QuerySnapshot requests = await _firestore
        .collection('song_requests')
        .where('event_id', isEqualTo: eventId)
        .get();

    double total = 0.0;
    for (var doc in requests.docs) {
      total += ((doc.data() as Map<String, dynamic>)['tip_amount'] ?? 0.0);
    }
    return total;
  }

  Future<EventAnalytics?> getEventAnalytics(String eventId) async {
    QuerySnapshot analyticsQuery = await _firestore
        .collection('event_analytics')
        .where('event_id', isEqualTo: eventId)
        .limit(1)
        .get();

    if (analyticsQuery.docs.isNotEmpty) {
      return EventAnalytics.fromFirestore(analyticsQuery.docs.first);
    }
    return null;
  }

  Future<void> updateEventAnalytics(String eventId) async {
    QuerySnapshot requests = await _firestore
        .collection('song_requests')
        .where('event_id', isEqualTo: eventId)
        .get();

    double totalTips = 0.0;
    Map<String, int> songCounts = {};

    for (var doc in requests.docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalTips += (data['tip_amount'] ?? 0.0);

      String songName = data['song_name'] ?? '';
      songCounts[songName] = (songCounts[songName] ?? 0) + 1;
    }

    String mostRequested = '';
    int maxCount = 0;
    songCounts.forEach((song, count) {
      if (count > maxCount) {
        maxCount = count;
        mostRequested = song;
      }
    });

    QuerySnapshot analyticsQuery = await _firestore
        .collection('event_analytics')
        .where('event_id', isEqualTo: eventId)
        .limit(1)
        .get();

    if (analyticsQuery.docs.isNotEmpty) {
      await analyticsQuery.docs.first.reference.update({
        'total_tips': totalTips,
        'total_requests': requests.docs.length,
        'most_requested_song': mostRequested,
      });
    } else {
      await _firestore.collection('event_analytics').add({
        'event_id': eventId,
        'total_tips': totalTips,
        'total_requests': requests.docs.length,
        'most_requested_song': mostRequested,
      });
    }
  }

  Future<void> addBan(BanList ban) async {
    final banDocId = '${ban.djId}_${ban.audienceId}';
    await _firestore.collection('ban_list').doc(banDocId).set(
      ban.toFirestore(),
      SetOptions(merge: true),
    );
  }

  Future<bool> isAudienceBannedForDj({
    required String djId,
    required String audienceId,
  }) async {
    final directDoc = await _firestore
        .collection('ban_list')
        .doc('${djId}_$audienceId')
        .get();
    if (directDoc.exists) {
      return true;
    }

    final query = await _firestore
        .collection('ban_list')
        .where('dj_id', isEqualTo: djId)
        .where('audience_id', isEqualTo: audienceId)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  Future<String> submitShoutout(Shoutout shoutout) async {
    DocumentReference docRef = await _firestore
        .collection('shoutouts')
        .add(shoutout.toFirestore());
    return docRef.id;
  }

  Stream<List<Shoutout>> getEventShoutouts(String eventId) {
    return _firestore
        .collection('shoutouts')
        .where('event_id', isEqualTo: eventId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Shoutout.fromFirestore(doc)).toList(),
        );
  }

  Future<void> updateShoutoutStatus(
    String shoutoutId,
    ShoutoutStatus status,
  ) async {
    await _firestore.collection('shoutouts').doc(shoutoutId).update({
      'status': Shoutout.statusToString(status),
    });
  }

  Stream<Map<String, dynamic>?> getUserDataStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      return doc.data();
    });
  }

  Future<Map<String, dynamic>?> getUserDataById(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data();
  }

  Future<void> updateUserSocials(
    String userId,
    Map<String, String> socials,
  ) async {
    await _firestore.collection('users').doc(userId).set({
      'socials': socials,
    }, SetOptions(merge: true));
  }

  Future<void> updateUserAvatarIcon(String userId, int iconCodePoint) async {
    await _firestore.collection('users').doc(userId).set({
      'avatar_icon': iconCodePoint,
    }, SetOptions(merge: true));
  }

  Future<void> followDjFromEvent({
    required String audienceId,
    required String eventId,
  }) async {
    final event = await getEvent(eventId);
    if (event == null) {
      throw Exception('Event not found.');
    }
    if (event.djId == audienceId) {
      throw Exception('You cannot follow yourself.');
    }

    final followId = '${audienceId}_${event.djId}';
    await _firestore.collection('user_follows').doc(followId).set({
      'audience_id': audienceId,
      'dj_id': event.djId,
      'event_id': eventId,
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> isFollowingDj({
    required String audienceId,
    required String djId,
  }) async {
    final followId = '${audienceId}_${djId}';
    final doc = await _firestore.collection('user_follows').doc(followId).get();
    return doc.exists;
  }

  Stream<int> getFollowersCountStream(String djId) {
    return _firestore
        .collection('user_follows')
        .where('dj_id', isEqualTo: djId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getFollowingCountStream(String audienceId) {
    return _firestore
        .collection('user_follows')
        .where('audience_id', isEqualTo: audienceId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<List<Map<String, dynamic>>> getFollowerProfiles(String djId) async {
    final follows = await _firestore
        .collection('user_follows')
        .where('dj_id', isEqualTo: djId)
        .get();

    final ids = follows.docs
        .map((doc) => (doc.data()['audience_id'] as String?) ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    return _getUserProfilesByIds(ids);
  }

  Future<List<Map<String, dynamic>>> getFollowingDjProfiles(
    String audienceId,
  ) async {
    final follows = await _firestore
        .collection('user_follows')
        .where('audience_id', isEqualTo: audienceId)
        .get();

    final ids = follows.docs
        .map((doc) => (doc.data()['dj_id'] as String?) ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    return _getUserProfilesByIds(ids);
  }

  Future<List<Map<String, dynamic>>> _getUserProfilesByIds(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return [];

    final profiles = <Map<String, dynamic>>[];
    for (var i = 0; i < userIds.length; i += 10) {
      final end = (i + 10 < userIds.length) ? i + 10 : userIds.length;
      final chunk = userIds.sublist(i, end);

      final snapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        profiles.add({
          'user_id': doc.id,
          'username': data['username'] ?? '',
          'email': data['email'] ?? '',
          'role': data['role'] ?? 'audience',
          'socials': data['socials'] ?? <String, dynamic>{},
          'avatar_icon': data['avatar_icon'],
        });
      }
    }

    profiles.sort((a, b) {
      final aName = (a['username'] as String?) ?? '';
      final bName = (b['username'] as String?) ?? '';
      return aName.toLowerCase().compareTo(bName.toLowerCase());
    });

    return profiles;
  }

  Future<Map<String, String>> getEventNamesByIds(
    Iterable<String> eventIds,
  ) async {
    final ids = eventIds.where((id) => id.isNotEmpty).toSet().toList();
    if (ids.isEmpty) return {};

    final Map<String, String> result = {};

    for (var i = 0; i < ids.length; i += 10) {
      final end = (i + 10 < ids.length) ? i + 10 : ids.length;
      final chunk = ids.sublist(i, end);

      final snapshot = await _firestore
          .collection('events')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        result[doc.id] =
            (data['event_name'] as String?)?.trim().isNotEmpty == true
            ? (data['event_name'] as String)
            : doc.id;
      }
    }

    return result;
  }

  Future<Map<String, num>> getDjProfileMetrics(String djId) async {
    final eventSnapshot = await _firestore
        .collection('events')
        .where('dj_id', isEqualTo: djId)
        .get();

    final eventIds = eventSnapshot.docs.map((doc) => doc.id).toList();
    var requestsHandled = 0;
    var tipsEarned = 0.0;

    for (var i = 0; i < eventIds.length; i += 10) {
      final end = (i + 10 < eventIds.length) ? i + 10 : eventIds.length;
      final chunk = eventIds.sublist(i, end);
      if (chunk.isEmpty) continue;

      final requestsSnapshot = await _firestore
          .collection('song_requests')
          .where('event_id', whereIn: chunk)
          .get();

      requestsHandled += requestsSnapshot.docs.length;
      for (final doc in requestsSnapshot.docs) {
        final data = doc.data();
        if ((data['status'] as String?) == 'played') {
          tipsEarned += (data['tip_amount'] as num?)?.toDouble() ?? 0.0;
        }
      }

      final shoutoutsSnapshot = await _firestore
          .collection('shoutouts')
          .where('event_id', whereIn: chunk)
          .get();

      for (final doc in shoutoutsSnapshot.docs) {
        final data = doc.data();
        tipsEarned += (data['tip_amount'] as num?)?.toDouble() ?? 0.0;
      }
    }

    return {
      'events_hosted': eventIds.length,
      'requests_handled': requestsHandled,
      'tips_earned': tipsEarned,
    };
  }

  Future<Map<String, num>> getAudienceProfileMetrics(String audienceId) async {
    final requestsSnapshot = await _firestore
        .collection('song_requests')
        .where('audience_id', isEqualTo: audienceId)
        .get();

    final joinedEventIds = <String>{};
    var tipsPaid = 0.0;

    for (final doc in requestsSnapshot.docs) {
      final data = doc.data();
      final eventId = (data['event_id'] as String?) ?? '';
      if (eventId.isNotEmpty) {
        joinedEventIds.add(eventId);
      }
      tipsPaid += (data['tip_amount'] as num?)?.toDouble() ?? 0.0;
    }

    final shoutoutsSnapshot = await _firestore
        .collection('shoutouts')
        .where('audience_id', isEqualTo: audienceId)
        .get();

    for (final doc in shoutoutsSnapshot.docs) {
      final data = doc.data();
      final eventId = (data['event_id'] as String?) ?? '';
      if (eventId.isNotEmpty) {
        joinedEventIds.add(eventId);
      }
      tipsPaid += (data['tip_amount'] as num?)?.toDouble() ?? 0.0;
    }

    return {
      'events_joined': joinedEventIds.length,
      'requests_made': requestsSnapshot.docs.length,
      'tips_paid': tipsPaid,
    };
  }

  Future<Map<String, double>> getDjPayoutsByEvent(String djId) async {
    final eventSnapshot = await _firestore
        .collection('events')
        .where('dj_id', isEqualTo: djId)
        .get();

    final eventIds = eventSnapshot.docs.map((doc) => doc.id).toList();
    final payouts = <String, double>{};

    for (final eventId in eventIds) {
      payouts[eventId] = 0.0;
    }

    for (var i = 0; i < eventIds.length; i += 10) {
      final end = (i + 10 < eventIds.length) ? i + 10 : eventIds.length;
      final chunk = eventIds.sublist(i, end);
      if (chunk.isEmpty) continue;

      final requestsSnapshot = await _firestore
          .collection('song_requests')
          .where('event_id', whereIn: chunk)
          .where('status', isEqualTo: 'played')
          .get();

      for (final doc in requestsSnapshot.docs) {
        final data = doc.data();
        final eventId = (data['event_id'] as String?) ?? '';
        final tip = (data['tip_amount'] as num?)?.toDouble() ?? 0.0;
        payouts[eventId] = (payouts[eventId] ?? 0.0) + tip;
      }

      final shoutoutsSnapshot = await _firestore
          .collection('shoutouts')
          .where('event_id', whereIn: chunk)
          .get();

      for (final doc in shoutoutsSnapshot.docs) {
        final data = doc.data();
        final eventId = (data['event_id'] as String?) ?? '';
        final tip = (data['tip_amount'] as num?)?.toDouble() ?? 0.0;
        payouts[eventId] = (payouts[eventId] ?? 0.0) + tip;
      }
    }

    return payouts;
  }

  Future<Map<String, double>> getAudiencePaymentsByEvent(
    String audienceId,
  ) async {
    final requestsSnapshot = await _firestore
        .collection('song_requests')
        .where('audience_id', isEqualTo: audienceId)
        .get();

    final payments = <String, double>{};

    for (final doc in requestsSnapshot.docs) {
      final data = doc.data();
      final eventId = (data['event_id'] as String?) ?? '';
      if (eventId.isEmpty) continue;
      final tip = (data['tip_amount'] as num?)?.toDouble() ?? 0.0;
      payments[eventId] = (payments[eventId] ?? 0.0) + tip;
    }

    final shoutoutsSnapshot = await _firestore
        .collection('shoutouts')
        .where('audience_id', isEqualTo: audienceId)
        .get();

    for (final doc in shoutoutsSnapshot.docs) {
      final data = doc.data();
      final eventId = (data['event_id'] as String?) ?? '';
      if (eventId.isEmpty) continue;
      final tip = (data['tip_amount'] as num?)?.toDouble() ?? 0.0;
      payments[eventId] = (payments[eventId] ?? 0.0) + tip;
    }

    return payments;
  }
}
