import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/auth/auth_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/auth_callback_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/folders/folder_form_screen.dart';
import 'features/folders/folders_screen.dart';
import 'features/posts/post_form_screen.dart';
import 'features/posts/posts_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/tags/tag_form_screen.dart';
import 'features/tags/tags_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Transição slide-up + fade para telas de formulário (estilo modal).
CustomTransitionPage<T> _slideUpPage<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Transição fade suave entre as abas do shell.
CustomTransitionPage<T> _fadePage<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthenticated = authState == AuthState.authenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (authState == AuthState.unknown) {
        return null;
      }

      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      // Auth routes (full-screen, no bottom nav)
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _fadePage(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const RegisterScreen()),
      ),
      GoRoute(
        path: '/callback',
        builder: (context, state) => const AuthCallbackScreen(),
      ),

      // Tab routes (bottom nav com estado preservado por aba)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) =>
                  _fadePage(state, const PostsScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/folders',
              pageBuilder: (context, state) =>
                  _fadePage(state, const FoldersScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/tags',
              pageBuilder: (context, state) =>
                  _fadePage(state, const TagsScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) =>
                  _fadePage(state, const ProfileScreen()),
            ),
          ]),
        ],
      ),

      // Form routes (full-screen, slide-up, no bottom nav)
      GoRoute(
        path: '/posts/new',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final initialUrl = state.uri.queryParameters['url'];
          return _slideUpPage(state, PostFormScreen(initialUrl: initialUrl));
        },
      ),
      GoRoute(
        path: '/posts/edit/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return _slideUpPage(state, PostFormScreen(postId: id));
        },
      ),
      GoRoute(
        path: '/folders/new',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _slideUpPage(state, const FolderFormScreen()),
      ),
      GoRoute(
        path: '/folders/edit/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return _slideUpPage(state, FolderFormScreen(folderId: id));
        },
      ),
      GoRoute(
        path: '/tags/new',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _slideUpPage(state, const TagFormScreen()),
      ),
      GoRoute(
        path: '/tags/edit/:tagId',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final tagId = int.parse(state.pathParameters['tagId']!);
          return _slideUpPage(state, TagFormScreen(tagId: tagId));
        },
      ),
    ],
  );
});

class PostSaverApp extends ConsumerWidget {
  const PostSaverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'PostSaver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.bookmark_border_rounded),
              selectedIcon: Icon(Icons.bookmark_rounded),
              label: 'Posts',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder_rounded),
              label: 'Pastas',
            ),
            NavigationDestination(
              icon: Icon(Icons.sell_outlined),
              selectedIcon: Icon(Icons.sell_rounded),
              label: 'Tags',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
