import 'package:flutter/material.dart';

class ConfirmacionPagoCard extends StatelessWidget {
  final String? estadoPago;
  final TextEditingController montoRecibidoController;
  final int? tipoPagoId;
  final TextEditingController motivoNoPagoController;
  final List<Map<String, dynamic>> tiposPago;
  final bool cargandoTiposPago;
  final Function(String?) onEstadoPagoChanged;
  final Function(int?) onTipoPagoChanged;

  static const List<String> estadosPago = ['PAGADO', 'PARCIAL', 'NO_PAGADO'];
  static const Map<String, String> estadosPagoLabels = {
    'PAGADO': '✅ Pagado Completo',
    'PARCIAL': '⚠️ Pago Parcial',
    'NO_PAGADO': '❌ No Pagado',
  };

  const ConfirmacionPagoCard({
    Key? key,
    required this.estadoPago,
    required this.montoRecibidoController,
    required this.tipoPagoId,
    required this.motivoNoPagoController,
    required this.tiposPago,
    required this.cargandoTiposPago,
    required this.onEstadoPagoChanged,
    required this.onTipoPagoChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: isDarkMode
          ? colorScheme.surfaceContainerHigh
          : colorScheme.primary.withValues(alpha: 0.06),
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
          children: [
            // Estado de Pago - Radio Buttons
            Text(
              'Estado de Pago *',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            Wrap(
              spacing: 16,
              children: estadosPago.map((estado) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<String>(
                      value: estado,
                      groupValue: estadoPago,
                      onChanged: onEstadoPagoChanged,
                      activeColor: colorScheme.primary,
                    ),
                    Text(
                      estadosPagoLabels[estado] ?? estado,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 8),

            // Monto Recibido
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(
                  'Monto Recibido (Bs.) ${estadoPago == 'PAGADO' ? '*' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                TextField(
                  controller: montoRecibidoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Bs. ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDarkMode
                            ? colorScheme.outline.withValues(alpha: 0.5)
                            : colorScheme.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDarkMode
                            ? colorScheme.outline.withValues(alpha: 0.5)
                            : colorScheme.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: isDarkMode
                        ? colorScheme.surface.withValues(alpha: 0.5)
                        : colorScheme.primaryContainer.withValues(alpha: 0.1),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),

            // Tipo de Pago
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(
                  'Tipo de Pago ${estadoPago == 'PAGADO' ? '*' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                cargandoTiposPago
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDarkMode
                                ? colorScheme.outline.withValues(alpha: 0.5)
                                : colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isDarkMode
                              ? colorScheme.surface.withValues(alpha: 0.5)
                              : colorScheme.primaryContainer.withValues(alpha: 0.1),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Cargando tipos de pago...',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : DropdownButtonFormField<int>(
                        initialValue: tipoPagoId,
                        items: tiposPago.map((tipo) {
                          return DropdownMenuItem(
                            value: tipo['id'] as int,
                            child: Text(tipo['nombre'] as String),
                          );
                        }).toList(),
                        onChanged: onTipoPagoChanged,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isDarkMode
                                  ? colorScheme.outline.withValues(alpha: 0.5)
                                  : colorScheme.outline,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isDarkMode
                                  ? colorScheme.outline.withValues(alpha: 0.5)
                                  : colorScheme.outline,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: isDarkMode
                              ? colorScheme.surface.withValues(alpha: 0.5)
                              : colorScheme.primaryContainer.withValues(alpha: 0.1),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        hint: Text(
                          '-- Seleccionar --',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
              ],
            ),

            // Motivo No Pago (condicional)
            if (estadoPago == 'NO_PAGADO' || estadoPago == 'PARCIAL')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(
                    'Motivo (${estadoPago == 'NO_PAGADO' ? 'Obligatorio' : 'Opcional'})',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  TextField(
                    controller: motivoNoPagoController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: '¿Por qué no pagó o por qué pagó parcial?',
                      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? colorScheme.outline.withValues(alpha: 0.5)
                              : colorScheme.outline,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? colorScheme.outline.withValues(alpha: 0.5)
                              : colorScheme.outline,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: isDarkMode
                          ? colorScheme.surface.withValues(alpha: 0.5)
                          : colorScheme.primaryContainer.withValues(alpha: 0.1),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
