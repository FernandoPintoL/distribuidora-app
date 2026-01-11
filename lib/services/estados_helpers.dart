/// Helpers para Estados - funciones sincrónicas para uso en modelos
///
/// Proporciona funciones helper que usan los fallback hardcodeados
/// para obtener información de estados sin necesidad de async/await.
///
/// Para usar en Riverpod/AsyncValue, revisar estados_provider.dart

import '../models/estado.dart';

class EstadosHelper {
  /// Cache en memoria de estados por categoría
  /// Se llena la primera vez que se accede y se invalida manualmente
  static Map<String, List<Estado>> _estadosCache = {};

  /// Actualiza el caché en memoria (llamar desde providers después de obtener datos)
  static void updateCache(String categoria, List<Estado> estados) {
    _estadosCache[categoria] = estados;
  }

  /// Limpia el caché en memoria
  static void clearCache() {
    _estadosCache.clear();
  }

  /// Obtiene un estado por código (usa caché + fallback)
  static Estado? getEstadoPorCodigo(String categoria, String codigo) {
    final estados = _getEstadosForCategoria(categoria);
    try {
      return estados.firstWhere((e) => e.codigo == codigo);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene un estado por ID (usa caché + fallback)
  static Estado? getEstadoPorId(String categoria, int id) {
    final estados = _getEstadosForCategoria(categoria);
    try {
      return estados.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene el label de un estado por código
  static String getEstadoLabel(String categoria, String codigo) {
    final estado = getEstadoPorCodigo(categoria, codigo);
    return estado?.nombre ?? codigo;
  }

  /// Obtiene el color (hex) de un estado por código
  static String getEstadoColor(String categoria, String codigo) {
    final estado = getEstadoPorCodigo(categoria, codigo);
    return estado?.color ?? '#000000';
  }

  /// Obtiene el ícono de un estado por código
  static String getEstadoIcon(String categoria, String codigo) {
    final estado = getEstadoPorCodigo(categoria, codigo);
    return estado?.icono ?? '❓';
  }

  /// Obtiene la descripción de un estado
  static String? getEstadoDescripcion(String categoria, String codigo) {
    final estado = getEstadoPorCodigo(categoria, codigo);
    return estado?.descripcion;
  }

  /// Obtiene todos los estados para una categoría (usa caché + fallback)
  static List<Estado> _getEstadosForCategoria(String categoria) {
    // Intentar desde caché en memoria
    if (_estadosCache.containsKey(categoria)) {
      return _estadosCache[categoria]!;
    }

    // Fallback a hardcodeados
    switch (categoria.toLowerCase()) {
      case 'entrega':
        return FALLBACK_ESTADOS_ENTREGA;
      case 'proforma':
        return FALLBACK_ESTADOS_PROFORMA;
      case 'venta_logistica':
      case 'ventalogistica':
        return FALLBACK_ESTADOS_VENTA_LOGISTICA;
      default:
        return [];
    }
  }

  /// Obtiene todos los estados para una categoría (solo para lectura)
  static List<Estado> getEstados(String categoria) {
    return _getEstadosForCategoria(categoria);
  }

  /// Obtiene solo los estados activos
  static List<Estado> getEstadosActivos(String categoria) {
    return _getEstadosForCategoria(categoria).where((e) => e.activo).toList();
  }

  /// Verifica si un estado es final (no permite más transiciones)
  static bool esEstadoFinal(String categoria, String codigo) {
    final estado = getEstadoPorCodigo(categoria, codigo);
    return estado?.esEstadoFinal ?? false;
  }

  /// Verifica si un estado permite edición
  static bool permiteEdicion(String categoria, String codigo) {
    final estado = getEstadoPorCodigo(categoria, codigo);
    return estado?.permiteEdicion ?? false;
  }

  /// Convierte color hex a Color (para Flutter UI)
  /// Ej: '#3B82F6' -> Color(0xFF3B82F6)
  static int colorHexToInt(String hexColor) {
    // Remover # si existe
    String hex = hexColor.replaceFirst('#', '');

    // Si tiene menos de 6 caracteres, asumir que es válido
    if (hex.length == 6) {
      hex = 'FF$hex'; // Agregar alpha channel (opaco)
    } else if (hex.length == 8) {
      // Ya tiene alpha channel
    } else {
      return 0xFF000000; // Default black si formato inválido
    }

    return int.parse(hex, radix: 16);
  }

  /// Obtiene los metadatos de un estado
  static Map<String, dynamic>? getMetadatos(String categoria, String codigo) {
    final estado = getEstadoPorCodigo(categoria, codigo);
    return estado?.metadatos;
  }
}

// ==========================================
// Extension methods para convenience
// ==========================================

extension EstadoStringExtension on String {
  /// Ej: 'entrega'.estadoLabel('PROGRAMADO') -> 'Programado'
  String estadoLabel() => this.isEmpty ? '' : EstadosHelper.getEstadoLabel('entrega', this);

  /// Ej: 'PROGRAMADO'.estadoColor('entrega') -> '#eab308'
  String estadoColor() => this.isEmpty ? '#000000' : EstadosHelper.getEstadoColor('entrega', this);

  /// Ej: 'PROGRAMADO'.estadoIcon('entrega') -> '📅'
  String estadoIcon() => this.isEmpty ? '❓' : EstadosHelper.getEstadoIcon('entrega', this);
}
