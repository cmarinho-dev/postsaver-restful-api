import 'package:freezed_annotation/freezed_annotation.dart';

part 'folder.freezed.dart';
part 'folder.g.dart';

@freezed
class Folder with _$Folder {
  const factory Folder({
    required int id,
    required String name,
    String? description,
    String? color,
    required DateTime createdAt,
  }) = _Folder;

  factory Folder.fromJson(Map<String, dynamic> json) => _$FolderFromJson(json);
}

@freezed
class FolderRequest with _$FolderRequest {
  const factory FolderRequest({
    required String name,
    String? description,
    String? color,
  }) = _FolderRequest;

  factory FolderRequest.fromJson(Map<String, dynamic> json) =>
      _$FolderRequestFromJson(json);
}
