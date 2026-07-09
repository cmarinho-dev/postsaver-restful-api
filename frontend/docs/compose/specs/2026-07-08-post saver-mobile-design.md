# PostSaver Mobile — Design Spec

## [S1] Problem

Build a complete Flutter mobile app (Android + iOS) for PostSaver that provides functional parity with the existing Angular web frontend, plus the key differentiator: receiving shared URLs from other apps via the system share sheet and pre-filling a "save post" form.

## [S2] Decisions Resolved

| Decision | Choice |
|----------|--------|
| State management | Riverpod |
| OAuth library | flutter_appauth |
| Code location | Monorepo (`frontend/postsaver/`) |
| Registration | Native form |
| Offline | Online-only (v1) |
| Dev environment | LAN IP |

## [S3] Architecture

```
lib/
  core/
    config/        # Environment config (issuer, apiBase per env)
    api/           # Dio client, ApiError model, auth interceptor
    models/        # Dart models mirroring backend DTOs 1:1
  features/
    auth/          # Login (OAuth browser), Register (native form), callback
    posts/         # List (search+filters+pagination), Create/Edit, Favorite toggle
    folders/       # CRUD screens
    tags/          # CRUD screens
    profile/       # View/Edit /me, Logout, Delete account
    share/         # Receive shared URL → pre-fill create post
  app.dart         # MaterialApp + GoRouter setup
  main.dart        # Entry point, ProviderScope
```

## [S4] Data Models

All models use `freezed` + `json_serializable` for immutability and serialization.

### SocialSource (enum)
`INSTAGRAM`, `TIKTOK`, `FACEBOOK`, `KWAI`, `YOUTUBE`, `TWITTER`, `OTHER`

### Post
- `id` (int), `title` (String), `url` (String), `description` (String?), `source` (SocialSource), `thumbnailUrl` (String?), `favorite` (bool), `folder` (Folder?), `tags` (List<Tag>), `createdAt` (DateTime), `updatedAt` (DateTime)

### PostRequest
- `title` (String), `url` (String), `description` (String?), `source` (SocialSource), `thumbnailUrl` (String?), `favorite` (bool?), `folderId` (int?), `tagIds` (Set<int>?)

### Folder
- `id` (int), `name` (String), `description` (String?), `color` (String?), `createdAt` (DateTime)

### FolderRequest
- `name` (String), `description` (String?), `color` (String?)

### Tag
- `id` (int), `name` (String), `color` (String?)

### TagRequest
- `name` (String), `color` (String?)

### User
- `id` (int), `name` (String), `username` (String), `email` (String)

### UserRequest
- `name` (String), `username` (String), `email` (String), `password` (String)

### Page<T>
- `content` (List<T>), `totalElements` (int), `totalPages` (int), `number` (int), `size` (int)

### ApiError
- `status` (int), `message` (String), `details` (List<String>), `timestamp` (DateTime)

## [S5] Authentication Flow

1. **Login**: `flutter_appauth` opens system browser → backend's `/oauth2/authorize` → user logs in on server → redirect to `br.com.cmarinho.postsaver://callback` → exchange code for tokens (PKCE) → store refresh token in `flutter_secure_storage`, access token in memory.
2. **Refresh**: Dio interceptor catches 401 → refresh using stored refresh token → update access token in memory + refresh token in storage (rotation) → retry original request. If refresh fails → clear session → redirect to login.
3. **Logout**: Clear tokens from secure storage + reset auth state.

## [S6] API Layer

- Dio base client with `baseUrl = {apiBase}/api/v1`
- `AuthInterceptor`: attaches `Authorization: Bearer <token>`, handles 401 with single refresh retry
- Error handling: map HTTP status → `ApiError` → user-facing messages
- Folders and Tags return `List<T>` (no pagination). Posts return `Page<Post>` with default size=12.

## [S7] Screens (v1)

| Screen | Route | Description |
|--------|-------|-------------|
| Login | `/login` | "Entrar" button triggers OAuth browser flow |
| Register | `/register` | Native form → POST /api/v1/users → redirect to login |
| Posts List | `/` | Search bar, filter chips (source/folder/tag/favorite), infinite scroll, pull-to-refresh |
| Create/Edit Post | `/posts/new`, `/posts/:id/edit` | Form with all fields, pre-filled from share intent |
| Folders List | `/folders` | List with swipe-to-delete, FAB to create |
| Create/Edit Folder | `/folders/new`, `/folders/:id/edit` | Name, description, color picker |
| Tags List | `/tags` | List with swipe-to-delete, FAB to create |
| Create/Edit Tag | `/tags/new`, `/tags/:id/edit` | Name, color picker |
| Profile | `/profile` | View/edit name/username/email, logout button, delete account |
| Share Handler | (deep link) | Receives shared URL, navigates to create post with pre-filled URL |

## [S8] Share Sheet (Android)

- `intent-filter` for `ACTION_SEND` with `text/plain` in `AndroidManifest.xml`
- `receive_sharing_intent` package to receive shared content
- On receive: check auth → navigate to create post with URL pre-filled → infer `source` from domain
- Handle both cold start and app-already-running scenarios
- iOS Share Extension deferred to post-v1 (requires native Swift target)

## [S9] Platform Configuration

### Android
- `applicationId`: `br.com.cmarinho.postsaver`
- `minSdk`: 21
- Custom scheme: `br.com.cmarinho.postsaver` via `appAuthRedirectScheme` in build.gradle
- Intent filter for share: `ACTION_SEND`, `text/plain`

### iOS
- Custom scheme in `CFBundleURLTypes` (Info.plist)
- ATS exception for dev (`http://` on LAN IP) — production uses HTTPS

## [S10] Environment Config

```dart
class Environment {
  final String issuer;
  final String apiBase;
  final String redirectUri;
  
  // Dev: issuer = http://10.0.2.2:8080, apiBase = http://10.0.2.2:8080
  // iOS Sim: issuer = http://localhost:8080, apiBase = http://localhost:8080
  // Prod: issuer = https://postsaver.example.com, apiBase = https://postsaver.example.com
}
```

## [S11] Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  flutter_appauth: ^8.0.0
  flutter_secure_storage: ^9.2.4
  dio: ^5.7.0
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  go_router: ^14.8.1
  receive_sharing_intent: ^1.8.0

dev_dependencies:
  freezed: ^2.5.8
  json_serializable: ^6.8.0
  build_runner: ^2.4.13
```

## [S12] Phases

1. **Foundation**: Project setup, env config, API client + models, ApiError handling
2. **Auth**: Login via browser, secure storage, refresh/rotation, interceptor, route guard, logout
3. **CRUD Parity**: Posts (list/filters/pagination/create/edit/favorite), Folders, Tags, Profile
4. **Share Feature**: Android share sheet → save post (iOS deferred)
5. **Polish**: Error/offline states, loading states, tests, cleanup
