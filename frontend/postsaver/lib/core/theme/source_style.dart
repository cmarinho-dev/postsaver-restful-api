import 'package:flutter/material.dart';

import '../models/social_source.dart';

/// Identidade visual de cada rede social (cor, gradiente, ícone e rótulo).
class SourceStyle {
  final String label;
  final Color color;
  final IconData icon;
  final LinearGradient gradient;

  const SourceStyle({
    required this.label,
    required this.color,
    required this.icon,
    required this.gradient,
  });

  static const Map<SocialSource, SourceStyle> _styles = {
    SocialSource.instagram: SourceStyle(
      label: 'Instagram',
      color: Color(0xFFE1306C),
      icon: Icons.camera_alt_rounded,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF833AB4), Color(0xFFE1306C), Color(0xFFF77737)],
      ),
    ),
    SocialSource.tiktok: SourceStyle(
      label: 'TikTok',
      color: Color(0xFF010101),
      icon: Icons.music_note_rounded,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF25F4EE), Color(0xFF010101), Color(0xFFFE2C55)],
      ),
    ),
    SocialSource.facebook: SourceStyle(
      label: 'Facebook',
      color: Color(0xFF1877F2),
      icon: Icons.facebook_rounded,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1877F2), Color(0xFF0C5DC7)],
      ),
    ),
    SocialSource.kwai: SourceStyle(
      label: 'Kwai',
      color: Color(0xFFFF7E00),
      icon: Icons.videocam_rounded,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF9500), Color(0xFFFF5E00)],
      ),
    ),
    SocialSource.youtube: SourceStyle(
      label: 'YouTube',
      color: Color(0xFFFF0000),
      icon: Icons.play_arrow_rounded,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF4E45), Color(0xFFC4302B)],
      ),
    ),
    SocialSource.twitter: SourceStyle(
      label: 'Twitter / X',
      color: Color(0xFF1DA1F2),
      icon: Icons.tag_rounded,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1DA1F2), Color(0xFF0D8BD9)],
      ),
    ),
    SocialSource.other: SourceStyle(
      label: 'Outro',
      color: Color(0xFF8E8E93),
      icon: Icons.public_rounded,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF9E9EA7), Color(0xFF6E6E78)],
      ),
    ),
  };

  static SourceStyle of(SocialSource source) => _styles[source]!;
}

/// Converte "#RRGGBB" em [Color], com fallback seguro.
Color parseHexColor(String? hex, {Color fallback = const Color(0xFF6C4DF6)}) {
  if (hex == null || hex.isEmpty) return fallback;
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return fallback;
  }
}

/// Paleta de cores para pastas e tags (seletor de cor dos forms).
const List<Color> presetPalette = [
  Color(0xFF6C4DF6),
  Color(0xFFB16CEA),
  Color(0xFFFF5E8A),
  Color(0xFFFF7043),
  Color(0xFFFFB300),
  Color(0xFF4CAF50),
  Color(0xFF00BFA5),
  Color(0xFF00B0FF),
  Color(0xFF1877F2),
  Color(0xFF607D8B),
  Color(0xFFE91E63),
  Color(0xFF795548),
];

String colorToHex(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
