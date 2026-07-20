import 'social_source.dart';

/// Metadados de um link (Open Graph/oEmbed) resolvidos pelo backend.
/// Campos podem vir nulos quando a rede social bloqueia leitura anônima.
class UrlMetadata {
  final String url;
  final String? title;
  final String? description;
  final String? thumbnailUrl;
  final SocialSource source;

  const UrlMetadata({
    required this.url,
    this.title,
    this.description,
    this.thumbnailUrl,
    this.source = SocialSource.other,
  });

  factory UrlMetadata.fromJson(Map<String, dynamic> json) {
    return UrlMetadata(
      url: json['url'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      source: SocialSource.values.firstWhere(
        (s) => s.name.toUpperCase() == (json['source'] as String? ?? 'OTHER'),
        orElse: () => SocialSource.other,
      ),
    );
  }
}
