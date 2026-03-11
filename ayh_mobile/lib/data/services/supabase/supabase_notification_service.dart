import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/notification.dart';
import '../../models/blood_request.dart';

/// Notifications via Supabase (production). Table: donor_notifications (or similar).
class SupabaseNotificationService {
  SupabaseClient get _client => Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<NotificationModel>> getMyNotifications() async {
    final uid = _userId;
    if (uid == null) return [];
    try {
      final list = await _client
          .from('donor_notifications')
          .select('*, blood_requests(*)')
          .eq('donor_id', uid)
          .order('created_at', ascending: false);
      return (list as List).map((e) => _rowToNotification(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<NotificationModel?> getNotificationDetail(int id) async {
    try {
      final res = await _client
          .from('donor_notifications')
          .select('*, blood_requests(*)')
          .eq('id', id)
          .maybeSingle();
      if (res == null) return null;
      return _rowToNotification(res);
    } catch (_) {
      return null;
    }
  }

  Future<bool> markAsRead(int id) async {
    try {
      await _client.from('donor_notifications').update({'is_read': true}).eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      await _client.from('donor_notifications').update({'is_read': true}).eq('donor_id', uid);
      return true;
    } catch (_) {
      return false;
    }
  }

  NotificationModel _rowToNotification(Map<String, dynamic> row) {
    final br = row['blood_requests'];
    return NotificationModel(
      id: row['id'] ?? 0,
      bloodRequest: br != null && br is Map
          ? BloodRequest.fromJson(_brRowToJson(br as Map<String, dynamic>))
          : BloodRequest.fromJson({}),
      isRead: row['is_read'] ?? false,
      createdAt: row['created_at'] != null ? DateTime.parse(row['created_at'].toString()) : DateTime.now(),
      hasResponded: row['has_responded'] ?? false,
      responseStatus: row['response_status']?.toString(),
      respondedAt: row['responded_at'] != null ? DateTime.tryParse(row['responded_at'].toString()) : null,
      distanceKm: _toDouble(row['distance_km']),
    );
  }

  Map<String, dynamic> _brRowToJson(Map<String, dynamic> row) {
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

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
