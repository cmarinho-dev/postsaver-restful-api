import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/folder.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/source_style.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/gradient_fab.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/state_views.dart';
import '../posts/posts_provider.dart';
import 'folders_provider.dart';

class FoldersScreen extends ConsumerStatefulWidget {
  const FoldersScreen({super.key});

  @override
  ConsumerState<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends ConsumerState<FoldersScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(foldersProvider.notifier).loadFolders();
  }

  Future<void> _onRefresh() async {
    await ref.read(foldersProvider.notifier).loadFolders(refresh: true);
  }

  Future<void> _onDeleteFolder(Folder folder) async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Excluir pasta?',
      message:
          'A pasta "${folder.name}" será removida. Os posts dela não serão excluídos.',
      confirmLabel: 'Excluir pasta',
      icon: Icons.folder_delete_outlined,
      isDestructive: true,
    );
    if (confirmed && mounted) {
      await ref.read(foldersProvider.notifier).deleteFolder(folder.id);
      if (mounted) {
        showAppSnackBar(context, 'Pasta excluída');
      }
    }
  }

  void _onOpenFolder(Folder folder) {
    final filter = ref.read(postsProvider).filter;
    ref.read(postsProvider.notifier).updateFilter(
          filter.copyWith(
            folderId: folder.id,
            folderName: folder.name,
            clearTag: true,
          ),
        );
    context.go('/');
  }

  Future<void> _onEditFolder(Folder folder) async {
    await context.push('/folders/edit/${folder.id}');
    if (mounted) {
      ref.read(foldersProvider.notifier).loadFolders(refresh: true);
    }
  }

  Future<void> _onCreateFolder() async {
    await context.push('/folders/new');
    if (mounted) {
      ref.read(foldersProvider.notifier).loadFolders(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final foldersState = ref.watch(foldersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text('Pastas', style: theme.textTheme.headlineSmall),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Toque em uma pasta para ver os posts dela.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: _buildContent(foldersState)),
          ],
        ),
      ),
      floatingActionButton: GradientFab(
        label: 'Nova pasta',
        icon: Icons.create_new_folder_outlined,
        onPressed: _onCreateFolder,
      ),
    );
  }

  Widget _buildContent(FoldersState foldersState) {
    if (foldersState.isLoading && foldersState.folders.isEmpty) {
      return GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          6,
          (_) => const SkeletonBox(
            height: double.infinity,
            borderRadius: BorderRadius.all(Radius.circular(AppTheme.radiusL)),
          ),
        ),
      );
    }

    if (foldersState.error != null && foldersState.folders.isEmpty) {
      return ErrorState(message: foldersState.error!, onRetry: _onRefresh);
    }

    if (foldersState.folders.isEmpty) {
      return EmptyState(
        icon: Icons.folder_open_rounded,
        title: 'Nenhuma pasta ainda',
        message:
            'Crie pastas para agrupar seus posts por assunto — receitas, viagens, inspirações...',
        actionLabel: 'Criar primeira pasta',
        onAction: _onCreateFolder,
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.25,
        ),
        itemCount: foldersState.folders.length,
        itemBuilder: (context, index) {
          final folder = foldersState.folders[index];
          final card = _FolderCard(
            folder: folder,
            onOpen: () => _onOpenFolder(folder),
            onEdit: () => _onEditFolder(folder),
            onDelete: () => _onDeleteFolder(folder),
          );
          if (index < 8) {
            return card
                .animate()
                .fadeIn(delay: (40 * index).ms, duration: 300.ms)
                .scale(
                  begin: const Offset(0.92, 0.92),
                  delay: (40 * index).ms,
                  duration: 300.ms,
                  curve: Curves.easeOutCubic,
                );
          }
          return card;
        },
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final Folder folder;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FolderCard({
    required this.folder,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final color = parseHexColor(folder.color);

    return Material(
      color: Color.alphaBlend(
        color.withValues(alpha: isDark ? 0.16 : 0.08),
        scheme.surfaceContainerLow,
      ),
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.4 : 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color,
                          Color.lerp(color, Colors.black, 0.25)!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.folder_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  _FolderMenu(onEdit: onEdit, onDelete: onDelete),
                ],
              ),
              const Spacer(),
              Text(
                folder.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (folder.description != null &&
                  folder.description!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  folder.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FolderMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FolderMenu({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MenuAnchor(
      style: MenuStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
        ),
      ),
      builder: (context, controller, _) => InkWell(
        customBorder: const CircleBorder(),
        onTap: () =>
            controller.isOpen ? controller.close() : controller.open(),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            Icons.more_horiz_rounded,
            size: 20,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.edit_rounded, size: 18),
          onPressed: onEdit,
          child: const Text('Editar'),
        ),
        MenuItemButton(
          leadingIcon: Icon(
            Icons.delete_outline_rounded,
            size: 18,
            color: scheme.error,
          ),
          onPressed: onDelete,
          child: Text('Excluir', style: TextStyle(color: scheme.error)),
        ),
      ],
    );
  }
}
