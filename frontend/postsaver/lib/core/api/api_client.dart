import 'package:dio/dio.dart';

import '../config/environment.dart';

Dio createApiClient({List<Interceptor>? interceptors}) {
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

  if (interceptors != null) {
    dio.interceptors.addAll(interceptors);
  }

  return dio;
}
