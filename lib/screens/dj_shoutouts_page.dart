import 'package:flutter/material.dart';
import '../models/app_session.dart';
import '../models/shoutout_model.dart';
import '../services/firestore_service.dart';
import '../widgets/main_bottom_nav.dart';

class DjShoutoutsPage extends StatefulWidget {
  const DjShoutoutsPage({super.key});

  @override
  State<DjShoutoutsPage> createState() => _DjShoutoutsPageState();
}

class _DjShoutoutsPageState extends State<DjShoutoutsPage> {
  final FirestoreService _firestoreService = FirestoreService();

  String _filter = 'all';

  Color _statusColor(ShoutoutStatus status) {
    switch (status) {
      case ShoutoutStatus.pending:
        return Colors.orangeAccent;
      case ShoutoutStatus.accepted:
        return Colors.blueAccent;
      case ShoutoutStatus.denied:
        return Colors.redAccent;
      case ShoutoutStatus.banned:
        return Colors.deepPurpleAccent;
    }
  }

  String _statusLabel(ShoutoutStatus status) {
    switch (status) {
      case ShoutoutStatus.pending:
        return 'Pending';
      case ShoutoutStatus.accepted:
        return 'Accepted';
      case ShoutoutStatus.denied:
        return 'Denied';
      case ShoutoutStatus.banned:
        return 'Banned';
    }
  }

  Future<void> _updateStatus(
    String shoutoutId,
    ShoutoutStatus newStatus,
  ) async {
    try {
      await _firestoreService.updateShoutoutStatus(shoutoutId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shoutout ${_statusLabel(newStatus).toLowerCase()}'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating shoutout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkBg = Colors.black;
    const purple = Color(0xFF4B0082);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Shoutouts', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: AppSession.selectedEvent == null
            ? const Center(child: Text('No active event selected'))
            : Column(
                children: [
                  const SizedBox(height: 8),

                  // Filter chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _FilterChip(
                          label: 'All',
                          isSelected: _filter == 'all',
                          onTap: () => setState(() => _filter = 'all'),
                        ),
                        _FilterChip(
                          label: 'Pending',
                          isSelected: _filter == 'pending',
                          onTap: () => setState(() => _filter = 'pending'),
                        ),
                        _FilterChip(
                          label: 'Accepted',
                          isSelected: _filter == 'accepted',
                          onTap: () => setState(() => _filter = 'accepted'),
                        ),
                        _FilterChip(
                          label: 'Denied',
                          isSelected: _filter == 'denied',
                          onTap: () => setState(() => _filter = 'denied'),
                        ),
                        _FilterChip(
                          label: 'Banned',
                          isSelected: _filter == 'banned',
                          onTap: () => setState(() => _filter = 'banned'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

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
                      child: StreamBuilder<List<Shoutout>>(
                        stream: _firestoreService.getEventShoutouts(
                          AppSession.selectedEvent!.id,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }

                          final all = snapshot.data ?? [];
                          final filtered = _filter == 'all'
                              ? List<Shoutout>.from(all)
                              : all
                                    .where(
                                      (s) =>
                                          Shoutout.statusToString(s.status) ==
                                          _filter,
                                    )
                                    .toList();

                          filtered.sort(
                            (a, b) => b.timestamp.compareTo(a.timestamp),
                          );

                          if (filtered.isEmpty) {
                            return const Center(
                              child: Text(
                                'No shoutouts in this filter yet.',
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final shout = filtered[index];
                              final statusColor = _statusColor(shout.status);

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade900,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                shout.name.isEmpty
                                                    ? 'Shoutout'
                                                    : 'For: ${shout.name}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                shout.message,
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(width: 8),

                                        if (shout.tipAmount > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: purple,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              '£${shout.tipAmount.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    Text(
                                      'Status: ${_statusLabel(shout.status)}',
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: TextButton.icon(
                                            onPressed:
                                                shout.status ==
                                                    ShoutoutStatus.accepted
                                                ? null
                                                : () => _updateStatus(
                                                    shout.shoutoutId,
                                                    ShoutoutStatus.accepted,
                                                  ),
                                            icon: const Icon(
                                              Icons.check,
                                              size: 18,
                                            ),
                                            label: const Text('Accept'),
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  Colors.greenAccent,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: TextButton.icon(
                                            onPressed:
                                                shout.status ==
                                                    ShoutoutStatus.denied
                                                ? null
                                                : () => _updateStatus(
                                                    shout.shoutoutId,
                                                    ShoutoutStatus.denied,
                                                  ),
                                            icon: const Icon(
                                              Icons.close,
                                              size: 18,
                                            ),
                                            label: const Text('Deny'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.redAccent,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: TextButton.icon(
                                            onPressed:
                                                shout.status ==
                                                    ShoutoutStatus.banned
                                                ? null
                                                : () => _updateStatus(
                                                    shout.shoutoutId,
                                                    ShoutoutStatus.banned,
                                                  ),
                                            icon: const Icon(
                                              Icons.block,
                                              size: 18,
                                            ),
                                            label: const Text('Ban'),
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  Colors.deepPurpleAccent,
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 0),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF4B0082);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? purple : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isSelected ? purple : Colors.white38),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
