import 'package:flutter/material.dart';

/// Servicio de utilidades para manejo de fechas, horas y turnos
/// Contiene funciones puras sin efectos secundarios
class DateTimeUtilService {
  static const String TURNO_MORNING = 'MORNING';
  static const String TURNO_AFTERNOON = 'AFTERNOON';

  /// Obtener fechas disponibles (Hoy, Mañana, Lunes)
  static Map<String, DateTime> obtenerFechasDisponibles() {
    final DateTime now = DateTime.now();
    final DateTime hoy = DateTime(now.year, now.month, now.day);
    final DateTime manana = hoy.add(const Duration(days: 1));

    final Map<String, DateTime> fechas = {'Hoy': hoy};

    if (manana.weekday < 7) {
      fechas['Mañana'] = manana;
    } else if (manana.weekday == 7) {
      fechas['Lunes'] = hoy.add(const Duration(days: 2));
    }

    return fechas;
  }

  /// Verificar si la fecha es estándar (está en la lista de fechas disponibles)
  static bool esFechaEstandar(DateTime fecha) {
    final fechasDisponibles = obtenerFechasDisponibles();
    return fechasDisponibles.values.any(
      (f) =>
          f.year == fecha.year && f.month == fecha.month && f.day == fecha.day,
    );
  }

  /// Obtener rango de horas según turno
  /// - MORNING: 8:00-12:00
  /// - AFTERNOON: 14:00-18:00
  static List<int> obtenerHorasDisponibles(String turno) {
    if (turno == TURNO_MORNING) {
      return [8, 9, 10, 11, 12];
    } else {
      return [14, 15, 16, 17, 18];
    }
  }

  /// Verificar qué turnos están disponibles según la fecha y hora actual
  /// Si es hoy: verifica si el turno ya pasó
  /// Si es otro día: ambos turnos disponibles
  static Map<String, bool> obtenerTurnosDisponibles(DateTime? fechaProgramada) {
    final ahora = DateTime.now();
    final esHoy = fechaProgramada?.year == ahora.year &&
        fechaProgramada?.month == ahora.month &&
        fechaProgramada?.day == ahora.day;

    // Si NO es hoy, ambos turnos están disponibles
    if (!esHoy) {
      return {TURNO_MORNING: true, TURNO_AFTERNOON: true};
    }

    // Si ES hoy, verificar cuales turnos aun estan disponibles
    // Turno MORNING: 8:00-12:00 -> no disponible si ya son las 12:00 o mas
    final morningDisponible = ahora.hour < 12;

    // Turno AFTERNOON: 14:00-18:00 -> no disponible si ya son las 18:00 o mas
    final afternoonDisponible = ahora.hour < 18;

    return {
      TURNO_MORNING: morningDisponible,
      TURNO_AFTERNOON: afternoonDisponible,
    };
  }

  /// Formatear fecha a formato legible
  /// Ejemplo: "Martes, 10 de Junio de 2026"
  static String formatearFecha(DateTime fecha) {
    final meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    final dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];

    final diaSemana = dias[fecha.weekday - 1];
    final dia = fecha.day;
    final mes = meses[fecha.month - 1];
    final anio = fecha.year;

    return '$diaSemana, $dia de $mes de $anio';
  }
}
