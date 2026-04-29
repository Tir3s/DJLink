import 'package:flutter/material.dart';
import '../widgets/main_bottom_nav.dart';
import '../models/app_session.dart';
import '../models/event_model.dart';
import '../services/firestore_service.dart';
import '../models/song_request_model.dart';
import '../models/shoutout_model.dart';

class DjDashboard extends StatelessWidget {
  const DjDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const DjDashboardPage();
  }
}

/// Same widget, different name so either can be used in main.dart
class DjDashboardPage extends StatefulWidget {
  const DjDashboardPage({super.key});

  @override
  State<DjDashboardPage> createState() => _DjDashboardPageState();
}

class _DjDashboardPageState extends State<DjDashboardPage> {
  final FirestoreService _firestoreService = FirestoreService();

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

  Future<void> _showEventSummaryDialog(
    BuildContext context,
    EventSummary event,
  ) async {
    final requests = await _firestoreService.getEventRequestsOnce(event.id);
    final shoutouts = await _firestoreService.getEventShoutouts(event.id).first;
    final played = requests
        .where((req) => req.status == RequestStatus.played)
        .toList();

    final requestTips = played.fold<double>(
      0.0,
      (sum, req) => sum + req.tipAmount,
    );
    final shoutoutTips = shoutouts.fold<double>(
      0.0,
      (sum, shout) => sum + shout.tipAmount,
    );
    final total = requestTips + shoutoutTips;

    final Map<String, double> byAudience = {};
    for (final request in played) {
      byAudience[request.audienceId] =
          (byAudience[request.audienceId] ?? 0.0) + request.tipAmount;
    }

    for (final shoutout in shoutouts) {
      byAudience[shoutout.audienceId] =
          (byAudience[shoutout.audienceId] ?? 0.0) + shoutout.tipAmount;
    }

    final displayNames = await _firestoreService.getUserDisplayNames(
      byAudience.keys,
    );

    final ranked = byAudience.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Event Summary',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Text(
                  'Revenue (requests + shoutouts): £${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Top contributors',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (ranked.isEmpty)
                  const Text(
                    'No played requests yet.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  )
                else
                  ...ranked.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${_audienceLabel(entry.key, displayNames)} - £${entry.value.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _goToRequestsPlaylist(BuildContext context) {
    Navigator.pushNamed(context, '/dj_requests_playlist');
  }

  void _goToSongRequests(BuildContext context) {
    Navigator.pushNamed(context, '/dj_song_requests');
  }

  void _goToShoutouts(BuildContext context) {
    Navigator.pushNamed(context, '/dj_shoutouts');
  }

  void _goToTipsBreakdown(BuildContext context) {
    Navigator.pushNamed(context, '/dj_tips_breakdown');
  }

  void _goToCreateEvent(BuildContext context) {
    Navigator.pushNamed(context, '/dj_create_event');
  }

  void _goToLiveEventsList(BuildContext context) {
    Navigator.pushNamed(context, '/live_events_list');
  }

  void _showTipInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: const Text(
            'Requests and shoutouts are automatically prioritised by tip amount. '
            'Higher tips appear closer to the top of the lists.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        );
      },
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _leaveEvent(BuildContext context) {
    AppSession.selectedEvent = null;
    setState(() {});
    _showSnack(context, 'Left current event');
  }

  Future<void> _setLiveStatus(BuildContext context, bool live) async {
    final event = AppSession.selectedEvent;
    if (event == null) {
      _showSnack(context, 'Create or join an event first.');
      return;
    }

    try {
      await _firestoreService.updateEventStatus(
        event.id,
        live ? EventStatus.active : EventStatus.scheduled,
      );
      AppSession.selectedEvent = EventSummary(
        id: event.id,
        name: event.name,
        venue: event.venue,
        time: live ? 'Live now' : 'Scheduled',
        isLive: live,
      );
      setState(() {});
      _showSnack(context, live ? 'Event is live' : 'Event set to scheduled');
    } catch (e) {
      _showSnack(context, 'Could not update event status');
    }
  }

  Future<void> _endEvent(BuildContext context) async {
    final event = AppSession.selectedEvent;
    if (event == null) {
      _showSnack(context, 'Create or join an event first.');
      return;
    }

    try {
      await _showEventSummaryDialog(context, event);
      await _firestoreService.updateEventStatus(event.id, EventStatus.ended);
      AppSession.selectedEvent = null;
      setState(() {});
      _showSnack(context, 'Event ended');
    } catch (e) {
      _showSnack(context, 'Could not end event');
    }
  }

  @override
  Widget build(BuildContext context) {
    const scaffoldBg = Colors.black;

    final event = AppSession.selectedEvent;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('DJ Dashboard'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CURRENT EVENT CARD (dark theme)
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
                    // Icon bubble
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
                    // Text column
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
                              'Create or join an event, or wait for the audience to link to your event.',
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (event == null) ...[
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () => _goToLiveEventsList(context),
                            child: Column(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white12,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white70,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Join event',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white30),
                            ),
                            child: TextButton(
                              onPressed: () => _goToCreateEvent(context),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                              ),
                              child: const Text(
                                'Create event',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (event != null)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white30),
                            ),
                            child: TextButton(
                              onPressed: () => _leaveEvent(context),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                              ),
                              child: const Text(
                                'Leave event',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        if (event != null) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 34,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: event.isLive
                                    ? Colors.redAccent
                                    : const Color(0xFF4B0082),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              onPressed: () =>
                                  _setLiveStatus(context, !event.isLive),
                              child: Text(
                                event.isLive ? 'Stop live' : 'Go live',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 34,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              onPressed: () => _endEvent(context),
                              child: const Text(
                                'End event',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Controls',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              // TILE BLOCK (light shell with individual cards)
              Container(
                width: double.infinity,
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 170,
                            child: event == null
                                ? _DjTile(
                                    icon: Icons.music_note,
                                    label: 'Song Requests',
                                    subtitle: '0 new',
                                    onTap: () => _goToSongRequests(context),
                                  )
                                : StreamBuilder<List<SongRequest>>(
                                    stream: _firestoreService.getEventRequests(
                                      event.id,
                                    ),
                                    builder: (context, snapshot) {
                                      final requests = snapshot.data ?? [];
                                      final pendingCount = requests
                                          .where(
                                            (req) =>
                                                req.status ==
                                                RequestStatus.pending,
                                          )
                                          .length;

                                      return _DjTile(
                                        icon: Icons.music_note,
                                        label: 'Song Requests',
                                        subtitle: '$pendingCount new',
                                        onTap: () => _goToSongRequests(context),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 170,
                            child: event == null
                                ? _DjTile(
                                    icon: Icons.campaign,
                                    label: 'Shoutouts',
                                    subtitle: '0 waiting',
                                    onTap: () => _goToShoutouts(context),
                                  )
                                : StreamBuilder<List<Shoutout>>(
                                    stream: _firestoreService.getEventShoutouts(
                                      event.id,
                                    ),
                                    builder: (context, snapshot) {
                                      final shoutouts = snapshot.data ?? [];
                                      final pendingCount = shoutouts
                                          .where(
                                            (shoutout) =>
                                                shoutout.status ==
                                                ShoutoutStatus.pending,
                                          )
                                          .length;

                                      return _DjTile(
                                        icon: Icons.campaign,
                                        label: 'Shoutouts',
                                        subtitle: '$pendingCount waiting',
                                        onTap: () => _goToShoutouts(context),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 170,
                            child: event == null
                                ? _DjTile(
                                    icon: Icons.queue_music,
                                    label: 'Requests Playlist',
                                    subtitle: '0 queued',
                                    onTap: () => _goToRequestsPlaylist(context),
                                  )
                                : StreamBuilder<List<SongRequest>>(
                                    stream: _firestoreService.getEventRequests(
                                      event.id,
                                    ),
                                    builder: (context, snapshot) {
                                      final requests = snapshot.data ?? [];
                                      final queuedCount = requests
                                          .where(
                                            (req) =>
                                                req.status ==
                                                RequestStatus.accepted,
                                          )
                                          .length;

                                      return _DjTile(
                                        icon: Icons.queue_music,
                                        label: 'Requests Playlist',
                                        subtitle: '$queuedCount queued',
                                        onTap: () =>
                                            _goToRequestsPlaylist(context),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 170,
                            child: event == null
                                ? _DjTile(
                                    icon: Icons.attach_money,
                                    label: 'Total Tips',
                                    subtitle: '£0.00',
                                    onTap: () => _goToTipsBreakdown(context),
                                    isTotalTips: true,
                                  )
                                : StreamBuilder<List<SongRequest>>(
                                    stream: _firestoreService.getEventRequests(
                                      event.id,
                                    ),
                                    builder: (context, snapshot) {
                                      final requests = snapshot.data ?? [];
                                      final requestTotal = requests
                                          .where(
                                            (req) =>
                                                req.status ==
                                                RequestStatus.played,
                                          )
                                          .fold<double>(
                                            0.0,
                                            (sum, req) => sum + req.tipAmount,
                                          );

                                      return StreamBuilder<List<Shoutout>>(
                                        stream: _firestoreService
                                            .getEventShoutouts(event.id),
                                        builder: (context, shoutSnapshot) {
                                          final shoutouts =
                                              shoutSnapshot.data ?? [];
                                          final shoutoutTotal = shoutouts.fold<
                                            double
                                          >(
                                            0.0,
                                            (sum, shout) =>
                                                sum + shout.tipAmount,
                                          );
                                          final total =
                                              requestTotal + shoutoutTotal;

                                          return _DjTile(
                                            icon: Icons.attach_money,
                                            label: 'Total Tips',
                                            subtitle:
                                                '£${total.toStringAsFixed(2)}',
                                            onTap: () =>
                                                _goToTipsBreakdown(context),
                                            isTotalTips: true,
                                          );
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const MainBottomNav(
        currentIndex: 0, // DJ dashboard tab
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: FloatingActionButton.small(
          heroTag: 'tipInfoFab',
          backgroundColor: Colors.white12,
          foregroundColor: Colors.white,
          onPressed: () => _showTipInfo(context),
          child: const Icon(Icons.question_mark_rounded),
        ),
      ),
    );
  }
}

class _DjTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isTotalTips;
  final String? subtitle;

  const _DjTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isTotalTips = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF4B0082);
    final tileBg = isTotalTips ? Colors.black : Colors.white;
    final primaryText = isTotalTips ? Colors.white : Colors.black87;
    final borderColor = isTotalTips ? purple : Colors.grey.shade300;
    final iconBg = isTotalTips ? Colors.white10 : purple.withOpacity(0.1);
    final iconColor = isTotalTips ? Colors.white : purple;
    final subtitleColor = isTotalTips
        ? Colors.white70
        : primaryText.withOpacity(0.6);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: isTotalTips ? 2 : 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const Spacer(),
                Text(
                  label,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
