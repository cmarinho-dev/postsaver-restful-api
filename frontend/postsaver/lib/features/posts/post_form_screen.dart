import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/folders_api.dart';
import '../../core/api/metadata_api.dart';
import '../../core/api/posts_api.dart';
import '../../core/api/tags_api.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/api_error.dart';
import '../../core/models/folder.dart';
import '../../core/models/post.dart';
import '../../core/models/social_source.dart';
import '../../core/models/tag.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/source_style.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/skeleton.dart';
import '../share/share_provider.dart';

class PostFormScreen extends ConsumerStatefulWidget {
  final int? postId;
  final String? initialUrl;

  const PostFormScreen({super.key, this.postId, this.initialUrl});

  @override
  ConsumerState<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends ConsumerState<PostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _thumbnailUrlController = TextEditingController();

  SocialSource _source = SocialSource.other;
  bool _favorite = false;
  int? _folderId;
  Set<int> _selectedTagIds = {};

  List<Folder> _folders = [];
  List<Tag> _tags = [];
  bool _isLoadingData = true;
  bool _isSaving = false;
  bool _isFetchingMetadata = false;
  String? _errorMessage;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialUrl != null) {
      _urlController.text = widget.initialUrl!;
      _source = inferSocialSource(widget.initialUrl!);
      _fetchMetadata(silent: true);
    }
    _thumbnailUrlController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    _thumbnailUrlController.dispose();
    super.dispose();
  }

  Dio get _dio => ref.read(apiClientProvider);

  bool get _isEditing => widget.postId != null;

  String get _title => _isEditing ? 'Editar post' : 'Salvar post';

  String get _submitLabel => _isEditing ? 'Salvar alterações' : 'Salvar post';

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        getFolders(dio: _dio),
        getTags(dio: _dio),
        if (_isEditing) getPost(dio: _dio, id: widget.postId!),
      ]);

      if (!mounted) return;

      setState(() {
        _folders = results[0] as List<Folder>;
        _tags = results[1] as List<Tag>;

        if (_isEditing && results.length > 2) {
          final post = results[2] as Post;
          _titleController.text = post.title;
          _urlController.text = post.url;
          _descriptionController.text = post.description ?? '';
          _thumbnailUrlController.text = post.thumbnailUrl ?? '';
          _source = post.source;
          _favorite = post.favorite;
          _folderId = post.folder?.id;
          _selectedTagIds = post.tags.map((t) => t.id).toSet();
        }

        _isLoadingData = false;
        _isInitialized = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoadingData = false;
      });
    }
  }

  /// Busca título/descrição/thumbnail do link e preenche os campos vazios
  /// (nunca sobrescreve o que o usuário já digitou).
  Future<void> _fetchMetadata({bool silent = false}) async {
    final url = _urlController.text.trim();
    if (url.isEmpty || _isFetchingMetadata) return;

    setState(() => _isFetchingMetadata = true);

    try {
      final metadata = await fetchUrlMetadata(dio: _dio, url: url);
      if (!mounted) return;
      setState(() {
        if (_titleController.text.trim().isEmpty &&
            (metadata.title ?? '').isNotEmpty) {
          _titleController.text = metadata.title!;
        }
        if (_descriptionController.text.trim().isEmpty &&
            (metadata.description ?? '').isNotEmpty) {
          _descriptionController.text = metadata.description!;
        }
        if (_thumbnailUrlController.text.trim().isEmpty &&
            (metadata.thumbnailUrl ?? '').isNotEmpty) {
          _thumbnailUrlController.text = metadata.thumbnailUrl!;
        }
        if (metadata.source != SocialSource.other) {
          _source = metadata.source;
        }
      });
    } catch (_) {
      if (!silent && mounted) {
        showAppSnackBar(
          context,
          'Não foi possível buscar os dados do link',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingMetadata = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final request = PostRequest(
      title: _titleController.text.trim(),
      url: _urlController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      source: _source,
      thumbnailUrl: _thumbnailUrlController.text.trim().isEmpty
          ? null
          : _thumbnailUrlController.text.trim(),
      favorite: _favorite,
      folderId: _folderId,
      tagIds: _selectedTagIds.isEmpty ? null : _selectedTagIds,
    );

    try {
      final Post post;
      if (_isEditing) {
        post = await updatePost(
          dio: _dio,
          id: widget.postId!,
          post: request,
        );
      } else {
        post = await createPost(dio: _dio, post: request);
      }

      if (!mounted) return;
      showAppSnackBar(
        context,
        _isEditing ? 'Post atualizado' : 'Post salvo com sucesso',
      );
      Navigator.of(context).pop(post);
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro inesperado. Tente novamente.';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: const SkeletonList(count: 5),
      );
    }

    if (_errorMessage != null && !_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 44,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                FilledButton.tonal(
                  onPressed: _loadData,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final thumbnailUrl = _thumbnailUrlController.text.trim();
    final hasThumbPreview = thumbnailUrl.isNotEmpty &&
        (Uri.tryParse(thumbnailUrl)?.hasScheme ?? false);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().shake(hz: 4, duration: 400.ms),
              const SizedBox(height: 16),
            ],
            _SectionLabel(label: 'Rede social'),
            const SizedBox(height: 10),
            _SourceSelector(
              selected: _source,
              onSelect: (source) => setState(() => _source = source),
            ),
            const SizedBox(height: 24),
            _SectionLabel(label: 'Informações'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título *',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              maxLength: 120,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Título é obrigatório';
                }
                if (value.length > 120) {
                  return 'Máximo de 120 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'URL *',
                prefixIcon: const Icon(Icons.link_rounded),
                suffixIcon: _isFetchingMetadata
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      )
                    : IconButton(
                        onPressed: _fetchMetadata,
                        icon: const Icon(Icons.auto_fix_high_rounded),
                        tooltip: 'Preencher dados do link',
                      ),
              ),
              maxLength: 500,
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'URL é obrigatória';
                }
                if (value.length > 500) {
                  return 'Máximo de 500 caracteres';
                }
                final uri = Uri.tryParse(value);
                if (uri == null || !uri.hasScheme) {
                  return 'URL inválida';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                alignLabelWithHint: true,
              ),
              maxLength: 500,
              maxLines: 3,
              validator: (value) {
                if (value != null && value.length > 500) {
                  return 'Máximo de 500 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _thumbnailUrlController,
              decoration: const InputDecoration(
                labelText: 'URL da thumbnail',
                prefixIcon: Icon(Icons.image_outlined),
              ),
              maxLength: 500,
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (value.length > 500) {
                    return 'Máximo de 500 caracteres';
                  }
                  final uri = Uri.tryParse(value);
                  if (uri == null || !uri.hasScheme) {
                    return 'URL inválida';
                  }
                }
                return null;
              },
            ),
            if (hasThumbPreview) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const SkeletonBox(
                      height: double.infinity,
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppTheme.radiusM),
                      ),
                    ),
                    errorWidget: (_, _, _) => Container(
                      color: theme.colorScheme.surfaceContainerHigh,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Não foi possível carregar a imagem',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms),
            ],
            const SizedBox(height: 20),
            _SectionLabel(label: 'Organização'),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: _folderId,
              decoration: const InputDecoration(
                labelText: 'Pasta',
                prefixIcon: Icon(Icons.folder_outlined),
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Nenhuma'),
                ),
                ..._folders.map((folder) {
                  return DropdownMenuItem(
                    value: folder.id,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder_rounded,
                          size: 18,
                          color: parseHexColor(folder.color),
                        ),
                        const SizedBox(width: 8),
                        Text(folder.name),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (value) => setState(() => _folderId = value),
            ),
            const SizedBox(height: 16),
            if (_tags.isNotEmpty) ...[
              Text(
                'Tags',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  final isSelected = _selectedTagIds.contains(tag.id);
                  final tagColor = parseHexColor(tag.color);
                  return FilterChip(
                    avatar: isSelected
                        ? Icon(Icons.check_rounded, size: 16, color: tagColor)
                        : null,
                    label: Text(tag.name),
                    selected: isSelected,
                    selectedColor: tagColor.withValues(alpha: 0.16),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? tagColor
                          : theme.colorScheme.onSurface,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? tagColor.withValues(alpha: 0.5)
                          : theme.colorScheme.outlineVariant,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTagIds.add(tag.id);
                        } else {
                          _selectedTagIds.remove(tag.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            Card(
              child: SwitchListTile(
                secondary: Icon(
                  _favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: _favorite
                      ? AppColors.favorite
                      : theme.colorScheme.onSurfaceVariant,
                ),
                title: const Text(
                  'Favorito',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Destacar entre os seus favoritos'),
                value: _favorite,
                onChanged: (value) => setState(() => _favorite = value),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.subtleBrandGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
              ),
              icon: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.bookmark_added_rounded, size: 20),
              label: Text(_submitLabel),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}

/// Seletor visual de rede social em cards horizontais.
class _SourceSelector extends StatelessWidget {
  final SocialSource selected;
  final ValueChanged<SocialSource> onSelect;

  const _SourceSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: SocialSource.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final source = SocialSource.values[index];
          final style = SourceStyle.of(source);
          final isSelected = source == selected;

          return GestureDetector(
            onTap: () => onSelect(source),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: 84,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(
                  color: isSelected
                      ? style.color.withValues(alpha: 0.7)
                      : scheme.outlineVariant,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: style.color.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.1 : 1,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: style.gradient,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        style.icon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    style.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
