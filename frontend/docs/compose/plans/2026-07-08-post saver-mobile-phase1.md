# PostSaver Mobile — Phase 1: Foundation + Auth Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use compose:subagent (recommended) or compose:execute to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Set up the Flutter project with all dependencies, environment config, API client, data models, authentication flow (OAuth2 PKCE via browser), and basic routing — producing a runnable app that can log in, store tokens, and make authenticated API calls.

**Architecture:** Feature-first architecture with `core/` for shared infrastructure (auth, API, config, models) and `features/` for feature modules. Riverpod for state management, GoRouter for navigation, flutter_appauth for OAuth2, Dio for HTTP.

**Tech Stack:** Flutter 3.x, Dart 3.x, Riverpod, flutter_appauth, flutter_secure_storage, Dio, freezed, json_serializable, go_router

## Global Constraints

- `client_id`: `postsaver-mobile` (public client, no secret)
- `redirect_uri`: `br.com.cmarinho.postsaver://callback`
- Scopes: `openid profile`
- PKCE mandatory
- Refresh token rotation (new token on every refresh)
- Access token in memory only, refresh token in flutter_secure_storage
- App never sends `uid`/`userId` — identity comes from JWT
- `applicationId`: `br.com.cmarinho.postsaver`
- Dev issuer: `http://10.0.2.2:8080` (Android emulator), `http://localhost:8080` (iOS sim)

---

## File Structure

```
frontend/postsaver/
  lib/
    core/
      config/
        environment.dart          # Environment enum + config
      api/
        api_client.dart           # Dio instance + interceptors
        api_error.dart            # ApiError model
      models/
        social_source.dart        # SocialSource enum
        post.dart                 # Post + PostRequest (freezed)
        folder.dart               # Folder + FolderRequest (freezed)
        tag.dart                  # Tag + TagRequest (freezed)
        user.dart                 # User + UserRequest (freezed)
        page.dart                 # Page<T> (freezed)
      auth/
        auth_service.dart         # OAuth login/logout/refresh via flutter_appauth
        auth_provider.dart        # Riverpod providers for auth state
        auth_interceptor.dart     # Dio interceptor for Bearer token + 401 handling
        auth_guard.dart           # GoRouter redirect for unauthenticated routes
    features/
      auth/
        login_screen.dart         # "Entrar" button
        register_screen.dart      # Native registration form
        auth_callback_screen.dart # Handles deep link callback
      posts/                      # (Phase 2)
      folders/                    # (Phase 2)
      tags/                       # (Phase 2)
      profile/                    # (Phase 2)
      share/                      # (Phase 3)
    app.dart                      # MaterialApp + GoRouter + ProviderScope
    main.dart                     # Entry point
  android/app/src/main/AndroidManifest.xml  # Custom scheme + share intent filter
  ios/Runner/Info.plist                      # Custom scheme URL type
```

---

### Task 1: Project Dependencies & Environment Config

**Covers:** [S3, S10, S11]

**Files:**
- Modify: `frontend/postsaver/pubspec.yaml`
- Create: `frontend/postsaver/lib/core/config/environment.dart`

**Interfaces:**
- Produces: `Environment` class with `issuer`, `apiBase`, `redirectUri` getters

- [ ] **Step 1: Update pubspec.yaml with all dependencies**

Replace the `dependencies` and `dev_dependencies` sections in `frontend/postsaver/pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_riverpod: ^2.6.1
  flutter_appauth: ^8.0.0
  flutter_secure_storage: ^9.2.4
  dio: ^5.7.0
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  go_router: ^14.8.1
  receive_sharing_intent: ^1.8.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  freezed: ^2.5.8
  json_serializable: ^6.8.0
  build_runner: ^2.4.13
```

- [ ] **Step 2: Run flutter pub get**

```bash
cd frontend/postsaver && flutter pub get
```

- [ ] **Step 3: Create environment config**

Create `frontend/postsaver/lib/core/config/environment.dart`:

```dart
enum AppEnvironment { dev, staging, prod }

class Environment {
  final String issuer;
  final String apiBase;
  final String redirectUri;

  const Environment({
    required this.issuer,
    required this.apiBase,
    required this.redirectUri,
  });

  static const _redirectUri = 'br.com.cmarinho.postsaver://callback';

  static const dev = Environment(
    issuer: 'http://10.0.2.2:8080',
    apiBase: 'http://10.0.2.2:8080',
    redirectUri: _redirectUri,
  );

  static const devIOSSim = Environment(
    issuer: 'http://localhost:8080',
    apiBase: 'http://localhost:8080',
    redirectUri: _redirectUri,
  );

  static const prod = Environment(
    issuer: 'https://postsaver.example.com',
    apiBase: 'https://postsaver.example.com',
    redirectUri: _redirectUri,
  );

  static Environment get current => dev;
}
```

