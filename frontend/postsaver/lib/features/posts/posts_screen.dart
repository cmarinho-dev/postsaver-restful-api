import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/post.dart';
import '../../core/models/social_source.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/source_style.dart';
import '../../core/utils/relative_time.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/favorite_button.dart';
import '../../core/widgets/gradient_fab.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/source_badge.dart';
import '../../core/widgets/state_views.dart';
import 'posts_provider.dart';

class PostsScreen extends ConsumerStatefulWidget {
  const PostsScreen({super.key});

  @override
  ConsumerState<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends ConsumerState<PostsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(postsProvider.notifier).loadPosts();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      final query = value.trim();
      final currentFilter = ref.read(postsProvider).filter;
      ref.read(postsProvider.notifier).updateFilter(
            currentFilter.copyWith(q: query, clearQ: query.isEmpty),
          );
    });
  }

  void _onSourceFilter(SocialSource? source) {
    final currentFilter = ref.read(postsProvider).filter;
    ref.read(postsProvider.notifier).updateFilter(
          currentFilter.copyWith(
            source: source,
            clearSource: source == null,
          ),
        );
  }

  void _onFavoriteFilter() {
    final currentFilter = ref.read(postsProvider).filter;
    final isFavorite = currentFilter.favorite == true;
    ref.read(postsProvider.notifier).updateFilter(
          currentFilter.copyWith(
            favorite: !isFavorite,
            clearFavorite: isFavorite,
          ),
        );
  }

  void _clearCollectionFilter() {
    final currentFilter = ref.read(postsProvider).filter;
    ref.read(postsProvider.notifier).updateFilter(
          currentFilter.copyWith(clearFolder: true, clearTag: true),
        );
  }

  Future<void> _onRefresh() async {
    await ref.read(postsProvider.notifier).loadPosts(refresh: true);
  }

  Future<void> _onDeletePost(Post post) async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Excluir post?',
      message:
          '"${post.title}" será removido para sempre. Essa ação não pode ser desfeita.',
      confirmLabel: 'Excluir post',
      icon: Icons.delete_outline_rounded,
      isDestructive: true,
    );
    if (confirmed && mounted) {
      await ref.read(postsProvider.notifier).deletePost(post.id);
      if (mounted) {
        showAppSnackBar(context, 'Post excluído');
      }
    }
  }

  Future<void> _openPostUrl(Post post) async {
    final uri = Uri.tryParse(post.url);
    if (uri == null) {
      showAppSnackBar(context, 'Link inválido', isError: true);
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      showAppSnackBar(context, 'Não foi possível abrir o link', isError: true);
    }
  }

  /// Abre o formulário de post e recarrega a lista ao voltar.
  Future<void> _openPostForm({int? postId}) async {
    await context.push(postId == null ? '/posts/new' : '/posts/edit/$postId');
    if (mounted) {
      ref.read(postsProvider.notifier).loadPosts(refresh: true);
    }
  }

  void _showPostDetail(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _PostDetailSheet(
        postId: post.id,
        onOpenUrl: _openPostUrl,
        onEdit: (p) {
          Navigator.of(sheetContext).pop();
          _openPostForm(postId: p.id);
        },
        onDelete: (p) {
          Navigator.of(sheetContext).pop();
          _onDeletePost(p);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postsState = ref.watch(postsProvider);
    final filter = postsState.filter;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Meus Posts',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  _FavoriteFilterButton(
                    isActive: filter.favorite == true,
                    onTap: _onFavoriteFilter,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _SearchField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onClear: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              ),
            ),
            if (filter.hasCollectionFilter)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _ActiveCollectionChip(
                  filter: filter,
                  onClear: _clearCollectionFilter,
                ),
              ),
            const SizedBox(height: 12),
            _SourceChipsRow(
              selected: filter.source,
              onSelect: _onSourceFilter,
            ),
            const SizedBox(height: 4),
            Expanded(child: _buildContent(postsState)),
          ],
        ),
      ),
      floatingActionButton: GradientFab(
        label: 'Salvar post',
        onPressed: _openPostForm,
      ),
    );
  }

  Widget _buildContent(PostsState postsState) {
    if (postsState.isLoading && postsState.posts.isEmpty) {
      return const SkeletonList();
    }

    if (postsState.error != null && postsState.posts.isEmpty) {
      return ErrorState(message: postsState.error!, onRetry: _onRefresh);
    }

    if (postsState.posts.isEmpty) {
      final hasFilter = postsState.filter.q != null ||
          postsState.filter.source != null ||
          postsState.filter.favorite == true ||
          postsState.filter.hasCollectionFilter;
      return EmptyState(
        icon: hasFilter
            ? Icons.search_off_rounded
            : Icons.bookmark_add_outlined,
        title: hasFilter ? 'Nada por aqui' : 'Comece a salvar',
        message: hasFilter
            ? 'Nenhum post corresponde aos filtros. Tente ajustar a busca.'
            : 'Compartilhe um post do Instagram, TikTok ou YouTube com o PostSaver — ou toque no botão abaixo.',
        actionLabel: hasFilter ? null : 'Salvar primeiro post',
        onAction: hasFilter ? null : _openPostForm,
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: postsState.posts.length + (postsState.hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= postsState.posts.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
            );
          }
          final post = postsState.posts[index];
          final card = _PostCard(
            post: post,
            onTap: () => _showPostDetail(post),
            onToggleFavorite: () =>
                ref.read(postsProvider.notifier).toggleFavorite(post.id),
            onDelete: () => _onDeletePost(post),
          );
          // Anima a entrada apenas dos primeiros itens visíveis.
          if (index < 8) {
            return card
                .animate()
                .fadeIn(
                  delay: (50 * index).ms,
                  duration: 350.ms,
                )
                .moveY(
                  begin: 24,
                  end: 0,
                  delay: (50 * index).ms,
                  duration: 350.ms,
                  curve: Curves.easeOutCubic,
                );
          }
          return card;
        },
      ),
    );
  }
}

