# PostSaver Mobile — Phase 2: CRUD Screens Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use compose:subagent (recommended) or compose:execute to implement this plan task-by-task.

**Goal:** Build all CRUD screens — Posts list/create/edit with search/filters/pagination, Folders CRUD, Tags CRUD, and Profile screen — achieving functional parity with the Angular web frontend.

**Architecture:** Feature-first with Riverpod providers per feature. Each feature has its own API service, state notifier, and screens.

**Tech Stack:** Flutter, Riverpod, Dio, GoRouter, freezed models (already in place from Phase 1)

## Global Constraints

- All API calls go through the shared `apiClientProvider` (Dio with auth interceptor)
- Models already exist in `lib/core/models/` — do NOT recreate them
- Backend endpoints: Posts use pagination (`Page<Post>`), Folders/Tags return `List<T>`
- Portuguese UI strings throughout

---

## File Structure (new/modified)

```
lib/
  core/
    api/
      posts_api.dart        # Posts API service
      folders_api.dart      # Folders API service
      tags_api.dart         # Tags API service
  features/
    posts/
      posts_provider.dart   # Posts state + notifier
      posts_screen.dart     # List with search, filters, pagination
      post_form_screen.dart # Create/Edit form
    folders/
      folders_provider.dart
      folders_screen.dart   # List with swipe-to-delete, FAB
      folder_form_screen.dart
    tags/
      tags_provider.dart
      tags_screen.dart
      tag_form_screen.dart
    profile/
      profile_provider.dart
      profile_screen.dart   # View/edit /me, logout, delete account
  app.dart                  # Add new routes
```

---

### Task 9: Posts API Service

**Covers:** [S5, S6]

**Files:**
- Create: `frontend/postsaver/lib/core/api/posts_api.dart`

**Interfaces:**
- Consumes: `apiClientProvider`, `Post`, `PostRequest`, `PageResponse`
- Produces: `getPosts()`, `getPost()`, `createPost()`, `updatePost()`, `deletePost()`, `toggleFavorite()`

- [ ] **Step 1: Create posts_api.dart**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/post.dart';
import '../../core/models/page.dart';
import '../../core/auth/auth_provider.dart';

final postsApiProvider = Provider<PostsApi>((ref) {
  return PostsApi(ref.read(apiClientProvider));
});

class PostsApi {
  final Dio _client;
  PostsApi(this._client);