- [ ] **Step 4: Commit**

```bash
git add frontend/postsaver/pubspec.yaml frontend/postsaver/pubspec.lock frontend/postsaver/lib/core/config/environment.dart
git commit -m "feat(mobile): add dependencies and environment config"
```

---

### Task 2: Data Models (freezed)

**Covers:** [S4]

**Files:**
- Create: `frontend/postsaver/lib/core/models/social_source.dart`
- Create: `frontend/postsaver/lib/core/models/post.dart`
- Create: `frontend/postsaver/lib/core/models/folder.dart`
- Create: `frontend/postsaver/lib/core/models/tag.dart`
- Create: `frontend/postsaver/lib/core/models/user.dart`
- Create: `frontend/postsaver/lib/core/models/page.dart`
- Create: `frontend/postsaver/lib/core/models/api_error.dart`

**Interfaces:**
- Produces: All data models with `fromJson`/`toJson` factories

- [ ] **Step 1: Create SocialSource enum**

Create `frontend/postsaver/lib/core/models/social_source.dart`:

```dart
import 'package:json_annotation/json_annotation.dart';

part 'social_source.g.dart';

@JsonEnum(alwaysInclude: true)
enum SocialSource {
  @JsonValue('INSTAGRAM')
  instagram,
  @JsonValue('TIKTOK')
  tiktok,
  @JsonValue('FACEBOOK')
  facebook,
  @JsonValue('KWAI')
  kwai,
  @JsonValue('YOUTUBE')
  youtube,
  @JsonValue('TWITTER')
  twitter,
  @JsonValue('OTHER')
  other;
}
```

- [ ] **Step 2: Create Post model**

Create `frontend/postsaver/lib/core/models/post.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'folder.dart';
import 'tag.dart';
import 'social_source.dart';

part 'post.freezed.dart';
part 'post.g.dart';

@freezed
class Post with _$Post {
  const factory Post({
    required int id,
    required String title,
    required String url,
    String? description,
    required SocialSource source,
    String? thumbnailUrl,
    required bool favorite,
    Folder? folder,
    @Default([]) List<Tag> tags,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}

@freezed
class PostRequest with _$PostRequest {
  const factory PostRequest({
    required String title,
    required String url,
    String? description,
    required SocialSource source,
    String? thumbnailUrl,
    bool? favorite,
    int? folderId,
    Set<int>? tagIds,
  }) = _PostRequest;

  factory PostRequest.fromJson(Map<String, dynamic> json) =>
      _$PostRequestFromJson(json);
}
```

- [ ] **Step 3: Create Folder model**

Create `frontend/postsaver/lib/core/models/folder.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'folder.freezed.dart';
part 'folder.g.dart';

@freezed
class Folder with _$Folder {
  const factory Folder({
    required int id,
    required String name,
    String? description,
    String? color,
    required DateTime createdAt,
  }) = _Folder;

  factory Folder.fromJson(Map<String, dynamic> json) =>
      _$FolderFromJson(json);
}

@freezed
class FolderRequest with _$FolderRequest {
  const factory FolderRequest({
    required String name,
    String? description,
    String? color,
  }) = _FolderRequest;

  factory FolderRequest.fromJson(Map<String, dynamic> json) =>
      _$FolderRequestFromJson(json);
}
```

- [ ] **Step 4: Create Tag model**

Create `frontend/postsaver/lib/core/models/tag.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag.freezed.dart';
part 'tag.g.dart';

@freezed
class Tag with _$Tag {
  const factory Tag({
    required int id,
    required String name,
    String? color,
  }) = _Tag;

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);
}

@freezed
class TagRequest with _$TagRequest {
  const factory TagRequest({
    required String name,
    String? color,
  }) = _TagRequest;

  factory TagRequest.fromJson(Map<String, dynamic> json) =>
      _$TagRequestFromJson(json);
}
```

- [ ] **Step 5: Create User model**

Create `frontend/postsaver/lib/core/models/user.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required int id,
    required String name,
    required String username,
    required String email,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
class UserRequest with _$UserRequest {
  const factory UserRequest({
    required String name,
    required String username,
    required String email,
    required String password,
  }) = _UserRequest;

  factory UserRequest.fromJson(Map<String, dynamic> json) =>
      _$UserRequestFromJson(json);
}
```

