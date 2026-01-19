import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';
import '../../config/config.dart';
import '../../extensions/theme_extension.dart';

class ResumenPedidoScreen extends StatefulWidget {
  final String tipoEntrega; // DELIVERY or PICKUP
  final ClientAddress? direccion; // Null para PICKUP, required para DELIVERY
  final DateTime? fechaProgramada;
  final TimeOfDay? horaInicio;
  final TimeOfDay? horaFin;
  final String? observaciones;

  const ResumenPedidoScreen({
    super.key,
    required this.tipoEntrega,
    this.direccion,
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

  // ✅ Política de pago (antes era _solicitarCredito)
  String _politicaPago = 'CONTRA_ENTREGA'; // Default

  // Constantes de políticas
  static const String POLITICA_ANTICIPADO = 'ANTICIPADO_100';
  static const String POLITICA_MEDIO_MEDIO = 'MEDIO_MEDIO';
  static const String POLITICA_CONTRA_ENTREGA = 'CONTRA_ENTREGA';
  static const String POLITICA_CREDITO = 'CREDITO';

  final PedidoService _pedidoService = PedidoService();

  // Detectar si es PICKUP o DELIVERY
  bool get esPickup => widget.tipoEntrega == 'PICKUP';

  Future<void> _confirmarPedido() async {
    final carritoProvider = context.read<CarritoProvider>();
    debugPrint(
      '🚀 cliente cargado ${carritoProvider.getClienteSeleccionadoId()}',
    );

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

      // Validar que el usuario esté autenticado
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Validación condicional según tipo de entrega
      int? direccionId;
      if (!esPickup) {
        // Para DELIVERY: la dirección es REQUERIDA
        if (widget.direccion == null || widget.direccion!.id == null) {
          throw Exception(
            'La dirección de entrega es requerida para pedidos de tipo DELIVERY',
          );
        }
        direccionId = widget.direccion!.id;
      }
      // Para PICKUP: direccionId puede ser null

      // Determinar si es cliente o preventista y obtener cliente_id para la proforma
      final clienteIdUsuario = authProvider.user!.clienteId;
      final carritoClienteId = carritoProvider.getClienteSeleccionadoId();

      late int clienteIdParaPedido;
      bool esClienteLogueado = false;
      bool esPreventista = false;

      // Si es cliente logueado (tiene clienteId en su perfil)
      if (clienteIdUsuario != null) {
        clienteIdParaPedido = clienteIdUsuario;
        esClienteLogueado = true;
        debugPrint('👤 Creador: CLIENTE logueado (ID: $clienteIdUsuario)');
      }
      // Si es preventista (no tiene clienteId pero seleccionó un cliente)
      else if (carritoClienteId != null) {
        clienteIdParaPedido = carritoClienteId;
        esPreventista = true;
        debugPrint(
          '👨‍💼 Creador: PREVENTISTA para cliente (ID: $carritoClienteId)',
        );
      }
      // Si ninguno de los dos casos se cumple, error
      else {
        throw Exception(
          'No se pudo identificar al cliente. Asegúrate de estar correctamente autenticado.',
        );
      }

      // Obtener el cliente para verificar permisos de crédito
      // ✅ Dos formas de obtener al cliente según el tipo de usuario:
      // 1. Si es CLIENTE LOGUEADO: cargar desde API usando clienteId
      // 2. Si es PREVENTISTA: obtener desde carritoProvider (ya seleccionado)
      Client? clienteSeleccionado;

      if (esClienteLogueado) {
        // Para cliente logueado: cargar desde API usando ClientProvider
        debugPrint(
          '👤 Cargando datos del cliente logueado (ID: $clienteIdParaPedido)...',
        );

        final clientProvider = Provider.of<ClientProvider>(
          context,
          listen: false,
        );
        clienteSeleccionado = await clientProvider.getClient(
          clienteIdParaPedido,
        );

        if (clienteSeleccionado == null) {
          throw Exception(
            'No se pudieron cargar los datos del cliente. Por favor, intenta de nuevo.',
          );
        }

        debugPrint(
          '👤 Cliente logueado cargado: ${clienteSeleccionado.nombre} (ID: ${clienteSeleccionado.id})',
        );
      } else if (esPreventista) {
        // Para preventista: obtener del carrito (ya fue seleccionado)
        clienteSeleccionado = carritoProvider.getClienteSeleccionado();
        if (clienteSeleccionado == null) {
          throw Exception(
            'No se pudo obtener el cliente seleccionado. Por favor, intenta de nuevo.',
          );
        }
        debugPrint(
          '👨‍💼 Cliente seleccionado por preventista: ${clienteSeleccionado.nombre} (ID: ${clienteSeleccionado.id})',
        );
      } else {
        throw Exception('No se pudo identificar el tipo de usuario.');
      }

      // ✅ Validar política de pago seleccionada
      debugPrint('💳 Política de pago seleccionada: $_politicaPago');

      // Si solicita crédito, validar permisos
      if (_politicaPago == POLITICA_CREDITO) {
        debugPrint(
          '💳 Verificando permisos de crédito para ${clienteSeleccionado.nombre}',
        );
        debugPrint('   ID Cliente: ${clienteSeleccionado.id}');
        debugPrint(
          '   puedeAtenerCredito: ${clienteSeleccionado.puedeAtenerCredito}',
        );
        debugPrint('   limiteCredito: ${clienteSeleccionado.limiteCredito}');

        if (!clienteSeleccionado.puedeAtenerCredito) {
          debugPrint('⚠️  Cliente NO tiene permisos de crédito');

          // Mostrar advertencia pero permitir que continúe
          if (!mounted) return;
          final shouldContinue = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('Sin Permisos de Crédito'),
              content: Text(
                'El cliente "${clienteSeleccionado!.nombre}" no tiene permisos para solicitar crédito.\n\n'
                '¿Deseas continuar con otra forma de pago?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Volver'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Continuar'),
                ),
              ],
            ),
          );

          if (shouldContinue != true) {
            setState(() {
              _isCreandoPedido = false;
            });
            return;
          }
        } else {
          debugPrint(
            '✅ Cliente tiene permisos de crédito. Límite: Bs. ${clienteSeleccionado.limiteCredito?.toStringAsFixed(2) ?? 'N/A'}',
          );
        }
      }

