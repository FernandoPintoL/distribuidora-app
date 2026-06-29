import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';
import '../../widgets/pedidos/direccion_selector_modal.dart';
import '../../config/config.dart';
import '../../extensions/theme_extension.dart';
import '../../utils/date_picker_utils.dart';
import 'widgets/cliente_info_widget.dart';
import 'widgets/tipo_entrega_widget.dart';
import 'widgets/direccion_widget.dart';
import 'widgets/fecha_hora_widget.dart';
import 'widgets/credit_summary_widget.dart';
import '../../widgets/carrito/carrito_item_card.dart';

class ResumenPedidoScreen extends StatefulWidget {
  const ResumenPedidoScreen({super.key});

  @override
  State<ResumenPedidoScreen> createState() => _ResumenPedidoScreenState();
}

class _ResumenPedidoScreenState extends State<ResumenPedidoScreen> {
  bool _isCreandoPedido = false;

  // âœ… Estado interno para tipo de entrega y datos relacionados
  String _tipoEntrega = 'DELIVERY'; // Default
  ClientAddress? _direccionSeleccionada;
  DateTime? _fechaProgramada;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  String _observaciones = '';

  // âœ… NUEVO: Estado para turno de entrega
  String _turnoSeleccionado =
      'MORNING'; // MORNING (08:00-12:00) o AFTERNOON (14:00-18:00)
  int?
  _horaEspecificaSeleccionada; // Hora especÃ­fica dentro del rango (8-12 o 14-18)
  static const String TURNO_MORNING = 'MORNING';
  static const String TURNO_AFTERNOON = 'AFTERNOON';

  // PolÃ­tica de pago
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

    // âœ… ACTUALIZADO: Inicializar turno MORNING y hora especÃ­fica por defecto (08:00)
    _turnoSeleccionado = DateTimeUtilService.TURNO_MORNING;
    _horaEspecificaSeleccionada = 8; // Hora especÃ­fica: 8 AM
    _horaInicio = const TimeOfDay(hour: 8, minute: 0);
    _horaFin = const TimeOfDay(hour: 8, minute: 0);

