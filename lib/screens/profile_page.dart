import 'package:flutter/material.dart';
import '../widgets/main_bottom_nav.dart';
import '../session.dart';
import '../models/app_session.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/remember_me_service.dart';
import 'connections_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  String? _userId;

  @override
  void initState() {
    super.initState();
    final currentUser = _authService.currentUser;
    _userId = currentUser?.uid;
  }

  Future<Map<String, num>> _loadMetrics(String userId, String roleFromDoc) {
    final isDj = Session.role == UserRole.dj || roleFromDoc == 'dj';
    if (isDj) {
      return _firestoreService.getDjProfileMetrics(userId);
    }
    return _firestoreService.getAudienceProfileMetrics(userId);
  }

  String _currency(double value) {
    return '£${value.toStringAsFixed(2)}';
  }

  Future<void> _pickAvatarIcon(
    BuildContext context,
    String userId,
    int? currentIconCodePoint,
  ) async {
    const choices = <IconData>[
      Icons.person,
      Icons.music_note,
      Icons.headphones,
      Icons.queue_music,
      Icons.mic,
      Icons.star,
      Icons.bolt,
      Icons.emoji_events,
      Icons.nightlife,
      Icons.album,
    ];

    final selected = await showDialog<IconData>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Choose profile icon'),
          content: SizedBox(
            width: 320,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: choices
                  .map(
                    (icon) => InkWell(
                      onTap: () => Navigator.of(dialogContext).pop(icon),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: currentIconCodePoint == icon.codePoint
                              ? const Color(0xFF4B0082)
                              : const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Icon(icon, color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selected == null) return;

    await _firestoreService.updateUserAvatarIcon(userId, selected.codePoint);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile icon updated.')));
  }

  Future<void> _showConnectionsList(
    BuildContext context,
    bool isDj,
    String userId,
  ) async {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConnectionsPage(isDj: isDj, userId: userId),
      ),
    );
  }

  Future<void> _followDjFromCurrentEvent(
    BuildContext context,
    String userId,
  ) async {
    final selectedEvent = AppSession.selectedEvent;
    if (selectedEvent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Join an event first to follow a DJ.')),
      );
      return;
    }

    try {
      final event = await _firestoreService.getEvent(selectedEvent.id);
      if (event == null) {
        throw Exception('Current event no longer exists.');
      }

      final alreadyFollowing = await _firestoreService.isFollowingDj(
        audienceId: userId,
        djId: event.djId,
      );
      if (alreadyFollowing) {
        throw Exception('You are already following this DJ.');
      }

      await _firestoreService.followDjFromEvent(
        audienceId: userId,
        eventId: selectedEvent.id,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('DJ followed successfully.')),
      );
      setState(() {});
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final rememberMeService = RememberMeService();

    await rememberMeService.forgetCurrentUserIfExpired();
    if (_authService.currentUser == null) {
      await _authService.signOut();
    }

    Session.role = null;
    AppSession.selectedEvent = null;
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
  }

  Future<void> _showPayouts(BuildContext context, String userId) async {
    final isDj = Session.role == UserRole.dj;
    final payouts = isDj
        ? await _firestoreService.getDjPayoutsByEvent(userId)
        : await _firestoreService.getAudiencePaymentsByEvent(userId);

    final names = await _firestoreService.getEventNamesByIds(payouts.keys);
    final rows = payouts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = rows.fold<double>(0, (sum, entry) => sum + entry.value);
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDj ? 'Total received' : 'Total paid',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  _currency(total),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'No payout data yet.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                else
                  SizedBox(
                    height: 320,
                    child: ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: Colors.white12, height: 1),
                      itemBuilder: (context, index) {
                        final entry = rows[index];
                        final eventName = names[entry.key] ?? entry.key;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            eventName,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            'Event code: ${entry.key}',
                            style: const TextStyle(color: Colors.white60),
                          ),
                          trailing: Text(
                            _currency(entry.value),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editSocials(
    BuildContext context,
    String userId,
    Map<String, String> currentSocials,
  ) async {
    var instagram = currentSocials['instagram'] ?? '';
    var snapchat = currentSocials['snapchat'] ?? '';
    var tiktok = currentSocials['tiktok'] ?? '';

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit socials'),
          content: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(dialogContext).unfocus(),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: instagram,
                    onChanged: (value) => instagram = value,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Instagram'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: snapchat,
                    onChanged: (value) => snapchat = value,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Snapchat'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: tiktok,
                    onChanged: (value) => tiktok = value,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(dialogContext).unfocus(),
                    decoration: const InputDecoration(labelText: 'TikTok'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved == true) {
      await _firestoreService.updateUserSocials(userId, {
        'instagram': instagram.trim(),
        'snapchat': snapchat.trim(),
        'tiktok': tiktok.trim(),
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Social links updated.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF4B0082);

    if (_userId == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Profile'),
        ),
        body: const Center(
          child: Text(
            'No user is signed in.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profile'),
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _firestoreService.getUserDataStream(_userId!),
        builder: (context, userSnapshot) {
          final userData = userSnapshot.data ?? <String, dynamic>{};
          final username = (userData['username'] as String?)?.trim();
          final email = (userData['email'] as String?)?.trim() ?? '';
          final roleFromDoc = (userData['role'] as String?) ?? '';
          final avatarIconCodePoint = (userData['avatar_icon'] as num?)
              ?.toInt();
          final roleLabel = Session.getRoleLabel().isNotEmpty
              ? Session.getRoleLabel()
              : (roleFromDoc == 'dj' ? 'DJ' : 'Audience');

          final socialsRaw =
              (userData['socials'] as Map<String, dynamic>?) ?? {};
          final socials = {
            'instagram': (socialsRaw['instagram'] as String?)?.trim() ?? '',
            'snapchat': (socialsRaw['snapchat'] as String?)?.trim() ?? '',
            'tiktok': (socialsRaw['tiktok'] as String?)?.trim() ?? '',
          };

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: purple.withValues(alpha: 0.25),
                          child: avatarIconCodePoint != null
                              ? Icon(
                                  IconData(
                                    avatarIconCodePoint,
                                    fontFamily: 'MaterialIcons',
                                  ),
                                  color: Colors.white,
                                  size: 28,
                                )
                              : Text(
                                  (username?.isNotEmpty ?? false)
                                      ? username![0].toUpperCase()
                                      : (roleLabel.isNotEmpty
                                            ? roleLabel[0].toUpperCase()
                                            : 'U'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 22,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (username?.isNotEmpty ?? false)
                                    ? username!
                                    : 'User',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email.isNotEmpty ? email : 'No email',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Role: $roleLabel',
                                style: const TextStyle(color: Colors.white54),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  StreamBuilder<int>(
                                    stream: (roleFromDoc == 'dj')
                                        ? _firestoreService
                                              .getFollowersCountStream(_userId!)
                                        : _firestoreService
                                              .getFollowingCountStream(
                                                _userId!,
                                              ),
                                    builder: (context, snapshot) {
                                      final count = snapshot.data ?? 0;
                                      final label = roleFromDoc == 'dj'
                                          ? 'Followers'
                                          : 'Following DJs';
                                      return _HeaderPill(
                                        label: label,
                                        value: '$count',
                                        onTap: () => _showConnectionsList(
                                          context,
                                          roleFromDoc == 'dj',
                                          _userId!,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _HeaderPill(
                                    label: 'Edit',
                                    value: '',
                                    onTap: () => _pickAvatarIcon(
                                      context,
                                      _userId!,
                                      avatarIconCodePoint,
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

                  const SizedBox(height: 16),

                  if (roleFromDoc != 'dj')
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4B0082),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () =>
                            _followDjFromCurrentEvent(context, _userId!),
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Follow DJ From Current Event'),
                      ),
                    ),

                  FutureBuilder<Map<String, num>>(
                    future: _loadMetrics(_userId!, roleFromDoc),
                    builder: (context, metricsSnapshot) {
                      final metrics = metricsSnapshot.data ?? <String, num>{};
                      final isDj =
                          Session.role == UserRole.dj || roleFromDoc == 'dj';

                      final cards = isDj
                          ? [
                              _MiniStat(
                                title: 'Events hosted',
                                value: (metrics['events_hosted'] ?? 0)
                                    .toDouble(),
                                icon: Icons.event,
                              ),
                              _MiniStat(
                                title: 'Requests handled',
                                value: (metrics['requests_handled'] ?? 0)
                                    .toDouble(),
                                icon: Icons.queue_music,
                              ),
                              _MiniStat(
                                title: 'Tips earned',
                                value: (metrics['tips_earned'] ?? 0).toDouble(),
                                isCurrency: true,
                                icon: Icons.payments,
                              ),
                            ]
                          : [
                              _MiniStat(
                                title: 'Events joined',
                                value: (metrics['events_joined'] ?? 0)
                                    .toDouble(),
                                icon: Icons.event_available,
                              ),
                              _MiniStat(
                                title: 'Requests made',
                                value: (metrics['requests_made'] ?? 0)
                                    .toDouble(),
                                icon: Icons.library_music,
                              ),
                              _MiniStat(
                                title: 'Tips paid',
                                value: (metrics['tips_paid'] ?? 0).toDouble(),
                                isCurrency: true,
                                icon: Icons.money_off,
                              ),
                            ];

                      return Row(
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 10),
                          Expanded(child: cards[1]),
                          const SizedBox(width: 10),
                          Expanded(child: cards[2]),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Social media',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  _editSocials(context, _userId!, socials),
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        _SocialRow(
                          label: 'Instagram',
                          value: socials['instagram']!,
                          icon: Icons.camera_alt_outlined,
                        ),
                        _SocialRow(
                          label: 'Snapchat',
                          value: socials['snapchat']!,
                          icon: Icons.chat_bubble_outline,
                        ),
                        _SocialRow(
                          label: 'TikTok',
                          value: socials['tiktok']!,
                          icon: Icons.music_note,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        _ActionButton(
                          label: 'View payouts',
                          icon: Icons.payments,
                          onTap: () => _showPayouts(context, _userId!),
                        ),
                        const SizedBox(height: 10),
                        _ActionButton(
                          label: 'Sign out',
                          icon: Icons.logout,
                          isDestructive: true,
                          onTap: () => _signOut(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _HeaderPill({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          value.isEmpty ? label : '$label $value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String title;
  final double value;
  final bool isCurrency;
  final IconData icon;

  const _MiniStat({
    required this.title,
    required this.value,
    required this.icon,
    this.isCurrency = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 10),
          _SlotValueText(value, isCurrency: isCurrency),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SlotValueText extends StatelessWidget {
  final double value;
  final bool isCurrency;

  const _SlotValueText(this.value, {this.isCurrency = false});

  String _format(double v) {
    if (isCurrency) {
      return '£${v.toStringAsFixed(2)}';
    }
    return v.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 2300),
      curve: Curves.easeOutQuart,
      builder: (context, animatedValue, _) {
        final display = _format(animatedValue);
        return Text(
          display,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        );
      },
    );
  }
}

class _SocialRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SocialRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final text = value.isEmpty ? 'Add $label' : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            text,
            style: TextStyle(
              color: value.isEmpty ? Colors.white54 : Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.redAccent : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }
}
