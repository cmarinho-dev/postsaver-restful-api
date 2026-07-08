import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/folders_api.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/api_error.dart';
import '../../core/models/folder.dart';

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

  static const List<String> _presetColors = [
    '#E53935', // Red
    '#D81B60', // Pink
    '#8E24AA', // Purple
    '#5E35B1', // Deep Purple
    '#3949AB', // Indigo
    '#1E88E5', // Blue
    '#039BE5', // Light Blue
    '#00ACC1', // Cyan
    '#00897B', // Teal
    '#43A047', // Green
    '#7CB342', // Light Green
    '#F4511E', // Deep Orange
    '#F4B400', // Amber
    '#6D4C41', // Brown
    '#546E7A', // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
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

  String get _title => _isEditing ? 'Editar Pasta' : 'Criar Pasta';

  String get _submitLabel => _isEditing ? 'Salvar' : 'Criar';

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

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) {
      return Colors.blue;
    }
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
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
                onPressed: _loadFolder,
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
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome *',
                border: OutlineInputBorder(),
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
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
            const SizedBox(height: 16),
            const Text(
              'Cor',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildColorOption(null, 'Nenhuma'),
                ..._presetColors.map((colorHex) => _buildColorOption(colorHex, null)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(String? colorHex, String? label) {
    final isSelected = _selectedColor == colorHex;
    final color = _parseColor(colorHex);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = colorHex;
        });
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 24)
            : (label != null
                ? Center(
                    child: Text(
                      label[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null),
      ),
    );
  }
}
