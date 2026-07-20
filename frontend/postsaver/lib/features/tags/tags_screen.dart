import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/tag.dart';
import '../../core/theme/source_style.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/gradient_fab.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/state_views.dart';
import '../posts/posts_provider.dart';
import 'tags_provider.dart';

class TagsScreen extends ConsumerStatefulWidget {
  const TagsScreen({super.key});

  @override
  ConsumerState<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends ConsumerState<TagsScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(tagsProvider.notifier).loadTags();
  }

  Future<void> _onRefresh() async {
    await ref.read(tagsProvider.notifier).loadTags();
  }

  Future<void> _onDeleteTag(Tag tag) async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Excluir tag?',
      message:
          'A tag "${tag.name}" será removida. Os posts marcados com ela não serão excluídos.',
      confirmLabel: 'Excluir tag',
      icon: Icons.sell_outlined,
      isDestructive: true,
    );
    if (confirmed && mounted) {
      await ref.read(tagsProvider.notifier).deleteTag(tag.id);
      if (mounted) {
        showAppSnackBar(context, 'Tag excluída');
      }
    }
  }

  void _onViewPosts(Tag tag) {
    final filter = ref.read(postsProvider).filter;
    ref.read(postsProvider.notifier).updateFilter(
          filter.copyWith(
            tagId: tag.id,
            tagName: tag.name,
            clearFolder: true,
          ),
        );
    context.go('/');
  }

  Future<void> _onEditTag(Tag tag) async {
    await context.push('/tags/edit/${tag.id}');
    if (mounted) {
      ref.read(tagsProvider.notifier).loadTags();
    }
  }

  void _showTagActions(Tag tag) {
    final theme = Theme.of(context);
    final color = parseHexColor(tag.color);
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.sell_rounded, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(tag.name, style: theme.textTheme.titleLarge),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.grid_view_rounded),
                title: const Text('Ver posts com esta tag'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _onViewPosts(tag);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('Editar tag'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _onEditTag(tag);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  'Excluir tag',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _onDeleteTag(tag);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onCreateTag() async {
    await context.push('/tags/new');
    if (mounted) {
      ref.read(tagsProvider.notifier).loadTags();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagsState = ref.watch(tagsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text('Tags', style: theme.textTheme.headlineSmall),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Toque em uma tag para ver opções.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: _buildContent(tagsState)),
          ],
        ),
      ),
      floatingActionButton: GradientFab(
        label: 'Nova tag',
        icon: Icons.new_label_outlined,
        onPressed: _onCreateTag,
      ),
    );
  }

  Widget _buildContent(TagsState tagsState) {
    if (tagsState.isLoading && tagsState.tags.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(
            8,
            (i) => SkeletonBox(
              width: 90.0 + (i % 3) * 30,
              height: 42,
              borderRadius: const BorderRadius.all(Radius.circular(100)),
            ),
          ),
        ),
      );
    }

    if (tagsState.error != null && tagsState.tags.isEmpty) {
      return ErrorState(message: tagsState.error!, onRetry: _onRefresh);
    }

    if (tagsState.tags.isEmpty) {
      return EmptyState(
        icon: Icons.sell_outlined,
        title: 'Nenhuma tag ainda',
        message:
            'Tags coloridas ajudam a encontrar posts rapidamente — crie a primeira!',
        actionLabel: 'Criar primeira tag',
        onAction: _onCreateTag,
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (index, tag) in tagsState.tags.indexed)
              _TagChip(
                tag: tag,
                onTap: () => _showTagActions(tag),
              )
                  .animate()
                  .fadeIn(delay: (30 * (index % 12)).ms, duration: 300.ms)
                  .scale(
                    begin: const Offset(0.85, 0.85),
                    delay: (30 * (index % 12)).ms,
                    duration: 300.ms,
                    curve: Curves.easeOutBack,
                  ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final Tag tag;
  final VoidCallback onTap;

  const _TagChip({required this.tag, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = parseHexColor(tag.color);

    return Material(
      color: color.withValues(alpha: isDark ? 0.2 : 0.1),
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.5 : 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                tag.name,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? Color.lerp(color, Colors.white, 0.35)
                      : Color.lerp(color, Colors.black, 0.25),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
