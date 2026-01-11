/// Estado Badge Widget
///
/// Componente reutilizable para mostrar el estado de una entrega o proforma
/// con etiqueta, color e ícono dinámicos desde la API.
///
/// Soporta dos modos:
/// 1. Async (con Riverpod) - Obtiene datos dinámicos
/// 2. Sync (con fallback) - Usa datos cacheados o hardcodeados

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/estado_riverpod_providers.dart';
import '../services/estados_helpers.dart';

/// Badge para mostrar estado - versión Riverpod (Recomendada)
///
/// Ejemplo:
/// ```dart
/// EstadoBadgeWidget(
///   categoria: 'entrega',
///   estadoCodigo: entrega.estado,
/// )
/// ```
class EstadoBadgeWidget extends ConsumerWidget {
  final String categoria;
  final String estadoCodigo;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const EstadoBadgeWidget({
    required this.categoria,
    required this.estadoCodigo,
    this.fontSize,
    this.padding,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtener label dinámico
    final labelAsync = ref.watch(
      estadoLabelProvider((categoria, estadoCodigo)),
    );

    // Obtener color dinámico
    final colorAsync = ref.watch(
      estadoColorProvider((categoria, estadoCodigo)),
    );

    // Obtener ícono dinámico
    final iconAsync = ref.watch(
      estadoIconProvider((categoria, estadoCodigo)),
    );

    return labelAsync.when(
      data: (label) {
        // Obtener color y ícono de forma sincrónica
        final color = colorAsync.maybeWhen(
          data: (c) => c,
          orElse: () => EstadosHelper.getEstadoColor(categoria, estadoCodigo),
        );

        final icon = iconAsync.maybeWhen(
          data: (i) => i,
          orElse: () => EstadosHelper.getEstadoIcon(categoria, estadoCodigo),
        );

        return _buildBadge(label, color, icon);
      },
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (err, stack) {
        // Fallback a valores sincrónicossi hay error
        final label = EstadosHelper.getEstadoLabel(categoria, estadoCodigo);
        final color = EstadosHelper.getEstadoColor(categoria, estadoCodigo);
        final icon = EstadosHelper.getEstadoIcon(categoria, estadoCodigo);
        return _buildBadge(label, color, icon);
      },
    );
  }

  Widget _buildBadge(String label, String colorHex, String icon) {
    final colorInt = EstadosHelper.colorHexToInt(colorHex);
    final bgColor = Color(colorInt);

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.15),
        border: Border.all(color: bgColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: TextStyle(fontSize: fontSize ?? 14),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: bgColor,
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge para mostrar estado - versión Sync (Simple)
///
/// Usa datos cacheados o fallback, sin necesidad de async.
/// Más rápido pero menos reactive a cambios de API.
///
/// Ejemplo:
/// ```dart
/// SimpleEstadoBadgeWidget(
///   categoria: 'entrega',
///   estadoCodigo: entrega.estado,
/// )
/// ```
class SimpleEstadoBadgeWidget extends StatelessWidget {
  final String categoria;
  final String estadoCodigo;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const SimpleEstadoBadgeWidget({
    required this.categoria,
    required this.estadoCodigo,
    this.fontSize,
    this.padding,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final label = EstadosHelper.getEstadoLabel(categoria, estadoCodigo);
    final colorHex = EstadosHelper.getEstadoColor(categoria, estadoCodigo);
    final icon = EstadosHelper.getEstadoIcon(categoria, estadoCodigo);

    final colorInt = EstadosHelper.colorHexToInt(colorHex);
    final bgColor = Color(colorInt);

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.15),
        border: Border.all(color: bgColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: TextStyle(fontSize: fontSize ?? 14),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: bgColor,
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip de estado - versión compacta
///
/// Similar a EstadoBadgeWidget pero con estilo tipo Chip
class EstadoChipWidget extends ConsumerWidget {
  final String categoria;
  final String estadoCodigo;
  final VoidCallback? onDeleted;

  const EstadoChipWidget({
    required this.categoria,
    required this.estadoCodigo,
    this.onDeleted,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labelAsync = ref.watch(
      estadoLabelProvider((categoria, estadoCodigo)),
    );

    final colorAsync = ref.watch(
      estadoColorProvider((categoria, estadoCodigo)),
    );

    return labelAsync.when(
      data: (label) {
        final colorHex = colorAsync.maybeWhen(
          data: (c) => c,
          orElse: () => EstadosHelper.getEstadoColor(categoria, estadoCodigo),
        );

        final colorInt = EstadosHelper.colorHexToInt(colorHex);
        final bgColor = Color(colorInt);

        return Chip(
          label: Text(label),
          backgroundColor: bgColor.withValues(alpha: 0.15),
          side: BorderSide(color: bgColor),
          onDeleted: onDeleted,
        );
      },
      loading: () => const SizedBox(
        width: 60,
        height: 32,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (err, stack) {
        final label = EstadosHelper.getEstadoLabel(categoria, estadoCodigo);
        final colorHex = EstadosHelper.getEstadoColor(categoria, estadoCodigo);
        final colorInt = EstadosHelper.colorHexToInt(colorHex);
        final bgColor = Color(colorInt);

        return Chip(
          label: Text(label),
          backgroundColor: bgColor.withValues(alpha: 0.15),
          side: BorderSide(color: bgColor),
          onDeleted: onDeleted,
        );
      },
    );
  }
}

/// Builder widget para acceder directamente al estado
///
/// Útil si necesitas más control o acceso a toda la información del estado
class EstadoBuilder extends ConsumerWidget {
  final String categoria;
  final String estadoCodigo;
  final Widget Function(
    BuildContext context,
    String label,
    String color,
    String icon,
  ) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object error, StackTrace stackTrace)?
      errorBuilder;

  const EstadoBuilder({
    required this.categoria,
    required this.estadoCodigo,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labelAsync = ref.watch(
      estadoLabelProvider((categoria, estadoCodigo)),
    );

    return labelAsync.when(
      data: (label) {
        final color = ref.watch(
          estadoColorProvider((categoria, estadoCodigo)),
        ).maybeWhen(
          data: (c) => c,
          orElse: () => EstadosHelper.getEstadoColor(categoria, estadoCodigo),
        );

        final icon = ref.watch(
          estadoIconProvider((categoria, estadoCodigo)),
        ).maybeWhen(
          data: (i) => i,
          orElse: () => EstadosHelper.getEstadoIcon(categoria, estadoCodigo),
        );

        return builder(context, label, color, icon);
      },
      loading: () => loadingBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator()),
      error: (error, stack) => errorBuilder?.call(context, error, stack) ??
          Center(child: Text('Error: $error')),
    );
  }
}
