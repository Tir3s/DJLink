import 'package:flutter/material.dart';
import '../session.dart';
import '../screens/dj_dashboard.dart';
import '../screens/audience_dashboard.dart';
import '../screens/discover_events_list_page.dart';
import '../screens/live_events_map_page.dart';
import '../screens/profile_page.dart';

class MainBottomNav extends StatelessWidget {
  final int currentIndex;

  const MainBottomNav({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return; // already on this tab

    Widget page;

    switch (index) {
      case 0: // Dashboard
        page = Session.role == UserRole.dj
            ? const DjDashboard()
            : const AudienceDashboard();
        break;
      case 1: // Discover
        page = const DiscoverEventsListPage();
        break;
      case 2: // Live
        page = const LiveEventsMapPage();
        break;
      case 3: // Profile
        page = const ProfilePage();
        break;
      default:
        return;
    }

    // Use instant transition for smooth tab switching
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Discover'),
        BottomNavigationBarItem(
          icon: Icon(Icons.wifi_tethering),
          label: 'Live',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}
