/// Estadísticas del preventista desde el login
class PreventistStats {
  final int totalClientesBd;
  final int totalClientesAsignados;
  final int clientesSinAsignar;
  final int clientesActivos;
  final int clientesInactivos;
  final double porcentajeActivos;
  final double porcentajeInactivos;
  final int cantidadProductosVendidos;
  final int sumatiorProductosVendidos;
  final int cantidadTotalItemsVendidos;
  final double precioPromedioVendido;
  final ProformasHoy proformasCredasHoy;
  final ProformasHoy proformasEntregaSolicitadaHoy;
  final int ventasAprobadas;
  final int ventasAnuladas;
  final int totalVentas;

  PreventistStats({
    required this.totalClientesBd,
    required this.totalClientesAsignados,
    required this.clientesSinAsignar,
    required this.clientesActivos,
    required this.clientesInactivos,
    required this.porcentajeActivos,
    required this.porcentajeInactivos,
    required this.cantidadProductosVendidos,
    required this.sumatiorProductosVendidos,
    required this.cantidadTotalItemsVendidos,
    required this.precioPromedioVendido,
    required this.proformasCredasHoy,
    required this.proformasEntregaSolicitadaHoy,
    required this.ventasAprobadas,
    required this.ventasAnuladas,
    required this.totalVentas,
  });

  factory PreventistStats.fromJson(Map<String, dynamic> json) {
    return PreventistStats(
      totalClientesBd: json['total_clientes_bd'] ?? 0,
      totalClientesAsignados: json['total_clientes_asignados'] ?? 0,
      clientesSinAsignar: json['clientes_sin_asignar'] ?? 0,
      clientesActivos: json['clientes_activos'] ?? 0,
      clientesInactivos: json['clientes_inactivos'] ?? 0,
      porcentajeActivos: (json['porcentaje_activos'] ?? 0).toDouble(),
      porcentajeInactivos: (json['porcentaje_inactivos'] ?? 0).toDouble(),
      cantidadProductosVendidos: json['cantidad_productos_vendidos'] ?? 0,
      sumatiorProductosVendidos: json['sumatoria_productos_vendidos'] ?? 0,
      cantidadTotalItemsVendidos: json['cantidad_total_items_vendidos'] ?? 0,
      precioPromedioVendido: (json['precio_promedio_vendido'] ?? 0).toDouble(),
      proformasCredasHoy: ProformasHoy.fromJson(
        json['proformas_creadas_hoy'] ?? {},
      ),
      proformasEntregaSolicitadaHoy: ProformasHoy.fromJson(
        json['proformas_entrega_solicitada_hoy'] ?? {},
      ),
      ventasAprobadas: json['ventas_aprobadas'] ?? 0,
      ventasAnuladas: json['ventas_anuladas'] ?? 0,
      totalVentas: json['total_ventas'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_clientes_bd': totalClientesBd,
      'total_clientes_asignados': totalClientesAsignados,
      'clientes_sin_asignar': clientesSinAsignar,
      'clientes_activos': clientesActivos,
      'clientes_inactivos': clientesInactivos,
      'porcentaje_activos': porcentajeActivos,
      'porcentaje_inactivos': porcentajeInactivos,
      'cantidad_productos_vendidos': cantidadProductosVendidos,
      'sumatoria_productos_vendidos': sumatiorProductosVendidos,
      'cantidad_total_items_vendidos': cantidadTotalItemsVendidos,
      'precio_promedio_vendido': precioPromedioVendido,
      'proformas_creadas_hoy': proformasCredasHoy.toJson(),
      'proformas_entrega_solicitada_hoy': proformasEntregaSolicitadaHoy.toJson(),
      'ventas_aprobadas': ventasAprobadas,
      'ventas_anuladas': ventasAnuladas,
      'total_ventas': totalVentas,
    };
  }
}

class ProformasHoy {
  final int pendientes;
  final int convertidas;
  final int rechazadas;
  final int total;

  ProformasHoy({
    required this.pendientes,
    required this.convertidas,
    required this.rechazadas,
    required this.total,
  });

  factory ProformasHoy.fromJson(Map<String, dynamic> json) {
    return ProformasHoy(
      pendientes: json['pendientes'] ?? 0,
      convertidas: json['convertidas'] ?? 0,
      rechazadas: json['rechazadas'] ?? 0,
      total: json['total'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pendientes': pendientes,
      'convertidas': convertidas,
      'rechazadas': rechazadas,
      'total': total,
    };
  }
}
