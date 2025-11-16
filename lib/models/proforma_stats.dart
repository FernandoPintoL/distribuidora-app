/// Modelo para estadísticas de proformas
///
/// Contiene contadores y métricas agregadas sin necesidad
/// de cargar todas las proformas completas
class ProformaStats {
  final int total;
  final ProformaEstadoStats porEstado;
  final ProformaMontosStats montosPorEstado;
  final ProformaCanalStats porCanal;
  final ProformaAlertasStats alertas;
  final double montoTotal;

  ProformaStats({
    required this.total,
    required this.porEstado,
    required this.montosPorEstado,
    required this.porCanal,
    required this.alertas,
    required this.montoTotal,
  });

  factory ProformaStats.fromJson(Map<String, dynamic> json) {
    return ProformaStats(
      total: json['total'] ?? 0,
      porEstado: ProformaEstadoStats.fromJson(json['por_estado'] ?? {}),
      montosPorEstado: ProformaMontosStats.fromJson(json['montos_por_estado'] ?? {}),
      porCanal: ProformaCanalStats.fromJson(json['por_canal'] ?? {}),
      alertas: ProformaAlertasStats.fromJson(json['alertas'] ?? {}),
      montoTotal: (json['monto_total'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'por_estado': porEstado.toJson(),
      'montos_por_estado': montosPorEstado.toJson(),
      'por_canal': porCanal.toJson(),
      'alertas': alertas.toJson(),
      'monto_total': montoTotal,
    };
  }
}

/// Contadores por estado
class ProformaEstadoStats {
  final int pendiente;
  final int aprobada;
  final int rechazada;
  final int convertida;
  final int vencida;

  ProformaEstadoStats({
    required this.pendiente,
    required this.aprobada,
    required this.rechazada,
    required this.convertida,
    required this.vencida,
  });

  factory ProformaEstadoStats.fromJson(Map<String, dynamic> json) {
    return ProformaEstadoStats(
      pendiente: json['pendiente'] ?? 0,
      aprobada: json['aprobada'] ?? 0,
      rechazada: json['rechazada'] ?? 0,
      convertida: json['convertida'] ?? 0,
      vencida: json['vencida'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pendiente': pendiente,
      'aprobada': aprobada,
      'rechazada': rechazada,
      'convertida': convertida,
      'vencida': vencida,
    };
  }

  /// Total de todas las proformas activas (pendiente + aprobada)
  int get activas => pendiente + aprobada;

  /// Total de todas las proformas finalizadas (rechazada + convertida + vencida)
  int get finalizadas => rechazada + convertida + vencida;
}

/// Montos por estado
class ProformaMontosStats {
  final double pendiente;
  final double aprobada;
  final double rechazada;
  final double convertida;
  final double vencida;

  ProformaMontosStats({
    required this.pendiente,
    required this.aprobada,
    required this.rechazada,
    required this.convertida,
    required this.vencida,
  });

  factory ProformaMontosStats.fromJson(Map<String, dynamic> json) {
    return ProformaMontosStats(
      pendiente: (json['pendiente'] ?? 0).toDouble(),
      aprobada: (json['aprobada'] ?? 0).toDouble(),
      rechazada: (json['rechazada'] ?? 0).toDouble(),
      convertida: (json['convertida'] ?? 0).toDouble(),
      vencida: (json['vencida'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pendiente': pendiente,
      'aprobada': aprobada,
      'rechazada': rechazada,
      'convertida': convertida,
      'vencida': vencida,
    };
  }

  /// Total de montos en estados activos
  double get activos => pendiente + aprobada;

  /// Total de montos finalizados
  double get finalizados => rechazada + convertida + vencida;
}

/// Contadores por canal
class ProformaCanalStats {
  final int appExterna;
  final int web;
  final int presencial;

  ProformaCanalStats({
    required this.appExterna,
    required this.web,
    required this.presencial,
  });

  factory ProformaCanalStats.fromJson(Map<String, dynamic> json) {
    return ProformaCanalStats(
      appExterna: json['app_externa'] ?? 0,
      web: json['web'] ?? 0,
      presencial: json['presencial'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'app_externa': appExterna,
      'web': web,
      'presencial': presencial,
    };
  }
}

/// Alertas y notificaciones
class ProformaAlertasStats {
  final int vencidas;
  final int porVencer;

  ProformaAlertasStats({
    required this.vencidas,
    required this.porVencer,
  });

  factory ProformaAlertasStats.fromJson(Map<String, dynamic> json) {
    return ProformaAlertasStats(
      vencidas: json['vencidas'] ?? 0,
      porVencer: json['por_vencer'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vencidas': vencidas,
      'por_vencer': porVencer,
    };
  }

  /// Tiene alertas activas
  bool get tieneAlertas => vencidas > 0 || porVencer > 0;

  /// Total de alertas
  int get total => vencidas + porVencer;
}
