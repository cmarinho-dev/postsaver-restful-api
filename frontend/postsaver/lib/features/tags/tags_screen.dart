import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  void _onDeleteTag(int tagId, String tagName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir tag'),
        content: Text('Tem certeza que deseja excluir a tag "$tagName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(tagsProvider.notifier).deleteTag(tagId);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tagsState = ref.watch(tagsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tags'),
      ),
      body: _buildContent(tagsState),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).pushNamed('/tags/new');
          ref.read(tagsProvider.notifier).loadTags();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(TagsState tagsState) {
    if (tagsState.isLoading && tagsState.tags.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tagsState.error != null && tagsState.tags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erro: ${tagsState.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onRefresh,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (tagsState.tags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.label_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhuma tag encontrada',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toque no + para adicionar uma nova tag',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        itemCount: tagsState.tags.length,
        itemBuilder: (context, index) {
          final tag = tagsState.tags[index];
          return Dismissible(
            key: ValueKey(tag.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (_) async {
              _onDeleteTag(tag.id, tag.name);
              return false;
            },
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: tag.color != null
                    ? Color(int.parse(tag.color!.replaceFirst('#', '0xFF')))
                    : Colors.grey[300],
                child: Text(
                  tag.name.isNotEmpty ? tag.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: tag.color != null ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              title: Text(tag.name),
              subtitle: tag.color != null ? Text('Cor: ${tag.color}') : null,
              onTap: () async {
                await Navigator.of(context).pushNamed('/tags/edit/${tag.id}');
                ref.read(tagsProvider.notifier).loadTags();
              },
            ),
          );
        },
      ),
    );
  }
}
