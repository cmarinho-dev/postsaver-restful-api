import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Bloco base de skeleton com efeito shimmer contínuo.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadiusGeometry borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: borderRadius,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1400.ms,
          color: scheme.surfaceContainerLowest.withValues(alpha: 0.6),
        );
  }
}

/// Skeleton de um card de post na lista.
class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const SkeletonBox(
              width: 72,
              height: 72,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(height: 16, width: double.infinity),
                  SizedBox(height: 8),
                  SkeletonBox(height: 16, width: 180),
                  SizedBox(height: 12),
                  SkeletonBox(height: 22, width: 90),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista de skeletons para o carregamento inicial.
class SkeletonList extends StatelessWidget {
  final int count;
  final Widget item;
  final EdgeInsetsGeometry padding;

  const SkeletonList({
    super.key,
    this.count = 6,
    this.item = const PostCardSkeleton(),
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 16),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => item,
    );
  }
}
