import 'package:dio/dio.dart';
import '../models/booking.dart';
import '../models/time_slot.dart';
import 'api_client.dart';

class BookingService {
  const BookingService(this._apiClient);

  final ApiClient _apiClient;

  List<Booking> _bookingListFromResponse(dynamic data) {
    if (data is List) {
      return data
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();
    } else if (data is Map<String, dynamic> && data.containsKey('results')) {
      final results = data['results'] as List;
      return results
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<Booking>> fetchMyBookings() async {
    try {
      final response = await _apiClient.dio.get('/bookings/my/');
      return _bookingListFromResponse(response.data);
    } on DioException catch (error) {
      throw BookingException(_messageFromDio(error));
    }
  }

  Future<Booking?> fetchBookingById(String id) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/bookings/my/$id/',
      );
      if (response.data != null) {
        return Booking.fromJson(response.data!);
      }
      return null;
    } on DioException catch (error) {
      throw BookingException(_messageFromDio(error));
    }
  }

  Future<Booking> createBooking({
    required String vehicleType,
    required String vehicleNumber,
    required String washPackage,
    required String date,
    required String timeSlot,
    String? contactPhone,
    String? address,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/bookings/my/',
        data: {
          'vehicle_type': vehicleType,
          'vehicle_number': vehicleNumber,
          'wash_package': washPackage,
          'date': date,
          'time_slot': timeSlot,
          if (contactPhone != null && contactPhone.isNotEmpty)
            'contact_phone': contactPhone,
          if (address != null && address.isNotEmpty) 'address': address,
        },
      );
      if (response.data != null) {
        return Booking.fromJson(response.data!);
      }
      throw const BookingException('Booking response was empty.');
    } on DioException catch (error) {
      throw BookingException(_messageFromDio(error));
    }
  }

  Future<Booking> updateBooking(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.patch<Map<String, dynamic>>(
        '/bookings/my/$id/',
        data: data,
      );
      if (response.data != null) {
        return Booking.fromJson(response.data!);
      }
      throw const BookingException('Booking response was empty.');
    } on DioException catch (error) {
      throw BookingException(_messageFromDio(error));
    }
  }

  Future<void> cancelBooking(String id) async {
    try {
      await _apiClient.dio.delete('/bookings/my/$id/');
    } on DioException catch (error) {
      throw BookingException(_messageFromDio(error));
    }
  }

  Future<List<TimeSlot>> fetchSlots(String date, String packageType) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/bookings/slots/',
        queryParameters: {'date': date, 'package': packageType},
      );
      final data = response.data;
      if (data != null && data.containsKey('slots')) {
        final slotsList = data['slots'] as List;
        return slotsList
            .map((json) => TimeSlot.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (error) {
      throw BookingException(_messageFromDio(error));
    }
  }

  Future<List<Booking>> fetchQueue({bool mine = false}) async {
    try {
      final response = await _apiClient.dio.get(
        '/bookings/queue/',
        queryParameters: {if (mine) 'mine': 'true'},
      );
      return _bookingListFromResponse(response.data);
    } on DioException catch (error) {
      throw BookingException(_messageFromDio(error));
    }
  }

  Future<List<Booking>> fetchAdminBookings({
    int page = 1,
    String? status,
    String? search,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/bookings/admin/',
        queryParameters: {
          'page': page,
          if (status != null && status != 'all') 'status': status,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
      );
      return _bookingListFromResponse(response.data);
    } on DioException catch (error) {
      throw BookingException(_messageFromDio(error));
    }
  }

  Future<Map<String, dynamic>> fetchAdminStats() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/bookings/admin/stats/',
      );
      return response.data ?? {};
    } on DioException catch (error) {
      throw BookingException(_messageFromDio(error));
    }
  }

  Future<Map<String, dynamic>> fetchAdminTeamStats() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/bookings/admin/team-stats/',
      );
      return response.data ?? {};
    } on DioException catch (error) {
      throw BookingException(_messageFromDio(error));
    }
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      await _apiClient.dio.patch(
        '/bookings/queue/$id/',
        data: {'status': status},
      );
    } on DioException catch (error) {
      throw BookingException(_messageFromDio(error));
    }
  }

  String _messageFromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['detail'] ?? data['error'];
      if (message is String && message.isNotEmpty) return message;
      // Handle array error lists e.g. status: ["invalid status"]
      final firstKey = data.keys.firstOrNull;
      if (firstKey != null && data[firstKey] is List) {
        return (data[firstKey] as List).join(', ');
      }
    }
    return 'Something went wrong with bookings. Please try again.';
  }
}

class BookingException implements Exception {
  const BookingException(this.message);

  final String message;

  @override
  String toString() => message;
}
