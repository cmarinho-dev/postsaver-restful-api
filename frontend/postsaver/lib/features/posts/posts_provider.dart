import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/posts_api.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/post.dart';
import '../../core/models/social_source.dart';

class PostsFilter {
  final String? q;
  final SocialSource? source;
  final int? folderId;
  final int? tagId;
  final bool? favorite;

  /// Nomes exibidos no chip de filtro ativo (quando vindo de Pastas/Tags).
  final String? folderName;
  final String? tagName;

  const PostsFilter({
    this.q,
    this.source,
    this.folderId,
    this.tagId,
    this.favorite,
    this.folderName,
    this.tagName,
  });

  bool get hasCollectionFilter => folderId != null || tagId != null;

  PostsFilter copyWith({
    String? q,
    SocialSource? source,
    int? folderId,
    int? tagId,
    bool? favorite,
    String? folderName,
    String? tagName,
    bool clearQ = false,
    bool clearSource = false,
    bool clearFolder = false,
    bool clearTag = false,
    bool clearFavorite = false,
  }) {
    return PostsFilter(
      q: clearQ ? null : (q ?? this.q),
      source: clearSource ? null : (source ?? this.source),
      folderId: clearFolder ? null : (folderId ?? this.folderId),
      tagId: clearTag ? null : (tagId ?? this.tagId),
      favorite: clearFavorite ? null : (favorite ?? this.favorite),
      folderName: clearFolder ? null : (folderName ?? this.folderName),
      tagName: clearTag ? null : (tagName ?? this.tagName),
    );
  }
}

class PostsState {
  final List<Post> posts;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final PostsFilter filter;
  final String? error;

  const PostsState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.filter = const PostsFilter(),
    this.error,
  });

  PostsState copyWith({
    List<Post>? posts,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    PostsFilter? filter,
    String? error,
    bool clearError = false,
  }) {
    return PostsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      filter: filter ?? this.filter,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PostsNotifier extends StateNotifier<PostsState> {
  final Dio _dio;
  static const int _pageSize = 20;

  PostsNotifier(this._dio) : super(const PostsState());

  Future<void> loadPosts({bool refresh = false}) async {
    if (state.isLoading) return;

    final page = refresh ? 0 : state.currentPage;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await getPosts(
        dio: _dio,
        q: state.filter.q,
        source: state.filter.source?.name.toUpperCase(),
        folderId: state.filter.folderId,
        tagId: state.filter.tagId,
        favorite: state.filter.favorite,
        page: page,
        size: _pageSize,
      );

      final newPosts = refresh ? result.content : [...state.posts, ...result.content];

      state = state.copyWith(
        posts: newPosts,
        isLoading: false,
        hasMore: result.content.length >= _pageSize,
        currentPage: page + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void updateFilter(PostsFilter filter) {
    state = state.copyWith(filter: filter);
    loadPosts(refresh: true);
  }

  Future<void> toggleFavorite(int postId) async {
    try {
      final updatedPost = await toggleFavoriteApi(dio: _dio, id: postId);
      state = state.copyWith(
        posts: state.posts.map((p) => p.id == postId ? updatedPost : p).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deletePost(int postId) async {
    try {
      await deletePostApi(dio: _dio, id: postId);
      state = state.copyWith(
        posts: state.posts.where((p) => p.id != postId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// Rename API functions to avoid name conflicts
Future<Post> toggleFavoriteApi({required Dio dio, required int id}) =>
    toggleFavorite(dio: dio, id: id);

Future<void> deletePostApi({required Dio dio, required int id}) =>
    deletePost(dio: dio, id: id);

final postsProvider =
    StateNotifierProvider<PostsNotifier, PostsState>((ref) {
  final dio = ref.watch(apiClientProvider);
  final notifier = PostsNotifier(dio);
  notifier.loadPosts();
  return notifier;
});
