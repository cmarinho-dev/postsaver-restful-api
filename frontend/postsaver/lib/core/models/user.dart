import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required int id,
    required String name,
    required String username,
    required String email,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
class UserRequest with _$UserRequest {
  const factory UserRequest({
    required String name,
    required String username,
    required String email,
    // Opcional no PUT /users/me: quando omitida, o backend mantém a senha.
    // ignore: invalid_annotation_target
    @JsonKey(includeIfNull: false) String? password,
  }) = _UserRequest;

  factory UserRequest.fromJson(Map<String, dynamic> json) =>
      _$UserRequestFromJson(json);
}
