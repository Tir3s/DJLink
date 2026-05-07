import 'package:flutter/material.dart';
import '../models/app_session.dart';
import '../models/song_request_model.dart';
import '../services/firestore_service.dart';
import '../widgets/main_bottom_nav.dart';
import '../widgets/modern_snackbar.dart';

class DjRequestsPlaylistPage extends StatefulWidget {
  const DjRequestsPlaylistPage({super.key});

  @override
  State<DjRequestsPlaylistPage> createState() => _DjRequestsPlaylistPageState();
}

class _DjRequestsPlaylistPageState extends State<DjRequestsPlaylistPage> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _promotingRequestId;

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

  Future<void> _moveToNext(
    SongRequest current,
    List<SongRequest> accepted,
  ) async {
    try {
      await _firestoreService.updateRequestStatus(
        current.requestId,
        RequestStatus.played,
      );

      final remaining = List<SongRequest>.from(accepted)
        ..removeWhere((req) => req.requestId == current.requestId);

      if (remaining.isNotEmpty) {
        await _firestoreService.updateRequestStatus(
          remaining.first.requestId,
          RequestStatus.playing,
        );
      }
    } catch (e) {
      if (mounted) {
        ModernSnackBar.showError(
          context,
          'Error moving to next: $e',
        );
      }
    }
  }

  String _statusBadgeLabel(RequestStatus status) {
    switch (status) {
      case RequestStatus.playing:
        return 'LIVE';
      case RequestStatus.played:
        return 'PLAYED';
      case RequestStatus.accepted:
        return 'QUEUED';
      case RequestStatus.pending:
        return 'PENDING';
      case RequestStatus.declined:
        return 'DECLINED';
      case RequestStatus.banned:
        return 'BANNED';
    }
  }

  Color _statusBadgeColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.playing:
        return Colors.greenAccent;
      case RequestStatus.played:
        return Colors.blueGrey;
      case RequestStatus.accepted:
        return Colors.blueAccent;
      case RequestStatus.pending:
        return Colors.orangeAccent;
      case RequestStatus.declined:
        return Colors.redAccent;
      case RequestStatus.banned:
        return Colors.deepOrangeAccent;
    }
  }

  void _ensureNowPlaying(
    List<SongRequest> playing,
    List<SongRequest> accepted,
  ) {
    if (playing.isNotEmpty || accepted.isEmpty) {
      return;
    }

    final nextUp = accepted.first;
    if (_promotingRequestId == nextUp.requestId) {
      return;
    }

    _promotingRequestId = nextUp.requestId;
    _firestoreService
        .updateRequestStatus(nextUp.requestId, RequestStatus.playing)
        .catchError((_) {})
        .whenComplete(() {
          if (_promotingRequestId == nextUp.requestId) {
            _promotingRequestId = null;
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    const darkBg = Colors.black;
    const purple = Color(0xFF4B0082);

    final event = AppSession.selectedEvent;

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Requests Playlist',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: event == null
            ? const Center(child: Text('No active event selected'))
            : StreamBuilder<List<SongRequest>>(
                stream: _firestoreService.getEventRequests(event.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final all = snapshot.data ?? [];
                  final playing = all
                      .where((req) => req.status == RequestStatus.playing)
                      .toList();
                  final accepted = all
                      .where((req) => req.status == RequestStatus.accepted)
                      .toList();

                  accepted.sort((a, b) {
                    final tipCompare = b.tipAmount.compareTo(a.tipAmount);
                    if (tipCompare != 0) return tipCompare;
                    return b.timestamp.compareTo(a.timestamp);
                  });

                  _ensureNowPlaying(playing, accepted);

                  final nowPlaying = playing.isNotEmpty
                      ? playing.first
                      : (accepted.isNotEmpty ? accepted.first : null);
                  final nowPlayingStatus = nowPlaying == null
                      ? null
                      : (playing.isEmpty &&
                                accepted.isNotEmpty &&
                                accepted.first.requestId == nowPlaying.requestId
                            ? RequestStatus.playing
                            : nowPlaying.status);
                  final upNext = accepted
                      .where(
                        (req) => nowPlaying == null
                            ? true
                            : req.requestId != nowPlaying.requestId,
                      )
                      .toList();

                  final audienceIds = <String>{
                    if (nowPlaying != null) nowPlaying.audienceId,
                    ...upNext.map((req) => req.audienceId),
                  };

                  return FutureBuilder<Map<String, String>>(
                    future: _firestoreService.getUserDisplayNames(audienceIds),
                    builder: (context, namesSnapshot) {
                      final displayNames =
                          namesSnapshot.data ?? const <String, String>{};

                      return Column(
                        children: [
                          const SizedBox(height: 12),

                          // NOW PLAYING
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Now Playing',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: nowPlaying == null
                                  ? const Text(
                                      'No song playing yet.',
                                      style: TextStyle(color: Colors.white70),
                                    )
                                  : Row(
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: purple,
                                              width: 2,
                                            ),
                                            color: Colors.grey.shade900,
                                          ),
                                          child: const Icon(
                                            Icons.music_note,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(width: 16),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                nowPlaying.songName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                nowPlaying.artistName,
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'From: ${_audienceLabel(nowPlaying.audienceId, displayNames)}',
                                                style: const TextStyle(
                                                  color: Colors.white60,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            if (nowPlaying.tipAmount > 0)
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
                                                  '£${nowPlaying.tipAmount.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _statusBadgeColor(
                                                  nowPlayingStatus!,
                                                ).withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: _statusBadgeColor(
                                                    nowPlayingStatus,
                                                  ),
                                                ),
                                              ),
                                              child: Text(
                                                _statusBadgeLabel(
                                                  nowPlayingStatus,
                                                ),
                                                style: TextStyle(
                                                  color: _statusBadgeColor(
                                                    nowPlayingStatus,
                                                  ),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 1.1,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            SizedBox(
                                              height: 28,
                                              child: OutlinedButton(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  side: const BorderSide(
                                                    color: Colors.white24,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                      ),
                                                ),
                                                onPressed: () => _moveToNext(
                                                  nowPlaying,
                                                  accepted,
                                                ),
                                                child: const Text(
                                                  'Next',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // UP NEXT header + count
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Up Next',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                Text(
                                  '${upNext.length} in queue',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // UP NEXT list (sorted by tip)
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
                              child: upNext.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No songs queued yet.',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.all(12),
                                      itemCount: upNext.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final item = upNext[index];

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
                                                width: 26,
                                                height: 26,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.grey.shade800,
                                                ),
                                                child: Text(
                                                  '${index + 1}',
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),

                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.songName,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      item.artistName,
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'From: ${_audienceLabel(item.audienceId, displayNames)}',
                                                      style: const TextStyle(
                                                        color: Colors.white60,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              const SizedBox(width: 8),

                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
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
                                                      item.tipAmount > 0
                                                          ? '£${item.tipAmount.toStringAsFixed(2)}'
                                                          : 'No tip',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  const Icon(
                                                    Icons.drag_handle,
                                                    color: Colors.white38,
                                                    size: 18,
                                                  ),
                                                ],
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
              ),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 0),
    );
  }
}
