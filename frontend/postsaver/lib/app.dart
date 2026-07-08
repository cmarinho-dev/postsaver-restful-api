import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/auth/auth_provider.dart';
import 'features/auth/auth_callback_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/tags/tag_form_screen.dart';
import 'features/tags/tags_screen.dart';
import 'features/folders/folder_form_screen.dart';
import 'features/folders/folders_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
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
      GoRoute(
        path: '/',
        builder: (context, state) => const _PlaceholderHome(),
      ),
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
        path: '/folders',
        builder: (context, state) => const FoldersScreen(),
      ),
      GoRoute(
        path: '/folders/new',
        builder: (context, state) => const FolderFormScreen(),
      ),
      GoRoute(
        path: '/folders/edit/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return FolderFormScreen(folderId: id);
        },
      ),
      GoRoute(
        path: '/tags',
        builder: (context, state) => const TagsScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const TagFormScreen(),
          ),
          GoRoute(
            path: 'edit/:tagId',
            builder: (context, state) {
              final tagId = int.parse(state.pathParameters['tagId']!);
              return TagFormScreen(tagId: tagId);
            },
          ),
        ],
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

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Home')),
    );
  }
}
