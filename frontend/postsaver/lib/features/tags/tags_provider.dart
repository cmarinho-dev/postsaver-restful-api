import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/tags_api.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/tag.dart';

class TagsState {
  final List<Tag> tags;
  final bool isLoading;
  final String? error;

  const TagsState({
    this.tags = const [],
    this.isLoading = false,
    this.error,
  });

  TagsState copyWith({
    List<Tag>? tags,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TagsState(
      tags: tags ?? this.tags,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TagsNotifier extends StateNotifier<TagsState> {
  final Dio _dio;

  TagsNotifier(this._dio) : super(const TagsState());

  Future<void> loadTags() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final tags = await getTags(dio: _dio);
      state = state.copyWith(tags: tags, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Tag?> createTag(TagRequest request) async {
    state = state.copyWith(clearError: true);

    try {
      final tag = await createTagApi(dio: _dio, tag: request);
      state = state.copyWith(tags: [...state.tags, tag]);
      return tag;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<Tag?> updateTag(int id, TagRequest request) async {
    state = state.copyWith(clearError: true);

    try {
      final tag = await updateTagApi(dio: _dio, id: id, tag: request);
      state = state.copyWith(
        tags: state.tags.map((t) => t.id == id ? tag : t).toList(),
      );
      return tag;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> deleteTag(int id) async {
    state = state.copyWith(clearError: true);

    try {
      await deleteTagApi(dio: _dio, id: id);
      state = state.copyWith(
        tags: state.tags.where((t) => t.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

Future<Tag> createTagApi({required Dio dio, required TagRequest tag}) =>
    createTag(dio: dio, tag: tag);

Future<Tag> updateTagApi({required Dio dio, required int id, required TagRequest tag}) =>
    updateTag(dio: dio, id: id, tag: tag);

Future<void> deleteTagApi({required Dio dio, required int id}) =>
    deleteTag(dio: dio, id: id);

final tagsProvider = StateNotifierProvider<TagsNotifier, TagsState>((ref) {
  final dio = ref.watch(apiClientProvider);
  final notifier = TagsNotifier(dio);
  notifier.loadTags();
  return notifier;
});
