import 'dart:io';

class ApiConstants {
  /// When using a **physical phone** on WiFi (not emulator), set this to your PC's IP.
  /// Example: 'http://192.168.1.5:8000/api/'
  /// Find your IP: Windows: ipconfig → IPv4 | Mac/Linux: ifconfig or ip addr
  /// Leave null for emulator (Android uses 10.0.2.2, iOS uses localhost).
  static const String? baseUrlOverride = null;

  // Base URL - use override when set (for physical device on WiFi), else platform default
  static String get baseUrl {
    if (baseUrlOverride != null && baseUrlOverride!.isNotEmpty) {
      return baseUrlOverride!.endsWith('/')
          ? baseUrlOverride!
          : '${baseUrlOverride!}/';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/'; // Android emulator
    } else if (Platform.isIOS) {
      return 'http://localhost:8000/api/';
    } else {
      return 'http://localhost:8000/api/';
    }
  }

  // Authentication endpoints
  static const String login = 'auth/login/';
  static const String register = 'auth/register/';
  static const String logout = 'auth/logout/';
  static const String currentUser = 'auth/me/';
  static const String tokenRefresh = 'auth/token/refresh/';

  // Donor profile endpoints
  static const String donors = 'donors/';
  static const String donorMe = 'donors/me/';
  static const String donorUpdateMe = 'donors/update_me/';

  // Blood request endpoints
  static const String bloodRequests = 'blood-requests/';
  static const String bloodRequestsActive = 'blood-requests/active/';
  static const String bloodRequestsMyRequests = 'blood-requests/my_requests/';

  // Notification endpoints
  static const String notifications = 'notifications/';
  static const String notificationMarkAllRead = 'notifications/mark_all_read/';

  // Response endpoint
  static const String respond = 'respond/';

  // Dashboard endpoint
  static const String dashboard = 'dashboard/';

  /// Default radius in km for location-based blood request matching (must match backend DEFAULT_RADIUS_KM).
  static const double defaultRadiusKm = 10.0;
}
