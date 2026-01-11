import 'package:flutter/material.dart';

/// Información sobre descuentos por volumen
/// Muestra escalas de precio según cantidad
class VolumeDiscountDisplay extends StatelessWidget {
  final String nombreProducto;
  final double precioActual;
  final int cantidadActual;

  /// Lista de tier de descuentos
  /// Ejemplo: [
  ///   {'cantidad': 10, 'descuento': 10, 'precio': 45},
  ///   {'cantidad': 50, 'descuento': 20, 'precio': 40},
  /// ]
  final List<Map<String, dynamic>> tiers;

  const VolumeDiscountDisplay({
    super.key,
    required this.nombreProducto,
    required this.precioActual,
    required this.cantidadActual,
    required this.tiers,
  });

  @override
  Widget build(BuildContext context) {
    if (tiers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.trending_down,
                  color: Colors.green.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '📊 Compra más, ahorra más:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tiers
            ..._buildTiers(context),

            const SizedBox(height: 16),

            // Sugerencia
            _buildSuggestion(context),
          ],
        ),
      ),
    );
  }

  /// Construye los tiers de descuento
  List<Widget> _buildTiers(BuildContext context) {
    return tiers.asMap().entries.map((entry) {
      final index = entry.key;
      final tier = entry.value;
      final cantidad = tier['cantidad'] as int;
      final descuento = tier['descuento'] as int;
      final precio = (tier['precio'] as num).toDouble();
      final isApplicable = cantidadActual >= cantidad;

      return Padding(
        padding: EdgeInsets.only(bottom: index < tiers.length - 1 ? 12 : 0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isApplicable
                ? Colors.green.shade50
                : Colors.grey.shade50,
            border: Border.all(
              color: isApplicable
                  ? Colors.green.shade300
                  : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index > 0 ? tiers[index - 1]['cantidad'] + 1 : 1}-${cantidad} unidades',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bs ${precio.toStringAsFixed(2)} c/u',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isApplicable
                              ? Colors.green.shade700
                              : Colors.black,
                        ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$descuento% dcto',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (isApplicable)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green.shade700,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  /// Construye sugerencia de ahorro
  Widget _buildSuggestion(BuildContext context) {
    // Calcular próximo tier aplicable
    final proximoTier = tiers.firstWhere(
      (t) => (t['cantidad'] as int) > cantidadActual,
      orElse: () => {},
    );

    if (proximoTier.isEmpty) {
      // Ya está en el mejor tier
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.blue.shade700,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '¡Excelente! Tienes el mejor precio',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue.shade700,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    final proximaCantidad = proximoTier['cantidad'] as int;
    final faltante = proximaCantidad - cantidadActual.toInt();
    final proximoDescuento = proximoTier['descuento'] as int;
    final proximoPrecio = (proximoTier['precio'] as num).toDouble();
    final ahorroUnitario = precioActual - proximoPrecio;
    final ahorroTotal = ahorroUnitario * proximaCantidad;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 Sugerencia:',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Compra $faltante unidad${faltante > 1 ? "es" : ""} más y obtén $proximoDescuento% de descuento',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.amber.shade800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ahorrarías Bs ${ahorroTotal.toStringAsFixed(2)} en total',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

/// Badge pequeño para mostrar en producto list
class VolumeDiscountBadge extends StatelessWidget {
  final int mejorDescuentoPorcentaje;

  const VolumeDiscountBadge({
    super.key,
    required this.mejorDescuentoPorcentaje,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Hasta $mejorDescuentoPorcentaje% dcto',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
      ),
    );
  }
}
