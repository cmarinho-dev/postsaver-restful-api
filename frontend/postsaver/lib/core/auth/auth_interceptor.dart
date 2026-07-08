import 'package:dio/dio.dart';

import 'auth_service.dart';

class AuthInterceptor extends Interceptor {
  final AuthService _authService;

  AuthInterceptor(this._authService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _authService.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        await _authService.refresh();
        final token = _authService.accessToken;
        if (token != null) {
          err.requestOptions.headers['Authorization'] = 'Bearer $token';
          final response = await Dio().fetch(err.requestOptions);
          handler.resolve(response);
          return;
        }
      } catch (_) {
        await _authService.logout();
      }
    }
    handler.next(err);
  }
}
