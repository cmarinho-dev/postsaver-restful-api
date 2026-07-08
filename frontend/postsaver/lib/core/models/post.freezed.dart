// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Post _$PostFromJson(Map<String, dynamic> json) {
  return _Post.fromJson(json);
}

/// @nodoc
mixin _$Post {
  int get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  SocialSource get source => throw _privateConstructorUsedError;
  String? get thumbnailUrl => throw _privateConstructorUsedError;
  bool get favorite => throw _privateConstructorUsedError;
  Folder? get folder => throw _privateConstructorUsedError;
  List<Tag> get tags => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Post to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Post
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PostCopyWith<Post> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PostCopyWith<$Res> {
  factory $PostCopyWith(Post value, $Res Function(Post) then) =
      _$PostCopyWithImpl<$Res, Post>;
  @useResult
  $Res call({
    int id,
    String title,
    String url,
    String? description,
    SocialSource source,
    String? thumbnailUrl,
    bool favorite,
    Folder? folder,
    List<Tag> tags,
    DateTime createdAt,
    DateTime updatedAt,
  });

  $FolderCopyWith<$Res>? get folder;
}

/// @nodoc
class _$PostCopyWithImpl<$Res, $Val extends Post>
    implements $PostCopyWith<$Res> {
  _$PostCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Post
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? url = null,
    Object? description = freezed,
    Object? source = null,
    Object? thumbnailUrl = freezed,
    Object? favorite = null,
    Object? folder = freezed,
    Object? tags = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            url: null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            source: null == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as SocialSource,
            thumbnailUrl: freezed == thumbnailUrl
                ? _value.thumbnailUrl
                : thumbnailUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            favorite: null == favorite
                ? _value.favorite
                : favorite // ignore: cast_nullable_to_non_nullable
                      as bool,
            folder: freezed == folder
                ? _value.folder
                : folder // ignore: cast_nullable_to_non_nullable
                      as Folder?,
            tags: null == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<Tag>,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }

  /// Create a copy of Post
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FolderCopyWith<$Res>? get folder {
    if (_value.folder == null) {
      return null;
    }

    return $FolderCopyWith<$Res>(_value.folder!, (value) {
      return _then(_value.copyWith(folder: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PostImplCopyWith<$Res> implements $PostCopyWith<$Res> {
  factory _$$PostImplCopyWith(
    _$PostImpl value,
    $Res Function(_$PostImpl) then,
  ) = __$$PostImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String title,
    String url,
    String? description,
    SocialSource source,
    String? thumbnailUrl,
    bool favorite,
    Folder? folder,
    List<Tag> tags,
    DateTime createdAt,
    DateTime updatedAt,
  });

  @override
  $FolderCopyWith<$Res>? get folder;
}

/// @nodoc
class __$$PostImplCopyWithImpl<$Res>
    extends _$PostCopyWithImpl<$Res, _$PostImpl>
    implements _$$PostImplCopyWith<$Res> {
  __$$PostImplCopyWithImpl(_$PostImpl _value, $Res Function(_$PostImpl) _then)
    : super(_value, _then);

  /// Create a copy of Post
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? url = null,
    Object? description = freezed,
    Object? source = null,
    Object? thumbnailUrl = freezed,
    Object? favorite = null,
    Object? folder = freezed,
    Object? tags = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$PostImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        url: null == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        source: null == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as SocialSource,
        thumbnailUrl: freezed == thumbnailUrl
            ? _value.thumbnailUrl
            : thumbnailUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        favorite: null == favorite
            ? _value.favorite
            : favorite // ignore: cast_nullable_to_non_nullable
                  as bool,
        folder: freezed == folder
            ? _value.folder
            : folder // ignore: cast_nullable_to_non_nullable
                  as Folder?,
        tags: null == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<Tag>,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PostImpl implements _Post {
  const _$PostImpl({
    required this.id,
    required this.title,
    required this.url,
    this.description,
    required this.source,
    this.thumbnailUrl,
    this.favorite = false,
    this.folder,
    final List<Tag> tags = const [],
    required this.createdAt,
    required this.updatedAt,
  }) : _tags = tags;

  factory _$PostImpl.fromJson(Map<String, dynamic> json) =>
      _$$PostImplFromJson(json);

  @override
  final int id;
  @override
  final String title;
  @override
  final String url;
  @override
  final String? description;
  @override
  final SocialSource source;
  @override
  final String? thumbnailUrl;
  @override
  @JsonKey()
  final bool favorite;
  @override
  final Folder? folder;
  final List<Tag> _tags;
  @override
  @JsonKey()
  List<Tag> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Post(id: $id, title: $title, url: $url, description: $description, source: $source, thumbnailUrl: $thumbnailUrl, favorite: $favorite, folder: $folder, tags: $tags, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PostImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            (identical(other.favorite, favorite) ||
                other.favorite == favorite) &&
            (identical(other.folder, folder) || other.folder == folder) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    url,
    description,
    source,
    thumbnailUrl,
    favorite,
    folder,
    const DeepCollectionEquality().hash(_tags),
    createdAt,
    updatedAt,
  );

  /// Create a copy of Post
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PostImplCopyWith<_$PostImpl> get copyWith =>
      __$$PostImplCopyWithImpl<_$PostImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PostImplToJson(this);
  }
}

abstract class _Post implements Post {
  const factory _Post({
    required final int id,
    required final String title,
    required final String url,
    final String? description,
    required final SocialSource source,
    final String? thumbnailUrl,
    final bool favorite,
    final Folder? folder,
    final List<Tag> tags,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$PostImpl;

  factory _Post.fromJson(Map<String, dynamic> json) = _$PostImpl.fromJson;

  @override
  int get id;
  @override
  String get title;
  @override
  String get url;
  @override
  String? get description;
  @override
  SocialSource get source;
  @override
  String? get thumbnailUrl;
  @override
  bool get favorite;
  @override
  Folder? get folder;
  @override
  List<Tag> get tags;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of Post
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PostImplCopyWith<_$PostImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PostRequest _$PostRequestFromJson(Map<String, dynamic> json) {
  return _PostRequest.fromJson(json);
}

/// @nodoc
mixin _$PostRequest {
  String get title => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  SocialSource get source => throw _privateConstructorUsedError;
  String? get thumbnailUrl => throw _privateConstructorUsedError;
  bool? get favorite => throw _privateConstructorUsedError;
  int? get folderId => throw _privateConstructorUsedError;
  Set<int>? get tagIds => throw _privateConstructorUsedError;

  /// Serializes this PostRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PostRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PostRequestCopyWith<PostRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PostRequestCopyWith<$Res> {
  factory $PostRequestCopyWith(
    PostRequest value,
    $Res Function(PostRequest) then,
  ) = _$PostRequestCopyWithImpl<$Res, PostRequest>;
  @useResult
  $Res call({
    String title,
    String url,
    String? description,
    SocialSource source,
    String? thumbnailUrl,
    bool? favorite,
    int? folderId,
    Set<int>? tagIds,
  });
}

/// @nodoc
class _$PostRequestCopyWithImpl<$Res, $Val extends PostRequest>
    implements $PostRequestCopyWith<$Res> {
  _$PostRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PostRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? url = null,
    Object? description = freezed,
    Object? source = null,
    Object? thumbnailUrl = freezed,
    Object? favorite = freezed,
    Object? folderId = freezed,
    Object? tagIds = freezed,
  }) {
    return _then(
      _value.copyWith(
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            url: null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            source: null == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as SocialSource,
            thumbnailUrl: freezed == thumbnailUrl
                ? _value.thumbnailUrl
                : thumbnailUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            favorite: freezed == favorite
                ? _value.favorite
                : favorite // ignore: cast_nullable_to_non_nullable
                      as bool?,
            folderId: freezed == folderId
                ? _value.folderId
                : folderId // ignore: cast_nullable_to_non_nullable
                      as int?,
            tagIds: freezed == tagIds
                ? _value.tagIds
                : tagIds // ignore: cast_nullable_to_non_nullable
                      as Set<int>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PostRequestImplCopyWith<$Res>
    implements $PostRequestCopyWith<$Res> {
  factory _$$PostRequestImplCopyWith(
    _$PostRequestImpl value,
    $Res Function(_$PostRequestImpl) then,
  ) = __$$PostRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String title,
    String url,
    String? description,
    SocialSource source,
    String? thumbnailUrl,
    bool? favorite,
    int? folderId,
    Set<int>? tagIds,
  });
}

/// @nodoc
class __$$PostRequestImplCopyWithImpl<$Res>
    extends _$PostRequestCopyWithImpl<$Res, _$PostRequestImpl>
    implements _$$PostRequestImplCopyWith<$Res> {
  __$$PostRequestImplCopyWithImpl(
    _$PostRequestImpl _value,
    $Res Function(_$PostRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PostRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? url = null,
    Object? description = freezed,
    Object? source = null,
    Object? thumbnailUrl = freezed,
    Object? favorite = freezed,
    Object? folderId = freezed,
    Object? tagIds = freezed,
  }) {
    return _then(
      _$PostRequestImpl(
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        url: null == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        source: null == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as SocialSource,
        thumbnailUrl: freezed == thumbnailUrl
            ? _value.thumbnailUrl
            : thumbnailUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        favorite: freezed == favorite
            ? _value.favorite
            : favorite // ignore: cast_nullable_to_non_nullable
                  as bool?,
        folderId: freezed == folderId
            ? _value.folderId
            : folderId // ignore: cast_nullable_to_non_nullable
                  as int?,
        tagIds: freezed == tagIds
            ? _value._tagIds
            : tagIds // ignore: cast_nullable_to_non_nullable
                  as Set<int>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PostRequestImpl implements _PostRequest {
  const _$PostRequestImpl({
    required this.title,
    required this.url,
    this.description,
    required this.source,
    this.thumbnailUrl,
    this.favorite,
    this.folderId,
    final Set<int>? tagIds,
  }) : _tagIds = tagIds;

  factory _$PostRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$PostRequestImplFromJson(json);

  @override
  final String title;
  @override
  final String url;
  @override
  final String? description;
  @override
  final SocialSource source;
  @override
  final String? thumbnailUrl;
  @override
  final bool? favorite;
  @override
  final int? folderId;
  final Set<int>? _tagIds;
  @override
  Set<int>? get tagIds {
    final value = _tagIds;
    if (value == null) return null;
    if (_tagIds is EqualUnmodifiableSetView) return _tagIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(value);
  }

  @override
  String toString() {
    return 'PostRequest(title: $title, url: $url, description: $description, source: $source, thumbnailUrl: $thumbnailUrl, favorite: $favorite, folderId: $folderId, tagIds: $tagIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PostRequestImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            (identical(other.favorite, favorite) ||
                other.favorite == favorite) &&
            (identical(other.folderId, folderId) ||
                other.folderId == folderId) &&
            const DeepCollectionEquality().equals(other._tagIds, _tagIds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    title,
    url,
    description,
    source,
    thumbnailUrl,
    favorite,
    folderId,
    const DeepCollectionEquality().hash(_tagIds),
  );

  /// Create a copy of PostRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PostRequestImplCopyWith<_$PostRequestImpl> get copyWith =>
      __$$PostRequestImplCopyWithImpl<_$PostRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PostRequestImplToJson(this);
  }
}

abstract class _PostRequest implements PostRequest {
  const factory _PostRequest({
    required final String title,
    required final String url,
    final String? description,
    required final SocialSource source,
    final String? thumbnailUrl,
    final bool? favorite,
    final int? folderId,
    final Set<int>? tagIds,
  }) = _$PostRequestImpl;

  factory _PostRequest.fromJson(Map<String, dynamic> json) =
      _$PostRequestImpl.fromJson;

  @override
  String get title;
  @override
  String get url;
  @override
  String? get description;
  @override
  SocialSource get source;
  @override
  String? get thumbnailUrl;
  @override
  bool? get favorite;
  @override
  int? get folderId;
  @override
  Set<int>? get tagIds;

  /// Create a copy of PostRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PostRequestImplCopyWith<_$PostRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
