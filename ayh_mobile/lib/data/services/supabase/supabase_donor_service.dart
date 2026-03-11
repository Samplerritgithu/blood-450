import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/donor_profile.dart';

/// Donor profile CRUD via Supabase (production). Table: donor_profiles.
class SupabaseDonorService {
  SupabaseClient get _client => Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<DonorProfile?> getMyProfile() async {
    final uid = _userId;
    if (uid == null) return null;
    try {
      final res = await _client
          .from('donor_profiles')
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      if (res == null) return null;
      return DonorProfile.fromJson(_rowToJson(res));
    } catch (_) {
      return null;
    }
  }

  Future<DonorProfile?> createProfile({
    required String phone,
    required String bloodGroup,
    required bool isAvailable,
    double? lastLat,
    double? lastLng,
  }) async {
    final uid = _userId;
    if (uid == null) return null;
    try {
      final data = <String, dynamic>{
        'user_id': uid,
        'phone': phone,
        'blood_group': bloodGroup,
        'is_available': isAvailable,
      };
      if (lastLat != null) data['last_lat'] = lastLat;
      if (lastLng != null) data['last_lng'] = lastLng;
      final res = await _client.from('donor_profiles').insert(data).select().single();
      return DonorProfile.fromJson(_rowToJson(res));
    } catch (_) {
      return null;
    }
  }

  Future<DonorProfile?> updateMyProfile({
    String? phone,
    String? bloodGroup,
    bool? isAvailable,
    double? lastLat,
    double? lastLng,
  }) async {
    final uid = _userId;
    if (uid == null) return null;
    try {
      final data = <String, dynamic>{};
      if (phone != null) data['phone'] = phone;
      if (bloodGroup != null) data['blood_group'] = bloodGroup;
      if (isAvailable != null) data['is_available'] = isAvailable;
      if (lastLat != null) data['last_lat'] = lastLat;
      if (lastLng != null) data['last_lng'] = lastLng;
      if (data.isEmpty) return getMyProfile();
      final res = await _client
          .from('donor_profiles')
          .update(data)
          .eq('user_id', uid)
          .select()
          .single();
      return DonorProfile.fromJson(_rowToJson(res));
    } catch (_) {
      return null;
    }
  }

  Future<List<DonorProfile>> getAllDonors() async {
    try {
      final list = await _client.from('donor_profiles').select();
      return (list as List)
          .map((e) => DonorProfile.fromJson(_rowToJson(e as Map<String, dynamic>)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Map<String, dynamic> _rowToJson(Map<String, dynamic> row) {
    return {
      'id': row['id'] ?? 0,
      'username': row['username'] ?? '',
      'phone': row['phone'] ?? '',
      'blood_group': row['blood_group'] ?? '',
      'is_available': row['is_available'] ?? true,
      'created_at': row['created_at']?.toString(),
      'last_lat': row['last_lat'],
      'last_lng': row['last_lng'],
      'location_updated_at': row['location_updated_at']?.toString(),
    };
  }
}
