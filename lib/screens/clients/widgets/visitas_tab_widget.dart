import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/app_text_styles.dart';
import '../../../models/models.dart';

class VisitasTabWidget extends StatelessWidget {
  final List<VisitaPreventistaCliente>? visitas;
  final Client? client;
  final VoidCallback? onMarkVisita;
  final Future<void> Function()? onRefresh;

  const VisitasTabWidget({
    super.key,
    required this.visitas,
    required this.client,
    this.onMarkVisita,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (visitas == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Cargando visitas...',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    final tieneVentanasEntrega = client?.ventanasEntrega?.isNotEmpty ?? false;

    if (!tieneVentanasEntrega && visitas!.isEmpty) {
      return _buildEmptyVisitasState(context, tieneVentanasEntrega);
    }

    return RefreshIndicator(
      onRefresh: onRefresh ?? (() => Future.value()),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (tieneVentanasEntrega)
            _PlanSemanalWidget(
              client: client,
              visitas: visitas,
              onMarkVisita: onMarkVisita,
            ),
          if (!tieneVentanasEntrega && visitas!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildInfoBox(context),
            ),
          ],
          if (tieneVentanasEntrega && visitas!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              height: 1,
              color: Theme.of(context).dividerColor,
              margin: const EdgeInsets.symmetric(vertical: 8),
            ),
            const SizedBox(height: 16),
          ],
          if (visitas!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildHistorialHeader(context),
            ),
            ..._buildVisitaCards(context),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No hay días de visita programados para este cliente',
              style: TextStyle(
                fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorialHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.history, color: colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          'Historial Completo de Visitas',
          style: TextStyle(
            fontSize: AppTextStyles.bodyLarge(context).fontSize!,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
          ),
          child: Text(
            '${visitas!.length}',
            style: TextStyle(
              fontSize: AppTextStyles.bodySmall(context).fontSize!,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildVisitaCards(BuildContext context) {
    return visitas!.map((visita) => _VisitaCardWidget(visita: visita)).toList();
  }

  Widget _buildEmptyVisitasState(
    BuildContext context,
    bool tieneVentanasEntrega,
  ) {
    final diasProgramados =
        client?.ventanasEntrega?.where((v) => v.activo).length ?? 0;

    return RefreshIndicator(
      onRefresh: onRefresh ?? (() => Future.value()),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 80,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 24),
              Text(
                'No hay visitas registradas',
                style: TextStyle(
                  fontSize: AppTextStyles.headlineSmall(context).fontSize!,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              if (tieneVentanasEntrega)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        'Este cliente tiene $diasProgramados día(s) de visita programado(s), pero aún no hay registros de visitas.',
                        style: TextStyle(
                          fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'El preventista aún no ha registrado visitas para este cliente en los días programados.',
                                style: TextStyle(
                                  fontSize: AppTextStyles.bodySmall(
                                    context,
                                  ).fontSize!,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'No hay visitas registradas y no hay días de visita programados para este cliente.',
                    style: TextStyle(
                      fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanSemanalWidget extends StatelessWidget {
  final Client? client;
  final List<VisitaPreventistaCliente>? visitas;
  final VoidCallback? onMarkVisita;

  const _PlanSemanalWidget({
    required this.client,
    required this.visitas,
    this.onMarkVisita,
  });

  @override
  Widget build(BuildContext context) {
    if (client?.ventanasEntrega?.isEmpty ?? true) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final days = [
      'Domingo',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
    ];

    final ahora = DateTime.now();
    final inicioSemana = ahora.subtract(Duration(days: ahora.weekday % 7));
    final finSemana = inicioSemana.add(const Duration(days: 6));

    final ventanasActivas = client!.ventanasEntrega!
        .where((v) => v.activo)
        .toList();

    final Map<int, VisitaPreventistaCliente?> visitasPorDia = {};

    for (final ventana in ventanasActivas) {
      final visita = visitas!.where((visita) {
        final visitDate = visita.fechaHoraVisita;
        final visitDayIndex = visitDate.weekday % 7;

        final esEseDia = visitDayIndex == ventana.diaSemana;
        final esEsaSemana =
            visitDate.isAfter(inicioSemana) &&
            visitDate.isBefore(finSemana.add(const Duration(days: 1)));
        final esExitoso =
            visita.estadoVisita == EstadoVisitaPreventista.EXITOSA;

        return esEseDia && esEsaSemana && esExitoso;
      }).firstOrNull;

      visitasPorDia[ventana.diaSemana] = visita;
    }

    int visitasCumplidas = visitasPorDia.values.where((v) => v != null).length;
    int visitasProgramadas = ventanasActivas.length;
    final porcentajeCumplimiento = visitasProgramadas > 0
        ? ((visitasCumplidas / visitasProgramadas) * 100).toInt()
        : 0;

    final cumplido = porcentajeCumplimiento >= 100;
    final alerta = porcentajeCumplimiento < 50 && visitasProgramadas > 0;
    final color = cumplido
        ? Colors.green
        : alerta
        ? Colors.red
        : Colors.orange;

    final ventanasOrdenadas = [...ventanasActivas]
      ..sort((a, b) => a.diaSemana.compareTo(b.diaSemana));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.event_repeat,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan de Visitas - Esta Semana',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Cumplimiento: $visitasCumplidas de $visitasProgramadas días',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.3 : 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$porcentajeCumplimiento%',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: visitasProgramadas > 0
                ? visitasCumplidas / visitasProgramadas
                : 0,
            minHeight: 10,
            backgroundColor: isDark
                ? Colors.grey.shade700
                : Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onMarkVisita,
            icon: const Icon(Icons.add_location),
            label: const Text('Marcar Nueva Visita'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 20),
        ...ventanasOrdenadas.map((ventana) {
          final visita = visitasPorDia[ventana.diaSemana];
          final visitado = visita != null;
          final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

          final bgColor = isDark
              ? (visitado
                    ? Colors.green.withOpacity(0.15)
                    : Colors.orange.withOpacity(0.15))
              : (visitado ? Colors.green.shade50 : Colors.orange.shade50);

          final borderColor = isDark
              ? (visitado
                    ? Colors.green.withOpacity(0.4)
                    : Colors.orange.withOpacity(0.4))
              : (visitado ? Colors.green.shade200 : Colors.orange.shade200);

          final statusBgColor = isDark
              ? (visitado
                    ? Colors.green.withOpacity(0.25)
                    : Colors.orange.withOpacity(0.25))
              : (visitado ? Colors.green.shade100 : Colors.orange.shade100);

          final statusTextColor = isDark
              ? (visitado ? Colors.green.shade300 : Colors.orange.shade300)
              : (visitado ? Colors.green.shade700 : Colors.orange.shade700);

          final detailBgColor = isDark
              ? colorScheme.surface
              : Colors.white.withOpacity(0.7);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: visitado ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          visitado ? Icons.check_circle : Icons.schedule,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                days[ventana.diaSemana],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  visitado ? 'Visitado' : 'Pendiente',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: statusTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${ventana.horaInicio} - ${ventana.horaFin}',
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (visitado && visita != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: detailBgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: visitado
                                  ? Colors.green
                                  : colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Visitado: ${dateFormat.format(visita.fechaHoraVisita)}',
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (visita.tipoVisita != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                _getTipoVisitaIcon(visita.tipoVisita),
                                size: 14,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Tipo: ${visita.tipoVisita.label}',
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.7,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  IconData _getTipoVisitaIcon(TipoVisitaPreventista tipo) {
    switch (tipo) {
      case TipoVisitaPreventista.COBRO:
        return Icons.payment;
      case TipoVisitaPreventista.TOMA_PEDIDO:
        return Icons.shopping_cart;
      case TipoVisitaPreventista.SUPERVISION:
        return Icons.visibility;
      case TipoVisitaPreventista.OTRO:
        return Icons.more_horiz;
    }
  }
}

class _VisitaCardWidget extends StatelessWidget {
  final VisitaPreventistaCliente visita;

  const _VisitaCardWidget({required this.visita});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? colorScheme.surface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: colorScheme.onPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        dateFormat.format(visita.fechaHoraVisita),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  _buildEstadoBadge(context, visita.estadoVisita),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    _getTipoVisitaIcon(visita.tipoVisita),
                    size: 18,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tipo: ${visita.tipoVisita.label}',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    visita.dentroVentanaHoraria
                        ? Icons.check_circle
                        : Icons.warning,
                    size: 18,
                    color: visita.dentroVentanaHoraria
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    visita.dentroVentanaHoraria
                        ? 'Dentro de ventana horaria'
                        : 'Fuera de ventana horaria',
                    style: TextStyle(
                      color: visita.dentroVentanaHoraria
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (visita.observaciones != null &&
                  visita.observaciones!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes, size: 16, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          visita.observaciones!,
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Divider(height: 24, color: Theme.of(context).dividerColor),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () =>
                        _abrirEnMaps(visita.latitud, visita.longitud),
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('Ver ubicación'),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                    ),
                  ),
                  if (visita.fotoLocal != null)
                    TextButton.icon(
                      onPressed: () =>
                          _mostrarFotoVisita(context, visita.fotoLocal!),
                      icon: const Icon(Icons.photo, size: 18),
                      label: const Text('Ver foto'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(
    BuildContext context,
    EstadoVisitaPreventista estado,
  ) {
    final color = estado == EstadoVisitaPreventista.EXITOSA
        ? Colors.green
        : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            estado == EstadoVisitaPreventista.EXITOSA
                ? Icons.check_circle
                : Icons.cancel,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            estado.label,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  IconData _getTipoVisitaIcon(TipoVisitaPreventista tipo) {
    switch (tipo) {
      case TipoVisitaPreventista.COBRO:
        return Icons.payment;
      case TipoVisitaPreventista.TOMA_PEDIDO:
        return Icons.shopping_cart;
      case TipoVisitaPreventista.SUPERVISION:
        return Icons.visibility;
      case TipoVisitaPreventista.OTRO:
        return Icons.more_horiz;
    }
  }

  Future<void> _abrirEnMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _mostrarFotoVisita(BuildContext context, String fotoUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Image.network(
                  fotoUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.black,
                      child: const Center(
                        child: Icon(Icons.error, color: Colors.white, size: 64),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
