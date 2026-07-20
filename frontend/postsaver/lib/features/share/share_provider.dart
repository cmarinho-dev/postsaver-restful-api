import '../../core/models/social_source.dart';

/// Extrai a primeira URL de um texto compartilhado (apps costumam mandar
/// legenda + link juntos no ACTION_SEND).
String? extractSharedUrl(String text) {
  final urlPattern = RegExp(r'https?://[^\s]+', caseSensitive: false);
  final match = urlPattern.firstMatch(text);
  if (match != null) {
    return match.group(0);
  }

  if (text.contains('.') && !text.contains(' ')) {
    return 'https://$text';
  }

  return null;
}

SocialSource inferSocialSource(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return SocialSource.other;

  final host = uri.host.toLowerCase();

  if (host.contains('instagram.com')) return SocialSource.instagram;
  if (host.contains('tiktok.com')) return SocialSource.tiktok;
  if (host.contains('facebook.com')) return SocialSource.facebook;
  if (host.contains('kwai.com')) return SocialSource.kwai;
  if (host.contains('youtube.com') || host.contains('youtu.be')) {
    return SocialSource.youtube;
  }
  if (host.contains('twitter.com') || host == 'x.com') {
    return SocialSource.twitter;
  }

  return SocialSource.other;
}
