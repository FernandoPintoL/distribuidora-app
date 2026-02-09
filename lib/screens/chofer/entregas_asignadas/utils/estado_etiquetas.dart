class EstadoEtiquetas {
  static const Map<String, String> etiquetas = {
    'PROGRAMADO': 'Programado',
    'ASIGNADA': 'Asignada',
    'PREPARACION_CARGA': 'En Prep.',
    'EN_CARGA': 'En Carga',
    'LISTO_PARA_ENTREGA': 'Listo',
    'EN_CAMINO': 'En Camino',
    'EN_TRANSITO': 'En Tránsito',
    'LLEGO': 'Llegó',
    'ENTREGADO': 'Entregado',
    'NOVEDAD': 'Novedad',
    'RECHAZADO': 'Rechazado',
    'CANCELADA': 'Cancelada',
  };

  static String getEtiqueta(String estado) {
    return etiquetas[estado] ?? estado;
  }
}
