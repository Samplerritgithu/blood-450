import 'package:supabase_flutter/supabase_flutter.dart';

/// Respond to blood request via Supabase (production). Table: donor_responses or similar.
class SupabaseResponseService {
  SupabaseClient get _client => Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<Map<String, dynamic>> respondToRequest({
    required int bloodRequestId,
    required String response,
  }) async {
    final uid = _userId;
    if (uid == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }
    try {
      await _client.from('donor_responses').upsert({
        'blood_request_id': bloodRequestId,
        'donor_id': uid,
        'response': response,
      }, onConflict: 'blood_request_id,donor_id');
      return {'success': true, 'message': 'Response recorded', 'response': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
