import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/dashboard_stats.dart';
import '../../models/blood_request.dart';

/// Dashboard stats via Supabase (production). Aggregates from blood_requests and donor_profiles.
class SupabaseDashboardService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<DashboardStats?> getDashboardStats() async {
    try {
      final requests = await _client.from('blood_requests').select();
      final donors = await _client.from('donor_profiles').select();
      final list = requests as List;
      final donorList = donors as List;
      final totalRequests = list.length;
      final activeRequests = list.where((e) => (e as Map)['is_active'] == true).length;
      final totalDonors = donorList.length;
      final availableDonors = donorList.where((e) => (e as Map)['is_available'] == true).length;
      final recent = list.take(10).map((e) => BloodRequest.fromJson(_brRow(e as Map<String, dynamic>))).toList();
      int totalAccepted = 0;
      int critical = 0;
      for (final r in list) {
        final m = r as Map;
        totalAccepted += (m['accepted_count'] as num?)?.toInt() ?? 0;
        if ((m['urgency'] as String?) == 'critical') critical++;
      }
      return DashboardStats(
        totalRequests: totalRequests,
        activeRequests: activeRequests,
        totalDonors: totalDonors,
        availableDonors: availableDonors,
        totalAccepted: totalAccepted,
        criticalRequests: critical,
        recentRequests: recent,
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _brRow(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'blood_group': row['blood_group'] ?? '',
      'units_needed': row['units_needed'] ?? 1,
      'urgency': row['urgency'] ?? 'normal',
      'urgency_display': row['urgency_display'] ?? row['urgency'] ?? 'Normal',
      'note': row['note'] ?? '',
      'created_by': row['created_by'],
      'is_active': row['is_active'] ?? true,
      'created_at': row['created_at']?.toString(),
      'notified_count': row['notified_count'] ?? 0,
      'accepted_count': row['accepted_count'] ?? 0,
      'req_lat': row['req_lat'],
      'req_lng': row['req_lng'],
      'location_name': row['location_name'],
      'radius_km': row['radius_km'] ?? 10.0,
    };
  }
}
