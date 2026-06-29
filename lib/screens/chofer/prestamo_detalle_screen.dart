import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/prestamos_provider.dart';
import '../../config/app_text_styles.dart';
import '../../models/prestamo_completo.dart';
import '../../models/prestamo_evento.dart';
import '../../models/prestamo_proveedor.dart';
import 'registrar_devolucion_screen.dart';

/// Pantalla que muestra los detalles de un préstamo
/// y permite registrar su devolución
class PrestamoDetalleScreen extends StatelessWidget {
  final dynamic prestamo;
  final String tipo; // 'cliente', 'evento', 'proveedor'

  const PrestamoDetalleScreen({
    super.key,
    required this.prestamo,
    required this.tipo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitulo()),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información general
            _buildSeccion(context, 'Información General', [
              _buildItem(context,'ID Préstamo', '#${prestamo.id}'),
              _buildItem(context,'Estado', prestamo.estado ?? 'N/A'),
              _buildItem(context,
                'Fecha Préstamo',
                prestamo.fechaPrestamo ?? 'N/A',
              ),
            ]),

            // Información específica según tipo
            if (tipo == 'cliente')
              _buildSeccion(context, 'Cliente', [
                _buildItem(context,
                  'Nombre',
                  prestamo.cliente?.nombre ?? 'N/A',
                ),
                _buildItem(context,
                  'Razón Social',
                  prestamo.cliente?.razonSocial ?? 'N/A',
                ),
                _buildItem(context,
                  'Teléfono',
                  prestamo.cliente?.telefono ?? 'N/A',
                ),
              ])
            else if (tipo == 'evento')
              _buildSeccion(context, 'Evento', [
                _buildItem(context,
                  'Nombre del Evento',
                  prestamo.nombreEvento ?? 'N/A',
                ),
                _buildItem(context,
                  'Encargado',
                  prestamo.encargadoEvento ?? 'N/A',
                ),
                _buildItem(context,
                  'Dirección',
                  prestamo.direccionEvento ?? 'N/A',
                ),
                _buildItem(context,
                  'Teléfono',
                  prestamo.telefonoUno ?? 'N/A',
                ),
              ])
            else if (tipo == 'proveedor')
              _buildSeccion(context, 'Proveedor', [
                _buildItem(context,
                  'Nombre',
                  prestamo.proveedor?.nombre ?? 'N/A',
                ),
                _buildItem(context,
                  'Teléfono',
                  prestamo.proveedor?.telefono ?? 'N/A',
                ),
              ]),

            // Detalles de items prestados
            _buildDetallesItems(context),

            // Garantía
            _buildSeccion(context, 'Garantía', [
              _buildItem(context,
                'Monto',
                'Bs ${(prestamo.montoGarantia ?? 0).toStringAsFixed(2)}',
              ),
            ]),

            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  String _getTitulo() {
    switch (tipo) {
      case 'cliente':
        return 'Préstamo a Cliente';
      case 'evento':
        return 'Préstamo a Evento';
      case 'proveedor':
        return 'Préstamo a Proveedor';
      default:
        return 'Detalle de Préstamo';
    }
  }

  // ✅ NUEVO: Obtener devoluciones según tipo de préstamo
  List<dynamic> _obtenerDevoluciones(dynamic detalle) {
    if (tipo == 'evento' && detalle is PrestamoEventoDetalle) {
      return detalle.devoluciones ?? [];
    }
    // Para cliente
    if (tipo == 'cliente' && detalle is PrestamoDetalle) {
      return detalle.devolucionDetalles ?? [];
    }
    // Para proveedor
    if (tipo == 'proveedor' && detalle is PrestamoProveedorDetalle) {
      return detalle.devolucionDetalles ?? [];
    }
    return [];
  }

  // ✅ NUEVO: Calcular total devuelto según tipo
  int _calcularTotalDevuelto(dynamic detalle) {
    final devoluciones = _obtenerDevoluciones(detalle);

    if (tipo == 'evento') {
      // Para eventos: usar DevolucionEventoDetalle
      return (devoluciones as List<dynamic>)
          .fold<int>(0, (sum, dev) {
            if (dev is DevolucionEventoDetalle) {
              return sum + dev.cantidadDevuelta;
            }
            return sum;
          });
    }

    if (tipo == 'proveedor') {
      // Para proveedor: usar DevolucionProveedorDetalle
      return (devoluciones as List<dynamic>)
          .fold<int>(0, (sum, dev) {
            if (dev is DevolucionProveedorDetalle) {
              return sum + dev.cantidadDevuelta;
            }
            return sum;
          });
    }

    // Para cliente: usar DevolucionDetalle
    return (devoluciones as List<dynamic>)
        .fold<int>(0, (sum, dev) {
          if (dev is DevolucionDetalle) {
            return sum + dev.cantidadDevuelta;
          }
          return sum;
        });
  }

  Widget _buildSeccion(
    BuildContext context,  // ✅ Parámetro ahora es consistente
    String titulo,
    List<Widget> items,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 1,
        color: isDark ? Theme.of(context).cardColor : Colors.white,  // ✅ Modo oscuro
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: AppTextStyles.titleMedium(context),
              ),
              const SizedBox(height: 12),
              ...items,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, String label, String value) {  // ✅ Agregar context
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade400 : Colors.grey,  // ✅ Modo oscuro
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetallesItems(BuildContext context) {
    final detalles = prestamo.detalles ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (detalles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 1,
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Items Prestados',
                style: AppTextStyles.titleMedium(context),
              ),
              const SizedBox(height: 12),
              ...detalles.map((detalle) {
                final cantidadPrestada = detalle.cantidadPrestada;
                final prestableName = detalle.prestable?.nombre ?? 'N/A';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prestableName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              'Prestado: $cantidadPrestada unidades',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey.shade400 : Colors.grey,
                              ),
                            ),
                            // ✅ NUEVO: Obtener devoluciones según tipo de préstamo
                            if (_obtenerDevoluciones(detalle).isNotEmpty)
                              Text(
                                'Devuelto: ${_calcularTotalDevuelto(detalle)} unidades',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RegistrarDevolucionScreen(
              prestamo: prestamo,
              tipo: tipo,
            ),
          ),
        );
      },
      icon: const Icon(Icons.check_circle),
      label: const Text('Registrar Devolución'),
      backgroundColor: Colors.green,
    );
  }
}
