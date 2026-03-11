/// Central configuration for backend environment.
///
/// **Development (default):** Flutter app → Django API → Database
/// **Production:** Flutter app → Supabase (auth + database)
///
/// Set at build time via dart-define, e.g. for production:
///   flutter build apk --dart-define=USE_SUPABASE=true \
///     --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=your_anon_key
///
/// Do NOT commit SUPABASE_ANON_KEY to the repo; use CI secrets or --dart-define-from-file.
class AppEnvironment {
  AppEnvironment._();

  /// When true, app uses Supabase for auth and data (production).
  /// When false, app uses Django REST API (local development).
  static const bool useSupabase =
      bool.fromEnvironment('USE_SUPABASE', defaultValue: false);

  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');

  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  /// Use Django API (when Supabase is not configured or not selected).
  static bool get isDjangoBackend => !isSupabaseConfigured;
  /// Use Supabase (when USE_SUPABASE=true and URL + anon key are set).
  static bool get isSupabaseBackend => isSupabaseConfigured;

  /// Valid for production: URL and anon key must be set when useSupabase is true.
  static bool get isSupabaseConfigured =>
      useSupabase && supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
