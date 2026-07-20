import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/folders_api.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/api_error.dart';
import '../../core/models/folder.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/source_style.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/color_swatch_picker.dart';

class FolderFormScreen extends ConsumerStatefulWidget {
  final int? folderId;

  const FolderFormScreen({super.key, this.folderId});

  @override
  ConsumerState<FolderFormScreen> createState() => _FolderFormScreenState();
}

class _FolderFormScreenState extends ConsumerState<FolderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedColor;
  bool _isLoadingData = false;
  bool _isSaving = false;
  String? _errorMessage;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    if (_isEditing) {
      _loadFolder();
    } else {
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Dio get _dio => ref.read(apiClientProvider);

  bool get _isEditing => widget.folderId != null;

  String get _title => _isEditing ? 'Editar pasta' : 'Nova pasta';

  String get _submitLabel =>
      _isEditing ? 'Salvar alterações' : 'Criar pasta';

  Future<void> _loadFolder() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final folders = await getFolders(dio: _dio);
      final folder = folders.firstWhere((f) => f.id == widget.folderId);

      if (!mounted) return;

      setState(() {
        _nameController.text = folder.name;
        _descriptionController.text = folder.description ?? '';
        _selectedColor = folder.color;
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

    final request = FolderRequest(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      color: _selectedColor,
    );

    try {
      if (_isEditing) {
        await updateFolder(dio: _dio, id: widget.folderId!, folder: request);
      } else {
        await createFolder(dio: _dio, folder: request);
      }

      if (!mounted) return;
      showAppSnackBar(
        context,
        _isEditing ? 'Pasta atualizada' : 'Pasta criada com sucesso',
      );
      context.pop(true);
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
                  onPressed: _loadFolder,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final previewColor = parseHexColor(_selectedColor);

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
            // Preview da pasta
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      previewColor,
                      Color.lerp(previewColor, Colors.black, 0.25)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  boxShadow: [
                    BoxShadow(
                      color: previewColor.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.folder_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _nameController.text.trim().isEmpty
                    ? 'Sua pasta'
                    : _nameController.text.trim(),
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome *',
                prefixIcon: Icon(Icons.folder_outlined),
              ),
              maxLength: 60,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nome é obrigatório';
                }
                if (value.length > 60) {
                  return 'Máximo de 60 caracteres';
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
              maxLength: 160,
              maxLines: 3,
              validator: (value) {
                if (value != null && value.length > 160) {
                  return 'Máximo de 160 caracteres';
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
