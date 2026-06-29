import 'package:intl/intl.dart';
import '../models/prestamo_completo.dart';

/// Utilidades para trabajar con préstamos
class PrestamosUtils {
  /// Obtiene el tipo de préstamo como string legible
  static String getTipoPrestamo(PrestamoCompleto prestamo) {
    if (prestamo.esEvento) {
      return 'Evento';
    } else if (prestamo.proveedor != null) {
      return 'Proveedor';
    } else {
      return 'Cliente';
    }
  }

  /// Obtiene el nombre del receptor del préstamo
  static String getNombreReceptor(PrestamoCompleto prestamo) {
    if (prestamo.esEvento && prestamo.nombreEvento != null) {
      return prestamo.nombreEvento!;
    } else if (prestamo.proveedor != null) {
      return prestamo.proveedor!.nombre;
    } else if (prestamo.cliente != null) {
      return prestamo.cliente!.nombre;
    }
    return 'Desconocido';
  }

  /// Obtiene el contacto del receptor (teléfono o email)
  static String? getContactoReceptor(PrestamoCompleto prestamo) {
    if (prestamo.esEvento && prestamo.telefonoCliente1 != null) {
      return prestamo.telefonoCliente1;
    } else if (prestamo.proveedor != null) {
      return prestamo.proveedor!.telefono;
    } else if (prestamo.cliente != null) {
      return prestamo.cliente!.telefono;
    }
    return null;
  }

  /// Determina si el préstamo está vencido
  static bool estaVencido(PrestamoCompleto prestamo) {
    if (prestamo.estado != 'ACTIVO') return false;
    if (prestamo.fechaEsperadaDevolucion == null) return false;

    final fechaVencimiento = DateTime.tryParse(prestamo.fechaEsperadaDevolucion!);
    if (fechaVencimiento == null) return false;

    return fechaVencimiento.isBefore(DateTime.now());
  }

  /// Calcula los días restantes para devolución (negativo si está vencido)
  static int diasRestantes(PrestamoCompleto prestamo) {
    if (prestamo.fechaEsperadaDevolucion == null) return 0;

    final fechaVencimiento = DateTime.tryParse(prestamo.fechaEsperadaDevolucion!);
    if (fechaVencimiento == null) return 0;

    final diferencia = fechaVencimiento.difference(DateTime.now()).inDays;
    return diferencia;
  }

  /// Formatea la fecha de esperada devolución
  static String formatearFecha(String? fecha) {
    if (fecha == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(fecha);
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  /// Obtiene el estado con color (para UI)
  static Map<String, String> getEstadoInfo(PrestamoCompleto prestamo) {
    switch (prestamo.estado?.toUpperCase()) {
      case 'ACTIVO':
        if (estaVencido(prestamo)) {
          return {'estado': 'Vencido', 'color': 'FF6B6B'};
        }
        return {'estado': 'Activo', 'color': '51CF66'};
      case 'DEVUELTO':
        return {'estado': 'Devuelto', 'color': '4C6EF5'};
      case 'CANCELADO':
        return {'estado': 'Cancelado', 'color': '868E96'};
      default:
        return {'estado': prestamo.estado ?? 'Desconocido', 'color': '868E96'};
    }
  }

  /// Calcula el total de garantía
  static double calcularTotalGarantia(List<PrestamoCompleto> prestamos) {
    return prestamos.fold<double>(0, (sum, p) => sum + (p.montoGarantia ?? 0));
  }

  /// Cuenta préstamos activos
  static int contarActivos(List<PrestamoCompleto> prestamos) {
    return prestamos.where((p) => p.estado == 'ACTIVO').length;
  }

  /// Cuenta préstamos vencidos
  static int contarVencidos(List<PrestamoCompleto> prestamos) {
    return prestamos.where((p) => estaVencido(p)).length;
  }

  /// Cuenta préstamos devueltos
  static int contarDevueltos(List<PrestamoCompleto> prestamos) {
    return prestamos.where((p) => p.estado == 'DEVUELTO').length;
  }

  /// Obtiene la cantidad total de prestables en un préstamo
  static int cantidadTotalPrestables(PrestamoCompleto prestamo) {
    if (prestamo.detalles == null || prestamo.detalles!.isEmpty) return 0;
    return prestamo.detalles!.length;
  }

  /// Obtiene la cantidad total de unidades prestadas
  static int cantidadTotalUnidades(PrestamoCompleto prestamo) {
    if (prestamo.detalles == null) return 0;
    return prestamo.detalles!
        .fold<int>(0, (sum, d) => sum + d.cantidadPrestada);
  }

  /// Obtiene resumen de detalles como string (ej: "2 canastillas, 240 embases")
  static String getResumenDetalles(PrestamoCompleto prestamo) {
    if (prestamo.detalles == null || prestamo.detalles!.isEmpty) {
      return 'Sin detalles';
    }

    final detalles = prestamo.detalles!
        .map((d) =>
            '${d.cantidadPrestada} ${d.prestable?.nombre ?? "items"}')
        .join(', ');

    return detalles;
  }

  /// Determina si un préstamo tiene devoluciones pendientes
  static bool tieneDevoluciones(PrestamoCompleto prestamo) {
    return prestamo.devoluciones != null && prestamo.devoluciones!.isNotEmpty;
  }

  /// Obtiene el porcentaje de items devueltos
  static double getPorcentajeDevuelto(PrestamoCompleto prestamo) {
    if (prestamo.detalles == null || prestamo.detalles!.isEmpty) return 0;

    final totalPrestado =
        prestamo.detalles!.fold<int>(0, (sum, d) => sum + d.cantidadPrestada);

    if (totalPrestado == 0) return 0;

    final totalDevuelto = prestamo.detalles!.fold<int>(
      0,
      (sum, d) {
        final devuelto =
            d.devolucionDetalles?.fold<int>(0, (s, dd) => s + dd.cantidadDevuelta) ??
                0;
        return sum + devuelto;
      },
    );

    return (totalDevuelto / totalPrestado) * 100;
  }
}
