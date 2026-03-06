import 'package:flutter/material.dart';
import 'dart:convert'; // ✅ NUEVO 2026-03-05: Para base64Decode
import 'dart:typed_data'; // ✅ NUEVO 2026-03-05: Para Uint8List
import '../../models/entrega.dart';
import '../../models/venta.dart';
import '../../providers/entrega_provider.dart';
import '../../services/entrega_service.dart';
import '../../widgets/widgets.dart';
import '../../config/config.dart';
import '../chofer/entrega_detalle/confirmar_entrega_venta_screen.dart';
// ✅ NUEVO 2026-03-05: Widgets extraídos para reducir duplicidad
import 'resumen_pagos_widgets/dark_mode_container.dart';
import 'resumen_pagos_widgets/money_row.dart';
import 'resumen_pagos_widgets/status_badge.dart';
import 'resumen_pagos_widgets/section_header.dart';
import 'resumen_pagos_widgets/product_line_item.dart';
import 'resumen_pagos_widgets/info_box.dart';
import 'resumen_pagos_widgets/photo_gallery.dart';
import 'resumen_pagos_widgets/money_text.dart';

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

  /// ✅ NUEVO 2026-03-05: Convertir a int de forma segura (maneja String e int)
  int? _convertirAInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    if (value is double) {
      return value.toInt();
    }
    return null;
  }

  /// ✅ NUEVO 2026-03-05: Decodificar base64 a bytes para mostrar imagen
  Uint8List _decodificarBase64(String base64String) {
    // Remover prefijo de data URI si existe
    String cleanBase64 = base64String.replaceAll(
      RegExp(r'^data:image/[^;]+;base64,'),
      '',
    );

    try {
      return base64Decode(cleanBase64);
    } catch (_) {
      // Si falla, intentar sin limpiar
      try {
        return base64Decode(base64String);
      } catch (__) {
        // Retornar bytes vacíos si falla todo
        return Uint8List(0);
      }
    }
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
    final cliente = resumen['cliente'] as Map<String, dynamic>? ?? {};

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
                const SizedBox(height: 16),
                // ✅ NUEVO 2026-03-05: Resumen de totales por tipo de pago
                Divider(color: Colors.white.withValues(alpha: 0.3), height: 1),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (() {
                    final Map<String, Map<String, dynamic>> totalPorTipo = {};
                    for (final pagoGroup in pagos) {
                      final tipoPago = pagoGroup['tipo_pago'] as String;
                      final tipoPagoCodigo =
                          pagoGroup['tipo_pago_codigo'] as String;
                      final totalPago = pagoGroup['total'] as num;

                      if (!totalPorTipo.containsKey(tipoPago)) {
                        totalPorTipo[tipoPago] = {
                          'monto': 0.0,
                          'codigo': tipoPagoCodigo,
                        };
                      }
                      totalPorTipo[tipoPago]!['monto'] =
                          (totalPorTipo[tipoPago]!['monto'] as double) +
                          totalPago.toDouble();
                    }

                    return totalPorTipo.entries.map((entry) {
                      final tipo = entry.key;
                      final datos = entry.value;
                      final monto = datos['monto'] as double;
                      final codigo = datos['codigo'] as String;
                      final icono = _obtenerIconoPago(codigo);

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icono, size: 16, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              '$tipo: Bs. ${monto.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: AppTextStyles.labelSmall(
                                  context,
                                ).fontSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList();
                  })(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ✅ SECCIÓN 1: VENTAS DE LA ENTREGA (PRINCIPAL — PRIMERO)
          Text(
            'Ventas de la Entrega',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // ✅ MEJORADO 2026-02-16: Agrupar por venta (no por tipo de pago)
          if (pagos.isNotEmpty)
            ..._construirVentasConPagos(pagos, cliente, isDarkMode)
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

          // ✅ SECCIÓN 2: VENTAS SIN PAGO REGISTRADO (SI EXISTEN)
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
                  final ventaId = venta['venta_id'] as int;
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
                        Expanded(
                          child: Column(
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
                              const SizedBox(height: 4),
                              Text(
                                'Bs. ${monto.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: AppTextStyles.bodySmall(
                                    context,
                                  ).fontSize!,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ✅ Botón de edición para confirmar entrega
                        SizedBox(
                          height: 36,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _navegarAConfirmarEntrega(context, ventaId);
                            },
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Confirmar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
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
        ],
      ),
    );
  }

  // ✅ NUEVO 2026-02-16: Construir tarjetas de ventas agrupadas por venta_id
  List<Widget> _construirVentasConPagos(
    List<dynamic> pagos,
    Map<String, dynamic> cliente,
    bool isDarkMode,
  ) {
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

        // ✅ NUEVO 2026-03-05: Extraer cliente específico de la venta (no el global)
        final clienteVenta = venta['cliente'] as Map<String, dynamic>? ?? {};

        if (ventaId > 0) {
          // ✅ NUEVA 2026-03-05: Extraer productos devueltos e info de devolución (SIEMPRE, para preservar en múltiples pagos)
          final productosDevueltos =
              (venta['productos_devueltos'] as List?) ?? [];
          final montoDevuelto = venta['monto_devuelto'] as num? ?? 0;
          final montoAceptado = venta['monto_aceptado'] as num? ?? ventaTotal;
          // ✅ NUEVO 2026-03-05: Extraer campos de novedad
          final tiendaAbierta = venta['tienda_abierta'] as bool?;
          final clientePresente = venta['cliente_presente'] as bool?;
          final motivoRechazo = venta['motivo_rechazo'] as String?;

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
              // ✅ NUEVO 2026-03-05: Guardar cliente específico de la venta
              'cliente': clienteVenta,
              // ✅ NUEVA 2026-03-05: Guardar productos devueltos e info de devolución
              'productos_devueltos': productosDevueltos,
              'monto_devuelto': montoDevuelto,
              'monto_aceptado': montoAceptado,
              // ✅ NUEVO 2026-03-05: Guardar campos de novedad
              'tienda_abierta': tiendaAbierta,
              'cliente_presente': clientePresente,
              'motivo_rechazo': motivoRechazo,
            };
          } else {
            // ✅ FIX 2026-03-05: Si la venta ya existe (múltiples pagos), asegurar que productos_devueltos se preserve
            if (productosDevueltos.isNotEmpty) {
              ventasMap[ventaId]!['productos_devueltos'] = productosDevueltos;
              ventasMap[ventaId]!['monto_devuelto'] = montoDevuelto;
              ventasMap[ventaId]!['monto_aceptado'] = montoAceptado;
            }
            // ✅ NUEVO 2026-03-05: Actualizar campos de novedad en venta existente
            if (tiendaAbierta != null) {
              ventasMap[ventaId]!['tienda_abierta'] = tiendaAbierta;
            }
            if (clientePresente != null) {
              ventasMap[ventaId]!['cliente_presente'] = clientePresente;
            }
            if (motivoRechazo != null) {
              ventasMap[ventaId]!['motivo_rechazo'] = motivoRechazo;
            }
          }

          // Agregar pago a la venta
          ventasMap[ventaId]!['pagos'].add({
            'tipo_pago': pagoGroup['tipo_pago'],
            'tipo_pago_id': pagoGroup['tipo_pago_id'],
            'tipo_pago_codigo': pagoGroup['tipo_pago_codigo'],
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
      // ✅ NUEVA 2026-03-05: Campos de novedad
      final tiendaAbierta = ventaData['tienda_abierta'] as bool?;
      final clientePresente = ventaData['cliente_presente'] as bool?;
      final motivoRechazo = ventaData['motivo_rechazo'] as String?;
      // ✅ NUEVA 2026-03-05: Productos devueltos en devolución parcial
      final productosDevueltosRaw = ventaData['productos_devueltos'];
      final productosDevueltos = (productosDevueltosRaw is List)
          ? (productosDevueltosRaw as List).cast<Map<String, dynamic>>()
          : [];
      final montoDevuelto =
          (ventaData['monto_devuelto'] as num?)?.toDouble() ?? 0.0;
      final montoAceptado =
          (ventaData['monto_aceptado'] as num?)?.toDouble() ?? 0.0;

      debugPrint(
        '📦 [VENTA $ventaId] tipo_novedad=$tipoNovedad, productosDevueltos=${productosDevueltos.length}, montoDevuelto=$montoDevuelto, ventaData.keys=${ventaData.keys.toList()}',
      );

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
                                    ? Colors.white
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
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // 👤 Información del cliente
                            Text(
                              cliente['nombre_completo'] as String? ??
                                  cliente['nombre'] as String? ??
                                  'Cliente desconocido',
                              style: TextStyle(
                                fontSize: AppTextStyles.bodySmall(
                                  context,
                                ).fontSize!,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? Colors.amber[300]
                                    : Colors.amber[800],
                              ),
                            ),
                            if ((cliente['email'] as String? ?? '')
                                    .isNotEmpty ||
                                (cliente['telefono'] as String? ?? '')
                                    .isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                [
                                  if ((cliente['email'] as String? ?? '')
                                      .isNotEmpty)
                                    cliente['email'],
                                  if ((cliente['telefono'] as String? ?? '')
                                      .isNotEmpty)
                                    cliente['telefono'],
                                ].join(' • '),
                                style: TextStyle(
                                  fontSize: AppTextStyles.labelSmall(
                                    context,
                                  ).fontSize!,
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            // ✅ NUEVO 2026-03-05: Badges de tipo entrega y tipo novedad
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                // Badge 1: Tipo de Entrega
                                tipoEntrega == 'COMPLETA'
                                    ? StatusBadge.completa()
                                    : StatusBadge.novedad(),
                                // Badge 2: Tipo de Novedad (si existe)
                                if (tipoNovedad != null)
                                  StatusBadge.tipoNovedad(
                                    tipoNovedad: _obtenerNombreTipoNovedad(
                                      tipoNovedad,
                                    ),
                                  ),
                              ],
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
                                // ✅ NUEVO 2026-03-05: Pasar cliente global (ya tiene datos correctos) y tipo de pago
                                cliente: cliente,
                                tipoPago: pagos.isNotEmpty
                                    ? {
                                        'id': _convertirAInt(
                                          pagos[0]['tipo_pago_id'],
                                        ),
                                        'nombre':
                                            pagos[0]['tipo_pago'] as String? ??
                                            'No especificado',
                                        'codigo':
                                            pagos[0]['tipo_pago_codigo']
                                                as String?,
                                      }
                                    : null,
                                // ✅ NUEVO 2026-03-05: Pasar información previa de fotos, observaciones y pagos
                                fotosExistentes: fotos.cast<String>(),
                                observacionesExistentes: observacionesLogistica,
                                pagosExistentes: pagos
                                    .map(
                                      (pago) => {
                                        'tipo_pago_id': pago['tipo_pago_id'],
                                        'monto': pago['monto'],
                                        'referencia': pago['referencia'],
                                      },
                                    )
                                    .toList(),
                                // ✅ NUEVA 2026-03-05: Pasar campos de novedad
                                tiendaAbiertaExistente: tiendaAbierta,
                                clientePresenteExistente: clientePresente,
                                motivoRechazoExistente: motivoRechazo,
                                // ✅ NUEVO 2026-03-05: Pasar productos devueltos existentes para DEVOLUCION_PARCIAL
                                productosDevueltosExistentes: productosDevueltos
                                    .cast<Map<String, dynamic>>(),
                              ),
                            ),
                          ).then((result) {
                            // ✅ Si hubo cambios (result == true), recargar y retornar a pantalla anterior
                            if (result == true) {
                              debugPrint(
                                '📝 [RESUMEN_PAGOS] Cambios detectados, recargando resumen...',
                              );
                              setState(() {
                                _cargarResumen();
                              });
                              // Esperar a que se cargue el resumen, luego retornar
                              Future.delayed(
                                const Duration(milliseconds: 1000),
                                () {
                                  if (mounted) {
                                    debugPrint(
                                      '✅ [RESUMEN_PAGOS] Resumen recargado, retornando true...',
                                    );
                                    Navigator.pop(context, true);
                                  }
                                },
                              );
                            } else {
                              // Si no hubo cambios, solo recargar el resumen
                              debugPrint(
                                '📝 [RESUMEN_PAGOS] Sin cambios detectados, recargando resumen...',
                              );
                              setState(() {
                                _cargarResumen();
                              });
                            }
                          });
                        },
                        tooltip: '📦 Cambiar Tipo Entrega',
                        color: Colors.orange[600],
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
                  // ✅ NUEVO 2026-03-05: Mostrar total ajustado para DEVOLUCION_PARCIAL
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.green[900]?.withOpacity(0.2)
                          : Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[400]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader.total(isDarkMode: isDarkMode),
                        const SizedBox(height: 4),
                        MoneyRow(
                          label: 'Monto Total',
                          amount: tipoNovedad == 'DEVOLUCION_PARCIAL'
                              ? montoAceptado
                              : total,
                          isDarkMode: isDarkMode,
                          amountColor:
                              tipoNovedad == 'DEVOLUCION_PARCIAL' &&
                                  montoDevuelto > 0
                              ? (isDarkMode
                                    ? Colors.green[300]
                                    : Colors.green[700])
                              : (isDarkMode
                                    ? Colors.green[100]
                                    : Colors.green[900]),
                          rightWidget:
                              tipoNovedad == 'DEVOLUCION_PARCIAL' &&
                                  montoDevuelto > 0
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    MoneyText.medium(
                                      montoAceptado,
                                      isDarkMode: isDarkMode,
                                      color: isDarkMode
                                          ? Colors.green[300]
                                          : Colors.green[700],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '↩️ -Bs. ${montoDevuelto.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red[700],
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ✅ Mostrar productos solo si hay devoluciones
                  if (tipoNovedad == 'DEVOLUCION_PARCIAL') ...[
                    // ✅ NUEVO 2026-03-05: Mostrar productos devueltos en devolución parcial
                    if (productosDevueltos.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.red[900]?.withOpacity(0.2)
                              : Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[400]!, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHeader.productosDevueltos(
                              isDarkMode: isDarkMode,
                            ),
                            const SizedBox(height: 12),
                            ...productosDevueltos.map((producto) {
                              final nombreProducto =
                                  producto['producto_nombre'] ?? 'N/A';
                              final cantidad = producto['cantidad'] ?? 0;
                              final precioUnitario =
                                  (producto['precio_unitario'] as num?)
                                      ?.toDouble() ??
                                  0.0;
                              final subtotal =
                                  (producto['subtotal'] as num?)?.toDouble() ??
                                  0.0;
                              return ProductLineItem(
                                productName: nombreProducto,
                                quantity: cantidad is int
                                    ? cantidad.toDouble()
                                    : cantidad,
                                unitPrice: precioUnitario,
                                subtotal: subtotal,
                                isDarkMode: isDarkMode,
                                subtotalColor: isDarkMode
                                    ? Colors.red[200]!
                                    : Colors.red[800]!,
                              );
                            }).toList(),
                            const SizedBox(height: 8),
                            Divider(color: Colors.red[300], height: 1),
                            const SizedBox(height: 8),
                            MoneyRow(
                              label: 'Monto Devuelto:',
                              amount: montoDevuelto,
                              isDarkMode: isDarkMode,
                              amountColor: isDarkMode
                                  ? Colors.red[200]!
                                  : Colors.red[800]!,
                            ),
                            const SizedBox(height: 4),
                            MoneyRow(
                              label: 'Monto Aceptado:',
                              amount: montoAceptado,
                              isDarkMode: isDarkMode,
                              amountColor: isDarkMode
                                  ? Colors.green[200]!
                                  : Colors.green[800]!,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],

                  // ✅ Desglose de pagos (para Entrega Completa y Devolución Parcial)
                  if (pagos.isNotEmpty &&
                      (tipoEntrega == 'COMPLETA' ||
                          tipoNovedad == 'DEVOLUCION_PARCIAL')) ...[
                    SectionHeader.pagos(isDarkMode: isDarkMode),
                    const SizedBox(height: 8),
                    // ✅ NUEVO 2026-03-05: Chips de pagos (tipo + monto)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: pagos.map((pago) {
                        final tipoPago = pago['tipo_pago'] as String;
                        final tipoPagoCodigo =
                            pago['tipo_pago_codigo'] as String? ?? '';
                        final monto =
                            (pago['monto'] as num?)?.toDouble() ?? 0.0;
                        final iconoPago = _obtenerIconoPago(tipoPagoCodigo);

                        return Chip(
                          avatar: Icon(
                            iconoPago,
                            size: 16,
                            color: isDarkMode
                                ? Colors.grey[300]
                                : Colors.grey[700],
                          ),
                          label: Text(
                            '$tipoPago • Bs. ${monto.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? Colors.white
                                  : Colors.grey[900],
                            ),
                          ),
                          backgroundColor: isDarkMode
                              ? Colors.blue[900]?.withOpacity(0.3)
                              : Colors.blue[50],
                          side: BorderSide(color: Colors.blue[300]!, width: 1),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    // ✅ NUEVO 2026-03-05: Mostrar Total Esperado y Total Recibido
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.green[900]?.withOpacity(0.2)
                            : Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[400]!, width: 1),
                      ),
                      child: Column(
                        children: [
                          // Total Esperado (ajustado si es DEVOLUCION_PARCIAL)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '💰 Total Esperado:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? Colors.blue[300]
                                      : Colors.blue[700],
                                ),
                              ),
                              Text(
                                // Mostrar total ajustado si es DEVOLUCION_PARCIAL
                                tipoNovedad == 'DEVOLUCION_PARCIAL'
                                    ? 'Bs. ${montoAceptado.toStringAsFixed(2)}'
                                    : 'Bs. ${total.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? Colors.blue[200]
                                      : Colors.blue[900],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Divider(color: Colors.green[300], height: 1),
                          const SizedBox(height: 8),
                          // Total Recibido
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '✅ Total Recibido:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? Colors.green[300]
                                      : Colors.green[800],
                                ),
                              ),
                              Text(
                                'Bs. ${pagos.fold<double>(0.0, (sum, p) => sum + ((p['monto'] as num?)?.toDouble() ?? 0.0)).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.green[200]
                                      : Colors.green[900],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else if (tipoNovedad != null &&
                      [
                        'RECHAZADO',
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
                              'No se espera pago por ${tipoNovedad == 'RECHAZADO'
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

                  // ✅ NUEVO 2026-03-05: Mostrar fotos si las hay (CLIENTE_CERRADO, etc.)
                  if (fotos.isNotEmpty) ...[
                    SectionHeader(
                      title: 'Fotos de Confirmación (${fotos.length})',
                      emoji: '📸',
                      isDarkMode: isDarkMode,
                      padding: const EdgeInsets.only(bottom: 8),
                    ),
                    DarkModeContainer(
                      child: PhotoGallery(
                        photos: fotos,
                        buildPhoto: (foto) {
                          final fotoUrl = foto as String;
                          final esBase64 =
                              fotoUrl.startsWith('data:') ||
                              fotoUrl.startsWith('/9j/') ||
                              fotoUrl.startsWith('iVBORw0KGgo');

                          final widget = esBase64
                              ? Image.memory(
                                  _decodificarBase64(fotoUrl),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : Image.network(
                                  fotoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );

                          return GestureDetector(
                            onTap: () => _mostrarFotoGrande(context, fotoUrl, esBase64),
                            child: widget,
                          );
                        },
                        isDarkMode: isDarkMode,
                      ),
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
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
        final tipoPagoId = _convertirAInt(pago['tipo_pago_id']);
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

        // ✅ Recargar el resumen con setState para forzar rebuild
        if (mounted) {
          setState(() {
            _cargarResumen();
          });
        }
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

  // ✅ NUEVO 2026-03-05: Traducir tipos de novedad a nombres legibles
  String _obtenerNombreTipoNovedad(String? tipo) {
    if (tipo == null) return '';
    switch (tipo.toUpperCase()) {
      case 'DEVOLUCION_PARCIAL':
        return 'Devolución Parcial';
      case 'CLIENTE_CERRADO':
        return 'Cliente Cerrado';
      case 'NO_CONTACTADO':
        return 'No Contactado';
      case 'RECHAZADO':
        return 'Rechazado';
      default:
        return tipo;
    }
  }

  // ✅ NUEVO 2026-03-05: Mostrar foto en grande con diálogo fullscreen
  void _mostrarFotoGrande(
    BuildContext context,
    String fotoUrl,
    bool esBase64,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            // Fondo oscuro
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black87,
              ),
            ),
            // Foto al centro
            Center(
              child: esBase64
                  ? Image.memory(
                      _decodificarBase64(fotoUrl),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 64,
                        ),
                      ),
                    )
                  : Image.network(
                      fotoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 64,
                        ),
                      ),
                    ),
            ),
            // Botón cerrar
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(10),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ NUEVO: Navegar a pantalla de confirmación de entrega para editar una venta sin registrar
  void _navegarAConfirmarEntrega(BuildContext context, int ventaId) {
    final venta = widget.entrega.ventas.firstWhere(
      (v) => v.id == ventaId,
      orElse: () => Venta(
        id: ventaId,
        numero: 'VEN-$ventaId',
        clienteNombre: '',
        subtotal: 0,
        impuesto: 0,
        total: 0,
        descuento: 0,
        estadoLogistico: '',
        estadoPago: '',
        fecha: DateTime.now(),
        detalles: const [],
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmarEntregaVentaScreen(
          entrega: widget.entrega,
          venta: venta,
          provider: widget.provider,
          isEditing: true, // Modo edición para volver a subir
        ),
      ),
    ).then((result) {
      // Si se guardó correctamente, recargar el resumen
      if (result == true) {
        setState(() {
          _cargarResumen();
        });
      }
    });
  }
}
