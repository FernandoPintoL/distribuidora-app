import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget para mostrar el estado SLA de una entrega o venta
/// Muestra:
/// - Fecha comprometida de entrega
/// - Ventana de tiempo de entrega (hora inicio - hora fin)
/// - Indicador visual de si está dentro o fuera del SLA
/// - Tiempo restante/retraso
class SlaStatusWidget extends StatelessWidget {
  /// Fecha comprometida de entrega
  final DateTime? fechaEntregaComprometida;

  /// Hora inicio de la ventana de entrega (TimeOfDay)
  final TimeOfDay? ventanaEntregaIni;

  /// Hora fin de la ventana de entrega (TimeOfDay)
  final TimeOfDay? ventanaEntregaFin;

  /// Hora actual para calcular si está en tiempo o retrasado
  final DateTime? horaActual;

  /// Estado actual de la entrega (para contexto visual)
  final String? estado;

  /// Tamaño compacto o expandido
  final bool compact;

  const SlaStatusWidget({
    Key? key,
    this.fechaEntregaComprometida,
    this.ventanaEntregaIni,
    this.ventanaEntregaFin,
    this.horaActual,
    this.estado,
    this.compact = false,
  }) : super(key: key);

  /// Calcula si la entrega está en tiempo (within SLA)
  /// Retorna: 'ON_TIME', 'CRITICAL', 'DELAYED'
  String _calculateSlaStatus() {
    if (fechaEntregaComprometida == null) {
      return 'SIN_SLA'; // Sin información SLA
    }

    final now = horaActual ?? DateTime.now();
    final diff = fechaEntregaComprometida!.difference(now);

    // Si ya se entregó, consideramos si fue a tiempo
    if (estado == 'ENTREGADO' || estado == 'COMPLETADA') {
      return diff.isNegative ? 'DELAYED' : 'ON_TIME';
    }

    // Si faltan más de 4 horas, está ON TIME
    if (diff.inHours > 4) {
      return 'ON_TIME';
    }

    // Si faltan 1-4 horas, está CRÍTICO (en peligro)
    if (diff.inHours >= 1) {
      return 'CRITICAL';
    }

    // Si ya pasó la fecha o queda menos de 1 hora, está RETRASADO
    return 'DELAYED';
  }

  /// Retorna la leyenda legible del estado SLA
  String _getSlaLabel() {
    final status = _calculateSlaStatus();
    switch (status) {
      case 'ON_TIME':
        return 'En tiempo ✓';
      case 'CRITICAL':
        return 'Crítico ⚠️';
      case 'DELAYED':
        return 'Retrasado ❌';
      case 'SIN_SLA':
      default:
        return 'Sin SLA';
    }
  }

  /// Retorna el color basado en el estado SLA
  Color _getSlaColor() {
    final status = _calculateSlaStatus();
    switch (status) {
      case 'ON_TIME':
        return Colors.green;
      case 'CRITICAL':
        return Colors.amber;
      case 'DELAYED':
        return Colors.red;
      case 'SIN_SLA':
      default:
        return Colors.grey;
    }
  }

  /// Calcula el tiempo restante/retraso de manera legible
  String _getTimeRemaining() {
    if (fechaEntregaComprometida == null) {
      return 'N/A';
    }

    final now = horaActual ?? DateTime.now();
    final diff = fechaEntregaComprometida!.difference(now);

    if (diff.isNegative) {
      // Retrasado
      final absDiff = diff.abs();
      if (absDiff.inHours > 0) {
        final minutes = absDiff.inMinutes % 60;
        return '${absDiff.inHours}h ${minutes}m de retraso';
      } else {
        return '${absDiff.inMinutes}m de retraso';
      }
    } else {
      // Tiempo restante
      if (diff.inHours > 24) {
        final days = diff.inDays;
        final hours = (diff.inHours % 24);
        return '${days}d ${hours}h restantes';
      } else if (diff.inHours > 0) {
        final minutes = diff.inMinutes % 60;
        return '${diff.inHours}h ${minutes}m restantes';
      } else {
        return '${diff.inMinutes}m restantes';
      }
    }
  }

  /// Formatea la fecha de manera legible
  String _formatFecha(DateTime fecha) {
    final formatter = DateFormat('dd/MM/yyyy', 'es_ES');
    return formatter.format(fecha);
  }

  /// Formatea la hora de manera legible
  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact(context);
    }
    return _buildExpanded(context);
  }

  /// Versión compacta del widget (una línea)
  Widget _buildCompact(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getSlaColor().withOpacity(0.1),
        border: Border.all(color: _getSlaColor()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _calculateSlaStatus() == 'ON_TIME'
                ? Icons.check_circle
                : _calculateSlaStatus() == 'CRITICAL'
                    ? Icons.warning
                    : Icons.error,
            color: _getSlaColor(),
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getSlaLabel(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getSlaColor(),
                    fontSize: 12,
                  ),
                ),
                if (fechaEntregaComprometida != null)
                  Text(
                    _getTimeRemaining(),
                    style: TextStyle(
                      color: _getSlaColor(),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Versión expandida del widget (con más detalles)
  Widget _buildExpanded(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: _getSlaColor(), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con icono y estado
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getSlaColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _calculateSlaStatus() == 'ON_TIME'
                        ? Icons.check_circle
                        : _calculateSlaStatus() == 'CRITICAL'
                            ? Icons.warning
                            : Icons.error,
                    color: _getSlaColor(),
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado SLA',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        _getSlaLabel(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _getSlaColor(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Fecha comprometida
            if (fechaEntregaComprometida != null) ...[
              _buildInfoRow(
                icon: Icons.calendar_today,
                label: 'Fecha Comprometida',
                value: _formatFecha(fechaEntregaComprometida!),
              ),
              SizedBox(height: 12),
            ],

            // Ventana de tiempo
            if (ventanaEntregaIni != null && ventanaEntregaFin != null) ...[
              _buildInfoRow(
                icon: Icons.access_time,
                label: 'Ventana de Entrega',
                value:
                    '${_formatTime(ventanaEntregaIni!)} - ${_formatTime(ventanaEntregaFin!)}',
              ),
              SizedBox(height: 12),
            ],

            // Tiempo restante o retraso
            if (fechaEntregaComprometida != null) ...[
              _buildInfoRow(
                icon: Icons.schedule,
                label: 'Tiempo',
                value: _getTimeRemaining(),
                valueColor: _getSlaColor(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Widget auxiliar para mostrar filas de información
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.grey[800],
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
