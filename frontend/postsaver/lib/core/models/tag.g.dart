// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TagImpl _$$TagImplFromJson(Map<String, dynamic> json) => _$TagImpl(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  color: json['color'] as String?,
);

Map<String, dynamic> _$$TagImplToJson(_$TagImpl instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'color': instance.color,
};

_$TagRequestImpl _$$TagRequestImplFromJson(Map<String, dynamic> json) =>
    _$TagRequestImpl(
      name: json['name'] as String,
      color: json['color'] as String?,
    );

Map<String, dynamic> _$$TagRequestImplToJson(_$TagRequestImpl instance) =>
    <String, dynamic>{'name': instance.name, 'color': instance.color};
