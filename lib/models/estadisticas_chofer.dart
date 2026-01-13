/// Modelo para estadísticas del chofer
///
/// Contiene métricas del desempeño del chofer sin necesidad de
/// cargar todas las entregas completas. Optimizado para dashboard.
/// ✅ ACTUALIZADO: Usa estados agrupados de tabla estados_logistica
class EstadisticasChofer {
  final int totalEntregas;
  final int entregasCompletadas;
  final int entregasPendientes;

  // ✅ NUEVOS: Estados principales agrupados (desde tabla estados_logistica)
  final int entregasEnPreparacion;      // PREPARACION_CARGA + EN_CARGA
  final int entregasListasEntrega;      // LISTO_PARA_ENTREGA
  final int entregasEnRuta;              // EN_TRANSITO + EN_CAMINO + LLEGO
  final int entregasEntregadas;          // ENTREGADO

  final double tasaExito;
  final double kmEstimados;
  final int tiempoPromedioMinutos;
  final ProximaEntrega? proximaEntrega;
  final DateTime timestamp;

  EstadisticasChofer({
    required this.totalEntregas,
    required this.entregasCompletadas,
    required this.entregasPendientes,
    required this.entregasEnPreparacion,
    required this.entregasListasEntrega,
    required this.entregasEnRuta,
    required this.entregasEntregadas,
    required this.tasaExito,
    required this.kmEstimados,
    required this.tiempoPromedioMinutos,
    this.proximaEntrega,
    required this.timestamp,
  });

  factory EstadisticasChofer.fromJson(Map<String, dynamic> json) {
    return EstadisticasChofer(
      totalEntregas: json['total_entregas'] ?? 0,
      entregasCompletadas: json['entregas_completadas'] ?? 0,
      entregasPendientes: json['entregas_pendientes'] ?? 0,
      // ✅ NUEVOS
      entregasEnPreparacion: json['entregas_en_preparacion'] ?? 0,
      entregasListasEntrega: json['entregas_listas_entrega'] ?? 0,
      entregasEnRuta: json['entregas_en_ruta'] ?? 0,
      entregasEntregadas: json['entregas_entregadas'] ?? 0,
      tasaExito: (json['tasa_exito'] ?? 0).toDouble(),
      kmEstimados: (json['km_estimados'] ?? 0).toDouble(),
      tiempoPromedioMinutos: json['tiempo_promedio_minutos'] ?? 0,
      proximaEntrega: json['proxima_entrega'] != null
          ? ProximaEntrega.fromJson(json['proxima_entrega'])
          : null,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_entregas': totalEntregas,
      'entregas_completadas': entregasCompletadas,
      'entregas_pendientes': entregasPendientes,
      'entregas_en_preparacion': entregasEnPreparacion,
      'entregas_listas_entrega': entregasListasEntrega,
      'entregas_en_ruta': entregasEnRuta,
      'entregas_entregadas': entregasEntregadas,
      'tasa_exito': tasaExito,
      'km_estimados': kmEstimados,
      'tiempo_promedio_minutos': tiempoPromedioMinutos,
      'proxima_entrega': proximaEntrega?.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Copia con cambios
  EstadisticasChofer copyWith({
    int? totalEntregas,
    int? entregasCompletadas,
    int? entregasPendientes,
    int? entregasEnPreparacion,
    int? entregasListasEntrega,
    int? entregasEnRuta,
    int? entregasEntregadas,
    double? tasaExito,
    double? kmEstimados,
    int? tiempoPromedioMinutos,
    ProximaEntrega? proximaEntrega,
    DateTime? timestamp,
  }) {
    return EstadisticasChofer(
      totalEntregas: totalEntregas ?? this.totalEntregas,
      entregasCompletadas: entregasCompletadas ?? this.entregasCompletadas,
      entregasPendientes: entregasPendientes ?? this.entregasPendientes,
      entregasEnPreparacion: entregasEnPreparacion ?? this.entregasEnPreparacion,
      entregasListasEntrega: entregasListasEntrega ?? this.entregasListasEntrega,
      entregasEnRuta: entregasEnRuta ?? this.entregasEnRuta,
      entregasEntregadas: entregasEntregadas ?? this.entregasEntregadas,
      tasaExito: tasaExito ?? this.tasaExito,
      kmEstimados: kmEstimados ?? this.kmEstimados,
      tiempoPromedioMinutos: tiempoPromedioMinutos ?? this.tiempoPromedioMinutos,
      proximaEntrega: proximaEntrega ?? this.proximaEntrega,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Progreso de entregas (0 a 100)
  int get progresoPorcentaje {
    if (totalEntregas == 0) return 0;
    return ((entregasCompletadas / totalEntregas) * 100).toInt();
  }

  /// ¿Tiene entregas pendientes?
  bool get tienePendientes => entregasPendientes > 0;

  /// ¿Tiene entregas en preparación?
  bool get tieneEnPreparacion => entregasEnPreparacion > 0;

  /// ¿Tiene entregas listas?
  bool get tieneListasEntrega => entregasListasEntrega > 0;

  /// ¿Tiene entregas en ruta?
  bool get tieneEnRuta => entregasEnRuta > 0;
}

/// Información de la próxima entrega
class ProximaEntrega {
  final int id;
  final String numeroEntrega;
  final String estado;
  final VehiculoInfo? vehiculo;

  ProximaEntrega({
    required this.id,
    required this.numeroEntrega,
    required this.estado,
    this.vehiculo,
  });

  factory ProximaEntrega.fromJson(Map<String, dynamic> json) {
    return ProximaEntrega(
      id: json['id'] ?? 0,
      numeroEntrega: json['numero_entrega'] ?? '',
      estado: json['estado'] ?? '',
      vehiculo: json['vehiculo'] != null
          ? VehiculoInfo.fromJson(json['vehiculo'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero_entrega': numeroEntrega,
      'estado': estado,
      'vehiculo': vehiculo?.toJson(),
    };
  }
}

/// Información del vehículo
class VehiculoInfo {
  final String placa;

  VehiculoInfo({
    required this.placa,
  });

  factory VehiculoInfo.fromJson(Map<String, dynamic> json) {
    return VehiculoInfo(
      placa: json['placa'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'placa': placa,
    };
  }
}
