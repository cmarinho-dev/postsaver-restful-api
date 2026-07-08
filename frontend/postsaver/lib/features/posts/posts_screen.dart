import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/post.dart';
import '../../core/models/social_source.dart';
import 'posts_provider.dart';

class PostsScreen extends ConsumerStatefulWidget {
  const PostsScreen({super.key});

  @override
  ConsumerState<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends ConsumerState<PostsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
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

  void _onSearch() {
    final query = _searchController.text.trim();
    final currentFilter = ref.read(postsProvider).filter;
    ref.read(postsProvider.notifier).updateFilter(
          currentFilter.copyWith(
            q: query,
            clearQ: query.isEmpty,
          ),
        );
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

  Future<void> _onRefresh() async {
    await ref.read(postsProvider.notifier).loadPosts(refresh: true);
  }

  void _onDeletePost(int postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir post'),
        content: const Text('Tem certeza que deseja excluir este post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(postsProvider.notifier).deletePost(postId);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postsState = ref.watch(postsProvider);
    final filter = postsState.filter;

    return Scaffold(
      appBar: AppBar(
        title: _isSearchActive
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar posts...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _onSearch(),
              )
            : const Text('Meus Posts'),
        actions: [
          IconButton(
            icon: Icon(_isSearchActive ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchActive = !_isSearchActive;
                if (!_isSearchActive) {
                  _searchController.clear();
                  _onSearch();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              Icons.favorite,
              color: filter.favorite == true ? Colors.red : null,
            ),
            onPressed: _onFavoriteFilter,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(filter),
          Expanded(
            child: _buildContent(postsState),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/posts/new');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChips(PostsFilter filter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildSourceChip('Todos', null, filter.source),
          const SizedBox(width: 8),
          ...SocialSource.values.map((source) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildSourceChip(
                  _sourceLabel(source),
                  source,
                  filter.source,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSourceChip(String label, SocialSource? source, SocialSource? selected) {
    final isSelected = source == selected;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onSourceFilter(isSelected ? null : source),
    );
  }

  String _sourceLabel(SocialSource source) {
    switch (source) {
      case SocialSource.instagram:
        return 'Instagram';
      case SocialSource.tiktok:
        return 'TikTok';
      case SocialSource.facebook:
        return 'Facebook';
      case SocialSource.kwai:
        return 'Kwai';
      case SocialSource.youtube:
        return 'YouTube';
      case SocialSource.twitter:
        return 'Twitter';
      case SocialSource.other:
        return 'Outro';
    }
  }

  Widget _buildContent(PostsState postsState) {
    if (postsState.isLoading && postsState.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (postsState.error != null && postsState.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erro: ${postsState.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onRefresh,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (postsState.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhum post encontrado',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toque no + para adicionar um novo post',
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
        controller: _scrollController,
        itemCount: postsState.posts.length + (postsState.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= postsState.posts.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return _buildPostCard(postsState.posts[index]);
        },
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    return Dismissible(
      key: ValueKey(post.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        _onDeletePost(post.id);
        return false;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (post.thumbnailUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post.thumbnailUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, e, s) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
              if (post.thumbnailUrl != null) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            post.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            post.favorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: post.favorite ? Colors.red : null,
                          ),
                          onPressed: () {
                            ref.read(postsProvider.notifier).toggleFavorite(post.id);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildSourceBadge(post.source),
                    if (post.folder != null || post.tags.isNotEmpty)
                      const SizedBox(height: 8),
                    if (post.folder != null || post.tags.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          if (post.folder != null)
                            Chip(
                              label: Text(
                                post.folder!.name,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.blue[100],
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ...post.tags.map((tag) => Chip(
                                label: Text(
                                  tag.name,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: tag.color != null
                                    ? Color(int.parse(tag.color!.replaceFirst('#', '0xFF')))
                                    : Colors.grey[200],
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              )),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceBadge(SocialSource source) {
    final colors = {
      SocialSource.instagram: const Color(0xFFE1306C),
      SocialSource.tiktok: const Color(0xFF000000),
      SocialSource.facebook: const Color(0xFF1877F2),
      SocialSource.kwai: const Color(0xFFFF6600),
      SocialSource.youtube: const Color(0xFFFF0000),
      SocialSource.twitter: const Color(0xFF1DA1F2),
      SocialSource.other: Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors[source]?.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _sourceLabel(source),
        style: TextStyle(
          fontSize: 12,
          color: colors[source],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
