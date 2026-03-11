import '../../core/config/app_environment.dart';
import '../services/notification_service.dart';
import '../services/response_service.dart';
import '../services/supabase/supabase_notification_service.dart';
import '../services/supabase/supabase_response_service.dart';
import '../models/notification.dart';

class NotificationRepository {
  final NotificationService _notificationService = NotificationService();
  final ResponseService _responseService = ResponseService();
  final SupabaseNotificationService _supabaseNotificationService = SupabaseNotificationService();
  final SupabaseResponseService _supabaseResponseService = SupabaseResponseService();

  Future<List<NotificationModel>> getMyNotifications() async {
    return AppEnvironment.isSupabaseBackend
        ? await _supabaseNotificationService.getMyNotifications()
        : await _notificationService.getMyNotifications();
  }

  Future<NotificationModel?> getNotificationDetail(int id) async {
    return AppEnvironment.isSupabaseBackend
        ? await _supabaseNotificationService.getNotificationDetail(id)
        : await _notificationService.getNotificationDetail(id);
  }

  Future<bool> markAsRead(int id) async {
    return AppEnvironment.isSupabaseBackend
        ? await _supabaseNotificationService.markAsRead(id)
        : await _notificationService.markAsRead(id);
  }

  Future<bool> markAllAsRead() async {
    return AppEnvironment.isSupabaseBackend
        ? await _supabaseNotificationService.markAllAsRead()
        : await _notificationService.markAllAsRead();
  }

  Future<Map<String, dynamic>> respondToRequest({
    required int bloodRequestId,
    required String response,
  }) async {
    return AppEnvironment.isSupabaseBackend
        ? await _supabaseResponseService.respondToRequest(
            bloodRequestId: bloodRequestId,
            response: response,
          )
        : await _responseService.respondToRequest(
            bloodRequestId: bloodRequestId,
            response: response,
          );
  }
}
