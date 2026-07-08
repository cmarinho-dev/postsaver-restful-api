import 'package:dio/dio.dart';

import '../models/user.dart';
import 'api_client.dart';
import 'api_error_handler.dart';

Future<User> registerUser({
  required String name,
  required String username,
  required String email,
  required String password,
}) async {
  final dio = createApiClient();

  try {
    final response = await dio.post(
      '/users',
      data: UserRequest(
        name: name,
        username: username,
        email: email,
        password: password,
      ).toJson(),
    );

    return User.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw handleApiError(e);
  }
}
