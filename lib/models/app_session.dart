// lib/models/app_session.dart

class EventSummary {
  final String id;
  final String name;
  final String venue;
  final String time;
  final bool isLive;
  final String? distance;

  const EventSummary({
    required this.id,
    required this.name,
    required this.venue,
    required this.time,
    required this.isLive,
    this.distance,
  });
}

/// Very simple global session for now.
/// Good enough for this project – later you can replace with Provider/Riverpod.
class AppSession {
  static EventSummary? selectedEvent;
}