      // Crear pedido con tipoEntrega y política de pago
      // IMPORTANTE: Usar clienteIdParaPedido como cliente_id
      final response = await _pedidoService.crearPedido(
        clienteId: clienteIdParaPedido,
        items: items,
        tipoEntrega: widget.tipoEntrega, // DELIVERY o PICKUP
        fechaProgramada: widget.fechaProgramada ?? DateTime.now(),
        direccionId: direccionId, // null para PICKUP, int para DELIVERY
        horaInicio: widget.horaInicio,
        horaFin: widget.horaFin,
        observaciones: widget.observaciones,
        politicaPago: _politicaPago, // ✅ Política de pago seleccionada
      );

      debugPrint('✅ Pedido creado - Política de pago: $_politicaPago');

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
              content: Text(
                response.message.isNotEmpty
                    ? response.message
                    : 'Error al crear el pedido',
              ),
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
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
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
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: 'Resumen del Pedido',
        customGradient: AppGradients.blue,
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
                  color: colorScheme.primary.withOpacity(isDark ? 0.15 : 0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Revisa tu pedido',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Verifica que todo esté correcto antes de confirmar',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
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
                      Text(
                        'Productos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...carrito.items.map(
                        (item) => Card(
                          color: colorScheme.surface,
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
                                    color: colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child:
                                      item.producto.imagenes != null &&
                                          item.producto.imagenes!.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.producto.nombre,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Cantidad: ${item.cantidad}',
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Precio
                                Text(
                                  'Bs. ${item.subtotal.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Mostrar dirección SOLO si es DELIVERY
                      if (!esPickup) ...[
                        Text(
                          'Dirección de entrega',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Card(
                          color: colorScheme.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: colorScheme.primary,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.direccion!.direccion,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      if (widget.direccion!.ciudad != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Ciudad: ${widget.direccion!.ciudad}',
                                          style: TextStyle(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                      if (widget.direccion!.observaciones !=
                                          null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Obs: ${widget.direccion!.observaciones}',
                                          style: TextStyle(
                                            color: colorScheme.primary,
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
                      ],

                      // Mostrar info de almacén SI es PICKUP
                      if (esPickup) ...[
                        Text(
                          'Lugar de Retiro',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Card(
                          color: isDark
                              ? Color(0xFFFFC107).withOpacity(0.15)
                              : Color(0xFFFFC107).withOpacity(0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Color(
                                0xFFFFC107,
                              ).withOpacity(isDark ? 0.4 : 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.storefront_outlined,
                                  color: Color(0xFFFFC107),
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Almacén Principal',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Retira tu pedido cuando esté listo',
                                        style: TextStyle(
                                          color: Color(0xFFFFC107),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],

                      // Fecha y hora programada
                      if (widget.fechaProgramada != null ||
                          widget.horaInicio != null ||
                          widget.horaFin != null) ...[
                        Text(
                          'Fecha y hora programada',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Card(
                          color: colorScheme.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                if (widget.fechaProgramada != null)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 20,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _formatearFecha(
                                          widget.fechaProgramada!,
                                        ),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),

                                if (widget.horaInicio != null ||
                                    widget.horaFin != null) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 20,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '${widget.horaInicio != null ? _formatearHora(widget.horaInicio!) : '--:--'} a ${widget.horaFin != null ? _formatearHora(widget.horaFin!) : '--:--'}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: colorScheme.onSurface,
                                        ),
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
                        Text(
                          'Observaciones',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Card(
                          color: colorScheme.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.note,
                                  size: 20,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.observaciones!,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],

                      // ✅ Sección de Política de Pago
                      Consumer<CarritoProvider>(
                        builder: (context, carritoProvider, _) {
                          final clienteSeleccionado = carritoProvider
                              .getClienteSeleccionado();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Política de Pago',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Card(
                                color: colorScheme.surface,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      // Opción 1: Pago Anticipado 100%
                                      _buildPoliticaPagoOption(
                                        context,
                                        value: POLITICA_ANTICIPADO,
                                        titulo: 'Pago Anticipado (100%)',
                                        descripcion:
                                            'Pagar antes de la preparación del pedido',
                                        icono: Icons.money,
                                        colorScheme: colorScheme,
                                      ),
                                      const Divider(height: 24),

                                      // Opción 2: Pago Mitad-Mitad
                                      _buildPoliticaPagoOption(
                                        context,
                                        value: POLITICA_MEDIO_MEDIO,
                                        titulo: 'Pago Mitad-Mitad (50%-50%)',
                                        descripcion:
                                            '50% anticipado + 50% contra entrega',
                                        icono: Icons.balance,
                                        colorScheme: colorScheme,
                                      ),
                                      const Divider(height: 24),

                                      // Opción 3: Contra Entrega
                                      _buildPoliticaPagoOption(
                                        context,
                                        value: POLITICA_CONTRA_ENTREGA,
                                        titulo: 'Contra Entrega',
                                        descripcion:
                                            'Pagar al recibir el pedido',
                                        icono: Icons.local_shipping,
                                        colorScheme: colorScheme,
                                      ),
                                      const Divider(height: 24),

                                      // Opción 4: Crédito (solo si tiene permisos)
                                      if (clienteSeleccionado != null &&
                                          clienteSeleccionado
                                              .puedeAtenerCredito)
                                        _buildPoliticaPagoOption(
                                          context,
                                          value: POLITICA_CREDITO,
                                          titulo: 'Solicitar Crédito',
                                          descripcion:
                                              'Límite disponible: Bs. ${clienteSeleccionado.limiteCredito?.toStringAsFixed(2) ?? '0.00'}',
                                          icono: Icons.credit_card,
                                          color: Colors.green.shade500,
                                          colorScheme: colorScheme,
                                        )
                                      else if (clienteSeleccionado != null)
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(
                                              isDark ? 0.15 : 0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.orange.withOpacity(
                                                isDark ? 0.4 : 0.2,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                size: 18,
                                                color: Colors.orange.shade500,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'El cliente no tiene permisos para solicitar crédito',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        Colors.orange.shade500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          );
                        },
                      ),

                      // Resumen de montos
                      Text(
                        'Resumen',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Card(
                        color: colorScheme.surfaceVariant,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Subtotal',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Bs. ${carrito.subtotal.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              Divider(
                                height: 24,
                                color: colorScheme.outline.withAlpha(
                                  isDark ? 80 : 40,
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Bs. ${carrito.total.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4CAF50),
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
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
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
                backgroundColor: Color(0xFF4CAF50),
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

  /// ✅ Widget auxiliar para construir opciones de política de pago
  Widget _buildPoliticaPagoOption(
    BuildContext context, {
    required String value,
    required String titulo,
    required String descripcion,
    required IconData icono,
    Color? color,
    required ColorScheme colorScheme,
  }) {
    final isDark = context.isDark;
    final isSelected = _politicaPago == value;
    final displayColor = color ?? colorScheme.primary;

    return GestureDetector(
      onTap: () {
        setState(() {
          _politicaPago = value;
        });
      },
      child: Row(
        children: [
          Radio<String>(
            value: value,
            groupValue: _politicaPago,
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  _politicaPago = newValue;
                });
              }
            },
            activeColor: displayColor,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      icono,
                      size: 18,
                      color: isSelected
                          ? displayColor
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? displayColor
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Text(
                    descripcion,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
