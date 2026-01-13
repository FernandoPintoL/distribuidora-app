/// Constantes para estados de logística según tabla estados_logistica
/// Categoría: 'entrega'
class EstadosEntrega {
  // Estados principales
  static const String ENTREGADO = 'ENTREGADA';
  static const String EN_TRANSITO = 'EN_RUTA';
  static const String EN_CAMINO = 'EN_RUTA';
  static const String LLEGO = 'LLEGO';

  // Estados de preparación
  static const String PREPARACION_CARGA = 'PREPARACION_CARGA';
  static const String EN_CARGA = 'EN_CARGA';
  static const String LISTO_PARA_ENTREGA = 'LISTO_PARA_ENTREGA';

  // Estados iniciales
  static const String PROGRAMADO = 'PROGRAMADO';
  static const String ASIGNADA = 'ASIGNADA';

  // Estados de excepción
  static const String NOVEDAD = 'NOVEDAD';
  static const String RECHAZADO = 'RECHAZADO';
  static const String CANCELADA = 'CANCELADA';

  /// Estados agrupados para el chofer (principales)
  static const List<String> ESTADOS_EN_PREPARACION = [
    PREPARACION_CARGA,
    EN_CARGA,
  ];
  static const List<String> ESTADOS_EN_RUTA = [EN_TRANSITO, EN_CAMINO, LLEGO];

  /// Estados finales (no hay más cambios)
  static const List<String> ESTADOS_FINALES = [ENTREGADO, RECHAZADO, CANCELADA];

  /// Estados pendientes (aún hay trabajo)
  static const List<String> ESTADOS_PENDIENTES = [
    PROGRAMADO,
    ASIGNADA,
    PREPARACION_CARGA,
    EN_CARGA,
    LISTO_PARA_ENTREGA,
    EN_CAMINO,
    EN_TRANSITO,
    LLEGO,
    NOVEDAD,
  ];

  /// Obtener nombre legible del estado
  static String getNombre(String codigo) {
    switch (codigo) {
      case ENTREGADO:
        return 'Entregado';
      case EN_TRANSITO:
        return 'En Tránsito';
      case EN_CAMINO:
        return 'En Camino';
      case LLEGO:
        return 'Llegó';
      case PREPARACION_CARGA:
        return 'Preparación de Carga';
      case EN_CARGA:
        return 'En Carga';
      case LISTO_PARA_ENTREGA:
        return 'Listo para Entrega';
      case PROGRAMADO:
        return 'Programado';
      case ASIGNADA:
        return 'Asignada';
      case NOVEDAD:
        return 'Con Novedad';
      case RECHAZADO:
        return 'Rechazado';
      case CANCELADA:
        return 'Cancelada';
      default:
        return codigo;
    }
  }

  /// Obtener color hex del estado (para UI)
  static String getColor(String codigo) {
    switch (codigo) {
      case ENTREGADO:
        return '#28A745'; // Verde
      case EN_TRANSITO:
      case EN_CAMINO:
      case LLEGO:
        return '#0099FF'; // Azul
      case PREPARACION_CARGA:
      case EN_CARGA:
      case LISTO_PARA_ENTREGA:
        return '#FF9800'; // Naranja
      case PROGRAMADO:
      case ASIGNADA:
        return '#6C757D'; // Gris
      case NOVEDAD:
        return '#FFC107'; // Amarillo
      case RECHAZADO:
      case CANCELADA:
        return '#DC3545'; // Rojo
      default:
        return '#6C757D';
    }
  }

  /// Obtener icono del estado
  static String getIcono(String codigo) {
    switch (codigo) {
      case ENTREGADO:
        return 'check_circle';
      case EN_TRANSITO:
      case EN_CAMINO:
      case LLEGO:
        return 'local_shipping';
      case PREPARACION_CARGA:
      case EN_CARGA:
      case LISTO_PARA_ENTREGA:
        return 'inventory';
      case PROGRAMADO:
      case ASIGNADA:
        return 'schedule';
      case NOVEDAD:
        return 'warning';
      case RECHAZADO:
      case CANCELADA:
        return 'cancel';
      default:
        return 'info';
    }
  }

  /// ¿Es estado final?
  static bool esEstadoFinal(String codigo) {
    return ESTADOS_FINALES.contains(codigo);
  }

  /// ¿Es estado pendiente?
  static bool esEstadoPendiente(String codigo) {
    return ESTADOS_PENDIENTES.contains(codigo);
  }

  /// ¿Está en preparación?
  static bool enPreparacion(String codigo) {
    return ESTADOS_EN_PREPARACION.contains(codigo);
  }

  /// ¿Está en ruta?
  static bool enRuta(String codigo) {
    return ESTADOS_EN_RUTA.contains(codigo);
  }
}
