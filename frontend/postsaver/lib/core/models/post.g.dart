// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PostImpl _$$PostImplFromJson(Map<String, dynamic> json) => _$PostImpl(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  url: json['url'] as String,
  description: json['description'] as String?,
  source: $enumDecode(_$SocialSourceEnumMap, json['source']),
  thumbnailUrl: json['thumbnailUrl'] as String?,
  favorite: json['favorite'] as bool? ?? false,
  folder: json['folder'] == null
      ? null
      : Folder.fromJson(json['folder'] as Map<String, dynamic>),
  tags:
      (json['tags'] as List<dynamic>?)
          ?.map((e) => Tag.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$PostImplToJson(_$PostImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'url': instance.url,
      'description': instance.description,
      'source': _$SocialSourceEnumMap[instance.source]!,
      'thumbnailUrl': instance.thumbnailUrl,
      'favorite': instance.favorite,
      'folder': instance.folder,
      'tags': instance.tags,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$SocialSourceEnumMap = {
  SocialSource.instagram: 'INSTAGRAM',
  SocialSource.tiktok: 'TIKTOK',
  SocialSource.facebook: 'FACEBOOK',
  SocialSource.kwai: 'KWAI',
  SocialSource.youtube: 'YOUTUBE',
  SocialSource.twitter: 'TWITTER',
  SocialSource.other: 'OTHER',
};

_$PostRequestImpl _$$PostRequestImplFromJson(Map<String, dynamic> json) =>
    _$PostRequestImpl(
      title: json['title'] as String,
      url: json['url'] as String,
      description: json['description'] as String?,
      source: $enumDecode(_$SocialSourceEnumMap, json['source']),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      favorite: json['favorite'] as bool?,
      folderId: (json['folderId'] as num?)?.toInt(),
      tagIds: (json['tagIds'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toSet(),
    );

Map<String, dynamic> _$$PostRequestImplToJson(_$PostRequestImpl instance) =>
    <String, dynamic>{
      'title': instance.title,
      'url': instance.url,
      'description': instance.description,
      'source': _$SocialSourceEnumMap[instance.source]!,
      'thumbnailUrl': instance.thumbnailUrl,
      'favorite': instance.favorite,
      'folderId': instance.folderId,
      'tagIds': instance.tagIds?.toList(),
    };
