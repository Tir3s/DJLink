import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class ConnectionsPage extends StatefulWidget {
  final bool isDj;
  final String userId;

  const ConnectionsPage({super.key, required this.isDj, required this.userId});

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  final _firestoreService = FirestoreService();
  late Future<List<Map<String, dynamic>>> _profilesFuture;

  @override
  void initState() {
    super.initState();
    _profilesFuture = widget.isDj
        ? _firestoreService.getFollowerProfiles(widget.userId)
        : _firestoreService.getFollowingDjProfiles(widget.userId);
  }

  String _currency(double value) => '£${value.toStringAsFixed(2)}';

  Future<Map<String, dynamic>> _loadProfileDetails(String profileUserId) async {
    final userData =
        await _firestoreService.getUserDataById(profileUserId) ??
        <String, dynamic>{};

    final role = (userData['role'] as String?) ?? 'audience';
    final metrics = role == 'dj'
        ? await _firestoreService.getDjProfileMetrics(profileUserId)
        : await _firestoreService.getAudienceProfileMetrics(profileUserId);

    final followersCount = await _firestoreService
        .getFollowersCountStream(profileUserId)
        .first;
    final followingCount = await _firestoreService
        .getFollowingCountStream(profileUserId)
        .first;

    return {
      'user': userData,
      'role': role,
      'metrics': metrics,
      'followers_count': followersCount,
      'following_count': followingCount,
    };
  }

  Widget _buildExpandedProfile(Map<String, dynamic> details) {
    final user =
        (details['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final role = (details['role'] as String?) ?? 'audience';
    final isDj = role == 'dj';
    final metrics =
        (details['metrics'] as Map<String, num>?) ?? <String, num>{};

    final socialsRaw = (user['socials'] as Map<String, dynamic>?) ?? {};
    final instagram = (socialsRaw['instagram'] as String?)?.trim() ?? '';
    final snapchat = (socialsRaw['snapchat'] as String?)?.trim() ?? '';
    final tiktok = (socialsRaw['tiktok'] as String?)?.trim() ?? '';

    final followersCount = (details['followers_count'] as int?) ?? 0;
    final followingCount = (details['following_count'] as int?) ?? 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Role: ${isDj ? 'DJ' : 'Audience'}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TinyChip(label: 'Followers', value: '$followersCount'),
              _TinyChip(label: 'Following', value: '$followingCount'),
              _TinyChip(
                label: isDj ? 'Events hosted' : 'Events joined',
                value:
                    '${metrics[isDj ? 'events_hosted' : 'events_joined'] ?? 0}',
              ),
              _TinyChip(
                label: isDj ? 'Requests handled' : 'Requests made',
                value:
                    '${metrics[isDj ? 'requests_handled' : 'requests_made'] ?? 0}',
              ),
              _TinyChip(
                label: isDj ? 'Tips earned' : 'Tips paid',
                value: _currency(
                  (metrics[isDj ? 'tips_earned' : 'tips_paid'] ?? 0).toDouble(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SocialLine(label: 'Instagram', value: instagram),
          _SocialLine(label: 'Snapchat', value: snapchat),
          _SocialLine(label: 'TikTok', value: tiktok),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isDj ? 'Followers' : 'Following DJs';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _profilesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Could not load connections.',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            final profiles = snapshot.data ?? [];
            if (profiles.isEmpty) {
              return Center(
                child: Text(
                  widget.isDj
                      ? 'No followers yet.'
                      : 'Not following any DJs yet.',
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: profiles.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final profile = profiles[index];
                final profileUserId = (profile['user_id'] as String?) ?? '';
                final username =
                    ((profile['username'] as String?)?.trim().isNotEmpty ??
                        false)
                    ? (profile['username'] as String)
                    : 'User';
                final email = (profile['email'] as String?) ?? '';

                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: ExpansionTile(
                    iconColor: Colors.white70,
                    collapsedIconColor: Colors.white54,
                    title: Text(
                      username,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      email,
                      style: const TextStyle(color: Colors.white60),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    children: [
                      if (profileUserId.isEmpty)
                        const Text(
                          'Profile unavailable.',
                          style: TextStyle(color: Colors.white60),
                        )
                      else
                        FutureBuilder<Map<String, dynamic>>(
                          future: _loadProfileDetails(profileUserId),
                          builder: (context, detailSnapshot) {
                            if (detailSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }

                            if (detailSnapshot.hasError) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'Could not load full profile.',
                                  style: TextStyle(color: Colors.white60),
                                ),
                              );
                            }

                            return _buildExpandedProfile(
                              detailSnapshot.data ?? <String, dynamic>{},
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _TinyChip extends StatelessWidget {
  final String label;
  final String value;

  const _TinyChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

class _SocialLine extends StatelessWidget {
  final String label;
  final String value;

  const _SocialLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.white70)),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}
