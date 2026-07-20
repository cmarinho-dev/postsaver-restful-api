import 'package:dio/dio.dart';

import '../models/url_metadata.dart';
import 'api_error_handler.dart';

Future<UrlMetadata> fetchUrlMetadata({
  required Dio dio,
  required String url,
}) async {
  try {
    final response = await dio.get(
      '/url-metadata',
      queryParameters: {'url': url},
    );
    return UrlMetadata.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw handleApiError(e);
  }
}
