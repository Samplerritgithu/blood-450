import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user.dart' as app_models;
import '../../models/donor_profile.dart';

/// Auth via Supabase (production). Maps Supabase Auth + donor_profiles to app models.
class SupabaseAuthService {
  GoTrueClient get _auth => Supabase.instance.client.auth;

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      // Supabase Auth uses email + password; accept email or username as identifier
      final response = await _auth.signInWithPassword(
        password: password,
        email: username.contains('@') ? username : '$username@temp.ayh.local',
      );
      if (response.session == null) {
        return {'success': false, 'error': 'Login failed'};
      }
      final user = response.user!;
      final appUser = _supabaseUserToAppUser(user);
      DonorProfile? donorProfile = await _fetchDonorProfile(user.id);
      return {
        'success': true,
        'access': response.session!.accessToken,
        'refresh': response.session!.refreshToken ?? '',
        'user': appUser,
        'has_donor_profile': donorProfile != null,
        'donor_profile': donorProfile,
      };
    } on AuthException catch (e) {
      return {'success': false, 'error': e.message};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    String? firstName,
    String? lastName,
  }) async {
    if (password != passwordConfirm) {
      return {'success': false, 'error': 'Passwords do not match'};
    }
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'full_name': '${firstName ?? ''} ${lastName ?? ''}'.trim(),
        },
      );
      if (response.session == null && response.user == null) {
        return {'success': false, 'error': 'Registration failed'};
      }
      final user = response.user!;
      final appUser = _supabaseUserToAppUser(user);
      return {
        'success': true,
        'access': response.session?.accessToken ?? '',
        'refresh': response.session?.refreshToken ?? '',
        'user': appUser,
        'message': 'Please confirm your email to sign in.',
      };
    } on AuthException catch (e) {
      return {'success': false, 'error': e.message};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final session = _auth.currentSession;
      if (session == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      final user = session.user;
      final appUser = _supabaseUserToAppUser(user);
      DonorProfile? donorProfile = await _fetchDonorProfile(user.id);
      return {
        'success': true,
        'user': appUser,
        'has_donor_profile': donorProfile != null,
        'donor_profile': donorProfile,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> logout(String refreshToken) async {
    try {
      await _auth.signOut();
      return true;
    } catch (_) {
      return false;
    }
  }

  app_models.User _supabaseUserToAppUser(User supabaseUser) {
    final meta = supabaseUser.userMetadata ?? {};
    final name = (meta['full_name'] as String?) ?? '';
    final parts = name.split(' ');
    return app_models.User(
      id: 0,
      username: (meta['username'] as String?) ?? supabaseUser.email ?? '',
      email: supabaseUser.email ?? '',
      firstName: parts.isNotEmpty ? parts.first : '',
      lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
      isStaff: false,
    );
  }

  Future<DonorProfile?> _fetchDonorProfile(String userId) async {
    try {
      final res = await Supabase.instance.client
          .from('donor_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (res == null) return null;
      return DonorProfile.fromJson(_donorRowToJson(res));
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _donorRowToJson(Map<String, dynamic> row) {
    return {
      'id': row['id'] ?? 0,
      'username': '',
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
