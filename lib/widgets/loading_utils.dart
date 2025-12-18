import 'package:flutter/material.dart';
import 'loading_dialog.dart';

/// Utilidades para mostrar y manejar diálogos de carga
class LoadingUtils {
  // Guarda la referencia del diálogo actual
  static BuildContext? _currentDialogContext;

  /// Muestra un diálogo de carga
  /// Ejemplo:
  /// LoadingUtils.show(context, 'Iniciando sesión...');
  static Future<void> show(
    BuildContext context,
    String message, {
    String? subtitle,
    bool dismissible = false,
    Duration? autoCloseDuration,
  }) async {
    // Si ya hay un diálogo, cerrarlo primero
    if (_currentDialogContext != null && _canPop(_currentDialogContext!)) {
      Navigator.of(_currentDialogContext!).pop();
    }

    _currentDialogContext = context;

    await showDialog(
      context: context,
      barrierDismissible: dismissible,
      builder: (context) => LoadingDialog(
        message: message,
        subtitle: subtitle,
        dismissible: dismissible,
        autoCloseDuration: autoCloseDuration,
      ),
    ).then((_) {
      _currentDialogContext = null;
    });
  }

  /// Muestra un diálogo de carga para login
  static Future<void> showLogin(BuildContext context) => show(
        context,
        'Iniciando sesión...',
        subtitle: 'Por favor espera',
      );

  /// Muestra un diálogo de carga para proforma
  static Future<void> showProforma(BuildContext context) => show(
        context,
        'Generando proforma...',
        subtitle: 'Esto puede tomar un momento',
      );

  /// Muestra un diálogo de carga para carga masiva
  static Future<void> showBulkLoad(BuildContext context) => show(
        context,
        'Cargando datos...',
        subtitle: 'Sincronizando con el servidor',
      );

  /// Muestra un diálogo de carga genérico
  static Future<void> showGeneric(
    BuildContext context,
    String message, {
    String? subtitle,
  }) =>
      show(
        context,
        message,
        subtitle: subtitle,
      );

  /// Cierra el diálogo de carga actual
  static void hide(BuildContext context) {
    if (_currentDialogContext != null && _canPop(_currentDialogContext!)) {
      Navigator.of(_currentDialogContext!).pop();
      _currentDialogContext = null;
    }
  }

  /// Cierra y muestra un mensaje de éxito
  static Future<void> hideAndShowSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) async {
    hide(context);

    await Future.delayed(const Duration(milliseconds: 300));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green[600],
          duration: duration,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  /// Cierra y muestra un mensaje de error
  static Future<void> hideAndShowError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) async {
    hide(context);

    await Future.delayed(const Duration(milliseconds: 300));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red[600],
          duration: duration,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  /// Verifica si es posible hacer pop del contexto
  static bool _canPop(BuildContext context) {
    try {
      return Navigator.canPop(context);
    } catch (e) {
      return false;
    }
  }
}
