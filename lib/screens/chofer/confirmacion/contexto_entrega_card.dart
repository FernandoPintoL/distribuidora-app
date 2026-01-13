import 'package:flutter/material.dart';

class ContextoEntregaCard extends StatelessWidget {
  final bool? tiendaAbierta;
  final bool? clientePresente;
  final String? motivoRechazo;
  final Function(bool?) onTiendaAbiertaChanged;
  final Function(bool?) onClientePresenteChanged;
  final Function(String?) onMotivoRechazoChanged;

  static const List<String> motivosRechazo = [
    'TIENDA_CERRADA',
    'CLIENTE_AUSENTE',
    'CLIENTE_RECHAZA',
    'DIRECCION_INCORRECTA',
    'CLIENTE_NO_IDENTIFICADO',
    'OTRO',
  ];

  static const Map<String, String> motivosRechazoLabels = {
    'TIENDA_CERRADA': '🏪 Tienda Cerrada',
    'CLIENTE_AUSENTE': '👤 Cliente Ausente',
    'CLIENTE_RECHAZA': '🚫 Cliente Rechaza',
    'DIRECCION_INCORRECTA': '📍 Dirección Incorrecta',
    'CLIENTE_NO_IDENTIFICADO': '🆔 Cliente No Identificado',
    'OTRO': '❓ Otro Motivo',
  };

  const ContextoEntregaCard({
    Key? key,
    required this.tiendaAbierta,
    required this.clientePresente,
    required this.motivoRechazo,
    required this.onTiendaAbiertaChanged,
    required this.onClientePresenteChanged,
    required this.onMotivoRechazoChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final mostrarMotivoRechazo = tiendaAbierta == false || clientePresente == false;

    return Card(
      color: isDarkMode
          ? colorScheme.surfaceContainerHighest
          : colorScheme.primary.withValues(alpha: 0.08),
      elevation: isDarkMode ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode
              ? colorScheme.outline.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 16,
          children: [
            // Tienda abierta
            Row(
              children: [
                Checkbox(
                  value: tiendaAbierta ?? false,
                  onChanged: onTiendaAbiertaChanged,
                  activeColor: colorScheme.primary,
                ),
                Expanded(
                  child: Text(
                    '✅ Tienda abierta',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            // Cliente presente
            Row(
              children: [
                Checkbox(
                  value: clientePresente ?? false,
                  onChanged: onClientePresenteChanged,
                  activeColor: colorScheme.primary,
                ),
                Expanded(
                  child: Text(
                    '✅ Cliente presente',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            // Motivo de rechazo (solo si alguno es false)
            if (mostrarMotivoRechazo)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(
                    'Motivo de rechazo *',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: motivoRechazo,
                    items: motivosRechazo.map((motivo) {
                      return DropdownMenuItem(
                        value: motivo,
                        child: Text(
                          motivosRechazoLabels[motivo] ?? motivo,
                        ),
                      );
                    }).toList(),
                    onChanged: onMotivoRechazoChanged,
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
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
          ],
        ),
      ),
    );
  }
}