- [ ] **Step 6: Create Page model**

Create `frontend/postsaver/lib/core/models/page.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'page.freezed.dart';
part 'page.g.dart';

@freezed
class PageResponse<T> with _$PageResponse<T> {
  const factory PageResponse({
    required List<T> content,
    required int totalElements,
    required int totalPages,
    required int number,
    required int size,
  }) = _PageResponse;

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$PageResponseFromJson(json, fromJsonT);
}
```

- [ ] **Step 7: Create ApiError model**

Create `frontend/postsaver/lib/core/models/api_error.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_error.freezed.dart';
part 'api_error.g.dart';

@freezed
class ApiError with _$ApiError {
  const factory ApiError({
    required int status,
    required String message,
    @Default([]) List<String> details,
    DateTime? timestamp,
  }) = _ApiError;

  factory ApiError.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorFromJson(json);
}
```

- [ ] **Step 8: Run build_runner to generate freezed code**

```bash
cd frontend/postsaver && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 9: Commit**

```bash
git add frontend/postsaver/lib/core/models/
git commit -m "feat(mobile): add data models with freezed"
```

---

### Task 3: API Client & Error Handling

**Covers:** [S5, S6]

**Files:**
- Create: `frontend/postsaver/lib/core/api/api_client.dart`
- Create: `frontend/postsaver/lib/core/api/api_error_handler.dart`

**Interfaces:**
- Consumes: `Environment.current`, `ApiError` model
- Produces: `apiClient` (Dio instance), `handleApiError()` function

- [ ] **Step 1: Create API client**

Create `frontend/postsaver/lib/core/api/api_client.dart`:

```dart
import 'package:dio/dio.dart';
import '../config/environment.dart';

Dio createApiClient() {
  return Dio(
    BaseOptions(
      baseUrl: '${Environment.current.apiBase}/api/v1',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );
}
```

- [ ] **Step 2: Create API error handler**

Create `frontend/postsaver/lib/core/api/api_error_handler.dart`:

```dart
import 'package:dio/dio.dart';
import '../models/api_error.dart';

String handleApiError(Object error) {
  if (error is DioException) {
    if (error.response?.data is Map<String, dynamic>) {
      try {
        final apiError = ApiError.fromJson(error.response!.data as Map<String, dynamic>);
        if (apiError.details.isNotEmpty) {
          return '${apiError.message}\n${apiError.details.join('\n')}';
        }
        return apiError.message;
      } catch (_) {}
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      default:
        return 'An unexpected error occurred.';
    }
  }
  return 'An unexpected error occurred.';
}
```

- [ ] **Step 3: Commit**

```bash
git add frontend/postsaver/lib/core/api/
git commit -m "feat(mobile): add API client and error handler"
```

---

### Task 4: Auth Service (OAuth2 PKCE)

**Covers:** [S5, S6]

**Files:**
- Create: `frontend/postsaver/lib/core/auth/auth_service.dart`
- Create: `frontend/postsaver/lib/core/auth/auth_provider.dart`
- Create: `frontend/postsaver/lib/core/auth/auth_interceptor.dart`

**Interfaces:**
- Consumes: `Environment.current`, `flutter_appauth`, `flutter_secure_storage`, `Dio`
- Produces: `authServiceProvider`, `authStateProvider`, `authInterceptorProvider`

- [ ] **Step 1: Create AuthService**

Create `frontend/postsaver/lib/core/auth/auth_service.dart`:

```dart
import 'dart:convert';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/environment.dart';

class AuthService {
  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  bool get isAuthenticated => _accessToken != null;

  Future<void> init() async {
    _refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    _accessToken = await _secureStorage.read(key: _accessTokenKey);
  }

  Future<bool> login() async {
    try {
      final env = Environment.current;
      final result = await _appAuth.authorizeAndExchangeToken(
        AuthorizationTokenRequest(
          'postsaver-mobile',
          env.redirectUri,
          issuer: env.issuer,
          scopes: ['openid', 'profile'],
          preferEphemeralSession: true,
        ),
      );
      if (result != null) {
        await _saveTokens(result);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> refresh() async {
    if (_refreshToken == null) return false;
    try {
      final env = Environment.current;
      final result = await _appAuth.token(
        TokenRequest(
          'postsaver-mobile',
          env.redirectUri,
          issuer: env.issuer,
          refreshToken: _refreshToken,
          scopes: ['openid', 'profile'],
        ),
      );
      if (result != null) {
        await _saveTokens(result);
        return true;
      }
      return false;
    } catch (e) {
      await logout();
      return false;
    }
  }

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  Future<void> _saveTokens(TokenResponse tokenResponse) async {
    _accessToken = tokenResponse.accessToken;
    _refreshToken = tokenResponse.refreshToken ?? _refreshToken;

    if (_accessToken != null) {
      await _secureStorage.write(key: _accessTokenKey, value: _accessToken);
    }
    if (_refreshToken != null) {
      await _secureStorage.write(key: _refreshTokenKey, value: _refreshToken);
    }
  }

  Map<String, dynamic>? decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = base64Url.normalize(parts[1]);
      return jsonDecode(utf8.decode(base64Url.decode(payload)))
          as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
```

- [ ] **Step 2: Create auth providers**

Create `frontend/postsaver/lib/core/auth/auth_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref.read(authServiceProvider));
});

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
  });

  AuthState copyWith({bool? isAuthenticated, bool? isLoading}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthStateNotifier(this._authService) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    await _authService.init();
    state = AuthState(
      isAuthenticated: _authService.isAuthenticated,
      isLoading: false,
    );
  }

  Future<bool> login() async {
    state = state.copyWith(isLoading: true);
    final success = await _authService.login();
    state = AuthState(
      isAuthenticated: success,
      isLoading: false,
    );
    return success;
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState();
  }

  Future<bool> refresh() async {
    return _authService.refresh();
  }
}
```

- [ ] **Step 3: Create auth interceptor**

Create `frontend/postsaver/lib/core/auth/auth_interceptor.dart`:

```dart
import 'package:dio/dio.dart';
import 'auth_service.dart';
import 'auth_provider.dart';

