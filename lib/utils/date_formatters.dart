/// Utilidades para formateo de fechas en español
class DateFormatters {
  /// Meses en español abreviados
  static const List<String> months = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  /// Formatear fecha en formato compacto: "15 Ene, 14:30"
  static String formatCompactDate(DateTime date) {
    final month = months[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} $month, $hour:$minute';
  }
}
