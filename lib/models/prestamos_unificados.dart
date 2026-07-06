import 'prestamo_cliente.dart';

/// Respuesta unificada para los 3 tipos de préstamos (cliente, evento, proveedor)
class PrestamosUnificadosResponse {
  final bool success;
  final PrestamosUnificadosData prestamosCliente;
  final PrestamosUnificadosData prestamosEvento;
  final PrestamosUnificadosData prestamosProveedor;

  PrestamosUnificadosResponse({
    required this.success,
    required this.prestamosCliente,
    required this.prestamosEvento,
    required this.prestamosProveedor,
  });

  /// Total de todos los préstamos
  int get totalPrestamos =>
      prestamosCliente.total + prestamosEvento.total + prestamosProveedor.total;

  /// Préstamos activos
  int get prestamosActivos =>
      prestamosCliente.prestamosActivos +
      prestamosEvento.prestamosActivos +
      prestamosProveedor.prestamosActivos;

  /// Préstamos vencidos (esperado de devolución < hoy)
  int get prestamosVencidos =>
      prestamosCliente.prestamosVencidos +
      prestamosEvento.prestamosVencidos +
      prestamosProveedor.prestamosVencidos;

  /// Préstamos devueltos
  int get prestamosDevueltos =>
      prestamosCliente.prestamosDevueltos +
      prestamosEvento.prestamosDevueltos +
      prestamosProveedor.prestamosDevueltos;
}

/// Estructura de datos paginada para préstamos
class PrestamosUnificadosData {
  final int currentPage;
  final int? from;
  final int lastPage;
  final int perPage;
  final int? to;
  final int total;
  final String path;
  final String? firstPageUrl;
  final String? lastPageUrl;
  final String? nextPageUrl;
  final String? prevPageUrl;
  final List<PrestamoCliente> prestamos;

  PrestamosUnificadosData({
    required this.currentPage,
    this.from,
    required this.lastPage,
    required this.perPage,
    this.to,
    required this.total,
    required this.path,
    this.firstPageUrl,
    this.lastPageUrl,
    this.nextPageUrl,
    this.prevPageUrl,
    required this.prestamos,
  });

  /// Cantidad de préstamos activos
  int get prestamosActivos =>
      prestamos.where((p) => p.estado == 'ACTIVO').length;

  /// Cantidad de préstamos vencidos
  int get prestamosVencidos {
    final hoy = DateTime.now();
    return prestamos.where((p) {
      if (p.estado != 'ACTIVO') return false;
      if (p.fechaEsperadaDevolucion == null) return false;
      final fechaVencimiento = DateTime.tryParse(p.fechaEsperadaDevolucion!);
      return fechaVencimiento != null && fechaVencimiento.isBefore(hoy);
    }).length;
  }

  /// Cantidad de préstamos devueltos
  int get prestamosDevueltos =>
      prestamos.where((p) => p.estado == 'DEVUELTO').length;

  factory PrestamosUnificadosData.fromJson(Map<String, dynamic> json) {
    return PrestamosUnificadosData(
      currentPage: json['current_page'] as int? ?? 1,
      from: json['from'] as int?,
      lastPage: json['last_page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 10,
      to: json['to'] as int?,
      total: json['total'] as int? ?? 0,
      path: json['path'] as String? ?? '',
      firstPageUrl: json['first_page_url'] as String?,
      lastPageUrl: json['last_page_url'] as String?,
      nextPageUrl: json['next_page_url'] as String?,
      prevPageUrl: json['prev_page_url'] as String?,
      prestamos:
          (json['data'] as List?)
              ?.map((p) => PrestamoCliente.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Crear instancia vacía (para cuando no hay datos)
  factory PrestamosUnificadosData.empty() {
    return PrestamosUnificadosData(
      currentPage: 1,
      lastPage: 1,
      perPage: 10,
      total: 0,
      path: '',
      prestamos: [],
    );
  }
}

/// Estadísticas generales de préstamos
class EstadisticasPrestamos {
  final int totalPrestamos;
  final int prestamosActivos;
  final int prestamosVencidos;
  final int prestamosDevueltos;
  final double montoTotalGarantia;
  final int cantidadPrestablesActivos;

  EstadisticasPrestamos({
    required this.totalPrestamos,
    required this.prestamosActivos,
    required this.prestamosVencidos,
    required this.prestamosDevueltos,
    required this.montoTotalGarantia,
    required this.cantidadPrestablesActivos,
  });

  /// Porcentaje de préstamos activos
  double get porcentajeActivos {
    if (totalPrestamos == 0) return 0;
    return (prestamosActivos / totalPrestamos) * 100;
  }

  /// Porcentaje de préstamos vencidos
  double get porcentajeVencidos {
    if (totalPrestamos == 0) return 0;
    return (prestamosVencidos / totalPrestamos) * 100;
  }

  /// Porcentaje de préstamos devueltos
  double get porcentajeDevueltos {
    if (totalPrestamos == 0) return 0;
    return (prestamosDevueltos / totalPrestamos) * 100;
  }

  factory EstadisticasPrestamos.fromPrestamos(
    PrestamosUnificadosData clienteData,
    PrestamosUnificadosData eventoData,
    PrestamosUnificadosData proveedorData,
  ) {
    final totalPrestamos =
        clienteData.total + eventoData.total + proveedorData.total;
    final prestamosActivos =
        clienteData.prestamosActivos +
        eventoData.prestamosActivos +
        proveedorData.prestamosActivos;
    final prestamosVencidos =
        clienteData.prestamosVencidos +
        eventoData.prestamosVencidos +
        proveedorData.prestamosVencidos;
    final prestamosDevueltos =
        clienteData.prestamosDevueltos +
        eventoData.prestamosDevueltos +
        proveedorData.prestamosDevueltos;

    final montoTotalGarantia = [clienteData, eventoData, proveedorData]
        .expand((data) => data.prestamos)
        .fold<double>(0, (sum, p) => sum + (p.montoGarantia ?? 0));

    return EstadisticasPrestamos(
      totalPrestamos: totalPrestamos,
      prestamosActivos: prestamosActivos,
      prestamosVencidos: prestamosVencidos,
      prestamosDevueltos: prestamosDevueltos,
      montoTotalGarantia: montoTotalGarantia,
      cantidadPrestablesActivos: [
        clienteData,
        eventoData,
        proveedorData,
      ].expand((data) => data.prestamos).expand((p) => p.detalles ?? []).length,
    );
  }
}
