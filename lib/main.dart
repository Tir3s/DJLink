import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/welcome_screen.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/dj_dashboard.dart';
import 'screens/audience_dashboard.dart';
import 'screens/live_events_list_page.dart';
import 'screens/live_events_map_page.dart';
import 'screens/discover_events_list_page.dart';
import 'screens/discover_events_map_page.dart';
import 'screens/profile_page.dart';
import 'screens/dj_create_join_event_page.dart';
import 'screens/dj_requests_playlist_page.dart';
import 'screens/dj_song_requests_realtime.dart' as realtime_dj;
import 'screens/dj_shoutouts_page.dart';
import 'screens/audience_request_song_realtime.dart' as realtime_audience;
import 'screens/audience_shoutouts_page.dart';
import 'screens/dj_tips_breakdown_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DJ Link',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),

      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),

        '/dj_dashboard': (context) => const DjDashboard(),
        '/audience_dashboard': (context) => const AudienceDashboard(),

        '/live_events_list': (context) => const LiveEventsListPage(),
        '/live_events_map': (context) => const LiveEventsMapPage(),

        '/discover_events_list': (context) => const DiscoverEventsListPage(),
        '/discover_events_map': (context) => const DiscoverEventsMapPage(),

        '/profile': (context) => const ProfilePage(),

        '/dj_create_event': (context) => const DjCreateJoinEventPage(),
        '/dj_requests_playlist': (context) => const DjRequestsPlaylistPage(),
        '/dj_song_requests': (context) =>
            const realtime_dj.DjSongRequestsPage(),
        '/dj_shoutouts': (context) => const DjShoutoutsPage(),

        '/audience_request_song': (context) =>
            const realtime_audience.AudienceRequestSongPageRealtime(),
        '/audience_shoutouts': (context) => const AudienceShoutoutsPage(),

        '/dj_tips_breakdown': (context) => const DjTipsBreakdownPage(),
      },
    );
  }
}
