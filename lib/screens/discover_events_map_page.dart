import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/app_session.dart';
import '../models/event_model.dart';
import '../services/firestore_service.dart';
import '../widgets/main_bottom_nav.dart';
import 'discover_events_list_page.dart';

class DiscoverEventsMapPage extends StatelessWidget {
  const DiscoverEventsMapPage({super.key});

  bool _isDiscoverable(Event event) {
    final now = DateTime.now();
    if (now.isAfter(event.endTime)) {
      return false;
    }

    if (event.status == EventStatus.active) {
      return true;
    }
    if (event.status == EventStatus.ended) {
      return false;
    }

    if (AppSession.selectedEvent?.id == event.eventId) {
      return true;
    }

    final eventStart = DateTime(
      event.date.year,
      event.date.month,
      event.date.day,
      event.startTime.hour,
      event.startTime.minute,
    );
    return !eventStart.isBefore(now);
  }

  String _formatEventTime(Event event) {
    if (event.status == EventStatus.active) {
      return 'Live now';
    }
    final date = event.date.toLocal();
    final time = event.startTime.toLocal();
    final dateText = '${date.day}/${date.month}';
    final timeText = '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    return '$dateText · $timeText';
  }

  String _formatDuration(Event event) {
    final hours = event.durationMinutes ~/ 60;
    final minutes = event.durationMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    }
    if (hours > 0) {
      return '${hours}h';
    }
    return '${minutes}m';
  }

  String _statusLabel(Event event) {
    if (event.status == EventStatus.active) {
      return 'LIVE';
    }
    return 'UPCOMING';
  }

  void _showEventDetails(BuildContext context, Event event) {
    const highlight = Color(0xFF4B0082);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 18,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        event.eventName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: highlight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _statusLabel(event),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.place, size: 16, color: Colors.white70),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.location,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      _formatEventTime(event),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.timelapse,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Duration ${_formatDuration(event)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: highlight),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Continue Exploring'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _goToList(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const DiscoverEventsListPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const darkBg = Colors.black;
    const highlight = Color(0xFF4B0082); // purple to match Live
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Upcoming Events'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _goToList(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Center(
                            child: Text(
                              'List',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: highlight,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Center(
                          child: Text(
                            'Map',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: StreamBuilder<List<Event>>(
                stream: firestoreService.getAllEvents(),
                builder: (context, snapshot) {
                  final events = (snapshot.data ?? [])
                      .where(_isDiscoverable)
                      .toList();
                  final mappable = events
                      .where(
                        (event) =>
                            event.latitude != null && event.longitude != null,
                      )
                      .toList();

                  final LatLng center = mappable.isNotEmpty
                      ? LatLng(
                          mappable.first.latitude!,
                          mappable.first.longitude!,
                        )
                      : const LatLng(50.8198, -1.0880);

                  return Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            initialCenter: center,
                            initialZoom: 12,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'dj_link',
                            ),
                            MarkerLayer(
                              markers: mappable
                                  .map(
                                    (event) => Marker(
                                      point: LatLng(
                                        event.latitude!,
                                        event.longitude!,
                                      ),
                                      width: 44,
                                      height: 44,
                                      child: GestureDetector(
                                        onTap: () =>
                                            _showEventDetails(context, event),
                                        child: const Icon(
                                          Icons.location_on,
                                          color: highlight,
                                          size: 36,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                        if (mappable.isEmpty)
                          const Center(
                            child: Text(
                              'No upcoming events with location yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 1),
    );
  }
}
