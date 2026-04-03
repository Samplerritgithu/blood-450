class ApiConstants {
  /// Development: Local Django server
  /// For production, change to: 'https://blood-450-gqkc.vercel.app/api/'
  static const String baseUrl = 'http://127.0.0.1:8000/api/';

  static const String login = 'auth/login/';
  static const String register = 'auth/register/';
  static const String logout = 'auth/logout/';
  static const String currentUser = 'auth/me/';
  static const String tokenRefresh = 'auth/token/refresh/';

  static const String donors = 'donors/';
  static const String donorMe = 'donors/me/';
  static const String donorUpdateMe = 'donors/update_me/';

  static const String bloodRequests = 'blood-requests/';
  static const String bloodRequestsActive = 'blood-requests/active/';
  static const String bloodRequestsMyRequests = 'blood-requests/my_requests/';

  static const String notifications = 'notifications/';
  static const String notificationMarkAllRead = 'notifications/mark_all_read/';

  static const String respond = 'respond/';
  static const String dashboard = 'dashboard/';

  static const double defaultRadiusKm = 10.0;
}