import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_feedback.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await ref.read(authStateProvider.notifier).login();
    } on FlutterAppAuthUserCancelledException {
      // Usuário fechou o navegador sem concluir o login: não é erro.
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Não foi possível entrar. Tente novamente.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Blobs de gradiente ao fundo
          Positioned(
            top: -120,
            left: -80,
            child: _GradientBlob(
              size: 320,
              colors: [
                AppColors.brand.withValues(alpha: isDark ? 0.35 : 0.22),
                Colors.transparent,
              ],
            ),
          ),
          Positioned(
            bottom: -140,
            right: -100,
            child: _GradientBlob(
              size: 380,
              colors: [
                AppColors.accent.withValues(alpha: isDark ? 0.28 : 0.16),
                Colors.transparent,
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // Logo
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brand.withValues(alpha: 0.4),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bookmark_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  )
                      .animate()
                      .scale(
                        duration: 600.ms,
                        curve: Curves.easeOutBack,
                        begin: const Offset(0.5, 0.5),
                      )
                      .fadeIn(duration: 400.ms),
                  const SizedBox(height: 28),
                  Text(
                    'PostSaver',
                    style: theme.textTheme.displaySmall,
                  )
                      .animate()
                      .fadeIn(delay: 150.ms, duration: 500.ms)
                      .moveY(
                        begin: 16,
                        end: 0,
                        delay: 150.ms,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  const SizedBox(height: 12),
                  Text(
                    'Todos os seus posts favoritos,\norganizados em um só lugar.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 250.ms, duration: 500.ms)
                      .moveY(
                        begin: 16,
                        end: 0,
                        delay: 250.ms,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  const SizedBox(height: 36),
                  const _FeatureRow(
                    icon: Icons.ios_share_rounded,
                    text: 'Salve direto do Instagram, TikTok e YouTube',
                  ).animate().fadeIn(delay: 350.ms, duration: 400.ms).moveX(
                        begin: -16,
                        end: 0,
                        delay: 350.ms,
                        duration: 400.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  const SizedBox(height: 14),
                  const _FeatureRow(
                    icon: Icons.folder_rounded,
                    text: 'Organize com pastas e tags coloridas',
                  ).animate().fadeIn(delay: 450.ms, duration: 400.ms).moveX(
                        begin: -16,
                        end: 0,
                        delay: 450.ms,
                        duration: 400.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  const SizedBox(height: 14),
                  const _FeatureRow(
                    icon: Icons.favorite_rounded,
                    text: 'Encontre seus favoritos em segundos',
                  ).animate().fadeIn(delay: 550.ms, duration: 400.ms).moveX(
                        begin: -16,
                        end: 0,
                        delay: 550.ms,
                        duration: 400.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  const Spacer(flex: 3),
                  _GradientButton(
                    onPressed: _isLoading ? null : _login,
                    isLoading: _isLoading,
                    label: 'Entrar',
                  ).animate().fadeIn(delay: 650.ms, duration: 500.ms).moveY(
                        begin: 24,
                        end: 0,
                        delay: 650.ms,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed:
                        _isLoading ? null : () => context.push('/register'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text.rich(
                      TextSpan(
                        text: 'Ainda não tem conta? ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        children: [
                          TextSpan(
                            text: 'Criar conta',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 750.ms, duration: 500.ms),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const _GradientButton({
    required this.onPressed,
    required this.isLoading,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class _GradientBlob extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _GradientBlob({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}
