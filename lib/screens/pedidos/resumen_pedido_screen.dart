import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';
import '../../widgets/pedidos/direccion_selector_modal.dart';
import '../../widgets/pedidos/fecha_hora_selector_modal.dart';
import '../../config/config.dart';
import '../../extensions/theme_extension.dart';

class ResumenPedidoScreen extends StatefulWidget {
  const ResumenPedidoScreen({super.key});

  @override
  State<ResumenPedidoScreen> createState() => _ResumenPedidoScreenState();
}

class _ResumenPedidoScreenState extends State<ResumenPedidoScreen> {
  bool _isCreandoPedido = false;

  // ✅ Estado interno para tipo de entrega y datos relacionados
  String _tipoEntrega = 'DELIVERY'; // Default
  ClientAddress? _direccionSeleccionada;
  DateTime? _fechaProgramada;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  String _observaciones = '';

  // Política de pago
  String _politicaPago = 'CONTRA_ENTREGA'; // Default
  static const String POLITICA_ANTICIPADO = 'ANTICIPADO_100';
  static const String POLITICA_MEDIO_MEDIO = 'MEDIO_MEDIO';
  static const String POLITICA_CONTRA_ENTREGA = 'CONTRA_ENTREGA';
  static const String POLITICA_CREDITO = 'CREDITO';

  final PedidoService _pedidoService = PedidoService();

  @override
  void initState() {
    super.initState();
    // Inicializar fecha/hora por defecto
    final now = DateTime.now();
    _fechaProgramada = DateTime(now.year, now.month, now.day);
    _horaInicio = const TimeOfDay(hour: 9, minute: 0);
    _horaFin = const TimeOfDay(hour: 17, minute: 0);

    // ✅ NUEVO: Cargar automáticamente la dirección principal del cliente
    _cargarDireccionPrincipal();
  }

  // ✅ NUEVO: Cargar automáticamente dirección principal
  void _cargarDireccionPrincipal() {
    try {
      final carritoProvider = context.read<CarritoProvider>();
      final cliente = carritoProvider.clienteSeleccionado;

      if (cliente == null || cliente.direcciones == null || cliente.direcciones!.isEmpty) {
        debugPrint('⚠️ [ResumenPedidoScreen] No hay direcciones disponibles');
        return;
      }

      // Buscar dirección principal
      final direccionPrincipal = cliente.direcciones!
          .firstWhere(
            (dir) => dir.esPrincipal == true,
            orElse: () => cliente.direcciones!.first, // Fallback a la primera si no hay principal
          );

      setState(() {
        _direccionSeleccionada = direccionPrincipal;
      });

      debugPrint(
        '✅ [ResumenPedidoScreen] Dirección principal seleccionada: ${direccionPrincipal.direccion}',
      );
    } catch (e) {
      debugPrint('❌ [ResumenPedidoScreen] Error al cargar dirección principal: $e');
    }
  }

  // ✅ Mostrar selector de dirección como modal
  void _mostrarSelectorDireccion() async {
    final carritoProvider = context.read<CarritoProvider>();
    final cliente = carritoProvider.clienteSeleccionado;

    if (cliente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Cliente no cargado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final resultado = await showModalBottomSheet<ClientAddress>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) => DireccionSelectorModal(
        cliente: cliente,
        direccionInicial: _direccionSeleccionada,
      ),
    );

