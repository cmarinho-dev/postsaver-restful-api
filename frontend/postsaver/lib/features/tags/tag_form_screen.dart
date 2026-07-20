import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/tags_api.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/api_error.dart';
import '../../core/models/tag.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/source_style.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/color_swatch_picker.dart';

class TagFormScreen extends ConsumerStatefulWidget {
  final int? tagId;

  const TagFormScreen({super.key, this.tagId});

  @override
  ConsumerState<TagFormScreen> createState() => _TagFormScreenState();
}

class _TagFormScreenState extends ConsumerState<TagFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String? _selectedColor;
  bool _isLoadingData = true;
  bool _isSaving = false;
  String? _errorMessage;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Dio get _dio => ref.read(apiClientProvider);

  bool get _isEditing => widget.tagId != null;

  String get _title => _isEditing ? 'Editar tag' : 'Nova tag';

  String get _submitLabel => _isEditing ? 'Salvar alterações' : 'Criar tag';

  Future<void> _loadData() async {
    if (!_isEditing) {
      setState(() {
        _isLoadingData = false;
        _isInitialized = true;
      });
      return;
    }

    try {
      final tags = await getTags(dio: _dio);
      final tag = tags.firstWhere((t) => t.id == widget.tagId);

      if (!mounted) return;

      setState(() {
        _nameController.text = tag.name;
        _selectedColor = tag.color;
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

    final request = TagRequest(
      name: _nameController.text.trim(),
      color: _selectedColor,
    );

    try {
      final Tag tag;
      if (_isEditing) {
        tag = await updateTag(
          dio: _dio,
          id: widget.tagId!,
          tag: request,
        );
      } else {
        tag = await createTag(dio: _dio, tag: request);
      }

      if (!mounted) return;
      showAppSnackBar(
        context,
        _isEditing ? 'Tag atualizada' : 'Tag criada com sucesso',
      );
      Navigator.of(context).pop(tag);
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
        body: const Center(child: CircularProgressIndicator()),
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
                Text(_errorMessage!, textAlign: TextAlign.center),
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

    final previewColor = parseHexColor(_selectedColor);
    final previewName = _nameController.text.trim().isEmpty
        ? 'sua tag'
        : _nameController.text.trim();

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
            // Preview da tag
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: previewColor.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.22 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: previewColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: previewColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      previewName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome *',
                prefixIcon: Icon(Icons.sell_outlined),
              ),
              maxLength: 40,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nome é obrigatório';
                }
                if (value.length > 40) {
                  return 'Máximo de 40 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Text(
              'COR',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ColorSwatchPicker(
              selected: _selectedColor,
              onChanged: (color) => setState(() => _selectedColor = color),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _submit,
            icon: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.check_rounded, size: 20),
            label: Text(_submitLabel),
          ),
        ),
      ),
    );
  }
}
