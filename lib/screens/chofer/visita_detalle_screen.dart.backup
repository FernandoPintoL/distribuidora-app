import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';

class VisitaDetalleScreen extends StatelessWidget {
  final VisitaPreventistaCliente visita;

  const VisitaDetalleScreen({
    super.key,
    required this.visita,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Visita'),
        backgroundColor: colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con cliente y estado
            _buildHeader(colorScheme),
            const SizedBox(height: 24),

            // Información básica
            _buildInfoSection(
              'Información Básica',
              [
                {
                  'label': 'Cliente',
                  'value': visita.cliente?.nombre ?? 'N/A',
                  'icon': Icons.business,
                },
                {
                  'label': 'Fecha y Hora',
                  'value': dateFormat.format(visita.fechaHoraVisita),
                  'icon': Icons.calendar_today,
                },
                {
                  'label': 'Tipo de Visita',
                  'value': visita.tipoVisita.label,
                  'icon': Icons.local_offer,
                },
                {
                  'label': 'Estado',
                  'value': visita.estadoVisita.label,
                  'icon': Icons.check_circle,
                },
              ],
            ),
            const SizedBox(height: 24),

            // Ubicación GPS
            _buildLocationSection(colorScheme),
            const SizedBox(height: 24),

            // Estado de No Atención (si aplica)
            if (visita.estadoVisita == EstadoVisitaPreventista.NO_ATENDIDO)
              _buildNoAtencionSection(),
            const SizedBox(height: 24),

            // Validación de Horario
            _buildHorarioSection(),
            const SizedBox(height: 24),

            // Observaciones (si existen)
            if (visita.observaciones != null && visita.observaciones!.isNotEmpty)
              _buildObservacionesSection(),
            const SizedBox(height: 24),

            // Foto (si existe)
            if (visita.fotoLocal != null)
              _buildFotoSection(),
            const SizedBox(height: 24),

            // Información de timestamps
            _buildTimestampsSection(dateFormat),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visita.cliente?.nombre ?? 'Cliente',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (visita.cliente?.codigoCliente != null)
                        Text(
                          'Código: ${visita.cliente!.codigoCliente}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                    ],
                  ),
                ),
                _buildEstadoBadgeGrande(visita.estadoVisita),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoBadgeGrande(EstadoVisitaPreventista estado) {
    final color = estado == EstadoVisitaPreventista.EXITOSA
        ? Colors.green
        : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        estado.label,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: List.generate(
              items.length,
              (index) {
                final item = items[index];
                final isLast = index == items.length - 1;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            item['icon'],
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['label'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['value'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(height: 1, color: Colors.grey[300]),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ubicación GPS',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${visita.latitud.toStringAsFixed(6)}, ${visita.longitud.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.map),
                  label: const Text('Ver en Mapa'),
                  onPressed: () {
                    // TODO: Implementar abrir en Google Maps
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoAtencionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Motivo de No Atención',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            border: Border.all(color: Colors.red),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  visita.motivoNoAtencion?.label ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHorarioSection() {
    final color = visita.dentroVentanaHoraria ? Colors.green : Colors.orange;
    final icon = visita.dentroVentanaHoraria
        ? Icons.check_circle
        : Icons.warning_rounded;
    final label = visita.dentroVentanaHoraria
        ? 'Dentro de horario programado'
        : 'Fuera de horario programado';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Validación de Horario',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildObservacionesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Observaciones',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              visita.observaciones!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFotoSection() {
    if (visita.fotoLocal == null || visita.fotoLocal!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto del Local',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            visita.fotoLocal ?? '',
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.image_not_supported),
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimestampsSection(DateFormat dateFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información de Sistema',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.grey.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (visita.createdAt != null)
                  Text(
                    'Registrado: ${dateFormat.format(visita.createdAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                if (visita.updatedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Actualizado: ${dateFormat.format(visita.updatedAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