  Future<PageResponse<Post>> getPosts({
    String? q,
    String? source,
    int? folderId,
    int? tagId,
    bool? favorite,
    int page = 0,
    int size = 12,
    String sort = 'createdAt,desc',
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'size': size,
      'sort': sort,
    };
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (source != null) params['source'] = source;
    if (folderId != null) params['folderId'] = folderId;
    if (tagId != null) params['tagId'] = tagId;
    if (favorite != null) params['favorite'] = favorite;

    final response = await _client.get('/posts', queryParameters: params);
    return PageResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Post.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Post> getPost(int id) async {
    final response = await _client.get('/posts/$id');
    return Post.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Post> createPost(PostRequest request) async {
    final response = await _client.post('/posts', data: request.toJson());
    return Post.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Post> updatePost(int id, PostRequest request) async {
    final response = await _client.put('/posts/$id', data: request.toJson());
    return Post.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePost(int id) async {
    await _client.delete('/posts/$id');
  }

  Future<Post> toggleFavorite(int id) async {
    final response = await _client.patch('/posts/$id/favorite');
    return Post.fromJson(response.data as Map<String, dynamic>);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add frontend/postsaver/lib/core/api/posts_api.dart
git commit -m "feat(mobile): add posts API service"
```

---

### Task 10: Folders & Tags API Services

**Covers:** [S5, S6]

**Files:**
- Create: `frontend/postsaver/lib/core/api/folders_api.dart`
- Create: `frontend/postsaver/lib/core/api/tags_api.dart`

- [ ] **Step 1: Create folders_api.dart**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/folder.dart';
import '../../core/auth/auth_provider.dart';

final foldersApiProvider = Provider<FoldersApi>((ref) {
  return FoldersApi(ref.read(apiClientProvider));
});

class FoldersApi {
  final Dio _client;
  FoldersApi(this._client);

  Future<List<Folder>> getFolders() async {
    final response = await _client.get('/folders');
    return (response.data as List)
        .map((json) => Folder.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Folder> createFolder(FolderRequest request) async {
    final response = await _client.post('/folders', data: request.toJson());
    return Folder.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Folder> updateFolder(int id, FolderRequest request) async {
    final response = await _client.put('/folders/$id', data: request.toJson());
    return Folder.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteFolder(int id) async {
    await _client.delete('/folders/$id');
  }
}
```

- [ ] **Step 2: Create tags_api.dart**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/tag.dart';
import '../../core/auth/auth_provider.dart';

final tagsApiProvider = Provider<TagsApi>((ref) {
  return TagsApi(ref.read(apiClientProvider));
});

class TagsApi {
  final Dio _client;
  TagsApi(this._client);

  Future<List<Tag>> getTags() async {
    final response = await _client.get('/tags');
    return (response.data as List)
        .map((json) => Tag.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Tag> createTag(TagRequest request) async {
    final response = await _client.post('/tags', data: request.toJson());
    return Tag.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Tag> updateTag(int id, TagRequest request) async {
    final response = await _client.put('/tags/$id', data: request.toJson());
    return Tag.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteTag(int id) async {
    await _client.delete('/tags/$id');
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add frontend/postsaver/lib/core/api/folders_api.dart frontend/postsaver/lib/core/api/tags_api.dart
git commit -m "feat(mobile): add folders and tags API services"
```

---

### Task 11: Posts List Screen (with search, filters, pagination)

**Covers:** [S7]

**Files:**
- Create: `frontend/postsaver/lib/features/posts/posts_provider.dart`
- Create: `frontend/postsaver/lib/features/posts/posts_screen.dart`

- [ ] **Step 1: Create posts_provider.dart**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/post.dart';
import '../../core/models/page.dart';
import '../../core/api/posts_api.dart';

class PostsFilter {
  final String? q;
  final String? source;
  final int? folderId;
  final int? tagId;
  final bool? favorite;

  const PostsFilter({this.q, this.source, this.folderId, this.tagId, this.favorite});

  PostsFilter copyWith({String? q, String? source, int? folderId, int? tagId, bool? favorite}) {
    return PostsFilter(
      q: q ?? this.q,
      source: source ?? this.source,
      folderId: folderId ?? this.folderId,
      tagId: tagId ?? this.tagId,
      favorite: favorite ?? this.favorite,
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

  PostsState copyWith({List<Post>? posts, bool? isLoading, bool? hasMore, int? currentPage, PostsFilter? filter, String? error}) {
    return PostsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      filter: filter ?? this.filter,
      error: error,
    );
  }
}

class PostsNotifier extends StateNotifier<PostsState> {
  final PostsApi _api;
  PostsNotifier(this._api) : super(const PostsState());

  Future<void> loadPosts({bool refresh = false}) async {
    if (state.isLoading) return;
    if (refresh) {
      state = state.copyWith(posts: [], currentPage: 0, hasMore: true, error: null);
    }
    if (!state.hasMore && !refresh) return;

    state = state.copyWith(isLoading: true);
    try {
      final page = await _api.getPosts(
        q: state.filter.q,
        source: state.filter.source,
        folderId: state.filter.folderId,
        tagId: state.filter.tagId,
        favorite: state.filter.favorite,
        page: state.currentPage,
      );
      final newPosts = refresh ? page.content : [...state.posts, ...page.content];
      state = state.copyWith(
        posts: newPosts,
        isLoading: false,
        hasMore: page.number < page.totalPages - 1,
        currentPage: page.number + 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void updateFilter(PostsFilter filter) {
    state = state.copyWith(filter: filter);
    loadPosts(refresh: true);
  }

  Future<void> toggleFavorite(int postId) async {
    try {
      final updated = await _api.toggleFavorite(postId);
      state = state.copyWith(
        posts: state.posts.map((p) => p.id == postId ? updated : p).toList(),
      );
    } catch (_) {}
  }

  Future<void> deletePost(int postId) async {
    try {
      await _api.deletePost(postId);
      state = state.copyWith(posts: state.posts.where((p) => p.id != postId).toList());
    } catch (_) {}
  }
}

final postsProvider = StateNotifierProvider<PostsNotifier, PostsState>((ref) {
  return PostsNotifier(ref.read(postsApiProvider))..loadPosts();
});
```

- [ ] **Step 2: Create posts_screen.dart**

Create a screen with:
- Search bar at top
- Filter chips (source, favorite toggle)
- ListView.builder with infinite scroll
- Pull-to-refresh
- Swipe-to-delete or long-press menu
- FAB to create new post
- Empty state when no posts
- Each post card shows: title, source badge, thumbnail (if any), favorite icon, folder/tag chips

- [ ] **Step 3: Commit**

```bash
git add frontend/postsaver/lib/features/posts/
git commit -m "feat(mobile): add posts list screen with search, filters, pagination"
```

---

### Task 12: Post Create/Edit Form

**Covers:** [S7]

**Files:**
- Create: `frontend/postsaver/lib/features/posts/post_form_screen.dart`

- [ ] **Step 1: Create post_form_screen.dart**

Form fields:
- Title (required, max 120)
- URL (required, valid URL, max 500)
- Source (required, dropdown of SocialSource enum)
- Description (optional, max 500)
- Thumbnail URL (optional, valid URL, max 500)
- Favorite (switch)
- Folder (dropdown, loaded from folders API)
- Tags (multi-select chips, loaded from tags API)

On submit: call createPost or updatePost, pop with result.

- [ ] **Step 2: Commit**

```bash
git add frontend/postsaver/lib/features/posts/post_form_screen.dart
git commit -m "feat(mobile): add post create/edit form"
```

---

### Task 13: Folders Screen (CRUD)

**Covers:** [S7]

**Files:**
- Create: `frontend/postsaver/lib/features/folders/folders_provider.dart`
- Create: `frontend/postsaver/lib/features/folders/folders_screen.dart`
- Create: `frontend/postsaver/lib/features/folders/folder_form_screen.dart`

- [ ] **Step 1: Create folders_provider.dart** — state notifier with load/create/update/delete
- [ ] **Step 2: Create folders_screen.dart** — list with swipe-to-delete, FAB to create
- [ ] **Step 3: Create folder_form_screen.dart** — name, description, color picker
- [ ] **Step 4: Commit**

```bash
git add frontend/postsaver/lib/features/folders/
git commit -m "feat(mobile): add folders CRUD screens"
```

---

### Task 14: Tags Screen (CRUD)

**Covers:** [S7]

**Files:**
- Create: `frontend/postsaver/lib/features/tags/tags_provider.dart`
- Create: `frontend/postsaver/lib/features/tags/tags_screen.dart`
- Create: `frontend/postsaver/lib/features/tags/tag_form_screen.dart`

- [ ] **Step 1: Create tags_provider.dart** — state notifier with load/create/update/delete
- [ ] **Step 2: Create tags_screen.dart** — list with swipe-to-delete, FAB to create
- [ ] **Step 3: Create tag_form_screen.dart** — name, color picker
- [ ] **Step 4: Commit**

```bash
git add frontend/postsaver/lib/features/tags/
git commit -m "feat(mobile): add tags CRUD screens"
```

---

### Task 15: Profile Screen

**Covers:** [S7]

**Files:**
- Create: `frontend/postsaver/lib/features/profile/profile_provider.dart`
- Create: `frontend/postsaver/lib/features/profile/profile_screen.dart`
- Modify: `frontend/postsaver/lib/core/api/user_api.dart` (add getMe, updateMe, deleteMe)

- [ ] **Step 1: Update user_api.dart** — add getMe(), updateMe(), deleteMe()
- [ ] **Step 2: Create profile_provider.dart** — load user, update, delete
- [ ] **Step 3: Create profile_screen.dart** — view/edit name/username/email, logout button, delete account with confirmation
- [ ] **Step 4: Commit**

```bash
git add frontend/postsaver/lib/features/profile/ frontend/postsaver/lib/core/api/user_api.dart
git commit -m "feat(mobile): add profile screen with edit, logout, delete account"
```

---

### Task 16: Wire Up Routes & Navigation

**Covers:** [S7]

**Files:**
- Modify: `frontend/postsaver/lib/app.dart`
- Modify: `frontend/postsaver/lib/features/posts/posts_screen.dart` (if needed for navigation)

- [ ] **Step 1: Update app.dart** — add all new routes:
  - `/` → PostsScreen
  - `/posts/new` → PostFormScreen
  - `/posts/:id/edit` → PostFormScreen
  - `/folders` → FoldersScreen
  - `/folders/new` → FolderFormScreen
  - `/folders/:id/edit` → FolderFormScreen
  - `/tags` → TagsScreen
  - `/tags/new` → TagFormScreen
  - `/tags/:id/edit` → TagFormScreen
  - `/profile` → ProfileScreen

- [ ] **Step 2: Add bottom navigation bar** — Posts, Folders, Tags, Profile tabs
- [ ] **Step 3: Verify flutter analyze passes**
- [ ] **Step 4: Commit**

```bash
git add frontend/postsaver/lib/app.dart
git commit -m "feat(mobile): wire up all routes and bottom navigation"
```

---

### Task 17: Final Verification

**Files:** None (verification only)

- [ ] **Step 1: Run flutter analyze** — should pass with 0 errors
- [ ] **Step 2: Run flutter test** — should pass
- [ ] **Step 3: Create branch, commit, push, PR**

---

## Summary

After Phase 2, the app will have:
- Posts list with search, filters (source/folder/tag/favorite), infinite scroll, pull-to-refresh
- Post create/edit form with all fields
- Folders CRUD (list, create, edit, delete)
- Tags CRUD (list, create, edit, delete)
- Profile screen (view/edit user, logout, delete account)
- Bottom navigation bar
- All routes wired up

**Next phase:**
- Phase 3: Share sheet integration (Android intent → pre-fill create post)
- Phase 4: Polish (error states, loading states, edge cases)
