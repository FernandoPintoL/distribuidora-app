import 'package:flutter/material.dart';
import '../../config/config.dart';
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
                      color: AppGradients.blue.stops?.first == 0
                          ? const Color(0xFF2196F3)
                          : const Color(0xFF1565C0),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '¿Cómo deseas recibir tu pedido?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Elige la opción que mejor se ajuste a tus necesidades',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
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
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Color(0xFF1976D2),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Información importante',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                          height: 1.6,
                        ),
                        children: [
                          TextSpan(
                            text: '📦 Entrega a Domicilio: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text:
                                'Selecciona una dirección y agenda la fecha y hora que mejor te convenga.\n\n',
                          ),
                          TextSpan(
                            text: '🏪 Retiro en Almacén: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                color: color.withOpacity(0.15),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    descripcion,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
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
                  color: isSelected ? color : Colors.grey.withOpacity(0.5),
                  width: 2,
                ),
                color: isSelected ? color : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
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
