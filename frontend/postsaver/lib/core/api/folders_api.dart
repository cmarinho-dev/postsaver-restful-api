import 'package:dio/dio.dart';

import '../models/folder.dart';
import 'api_error_handler.dart';

Future<List<Folder>> getFolders({required Dio dio}) async {
  try {
    final response = await dio.get('/folders');
    final data = response.data as List;
    return data.map((e) => Folder.fromJson(e as Map<String, dynamic>)).toList();
  } on DioException catch (e) {
    throw handleApiError(e);
  }
}

Future<Folder> createFolder({
  required Dio dio,
  required FolderRequest folder,
}) async {
  try {
    final response = await dio.post('/folders', data: folder.toJson());
    return Folder.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw handleApiError(e);
  }
}

Future<Folder> updateFolder({
  required Dio dio,
  required int id,
  required FolderRequest folder,
}) async {
  try {
    final response = await dio.put('/folders/$id', data: folder.toJson());
    return Folder.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw handleApiError(e);
  }
}

Future<void> deleteFolder({
  required Dio dio,
  required int id,
}) async {
  try {
    await dio.delete('/folders/$id');
  } on DioException catch (e) {
    throw handleApiError(e);
  }
}
