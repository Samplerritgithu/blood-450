import '../../core/config/app_environment.dart';
import '../services/blood_request_service.dart';
import '../services/supabase/supabase_blood_request_service.dart';
import '../models/blood_request.dart';

class BloodRequestRepository {
  final BloodRequestService _service = BloodRequestService();
  final SupabaseBloodRequestService _supabaseService = SupabaseBloodRequestService();

  Future<List<BloodRequest>> getAllRequests() async {
    return AppEnvironment.isSupabaseBackend
        ? await _supabaseService.getAllRequests()
        : await _service.getAllRequests();
  }

  Future<List<BloodRequest>> getActiveRequests() async {
    return AppEnvironment.isSupabaseBackend
        ? await _supabaseService.getActiveRequests()
        : await _service.getActiveRequests();
  }

  Future<List<BloodRequest>> getMyRequests() async {
    return AppEnvironment.isSupabaseBackend
        ? await _supabaseService.getMyRequests()
        : await _service.getMyRequests();
  }

  Future<BloodRequest?> getRequestDetail(int id) async {
    return AppEnvironment.isSupabaseBackend
        ? await _supabaseService.getRequestDetail(id)
        : await _service.getRequestDetail(id);
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
    return AppEnvironment.isSupabaseBackend
        ? await _supabaseService.createRequest(
            bloodGroup: bloodGroup,
            unitsNeeded: unitsNeeded,
            urgency: urgency,
            note: note,
            reqLat: reqLat,
            reqLng: reqLng,
            locationName: locationName,
            radiusKm: radiusKm,
          )
        : await _service.createRequest(
            bloodGroup: bloodGroup,
            unitsNeeded: unitsNeeded,
            urgency: urgency,
            note: note,
            reqLat: reqLat,
            reqLng: reqLng,
            locationName: locationName,
            radiusKm: radiusKm,
          );
  }

  Future<bool> updateRequest(int id, {bool? isActive}) async {
    return AppEnvironment.isSupabaseBackend
        ? await _supabaseService.updateRequest(id, isActive: isActive)
        : await _service.updateRequest(id, isActive: isActive);
  }

  Future<bool> deleteRequest(int id) async {
    return AppEnvironment.isSupabaseBackend
        ? await _supabaseService.deleteRequest(id)
        : await _service.deleteRequest(id);
  }
}
