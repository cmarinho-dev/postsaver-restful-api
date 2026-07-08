import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/folders_api.dart';
import '../../core/api/posts_api.dart';
import '../../core/api/tags_api.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/api_error.dart';
import '../../core/models/folder.dart';
import '../../core/models/post.dart';
import '../../core/models/social_source.dart';
import '../../core/models/tag.dart';
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
  String? _errorMessage;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialUrl != null) {
      _urlController.text = widget.initialUrl!;
      _source = inferSocialSource(widget.initialUrl!);
    }
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

  String get _title => _isEditing ? 'Editar Post' : 'Criar Post';

  String get _submitLabel => _isEditing ? 'Salvar' : 'Criar';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Post atualizado' : 'Post criado com sucesso')),
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
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && !_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _submit,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_submitLabel),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título *',
                border: OutlineInputBorder(),
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL *',
                border: OutlineInputBorder(),
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
            const SizedBox(height: 16),
            DropdownButtonFormField<SocialSource>(
              initialValue: _source,
              decoration: const InputDecoration(
                labelText: 'Fonte *',
                border: OutlineInputBorder(),
              ),
              items: SocialSource.values.map((source) {
                return DropdownMenuItem(
                  value: source,
                  child: Text(_sourceLabel(source)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _source = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _thumbnailUrlController,
              decoration: const InputDecoration(
                labelText: 'URL da Thumbnail',
                border: OutlineInputBorder(),
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
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Favorito'),
              value: _favorite,
              onChanged: (value) => setState(() => _favorite = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _folderId,
              decoration: const InputDecoration(
                labelText: 'Pasta',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Nenhuma'),
                ),
                ..._folders.map((folder) {
                  return DropdownMenuItem(
                    value: folder.id,
                    child: Text(folder.name),
                  );
                }),
              ],
              onChanged: (value) => setState(() => _folderId = value),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tags',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            if (_tags.isEmpty)
              const Text('Nenhuma tag disponível')
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _tags.map((tag) {
                  final isSelected = _selectedTagIds.contains(tag.id);
                  return FilterChip(
                    label: Text(tag.name),
                    selected: isSelected,
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
          ],
        ),
      ),
    );
  }

  String _sourceLabel(SocialSource source) {
    switch (source) {
      case SocialSource.instagram:
        return 'Instagram';
      case SocialSource.tiktok:
        return 'TikTok';
      case SocialSource.facebook:
        return 'Facebook';
      case SocialSource.kwai:
        return 'Kwai';
      case SocialSource.youtube:
        return 'YouTube';
      case SocialSource.twitter:
        return 'Twitter';
      case SocialSource.other:
        return 'Outro';
    }
  }
}
