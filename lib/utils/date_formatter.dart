/// Utilidades para formatear fechas
class DateFormatter {
  const DateFormatter._();

  /// Formatea una fecha string en formato dd/mm/yyyy
  static String format(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  /// Verifica si una fecha vence pronto (dentro de 30 días)
  static bool isExpiringSoon(String? dateStr) {
    if (dateStr == null) return false;
    try {
      final date = DateTime.parse(dateStr);
      final daysUntilExpiry = date.difference(DateTime.now()).inDays;
      return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
    } catch (_) {
      return false;
    }
  }
}
