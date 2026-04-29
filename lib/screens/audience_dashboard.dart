import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/main_bottom_nav.dart';
import '../models/app_session.dart';
import '../models/song_request_model.dart';
import '../services/firestore_service.dart';

class AudienceDashboard extends StatefulWidget {
  const AudienceDashboard({super.key});

  @override
  State<AudienceDashboard> createState() => _AudienceDashboardState();
}

class _AudienceDashboardState extends State<AudienceDashboard> {
  final FirestoreService _firestoreService = FirestoreService();
  void _goToRequestSong(BuildContext context) {
    Navigator.pushNamed(context, '/audience_request_song');
  }

  void _goToShoutouts(BuildContext context) {
    Navigator.pushNamed(context, '/audience_shoutouts');
  }

  void _goToLiveEvents(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/live_events_map');
  }

  void _leaveEvent() {
    AppSession.selectedEvent = null;
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Left current event')));
  }

  Color _statusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orangeAccent;
      case RequestStatus.accepted:
        return Colors.blueAccent;
      case RequestStatus.declined:
        return Colors.redAccent;
      case RequestStatus.playing:
        return Colors.greenAccent;
      case RequestStatus.played:
        return Colors.blueGrey;
      case RequestStatus.banned:
        return Colors.deepOrangeAccent;
    }
  }

  String _statusLabel(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.accepted:
        return 'Accepted';
      case RequestStatus.declined:
        return 'Declined';
      case RequestStatus.playing:
        return 'Playing';
      case RequestStatus.played:
        return 'Played';
      case RequestStatus.banned:
        return 'Banned';
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkBg = Colors.black;
    final event = AppSession.selectedEvent;

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Audience Dashboard'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CURRENT EVENT CARD (match DJ style)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white12,
                      ),
                      child: const Icon(
                        Icons.event,
                        color: Colors.white70,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current event',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event != null ? event.name : 'No active event',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (event != null) ...[
                            Text(
                              event.venue,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              event.time,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ] else ...[
                            const Text(
                              'Join an event to start sending requests.',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (event == null)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: TextButton(
                          onPressed: () => _goToLiveEvents(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          child: const Text(
                            'Join event',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (event != null)
                      SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed: _leaveEvent,
                          child: const Text(
                            'Leave event',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // MAIN BLOCK (light shell, DJ theme)
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.55,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1E1E1),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Requests Status',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (event == null)
                            const Text(
                              'Join an event to see request updates.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            )
                          else
                            StreamBuilder<List<SongRequest>>(
                              stream: _firestoreService
                                  .getAudienceRequestsForEvent(
                                    FirebaseAuth.instance.currentUser?.uid ??
                                        '',
                                    event.id,
                                  ),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: LinearProgressIndicator(),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return const Text(
                                    'Unable to load requests right now.',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                  );
                                }

                                final requests = snapshot.data ?? [];

                                if (requests.isEmpty) {
                                  return const Text(
                                    'No requests yet.',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                  );
                                }

                                requests.sort(
                                  (a, b) => b.timestamp.compareTo(a.timestamp),
                                );

                                final visible = requests.take(3).toList();

                                return Column(
                                  children: visible.map((req) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${req.songName} - ${req.artistName}',
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _statusColor(
                                                req.status,
                                              ).withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: _statusColor(req.status),
                                              ),
                                            ),
                                            child: Text(
                                              _statusLabel(req.status),
                                              style: TextStyle(
                                                color: _statusColor(req.status),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tiles row
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _ActionTile(
                              label: 'Request Song',
                              onTap: () => _goToRequestSong(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionTile(
                              label: 'Shoutouts',
                              onTap: () => _goToShoutouts(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const MainBottomNav(
        currentIndex: 0, // Dashboard tab
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Center(
                child: Text(
                  '+',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