class _FavoriteFilterButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _FavoriteFilterButton({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.favorite.withValues(alpha: 0.14)
            : scheme.surfaceContainerLow,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive
              ? AppColors.favorite.withValues(alpha: 0.4)
              : scheme.outlineVariant,
        ),
      ),
      child: IconButton(
        onPressed: onTap,
        tooltip: 'Somente favoritos',
        icon: Icon(
          isActive ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: isActive ? AppColors.favorite : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar posts...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: onClear,
                ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class _ActiveCollectionChip extends StatelessWidget {
  final PostsFilter filter;
  final VoidCallback onClear;

  const _ActiveCollectionChip({required this.filter, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isFolder = filter.folderId != null;
    final label = isFolder
        ? (filter.folderName ?? 'Pasta')
        : (filter.tagName ?? 'Tag');

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFolder ? Icons.folder_rounded : Icons.sell_rounded,
              size: 16,
              color: scheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: onClear,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: scheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).scale(
          begin: const Offset(0.9, 0.9),
          duration: 250.ms,
          curve: Curves.easeOutBack,
        );
  }
}

class _SourceChipsRow extends StatelessWidget {
  final SocialSource? selected;
  final ValueChanged<SocialSource?> onSelect;

  const _SourceChipsRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Todos'),
              selected: selected == null,
              onSelected: (_) => onSelect(null),
            ),
          ),
          ...SocialSource.values.map((source) {
            final style = SourceStyle.of(source);
            final isSelected = selected == source;
            final chipColor =
                isDark && source == SocialSource.tiktok
                    ? Colors.white
                    : style.color;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(
                  style.icon,
                  size: 16,
                  color: isSelected ? chipColor : scheme.onSurfaceVariant,
                ),
                label: Text(style.label),
                selected: isSelected,
                selectedColor: chipColor.withValues(alpha: isDark ? 0.25 : 0.14),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? chipColor : scheme.onSurface,
                ),
                side: BorderSide(
                  color: isSelected
                      ? chipColor.withValues(alpha: 0.5)
                      : scheme.outlineVariant,
                ),
                onSelected: (_) => onSelect(isSelected ? null : source),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;

  const _PostCard({
    required this.post,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Dismissible(
      key: ValueKey(post.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: scheme.error,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumbnail(post: post),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                post.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          FavoriteButton(
                            isFavorite: post.favorite,
                            onToggle: onToggleFavorite,
                            size: 22,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          SourceBadge(source: post.source, compact: true),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              relativeTime(post.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (post.folder != null || post.tags.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (post.folder != null)
                              _MiniChip(
                                icon: Icons.folder_rounded,
                                label: post.folder!.name,
                                color: parseHexColor(post.folder!.color),
                              ),
                            ...post.tags.take(3).map(
                                  (tag) => _MiniChip(
                                    icon: Icons.sell_rounded,
                                    label: tag.name,
                                    color: parseHexColor(tag.color),
                                  ),
                                ),
                            if (post.tags.length > 3)
                              _MiniChip(
                                label: '+${post.tags.length - 3}',
                                color: scheme.onSurfaceVariant,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final Post post;

  const _Thumbnail({required this.post});

  @override
  Widget build(BuildContext context) {
    if (post.thumbnailUrl == null || post.thumbnailUrl!.isEmpty) {
      return SourceAvatar(source: post.source, size: 76);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: post.thumbnailUrl!,
        width: 76,
        height: 76,
        fit: BoxFit.cover,
        placeholder: (_, _) => const SkeletonBox(
          width: 76,
          height: 76,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        errorWidget: (_, _, _) => SourceAvatar(source: post.source, size: 76),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;

  const _MiniChip({this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.24 : 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet com o detalhe do post e ações rápidas.
class _PostDetailSheet extends ConsumerWidget {
  final int postId;
  final Future<void> Function(Post) onOpenUrl;
  final void Function(Post) onEdit;
  final void Function(Post) onDelete;

  const _PostDetailSheet({
    required this.postId,
    required this.onOpenUrl,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Observa a lista para refletir o toggle de favorito em tempo real.
    final post = ref.watch(
      postsProvider.select(
        (state) => state.posts.where((p) => p.id == postId).firstOrNull,
      ),
    );

    if (post == null) return const SizedBox.shrink();

    final style = SourceStyle.of(post.source);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (post.thumbnailUrl != null && post.thumbnailUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: post.thumbnailUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const SkeletonBox(
                      height: double.infinity,
                      borderRadius:
                          BorderRadius.all(Radius.circular(AppTheme.radiusL)),
                    ),
                    errorWidget: (_, _, _) => Container(
                      decoration: BoxDecoration(gradient: style.gradient),
                      child: Icon(
                        style.icon,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: style.gradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                ),
                child: Icon(style.icon, color: Colors.white, size: 52),
              ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    post.title,
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
                  ),
                ),
                FavoriteButton(
                  isFavorite: post.favorite,
                  onToggle: () =>
                      ref.read(postsProvider.notifier).toggleFavorite(post.id),
                  size: 26,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                SourceBadge(source: post.source),
                const SizedBox(width: 10),
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  relativeTime(post.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (post.description != null && post.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                post.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
            if (post.folder != null || post.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (post.folder != null)
                    _MiniChip(
                      icon: Icons.folder_rounded,
                      label: post.folder!.name,
                      color: parseHexColor(post.folder!.color),
                    ),
                  ...post.tags.map(
                    (tag) => _MiniChip(
                      icon: Icons.sell_rounded,
                      label: tag.name,
                      color: parseHexColor(tag.color),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.subtleBrandGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: FilledButton.icon(
                onPressed: () => onOpenUrl(post),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 20),
                label: Text('Abrir no ${style.label}'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => onEdit(post),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => onDelete(post),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          scheme.errorContainer.withValues(alpha: 0.55),
                      foregroundColor: scheme.error,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Excluir'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
