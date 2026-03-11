import '../../core/config/app_environment.dart';
import '../services/donor_service.dart';
import '../services/supabase/supabase_donor_service.dart';
import '../services/storage_service.dart';
import '../models/donor_profile.dart';

class DonorRepository {
  final DonorService _donorService = DonorService();
  final SupabaseDonorService _supabaseDonorService = SupabaseDonorService();
  final StorageService _storageService = StorageService();

  Future<DonorProfile?> getMyProfile() async {
    final profile = AppEnvironment.isSupabaseBackend
        ? await _supabaseDonorService.getMyProfile()
        : await _donorService.getMyProfile();
    if (profile != null) {
      await _storageService.saveDonorProfile(profile);
    }
    return profile;
  }

  Future<DonorProfile?> createProfile({
    required String phone,
    required String bloodGroup,
    required bool isAvailable,
    double? lastLat,
    double? lastLng,
  }) async {
    final profile = AppEnvironment.isSupabaseBackend
        ? await _supabaseDonorService.createProfile(
            phone: phone,
            bloodGroup: bloodGroup,
            isAvailable: isAvailable,
            lastLat: lastLat,
            lastLng: lastLng,
          )
        : await _donorService.createProfile(
      phone: phone,
      bloodGroup: bloodGroup,
      isAvailable: isAvailable,
            lastLat: lastLat,
            lastLng: lastLng,
          );

    if (profile != null) await _storageService.saveDonorProfile(profile);
    return profile;
  }

  Future<DonorProfile?> updateMyProfile({
    String? phone,
    String? bloodGroup,
    bool? isAvailable,
    double? lastLat,
    double? lastLng,
  }) async {
    final profile = AppEnvironment.isSupabaseBackend
        ? await _supabaseDonorService.updateMyProfile(
            phone: phone,
            bloodGroup: bloodGroup,
            isAvailable: isAvailable,
            lastLat: lastLat,
            lastLng: lastLng,
          )
        : await _donorService.updateMyProfile(
            phone: phone,
            bloodGroup: bloodGroup,
            isAvailable: isAvailable,
            lastLat: lastLat,
            lastLng: lastLng,
          );

    if (profile != null) await _storageService.saveDonorProfile(profile);
    return profile;
  }

  /// Update donor's last-known location (for distance-based matching).
  Future<DonorProfile?> updateMyLocation(double lat, double lng) async {
    return updateMyProfile(lastLat: lat, lastLng: lng);
  }

  Future<List<DonorProfile>> getAllDonors() async {
    return AppEnvironment.isSupabaseBackend
        ? await _supabaseDonorService.getAllDonors()
        : await _donorService.getAllDonors();
  }

  Future<DonorProfile?> getCachedProfile() async {
    return await _storageService.getDonorProfile();
  }
}
