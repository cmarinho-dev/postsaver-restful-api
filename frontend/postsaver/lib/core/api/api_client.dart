import 'package:dio/dio.dart';

import '../config/environment.dart';

Dio createApiClient() {
  final baseUrl = '${Environment.current.apiBase}/api/v1';

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  return dio;
}
