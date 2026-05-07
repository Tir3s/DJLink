import 'package:flutter/material.dart';
import '../widgets/main_bottom_nav.dart';
import '../widgets/modern_snackbar.dart';
import '../models/app_session.dart';
import '../models/event_model.dart';
import '../services/firestore_service.dart';
import 'live_events_map_page.dart';

class LiveEventsListPage extends StatefulWidget {
  const LiveEventsListPage({super.key});

  @override
  State<LiveEventsListPage> createState() => _LiveEventsListPageState();
}

class _LiveEventsListPageState extends State<LiveEventsListPage> {
  final FirestoreService _firestoreService = FirestoreService();

  int? _expandedIndex;

  String _formatStarted(Event event) {
    if (event.status != EventStatus.active) {
      final time = event.startTime.toLocal();
      final timeText = '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
      return 'Starts $timeText';
    }
    final time = event.startTime.toLocal();
    final timeText = '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    return 'Started $timeText';
  }

  _LiveEvent _buildLiveEvent(Event event) {
    final summary = EventSummary(
      id: event.eventId,
      name: event.eventName,
      venue: event.location,
      time: event.status == EventStatus.active ? 'Live now' : 'Scheduled',
      isLive: event.status == EventStatus.active,
    );

    return _LiveEvent(
      summary: summary,
      listeners: 'Live crowd',
      dj: 'DJ',
      genre: event.theme.isNotEmpty ? event.theme : 'Live set',
      started: _formatStarted(event),
      description: 'Live event at ${event.location}.',
    );
  }

  void _goToMap(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const LiveEventsMapPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF4B0082);
    const darkBg = Colors.black;

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Live Events'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ViewToggle(
                isListSelected: true,
                onListTap: () {},
                onMapTap: () => _goToMap(context),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: StreamBuilder<List<Event>>(
                stream: _firestoreService.getLiveEvents(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final events = snapshot.data ?? [];
                  if (events.isEmpty) {
                    return const Center(
                      child: Text(
                        'No live events yet',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final e = _buildLiveEvent(event);
                      final summary = e.summary;
                      final isExpanded = _expandedIndex == index;

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
                                      Text(
                                        summary.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        summary.venue,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        e.listeners,
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: summary.isLive
                                            ? purple
                                            : Colors.white24,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        summary.isLive
                                            ? 'Live now'
                                            : 'Scheduled',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: purple,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 6,
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
                                    'DJ: ${e.dj}',
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
                                    e.genre,
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
                                    Icons.schedule,
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    e.started,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                e.description,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: SizedBox(
                                  height: 30,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: purple),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                    ),
                                    onPressed: () {
                                      final now = DateTime.now();
                                      if (!event.isJoinableAt(now)) {
                                        final message =
                                            now.isBefore(event.joinOpensAt)
                                            ? 'Join opens 2 hours before start time.'
                                            : 'This event has ended and can no longer be joined.';
                                        ModernSnackBar.showWarning(
                                          context,
                                          message,
                                        );
                                        return;
                                      }
                                      AppSession.selectedEvent = summary;
                                    },
                                    child: const Text('Join'),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (!summary.isLive)
                                const Text(
                                  'Scheduled for today.',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
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
        currentIndex: 2, // Live tab
      ),
    );
  }
}

class _LiveEvent {
  final EventSummary summary;
  final String listeners;
  final String dj;
  final String genre;
  final String started;
  final String description;

  const _LiveEvent({
    required this.summary,
    required this.listeners,
    required this.dj,
    required this.genre,
    required this.started,
    required this.description,
  });
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
        borderRadius: BorderRadius.circular(999),
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
                  borderRadius: BorderRadius.circular(999),
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
                  borderRadius: BorderRadius.circular(999),
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
