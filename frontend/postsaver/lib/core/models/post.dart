import 'package:freezed_annotation/freezed_annotation.dart';

import 'folder.dart';
import 'social_source.dart';
import 'tag.dart';

part 'post.freezed.dart';
part 'post.g.dart';

@freezed
class Post with _$Post {
  const factory Post({
    required int id,
    required String title,
    required String url,
    String? description,
    required SocialSource source,
    String? thumbnailUrl,
    @Default(false) bool favorite,
    Folder? folder,
    @Default([]) List<Tag> tags,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}

@freezed
class PostRequest with _$PostRequest {
  const factory PostRequest({
    required String title,
    required String url,
    String? description,
    required SocialSource source,
    String? thumbnailUrl,
    bool? favorite,
    int? folderId,
    Set<int>? tagIds,
  }) = _PostRequest;

  factory PostRequest.fromJson(Map<String, dynamic> json) =>
      _$PostRequestFromJson(json);
}
