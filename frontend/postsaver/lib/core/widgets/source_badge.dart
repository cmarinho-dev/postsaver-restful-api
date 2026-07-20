import 'package:flutter/material.dart';

import '../models/social_source.dart';
import '../theme/source_style.dart';

/// Selo compacto com o ícone e a cor da rede social.
class SourceBadge extends StatelessWidget {
  final SocialSource source;
  final bool compact;

  const SourceBadge({super.key, required this.source, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final style = SourceStyle.of(source);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark && source == SocialSource.tiktok
        ? Colors.white
        : style.color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: compact ? 12 : 14, color: color),
          const SizedBox(width: 4),
          Text(
            style.label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar circular em gradiente da rede social (usado em cards sem thumbnail).
class SourceAvatar extends StatelessWidget {
  final SocialSource source;
  final double size;

  const SourceAvatar({super.key, required this.source, this.size = 72});

  @override
  Widget build(BuildContext context) {
    final style = SourceStyle.of(source);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: style.gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(style.icon, color: Colors.white, size: size * 0.42),
    );
  }
}
