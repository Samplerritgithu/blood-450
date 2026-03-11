import '../../core/config/app_environment.dart';
import '../services/dashboard_service.dart';
import '../services/supabase/supabase_dashboard_service.dart';
import '../models/dashboard_stats.dart';

class DashboardRepository {
  final DashboardService _service = DashboardService();
  final SupabaseDashboardService _supabaseService = SupabaseDashboardService();

  Future<DashboardStats?> getDashboardStats() async {
    return AppEnvironment.isSupabaseBackend
        ? await _supabaseService.getDashboardStats()
        : await _service.getDashboardStats();
  }
}
