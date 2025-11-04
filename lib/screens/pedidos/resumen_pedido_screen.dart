import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';

class ResumenPedidoScreen extends StatefulWidget {
  final ClientAddress direccion;
  final DateTime? fechaProgramada;
  final TimeOfDay? horaInicio;
  final TimeOfDay? horaFin;
  final String? observaciones;

  const ResumenPedidoScreen({
    super.key,
    required this.direccion,
    this.fechaProgramada,
    this.horaInicio,
    this.horaFin,
    this.observaciones,
  });

  @override
  State<ResumenPedidoScreen> createState() => _ResumenPedidoScreenState();
}

class _ResumenPedidoScreenState extends State<ResumenPedidoScreen> {
  bool _isCreandoPedido = false;
  final PedidoService _pedidoService = PedidoService();

  Future<void> _confirmarPedido() async {
    final carritoProvider = context.read<CarritoProvider>();

    if (carritoProvider.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El carrito está vacío'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreandoPedido = true;
    });

    try {
      // Obtener items del carrito
      final items = carritoProvider.getItemsParaPedido();

      // Validar que el cliente esté autenticado
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) {
        throw Exception('Cliente no autenticado');
      }

      // Crear proforma
      final response = await _pedidoService.crearPedido(
        clienteId: authProvider.user!.id,
        items: items,
        fechaProgramada: widget.fechaProgramada,
        horaInicio: widget.horaInicio,
        horaFin: widget.horaFin,
        observaciones: widget.observaciones,
      );

      setState(() {
        _isCreandoPedido = false;
      });

      if (response.success && response.data != null) {
        // Limpiar el carrito
        carritoProvider.limpiarCarrito();

        // Navegar a pantalla de éxito
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/pedido-creado',
            (route) => route.isFirst,
            arguments: response.data,
          );
        }
      } else {
        // Mostrar error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message.isNotEmpty
                  ? response.message
                  : 'Error al crear el pedido'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isCreandoPedido = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatearFecha(DateTime fecha) {
    final meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];

    return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}';
  }

  String _formatearHora(TimeOfDay hora) {
    final hour = hora.hour.toString().padLeft(2, '0');
    final minute = hora.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen del Pedido'),
        elevation: 0,
      ),
      body: Consumer<CarritoProvider>(
        builder: (context, carritoProvider, _) {
          final carrito = carritoProvider.carrito;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Revisa tu pedido',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Verifica que todo esté correcto antes de confirmar',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Productos
                      const Text(
                        'Productos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...carrito.items.map((item) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Imagen del producto
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: item.producto.imagenes != null && item.producto.imagenes!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          item.producto.imagenes!.first.url,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.image),
                                        ),
                                      )
                                    : const Icon(Icons.image, size: 32),
                              ),

                              const SizedBox(width: 12),

                              // Información del producto
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.producto.nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Cantidad: ${item.cantidad.toStringAsFixed(item.cantidad.truncateToDouble() == item.cantidad ? 0 : 2)}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Precio
                              Text(
                                'Bs. ${item.subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),

                      const SizedBox(height: 24),

                      // Dirección de entrega
                      const Text(
                        'Dirección de entrega',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Theme.of(context).primaryColor,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.direccion.direccion,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (widget.direccion.ciudad != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Ciudad: ${widget.direccion.ciudad}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                    if (widget.direccion.observaciones != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Obs: ${widget.direccion.observaciones}',
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Fecha y hora programada
                      if (widget.fechaProgramada != null ||
                          widget.horaInicio != null ||
                          widget.horaFin != null) ...[
                        const Text(
                          'Fecha y hora programada',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                if (widget.fechaProgramada != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 20),
                                      const SizedBox(width: 12),
                                      Text(
                                        _formatearFecha(widget.fechaProgramada!),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),

                                if (widget.horaInicio != null || widget.horaFin != null) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 20),
                                      const SizedBox(width: 12),
                                      Text(
                                        '${widget.horaInicio != null ? _formatearHora(widget.horaInicio!) : '--:--'} a ${widget.horaFin != null ? _formatearHora(widget.horaFin!) : '--:--'}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],

                      // Observaciones
                      if (widget.observaciones != null &&
                          widget.observaciones!.isNotEmpty) ...[
                        const Text(
                          'Observaciones',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.note, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.observaciones!,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],

                      // Resumen de montos
                      const Text(
                        'Resumen',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Card(
                        color: Colors.grey.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Subtotal',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    'Bs. ${carrito.subtotal.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Impuesto (13%)',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    'Bs. ${carrito.impuesto.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Bs. ${carrito.total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isCreandoPedido ? null : _confirmarPedido,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.green,
              ),
              child: _isCreandoPedido
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Confirmar Pedido',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
