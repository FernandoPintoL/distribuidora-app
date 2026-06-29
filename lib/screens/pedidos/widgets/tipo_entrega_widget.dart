import 'package:flutter/material.dart';
import '../../../config/config.dart';
import '../../../extensions/theme_extension.dart';

class TipoEntregaWidget extends StatelessWidget {
  final String tipoEntregaSeleccionado;
  final Function(String) onTipoEntregaChanged;
  final BuildContext parentContext;

  const TipoEntregaWidget({
    super.key,
    required this.tipoEntregaSeleccionado,
    required this.onTipoEntregaChanged,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = parentContext.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Entrega',
          style: TextStyle(
            fontSize: AppTextStyles.headlineSmall(parentContext).fontSize!,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TipoEntregaChip(
                value: 'DELIVERY',
                label: '🚚 Delivery',
                color: const Color(0xFF4CAF50),
                isSelected: tipoEntregaSeleccionado == 'DELIVERY',
                onTap: () => onTipoEntregaChanged('DELIVERY'),
                parentContext: parentContext,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TipoEntregaChip(
                value: 'PICKUP',
                label: '🏪 Retiro',
                color: const Color(0xFFFFC107),
                isSelected: tipoEntregaSeleccionado == 'PICKUP',
                onTap: () {
                  onTipoEntregaChanged('PICKUP');
                },
                parentContext: parentContext,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TipoEntregaChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final BuildContext parentContext;

  const _TipoEntregaChip({
    required this.value,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = parentContext.colorScheme;
    final isDark = parentContext.isDark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(isDark ? 0.2 : 0.1)
              : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color
                : colorScheme.outline.withOpacity(isDark ? 0.3 : 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? color : colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
