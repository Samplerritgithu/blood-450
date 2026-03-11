import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/blood_request.dart';

/// Blood requests via Supabase (production). Table: blood_requests.
class SupabaseBloodRequestService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<BloodRequest>> getAllRequests() async {
    try {
      final list = await _client.from('blood_requests').select().order('created_at', ascending: false);
      return (list as List).map((e) => BloodRequest.fromJson(_rowToJson(e as Map<String, dynamic>))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<BloodRequest>> getActiveRequests() async {
    try {
      final list = await _client
          .from('blood_requests')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);
      return (list as List).map((e) => BloodRequest.fromJson(_rowToJson(e as Map<String, dynamic>))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<BloodRequest>> getMyRequests() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    try {
      final list = await _client
          .from('blood_requests')
          .select()
          .eq('created_by', uid)
          .order('created_at', ascending: false);
      return (list as List).map((e) => BloodRequest.fromJson(_rowToJson(e as Map<String, dynamic>))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<BloodRequest?> getRequestDetail(int id) async {
    try {
      final res = await _client.from('blood_requests').select().eq('id', id).maybeSingle();
      if (res == null) return null;
      return BloodRequest.fromJson(_rowToJson(res));
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> createRequest({
    required String bloodGroup,
    required int unitsNeeded,
    required String urgency,
    String? note,
    double? reqLat,
    double? reqLng,
    String? locationName,
    double? radiusKm,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }
    try {
      final data = <String, dynamic>{
        'created_by': uid,
        'blood_group': bloodGroup,
        'units_needed': unitsNeeded,
        'urgency': urgency,
        'note': note ?? '',
        'radius_km': radiusKm ?? 10.0,
      };
      if (reqLat != null) data['req_lat'] = reqLat;
      if (reqLng != null) data['req_lng'] = reqLng;
      if (locationName != null && locationName.isNotEmpty) data['location_name'] = locationName;
      final res = await _client.from('blood_requests').insert(data).select().single();
      final bloodRequest = BloodRequest.fromJson(_rowToJson(res));
      return {
        'success': true,
        'message': 'Request created',
        'blood_request': bloodRequest,
        'matched_donors': <MatchedDonor>[],
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> updateRequest(int id, {bool? isActive}) async {
    if (isActive == null) return true;
    try {
      await _client.from('blood_requests').update({'is_active': isActive}).eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteRequest(int id) async {
    try {
      await _client.from('blood_requests').delete().eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _rowToJson(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'blood_group': row['blood_group'] ?? '',
      'units_needed': row['units_needed'] ?? 1,
      'urgency': row['urgency'] ?? 'normal',
      'urgency_display': row['urgency_display'] ?? row['urgency'] ?? 'Normal',
      'note': row['note'] ?? '',
      'created_by': row['created_by'],
      'created_by_username': null,
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
