import 'package:flutter/material.dart';
import '../widgets/main_bottom_nav.dart';

class DjSongRequestsPage extends StatefulWidget {
  const DjSongRequestsPage({super.key});

  @override
  State<DjSongRequestsPage> createState() => _DjSongRequestsPageState();
}

class _DjSongRequestsPageState extends State<DjSongRequestsPage> {
  // Tip is core: every request has a tip and we prioritise higher tips first.
  final List<Map<String, dynamic>> _requests = [
    {
      'song': 'One More Time',
      'artist': 'Daft Punk',
      'from': 'Table 4',
      'tip': 5,
      'status': 'Pending',
    },
    {
      'song': 'Titanium',
      'artist': 'David Guetta ft. Sia',
      'from': 'Sarah',
      'tip': 3,
      'status': 'Pending',
    },
    {
      'song': 'Pepas',
      'artist': 'Farruko',
      'from': 'VIP Booth',
      'tip': 10,
      'status': 'Pending',
    },
    {
      'song': 'Bohemian Rhapsody',
      'artist': 'Queen',
      'from': 'Bar Group',
      'tip': 2,
      'status': 'Pending',
    },
  ];

  String _filter = 'All';

  List<Map<String, dynamic>> get _filteredRequests {
    // Filter by status
    List<Map<String, dynamic>> list;
    if (_filter == 'All') {
      list = List.of(_requests);
    } else {
      list = _requests.where((r) => r['status'] == _filter).toList();
    }

    // Sort by tip DESC (higher tip = higher in the list)
    list.sort((a, b) => (b['tip'] as int).compareTo(a['tip'] as int));
    return list;
  }

  void _updateStatus(int index, String newStatus) {
    setState(() {
      _requests[index]['status'] = newStatus;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request ${newStatus.toLowerCase()}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orangeAccent;
      case 'Accepted':
        return Colors.blueAccent;
      case 'Denied':
        return Colors.redAccent;
      case 'Banned':
        return Colors.deepPurpleAccent;
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF4B0082);
    const darkBg = Colors.black;

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Song Requests',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
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
                    isSelected: _filter == 'All',
                    onTap: () => setState(() => _filter = 'All'),
                  ),
                  _FilterChip(
                    label: 'Pending',
                    isSelected: _filter == 'Pending',
                    onTap: () => setState(() => _filter = 'Pending'),
                  ),
                  _FilterChip(
                    label: 'Accepted',
                    isSelected: _filter == 'Accepted',
                    onTap: () => setState(() => _filter = 'Accepted'),
                  ),
                  _FilterChip(
                    label: 'Denied',
                    isSelected: _filter == 'Denied',
                    onTap: () => setState(() => _filter = 'Denied'),
                  ),
                  _FilterChip(
                    label: 'Banned',
                    isSelected: _filter == 'Banned',
                    onTap: () => setState(() => _filter = 'Banned'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _filteredRequests.isEmpty
                    ? const Center(
                        child: Text(
                          'No requests in this filter yet.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filteredRequests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final req = _filteredRequests[index];
                          // Map back to original list index
                          final originalIndex = _requests.indexOf(req);
                          final status = req['status'] as String;
                          final tip = req['tip'] as int;
                          final statusColor = _statusColor(status);

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: main info + tip
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Left: main info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            req['song'] as String,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            req['artist'] as String,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'From: ${req['from']}',
                                            style: const TextStyle(
                                              color: Colors.white60,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    // Right: tip badge (always present)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: purple,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        '£$tip',
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

                                // Status text
                                Text(
                                  'Status: $status',
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Action buttons: Accept / Deny / Ban
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: TextButton.icon(
                                        onPressed: status == 'Accepted'
                                            ? null
                                            : () => _updateStatus(
                                                originalIndex,
                                                'Accepted',
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
                                        onPressed: status == 'Denied'
                                            ? null
                                            : () => _updateStatus(
                                                originalIndex,
                                                'Denied',
                                              ),
                                        icon: const Icon(Icons.close, size: 18),
                                        label: const Text('Deny'),
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
                                        onPressed: status == 'Banned'
                                            ? null
                                            : () => _updateStatus(
                                                originalIndex,
                                                'Banned',
                                              ),
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
          borderRadius: BorderRadius.circular(20),
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
