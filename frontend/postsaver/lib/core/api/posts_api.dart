import 'package:dio/dio.dart';

import '../models/page.dart';
import '../models/post.dart';
import 'api_error_handler.dart';

Future<PageResponse<Post>> getPosts({
  required Dio dio,
  String? q,
  String? source,
  int? folderId,
  int? tagId,
  bool? favorite,
  int page = 0,
  int size = 20,
  String sort = 'updatedAt,desc',
}) async {
  try {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      'sort': sort,
    };
    if (q != null) queryParams['q'] = q;
    if (source != null) queryParams['source'] = source;
    if (folderId != null) queryParams['folderId'] = folderId;
    if (tagId != null) queryParams['tagId'] = tagId;
    if (favorite != null) queryParams['favorite'] = favorite;

    final response = await dio.get('/posts', queryParameters: queryParams);

    return PageResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Post.fromJson(json! as Map<String, dynamic>),
    );
  } on DioException catch (e) {
    throw handleApiError(e);
  }
}

Future<Post> getPost({
  required Dio dio,
  required int id,
}) async {
  try {
    final response = await dio.get('/posts/$id');
    return Post.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw handleApiError(e);
  }
}

Future<Post> createPost({
  required Dio dio,
  required PostRequest post,
}) async {
  try {
    final response = await dio.post('/posts', data: post.toJson());
    return Post.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw handleApiError(e);
  }
}

Future<Post> updatePost({
  required Dio dio,
  required int id,
  required PostRequest post,
}) async {
  try {
    final response = await dio.put('/posts/$id', data: post.toJson());
    return Post.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw handleApiError(e);
  }
}

Future<void> deletePost({
  required Dio dio,
  required int id,
}) async {
  try {
    await dio.delete('/posts/$id');
  } on DioException catch (e) {
    throw handleApiError(e);
  }
}

Future<Post> toggleFavorite({
  required Dio dio,
  required int id,
}) async {
  try {
    final response = await dio.patch('/posts/$id/favorite');
    return Post.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw handleApiError(e);
  }
}
