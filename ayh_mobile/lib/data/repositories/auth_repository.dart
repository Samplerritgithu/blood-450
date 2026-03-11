import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/app_environment.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/supabase/supabase_auth_service.dart';
import '../models/user.dart' as app_models;
import '../models/donor_profile.dart';

class AuthRepository {
  final AuthService _authService = AuthService();
  final SupabaseAuthService _supabaseAuthService = SupabaseAuthService();
  final StorageService _storageService = StorageService();

  Future<Map<String, dynamic>> login(String username, String password) async {
    final result = AppEnvironment.isSupabaseBackend
        ? await _supabaseAuthService.login(username, password)
        : await _authService.login(username, password);

    if (result['success']) {
      if (!AppEnvironment.isSupabaseBackend) {
        await _storageService.saveTokens(
          result['access'] as String,
          result['refresh'] as String,
        );
      }
      await _storageService.saveUser(result['user'] as app_models.User);
      if (result['donor_profile'] != null) {
        await _storageService.saveDonorProfile(result['donor_profile'] as DonorProfile);
      }
    }

    return result;
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    String? firstName,
    String? lastName,
  }) async {
    final result = AppEnvironment.isSupabaseBackend
        ? await _supabaseAuthService.register(
            username: username,
            email: email,
            password: password,
            passwordConfirm: passwordConfirm,
            firstName: firstName,
            lastName: lastName,
          )
        : await _authService.register(
            username: username,
            email: email,
            password: password,
            passwordConfirm: passwordConfirm,
            firstName: firstName,
            lastName: lastName,
          );

    if (result['success']) {
      if (!AppEnvironment.isSupabaseBackend) {
        await _storageService.saveTokens(
          result['access'] as String,
          result['refresh'] as String,
        );
      }
      await _storageService.saveUser(result['user'] as app_models.User);
    }

    return result;
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    return AppEnvironment.isSupabaseBackend
        ? await _supabaseAuthService.getCurrentUser()
        : await _authService.getCurrentUser();
  }

  Future<void> logout() async {
    if (AppEnvironment.isSupabaseBackend) {
      await _supabaseAuthService.logout('');
    } else {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken != null) await _authService.logout(refreshToken);
    }
    await _storageService.clearAll();
  }

  Future<app_models.User?> getCachedUser() async {
    return await _storageService.getUser();
  }

  Future<DonorProfile?> getCachedDonorProfile() async {
    return await _storageService.getDonorProfile();
  }

  Future<bool> isLoggedIn() async {
    if (AppEnvironment.isSupabaseBackend) {
      try {
        return Supabase.instance.client.auth.currentSession != null;
      } catch (_) {
        return false;
      }
    }
    return await _storageService.isLoggedIn();
  }
}
