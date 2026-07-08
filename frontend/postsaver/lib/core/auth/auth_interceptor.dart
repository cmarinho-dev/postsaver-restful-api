import 'dart:async';

import 'package:dio/dio.dart';

import 'auth_service.dart';

class AuthInterceptor extends Interceptor {
  final AuthService _authService;
  final Dio _dio;
  Completer<void>? _refreshCompleter;

  AuthInterceptor(this._authService, this._dio);

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
      if (_refreshCompleter != null) {
        await _refreshCompleter!.future;
        if (_authService.accessToken != null) {
          err.requestOptions.headers['Authorization'] =
              'Bearer ${_authService.accessToken}';
          try {
            final response = await _dio.fetch(err.requestOptions);
            handler.resolve(response);
            return;
          } catch (_) {
            handler.next(err);
            return;
          }
        }
      } else {
        _refreshCompleter = Completer<void>();
        try {
          await _authService.refresh();
          _refreshCompleter!.complete();
          _refreshCompleter = null;

          final token = _authService.accessToken;
          if (token != null) {
            err.requestOptions.headers['Authorization'] = 'Bearer $token';
            try {
              final response = await _dio.fetch(err.requestOptions);
              handler.resolve(response);
              return;
            } catch (_) {
              handler.next(err);
              return;
            }
          }
        } catch (e) {
          _refreshCompleter!.completeError(e);
          _refreshCompleter = null;
          await _authService.logout();
        }
      }
    }
    handler.next(err);
  }
}
