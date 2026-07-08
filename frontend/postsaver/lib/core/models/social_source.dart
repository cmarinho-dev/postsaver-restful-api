import 'package:json_annotation/json_annotation.dart';

enum SocialSource {
  @JsonValue('INSTAGRAM')
  instagram,

  @JsonValue('TIKTOK')
  tiktok,

  @JsonValue('FACEBOOK')
  facebook,

  @JsonValue('KWAI')
  kwai,

  @JsonValue('YOUTUBE')
  youtube,

  @JsonValue('TWITTER')
  twitter,

  @JsonValue('OTHER')
  other,
}
