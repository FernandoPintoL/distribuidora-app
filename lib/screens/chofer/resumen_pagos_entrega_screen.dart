import 'package:flutter/material.dart';
import '../../models/entrega.dart';
import '../../models/venta.dart';
import '../../providers/entrega_provider.dart';
import '../../services/entrega_service.dart';
import '../../widgets/widgets.dart';
import '../../config/config.dart';
import '../chofer/entrega_detalle/confirmar_entrega_venta_screen.dart';

class ResumenPagosEntregaScreen extends StatefulWidget {
  final Entrega entrega;
  final EntregaProvider provider;

  const ResumenPagosEntregaScreen({
    Key? key,
    required this.entrega,
    required this.provider,
  }) : super(key: key);

  @override
  State<ResumenPagosEntregaScreen> createState() =>
      _ResumenPagosEntregaScreenState();
}

class _ResumenPagosEntregaScreenState extends State<ResumenPagosEntregaScreen> {
  final EntregaService _entregaService = EntregaService();
  late Future<Map<String, dynamic>?> _resumenFuture;

  // ✅ NUEVO 2026-02-15: Tipos de pago cargados del backend
  List<Map<String, dynamic>> tiposPago = [];
  bool tiposPagoCargados = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // ✅ NUEVO: Cargar tipos de pago desde el backend
  Future<void> _cargarDatos() async {
    _cargarResumen();

    // Cargar tipos de pago
    final tiposPagoResponse = await _entregaService.obtenerTiposPago();
    if (tiposPagoResponse.success && tiposPagoResponse.data != null) {
      setState(() {
        tiposPago = tiposPagoResponse.data!;
        tiposPagoCargados = true;
      });
    }
  }

  void _cargarResumen() {
    _resumenFuture = _obtenerResumen();
  }

  Future<Map<String, dynamic>?> _obtenerResumen() async {
    final response = await _entregaService.obtenerResumenPagos(
      widget.entrega.id,
    );
    if (response.success && response.data != null) {
      return response.data;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: 'Resumen de Pagos - Entrega #${widget.entrega.id}',
        customGradient: AppGradients.green,
        actions: [
          // ✅ Botón para recargar la pantalla
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: () {
              setState(() => _cargarResumen());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Recargando datos...'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.blue[600],
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _resumenFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: isDarkMode ? Colors.red[400] : Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar resumen',
                    style: TextStyle(
                      fontSize: AppTextStyles.bodyLarge(context).fontSize!,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _cargarResumen());
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final resumen = snapshot.data!;
          return _buildResumen(resumen, isDarkMode);
        },
      ),
    );
  }

