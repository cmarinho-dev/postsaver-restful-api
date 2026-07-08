import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/folders_api.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/folder.dart';

class FoldersState {
  final List<Folder> folders;
  final bool isLoading;
  final String? error;

  const FoldersState({
    this.folders = const [],
    this.isLoading = false,
    this.error,
  });

  FoldersState copyWith({
    List<Folder>? folders,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return FoldersState(
      folders: folders ?? this.folders,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class FoldersNotifier extends StateNotifier<FoldersState> {
  final Dio _dio;

  FoldersNotifier(this._dio) : super(const FoldersState());

  Future<void> loadFolders({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final folders = await getFolders(dio: _dio);
      state = state.copyWith(folders: folders, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Folder> createFolder(FolderRequest folder) async {
    final newFolder = await createFolderApi(dio: _dio, folder: folder);
    state = state.copyWith(folders: [...state.folders, newFolder]);
    return newFolder;
  }

  Future<Folder> updateFolder(int id, FolderRequest folder) async {
    final updatedFolder = await updateFolderApi(dio: _dio, id: id, folder: folder);
    state = state.copyWith(
      folders: state.folders.map((f) => f.id == id ? updatedFolder : f).toList(),
    );
    return updatedFolder;
  }

  Future<void> deleteFolder(int id) async {
    await deleteFolderApi(dio: _dio, id: id);
    state = state.copyWith(folders: state.folders.where((f) => f.id != id).toList());
  }
}

Future<Folder> createFolderApi({required Dio dio, required FolderRequest folder}) =>
    createFolder(dio: dio, folder: folder);

Future<Folder> updateFolderApi({required Dio dio, required int id, required FolderRequest folder}) =>
    updateFolder(dio: dio, id: id, folder: folder);

Future<void> deleteFolderApi({required Dio dio, required int id}) =>
    deleteFolder(dio: dio, id: id);

final foldersProvider = StateNotifierProvider<FoldersNotifier, FoldersState>((ref) {
  final dio = ref.watch(apiClientProvider);
  final notifier = FoldersNotifier(dio);
  notifier.loadFolders();
  return notifier;
});
