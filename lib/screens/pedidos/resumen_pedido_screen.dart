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

  // ✅ NUEVO: Estado para turno de entrega
  String _turnoSeleccionado =
      'MORNING'; // MORNING (08:00-12:00) o AFTERNOON (14:00-18:00)
  int?
  _horaEspecificaSeleccionada; // Hora específica dentro del rango (8-12 o 14-18)
  static const String TURNO_MORNING = 'MORNING';
  static const String TURNO_AFTERNOON = 'AFTERNOON';

  // Política de pago
  String _politicaPago = 'CONTRA_ENTREGA'; // Default
  static const String POLITICA_ANTICIPADO = 'ANTICIPADO_100';
  static const String POLITICA_MEDIO_MEDIO = 'MEDIO_MEDIO';
  static const String POLITICA_CONTRA_ENTREGA = 'CONTRA_ENTREGA';
  static const String POLITICA_CREDITO = 'CREDITO';

  final PedidoService _pedidoService = PedidoService();
  final ProformaService _proformaService = ProformaService();

  @override
  void initState() {
    super.initState();
    // Inicializar fecha/hora por defecto
    final now = DateTime.now();
    _fechaProgramada = DateTime(now.year, now.month, now.day);

    // ✅ ACTUALIZADO: Inicializar turno MORNING y hora específica por defecto (08:00)
    _turnoSeleccionado = TURNO_MORNING;
    _horaEspecificaSeleccionada = 8; // Hora específica: 8 AM
    _horaInicio = const TimeOfDay(hour: 8, minute: 0);
    _horaFin = const TimeOfDay(hour: 8, minute: 0);

    // ✅ NUEVO: Cargar automáticamente la dirección principal del cliente
    _cargarDireccionPrincipal();
  }

  // ✅ NUEVO: Cargar automáticamente dirección principal
  void _cargarDireccionPrincipal() {
    try {
      final carritoProvider = context.read<CarritoProvider>();
      final cliente = carritoProvider.clienteSeleccionado;

      if (cliente == null ||
          cliente.direcciones == null ||
          cliente.direcciones!.isEmpty) {
        debugPrint('⚠️ [ResumenPedidoScreen] No hay direcciones disponibles');
        return;
      }

      // Buscar dirección principal
      final direccionPrincipal = cliente.direcciones!.firstWhere(
        (dir) => dir.esPrincipal == true,
        orElse: () => cliente
            .direcciones!
            .first, // Fallback a la primera si no hay principal
      );

      setState(() {
        _direccionSeleccionada = direccionPrincipal;
      });

      debugPrint(
        '✅ [ResumenPedidoScreen] Dirección principal seleccionada: ${direccionPrincipal.direccion}',
      );
    } catch (e) {
      debugPrint(
        '❌ [ResumenPedidoScreen] Error al cargar dirección principal: $e',
      );
    }
  }

  // ✅ Obtener cantidad de direcciones del cliente
  int _obtenerCantidadDirecciones() {
    try {
      final carritoProvider = context.read<CarritoProvider>();
      final cliente = carritoProvider.clienteSeleccionado;
      return cliente?.direcciones?.length ?? 0;
    } catch (e) {
      debugPrint('❌ Error al obtener cantidad de direcciones: $e');
      return 0;
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

  // ✅ Obtener fechas disponibles (Hoy, Mañana, Lunes)
  Map<String, DateTime> _obtenerFechasDisponibles() {
    final DateTime now = DateTime.now();
    final DateTime hoy = DateTime(now.year, now.month, now.day);
    final DateTime manana = hoy.add(const Duration(days: 1));

    final Map<String, DateTime> fechas = {'Hoy': hoy};

    if (manana.weekday < 7) {
      fechas['Mañana'] = manana;
    } else if (manana.weekday == 7) {
      fechas['Lunes'] = hoy.add(const Duration(days: 2));
    }

    return fechas;
  }

  // ✅ Verificar si la fecha es estándar
  bool _esFechaEstandar(DateTime fecha) {
    final fechasDisponibles = _obtenerFechasDisponibles();
    return fechasDisponibles.values.any(
      (f) =>
          f.year == fecha.year && f.month == fecha.month && f.day == fecha.day,
    );
  }

  // ✅ Seleccionar fecha personalizada
  Future<void> _seleccionarFechaPersonalizada() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaProgramada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Selecciona una fecha personalizada',
    );

    if (picked != null && mounted) {
      setState(() {
        _fechaProgramada = picked;
      });
    }
  }

  // ✅ Seleccionar hora inicio
  Future<void> _seleccionarHoraInicio() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horaInicio ?? TimeOfDay.now(),
      helpText: 'Hora de inicio',
    );

    if (picked != null && mounted) {
      setState(() {
        _horaInicio = picked;
      });
    }
  }

  // ✅ Seleccionar hora fin
  Future<void> _seleccionarHoraFin() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horaFin ?? TimeOfDay.now(),
      helpText: 'Hora de fin',
    );

    if (picked != null && mounted) {
      setState(() {
        _horaFin = picked;
      });
    }
  }

  // ✅ NUEVO: Actualizar turno y hora específica
  void _actualizarHorasPorTurno(String turno) {
    setState(() {
      _turnoSeleccionado = turno;
      // Resetear la hora específica seleccionada
      if (turno == TURNO_MORNING) {
        _horaEspecificaSeleccionada = 8;
        _horaInicio = const TimeOfDay(hour: 8, minute: 0);
      } else {
        _horaEspecificaSeleccionada = 14;
        _horaInicio = const TimeOfDay(hour: 14, minute: 0);
      }
    });
  }

  // ✅ Obtener rango de horas según turno
  List<int> _obtenerHorasDisponibles() {
    if (_turnoSeleccionado == TURNO_MORNING) {
      return [8, 9, 10, 11, 12];
    } else {
      return [14, 15, 16, 17, 18];
    }
  }

  // ✅ NUEVO: Verificar qué turnos están disponibles según la fecha y hora actual
  Map<String, bool> _obtenerTurnosDisponibles() {
    final ahora = DateTime.now();
    final esHoy = _fechaProgramada?.year == ahora.year &&
        _fechaProgramada?.month == ahora.month &&
        _fechaProgramada?.day == ahora.day;

    // Si NO es hoy, ambos turnos están disponibles
    if (!esHoy) {
      return {
        TURNO_MORNING: true,
        TURNO_AFTERNOON: true,
      };
    }

    // Si ES hoy, verificar cuales turnos aun estan disponibles
    // Turno MORNING: 8:00-12:00 -> no disponible si ya son las 12:00 o mas
    final morningDisponible = ahora.hour < 12;

    // Turno AFTERNOON: 14:00-18:00 -> no disponible si ya son las 18:00 o mas
    final afternoonDisponible = ahora.hour < 18;

    return {
      TURNO_MORNING: morningDisponible,
      TURNO_AFTERNOON: afternoonDisponible,
    };
  }

  // ✅ Formatear fecha
  String _formatearFecha(DateTime fecha) {
    final meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    final dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];

    final diaSemana = dias[fecha.weekday - 1];
    final dia = fecha.day;
    final mes = meses[fecha.month - 1];
    final anio = fecha.year;

    return '$diaSemana, $dia de $mes de $anio';
  }

  // ✅ Formatear hora
  String _formatearHora(TimeOfDay hora) {
    final hour = hora.hour.toString().padLeft(2, '0');
    final minute = hora.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _confirmarPedido() async {
    final carritoProvider = context.read<CarritoProvider>();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final esPreventista = user?.roles?.contains('preventista') ?? false;

    debugPrint('🚀 Usuario: ${user?.email}, esPreventista: $esPreventista');

    // ✅ Detectar si estamos editando una proforma existente
    final editandoProforma = carritoProvider.editandoProforma;
    final proformaId = carritoProvider.proformaEditandoId;

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
      // Validar que el usuario esté autenticado
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Dirección ID (null para PICKUP)
      int? direccionId;
      if (_tipoEntrega == 'DELIVERY') {
        direccionId = _direccionSeleccionada!.id;
      }

      // ✅ NUEVO: Si es preventista, usar lógica de proforma con combo items
      if (esPreventista) {
        final cliente = carritoProvider.clienteSeleccionado;
        if (cliente == null) {
          throw Exception('Error: Cliente no seleccionado');
        }

        // Obtener items con detalles de combo
        final items = carritoProvider.items.map((item) {
          final detalleConRango = carritoProvider.obtenerDetalleConRango(
            item.producto.id,
          );

          final precioUnitarioFinal =
              detalleConRango?.precioUnitario ?? item.precioUnitario;
          final subtotalFinal = precioUnitarioFinal * item.cantidad;

          return {
            'producto_id': item.producto.id,
            'cantidad': item.cantidad,
            'precio_unitario': precioUnitarioFinal,
            'subtotal': subtotalFinal,
            if (detalleConRango != null)
              'tipo_precio_id': detalleConRango.tipoPrecioId,
            if (detalleConRango != null)
              'tipo_precio_nombre': detalleConRango.tipoPrecioNombre,
            if (item.comboItemsSeleccionados != null)
              'combo_items_seleccionados': item.comboItemsSeleccionados,
          };
        }).toList();

        dynamic response;

        // ✅ NUEVO: Verificar si está editando o creando nueva proforma
        if (editandoProforma && proformaId != null) {
          debugPrint('✏️ Actualizando proforma #$proformaId...');

          response = await _proformaService.actualizarProforma(
            proformaId: proformaId,
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

          debugPrint('✅ Proforma actualizada');
        } else {
          debugPrint('➕ Creando nueva proforma para preventista...');

          response = await _proformaService.crearProforma(
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

          debugPrint('✅ Proforma creada');
        }

        setState(() {
          _isCreandoPedido = false;
        });

        if (response.success && response.data != null) {
          carritoProvider.limpiarCarrito();

          if (editandoProforma) {
            carritoProvider.limpiarProformaEditando();
            debugPrint('✅ Edición limpiada');
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
                        : editandoProforma
                        ? 'Error al actualizar la proforma'
                        : 'Error al crear la proforma',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } else {
        // ✅ Cliente logueado: usar lógica de pedido normal
        debugPrint('👤 Creando pedido para cliente logueado...');

        // Obtener items del carrito de forma normal
        final items = carritoProvider.getItemsParaPedido();

        // Determinar cliente ID
        final clienteIdUsuario = user.clienteId;
        if (clienteIdUsuario == null) {
          throw Exception(
            'No se pudo identificar al cliente. Asegúrate de estar correctamente autenticado.',
          );
        }

        // Obtener cliente
        final clientProvider = Provider.of<ClientProvider>(
          context,
          listen: false,
        );
        final clienteSeleccionado = await clientProvider.getClient(
          clienteIdUsuario,
        );

        if (clienteSeleccionado == null) {
          throw Exception(
            'No se pudieron cargar los datos del cliente. Por favor, intenta de nuevo.',
          );
        }

        // ✅ Validar política de pago
        debugPrint('💳 Política de pago seleccionada: $_politicaPago');

        if (_politicaPago == POLITICA_CREDITO) {
          if (!clienteSeleccionado.puedeAtenerCredito) {
            debugPrint('⚠️  Cliente NO tiene permisos de crédito');

            if (!mounted) return;
            final shouldContinue = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                title: const Text('Sin Permisos de Crédito'),
                content: Text(
                  'El cliente "${clienteSeleccionado.nombre}" no tiene permisos para solicitar crédito.\n\n'
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
          }
        }

        // ✅ Crear o actualizar pedido
        dynamic response;

        if (editandoProforma && proformaId != null) {
          response = await _pedidoService.actualizarProforma(
            proformaId: proformaId,
            clienteId: clienteIdUsuario,
            items: items,
            tipoEntrega: _tipoEntrega,
            fechaProgramada: _fechaProgramada ?? DateTime.now(),
            direccionId: direccionId,
            horaInicio: _horaInicio,
            horaFin: _horaFin,
            observaciones: _observaciones,
            politicaPago: _politicaPago,
          );

          debugPrint(
            '✅ Proforma actualizada - Política de pago: $_politicaPago',
          );
        } else {
          response = await _pedidoService.crearPedido(
            clienteId: clienteIdUsuario,
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    final carritoProvider = context.read<CarritoProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    final esPreventista = user?.roles?.contains('preventista') ?? false;

    final editandoProforma = carritoProvider.editandoProforma;
    final tituloResumen = esPreventista
        ? (editandoProforma ? 'Actualizar Proforma' : 'Crear Proforma')
        : (editandoProforma ? 'Actualizar Proforma' : 'Resumen del Pedido');

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
                                      fontSize: AppTextStyles.bodyLarge(
                                        context,
                                      ).fontSize!,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '#${carritoProvider.proformaEditando?.numero ?? 'N/A'} (ID: ${carritoProvider.proformaEditandoId ?? 'N/A'})',
                                    style: TextStyle(
                                      fontSize: AppTextStyles.bodySmall(
                                        context,
                                      ).fontSize!,
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
                          esPreventista ? 'Nueva Proforma' : 'Revisa tu pedido',
                          style: TextStyle(
                            fontSize: AppTextStyles.bodyLarge(
                              context,
                            ).fontSize!,
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
                          fontSize: AppTextStyles.bodyMedium(context).fontSize!,
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
                          fontSize: AppTextStyles.headlineSmall(
                            context,
                          ).fontSize!,
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
                                      child:
                                          item.producto.imagenes != null &&
                                              item.producto.imagenes!.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                item
                                                    .producto
                                                    .imagenes!
                                                    .first
                                                    .url,
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
                                                  fontSize:
                                                      AppTextStyles.bodySmall(
                                                        context,
                                                      ).fontSize!,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                '×${item.cantidad}',
                                                style: TextStyle(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                  fontSize:
                                                      AppTextStyles.bodySmall(
                                                        context,
                                                      ).fontSize!,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Bs. ${item.subtotal.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: AppTextStyles.bodyLarge(
                                              context,
                                            ).fontSize!,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'subtotal',
                                          style: TextStyle(
                                            fontSize: AppTextStyles.labelSmall(
                                              context,
                                            ).fontSize!,
                                            color: colorScheme.onSurfaceVariant,
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

                      // ✅ Sección de Crédito (solo si el cliente puede usar crédito)
                      Consumer<CarritoProvider>(
                        builder: (context, carritoProvider, _) {
                          final clienteSeleccionado = carritoProvider
                              .getClienteSeleccionado();
                          final usarCredito = _politicaPago == POLITICA_CREDITO;

                          // Solo mostrar si el cliente tiene crédito habilitado
                          if (clienteSeleccionado == null ||
                              !clienteSeleccionado.puedeAtenerCredito) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Card(
                                color: usarCredito
                                    ? Colors.green.shade50
                                    : colorScheme.surfaceVariant,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: usarCredito
                                      ? BorderSide(
                                          color: Colors.green.shade300,
                                          width: 2,
                                        )
                                      : BorderSide.none,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.credit_card,
                                        color: usarCredito
                                            ? Colors.green.shade600
                                            : colorScheme.onSurfaceVariant,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Solicitar Crédito',
                                              style: context
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: usarCredito
                                                        ? Colors.green.shade700
                                                        : colorScheme.onSurface,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Límite disponible: Bs. ${clienteSeleccionado.limiteCredito?.toStringAsFixed(2) ?? '0.00'}',
                                              style: context.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: usarCredito
                                                        ? Colors.green.shade600
                                                        : colorScheme
                                                              .onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Switch(
                                        value: usarCredito,
                                        activeColor: Colors.green.shade600,
                                        onChanged: (value) {
                                          setState(() {
                                            _politicaPago = value
                                                ? POLITICA_CREDITO
                                                : POLITICA_CONTRA_ENTREGA;
                                          });
                                        },
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
                          fontSize: AppTextStyles.headlineSmall(
                            context,
                          ).fontSize!,
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
                                  fontSize: AppTextStyles.headlineMedium(
                                    context,
                                  ).fontSize!,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'Bs. ${carrito.total.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: AppTextStyles.headlineMedium(
                                    context,
                                  ).fontSize!,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (carritoProvider
                              .clienteSeleccionado
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
                      style: TextStyle(
                        fontSize: AppTextStyles.bodyLarge(context).fontSize!,
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
              Icon(Icons.person_outline, color: colorScheme.primary, size: 20),
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
            fontSize: AppTextStyles.headlineSmall(context).fontSize!,
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
            fontSize: AppTextStyles.bodyMedium(context).fontSize!,
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
    final cantidadDirecciones = _obtenerCantidadDirecciones();

    // 1️⃣ SIN DIRECCIONES: Mostrar advertencia para registrar
    if (cantidadDirecciones == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dirección de Entrega',
            style: TextStyle(
              fontSize: AppTextStyles.headlineSmall(context).fontSize!,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: colorScheme.error,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sin dirección registrada',
                              style: context.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Registra una dirección para continuar',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final carritoProvider = context.read<CarritoProvider>();
                        final cliente = carritoProvider.clienteSeleccionado;

                        if (cliente != null) {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DireccionFormScreenForClient(
                                        clientId: cliente.id,
                                      ),
                                ),
                              )
                              .then((_) {
                                _cargarDireccionPrincipal();
                                setState(() {});
                              });
                        }
                      },
                      icon: const Icon(Icons.add_location),
                      label: const Text('Registrar Dirección'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // 2️⃣ UNA DIRECCIÓN: No mostrar nada, usar automáticamente
    if (cantidadDirecciones == 1) {
      return const SizedBox.shrink();
    }

    // 3️⃣ 2+ DIRECCIONES: Mostrar selector
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dirección de Entrega',
          style: TextStyle(
            fontSize: AppTextStyles.headlineSmall(context).fontSize!,
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
                        final carritoProvider = context.read<CarritoProvider>();
                        final cliente = carritoProvider.clienteSeleccionado;

                        if (cliente != null) {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DireccionFormScreenForClient(
                                        clientId: cliente.id,
                                      ),
                                ),
                              )
                              .then((_) {
                                _cargarDireccionPrincipal();
                                setState(() {});
                              });
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
  // ✅ Widget: Selector Fecha/Hora Expandido
  Widget _buildFechaHoraSection() {
    final colorScheme = context.colorScheme;
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    final esPreventista = user?.roles?.contains('preventista') ?? false;
    final fechasDisponibles = _obtenerFechasDisponibles();

    bool usarFechaPersonalizada = false;
    if (_fechaProgramada != null) {
      usarFechaPersonalizada = !_esFechaEstandar(_fechaProgramada!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título con toggle de fecha personalizada
        Row(
          children: [
            Expanded(
              child: Text(
                'Fecha y Hora de Entrega',
                style: TextStyle(
                  fontSize: AppTextStyles.headlineSmall(context).fontSize!,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            // ✅ Toggle para preventistas
            if (esPreventista)
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Otra fecha',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: usarFechaPersonalizada,
                      onChanged: (value) {
                        setState(() {
                          if (value) {
                            _seleccionarFechaPersonalizada();
                          } else {
                            final now = DateTime.now();
                            _fechaProgramada = DateTime(
                              now.year,
                              now.month,
                              now.day,
                            );
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // ✅ SECCIÓN 1: Fechas estándar
        if (!usarFechaPersonalizada) ...[
          Text(
            'Selecciona una fecha',
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: fechasDisponibles.entries.toList().asMap().entries.map((indexedEntry) {
              final index = indexedEntry.key;
              final entry = indexedEntry.value;
              final isLast = index == fechasDisponibles.length - 1;

              final nombreFecha = entry.key;
              final fecha = entry.value;
              final isSelected =
                  _fechaProgramada?.year == fecha.year &&
                  _fechaProgramada?.month == fecha.month &&
                  _fechaProgramada?.day == fecha.day;

              final diasSemana = [
                'Lunes',
                'Martes',
                'Miércoles',
                'Jueves',
                'Viernes',
                'Sábado',
                'Domingo',
              ];
              final nombreDia = diasSemana[fecha.weekday - 1];
              final fechaFormato = '${fecha.day}/${fecha.month}';

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 8),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _fechaProgramada = fecha;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected
                          ? colorScheme.primary
                          : colorScheme.surfaceVariant,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          nombreFecha,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '$nombreDia\n$fechaFormato',
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // ✅ NUEVO: Sección de Turno de Entrega
          Text(
            'Selecciona un turno',
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (context) {
                    final turnosDisponibles = _obtenerTurnosDisponibles();
                    final morningDisponible =
                        turnosDisponibles[TURNO_MORNING] ?? false;

                    return Opacity(
                      opacity: morningDisponible ? 1.0 : 0.5,
                      child: ElevatedButton.icon(
                        onPressed: morningDisponible
                            ? () => _actualizarHorasPorTurno(TURNO_MORNING)
                            : null,
                        icon: const Icon(Icons.sunny),
                        label: const Text('Mañana\n8:00 - 12:00'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _turnoSeleccionado == TURNO_MORNING
                              ? Colors.orange.shade500
                              : colorScheme.surfaceVariant,
                          foregroundColor: _turnoSeleccionado == TURNO_MORNING
                              ? Colors.white
                              : colorScheme.onSurface,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final turnosDisponibles = _obtenerTurnosDisponibles();
                    final tardeDisponible =
                        turnosDisponibles[TURNO_AFTERNOON] ?? false;

                    return Opacity(
                      opacity: tardeDisponible ? 1.0 : 0.5,
                      child: ElevatedButton.icon(
                        onPressed: tardeDisponible
                            ? () => _actualizarHorasPorTurno(TURNO_AFTERNOON)
                            : null,
                        icon: const Icon(Icons.wb_twilight),
                        label: const Text('Tarde\n14:00 - 18:00'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _turnoSeleccionado == TURNO_AFTERNOON
                              ? Colors.purple.shade500
                              : colorScheme.surfaceVariant,
                          foregroundColor: _turnoSeleccionado == TURNO_AFTERNOON
                              ? Colors.white
                              : colorScheme.onSurface,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ✅ NUEVO: Mostrar aviso si no hay turnos disponibles para hoy
          Builder(
            builder: (context) {
              final turnosDisponibles = _obtenerTurnosDisponibles();
              final esHoy = _fechaProgramada?.year == DateTime.now().year &&
                  _fechaProgramada?.month == DateTime.now().month &&
                  _fechaProgramada?.day == DateTime.now().day;
              final hayAlgunDisponible = turnosDisponibles.values.any((v) => v);

              if (esHoy && !hayAlgunDisponible) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Es muy tarde para hoy. Por favor, selecciona mañana o una fecha posterior.',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize:
                                AppTextStyles.bodySmall(context).fontSize!,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (esHoy && !turnosDisponibles[TURNO_MORNING]!) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    border: Border.all(color: Colors.amber.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_rounded,
                        color: Colors.amber.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'El turno matutino ya no está disponible. Solo puedes elegir el turno de la tarde.',
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontSize:
                                AppTextStyles.bodySmall(context).fontSize!,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 16),

          // ✅ Mostrar horas del turno seleccionado
          /* Card(
            color: colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Horario: ${_formatearHora(_horaInicio!)} - ${_formatearHora(_horaFin!)}',
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Ajustable',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ), */
        ] else ...[
          // ✅ SECCIÓN 2: Fecha personalizada (preventistas)
          Text(
            'Fecha seleccionada',
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _seleccionarFechaPersonalizada,
            child: Card(
              color: colorScheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _fechaProgramada != null
                            ? _formatearFecha(_fechaProgramada!)
                            : 'Seleccionar fecha',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Icon(Icons.edit, color: colorScheme.primary, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),

        // ✅ SECCIÓN 3: Seleccionar Hora Específica
        Text(
          'Selecciona la hora',
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _obtenerHorasDisponibles().map((hora) {
            final isSelected = _horaEspecificaSeleccionada == hora;
            return ElevatedButton(
              onPressed: () {
                setState(() {
                  _horaEspecificaSeleccionada = hora;
                  _horaInicio = TimeOfDay(hour: hora, minute: 0);
                  _horaFin = TimeOfDay(hour: hora, minute: 0);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected
                    ? colorScheme.primary
                    : colorScheme.surfaceVariant,
                foregroundColor: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: Text(
                '$hora:00',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // ✅ SECCIÓN 4: Observaciones
        Text(
          'Observaciones (Opcional)',
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: 'Ej: Entregar entre semana, no sábado...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.all(12),
          ),
          maxLines: 2,
          onChanged: (value) {
            setState(() {
              _observaciones = value;
            });
          },
          controller: TextEditingController(text: _observaciones),
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
                          fontSize: AppTextStyles.bodyMedium(context).fontSize!,
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
                      fontSize: AppTextStyles.bodySmall(context).fontSize!,
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
    final porcentajeUsado = limiteCredito > 0
        ? (creditoUtilizado / limiteCredito) * 100
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        color: Colors.blue.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.blue.shade200, width: 1),
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
                      fontSize: AppTextStyles.bodyMedium(context).fontSize!,
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
                      fontSize: AppTextStyles.bodySmall(context).fontSize!,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  Text(
                    'Bs. ${limiteCredito.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: AppTextStyles.bodySmall(context).fontSize!,
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
                      fontSize: AppTextStyles.bodySmall(context).fontSize!,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  Text(
                    'Bs. ${creditoUtilizado.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: AppTextStyles.bodySmall(context).fontSize!,
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
                      fontSize: AppTextStyles.bodySmall(context).fontSize!,
                      fontWeight: FontWeight.bold,
                      color: creditoDisponible > 0
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                  Text(
                    'Bs. ${creditoDisponible.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: AppTextStyles.bodySmall(context).fontSize!,
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

  // ✅ NUEVO: Mostrar detalles de los items incluidos en un combo
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
                      fontSize: AppTextStyles.bodySmall(context).fontSize!,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.blue.shade200)),
            ),
            child: Column(
              children: comboItems.asMap().entries.map((entry) {
                final index = entry.key;
                final comboItem = entry.value;
                // ✅ Convertir cantidad de forma segura (puede ser int o double)
                final cantidadRaw = comboItem['cantidad'] ?? 1;
                final cantidad = cantidadRaw is int
                    ? cantidadRaw
                    : (cantidadRaw as num).toInt();
                final comboItemId = comboItem['combo_item_id'] ?? 0;
                final nombreProducto =
                    obtenerNombreComboItem(comboItemId) ?? 'Producto';
                final isLast = index == comboItems.length - 1;

                // Mostrar cantidad total si el combo tiene cantidad > 1
                final cantidadTotal = cantidad * item.cantidad;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(
                            bottom: BorderSide(color: Colors.blue.shade100),
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
                                fontSize: AppTextStyles.bodySmall(
                                  context,
                                ).fontSize!,
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
                                fontSize: AppTextStyles.labelSmall(
                                  context,
                                ).fontSize!,
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
                                fontSize: AppTextStyles.bodySmall(
                                  context,
                                ).fontSize!,
                              ),
                            ),
                          ),
                          if (item.cantidad > 1)
                            Text(
                              '($cantidad×${item.cantidad})',
                              style: TextStyle(
                                fontSize: AppTextStyles.labelSmall(
                                  context,
                                ).fontSize!,
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