class AuthInterceptor extends Interceptor {
  final AuthService _authService;
  final Ref _ref;

  AuthInterceptor(this._authService, this._ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _authService.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && _authService.refreshToken != null) {
      final refreshed = await _authService.refresh();
      if (refreshed) {
        err.requestOptions.headers['Authorization'] =
            'Bearer ${_authService.accessToken}';
        try {
          final response = await Dio().fetch(err.requestOptions);
          handler.resolve(response);
          return;
        } catch (_) {}
      }
      await _authService.logout();
      _ref.read(authStateProvider.notifier).logout();
    }
    handler.next(err);
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add frontend/postsaver/lib/core/auth/
git commit -m "feat(mobile): add OAuth2 auth service with PKCE and token refresh"
```

---

### Task 5: Android Platform Configuration

**Covers:** [S8, S9]

**Files:**
- Modify: `frontend/postsaver/android/app/build.gradle.kts`
- Modify: `frontend/postsaver/android/app/src/main/AndroidManifest.xml`

**Interfaces:**
- Consumes: Custom scheme `br.com.cmarinho.postsaver`

- [ ] **Step 1: Update Android build.gradle.kts**

Edit `frontend/postsaver/android/app/build.gradle.kts`:

```kotlin
android {
    namespace = "br.com.cmarinho.postsaver"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "br.com.cmarinho.postsaver"
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    flutter {
        manifestPlaceholders += mapOf(
            "appAuthRedirectScheme" to "br.com.cmarinho.postsaver"
        )
    }
}
```

- [ ] **Step 2: Update AndroidManifest.xml with share intent filter**

Edit `frontend/postsaver/android/app/src/main/AndroidManifest.xml` to add inside `<activity>`:

```xml
<intent-filter>
    <action android:name="android.intent.action.SEND" />
    <category android:name="android.intent.category.DEFAULT" />
    <data android:mimeType="text/plain" />
</intent-filter>
```

- [ ] **Step 3: Commit**

```bash
git add frontend/postsaver/android/
git commit -m "feat(mobile): configure Android custom scheme and share intent filter"
```

---

### Task 6: iOS Platform Configuration

**Covers:** [S9]

**Files:**
- Modify: `frontend/postsaver/ios/Runner/Info.plist`

**Interfaces:**
- Consumes: Custom scheme `br.com.cmarinho.postsaver`

- [ ] **Step 1: Add custom URL scheme to Info.plist**

Edit `frontend/postsaver/ios/Runner/Info.plist` and add inside `<dict>`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>br.com.cmarinho.postsaver</string>
        </array>
    </dict>
</array>
```

- [ ] **Step 2: Commit**

```bash
git add frontend/postsaver/ios/
git commit -m "feat(mobile): configure iOS custom URL scheme"
```

---

### Task 7: App Shell & Router

**Covers:** [S3, S7]

**Files:**
- Create: `frontend/postsaver/lib/app.dart`
- Modify: `frontend/postsaver/lib/main.dart`

**Interfaces:**
- Consumes: `authStateProvider`, `authServiceProvider`
- Produces: `app` widget with GoRouter routes

- [ ] **Step 1: Create app.dart with GoRouter**

Create `frontend/postsaver/lib/app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/auth_callback_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/callback';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/callback',
        builder: (context, state) => const AuthCallbackScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('PostSaver Home (Phase 2)')),
        ),
      ),
    ],
  );
});

class PostSaverApp extends ConsumerWidget {
  const PostSaverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final authState = ref.watch(authStateProvider);

    if (authState.isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp.router(
      title: 'PostSaver',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
```

- [ ] **Step 2: Update main.dart**

Replace `frontend/postsaver/lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: PostSaverApp()));
}
```

- [ ] **Step 3: Create placeholder screens**

Create `frontend/postsaver/lib/features/auth/login_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('PostSaver', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: authState.isLoading
                  ? null
                  : () => ref.read(authStateProvider.notifier).login(),
              child: authState.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Entrar'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.push('/register'),
              child: const Text('Criar conta'),
            ),
          ],
        ),
      ),
    );
  }
}
```

Create `frontend/postsaver/lib/features/auth/register_screen.dart`:

```dart
import 'package:flutter/material.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Register (Phase 2)')),
    );
  }
}
```

Create `frontend/postsaver/lib/features/auth/auth_callback_screen.dart`:

```dart
import 'package:flutter/material.dart';

class AuthCallbackScreen extends StatelessWidget {
  const AuthCallbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
```

- [ ] **Step 4: Verify the app builds**

```bash
cd frontend/postsaver && flutter analyze
```

- [ ] **Step 5: Commit**

```bash
git add frontend/postsaver/lib/
git commit -m "feat(mobile): add app shell with GoRouter and login screen"
```

---

### Task 8: Registration Screen

**Covers:** [S7]

**Files:**
- Modify: `frontend/postsaver/lib/features/auth/register_screen.dart`
- Create: `frontend/postsaver/lib/core/api/user_api.dart`

**Interfaces:**
- Consumes: `apiClient`, `UserRequest` model
- Produces: `registerUser()` function

- [ ] **Step 1: Create user API service**

Create `frontend/postsaver/lib/core/api/user_api.dart`:

```dart
import '../api/api_client.dart';
import '../models/user.dart';

final _client = createApiClient();

Future<void> registerUser(UserRequest request) async {
  await _client.post('/users', data: request.toJson());
}
```

- [ ] **Step 2: Implement registration form**

Replace `frontend/postsaver/lib/features/auth/register_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/models/user.dart';
import '../../core/api/user_api.dart';
import '../../core/api/api_error_handler.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await registerUser(UserRequest(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conta criada! Faça login.')),
        );
        Navigator.of(context).pop();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(handleApiError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) => (v == null || v.isEmpty || v.length > 50)
                    ? 'Nome obrigatório (max 50)'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Usuário'),
                validator: (v) => (v == null || v.isEmpty || v.length > 20)
                    ? 'Usuário obrigatório (max 20)'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'E-mail obrigatório';
                  if (v.length > 120) return 'Max 120 caracteres';
                  if (!v.contains('@')) return 'E-mail inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Senha'),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Senha obrigatória';
                  if (v.length < 6 || v.length > 72) {
                    return 'Senha deve ter 6–72 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Cadastrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add frontend/postsaver/lib/features/auth/register_screen.dart frontend/postsaver/lib/core/api/user_api.dart
git commit -m "feat(mobile): add registration screen with form validation"
```

---

## Summary

After completing this plan, the app will have:
- All dependencies installed
- Environment config for dev/staging/prod
- Complete data models (freezed) matching backend DTOs 1:1
- API client with error handling
- OAuth2 PKCE login via system browser
- Token storage in secure storage with refresh rotation
- Auth interceptor on Dio (auto-refresh on 401)
- GoRouter with auth guard
- Android custom scheme + share intent filter
- iOS custom URL scheme
- Login screen with "Entrar" button
- Registration screen with native form

**Next phases:**
- Phase 2: CRUD screens (Posts list/create/edit, Folders, Tags, Profile)
- Phase 3: Share sheet integration
- Phase 4: Polish (error states, loading, tests)
