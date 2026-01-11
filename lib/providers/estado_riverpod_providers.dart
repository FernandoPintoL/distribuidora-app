import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/estado.dart';
import '../services/estados_helpers.dart';

/// Providers de Riverpod para estados dinámicos
/// Usados por EstadoBadgeWidget y otros componentes

/// Obtener el label (nombre) de un estado
final estadoLabelProvider = FutureProvider.family<String, (String, String)>(
  (ref, params) async {
    final (categoria, codigo) = params;
    // En lugar de async, usamos el helper sincrónico directamente
    return EstadosHelper.getEstadoLabel(categoria, codigo);
  },
);

/// Obtener el color hexadecimal de un estado
final estadoColorProvider = FutureProvider.family<String, (String, String)>(
  (ref, params) async {
    final (categoria, codigo) = params;
    return EstadosHelper.getEstadoColor(categoria, codigo);
  },
);

/// Obtener el ícono/emoji de un estado
final estadoIconProvider = FutureProvider.family<String, (String, String)>(
  (ref, params) async {
    final (categoria, codigo) = params;
    return EstadosHelper.getEstadoIcon(categoria, codigo);
  },
);

/// Obtener todos los estados de una categoría
/// Devuelve objetos Estado completos con todas sus propiedades
final estadosPorCategoriaProvider = FutureProvider.family<List<Estado>, String>(
  (ref, categoria) async {
    try {
      // Obtener todos los estados para una categoría
      final estados = EstadosHelper.getEstadosActivos(categoria);
      return estados;
    } catch (e) {
      return [];
    }
  },
);
