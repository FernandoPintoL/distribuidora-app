/// Constantes para estados de venta en logística según tabla estados_logistica
/// Categoría: 'venta_logistica'
class EstadosVenta {
  // Estados principales de venta
  static const String ENTREGADA = 'ENTREGADA';
  static const String CANCELADA = 'CANCELADA';

  /// Obtener nombre legible del estado
  static String getNombre(String codigo) {
    switch (codigo) {
      case ENTREGADA:
        return 'Entregada';
      case CANCELADA:
        return 'Cancelada';
      default:
        return codigo;
    }
  }

  /// Obtener color hex del estado (para UI)
  static String getColor(String codigo) {
    switch (codigo) {
      case ENTREGADA:
        return '#28A745'; // Verde
      case CANCELADA:
        return '#DC3545'; // Rojo
      default:
        return '#6C757D';
    }
  }

  /// Obtener icono del estado
  static String getIcono(String codigo) {
    switch (codigo) {
      case ENTREGADA:
        return 'check_circle';
      case CANCELADA:
        return 'cancel';
      default:
        return 'info';
    }
  }
}
