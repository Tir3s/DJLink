import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/main_bottom_nav.dart';
import '../models/app_session.dart';
import '../models/event_model.dart';
import '../services/firestore_service.dart';
import 'discover_events_map_page.dart';
import '../session.dart';

class DiscoverEventsListPage extends StatefulWidget {
  const DiscoverEventsListPage({super.key});

  @override
  State<DiscoverEventsListPage> createState() => _DiscoverEventsListPageState();
}

class _DiscoverEventsListPageState extends State<DiscoverEventsListPage> {
  final FirestoreService _firestoreService = FirestoreService();

  int? _expandedIndex; // which card is expanded, null = none

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

  Map<String, String> _detailsForEvent(Event event) {
    final genre = event.theme.isNotEmpty ? event.theme : 'Live set';
    return {
      'dj': 'DJ',
      'genre': genre,
      'price': 'Free entry',
      'age': '18+',
      'description': 'Upcoming event at ${event.location}.',
    };
  }

  void _goToMap(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const DiscoverEventsMapPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  Future<void> _deleteUpcomingEvent(BuildContext context, Event event) async {
    try {
      await _firestoreService.deleteEvent(event.eventId);
      if (AppSession.selectedEvent?.id == event.eventId) {
        AppSession.selectedEvent = null;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Deleted ${event.eventName}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not delete event')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkBg = Colors.black;

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

            // Toggle List / Map
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _ViewToggle(
                isListSelected: true,
                onListTap: () {},
                onMapTap: () => _goToMap(context),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: StreamBuilder<List<Event>>(
                stream: _firestoreService.getAllEvents(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final events = (snapshot.data ?? [])
                      .where(_isDiscoverable)
                      .toList();
                  if (events.isEmpty) {
                    return const Center(
                      child: Text(
                        'No upcoming events yet',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final e = EventSummary(
                        id: event.eventId,
                        name: event.eventName,
                        venue: event.location,
                        time: _formatEventTime(event),
                        isLive: event.status == EventStatus.active,
                      );
                      final currentUserId =
                          FirebaseAuth.instance.currentUser?.uid;
                      final canDeleteUpcoming =
                          Session.role == UserRole.dj &&
                          event.status == EventStatus.scheduled &&
                          currentUserId != null &&
                          event.djId == currentUserId;
                      final details = _detailsForEvent(event);
                      final bool isExpanded = _expandedIndex == index;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              e.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          if (e.isLive)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF4B0082),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: const Text(
                                                'Live',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        e.venue,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        e.time,
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4B0082),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (isExpanded) {
                                        _expandedIndex = null;
                                      } else {
                                        _expandedIndex = index;
                                      }
                                    });
                                  },
                                  child: Text(isExpanded ? 'Hide' : 'View'),
                                ),
                              ],
                            ),
                            if (isExpanded) ...[
                              const SizedBox(height: 10),
                              const Divider(color: Colors.white24, height: 1),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'DJ: ${details['dj']}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.music_note,
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    details['genre']!,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.local_offer,
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    details['price']!,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    details['age']!,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                details['description']!,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (canDeleteUpcoming) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () =>
                                        _deleteUpcomingEvent(context, event),
                                    child: const Text('Delete upcoming event'),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MainBottomNav(
        currentIndex: 1, // Discover tab
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final bool isListSelected;
  final VoidCallback onListTap;
  final VoidCallback onMapTap;

  const _ViewToggle({
    required this.isListSelected,
    required this.onListTap,
    required this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF4B0082);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onListTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isListSelected ? purple : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    'List',
                    style: TextStyle(
                      color: isListSelected ? Colors.white : Colors.white70,
                      fontWeight: isListSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onMapTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isListSelected ? Colors.transparent : purple,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    'Map',
                    style: TextStyle(
                      color: isListSelected ? Colors.white70 : Colors.white,
                      fontWeight: isListSelected
                          ? FontWeight.w400
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
