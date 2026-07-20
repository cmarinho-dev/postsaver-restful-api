import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/models/user.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/state_views.dart';
import 'profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(profileProvider.notifier).loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    final user = ref.read(profileProvider).user;
    if (user != null) {
      _nameController.text = user.name;
      _usernameController.text = user.username;
      _emailController.text = user.email;
    }
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(profileProvider).user;
    if (user == null) return;

    final request = UserRequest(
      name: _nameController.text,
      username: _usernameController.text,
      email: _emailController.text,
    );

    final updatedUser =
        await ref.read(profileProvider.notifier).updateUser(request);
    if (updatedUser != null && mounted) {
      setState(() {
        _isEditing = false;
      });
      showAppSnackBar(context, 'Perfil atualizado');
    }
  }

  Future<void> _logout() async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Sair da conta?',
      message: 'Você precisará entrar novamente para acessar seus posts.',
      confirmLabel: 'Sair',
      icon: Icons.logout_rounded,
    );
    if (confirmed) {
      await ref.read(authStateProvider.notifier).logout();
    }
  }

  Future<void> _deleteAccount() async {
    final controller = TextEditingController();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_forever_rounded,
                      size: 34,
                      color: theme.colorScheme.error,
                    ),
                  ).animate().scale(
                        duration: 350.ms,
                        curve: Curves.easeOutBack,
                        begin: const Offset(0.7, 0.7),
                      ),
                  const SizedBox(height: 20),
                  Text(
                    'Excluir conta?',
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Todos os seus posts, pastas e tags serão apagados para sempre. Essa ação não pode ser desfeita.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Digite EXCLUIR para confirmar',
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      final value = controller.text.trim().toUpperCase();
                      Navigator.of(sheetContext).pop(value == 'EXCLUIR');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                    ),
                    child: const Text('Excluir minha conta'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(false),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                    ),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    controller.dispose();

    if (confirmed == true && mounted) {
      final success = await ref.read(profileProvider.notifier).deleteUser();
      if (success && mounted) {
        showAppSnackBar(context, 'Conta excluída');
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child:
                        Text('Perfil', style: theme.textTheme.headlineSmall),
                  ),
                  if (profileState.user != null)
                    IconButton.outlined(
                      style: IconButton.styleFrom(
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      icon: Icon(
                        _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                        size: 20,
                      ),
                      onPressed: _toggleEdit,
                      tooltip: _isEditing ? 'Cancelar edição' : 'Editar perfil',
                    ),
                ],
              ),
            ),
            Expanded(child: _buildContent(profileState)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ProfileState profileState) {
    if (profileState.isLoading && profileState.user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (profileState.error != null && profileState.user == null) {
      return ErrorState(
        message: profileState.error!,
        onRetry: () => ref.read(profileProvider.notifier).loadUser(),
      );
    }

    final user = profileState.user;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header com avatar em gradiente
            Center(
              child: Column(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brand.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ).animate().scale(
                        duration: 450.ms,
                        curve: Curves.easeOutBack,
                        begin: const Offset(0.7, 0.7),
                      ),
                  const SizedBox(height: 14),
                  Text(user.name, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            if (_isEditing)
              _buildEditForm(profileState)
            else ...[
              _buildInfoCard(user),
              const SizedBox(height: 20),
              _buildAppearanceCard(),
              const SizedBox(height: 20),
              _buildAccountActions(),
            ],
            if (profileState.error != null && !_isEditing) ...[
              const SizedBox(height: 16),
              _ErrorBanner(message: profileState.error!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          children: [
            _InfoTile(
              icon: Icons.badge_outlined,
              title: 'Nome',
              value: user.name,
            ),
            const Divider(indent: 56),
            _InfoTile(
              icon: Icons.alternate_email_rounded,
              title: 'Usuário',
              value: user.username,
            ),
            const Divider(indent: 56),
            _InfoTile(
              icon: Icons.mail_outline_rounded,
              title: 'E-mail',
              value: user.email,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms).moveY(
          begin: 16,
          end: 0,
          delay: 100.ms,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildAppearanceCard() {
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text('Aparência', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 14),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('Sistema'),
                  icon: Icon(Icons.brightness_auto_rounded, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Claro'),
                  icon: Icon(Icons.light_mode_rounded, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Escuro'),
                  icon: Icon(Icons.dark_mode_rounded, size: 18),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (selection) {
                ref.read(themeModeProvider.notifier).setMode(selection.first);
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.14),
                selectedForegroundColor: theme.colorScheme.primary,
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              showSelectedIcon: false,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 180.ms, duration: 400.ms).moveY(
          begin: 16,
          end: 0,
          delay: 180.ms,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildAccountActions() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout_rounded, size: 20),
          label: const Text('Sair da conta'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _deleteAccount,
          icon: const Icon(Icons.delete_forever_rounded, size: 20),
          label: const Text('Excluir conta'),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(
              color: theme.colorScheme.error.withValues(alpha: 0.4),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 260.ms, duration: 400.ms).moveY(
          begin: 16,
          end: 0,
          delay: 260.ms,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildEditForm(ProfileState profileState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nome',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Nome é obrigatório';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: 'Nome de usuário',
            prefixIcon: Icon(Icons.alternate_email_rounded),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Nome de usuário é obrigatório';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'E-mail',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'E-mail é obrigatório';
            }
            if (!value.contains('@')) {
              return 'E-mail inválido';
            }
            return null;
          },
        ),
        if (profileState.error != null) ...[
          const SizedBox(height: 16),
          _ErrorBanner(message: profileState.error!),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: profileState.isLoading ? null : _saveProfile,
          icon: profileState.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Icon(Icons.check_rounded, size: 20),
          label: const Text('Salvar alterações'),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: theme.colorScheme.primary),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Text(
        value,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