    if (resultado != null) {
      setState(() {
        _direccionSeleccionada = resultado;
      });
    }
  }

  // ✅ Mostrar selector de fecha/hora como dialog
  void _mostrarSelectorFechaHora() async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => FechaHoraSelectorModal(
        fechaInicial: _fechaProgramada,
        horaInicioInicial: _horaInicio,
        horaFinInicial: _horaFin,
        observacionesInicial: _observaciones,
      ),
    );

    if (resultado != null && mounted) {
      setState(() {
        _fechaProgramada = resultado['fecha'];
        _horaInicio = resultado['horaInicio'];
        _horaFin = resultado['horaFin'];
        _observaciones = resultado['observaciones'] ?? '';
      });
    }
  }

  Future<void> _confirmarPedido() async {
    final carritoProvider = context.read<CarritoProvider>();
    debugPrint(
      '🚀 cliente cargado ${carritoProvider.getClienteSeleccionadoId()}',
    );

    // ✅ Detectar si estamos editando una proforma existente
    final editandoProforma = carritoProvider.editandoProforma;
    final proformaId = carritoProvider.proformaEditandoId;

    if (editandoProforma && proformaId != null) {
      debugPrint('✏️ MODO EDICIÓN: Actualizando proforma #$proformaId');
    } else {
      debugPrint('➕ MODO CREACIÓN: Creando nueva proforma');
    }

    if (carritoProvider.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El carrito está vacío'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ Validación: Si es DELIVERY, dirección es obligatoria
    if (_tipoEntrega == 'DELIVERY' && _direccionSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar una dirección de entrega'),
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

      // Dirección ID (null para PICKUP)
      int? direccionId;
      if (_tipoEntrega == 'DELIVERY') {
        direccionId = _direccionSeleccionada!.id;
      }

      // Determinar cliente ID
      final clienteIdUsuario = authProvider.user!.clienteId;
      final carritoClienteId = carritoProvider.getClienteSeleccionadoId();

      late int clienteIdParaPedido;
      bool esClienteLogueado = false;
      bool esPreventista = false;

      if (clienteIdUsuario != null) {
        clienteIdParaPedido = clienteIdUsuario;
        esClienteLogueado = true;
        debugPrint('👤 Creador: CLIENTE logueado (ID: $clienteIdUsuario)');
      } else if (carritoClienteId != null) {
        clienteIdParaPedido = carritoClienteId;
        esPreventista = true;
        debugPrint(
          '👨‍💼 Creador: PREVENTISTA para cliente (ID: $carritoClienteId)',
        );
      } else {
        throw Exception(
          'No se pudo identificar al cliente. Asegúrate de estar correctamente autenticado.',
        );
      }

      // Obtener cliente
      Client? clienteSeleccionado;

      if (esClienteLogueado) {
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

      // ✅ Validar política de pago
      debugPrint('💳 Política de pago seleccionada: $_politicaPago');

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

      // ✅ Crear o actualizar proforma
      dynamic response;

      if (editandoProforma && proformaId != null) {
        debugPrint(
          '📝 Actualizando proforma #$proformaId con los nuevos datos...',
        );

        response = await _pedidoService.actualizarProforma(
          proformaId: proformaId,
          clienteId: clienteIdParaPedido,
          items: items,
          tipoEntrega: _tipoEntrega,
          fechaProgramada: _fechaProgramada ?? DateTime.now(),
          direccionId: direccionId,
          horaInicio: _horaInicio,
          horaFin: _horaFin,
          observaciones: _observaciones,
          politicaPago: _politicaPago,
        );

        debugPrint('✅ Proforma actualizada - Política de pago: $_politicaPago');
      } else {
        debugPrint('➕ Creando nueva proforma...');

        response = await _pedidoService.crearPedido(
          clienteId: clienteIdParaPedido,
          items: items,
          tipoEntrega: _tipoEntrega,
          fechaProgramada: _fechaProgramada ?? DateTime.now(),
          direccionId: direccionId,
          horaInicio: _horaInicio,
          horaFin: _horaFin,
          observaciones: _observaciones,
          politicaPago: _politicaPago,
        );

        debugPrint('✅ Pedido creado - Política de pago: $_politicaPago');
      }

      setState(() {
        _isCreandoPedido = false;
      });

      if (response.success && response.data != null) {
        carritoProvider.limpiarCarrito();

        if (editandoProforma) {
          carritoProvider.limpiarProformaEditando();
          debugPrint('✅ Estado de edición limpiado');
        }

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/pedido-creado',
            (route) => route.isFirst,
            arguments: {
              'pedido': response.data,
              'esActualizacion': editandoProforma,
            },
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.message.isNotEmpty
                    ? response.message
                    : editandoProforma
                    ? 'Error al actualizar la proforma'
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

  // ✅ Métodos auxiliares de formato
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

    final carritoProvider = context.read<CarritoProvider>();
    final editandoProforma = carritoProvider.editandoProforma;
    final tituloResumen =
        editandoProforma ? 'Actualizar Proforma' : 'Resumen del Pedido';

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: tituloResumen,
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
                      if (editandoProforma) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.edit_document,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Actualizando Proforma',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '#${carritoProvider.proformaEditando?.numero ?? 'N/A'} (ID: ${carritoProvider.proformaEditandoId ?? 'N/A'})',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          'Revisa tu pedido',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        editandoProforma
                            ? 'Verifica los cambios antes de actualizar'
                            : 'Verifica que todo esté correcto antes de confirmar',
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
                      // ✅ NUEVO: Sección Información del Cliente
                      _buildClienteInfoSection(context, carritoProvider),
                      const SizedBox(height: 24),

                      // ✅ NUEVO: Selector de Tipo de Entrega
                      _buildTipoEntregaSelector(),
                      const SizedBox(height: 24),

                      // ✅ NUEVO: Selector de Dirección (solo si DELIVERY)
                      if (_tipoEntrega == 'DELIVERY') ...[
                        _buildDireccionSection(),
                        const SizedBox(height: 24),
                      ],

                      // ✅ NUEVO: Selector de Fecha/Hora
                      _buildFechaHoraSection(),
                      const SizedBox(height: 24),

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
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(
                                            'Precio: Bs. ${(item.subtotal / item.cantidad).toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: colorScheme.primary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '×${item.cantidad}',
                                            style: TextStyle(
                                              color: colorScheme
                                                  .onSurfaceVariant,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Bs. ${item.subtotal.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'subtotal',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        ),
                      ),

                      if (carritoProvider.clienteSeleccionado
                              ?.puedeAtenerCredito ??
                          false)
                        _buildCreditSummaryCard(
                          carritoProvider.clienteSeleccionado!,
                          colorScheme,
                          isDark,
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
                  : Text(
                      editandoProforma
                          ? 'Actualizar Proforma'
                          : 'Confirmar Pedido',
                      style: const TextStyle(
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

  // ✅ Widget: Información del Cliente
  Widget _buildClienteInfoSection(
    BuildContext context,
    CarritoProvider carritoProvider,
  ) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    final cliente = carritoProvider.clienteSeleccionado;

    if (cliente == null) {
      return SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(isDark ? 0.3 : 0.1),
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
                Icons.person_outline,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Información del Cliente',
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cliente',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cliente.nombre,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (cliente.telefono != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teléfono',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cliente.telefono ?? '-',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),

          if (cliente.puedeAtenerCredito == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: const Color(0xFF4CAF50),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cliente con crédito disponible',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF4CAF50),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ Widget: Selector Tipo de Entrega
  Widget _buildTipoEntregaSelector() {
    final colorScheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Entrega',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTipoEntregaChip(
                'DELIVERY',
                '🚚 Delivery',
                const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTipoEntregaChip(
                'PICKUP',
                '🏪 Retiro',
                const Color(0xFFFFC107),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTipoEntregaChip(String value, String label, Color color) {
    final isSelected = _tipoEntrega == value;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _tipoEntrega = value;
          if (value == 'PICKUP') {
            _direccionSeleccionada = null;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? color : colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ✅ Widget: Selector Dirección
  Widget _buildDireccionSection() {
    final colorScheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dirección de Entrega',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        if (_direccionSeleccionada == null)
          GestureDetector(
            onTap: _mostrarSelectorDireccion,
            child: Card(
              color: colorScheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Seleccionar dirección',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Column(
            children: [
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _direccionSeleccionada!.direccion,
                              style: context.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_direccionSeleccionada!.ciudad != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Ciudad: ${_direccionSeleccionada!.ciudad}',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
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
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _mostrarSelectorDireccion,
                  icon: const Icon(Icons.edit),
                  label: const Text('Cambiar Dirección'),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ✅ Widget: Selector Fecha/Hora
  Widget _buildFechaHoraSection() {
    final colorScheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha y Hora de Entrega',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _mostrarSelectorFechaHora,
          child: Card(
            color: colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fechaProgramada != null
                              ? _formatearFecha(_fechaProgramada!)
                              : 'Seleccionar fecha',
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (_horaInicio != null && _horaFin != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '🕐 ${_formatearHora(_horaInicio!)} - ${_formatearHora(_horaFin!)}',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ✅ Widget auxiliar: Opción de Política de Pago
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

  // ✅ Widget: Resumen de Crédito
  Widget _buildCreditSummaryCard(
    Client cliente,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final limiteCredito = cliente.limiteCredito ?? 0.0;
    final creditoUtilizado = cliente.creditoUtilizado ?? 0.0;
    final creditoDisponible = limiteCredito - creditoUtilizado;
    final porcentajeUsado = limiteCredito > 0 ? (creditoUtilizado / limiteCredito) * 100 : 0.0;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        color: Colors.blue.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.blue.shade200,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.credit_card,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Resumen de Crédito',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Límite de Crédito',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  Text(
                    'Bs. ${limiteCredito.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Utilizado',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  Text(
                    'Bs. ${creditoUtilizado.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: porcentajeUsado / 100,
                  minHeight: 8,
                  backgroundColor: Colors.blue.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    porcentajeUsado > 80
                        ? Colors.red.shade500
                        : porcentajeUsado > 50
                        ? Colors.orange.shade500
                        : Colors.green.shade500,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Disponible',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: creditoDisponible > 0
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                  Text(
                    'Bs. ${creditoDisponible.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: creditoDisponible > 0
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
