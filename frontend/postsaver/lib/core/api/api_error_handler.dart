import 'package:dio/dio.dart';

import '../models/api_error.dart';

ApiError handleApiError(DioException error) {
  final statusCode = error.response?.statusCode ?? 0;
  final data = error.response?.data;

  if (data is Map<String, dynamic>) {
    try {
      return ApiError.fromJson(data);
    } catch (_) {
      return ApiError(
        status: statusCode,
        message: _messageForStatus(statusCode),
      );
    }
  }

  return ApiError(
    status: statusCode,
    message: _messageForStatus(statusCode),
  );
}

String _messageForStatus(int status) {
  switch (status) {
    case 400:
      return 'Bad request. Please check your input.';
    case 401:
      return 'Authentication required. Please sign in again.';
    case 403:
      return 'You do not have permission to perform this action.';
    case 404:
      return 'The requested resource was not found.';
    case 409:
      return 'A conflict occurred. The resource may have been modified.';
    case 422:
      return 'Validation error. Please check your input.';
    case 429:
      return 'Too many requests. Please try again later.';
    case 500:
      return 'Server error. Please try again later.';
    case 502:
      return 'Bad gateway. Please try again later.';
    case 503:
      return 'Service unavailable. Please try again later.';
    default:
      return 'An unexpected error occurred. Please try again.';
  }
}
