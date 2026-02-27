/// ✅ HELPERS: Lógica de filtros
class FiltroLogic {
  /// Construir texto de filtros activos para mostrar en banner
  static String getFiltroActivoText({
    String? filtroEstado,
    bool tieneSearchText = false,
    DateTime? filtroFechaDesde,
    DateTime? filtroFechaHasta,
    DateTime? filtroFechaVencimientoDesde,
    DateTime? filtroFechaVencimientoHasta,
    DateTime? filtroFechaEntregaSolicitadaDesde,
    DateTime? filtroFechaEntregaSolicitadaHasta,
  }) {
    final partes = <String>[];

    if (filtroEstado != null) {
      partes.add('Estado: $filtroEstado');
    }

    if (tieneSearchText) {
      partes.add('Búsqueda: activa');
    }

    if (filtroFechaDesde != null || filtroFechaHasta != null) {
      partes.add('Fecha de creación: activa');
    }

    if (filtroFechaVencimientoDesde != null ||
        filtroFechaVencimientoHasta != null) {
      partes.add('Fecha vencimiento: activa');
    }

    if (filtroFechaEntregaSolicitadaDesde != null ||
        filtroFechaEntregaSolicitadaHasta != null) {
      partes.add('Entrega solicitada: activa');
    }

    return partes.isEmpty ? 'Sin filtros' : partes.join(' • ');
  }

  /// Verificar si hay filtros activos
  static bool tieneFilatrosActivos({
    String? filtroEstado,
    bool tieneSearchText = false,
    DateTime? filtroFechaDesde,
    DateTime? filtroFechaHasta,
    DateTime? filtroFechaVencimientoDesde,
    DateTime? filtroFechaVencimientoHasta,
    DateTime? filtroFechaEntregaSolicitadaDesde,
    DateTime? filtroFechaEntregaSolicitadaHasta,
  }) {
    return filtroEstado != null ||
        tieneSearchText ||
        filtroFechaDesde != null ||
        filtroFechaHasta != null ||
        filtroFechaVencimientoDesde != null ||
        filtroFechaVencimientoHasta != null ||
        filtroFechaEntregaSolicitadaDesde != null ||
        filtroFechaEntregaSolicitadaHasta != null;
  }
}
