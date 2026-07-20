import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// SnackBar padronizado com ícone e tom de sucesso/erro.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  IconData? icon,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            icon ??
                (isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded),
            color: isError ? const Color(0xFFFF8A80) : const Color(0xFF9CFFC2),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

/// Bottom sheet de confirmação no estilo das grandes apps
/// (ícone, título, mensagem e ações empilhadas). Retorna true se confirmado.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
  IconData icon = Icons.warning_amber_rounded,
  bool isDestructive = false,
}) async {
  final theme = Theme.of(context);
  final result = await showModalBottomSheet<bool>(
    context: context,
    builder: (sheetContext) {
      final accent =
          isDestructive ? theme.colorScheme.error : theme.colorScheme.primary;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 34, color: accent),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: isDestructive
                      ? theme.colorScheme.onError
                      : theme.colorScheme.onPrimary,
                ),
                child: Text(confirmLabel),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(false),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                ),
                child: Text(cancelLabel),
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}
