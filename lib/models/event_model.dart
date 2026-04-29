import 'package:cloud_firestore/cloud_firestore.dart';

enum EventStatus { scheduled, active, ended }

class Event {
  final String eventId;
  final String djId;
  final String eventName;
  final String location;
  final double? latitude;
  final double? longitude;
  final DateTime date;
  final String theme;
  final EventStatus status;
  final DateTime startTime;
  final int durationMinutes;

  Event({
    required this.eventId,
    required this.djId,
    required this.eventName,
    required this.location,
    this.latitude,
    this.longitude,
    required this.date,
    this.theme = '',
    this.status = EventStatus.scheduled,
    required this.startTime,
    this.durationMinutes = 180,
  });

  DateTime get joinOpensAt => startTime.subtract(const Duration(hours: 2));

  DateTime get endTime => startTime.add(Duration(minutes: durationMinutes));

  bool isJoinableAt(DateTime now) {
    return !now.isBefore(joinOpensAt) && !now.isAfter(endTime);
  }

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawDuration = data['duration_minutes'];
    final parsedDuration = rawDuration is num ? rawDuration.toInt() : 180;
    return Event(
      eventId: doc.id,
      djId: data['dj_id'] ?? '',
      eventName: data['event_name'] ?? '',
      location: data['location'] ?? '',
      latitude: (data['lat'] as num?)?.toDouble(),
      longitude: (data['lng'] as num?)?.toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      theme: data['theme'] ?? '',
      status: statusFromString(data['status']),
      startTime: (data['start_time'] as Timestamp).toDate(),
      durationMinutes: parsedDuration > 0 ? parsedDuration : 180,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'dj_id': djId,
      'event_name': eventName,
      'location': location,
      if (latitude != null) 'lat': latitude,
      if (longitude != null) 'lng': longitude,
      'date': Timestamp.fromDate(date),
      'theme': theme,
      'status': statusToString(status),
      'start_time': Timestamp.fromDate(startTime),
      'duration_minutes': durationMinutes,
    };
  }

  static EventStatus statusFromString(String? status) {
    switch (status) {
      case 'active':
        return EventStatus.active;
      case 'ended':
        return EventStatus.ended;
      default:
        return EventStatus.scheduled;
    }
  }

  static String statusToString(EventStatus status) {
    switch (status) {
      case EventStatus.active:
        return 'active';
      case EventStatus.ended:
        return 'ended';
      case EventStatus.scheduled:
        return 'scheduled';
    }
  }
}

class EventAnalytics {
  final String analyticsId;
  final String eventId;
  final double totalTips;
  final int totalRequests;
  final String mostRequestedSong;

  EventAnalytics({
    required this.analyticsId,
    required this.eventId,
    this.totalTips = 0.0,
    this.totalRequests = 0,
    this.mostRequestedSong = '',
  });

  factory EventAnalytics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventAnalytics(
      analyticsId: doc.id,
      eventId: data['event_id'] ?? '',
      totalTips: (data['total_tips'] ?? 0.0).toDouble(),
      totalRequests: data['total_requests'] ?? 0,
      mostRequestedSong: data['most_requested_song'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'event_id': eventId,
      'total_tips': totalTips,
      'total_requests': totalRequests,
      'most_requested_song': mostRequestedSong,
    };
  }
}
