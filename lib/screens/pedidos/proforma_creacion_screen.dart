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
import '../clients/direccion_form_screen_for_client.dart';

/// 🎯 Pantalla de creación de proformas (Preventistas)
///
/// Adaptado de ResumenPedidoScreen con soporte para combos.
/// El backend valida automáticamente COMBO vs SIMPLE products.
class ProformaCreacionScreen extends StatefulWidget {
  const ProformaCreacionScreen({super.key});

  @override
  State<ProformaCreacionScreen> createState() => _ProformaCreacionScreenState();
}

class _ProformaCreacionScreenState extends State<ProformaCreacionScreen> {
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

  final ProformaService _proformaService = ProformaService();

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
        debugPrint('⚠️ [ProformaCreacionScreen] No hay direcciones disponibles');
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
        '✅ [ProformaCreacionScreen] Dirección principal seleccionada: ${direccionPrincipal.direccion}',
      );
    } catch (e) {
      debugPrint('❌ [ProformaCreacionScreen] Error al cargar dirección principal: $e');
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

  Future<void> _confirmarProforma() async {
    final carritoProvider = context.read<CarritoProvider>();
    final cliente = carritoProvider.clienteSeleccionado;

    debugPrint('🎯 Creando proforma para cliente: ${cliente?.nombre}');

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

    if (cliente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Cliente no seleccionado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreandoPedido = true;
    });

    try {
      // Obtener items del carrito - Usar producto.id directamente
      // ✅ NUEVO: Incluir combo_items_seleccionados en el payload
      final items = carritoProvider.items.map((item) {
        return {
          'producto_id': item.producto.id,
          'cantidad': item.cantidad,
          'precio_unitario': item.precioUnitario,
          if (item.comboItemsSeleccionados != null)
            'combo_items_seleccionados': item.comboItemsSeleccionados,
        };
      }).toList();

      // Dirección ID (null para PICKUP)
      int? direccionId;
      if (_tipoEntrega == 'DELIVERY') {
        direccionId = _direccionSeleccionada!.id;
      }

      debugPrint('📝 Creando proforma con ${items.length} productos');
      debugPrint('   Cliente: ${cliente.nombre} (ID: ${cliente.id})');
      debugPrint('   Tipo entrega: $_tipoEntrega');
      debugPrint('   Política pago: $_politicaPago');

      // ✅ DEBUG: Mostrar items con combo_items_seleccionados
      for (var i = 0; i < items.length; i++) {
        debugPrint('   📦 Producto ${i+1}: ID ${items[i]['producto_id']}, Combo items: ${items[i]['combo_items_seleccionados']}');
      }

      final response = await _proformaService.crearProforma(
        clienteId: cliente.id,
        items: items,
        tipoEntrega: _tipoEntrega,
        fechaProgramada: _fechaProgramada ?? DateTime.now(),
        direccionId: direccionId,
        horaInicio: _horaInicio,
        horaFin: _horaFin,
        observaciones: _observaciones.isNotEmpty ? _observaciones : null,
        politicaPago: _politicaPago,
      );

      setState(() {
        _isCreandoPedido = false;
      });

      if (response.success && response.data != null) {
        carritoProvider.limpiarCarrito();

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/pedido-creado',
            (route) => route.isFirst,
            arguments: {
              'pedido': response.data,
              'esActualizacion': false,
            },
          );
        }
      } else {
        if (mounted) {
          // 🔴 Si es error de stock, mostrar un Dialog con más detalles
          if (response.message.contains('Stock insuficiente')) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('❌ Stock Insuficiente'),
                content: Text(response.message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Ajustar cantidad'),
                  ),
                ],
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  response.message.isNotEmpty
                      ? response.message
                      : 'Error al crear la proforma',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
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

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: 'Crear Proforma',
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
                        'Nueva Proforma',
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
                      // ✅ Sección Información del Cliente
                      _buildClienteInfoSection(context, carritoProvider),
                      const SizedBox(height: 24),

                      // ✅ Selector de Tipo de Entrega
                      _buildTipoEntregaSelector(),
                      const SizedBox(height: 24),

                      // ✅ Selector de Dirección (solo si DELIVERY)
                      if (_tipoEntrega == 'DELIVERY') ...[
                        _buildDireccionSection(),
                        const SizedBox(height: 24),
                      ],

                      // ✅ Selector de Fecha/Hora
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
                        (item) => Column(
                          children: [
                            Card(
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
                                      child: item.producto.imagenes != null &&
                                              item.producto.imagenes!.isNotEmpty
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
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Precio: Bs. ${(item.subtotal / item.cantidad).toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: colorScheme.primary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
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

                            // ✅ NUEVO: Mostrar detalles del combo si tiene items seleccionados
                            if (item.producto.esCombo &&
                                item.comboItemsSeleccionados != null &&
                                item.comboItemsSeleccionados!.isNotEmpty)
                              _buildComboDetallesSection(item, colorScheme),
                          ],
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
              onPressed: _isCreandoPedido ? null : _confirmarProforma,
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
                      'Crear Proforma',
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

  // ✅ Widget: Información del Cliente
  Widget _buildClienteInfoSection(
    BuildContext context,
    CarritoProvider carritoProvider,
  ) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    final cliente = carritoProvider.clienteSeleccionado;

    if (cliente == null) {
      return const SizedBox.shrink();
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
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _mostrarSelectorDireccion,
                      icon: const Icon(Icons.edit),
                      label: const Text('Cambiar Dirección'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Obtener el cliente seleccionado
                        final carritoProvider = context.read<CarritoProvider>();
                        final cliente = carritoProvider.clienteSeleccionado;

                        if (cliente != null) {
                          // Navegar a crear nueva dirección
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DireccionFormScreenForClient(
                                clientId: cliente.id,
                              ),
                            ),
                          ).then((_) {
                            // Recargar direcciones después de crear una nueva
                            _cargarDireccionPrincipal();
                          });
                        } else {
                          debugPrint('⚠️ No hay cliente seleccionado');
                        }
                      },
                      icon: const Icon(Icons.add_location),
                      label: const Text('+Crear Dirección'),
                    ),
                  ),
                ],
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

  // ✅ NUEVO: Mostrar detalles de componentes del combo
  Widget _buildComboDetallesSection(CarritoItem item, ColorScheme colorScheme) {
    final comboItems = item.comboItemsSeleccionados ?? [];

    // Obtener nombres de los productos desde el combo
    final comboItemsDelProducto = item.producto.comboItems ?? [];

    String? obtenerNombreComboItem(int comboItemId) {
      try {
        return comboItemsDelProducto
            .firstWhere((c) => c.id == comboItemId)
            .productoNombre;
      } catch (e) {
        return null;
      }
    }

    return Container(
      margin: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_cart_checkout,
                  color: Colors.blue.shade600,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Componentes - ${item.cantidad} combo${item.cantidad > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.blue.shade200),
              ),
            ),
            child: Column(
              children: comboItems.asMap().entries.map((entry) {
                final index = entry.key;
                final comboItem = entry.value;
                // ✅ Convertir cantidad de forma segura (puede ser int o double)
                final cantidadRaw = comboItem['cantidad'] ?? 1;
                final cantidad = cantidadRaw is int ? cantidadRaw : (cantidadRaw as num).toInt();
                final comboItemId = comboItem['combo_item_id'] ?? 0;
                final nombreProducto = obtenerNombreComboItem(comboItemId) ?? 'Producto';
                final isLast = index == comboItems.length - 1;

                // Mostrar cantidad total si el combo tiene cantidad > 1
                final cantidadTotal = cantidad * item.cantidad;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(
                            bottom: BorderSide(
                              color: Colors.blue.shade100,
                            ),
                          ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• $nombreProducto',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue.shade900,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID: ${comboItem['producto_id']}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${cantidadTotal}x',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (item.cantidad > 1)
                            Text(
                              '($cantidad×${item.cantidad})',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue.shade600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
