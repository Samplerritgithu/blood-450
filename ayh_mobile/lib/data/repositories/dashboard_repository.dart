import '../services/dashboard_service.dart';
import '../models/dashboard_stats.dart';

class DashboardRepository {
  final DashboardService _service = DashboardService();

  Future<DashboardStats?> getDashboardStats() async {
    return await _service.getDashboardStats();
  }
}
