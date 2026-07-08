import 'package:dio/dio.dart';

import '../models/tag.dart';
import 'api_error_handler.dart';

Future<List<Tag>> getTags({required Dio dio}) async {
  try {
    final response = await dio.get('/tags');
    final data = response.data as List;
    return data.map((e) => Tag.fromJson(e as Map<String, dynamic>)).toList();
  } on DioException catch (e) {
    throw handleApiError(e);
  }
}

Future<Tag> createTag({
  required Dio dio,
  required TagRequest tag,
}) async {
  try {
    final response = await dio.post('/tags', data: tag.toJson());
    return Tag.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw handleApiError(e);
  }
}

Future<Tag> updateTag({
  required Dio dio,
  required int id,
  required TagRequest tag,
}) async {
  try {
    final response = await dio.put('/tags/$id', data: tag.toJson());
    return Tag.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw handleApiError(e);
  }
}

Future<void> deleteTag({
  required Dio dio,
  required int id,
}) async {
  try {
    await dio.delete('/tags/$id');
  } on DioException catch (e) {
    throw handleApiError(e);
  }
}
