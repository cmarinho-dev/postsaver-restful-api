import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/metadata_api.dart';
import '../../core/api/posts_api.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/post.dart';
import '../../core/models/social_source.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/source_badge.dart';
import 'share_provider.dart';

const shareChannel = MethodChannel('br.com.cmarinho.postsaver/share');

enum _PopupStage { loading, loggedOut, invalid, form, saving, saved }

/// Popup de "salvar post" renderizado pela ShareActivity translúcida:
/// o app de origem (Instagram etc.) permanece visível atrás do sheet.
class SharePopupScreen extends ConsumerStatefulWidget {
  const SharePopupScreen({super.key});

  @override
  ConsumerState<SharePopupScreen> createState() => _SharePopupScreenState();
}

class _SharePopupScreenState extends ConsumerState<SharePopupScreen> {
  final _titleController = TextEditingController();

  _PopupStage _stage = _PopupStage.loading;
  String? _url;
  SocialSource _source = SocialSource.other;
  String? _description;
  String? _thumbnailUrl;
  bool _favorite = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
    _bootstrap();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final sharedText = await shareChannel.invokeMethod<String>('getSharedText');
    final url = sharedText == null ? null : extractSharedUrl(sharedText);
    if (url == null) {
      setState(() => _stage = _PopupStage.invalid);
      return;
    }
    _url = url;
    _source = inferSocialSource(url);

    await ref.read(authStateProvider.notifier).init();
    if (!mounted) return;
    if (ref.read(authStateProvider) != AuthState.authenticated) {
      setState(() => _stage = _PopupStage.loggedOut);
      return;
    }

    try {
      final metadata = await fetchUrlMetadata(
        dio: ref.read(apiClientProvider),
        url: url,
      );
      _titleController.text = metadata.title ?? '';
      _description = metadata.description;
      _thumbnailUrl = metadata.thumbnailUrl;
      if (metadata.source != SocialSource.other) {
        _source = metadata.source;
      }
    } catch (_) {
      // Sem metadados o formulário abre vazio; o usuário digita o título.
    }
    if (!mounted) return;
    setState(() => _stage = _PopupStage.form);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _url == null) return;

    setState(() {
      _stage = _PopupStage.saving;
      _saveError = null;
    });

    try {
      await createPost(
        dio: ref.read(apiClientProvider),
        post: PostRequest(
          title: title,
          url: _url!,
          description: _description,
          source: _source,
          thumbnailUrl: _thumbnailUrl,
          favorite: _favorite,
        ),
      );
      if (!mounted) return;
      setState(() => _stage = _PopupStage.saved);
      Timer(const Duration(milliseconds: 1100), _close);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _PopupStage.form;
        _saveError = 'Não foi possível salvar. Tente novamente.';
      });
    }
  }

  void _close() => shareChannel.invokeMethod('close');

  void _openApp() => shareChannel.invokeMethod('openApp');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Backdrop: fecha ao tocar fora do card.
          Positioned.fill(
            child: GestureDetector(
              onTap: _stage == _PopupStage.saving ? null : _close,
              child: Container(color: Colors.black54)
                  .animate()
                  .fadeIn(duration: 200.ms),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _grabHandle(theme),
                      _header(theme),
                      const SizedBox(height: 4),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _content(theme),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .slideY(
                      begin: 0.25,
                      duration: 320.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .fadeIn(duration: 220.ms),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _grabHandle(ThemeData theme) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }

  Widget _header(ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.bookmark_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Salvar no PostSaver',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          onPressed: _stage == _PopupStage.saving ? null : _close,
          icon: const Icon(Icons.close_rounded),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _content(ThemeData theme) {
    switch (_stage) {
      case _PopupStage.loading:
        return _loading(theme);
      case _PopupStage.loggedOut:
        return _message(
          theme,
          key: const ValueKey('loggedOut'),
          icon: Icons.lock_outline_rounded,
          text: 'Entre no PostSaver para salvar posts compartilhados.',
          actionLabel: 'Abrir PostSaver',
          onAction: _openApp,
        );
      case _PopupStage.invalid:
        return _message(
          theme,
          key: const ValueKey('invalid'),
          icon: Icons.link_off_rounded,
          text: 'Nenhum link válido foi encontrado no compartilhamento.',
          actionLabel: 'Fechar',
          onAction: _close,
        );
      case _PopupStage.saved:
        return _savedBadge(theme);
      case _PopupStage.form:
      case _PopupStage.saving:
        return _form(theme);
    }
  }

  Widget _loading(ThemeData theme) {
    return Padding(
      key: const ValueKey('loading'),
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 14),
          Text(
            'Buscando informações do link…',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _message(
    ThemeData theme, {
    required Key key,
    required IconData icon,
    required String text,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _savedBadge(ThemeData theme) {
    return Padding(
      key: const ValueKey('saved'),
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              gradient: AppColors.brandGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 36,
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.5, 0.5),
                duration: 350.ms,
                curve: Curves.easeOutCubic,
              )
              .fadeIn(duration: 200.ms),
          const SizedBox(height: 14),
          Text(
            'Post salvo!',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _form(ThemeData theme) {
    final isSaving = _stage == _PopupStage.saving;
    final canSave = !isSaving && _titleController.text.trim().isNotEmpty;

    return Column(
      key: const ValueKey('form'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_thumbnailUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: _thumbnailUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => _thumbFallback(theme),
                placeholder: (_, _) => Container(
                  color: theme.colorScheme.surfaceContainerHigh,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            SourceBadge(source: _source),
            const Spacer(),
            IconButton(
              onPressed: isSaving
                  ? null
                  : () => setState(() => _favorite = !_favorite),
              icon: Icon(
                _favorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: _favorite
                    ? AppColors.favorite
                    : theme.colorScheme.onSurfaceVariant,
              ),
              tooltip: 'Favorito',
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _titleController,
          enabled: !isSaving,
          maxLength: 120,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Título',
            hintText: 'Dê um nome para este post',
            counterText: '',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.link_rounded,
              size: 15,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _url ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        if (_saveError != null) ...[
          const SizedBox(height: 10),
          Text(
            _saveError!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: canSave ? AppColors.subtleBrandGradient : null,
              color: canSave ? null : theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: FilledButton(
              onPressed: canSave ? _save : null,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Salvar post',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _thumbFallback(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
