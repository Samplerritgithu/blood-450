import '../../core/api/api_client.dart';
import '../../core/constants/api_constants.dart';

class ResponseService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> respondToRequest({
    required int bloodRequestId,
    required String response, // 'accepted' or 'rejected'
  }) async {
    try {
      final apiResponse = await _apiClient.post(
        ApiConstants.respond,
        data: {
          'blood_request_id': bloodRequestId,
          'response': response,
        },
      );

      if (apiResponse.statusCode == 200) {
        return {
          'success': true,
          'message': apiResponse.data['message'],
          'response': apiResponse.data['response'],
        };
      }
      return {'success': false, 'error': 'Failed to respond'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
