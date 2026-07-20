import 'package:flutter/material.dart';

import '../theme/source_style.dart';

/// Paleta de cores com seleção animada e opção de cor personalizada.
class ColorSwatchPicker extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const ColorSwatchPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  Future<void> _pickCustomColor(BuildContext context) async {
    final initial = parseHexColor(selected);
    final color = await showDialog<Color>(
      context: context,
      builder: (context) => _CustomColorDialog(initial: initial),
    );
    if (color != null) {
      onChanged(colorToHex(color));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedHex = selected?.toUpperCase();
    final isCustom = selectedHex != null &&
        !presetPalette.map(colorToHex).contains(selectedHex);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _SwatchCircle(
          isSelected: selected == null,
          onTap: () => onChanged(null),
          background: scheme.surfaceContainerHigh,
          child: Icon(
            Icons.block_rounded,
            size: 20,
            color: scheme.onSurfaceVariant,
          ),
        ),
        ...presetPalette.map((color) {
          final hex = colorToHex(color);
          final isSelected = selectedHex == hex;
          return _SwatchCircle(
            isSelected: isSelected,
            onTap: () => onChanged(isSelected ? null : hex),
            background: color,
            child: isSelected
                ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 22)
                : null,
          );
        }),
        _SwatchCircle(
          isSelected: isCustom,
          onTap: () => _pickCustomColor(context),
          background: isCustom ? parseHexColor(selected) : null,
          gradient: isCustom
              ? null
              : const SweepGradient(
                  colors: [
                    Color(0xFFFF5E8A),
                    Color(0xFFFFB300),
                    Color(0xFF4CAF50),
                    Color(0xFF00B0FF),
                    Color(0xFF6C4DF6),
                    Color(0xFFFF5E8A),
                  ],
                ),
          child: Icon(
            isCustom ? Icons.check_rounded : Icons.colorize_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ],
    );
  }
}

class _SwatchCircle extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Color? background;
  final Gradient? gradient;
  final Widget? child;

  const _SwatchCircle({
    required this.isSelected,
    required this.onTap,
    this.background,
    this.gradient,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        // Não usar curvas com overshoot aqui: o lerp do boxShadow extrapola
        // para blurRadius negativo e dispara assertion do dart:ui.
        curve: Curves.easeOutCubic,
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: background,
          gradient: gradient,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? scheme.onSurface : scheme.outlineVariant,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected && background != null
              ? [
                  BoxShadow(
                    color: background!.withValues(alpha: 0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _CustomColorDialog extends StatefulWidget {
  final Color initial;

  const _CustomColorDialog({required this.initial});

  @override
  State<_CustomColorDialog> createState() => _CustomColorDialogState();
}

class _CustomColorDialogState extends State<_CustomColorDialog> {
  late HSVColor _hsv = HSVColor.fromColor(widget.initial);

  @override
  Widget build(BuildContext context) {
    final color = _hsv.toColor();
    return AlertDialog(
      title: const Text('Cor personalizada'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _slider(
            'Matiz',
            _hsv.hue,
            360,
            (v) => setState(() => _hsv = _hsv.withHue(v)),
          ),
          _slider(
            'Saturação',
            _hsv.saturation,
            1,
            (v) => setState(() => _hsv = _hsv.withSaturation(v)),
          ),
          _slider(
            'Brilho',
            _hsv.value,
            1,
            (v) => setState(() => _hsv = _hsv.withValue(v)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(color),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          child: const Text('Selecionar'),
        ),
      ],
    );
  }

  Widget _slider(
    String label,
    double value,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 76,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Slider(value: value, max: max, onChanged: onChanged),
        ),
      ],
    );
  }
}
