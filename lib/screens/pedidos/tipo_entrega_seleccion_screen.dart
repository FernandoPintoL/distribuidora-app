import 'package:flutter/material.dart';
import '../../config/config.dart';
import '../../extensions/theme_extension.dart';
import '../../widgets/widgets.dart';

class TipoEntregaSeleccionScreen extends StatefulWidget {
  const TipoEntregaSeleccionScreen({super.key});

  @override
  State<TipoEntregaSeleccionScreen> createState() =>
      _TipoEntregaSeleccionScreenState();
}

class _TipoEntregaSeleccionScreenState
    extends State<TipoEntregaSeleccionScreen> {
  String? _tipoSeleccionado;

  void _continuarConDelivery() {
    // Navegar a la pantalla de selección de dirección (para DELIVERY)
    Navigator.pushNamed(
      context,
      '/direccion-entrega-seleccion',
    );
  }

  void _continuarConPickup() {
    // Navegar a la pantalla de fecha/hora (para PICKUP, sin dirección)
    Navigator.pushNamed(
      context,
      '/fecha-hora-entrega',
      arguments: null, // No pasar dirección para pickup
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: 'Tipo de Entrega',
        customGradient: AppGradients.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Encabezado
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 60,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '¿Cómo deseas recibir tu pedido?',
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Elige la opción que mejor se ajuste a tus necesidades',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Opción DELIVERY
              _buildTipoEntregaCard(
                context: context,
                titulo: 'Entrega a Domicilio',
                descripcion: 'Te lo llevamos a tu dirección',
                icono: Icons.delivery_dining_outlined,
                color: const Color(0xFF4CAF50),
                onTap: _continuarConDelivery,
                isSelected: _tipoSeleccionado == 'DELIVERY',
              ),

              const SizedBox(height: 20),

              // Opción PICKUP
              _buildTipoEntregaCard(
                context: context,
                titulo: 'Retiro en Almacén',
                descripcion: 'Retira tu pedido en nuestro almacén principal',
                icono: Icons.storefront_outlined,
                color: const Color(0xFFFFC107),
                onTap: _continuarConPickup,
                isSelected: _tipoSeleccionado == 'PICKUP',
              ),

              const SizedBox(height: 40),

              // Información adicional
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(isDark ? 0.1 : 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(isDark ? 0.3 : 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Información importante',
                          style: context.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.6,
                        ),
                        children: [
                          TextSpan(
                            text: '📦 Entrega a Domicilio: ',
                            style: context.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const TextSpan(
                            text:
                                'Selecciona una dirección y agenda la fecha y hora que mejor te convenga.\n\n',
                          ),
                          TextSpan(
                            text: '🏪 Retiro en Almacén: ',
                            style: context.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const TextSpan(
                            text:
                                'Agenda la fecha y hora preferida. Te notificaremos cuando el pedido esté listo.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipoEntregaCard({
    required BuildContext context,
    required String titulo,
    required String descripcion,
    required IconData icono,
    required Color color,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color
                : colorScheme.outline.withOpacity(isDark ? 0.3 : 0.2),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withOpacity(isDark ? 0.2 : 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            // Icono
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.2 : 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icono,
                size: 36,
                color: color,
              ),
            ),
            const SizedBox(width: 20),
            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    descripcion,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Indicador de selección
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? color
                      : colorScheme.outline.withOpacity(isDark ? 0.5 : 0.4),
                  width: 2,
                ),
                color: isSelected ? color : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
