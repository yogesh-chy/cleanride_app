import 'package:dio/dio.dart';
import 'api_client.dart';

class PaymentService {
  const PaymentService(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> initiatePayment({
    required String bookingId,
    required String returnUrl,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/payments/initiate/',
        data: {
          'booking_id': int.tryParse(bookingId) ?? bookingId,
          'return_url': returnUrl,
        },
      );
      return response.data ?? {};
    } on DioException catch (error) {
      throw PaymentException(_messageFromDio(error));
    }
  }

  Future<Map<String, dynamic>> verifyPayment({
    required String pidx,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/payments/verify/',
        data: {
          'pidx': pidx,
        },
      );
      return response.data ?? {};
    } on DioException catch (error) {
      throw PaymentException(_messageFromDio(error));
    }
  }

  String _messageFromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['detail'] ?? data['error'];
      if (message is String && message.isNotEmpty) return message;
    }
    return 'Payment processing failed. Please try again.';
  }
}

class PaymentException implements Exception {
  const PaymentException(this.message);

  final String message;

  @override
  String toString() => message;
}