  Widget _buildResumen(Map<String, dynamic> resumen, bool isDarkMode) {
    final totalEsperado = resumen['total_esperado'] as num? ?? 0;
    final totalRecibido = resumen['total_recibido'] as num? ?? 0;
    final diferencia = resumen['diferencia'] as num? ?? 0;
    final porcentajeRecibido = resumen['porcentaje_recibido'] as num? ?? 0;
    final pagos = (resumen['pagos'] as List?) ?? [];
    final sinRegistrar = (resumen['sin_registrar'] as List?) ?? [];

    final diferenciaNegativa = diferencia < 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ TARJETA RESUMEN PRINCIPAL
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[400]!, Colors.green[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen de Entrega #${widget.entrega.id}',
                  style: TextStyle(
                    fontSize: AppTextStyles.headlineSmall(context).fontSize!,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Esperado',
                          style: TextStyle(
                            fontSize: AppTextStyles.bodySmall(
                              context,
                            ).fontSize!,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bs. ${totalEsperado.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: AppTextStyles.headlineMedium(
                              context,
                            ).fontSize!,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total Recibido',
                          style: TextStyle(
                            fontSize: AppTextStyles.bodySmall(
                              context,
                            ).fontSize!,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bs. ${totalRecibido.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: AppTextStyles.headlineMedium(
                              context,
                            ).fontSize!,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: totalEsperado > 0
                      ? (totalRecibido / totalEsperado).toDouble()
                      : 0,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    diferenciaNegativa ? Colors.orange : Colors.lightGreen,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Avance: ${porcentajeRecibido.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: AppTextStyles.bodySmall(context).fontSize!,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      diferenciaNegativa
                          ? 'Falta: Bs. ${diferencia.abs().toStringAsFixed(2)}'
                          : 'Completo ✅',
                      style: TextStyle(
                        fontSize: AppTextStyles.bodySmall(context).fontSize!,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ✅ SECCIÓN DE PAGOS POR TIPO
          Text(
            'Pagos Registrados',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          if (pagos.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'No hay pagos registrados',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            ...pagos.map((pago) {
              final tipoPago = pago['tipo_pago'] as String;
              final tipoPagoCodigo = pago['tipo_pago_codigo'] as String;
              final totalPago = pago['total'] as num;
              final cantidadVentas = pago['cantidad_ventas'] as num;
              final ventas = pago['ventas'] as List;

              final iconoPago = _obtenerIconoPago(tipoPagoCodigo);
              final colorPago = _obtenerColorPago(tipoPagoCodigo);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPagoCard(
                  icono: iconoPago,
                  color: colorPago,
                  tipo: tipoPago,
                  total: totalPago.toDouble(),
                  cantidad: cantidadVentas.toInt(),
                  ventas: ventas,
                  isDarkMode: isDarkMode,
                ),
              );
            }).toList(),

          const SizedBox(height: 24),

          // ✅ NUEVA 2026-02-15: SECCIÓN DE DETALLE DE VENTAS CON PAGOS EDITABLES
          Text(
            'Detalle de Ventas',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // ✅ MEJORADO 2026-02-16: Agrupar por venta (no por tipo de pago)
          if (pagos.isNotEmpty)
            ..._construirVentasConPagos(pagos, isDarkMode)
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'No hay ventas registradas',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 24),

          // ✅ SECCIÓN DE VENTAS SIN PAGO REGISTRADO
          if (sinRegistrar.isNotEmpty) ...[
            Text(
              'Ventas Sin Pago Registrado',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.orange[900]?.withOpacity(0.2)
                    : Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode ? Colors.orange[700]! : Colors.orange[200]!,
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sinRegistrar.length,
                separatorBuilder: (_, __) => Divider(
                  color: isDarkMode ? Colors.orange[700] : Colors.orange[200],
                  height: 1,
                ),
                itemBuilder: (_, index) {
                  final venta = sinRegistrar[index];
                  final ventaNumero = venta['venta_numero'] as String;
                  final monto = venta['monto'] as num;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Venta $ventaNumero',
                              style: TextStyle(
                                fontSize: AppTextStyles.bodyMedium(
                                  context,
                                ).fontSize!,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode
                                    ? Colors.grey[200]
                                    : Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Bs. ${monto.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: AppTextStyles.bodyMedium(
                              context,
                            ).fontSize!,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ✅ BOTONES DE ACCIÓN
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Atrás'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _cargarResumen());
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ NUEVO 2026-02-16: Construir tarjetas de ventas agrupadas por venta_id
  List<Widget> _construirVentasConPagos(List<dynamic> pagos, bool isDarkMode) {
    // Agrupar todas las ventas únicas con sus pagos
    final Map<int, Map<String, dynamic>> ventasMap = {};

    for (final pagoGroup in pagos) {
      final ventas = pagoGroup['ventas'] as List<dynamic>? ?? [];
      for (final venta in ventas) {
        final ventaId = venta['venta_id'] as int? ?? 0;
        final ventaNumero = venta['venta_numero'] as String;
        final tipoEntrega = venta['tipo_entrega'] as String? ?? 'COMPLETA';
        final tipoNovedad = venta['tipo_novedad'] as String?;
        final ventaTotal = (venta['venta_total'] as num? ?? 0).toDouble();

        // ✅ NUEVO 2026-02-17: Extraer campos de confirmación de entrega
        final fotos = (venta['fotos'] as List<dynamic>?)?.cast<String>() ?? [];
        final observacionesLogistica =
            venta['observaciones_logistica'] as String? ?? '';
        final firmaDigitalUrl = venta['firma_digital_url'] as String?;
        final detalles =
            (venta['detalles'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];

        if (ventaId > 0) {
          if (!ventasMap.containsKey(ventaId)) {
            ventasMap[ventaId] = {
              'venta_id': ventaId,
              'venta_numero': ventaNumero,
              'tipo_entrega': tipoEntrega,
              'tipo_novedad': tipoNovedad,
              'pagos': <Map<String, dynamic>>[],
              'total': ventaTotal, // ✅ NUEVO: Usa venta_total del backend
              // ✅ NUEVO 2026-02-17: Campos de confirmación de entrega
              'fotos': fotos,
              'observaciones_logistica': observacionesLogistica,
              'firma_digital_url': firmaDigitalUrl,
              'detalles': detalles,
            };
          }

          // Agregar pago a la venta
          ventasMap[ventaId]!['pagos'].add({
            'tipo_pago': pagoGroup['tipo_pago'],
            'tipo_pago_id': pagoGroup['tipo_pago_id'],
            'monto': venta['monto_recibido'] as num? ?? 0,
            'referencia': venta['referencia'] as String? ?? '',
          });
        }
      }
    }

    // Ordenar ventas por ID (de menor a mayor)
    final ventasOrdenadas = ventasMap.values.toList()
      ..sort((a, b) => (a['venta_id'] as int).compareTo(b['venta_id'] as int));

    // Construir widgets
    return ventasOrdenadas.map((ventaData) {
      final ventaId = ventaData['venta_id'] as int;
      final ventaNumero = ventaData['venta_numero'] as String;
      final tipoEntrega = ventaData['tipo_entrega'] as String;
      final tipoNovedad = ventaData['tipo_novedad'] as String?;
      final pagos = ventaData['pagos'] as List<Map<String, dynamic>>;
      final total = ventaData['total'] as double;
      // ✅ NUEVO 2026-02-17: Campos de confirmación de entrega
      final fotos = (ventaData['fotos'] as List?) ?? [];
      final observacionesLogistica =
          ventaData['observaciones_logistica'] as String? ?? '';
      final detalles = (ventaData['detalles'] as List?) ?? [];

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Card(
          elevation: 2,
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tipoEntrega == 'COMPLETA'
                    ? Colors.green[300]!
                    : Colors.orange[300]!,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Encabezado con ID y estado de entrega
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Venta #$ventaId',
                              style: TextStyle(
                                fontSize: AppTextStyles.bodyLarge(
                                  context,
                                ).fontSize!,
                                fontWeight: FontWeight.w700,
                                color: isDarkMode
                                    ? Colors.grey[100]
                                    : Colors.grey[900],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ventaNumero,
                              style: TextStyle(
                                fontSize: AppTextStyles.bodySmall(
                                  context,
                                ).fontSize!,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Estado de entrega
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: tipoEntrega == 'COMPLETA'
                                    ? Colors.green[100]
                                    : Colors.orange[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    tipoEntrega == 'COMPLETA'
                                        ? Icons.check_circle
                                        : Icons.warning,
                                    size: 14,
                                    color: tipoEntrega == 'COMPLETA'
                                        ? Colors.green[700]
                                        : Colors.orange[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    tipoEntrega == 'COMPLETA'
                                        ? '✅ Completa'
                                        : '⚠️ Con Novedad${tipoNovedad != null ? ': $tipoNovedad' : ''}',
                                    style: TextStyle(
                                      fontSize: AppTextStyles.labelSmall(
                                        context,
                                      ).fontSize!,
                                      fontWeight: FontWeight.w600,
                                      color: tipoEntrega == 'COMPLETA'
                                          ? Colors.green[700]
                                          : Colors.orange[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Botón cambiar tipo de entrega - Navega a pantalla completa
                      IconButton(
                        icon: const Icon(
                          Icons.local_shipping_outlined,
                          size: 22,
                        ),
                        onPressed: () {
                          // Convertir detalles de Map a VentaDetalle
                          final detallesVenta = detalles
                              .cast<Map<String, dynamic>>()
                              .map((det) => VentaDetalle.fromJson(det))
                              .toList();

                          // Crear un objeto Venta temporal para la pantalla
                          final ventaTmp = Venta(
                            id: ventaId,
                            numero: ventaNumero,
                            total: total,
                            subtotal: total,
                            descuento: 0,
                            impuesto: 0,
                            estadoLogistico: 'ENTREGADO',
                            estadoPago: 'PAGADO',
                            fecha: DateTime.now(),
                            detalles: detallesVenta,
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConfirmarEntregaVentaScreen(
                                entrega: widget.entrega,
                                venta: ventaTmp,
                                provider: widget.provider,
                                isEditing: true,
                                tipoEntregaExistente: tipoEntrega,
                                tipoNovedadExistente: tipoNovedad,
                              ),
                            ),
                          ).then((_) {
                            // Recargar el resumen cuando vuelve
                            _cargarResumen();
                          });
                        },
                        tooltip: '📦 Cambiar Tipo Entrega',
                        color: Colors.orange[600],
                      ),
                      // ✅ Botón editar pagos (solo para Entrega Completa o Devolución Parcial)
                      if (tipoEntrega == 'COMPLETA' ||
                          tipoNovedad == 'DEVOLUCION_PARCIAL')
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 22),
                          onPressed: () {
                            _mostrarDialogoCorregirPagos(
                              context: context,
                              entregaId: widget.entrega.id,
                              ventaId: ventaId,
                              ventaNumero: ventaNumero,
                              clienteNombre: 'Venta #$ventaId',
                              total: total,
                              desglose: pagos,
                            );
                          },
                          tooltip: '✏️ Editar Pagos',
                          color: Colors.blue[600],
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Divider(
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    height: 1,
                  ),
                  const SizedBox(height: 12),

                  // 💰 Total de la venta
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.blue[900]?.withOpacity(0.3)
                          : Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[400]!, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '💰 Total de la Venta',
                          style: TextStyle(
                            fontSize: AppTextStyles.bodySmall(
                              context,
                            ).fontSize!,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? Colors.blue[200]
                                : Colors.blue[800],
                          ),
                        ),
                        Text(
                          'Bs. ${total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: AppTextStyles.bodyMedium(
                              context,
                            ).fontSize!,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? Colors.blue[100]
                                : Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ✅ NUEVO 2026-02-17: Reporte de productos en esta venta
                  // Pasar detalles desde venta, no desde pagos
                  _buildReporteProductosConDetalles(
                    ventaId: ventaId,
                    detalles: detalles.cast<Map<String, dynamic>>(),
                    isDarkMode: isDarkMode,
                    fotos: fotos.cast<String>(),
                    observacionesLogistica: observacionesLogistica,
                    tipoNovedad:
                        tipoNovedad, // ✅ NUEVO 2026-02-17: Pasar tipo_novedad para destacar devoluciones
                  ),
                  const SizedBox(height: 12),

                  // ✅ Desglose de pagos (solo para Devolución Parcial)
                  if (tipoNovedad == 'DEVOLUCION_PARCIAL') ...[
                    Text(
                      '💳 Pagos Registrados',
                      style: TextStyle(
                        fontSize: AppTextStyles.bodySmall(context).fontSize!,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ] else if (tipoNovedad != null &&
                      [
                        'RECHAZADA',
                        'CLIENTE_CERRADO',
                        'NO_CONTACTADO',
                      ].contains(tipoNovedad)) ...[
                    // Mensaje informativo cuando no hay pago esperado
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange[300]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No se espera pago por ${tipoNovedad == 'RECHAZADA'
                                  ? 'rechazo total'
                                  : tipoNovedad == 'CLIENTE_CERRADO'
                                  ? 'cliente cerrado'
                                  : 'no haber sido contactado'}',
                              style: TextStyle(
                                fontSize: AppTextStyles.bodySmall(
                                  context,
                                ).fontSize!,
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (pagos.isNotEmpty && tipoNovedad == 'DEVOLUCION_PARCIAL')
                    Column(
                      children: pagos.asMap().entries.map((entry) {
                        final pago = entry.value;
                        final tipoPago = pago['tipo_pago'] as String;
                        final monto = pago['monto'] as num;
                        final isLast = entry.key == pagos.length - 1;

                        return Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    '└─ $tipoPago',
                                    style: TextStyle(
                                      fontSize: AppTextStyles.bodySmall(
                                        context,
                                      ).fontSize!,
                                      color: isDarkMode
                                          ? Colors.grey[300]
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                'Bs. ${monto.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: AppTextStyles.bodySmall(
                                    context,
                                  ).fontSize!,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    )
                  // ✅ Solo mostrar "Sin pagos registrados" si es Devolución Parcial pero no tiene pagos
                  else if (pagos.isEmpty && tipoNovedad == 'DEVOLUCION_PARCIAL')
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.orange[900]?.withOpacity(0.2)
                            : Colors.orange[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.orange[700]!
                              : Colors.orange[200]!,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '⚠️ Sin pagos registrados',
                          style: TextStyle(
                            fontSize: AppTextStyles.bodySmall(
                              context,
                            ).fontSize!,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '📊 Total de Pagos:',
                          style: TextStyle(
                            fontSize: AppTextStyles.bodySmall(
                              context,
                            ).fontSize!,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? Colors.grey[200]
                                : Colors.grey[800],
                          ),
                        ),
                        Text(
                          'Bs. ${total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: AppTextStyles.bodyMedium(
                              context,
                            ).fontSize!,
                            fontWeight: FontWeight.w700,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  // ✅ NUEVO 2026-02-17: Construir sección de reporte de productos para cada venta
  Widget _buildReporteProductos(
    int ventaId,
    List<Map<String, dynamic>> pagos,
    bool isDarkMode,
  ) {
    // Extraer detalles (productos) del primer pago que los contenga
    List<Map<String, dynamic>> detalles = [];
    if (pagos.isNotEmpty) {
      final primerPago = pagos.first;
      if (primerPago.containsKey('detalles') &&
          primerPago['detalles'] is List) {
        detalles = List<Map<String, dynamic>>.from(
          primerPago['detalles'] as List,
        );
      }
    }

    // Si no hay detalles, mostrar vacío
    if (detalles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.grey[900]?.withOpacity(0.3)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
        child: Center(
          child: Text(
            '📦 Sin productos',
            style: TextStyle(
              fontSize: AppTextStyles.bodySmall(context).fontSize!,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    // Construir lista de productos
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          '📦 Productos (${detalles.length})',
          style: TextStyle(
            fontSize: AppTextStyles.bodySmall(context).fontSize!,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),

        // Lista de productos
        Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.grey[900]?.withOpacity(0.3)
                : Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDarkMode ? Colors.blue[800]! : Colors.blue[200]!,
            ),
          ),
          child: Column(
            children: detalles.asMap().entries.map((entry) {
              final detalle = entry.value;
              final isLast = entry.key == detalles.length - 1;

              final productoNombre =
                  detalle['producto_nombre'] as String? ??
                  'Producto desconocido';
              final productoCodiogo =
                  detalle['producto_codigo'] as String? ?? '';
              final cantidad = (detalle['cantidad'] as num?) ?? 0;
              final precioUnitario = (detalle['precio_unitario'] as num?) ?? 0;
              final subtotal = (detalle['subtotal'] as num?) ?? 0;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre y código del producto
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productoNombre,
                                    style: TextStyle(
                                      fontSize: AppTextStyles.bodySmall(
                                        context,
                                      ).fontSize!,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode
                                          ? Colors.grey[200]
                                          : Colors.grey[900],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (productoCodiogo.isNotEmpty)
                                    Text(
                                      '#$productoCodiogo',
                                      style: TextStyle(
                                        fontSize: AppTextStyles.labelSmall(
                                          context,
                                        ).fontSize!,
                                        color: isDarkMode
                                            ? Colors.grey[500]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Cantidad, precio unitario y subtotal
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Cantidad
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cantidad',
                                    style: TextStyle(
                                      fontSize: AppTextStyles.labelSmall(
                                        context,
                                      ).fontSize!,
                                      color: isDarkMode
                                          ? Colors.grey[500]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    cantidad.toString(),
                                    style: TextStyle(
                                      fontSize: AppTextStyles.bodySmall(
                                        context,
                                      ).fontSize!,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode
                                          ? Colors.grey[300]
                                          : Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Precio unitario
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Precio Unit.',
                                    style: TextStyle(
                                      fontSize: AppTextStyles.labelSmall(
                                        context,
                                      ).fontSize!,
                                      color: isDarkMode
                                          ? Colors.grey[500]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'Bs. ${precioUnitario.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: AppTextStyles.bodySmall(
                                        context,
                                      ).fontSize!,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode
                                          ? Colors.grey[300]
                                          : Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Subtotal
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Subtotal',
                                    style: TextStyle(
                                      fontSize: AppTextStyles.labelSmall(
                                        context,
                                      ).fontSize!,
                                      color: isDarkMode
                                          ? Colors.grey[500]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'Bs. ${subtotal.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: AppTextStyles.bodySmall(
                                        context,
                                      ).fontSize!,
                                      fontWeight: FontWeight.w700,
                                      color: isDarkMode
                                          ? Colors.green[400]
                                          : Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Separador (si no es el último)
                  if (!isLast)
                    Divider(
                      color: isDarkMode ? Colors.grey[700] : Colors.blue[200],
                      height: 1,
                      thickness: 1,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ✅ NUEVO 2026-02-17: Construir reporte de productos con detalles, fotos y observaciones
  Widget _buildReporteProductosConDetalles({
    required int ventaId,
    required List<Map<String, dynamic>> detalles,
    required bool isDarkMode,
    required List<String> fotos,
    required String observacionesLogistica,
    required String? tipoNovedad,
  }) {
    // Si no hay detalles, mostrar vacío
    if (detalles.isEmpty && fotos.isEmpty && observacionesLogistica.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Mostrar fotos si existen
        if (fotos.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '📸 Fotos (${fotos.length})',
            style: TextStyle(
              fontSize: AppTextStyles.bodySmall(context).fontSize!,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: fotos.map((fotoUrl) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      fotoUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.grey[700]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        // ✅ Mostrar observaciones si existen
        if (observacionesLogistica.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '📝 Observaciones',
            style: TextStyle(
              fontSize: AppTextStyles.bodySmall(context).fontSize!,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.orange[900]?.withOpacity(0.2)
                  : Colors.orange[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.orange[300]!),
            ),
            child: Text(
              observacionesLogistica,
              style: TextStyle(
                fontSize: AppTextStyles.bodySmall(context).fontSize!,
                color: isDarkMode ? Colors.orange[200] : Colors.orange[900],
              ),
            ),
          ),
        ],

        // ✅ Mostrar productos si existen
        if (detalles.isNotEmpty) ...[
          const SizedBox(height: 12),
          // ✅ Título diferenciado según tipo de novedad
          Text(
            (tipoNovedad ?? '') == 'DEVOLUCION_PARCIAL'
                ? '📦 Productos Devueltos (${detalles.length})'
                : '📦 Productos (${detalles.length})',
            style: TextStyle(
              fontSize: AppTextStyles.bodySmall(context).fontSize!,
              fontWeight: FontWeight.w600,
              color: (tipoNovedad ?? '') == 'DEVOLUCION_PARCIAL'
                  ? (isDarkMode ? Colors.orange[300] : Colors.orange[800])
                  : (isDarkMode ? Colors.grey[300] : Colors.grey[700]),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              // ✅ Colores diferenciados para DEVOLUCION_PARCIAL
              color: (tipoNovedad ?? '') == 'DEVOLUCION_PARCIAL'
                  ? (isDarkMode
                        ? Colors.orange[900]?.withOpacity(0.2)
                        : Colors.orange[50])
                  : (isDarkMode
                        ? Colors.grey[900]?.withOpacity(0.3)
                        : Colors.blue[50]),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (tipoNovedad ?? '') == 'DEVOLUCION_PARCIAL'
                    ? (isDarkMode ? Colors.orange[700]! : Colors.orange[200]!)
                    : (isDarkMode ? Colors.blue[800]! : Colors.blue[200]!),
              ),
            ),
            child: Column(
              children: detalles.asMap().entries.map((entry) {
                final detalle = entry.value;
                final isLast = entry.key == detalles.length - 1;

                final productoNombre =
                    detalle['producto_nombre'] as String? ??
                    'Producto desconocido';
                final productoCodiogo =
                    detalle['producto_codigo'] as String? ?? '';
                final cantidad = (detalle['cantidad'] as num?) ?? 0;
                final precioUnitario =
                    (detalle['precio_unitario'] as num?) ?? 0;
                final subtotal = (detalle['subtotal'] as num?) ?? 0;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre y código del producto
                          Text(
                            productoNombre,
                            style: TextStyle(
                              fontSize: AppTextStyles.bodySmall(
                                context,
                              ).fontSize!,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? Colors.grey[200]
                                  : Colors.grey[900],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (productoCodiogo.isNotEmpty)
                            Text(
                              '#$productoCodiogo',
                              style: TextStyle(
                                fontSize: AppTextStyles.labelSmall(
                                  context,
                                ).fontSize!,
                                color: isDarkMode
                                    ? Colors.grey[500]
                                    : Colors.grey[600],
                              ),
                            ),
                          const SizedBox(height: 6),
                          // Cantidad x Precio Unitario = Subtotal
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Cant: ${cantidad.toInt()}',
                                style: TextStyle(
                                  fontSize: AppTextStyles.labelSmall(
                                    context,
                                  ).fontSize!,
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[700],
                                ),
                              ),
                              Text(
                                'Bs. ${precioUnitario.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: AppTextStyles.labelSmall(
                                    context,
                                  ).fontSize!,
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[700],
                                ),
                              ),
                              Text(
                                'Bs. ${subtotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: AppTextStyles.labelSmall(
                                    context,
                                  ).fontSize!,
                                  fontWeight: FontWeight.w700,
                                  color: isDarkMode
                                      ? Colors.green[400]
                                      : Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        color: (tipoNovedad ?? '') == 'DEVOLUCION_PARCIAL'
                            ? (isDarkMode
                                  ? Colors.orange[700]
                                  : Colors.orange[200])
                            : (isDarkMode
                                  ? Colors.grey[700]
                                  : Colors.blue[200]),
                        height: 1,
                        thickness: 1,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  // ✅ NUEVO 2026-02-15: Diálogo para corregir pagos de una venta específica
  void _mostrarDialogoCorregirPagos({
    required BuildContext context,
    required int entregaId,
    required int ventaId,
    required String ventaNumero,
    required String clienteNombre,
    required double total,
    required List<dynamic> desglose,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // ✅ ACTUALIZADO 2026-02-15: Mapear desglose real a estructura editable
    List<Map<String, dynamic>> pagosEditables = [];

    // Procesar desglose actual
    if (desglose.isNotEmpty) {
      for (final pago in desglose) {
        final tipoPago = pago['tipo_pago'] as String?;
        final monto = (pago['monto'] as num?)?.toDouble() ?? 0.0;
        final referencia = pago['referencia'] as String? ?? '';

        // Buscar el tipo de pago en la lista para obtener el ID
        int tipoPagoId = 0;
        if (tipoPago != null && tiposPago.isNotEmpty) {
          try {
            final tipoEncontrado = tiposPago.firstWhere(
              (t) =>
                  (t['nombre'] as String).toUpperCase() ==
                  tipoPago.toUpperCase(),
              orElse: () => {'id': 0, 'nombre': tipoPago},
            );
            tipoPagoId = tipoEncontrado['id'] as int? ?? 0;
          } catch (_) {
            tipoPagoId = 0;
          }
        }

        pagosEditables.add({
          'tipo_pago_id': tipoPagoId,
          'tipo_pago_nombre': tipoPago ?? 'SIN_TIPO',
          'monto': monto,
          'referencia': referencia,
          'registrado': true, // Marca como ya registrado
        });
      }
    }

    // ✅ FIX 2026-02-21: Controllers se crean FUERA del builder para persistir entre rebuilds
    final Map<int, TextEditingController> montoControllers =
        <int, TextEditingController>{};
    for (int i = 0; i < pagosEditables.length; i++) {
      montoControllers[i] = TextEditingController(
        text: (pagosEditables[i]['monto'] as double).toStringAsFixed(2),
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final totalRecibidoActual = pagosEditables.fold(
              0.0,
              (sum, p) => sum + (p['monto'] as double),
            );
            final montoPendienteActual = (total - totalRecibidoActual).clamp(
              0.0,
              double.infinity,
            );

            return Dialog(
              backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '✏️ Corregir Pagos',
                          style: TextStyle(
                            fontSize: AppTextStyles.headlineSmall(
                              context,
                            ).fontSize!,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? Colors.grey[100]
                                : Colors.grey[900],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            // Limpiar controllers al cerrar
                            for (final controller in montoControllers.values) {
                              controller.dispose();
                            }
                            Navigator.pop(context);
                          },
                          color: isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Venta $ventaNumero - $clienteNombre',
                      style: TextStyle(
                        fontSize: AppTextStyles.bodySmall(context).fontSize!,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Información de totales
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Venta:',
                                style: TextStyle(
                                  fontSize: AppTextStyles.bodySmall(
                                    context,
                                  ).fontSize!,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                ),
                              ),
                              Text(
                                'Bs. ${total.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: AppTextStyles.bodyMedium(
                                    context,
                                  ).fontSize!,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Recibido:',
                                style: TextStyle(
                                  fontSize: AppTextStyles.bodySmall(
                                    context,
                                  ).fontSize!,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                ),
                              ),
                              Text(
                                'Bs. ${totalRecibidoActual.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: AppTextStyles.bodyMedium(
                                    context,
                                  ).fontSize!,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.blue[400]
                                      : Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Monto Pendiente:',
                                style: TextStyle(
                                  fontSize: AppTextStyles.bodySmall(
                                    context,
                                  ).fontSize!,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                ),
                              ),
                              Text(
                                'Bs. ${montoPendienteActual.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: AppTextStyles.bodyMedium(
                                    context,
                                  ).fontSize!,
                                  fontWeight: FontWeight.bold,
                                  color: montoPendienteActual > 0
                                      ? (isDarkMode
                                            ? Colors.red[400]
                                            : Colors.red[700])
                                      : (isDarkMode
                                            ? Colors.green[400]
                                            : Colors.green[700]),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ✅ ACTUALIZADO: Mostrar qué se ha registrado de cada venta
                    Text(
                      'Pagos de esta Venta',
                      style: TextStyle(
                        fontSize: AppTextStyles.bodySmall(context).fontSize!,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.grey[200] : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (pagosEditables.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.orange[900]?.withOpacity(0.2)
                              : Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.orange[700]!
                                : Colors.orange[200]!,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '⚠️ Sin pagos registrados aún',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: AppTextStyles.bodySmall(
                                context,
                              ).fontSize!,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    else
                      ...List<int>.generate(
                        pagosEditables.length,
                        (i) => i,
                      ).map((index) {
                        final pago = pagosEditables[index];
                        final esRegistrado =
                            pago['registrado'] as bool? ?? false;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: esRegistrado
                                    ? Colors.green[400]!
                                    : (isDarkMode
                                          ? Colors.grey[700]!
                                          : Colors.grey[300]!),
                                width: esRegistrado ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                // Encabezado con estado
                                Row(
                                  children: [
                                    if (esRegistrado)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green[100],
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          '✅ Registrado',
                                          style: TextStyle(
                                            fontSize: AppTextStyles.labelSmall(
                                              context,
                                            ).fontSize!,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[100],
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          '+ Nuevo',
                                          style: TextStyle(
                                            fontSize: AppTextStyles.labelSmall(
                                              context,
                                            ).fontSize!,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                      ),
                                    const Spacer(),
                                    Text(
                                      'Bs. ${(pago['monto'] as double).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: AppTextStyles.bodyMedium(
                                          context,
                                        ).fontSize!,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Campos editables
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: DropdownButton<int>(
                                        value: pago['tipo_pago_id'] ?? 0,
                                        isExpanded: true,
                                        items: [
                                          const DropdownMenuItem<int>(
                                            value: 0,
                                            child: Text('Seleccionar tipo...'),
                                          ),
                                          ...tiposPago.map(
                                            (tipo) => DropdownMenuItem<int>(
                                              value: tipo['id'] as int,
                                              child: Text(
                                                tipo['nombre'] as String,
                                              ),
                                            ),
                                          ),
                                        ],
                                        onChanged: (newValue) {
                                          if (newValue != null &&
                                              newValue != 0) {
                                            final tipoSeleccionado = tiposPago
                                                .firstWhere(
                                                  (t) => t['id'] == newValue,
                                                  orElse: () => {
                                                    'id': newValue,
                                                    'nombre': 'OTRO',
                                                  },
                                                );
                                            setStateDialog(() {
                                              pagosEditables[index]['tipo_pago_id'] =
                                                  newValue;
                                              pagosEditables[index]['tipo_pago_nombre'] =
                                                  tipoSeleccionado['nombre'];
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 1,
                                      child: TextField(
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: InputDecoration(
                                          hintText: 'Monto',
                                          hintStyle: TextStyle(
                                            color: isDarkMode
                                                ? Colors.grey[500]
                                                : Colors.grey[400],
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 8,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                        controller: montoControllers[index]!,
                                        onChanged: (value) {
                                          setStateDialog(() {
                                            pagosEditables[index]['monto'] =
                                                double.tryParse(value) ?? 0.0;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        setStateDialog(() {
                                          // Dispose el controller del pago que se elimina
                                          montoControllers[index]?.dispose();
                                          montoControllers.remove(index);

                                          // Remover el pago
                                          pagosEditables.removeAt(index);

                                          // Reconstruir mapa de controllers con índices válidos
                                          final newControllers =
                                              <int, TextEditingController>{};
                                          for (
                                            int i = 0;
                                            i < pagosEditables.length;
                                            i++
                                          ) {
                                            // Usar el controller existente o crear uno nuevo
                                            if (i < index &&
                                                montoControllers.containsKey(
                                                  i,
                                                )) {
                                              newControllers[i] =
                                                  montoControllers[i]!;
                                            } else if (i >= index &&
                                                montoControllers.containsKey(
                                                  i + 1,
                                                )) {
                                              newControllers[i] =
                                                  montoControllers[i + 1]!;
                                            } else {
                                              newControllers[i] =
                                                  TextEditingController(
                                                    text:
                                                        (pagosEditables[i]['monto']
                                                                as double)
                                                            .toStringAsFixed(2),
                                                  );
                                            }
                                          }
                                          montoControllers.clear();
                                          montoControllers.addAll(
                                            newControllers,
                                          );
                                        });
                                      },
                                      iconSize: 20,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),

                    const SizedBox(height: 12),

                    // Botón agregar pago
                    OutlinedButton.icon(
                      onPressed: () {
                        setStateDialog(() {
                          pagosEditables.add({
                            'tipo_pago_id': 0,
                            'tipo_pago_nombre': '',
                            'monto': 0.0,
                            'referencia': '',
                          });
                          // Crear controller para el nuevo pago
                          final newIndex = pagosEditables.length - 1;
                          montoControllers[newIndex] = TextEditingController(
                            text: '0.00',
                          );
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Pago'),
                    ),

                    const SizedBox(height: 16),

                    // Botones de acción
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            // Limpiar todos los controllers al cancelar
                            for (final controller in montoControllers.values) {
                              controller.dispose();
                            }
                            Navigator.pop(context);
                          },
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Guardar y después limpiar controllers
                            _guardarPagosCorregidos(
                              context: context,
                              entregaId: entregaId,
                              ventaId: ventaId,
                              desglose: pagosEditables,
                              onFinish: () {
                                // Limpiar controllers después de guardar
                                for (final controller
                                    in montoControllers.values) {
                                  controller.dispose();
                                }
                              },
                            );
                          },
                          child: const Text('Guardar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ✅ NUEVO 2026-02-15: Guardar pagos corregidos en el backend
  Future<void> _guardarPagosCorregidos({
    required BuildContext context,
    required int entregaId,
    required int ventaId,
    required List<Map<String, dynamic>> desglose,
    VoidCallback? onFinish,
  }) async {
    try {
      // Validar que haya al menos un pago
      if (desglose.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Debe agregar al menos un pago'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Validar que cada pago tenga tipo_pago_id válido
      for (final pago in desglose) {
        final tipoPagoId = pago['tipo_pago_id'] as int?;
        if (tipoPagoId == null || tipoPagoId == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⚠️ Todos los pagos deben tener un tipo seleccionado',
              ),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        if (((pago['monto'] as double?) ?? 0) <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⚠️ Todos los pagos deben tener un monto mayor a 0',
              ),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      // Mostrar loading
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Guardando pagos...'),
            ],
          ),
        ),
      );

      // Preparar desglose para enviar al API
      final desgloseParaApi = desglose
          .map(
            (pago) => {
              'tipo_pago_id': pago['tipo_pago_id'],
              'tipo_pago_nombre': pago['tipo_pago_nombre'],
              'monto': pago['monto'],
              'referencia': pago['referencia'] ?? '',
            },
          )
          .toList();

      // Llamar al API
      final response = await _entregaService.corregirPagoVenta(
        entregaId: entregaId,
        ventaId: ventaId,
        desglosePagos: desgloseParaApi,
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Cerrar loading dialog

      if (response.success) {
        // Cerrar el dialog de corrección
        Navigator.pop(context);

        // Mostrar éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pagos corregidos exitosamente'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );

        // Ejecutar callback de limpieza
        onFinish?.call();

        // Recargar el resumen
        _cargarResumen();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Error: ${response.message ?? 'No se pudieron guardar los pagos'}',
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Cerrar loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPagoCard({
    required IconData icono,
    required Color color,
    required String tipo,
    required double total,
    required int cantidad,
    required List<dynamic> ventas,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icono, color: color, size: 24),
        ),
        title: Text(
          tipo,
          style: TextStyle(
            fontSize: AppTextStyles.bodyLarge(context).fontSize!,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.grey[100] : Colors.grey[900],
          ),
        ),
        subtitle: Text(
          '$cantidad venta${cantidad > 1 ? 's' : ''}',
          style: TextStyle(
            fontSize: AppTextStyles.bodySmall(context).fontSize!,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        trailing: Text(
          'Bs. ${total.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: AppTextStyles.bodyLarge(context).fontSize!,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        children: [
          Divider(
            color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
            height: 1,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ventas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final venta = ventas[index];
                final ventaNumero = venta['venta_numero'] as String;
                final montoRecibido = venta['monto_recibido'] as num;
                final tipoEntrega = venta['tipo_entrega'] as String;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Venta $ventaNumero',
                              style: TextStyle(
                                fontSize: AppTextStyles.bodySmall(
                                  context,
                                ).fontSize!,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode
                                    ? Colors.grey[200]
                                    : Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tipoEntrega == 'COMPLETA'
                                  ? '✅ Entrega Completa'
                                  : '⚠️ Con Novedad',
                              style: TextStyle(
                                fontSize: AppTextStyles.labelSmall(
                                  context,
                                ).fontSize!,
                                color: tipoEntrega == 'COMPLETA'
                                    ? Colors.green[600]
                                    : Colors.orange[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Bs. ${montoRecibido.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: AppTextStyles.bodySmall(context).fontSize!,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _obtenerIconoPago(String codigo) {
    switch (codigo.toUpperCase()) {
      case 'EFECTIVO':
        return Icons.money;
      case 'TRANSFERENCIA':
      case 'QR':
        return Icons.account_balance;
      case 'TARJETA':
        return Icons.credit_card;
      case 'CHEQUE':
        return Icons.receipt;
      default:
        return Icons.payments;
    }
  }

  Color _obtenerColorPago(String codigo) {
    switch (codigo.toUpperCase()) {
      case 'EFECTIVO':
        return Colors.green;
      case 'TRANSFERENCIA':
      case 'QR':
        return Colors.blue;
      case 'TARJETA':
        return Colors.purple;
      case 'CHEQUE':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
