import 'package:flutter/material.dart';
import '../../../models/orden_del_dia.dart';

/// Vista agrupada por localidades
class LocalidadesView extends StatelessWidget {
  final OrdenDelDia ordenDelDia;
  final Function(ClienteOrdenDelDia) onClienteTap;
  final Function(ClienteOrdenDelDia) onMapTap;
  final Function(ClienteOrdenDelDia) onMarcarVisitaTap;
  final Function(ClienteOrdenDelDia) onPedidoTap;

  const LocalidadesView({
    super.key,
    required this.ordenDelDia,
    required this.onClienteTap,
    required this.onMapTap,
    required this.onMarcarVisitaTap,
    required this.onPedidoTap,
  });

  /// Agrupar clientes por localidad
  Map<String, List<ClienteOrdenDelDia>> _agruparPorLocalidad() {
    final grupos = <String, List<ClienteOrdenDelDia>>{};

    for (final cliente in ordenDelDia.clientes) {
      final localidad = cliente.localidad?.nombre ?? 'Sin localidad';
      grupos.putIfAbsent(localidad, () => []);
      grupos[localidad]!.add(cliente);
    }

    return grupos;
  }

  @override
  Widget build(BuildContext context) {
    final grupos = _agruparPorLocalidad();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (grupos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                'No hay clientes con localidades',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: grupos.length,
      itemBuilder: (context, index) {
        final localidad = grupos.keys.elementAt(index);
        final clientes = grupos[localidad]!;
        final visitados = clientes.where((c) => c.visitado).length;
        final pendientes = clientes.length - visitados;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Encabezado de Localidad
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 18,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                localidad,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$visitados visitados • $pendientes pendientes',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                                .withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${clientes.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ✅ Clientes en esta localidad
            ...clientes.asMap().entries.map((entry) {
              final clienteIndex = entry.key;
              final cliente = entry.value;
              final estadoVisitado = cliente.visitado;
              final statusColor = estadoVisitado ? Colors.green : Colors.orange;
              final statusIcon = estadoVisitado ? Icons.check_circle : Icons.schedule;
              final statusText = estadoVisitado ? 'Visitado' : 'Pendiente';
              final secondaryTextColor = isDark
                  ? Colors.grey.shade400
                  : Colors.grey.shade700;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: estadoVisitado
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isDark
                      ? Colors.grey.shade900
                      : (estadoVisitado
                            ? Colors.green.withOpacity(0.05)
                            : Colors.orange.withOpacity(0.05)),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onClienteTap(cliente),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Número de orden
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${clienteIndex + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Información del cliente
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        cliente.nombre,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            statusIcon,
                                            size: 12,
                                            color: statusColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            statusText,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: statusColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (cliente.codigoCliente != null)
                                  Text(
                                    cliente.codigoCliente!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 12,
                                      color: secondaryTextColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${cliente.ventanaHoraria.horaInicio} - ${cliente.ventanaHoraria.horaFin}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
