import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/main_bottom_nav.dart';
import '../models/song_request_model.dart';
import '../models/app_session.dart';
import '../models/ban_list_model.dart';
import '../services/firestore_service.dart';

class DjSongRequestsPage extends StatefulWidget {
  const DjSongRequestsPage({super.key});

  @override
  State<DjSongRequestsPage> createState() => _DjSongRequestsPageState();
}

class _DjSongRequestsPageState extends State<DjSongRequestsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  String _filter = 'pending';

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
        return 'Playing Now';
      case RequestStatus.played:
        return 'Played';
      case RequestStatus.banned:
        return 'Banned';
    }
  }

  Future<void> _updateRequestStatus(
    String requestId,
    RequestStatus newStatus,
  ) async {
    try {
      await _firestoreService.updateRequestStatus(requestId, newStatus);

      // Update analytics
      if (AppSession.selectedEvent != null) {
        await _firestoreService.updateEventAnalytics(
          AppSession.selectedEvent!.id,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request ${_statusLabel(newStatus).toLowerCase()}'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _banAudience(SongRequest request) async {
    final djId = FirebaseAuth.instance.currentUser?.uid;
    if (djId == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please log in again.')));
      }
      return;
    }

    try {
      final ban = BanList(
        banId: '',
        djId: djId,
        audienceId: request.audienceId,
        reason: 'Banned from requests',
        dateBanned: DateTime.now(),
      );
      await _firestoreService.addBan(ban);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Audience banned. Existing requests stay unchanged; new ones are blocked.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error banning audience: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (AppSession.selectedEvent == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: const Text('Song Requests')),
        body: const Center(child: Text('No active event selected')),
        bottomNavigationBar: const MainBottomNav(currentIndex: 0),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Song Requests')),
      body: SafeArea(
        child: StreamBuilder<List<SongRequest>>(
          stream: _firestoreService.getEventRequests(
            AppSession.selectedEvent!.id,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No song requests yet'));
            }

            final allRequests = snapshot.data!;
            final requests = _filter == 'all'
                ? List<SongRequest>.from(allRequests)
                : allRequests
                      .where(
                        (request) =>
                            SongRequest.statusToString(request.status) ==
                            _filter,
                      )
                      .toList();

            if (_filter == 'pending') {
              requests.sort((a, b) => b.tipAmount.compareTo(a.tipAmount));
            } else if (_filter == 'all') {
              requests.sort((a, b) {
                if (a.status == RequestStatus.pending &&
                    b.status != RequestStatus.pending) {
                  return -1;
                }
                if (a.status != RequestStatus.pending &&
                    b.status == RequestStatus.pending) {
                  return 1;
                }
                return b.timestamp.compareTo(a.timestamp);
              });
            } else {
              requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            }

            return Column(
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterIcon(
                          icon: Icons.all_inbox,
                          label: 'All',
                          isSelected: _filter == 'all',
                          onTap: () => setState(() => _filter = 'all'),
                        ),
                        const SizedBox(width: 16),
                        _FilterIcon(
                          icon: Icons.hourglass_top,
                          label: 'Pending',
                          isSelected: _filter == 'pending',
                          onTap: () => setState(() => _filter = 'pending'),
                        ),
                        const SizedBox(width: 16),
                        _FilterIcon(
                          icon: Icons.check_circle,
                          label: 'Accepted',
                          isSelected: _filter == 'accepted',
                          onTap: () => setState(() => _filter = 'accepted'),
                        ),
                        const SizedBox(width: 16),
                        _FilterIcon(
                          icon: Icons.playlist_play,
                          label: 'Played',
                          isSelected: _filter == 'played',
                          onTap: () => setState(() => _filter = 'played'),
                        ),
                        const SizedBox(width: 16),
                        _FilterIcon(
                          icon: Icons.cancel,
                          label: 'Denied',
                          isSelected: _filter == 'declined',
                          onTap: () => setState(() => _filter = 'declined'),
                        ),
                        const SizedBox(width: 16),
                        _FilterIcon(
                          icon: Icons.block,
                          label: 'Banned',
                          isSelected: _filter == 'banned',
                          onTap: () => setState(() => _filter = 'banned'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];

                      return Card(
                        color: const Color(0xFF1E1E1E),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          request.songName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          request.artistName,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (request.tipAmount > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4B0082),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            '£${request.tipAmount.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _statusColor(
                                            request.status,
                                          ).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: _statusColor(request.status),
                                          ),
                                        ),
                                        child: Text(
                                          _statusLabel(request.status),
                                          style: TextStyle(
                                            color: _statusColor(request.status),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (request.comment.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  request.comment,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: TextButton.icon(
                                      onPressed: () => _updateRequestStatus(
                                        request.requestId,
                                        RequestStatus.accepted,
                                      ),
                                      icon: const Icon(Icons.check, size: 18),
                                      label: const Text('Accept'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.greenAccent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextButton.icon(
                                      onPressed: () => _updateRequestStatus(
                                        request.requestId,
                                        RequestStatus.declined,
                                      ),
                                      icon: const Icon(Icons.close, size: 18),
                                      label: const Text('Decline'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextButton.icon(
                                      onPressed: () => _banAudience(request),
                                      icon: const Icon(Icons.block, size: 18),
                                      label: const Text('Ban'),
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            Colors.deepPurpleAccent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 0),
    );
  }
}

class _FilterIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterIcon({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF4B0082) : Colors.white10,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white24 : Colors.white12,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
