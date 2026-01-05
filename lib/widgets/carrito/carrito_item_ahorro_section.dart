import 'package:flutter/material.dart';
import '../../models/detalle_carrito_con_rango.dart';

/// Widget que muestra la oportunidad de ahorro para un item del carrito
/// cuando el cliente puede obtener un precio mejor agregando más cantidad
class CarritoItemAhorroSection extends StatelessWidget {
  final DetalleCarritoConRango detalle;
  final VoidCallback onAgregarParaAhorrar;

  const CarritoItemAhorroSection({
    super.key,
    required this.detalle,
    required this.onAgregarParaAhorrar,
  });

  @override
  Widget build(BuildContext context) {
    // Si no hay oportunidad de ahorro, no mostrar nada
    if (!detalle.tieneOportunidadAhorro) {
      return const SizedBox.shrink();
    }

    final proximoRango = detalle.proximoRango!;
    final ahorro = detalle.ahorroProximo!;
    final faltaQuantity = proximoRango.faltaCantidad;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(
          color: Colors.green.shade300,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Row(
            children: [
              Icon(
                Icons.trending_down,
                color: Colors.green.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '¡Oportunidad de Ahorro!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Información del ahorro
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cantidad a agregar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Agrega ${faltaQuantity} más:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '→ Rango ${proximoRango.rangoTexto}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Monto de ahorro
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ahorrarás:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      'Bs ${ahorro.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Botón para agregar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAgregarParaAhorrar,
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                'Agregar $faltaQuantity para ahorrar',
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
