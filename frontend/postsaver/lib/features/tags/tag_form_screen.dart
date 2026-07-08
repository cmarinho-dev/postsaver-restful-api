import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/tags_api.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/api_error.dart';
import '../../core/models/tag.dart';

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
    '#C0CA33', // Lime
    '#FDD835', // Yellow
    '#FFB300', // Amber
    '#FB8C00', // Orange
    '#F4511E', // Deep Orange
    '#6D4C41', // Brown
    '#757575', // Grey
    '#546E7A', // Blue Grey
    '#26A69A', // Teal variant
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Dio get _dio => ref.read(apiClientProvider);

  bool get _isEditing => widget.tagId != null;

  String get _title => _isEditing ? 'Editar Tag' : 'Criar Tag';

  String get _submitLabel => _isEditing ? 'Salvar' : 'Criar';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Tag atualizada' : 'Tag criada com sucesso')),
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
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome *',
                border: OutlineInputBorder(),
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
            const SizedBox(height: 16),
            const Text(
              'Cor',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildColorPicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected color preview
        if (_selectedColor != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(
                    int.parse(_selectedColor!.replaceFirst('#', '0xFF')),
                  ),
                  radius: 16,
                ),
                const SizedBox(width: 8),
                Text('Cor selecionada: $_selectedColor'),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _selectedColor = null),
                  child: const Text('Remover'),
                ),
              ],
            ),
          ),
        // Preset colors
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetColors.map((color) {
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedColor = isSelected ? null : color;
              }),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.black, width: 3)
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Custom color button
        OutlinedButton.icon(
          onPressed: () => _showColorPickerDialog(),
          icon: const Icon(Icons.color_lens),
          label: const Text('Escolher cor personalizada'),
        ),
      ],
    );
  }

  Future<void> _showColorPickerDialog() async {
    final color = await showDialog<Color>(
      context: context,
      builder: (context) => _ColorPickerDialog(),
    );

    if (color != null) {
      final hexColor = '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
      setState(() => _selectedColor = hexColor);
    }
  }
}

class _ColorPickerDialog extends StatefulWidget {
  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Escolher cor'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _selectedColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 16),
            _buildColorSlider('Vermelho', (_selectedColor.r * 255).round().clamp(0, 255), (value) {
              setState(() {
                _selectedColor = Color.fromARGB(
                  255,
                  value.round(),
                  (_selectedColor.g * 255).round().clamp(0, 255),
                  (_selectedColor.b * 255).round().clamp(0, 255),
                );
              });
            }),
            _buildColorSlider('Verde', (_selectedColor.g * 255).round().clamp(0, 255), (value) {
              setState(() {
                _selectedColor = Color.fromARGB(
                  255,
                  (_selectedColor.r * 255).round().clamp(0, 255),
                  value.round(),
                  (_selectedColor.b * 255).round().clamp(0, 255),
                );
              });
            }),
            _buildColorSlider('Azul', (_selectedColor.b * 255).round().clamp(0, 255), (value) {
              setState(() {
                _selectedColor = Color.fromARGB(
                  255,
                  (_selectedColor.r * 255).round().clamp(0, 255),
                  (_selectedColor.g * 255).round().clamp(0, 255),
                  value.round(),
                );
              });
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selectedColor),
          child: const Text('Selecionar'),
        ),
      ],
    );
  }

  Widget _buildColorSlider(String label, int value, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(value.toString()),
        ),
      ],
    );
  }
}
