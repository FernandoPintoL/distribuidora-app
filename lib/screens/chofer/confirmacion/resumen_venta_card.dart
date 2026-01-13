import 'package:flutter/material.dart';
import '../../../models/venta.dart';

class ResumenVentaCard extends StatelessWidget {
  final Venta venta;
  final String? clienteNombre;
  final String? clienteDireccion;

  const ResumenVentaCard({
    Key? key,
    required this.venta,
    this.clienteNombre,
    this.clienteDireccion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: isDarkMode
          ? colorScheme.surfaceContainerHigh
          : colorScheme.primaryContainer.withValues(alpha: 0.06),
      elevation: isDarkMode ? 1 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode
              ? colorScheme.outline.withValues(alpha: 0.2)
              : colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 16,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Resumen de Venta',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                ),
              ],
            ),

            // Divider
            Divider(
              color: isDarkMode
                  ? colorScheme.outline.withValues(alpha: 0.2)
                  : colorScheme.outline.withValues(alpha: 0.1),
              thickness: 1,
              height: 1,
            ),

            // Cliente y dirección
            Column(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  context,
                  icon: Icons.person,
                  label: 'Cliente',
                  value: clienteNombre ?? venta.clienteNombre ?? 'N/A',
                ),
                if (clienteDireccion != null || venta.direccion != null)
                  _buildInfoRow(
                    context,
                    icon: Icons.location_on,
                    label: 'Dirección',
                    value: clienteDireccion ?? venta.direccion ?? 'N/A',
                    isMultiline: true,
                  ),
                _buildInfoRow(
                  context,
                  icon: Icons.confirmation_number,
                  label: 'Número de Venta',
                  value: venta.numero,
                ),
              ],
            ),

            // Divider
            Divider(
              color: isDarkMode
                  ? colorScheme.outline.withValues(alpha: 0.2)
                  : colorScheme.outline.withValues(alpha: 0.1),
              thickness: 1,
              height: 1,
            ),

            // Detalles de productos
            if (venta.detalles.isNotEmpty)
              Column(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Productos (${venta.detalles.length})',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                  ),
                  ...venta.detalles.map((detalle) => _buildDetalleItem(
                        context,
                        detalle,
                        isDarkMode,
                        colorScheme,
                      )),
                ],
              ),

            // Divider
            Divider(
              color: isDarkMode
                  ? colorScheme.outline.withValues(alpha: 0.2)
                  : colorScheme.outline.withValues(alpha: 0.1),
              thickness: 1,
              height: 1,
            ),

            // Totales
            Column(
              spacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDarkMode
                            ? colorScheme.outline.withValues(alpha: 0.2)
                            : colorScheme.outline.withValues(alpha: 0.1),
                      ),
                      bottom: BorderSide(
                        color: isDarkMode
                            ? colorScheme.outline.withValues(alpha: 0.2)
                            : colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SUBTOTAL',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.primary,
                                ),
                      ),
                      Text(
                        'Bs. ${venta.subtotal.toStringAsFixed(2)}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.primary,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isMultiline = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment:
          isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 18,
          color: colorScheme.primary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDarkMode
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: isMultiline ? 3 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetalleItem(
    BuildContext context,
    dynamic detalle,
    bool isDarkMode,
    ColorScheme colorScheme,
  ) {
    // Obtener nombre del producto
    final nombreProducto = detalle.producto?.nombre ?? 'Producto sin nombre';
    final cantidad = detalle.cantidad ?? 0;
    final subtotal = detalle.subtotal ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? colorScheme.surface.withValues(alpha: 0.3)
            : colorScheme.primaryContainer.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode
              ? colorScheme.outline.withValues(alpha: 0.1)
              : colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(
            nombreProducto,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cantidad: ${cantidad.toStringAsFixed(cantidad == cantidad.toInt() ? 0 : 2)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
              ),
              Text(
                'Bs. ${subtotal.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    BuildContext context, {
    required String label,
    required String value,
    required bool isDarkMode,
    required ColorScheme colorScheme,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDarkMode
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
        ),
      ],
    );
  }
}
