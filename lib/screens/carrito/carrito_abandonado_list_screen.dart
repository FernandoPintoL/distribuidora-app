import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/carrito_provider.dart';
import '../../models/carrito.dart';

class CarritoAbandonadoListScreen extends StatefulWidget {
  const CarritoAbandonadoListScreen({super.key});

  @override
  State<CarritoAbandonadoListScreen> createState() =>
      _CarritoAbandonadoListScreenState();
}

class _CarritoAbandonadoListScreenState
    extends State<CarritoAbandonadoListScreen> {
  late Future<List<Carrito>> _futureCarritos;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _futureCarritos = context
        .read<CarritoProvider>()
        .obtenerCarritosAbandonados();
  }

  Future<void> _refrescar() async {
    setState(() {
      _futureCarritos = context
          .read<CarritoProvider>()
          .obtenerCarritosAbandonados();
    });
  }

  Future<void> _recuperarCarrito(Carrito carrito) async {
    setState(() => _isLoading = true);

    final success = await context
        .read<CarritoProvider>()
        .recuperarCarritoAbandonado(carrito);

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Carrito recuperado exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navegar de vuelta a carrito
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error al recuperar carrito'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _confirmarEliminar(Carrito carrito) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar carrito'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este carrito del historial?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              if (carrito.id != null) {
                final success = await context
                    .read<CarritoProvider>()
                    .eliminarCarritoAbandonado(carrito.id!);

                if (mounted) {
                  if (success) {
                    // Actualizar lista
                    await _refrescar();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Carrito eliminado'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ Error al eliminar'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Carritos Guardados'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refrescar,
        child: FutureBuilder<List<Carrito>>(
          future: _futureCarritos,
          builder: (context, snapshot) {
            // Loading
            if (snapshot.connectionState == ConnectionState.waiting &&
                !_isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // Error
            if (snapshot.hasError) {
              return _buildErrorWidget(snapshot.error.toString());
            }

            // Sin datos
            final carritos = snapshot.data ?? [];
            if (carritos.isEmpty) {
              return _buildEmptyState();
            }

            // Con datos
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: carritos.length,
              itemBuilder: (context, index) {
                final carrito = carritos[index];
                return _buildCarritoCard(context, carrito);
              },
            );
          },
        ),
      ),
    );
  }

  /// Widget para estado vacío
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay carritos guardados',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los carritos que guardes aparecerán aquí',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Widget para errores
  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar carritos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.red.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _futureCarritos = context
                    .read<CarritoProvider>()
                    .obtenerCarritosAbandonados();
              });
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  /// Tarjeta de carrito abandonado
  Widget _buildCarritoCard(BuildContext context, Carrito carrito) {
    final carritoProvider = context.read<CarritoProvider>();
    final diasAbandonado = carritoProvider.obtenerDiasAbandonado(carrito);
    final debeAlertarExpiracion = carritoProvider.debeAlertarExpiracion(carrito);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con fecha y estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Carrito del ${_formatearFecha(carrito.fechaAbandono)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hace $diasAbandonado día${diasAbandonado != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
                if (debeAlertarExpiracion)
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
                      'Por expirar',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Información de items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${carrito.items.length} item${carrito.items.length != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Bs ${carrito.subtotal.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
              ],
            ),

            // Resumen de items (máximo 3)
            if (carrito.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._buildItemsResumen(context, carrito),
            ],

            const SizedBox(height: 12),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _recuperarCarrito(carrito),
                    icon: const Icon(Icons.restore),
                    label: const Text('Recuperar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _confirmarEliminar(carrito),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construye resumen de items (máximo 3)
  List<Widget> _buildItemsResumen(BuildContext context, Carrito carrito) {
    final itemsAMostrar = carrito.items.take(3).toList();
    final hayMas = carrito.items.length > 3;

    return [
      Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            ...itemsAMostrar.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.producto?.nombre ?? 'Producto',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall,
                            ),
                            Text(
                              'Qty: ${item.cantidad.toStringAsFixed(1)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Bs ${(item.cantidad * item.precioUnitario).toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                )),
            if (hayMas)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Text(
                  '+ ${carrito.items.length - 3} items más',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
          ],
        ),
      ),
    ];
  }

  /// Formatea la fecha para mostrar
  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'N/A';

    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final ayer = hoy.subtract(const Duration(days: 1));
    final diaFecha = DateTime(fecha.year, fecha.month, fecha.day);

    if (diaFecha == hoy) {
      return 'Hoy ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    } else if (diaFecha == ayer) {
      return 'Ayer';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }
}
