import 'package:flutter/material.dart';
import '../models/app_session.dart';
import '../models/song_request_model.dart';
import '../models/shoutout_model.dart';
import '../services/firestore_service.dart';
import '../widgets/main_bottom_nav.dart';

class DjTipsBreakdownPage extends StatelessWidget {
  const DjTipsBreakdownPage({super.key});

  String _entryLabel(String type, String content) {
    return type == 'shoutout' ? 'Shoutout - $content' : content;
  }

  String _audienceLabel(String audienceId, Map<String, String> displayNames) {
    final name = displayNames[audienceId];
    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }
    if (audienceId.isEmpty) return 'Audience';
    final trimmed = audienceId.length > 6
        ? audienceId.substring(0, 6)
        : audienceId;
    return 'Audience $trimmed';
  }

  @override
  Widget build(BuildContext context) {
    const darkBg = Colors.black;
    const purple = Color(0xFF4B0082);
    final event = AppSession.selectedEvent;
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Tips Breakdown',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: event == null
            ? const Center(
                child: Text(
                  'No active event selected.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : StreamBuilder<List<SongRequest>>(
                stream: firestoreService.getEventRequests(event.id),
                builder: (context, snapshot) {
                  final all = snapshot.data ?? [];
                  final songTips = all
                      .where((req) => req.status == RequestStatus.played)
                      .toList();

                  return StreamBuilder<List<Shoutout>>(
                    stream: firestoreService.getEventShoutouts(event.id),
                    builder: (context, shoutSnapshot) {
                      final shoutouts = shoutSnapshot.data ?? [];

                      final entries = <Map<String, dynamic>>[
                        ...songTips.map(
                          (req) => {
                            'type': 'song',
                            'audienceId': req.audienceId,
                            'title': req.songName,
                            'amount': req.tipAmount,
                            'timestamp': req.timestamp,
                          },
                        ),
                        ...shoutouts.map(
                          (shout) => {
                            'type': 'shoutout',
                            'audienceId': shout.audienceId,
                            'title': shout.message,
                            'amount': shout.tipAmount,
                            'timestamp': shout.timestamp,
                          },
                        ),
                      ]..sort(
                        (a, b) => (b['timestamp'] as DateTime).compareTo(
                          a['timestamp'] as DateTime,
                        ),
                      );

                      final total = entries.fold<double>(
                        0.0,
                        (sum, entry) => sum + (entry['amount'] as double),
                      );

                      final audienceIds = entries
                          .map((entry) => entry['audienceId'] as String)
                          .toSet();

                      return FutureBuilder<Map<String, String>>(
                        future: firestoreService.getUserDisplayNames(audienceIds),
                        builder: (context, namesSnapshot) {
                          final displayNames =
                              namesSnapshot.data ?? const <String, String>{};

                          return Column(
                            children: [
                          const SizedBox(height: 12),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Tips Amount',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '£${total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: entries.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No tips yet.',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.all(12),
                                      itemCount: entries.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final entry = entries[index];
                                        final time =
                                            (entry['timestamp'] as DateTime)
                                                .toLocal();
                                        final timeText =
                                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

                                        return Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade900,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 32,
                                                height: 32,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.grey.shade800,
                                                ),
                                                child: const Icon(
                                                  Icons.attach_money,
                                                  size: 18,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '${_entryLabel(entry['type'] as String, entry['title'] as String)} - ${_audienceLabel(entry['audienceId'] as String, displayNames)}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Time: $timeText',
                                                      style: const TextStyle(
                                                        color: Colors.white60,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: purple,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                ),
                                                child: Text(
                                                  '£${(entry['amount'] as double).toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 0),
    );
  }
}
