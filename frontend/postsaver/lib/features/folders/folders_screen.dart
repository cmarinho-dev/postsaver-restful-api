import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/folder.dart';
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

  void _onDeleteFolder(Folder folder) {
    final scaffoldContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir pasta'),
        content: Text('Tem certeza que deseja excluir a pasta "${folder.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(foldersProvider.notifier).deleteFolder(folder.id);
              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                const SnackBar(content: Text('Pasta excluída')),
              );
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _onEditFolder(Folder folder) {
    context.push('/folders/edit/${folder.id}');
  }

  void _onCreateFolder() {
    context.push('/folders/new');
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) {
      return Colors.blue;
    }
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final foldersState = ref.watch(foldersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Pastas'),
      ),
      body: _buildContent(foldersState),
      floatingActionButton: FloatingActionButton(
        onPressed: _onCreateFolder,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(FoldersState foldersState) {
    if (foldersState.isLoading && foldersState.folders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (foldersState.error != null && foldersState.folders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erro: ${foldersState.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onRefresh,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (foldersState.folders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhuma pasta. Toque + para criar uma.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        itemCount: foldersState.folders.length,
        itemBuilder: (context, index) {
          return _buildFolderCard(foldersState.folders[index]);
        },
      ),
    );
  }

  Widget _buildFolderCard(Folder folder) {
    final color = _parseColor(folder.color);

    return Dismissible(
      key: ValueKey(folder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        _onDeleteFolder(folder);
        return false;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.folder, color: color),
          ),
          title: Text(
            folder.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: folder.description != null && folder.description!.isNotEmpty
              ? Text(
                  folder.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _onEditFolder(folder),
        ),
      ),
    );
  }
}
