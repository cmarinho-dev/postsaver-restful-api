import 'package:json_annotation/json_annotation.dart';

part 'page.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class PageResponse<T> {
  const PageResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.size,
  });

  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final int size;

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) =>
      _$PageResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T) toJsonT) =>
      _$PageResponseToJson(this, toJsonT);

  PageResponse<T> copyWith({
    List<T>? content,
    int? totalElements,
    int? totalPages,
    int? number,
    int? size,
  }) {
    return PageResponse<T>(
      content: content ?? this.content,
      totalElements: totalElements ?? this.totalElements,
      totalPages: totalPages ?? this.totalPages,
      number: number ?? this.number,
      size: size ?? this.size,
    );
  }
}