    // âœ… NUEVO: Cargar automÃ¡ticamente la direcciÃ³n principal del cliente
    _cargarDireccionPrincipal();
  }

  // âœ… NUEVO: Cargar automÃ¡ticamente direcciÃ³n principal
  void _cargarDireccionPrincipal() {
    try {
      final carritoProvider = context.read<CarritoProvider>();
      final cliente = carritoProvider.clienteSeleccionado;

      if (cliente == null ||
          cliente.direcciones == null ||
          cliente.direcciones!.isEmpty) {
        debugPrint(
          'âš ï¸ [ResumenPedidoScreen] No hay direcciones disponibles',
        );
        return;
      }

      // Buscar direcciÃ³n principal
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
        'âœ… [ResumenPedidoScreen] DirecciÃ³n principal seleccionada: ${direccionPrincipal.direccion}',
      );
    } catch (e) {
      debugPrint(
        'âŒ [ResumenPedidoScreen] Error al cargar direcciÃ³n principal: $e',
      );
    }
  }

  // âœ… Obtener cantidad de direcciones del cliente
  int _obtenerCantidadDirecciones() {
    try {
      final carritoProvider = context.read<CarritoProvider>();
      final cliente = carritoProvider.clienteSeleccionado;
      return cliente?.direcciones?.length ?? 0;
    } catch (e) {
      debugPrint('âŒ Error al obtener cantidad de direcciones: $e');
      return 0;
    }
  }

  // âœ… Mostrar selector de direcciÃ³n como modal
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

  // âœ… Seleccionar fecha personalizada (UI action)
  Future<void> _seleccionarFechaPersonalizada() async {
    final DateTime? picked = await DatePickerUtils.showThemedDatePicker(
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

  Future<void> _confirmarPedido() async {
    final carritoProvider = context.read<CarritoProvider>();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final esPreventista = user?.roles?.contains('preventista') ?? false;

    debugPrint('ðŸš€ Usuario: ${user?.email}, esPreventista: $esPreventista');

    // âœ… Detectar si estamos editando una proforma existente
    final editandoProforma = carritoProvider.editandoProforma;
    final proformaId = carritoProvider.proformaEditandoId;

    if (carritoProvider.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El carrito estÃ¡ vacÃ­o'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // âœ… ValidaciÃ³n: Si es DELIVERY, direcciÃ³n es obligatoria
    if (_tipoEntrega == 'DELIVERY' && _direccionSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar una direcciÃ³n de entrega'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreandoPedido = true;
    });

    try {
      // Validar que el usuario estÃ© autenticado
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // DirecciÃ³n ID (null para PICKUP)
      int? direccionId;
      if (_tipoEntrega == 'DELIVERY') {
        direccionId = _direccionSeleccionada!.id;
      }

      // âœ… NUEVO: Si es preventista, usar lÃ³gica de proforma con combo items
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

        // âœ… NUEVO: Verificar si estÃ¡ editando o creando nueva proforma
        if (editandoProforma && proformaId != null) {
          debugPrint('âœï¸ Actualizando proforma #$proformaId...');

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

          debugPrint('âœ… Proforma actualizada');
        } else {
          debugPrint('âž• Creando nueva proforma para preventista...');

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

          debugPrint('âœ… Proforma creada');
        }

        setState(() {
          _isCreandoPedido = false;
        });

        if (response.success && response.data != null) {
          carritoProvider.limpiarCarrito();

          if (editandoProforma) {
            carritoProvider.limpiarProformaEditando();
            debugPrint('âœ… EdiciÃ³n limpiada');
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
                  title: const Text('âŒ Stock Insuficiente'),
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
        // âœ… Cliente logueado: usar lÃ³gica de pedido normal
        debugPrint('ðŸ‘¤ Creando pedido para cliente logueado...');

        // Obtener items del carrito de forma normal
        final items = carritoProvider.getItemsParaPedido();

        // Determinar cliente ID
        final clienteIdUsuario = user.clienteId;
        if (clienteIdUsuario == null) {
          throw Exception(
            'No se pudo identificar al cliente. AsegÃºrate de estar correctamente autenticado.',
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

        // âœ… Validar polÃ­tica de pago
        debugPrint('ðŸ’³ PolÃ­tica de pago seleccionada: $_politicaPago');

        if (_politicaPago == POLITICA_CREDITO) {
          if (!clienteSeleccionado.puedeAtenerCredito) {
            debugPrint('âš ï¸  Cliente NO tiene permisos de crÃ©dito');

            if (!mounted) return;
            final shouldContinue = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                title: const Text('Sin Permisos de CrÃ©dito'),
                content: Text(
                  'El cliente "${clienteSeleccionado.nombre}" no tiene permisos para solicitar crÃ©dito.\n\n'
                  'Â¿Deseas continuar con otra forma de pago?',
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

        // âœ… Crear o actualizar pedido
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
            'âœ… Proforma actualizada - PolÃ­tica de pago: $_politicaPago',
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

          debugPrint('âœ… Pedido creado - PolÃ­tica de pago: $_politicaPago');
        }

        setState(() {
          _isCreandoPedido = false;
        });

        if (response.success && response.data != null) {
          carritoProvider.limpiarCarrito();

          if (editandoProforma) {
            carritoProvider.limpiarProformaEditando();
            debugPrint('âœ… Estado de ediciÃ³n limpiado');
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
    /*final tituloResumen = esPreventista
        ? (editandoProforma ? 'Actualizar Proforma' : 'Crear Proforma')
        : (editandoProforma ? 'Actualizar Proforma' : 'Resumen del Pedido');*/
    final tituloResumen = 'Resumen del Pedido';

    return Scaffold(
      appBar: CustomGradientAppBar(title: tituloResumen),
      body: Consumer<CarritoProvider>(
        builder: (context, carritoProvider, _) {
          final carrito = carritoProvider.carrito;

          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // âœ… NUEVO: Selector de Tipo de Entrega
                      TipoEntregaWidget(
                        tipoEntregaSeleccionado: _tipoEntrega,
                        onTipoEntregaChanged: (nuevoTipo) {
                          setState(() {
                            _tipoEntrega = nuevoTipo;
                            if (nuevoTipo == 'PICKUP') {
                              _direccionSeleccionada = null;
                            }
                          });
                        },
                        parentContext: context,
                      ),
                      const SizedBox(height: 8),
                      // âœ… NUEVO: SecciÃ³n InformaciÃ³n del Cliente
                      ClienteInfoWidget(parentContext: context),
                      const SizedBox(height: 8),
                      // âœ… SecciÃ³n de CrÃ©dito (mostrar siempre si hay cliente)
                      Consumer<CarritoProvider>(
                        builder: (context, carritoProvider, _) {
                          final clienteSeleccionado = carritoProvider
                              .getClienteSeleccionado();
                          final usarCredito = _politicaPago == POLITICA_CREDITO;

                          // Mostrar solo si hay cliente seleccionado
                          if (clienteSeleccionado == null) {
                            return const SizedBox.shrink();
                          }

                          final puedeUsarCredito =
                              clienteSeleccionado.puedeAtenerCredito;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // âœ… Tarjeta "Solicitar CrÃ©dito" (solo si puede usar crÃ©dito)
                              if (puedeUsarCredito)
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
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.credit_card,
                                              color: usarCredito
                                                  ? Colors.green.shade600
                                                  : colorScheme
                                                        .onSurfaceVariant,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Solicitar Credito',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: usarCredito
                                                          ? Colors
                                                                .green
                                                                .shade700
                                                          : colorScheme
                                                                .onSurface,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Disponible: Bs. ${clienteSeleccionado.creditoDisponible?.toStringAsFixed(2) ?? (clienteSeleccionado.limiteCredito?.toStringAsFixed(2) ?? "0.00")} / ${clienteSeleccionado.limiteCredito?.toStringAsFixed(2) ?? "0.00"}',
                                                    style: TextStyle(
                                                      color: usarCredito
                                                          ? Colors
                                                                .green
                                                                .shade600
                                                          : colorScheme
                                                                .onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Switch(
                                              value: usarCredito,
                                              activeColor:
                                                  Colors.green.shade600,
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
                                        const SizedBox(height: 12),
                                        // Información de crédito resumida
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'Deudas Activas',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Bs. ${clienteSeleccionado.cuentasPorCobrarActivas?.toStringAsFixed(2) ?? "0.00"}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        (clienteSeleccionado
                                                                    .creditoDisponible ??
                                                                0) >
                                                            0
                                                        ? Colors.green.shade700
                                                        : Colors.red.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'Deudas x Aprobar',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Bs. ${clienteSeleccionado.cuentasPorCobrarPorAprobar?.toStringAsFixed(2) ?? "0.00"}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        (clienteSeleccionado
                                                                    .creditoDisponible ??
                                                                0) >
                                                            0
                                                        ? Colors.green.shade700
                                                        : Colors.red.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                // âœ… Mostrar aviso si no puede usar crÃ©dito
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    border: Border.all(
                                      color: Colors.red.shade300,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.red.shade600,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Este cliente no puede usar crÃ©dito',
                                          style: TextStyle(
                                            fontSize: AppTextStyles.bodySmall(
                                              context,
                                            ).fontSize!,
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      // âœ… NUEVO: Selector de DirecciÃ³n (solo si DELIVERY)
                      if (_tipoEntrega == 'DELIVERY') ...[
                        DireccionWidget(
                          parentContext: context,
                          direccionSeleccionada: _direccionSeleccionada,
                          onMostrarSelectorDireccion: _mostrarSelectorDireccion,
                          onDireccionChanged: (nuevaDireccion) {
                            setState(() {
                              _direccionSeleccionada = nuevaDireccion;
                            });
                          },
                          cantidadDirecciones: _obtenerCantidadDirecciones(),
                        ),
                      ],
                      const SizedBox(height: 4),
                      // âœ… NUEVO: Selector de Fecha/Hora
                      FechaHoraWidget(
                        parentContext: context,
                        fechaProgramada: _fechaProgramada,
                        horaInicio: _horaInicio,
                        horaFin: _horaFin,
                        observaciones: _observaciones,
                        turnoSeleccionado: _turnoSeleccionado,
                        horaEspecificaSeleccionada: _horaEspecificaSeleccionada,
                        onFechaProgramadaChanged: (nuevaFecha) {
                          setState(() {
                            _fechaProgramada = nuevaFecha;
                          });
                        },
                        onTurnoChanged: (turno, hora) {
                          setState(() {
                            _turnoSeleccionado = turno;
                            if (hora != null) {
                              _horaEspecificaSeleccionada = hora;
                              _horaInicio = TimeOfDay(hour: hora, minute: 0);
                              _horaFin = TimeOfDay(hour: hora, minute: 0);
                            }
                          });
                        },
                        onHoraEspecificaChanged: (hora) {
                          setState(() {
                            _horaEspecificaSeleccionada = hora;
                            _horaInicio = TimeOfDay(hour: hora, minute: 0);
                            _horaFin = TimeOfDay(hour: hora, minute: 0);
                          });
                        },
                        onObservacionesChanged: (nuevasObservaciones) {
                          setState(() {
                            _observaciones = nuevasObservaciones;
                          });
                        },
                        onSeleccionarFechaPersonalizada:
                            _seleccionarFechaPersonalizada,
                      ),
                      const SizedBox(height: 8),

                      // Productos
                      Text(
                        'Productos',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // âœ… Usar el mismo componente CarritoItemCard que en carrito_screen
                      ...carrito.items.map((item) {
                        final detalleConRango = carritoProvider
                            .obtenerDetalleConRango(item.producto.id);

                        return CarritoItemCard(
                          item: item,
                          detalleConRango: detalleConRango,
                          isPreventista: false,
                          showDeleteButton: false,
                          showQuantityControls: false,
                          onIncrement: () {},
                          onDecrement: () {},
                          onRemove: () {},
                          onUpdateCantidad: (_) {},
                        );
                      }),

                      // Resumen de montos
                      Text(
                        'Resumen',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'Bs. ${carrito.total.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
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
}
