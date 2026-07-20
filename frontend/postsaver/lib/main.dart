import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/auth/auth_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/share/share_popup_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ProviderScope(
      child: const AppInit(),
    ),
  );
}

/// Entrypoint da ShareActivity translúcida: renderiza apenas o popup de
/// salvar post por cima do app que originou o compartilhamento.
@pragma('vm:entry-point')
void shareMain() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ProviderScope(
      child: MaterialApp(
        title: 'Salvar no PostSaver',
        debugShowCheckedModeBanner: false,
        color: Colors.transparent,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const SharePopupScreen(),
      ),
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
    return const PostSaverApp();
  }
}
