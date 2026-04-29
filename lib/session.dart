import 'models/user_model.dart';

// Export UserRole so other files can import from session.dart
export 'models/user_model.dart' show UserRole;

class Session {
  static UserRole? role; // set on welcome screen

  static String getDashboardRoute() {
    if (role == UserRole.dj) return '/dj_dashboard';
    return '/audience_dashboard';
  }

  static String getRoleLabel() {
    switch (role) {
      case UserRole.dj:
        return 'DJ';
      case UserRole.audience:
        return 'Audience';
      default:
        return '';
    }
  }
}
