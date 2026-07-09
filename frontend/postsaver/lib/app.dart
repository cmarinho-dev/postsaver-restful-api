import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/auth/auth_provider.dart';
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
final _shellNavigatorKey = GlobalKey<NavigatorState>();

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

      // Tab routes (with bottom nav via ShellRoute)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const PostsScreen(),
          ),
          GoRoute(
            path: '/folders',
            builder: (context, state) => const FoldersScreen(),
          ),
          GoRoute(
            path: '/tags',
            builder: (context, state) => const TagsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Form routes (full-screen, no bottom nav)
      GoRoute(
        path: '/posts/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final initialUrl = state.uri.queryParameters['url'];
          return PostFormScreen(initialUrl: initialUrl);
        },
      ),
      GoRoute(
        path: '/posts/edit/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return PostFormScreen(postId: id);
        },
      ),
      GoRoute(
        path: '/folders/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FolderFormScreen(),
      ),
      GoRoute(
        path: '/folders/edit/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return FolderFormScreen(folderId: id);
        },
      ),
      GoRoute(
        path: '/tags/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TagFormScreen(),
      ),
      GoRoute(
        path: '/tags/edit/:tagId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final tagId = int.parse(state.pathParameters['tagId']!);
          return TagFormScreen(tagId: tagId);
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

    return MaterialApp.router(
      title: 'PostSaver',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: router,
    );
  }
}

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _Calc.currentIndex(context),
        onTap: (index) => _onTap(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Posts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Folders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.label),
            label: 'Tags',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    final location = _navLocations[index];
    context.go(location);
  }
}

class _Calc {
  static int currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < _navLocations.length; i++) {
      if (location == _navLocations[i] ||
          (i == 0 && location == '/')) {
        return i;
      }
    }
    return 0;
  }
}

const _navLocations = ['/', '/folders', '/tags', '/profile'];
