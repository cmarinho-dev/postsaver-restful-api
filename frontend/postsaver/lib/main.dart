import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/auth/auth_provider.dart';
import 'features/share/share_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ProviderScope(
      child: const AppInit(),
    ),
  );
}

class AppInit extends ConsumerStatefulWidget {
  const AppInit({super.key});

  @override
  ConsumerState<AppInit> createState() => _AppInitState();
}

class _AppInitState extends ConsumerState<AppInit> {
  @override
  void initState() {
    super.initState();
    ref.read(authStateProvider.notifier).init();
  }

  @override
  Widget build(BuildContext context) {
    return const ShareHandler(
      child: PostSaverApp(),
    );
  }
}
