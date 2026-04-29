# DJ Link - Copilot Instructions

## Project Overview

**DJ Link** is a Flutter mobile app that enables crowd-interactive music requests at live events. Users adopt one of two roles: **DJ** (event organizer) or **Audience** (attendee), each with distinct dashboards and workflows.

### Core Architecture

- **Single-app duality**: One codebase serves both DJ and Audience users via role-based navigation
- **Simple global state**: Uses static session classes (`session.dart`, `app_session.dart`) for lightweight user role and event tracking—no state management framework yet (Provider/Riverpod could be added later)
- **Material 3 dark theme**: Dark background (Colors.black), purple accents (#4B0082), and Material 3 design system
- **Named route navigation**: All screen transitions use named routes defined in `main.dart` (e.g., `/dj_dashboard`, `/audience_dashboard`)

## Code Organization

```
lib/
  main.dart              → App shell, theme config, route definitions
  session.dart           → UserRole enum + Session.role static; role routing logic
  models/
    app_session.dart     → EventSummary model, AppSession global state
  screens/               → 17 screen implementations (login, dashboards, etc.)
  widgets/
    main_bottom_nav.dart → Shared 4-tab bottom navigation (role-aware)
```

## Key Patterns & Conventions

### Session Management
- **`Session.role`** (UserRole enum: `dj` or `audience`) is set at welcome screen and drives dashboard routing
- Use `Session.getDashboardRoute()` to navigate to the correct dashboard based on role
- **`AppSession.selectedEvent`** holds the active event (EventSummary with id, name, venue, time, isLive)

### Screen Structure
Screens are **StatelessWidget** classes with consistent patterns:
```dart
class DjDashboard extends StatelessWidget {
  const DjDashboard({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(...),
      bottomNavigationBar: MainBottomNav(currentIndex: 0),
    );
  }
}
```
- Always include `SafeArea` for device notches
- Use `MainBottomNav(currentIndex: X)` on dashboard screens
- Navigation via `Navigator.pushNamed(context, '/route_name')`

### Bottom Navigation
- Shared across DJ and Audience after login: Dashboard, Discover, Live, Profile
- `MainBottomNav` uses `Navigator.pushReplacementNamed()` to swap screens cleanly
- Tab indices: 0=Dashboard, 1=Discover, 2=Live, 3=Profile

### Styling
- **Colors**: Dark theme with blacks/greys + purple (#4B0082) for emphasis
- **Spacing**: Horizontal padding typically 24dp, vertical 16dp
- **Pills/Chips**: Use `Container` with `BorderRadius.circular(20)` for rounded labels
- **Icons**: Material `Icons.*` for standard UI elements

## Screen Inventory

### Authentication Flow
- `welcome_screen.dart` → Role selection (DJ/Audience)
- `login_page.dart`, `register_page.dart` → Credentials

### DJ Screens
- `dj_dashboard.dart` → Main hub (event control, quick links)
- `dj_create_join_event_page.dart` → Create/join an event
- `dj_requests_playlist_page.dart` → Song request queue
- `dj_song_requests_page.dart` → Manage requested songs
- `dj_shoutouts_page.dart` → Crowd shoutouts
- `dj_tips_breakdown_page.dart` → Earnings/tips analytics

### Audience Screens
- `audience_dashboard.dart` → Main hub (event discovery, actions)
- `audience_request_song_page.dart` → Submit song requests
- `audience_shoutouts_page.dart` → Send/view shoutouts

### Shared Screens
- `live_events_list_page.dart` / `live_events_map_page.dart` → Browse active events (list/map views)
- `discover_events_list_page.dart` / `discover_events_map_page.dart` → Find upcoming events
- `profile_page.dart` → User profile / settings

## Development Workflows

### Running the App
```bash
flutter pub get              # Fetch dependencies
flutter run                  # Debug on connected device/emulator
flutter run -d macos         # Target macOS (if building for desktop)
```

### Building & Testing
```bash
flutter analyze              # Lint check (configured in analysis_options.yaml)
flutter test                 # Run unit/widget tests (test/ directory)
flutter build apk            # Android release
flutter build ios            # iOS release
```

### Code Style
- Follows `flutter_lints` rules (in `analysis_options.yaml`)
- Use **const constructors** wherever possible for widget performance
- **Null safety** enabled (SDK ^3.10.1)
- Prefer **single-line if expressions** and trailing commas for readability

## Important Notes

- **No backend yet**: EventSummary and AppSession are UI placeholders; real data fetching would be added to Session or a new service layer
- **Responsive design**: Screens assume mobile-first (portrait orientation primarily)
- **Next steps for state management**: Consider migrating to Provider or Riverpod when session complexity grows beyond static variables
