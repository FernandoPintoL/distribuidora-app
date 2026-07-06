import 'package:distribuidora/extensions/theme_extension.dart';
import 'package:distribuidora/models/devolucion_prestamo_cliente.dart';
import 'package:distribuidora/models/devolucion_prestamo_evento.dart';
import 'package:distribuidora/models/devolucion_prestamo_proveedor.dart';
import 'package:flutter/material.dart';
import '../../config/app_text_styles.dart';
import '../../config/app_urls.dart';
import '../../models/prestamo_cliente.dart';
import '../../models/prestamo_evento.dart';
import '../../models/prestamo_proveedor.dart';
import '../../widgets/map_location_selector.dart';
import 'package:url_launcher/url_launcher.dart';
import 'registrar_devolucion_screen.dart';

/// Pantalla que muestra los detalles de un préstamo
/// y permite registrar su devolución
class PrestamoDetalleScreen extends StatefulWidget {
  final dynamic prestamo;
  final String tipo; // 'cliente', 'evento', 'proveedor'

  const PrestamoDetalleScreen({
    super.key,
    required this.prestamo,
    required this.tipo,
  });

  @override
  State<PrestamoDetalleScreen> createState() => _PrestamoDetalleScreenState();
}

class _PrestamoDetalleScreenState extends State<PrestamoDetalleScreen> {
  late dynamic prestamo;
  late String tipo;

  @override
  void initState() {
    super.initState();
    prestamo = widget.prestamo;
    tipo = widget.tipo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${_getTitulo()} #${prestamo.id}"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información general
            _buildSeccion(context, 'Información General', [
              _buildItem(context, 'Folio', '#${prestamo.id}'),
              _buildItem(context, 'Estado', prestamo.estado ?? 'N/A'),
              _buildItem(
                context,
                'Fecha Préstamo',
                _formatearFecha(prestamo.fechaPrestamo),
              ),
            ]),

            // Información específica según tipo
            if (tipo == 'cliente')
              _buildClienteSection(context)
            else if (tipo == 'evento')
              _buildSeccion(context, 'Evento', [
                _buildItem(
                  context,
                  'Nombre del Evento',
                  prestamo.nombreEvento ?? 'N/A',
                ),
                _buildItem(
                  context,
                  'Encargado',
                  prestamo.encargadoEvento ?? 'N/A',
                ),
                _buildItem(
                  context,
                  'Dirección',
                  prestamo.direccionEvento ?? 'N/A',
                ),
                _buildItem(context, 'Teléfono', prestamo.telefonoUno ?? 'N/A'),
              ])
            else if (tipo == 'proveedor')
              _buildSeccion(context, 'Proveedor', [
                _buildItem(
                  context,
                  'Nombre',
                  prestamo.proveedor?.nombre ?? 'N/A',
                ),
                _buildItem(
                  context,
                  'Teléfono',
                  prestamo.proveedor?.telefono ?? 'N/A',
                ),
              ]),

            // ✅ MEJORADO: Sección de Ubicaciones del préstamo
            if (prestamo.ubicaciones != null &&
                prestamo.ubicaciones!.isNotEmpty)
              _buildUbicacionesSeccion(context),

            // Detalles de items prestados
            _buildDetallesItems(context),

            // ✅ NUEVO: Sección de Devoluciones
            if (_obtenerDevoluciones(prestamo).isNotEmpty)
              _buildDevolucionesSeccion(context),

            // Garantía
            _buildSeccion(context, 'Garantía', [
              _buildItem(
                context,
                'Monto',
                'Bs ${(prestamo.montoGarantia ?? 0).toStringAsFixed(2)}',
              ),
            ]),

            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  String _getTitulo() {
    switch (tipo) {
      case 'cliente':
        return 'Préstamo a Cliente';
      case 'evento':
        return 'Préstamo a Evento';
      case 'proveedor':
        return 'Préstamo a Proveedor';
      default:
        return 'Detalle de Préstamo';
    }
  }

  // ✅ NUEVO: Obtener devoluciones según tipo de préstamo
  List<dynamic> _obtenerDevoluciones(dynamic prestamo) {
    if (tipo == 'evento' && prestamo is PrestamoEvento) {
      return prestamo.devoluciones ?? [];
    }
    // Para cliente
    if (tipo == 'cliente' && prestamo is PrestamoCliente) {
      return prestamo.devoluciones ?? [];
    }
    // Para proveedor
    if (tipo == 'proveedor' && prestamo is PrestamoProveedor) {
      return prestamo.devoluciones ?? [];
    }
    return [];
  }

  // ✅ NUEVO: Calcular total devuelto según tipo
  int _calcularTotalDevuelto(dynamic detalle) {
    final devoluciones = _obtenerDevoluciones(detalle);

    if (tipo == 'evento') {
      // Para eventos: usar DevolucionEventoDetalle
      return (devoluciones).fold<int>(0, (sum, dev) {
        if (dev is DevolucionEventoDetalle) {
          return sum + dev.cantidadDevuelta;
        }
        return sum;
      });
    }

    if (tipo == 'proveedor') {
      // Para proveedor: usar DevolucionProveedorDetalle
      return (devoluciones).fold<int>(0, (sum, dev) {
        if (dev is DevolucionProveedorDetalle) {
          return sum + dev.cantidadDevuelta;
        }
        return sum;
      });
    }

    // Para cliente: usar DevolucionClienteDetalle
    return (devoluciones).fold<int>(0, (sum, dev) {
      if (dev is DevolucionClienteDetalle) {
        return sum + dev.cantidadDevuelta;
      }
      return sum;
    });
  }

  // ✅ NUEVO: Formatear fecha ISO a formato legible
  String _formatearFecha(String? fechaIso) {
    if (fechaIso == null || fechaIso.isEmpty) {
      return 'N/A';
    }

    try {
      final dateTime = DateTime.parse(fechaIso);
      // Formato: "15 de Julio de 2026 - 14:30:45"
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

      final dia = dateTime.day;
      final mes = meses[dateTime.month - 1];
      final anho = dateTime.year;
      final hora = dateTime.hour.toString().padLeft(2, '0');
      final minuto = dateTime.minute.toString().padLeft(2, '0');
      final segundo = dateTime.second.toString().padLeft(2, '0');

      return '$dia de $mes de $anho - $hora:$minuto:$segundo';
    } catch (e) {
      debugPrint('Error formateando fecha: $e');
      return fechaIso;
    }
  }

  Widget _buildSeccion(
    BuildContext context, // ✅ Parámetro ahora es consistente
    String titulo,
    List<Widget> items,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  color: context.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...items,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, String label, String value) {
    // ✅ Agregar context
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500, // ✅ Modo oscuro
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ✅ NUEVO: Sección de cliente con imagen
  Widget _buildClienteSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cliente = prestamo.cliente;

    if (cliente == null) {
      return _buildSeccion(context, 'Cliente', [
        _buildItem(context, 'Nombre', 'N/A'),
      ]);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        child: Column(
          children: [
            // Imagen del cliente
            if (cliente.fotoPerfil != null && cliente.fotoPerfil!.isNotEmpty)
              _buildClienteImageWidget(cliente.fotoPerfil!)
            else
              _buildClienteAvatarWidget(cliente.nombre),
            // Datos del cliente
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cliente',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  _buildItem(context, 'Nombre', cliente.nombre),
                  if (cliente.razonSocial != null &&
                      cliente.razonSocial!.isNotEmpty)
                    _buildItem(context, 'Razón Social', cliente.razonSocial!),
                  if (cliente.telefono != null && cliente.telefono!.isNotEmpty)
                    _buildItem(context, 'Teléfono', cliente.telefono!),
                  if (cliente.nit != null && cliente.nit!.isNotEmpty)
                    _buildItem(context, 'NIT', cliente.nit!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NUEVO: Widget para mostrar imagen de cliente
  Widget _buildClienteImageWidget(String fotoPerfil) {
    final imageUrl = AppUrls.buildImageUrl(fotoPerfil);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(4),
        topRight: Radius.circular(4),
      ),
      child: Container(
        width: double.infinity,
        height: 200,
        color: Theme.of(context).primaryColor.withAlpha(50),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ Error cargando imagen: $imageUrl - $error');
            return Container(
              color: Theme.of(context).primaryColor.withAlpha(50),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error cargando imagen',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ],
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ✅ NUEVO: Widget para mostrar avatar con iniciales
  Widget _buildClienteAvatarWidget(String nombre) {
    final iniciales = nombre
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              iniciales.isNotEmpty ? iniciales : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 56,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              nombre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ MEJORADO: Sección de ubicaciones del préstamo (múltiples)
  Widget _buildUbicacionesSeccion(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ubicaciones = prestamo.ubicaciones ?? [];

    List<Widget> allItems = [];

    for (int i = 0; i < ubicaciones.length; i++) {
      final ubicacion = ubicaciones[i];
      final items = <Widget>[];
      // Localidad
      if (ubicacion.localidad != null) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Localidad',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Flexible(
                  child: Text(
                    "📍 " + ubicacion.localidad!.nombre ?? 'N/A',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Dirección
      if (ubicacion.direccion != null && ubicacion.direccion!.isNotEmpty) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dirección',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        ubicacion.direccion!,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (ubicacion.direccionCliente?.latitud != null &&
                    ubicacion.direccionCliente!.longitud != null)
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      icon: Icon(
                        Icons.map,
                        size: 18,
                        color: context.colorScheme.secondary,
                      ),
                      onPressed: () => _abrirMapa(ubicacion),
                      padding: EdgeInsets.zero,
                      tooltip: 'Ver en mapa',
                    ),
                  ),
              ],
            ),
          ),
        );
      }

      // Observaciones
      /*if (ubicacion.observaciones != null &&
          ubicacion.observaciones!.isNotEmpty) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Observaciones',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        ubicacion.observaciones!,
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }*/

      allItems.addAll(items);
      if (i < ubicaciones.length - 1) {
        allItems.add(const Divider(height: 12));
      }
    }

    if (allItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSeccion(context, 'Ubicaciones', allItems);
  }

  // ✅ NUEVO: Sección de Devoluciones
  Widget _buildDevolucionesSeccion(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final devoluciones = _obtenerDevoluciones(prestamo);

    if (devoluciones.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calcular totales
    int totalPrestado = 0;
    int totalDevuelto = 0;

    if (prestamo.detalles != null) {
      for (var detalle in prestamo.detalles!) {
        final cantidad = detalle.cantidadPrestada;
        if (cantidad is num) {
          totalPrestado += cantidad.toInt();
        } else if (cantidad != null) {
          totalPrestado += cantidad as int;
        }
      }
    }

    for (var devolucion in devoluciones) {
      if (devolucion is DevolucionCliente) {
        if (devolucion.detalles != null) {
          for (var detalle in devolucion.detalles!) {
            totalDevuelto += detalle.cantidadDevuelta;
          }
        }
      } else if (devolucion is DevolucionEvento) {
        totalDevuelto += devolucion.cantidadTotalDevuelta ?? 0;
      } else if (devolucion is DevolucionProveedor) {
        totalDevuelto += devolucion.cantidadTotalDevuelta ?? 0;
      }
    }

    List<Widget> items = [];

    // Detalles de cada devolución
    for (int i = 0; i < devoluciones.length; i++) {
      final devolucion = devoluciones[i];
      items.add(_buildDevolucionItem(context, devolucion, i + 1));

      if (i < devoluciones.length - 1) {
        items.add(const Divider(height: 16));
      }
    }

    return _buildSeccion(context, 'Devoluciones', items);
  }

  // ✅ NUEVO: Calcular sumatoria por tipo de prestable
  Map<String, Map<String, int>> _calcularSumatoriaPorTipo(dynamic devolucion) {
    Map<String, Map<String, int>> resultado = {};

    if (devolucion.detalles == null) return resultado;

    print('🔍 [SUMATORIA] Iniciando cálculo de sumatorias por tipo para ${devolucion.runtimeType}');

    // Cliente
    if (devolucion is DevolucionCliente) {
      print('📦 [CLIENTE] Procesando ${devolucion.detalles!.length} detalles');
      for (var detalle in devolucion.detalles!) {
        final prestamoDetalle = detalle.detallePrestamoCliente;
        if (prestamoDetalle?.prestable == null) continue;

        final tipo = prestamoDetalle!.prestable!.tipo;
        final nombre = prestamoDetalle.prestable!.nombre;
        final key = '$tipo|$nombre';

        if (!resultado.containsKey(key)) {
          resultado[key] = {
            'prestado': prestamoDetalle.cantidadPrestada,
            'devuelto_buen_estado': 0,
            'devuelto_danado': 0,
          };
          print('  ➕ Nuevo tipo: "$key" - Prestado: ${prestamoDetalle.cantidadPrestada}');
        }

        final devBuen = detalle.cantidadDevuelta;
        final devDanado = detalle.cantidadDaniadaTotal ?? 0;
        resultado[key]!['devuelto_buen_estado'] =
            resultado[key]!['devuelto_buen_estado']! + devBuen;
        resultado[key]!['devuelto_danado'] =
            resultado[key]!['devuelto_danado']! + devDanado;
        print('  ✓ "$key" actualizado - Buen estado: +$devBuen, Dañado: +$devDanado');
      }
    }
    // Evento
    else if (devolucion is DevolucionEvento) {
      print('📦 [EVENTO] Procesando ${devolucion.detalles!.length} detalles');
      for (var detalle in devolucion.detalles!) {
        final prestamoDetalle = detalle.detallePrestamoEvento;
        if (prestamoDetalle == null || prestamoDetalle is! Map<String, dynamic>)
          continue;

        final prestable = prestamoDetalle['prestable'];
        if (prestable == null) continue;

        final tipo = prestable['tipo'] as String? ?? 'Sin tipo';
        final nombre = prestable['nombre'] as String? ?? 'Sin nombre';
        final key = '$tipo|$nombre';
        final prestado = prestamoDetalle['cantidad_prestada'] as int? ?? 0;

        if (!resultado.containsKey(key)) {
          resultado[key] = {
            'prestado': prestado,
            'devuelto_buen_estado': 0,
            'devuelto_danado': 0,
          };
          print('  ➕ Nuevo tipo: "$key" - Prestado: $prestado');
        }

        final devBuen = detalle.cantidadDevuelta;
        final devDanado = detalle.cantidadDaniadaTotal ?? 0;
        resultado[key]!['devuelto_buen_estado'] =
            resultado[key]!['devuelto_buen_estado']! + devBuen;
        resultado[key]!['devuelto_danado'] =
            resultado[key]!['devuelto_danado']! + devDanado;
        print('  ✓ "$key" actualizado - Buen estado: +$devBuen, Dañado: +$devDanado');
      }
    }
    // Proveedor
    else if (devolucion is DevolucionProveedor) {
      print('📦 [PROVEEDOR] Procesando ${devolucion.detalles!.length} detalles');
      for (var detalle in devolucion.detalles!) {
        final prestamoDetalle = detalle.detallePrestamoProveedor;
        if (prestamoDetalle == null || prestamoDetalle is! Map<String, dynamic>)
          continue;

        final prestable = prestamoDetalle['prestable'];
        if (prestable == null) continue;

        final tipo = prestable['tipo'] as String? ?? 'Sin tipo';
        final nombre = prestable['nombre'] as String? ?? 'Sin nombre';
        final key = '$tipo|$nombre';
        final prestado = prestamoDetalle['cantidad_prestada'] as int? ?? 0;

        if (!resultado.containsKey(key)) {
          resultado[key] = {
            'prestado': prestado,
            'devuelto_buen_estado': 0,
            'devuelto_danado': 0,
          };
          print('  ➕ Nuevo tipo: "$key" - Prestado: $prestado');
        }

        final devBuen = detalle.cantidadDevuelta;
        final devDanado = detalle.cantidadDaniadaTotal ?? 0;
        resultado[key]!['devuelto_buen_estado'] =
            resultado[key]!['devuelto_buen_estado']! + devBuen;
        resultado[key]!['devuelto_danado'] =
            resultado[key]!['devuelto_danado']! + devDanado;
        print('  ✓ "$key" actualizado - Buen estado: +$devBuen, Dañado: +$devDanado');
      }
    }

    print('✅ [SUMATORIA] Cálculo completado: ${resultado.length} tipos encontrados\n');
    resultado.forEach((key, stats) {
      print('  📊 $key: Prestado=${stats['prestado']}, BuenEstado=${stats['devuelto_buen_estado']}, Dañado=${stats['devuelto_danado']}');
    });

    return resultado;
  }

  // ✅ NUEVO: Construir item de devolución
  Widget _buildDevolucionItem(
    BuildContext context,
    dynamic devolucion,
    int numero,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String fechaDevolucion = 'N/A';
    String cantidadDevuelta = '0';
    String montoGarantia = '0.00';
    List<Widget> detalles = [];
    List<Widget> sumatorias = [];

    if (devolucion is DevolucionCliente) {
      fechaDevolucion = devolucion.fechaDevolucion ?? 'N/A';
      montoGarantia = devolucion.montoGarantiaDevueltaTotal ?? '0.00';

      // Calcular cantidad devuelta total
      int totalDevuelto = 0;
      if (devolucion.detalles != null) {
        for (var det in devolucion.detalles!) {
          totalDevuelto += det.cantidadDevuelta;
        }
      }
      cantidadDevuelta = totalDevuelto.toString();

      // Calcular sumatoria por tipo de prestable
      final sumatoriaPorTipo = _calcularSumatoriaPorTipo(devolucion);
      if (sumatoriaPorTipo.isNotEmpty) {
        sumatorias.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Resumen por Tipo:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
          ),
        );

        sumatoriaPorTipo.forEach((key, stats) {
          final tipoPrestable = key.split('|')[0];
          final nombrePrestable = key.split('|')[1];
          final prestado = stats['prestado'] ?? 0;
          final devueltoBuenEstado = stats['devuelto_buen_estado'] ?? 0;
          final devueltoDanado = stats['devuelto_danado'] ?? 0;
          final faltante = prestado - (devueltoBuenEstado + devueltoDanado);

          print('📋 [MOSTRAR] $tipoPrestable - $nombrePrestable: Prestado=$prestado, BuenEstado=$devueltoBuenEstado, Dañado=$devueltoDanado, Faltante=$faltante');

          sumatorias.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$tipoPrestable - $nombrePrestable',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Prestado: $prestado'),
                  const SizedBox(height: 4),
                  Text(
                    'Devuelto (Buen Estado): $devueltoBuenEstado',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (devueltoDanado > 0)
                    Text(
                      'Devuelto (Dañado): $devueltoDanado',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Faltante: $faltante',
                    style: TextStyle(
                      color: faltante > 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      }

      // Detalles de devolución
      /*if (devolucion.detalles != null && devolucion.detalles!.isNotEmpty) {
        for (var detalle in devolucion.detalles!) {
          detalles.add(
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '• Devuelto: ${detalle.cantidadDevuelta} unidades',
                    ),
                  ),
                ],
              ),
            ),
          );
          if (detalle.cantidadDaniadaTotal != null &&
              detalle.cantidadDaniadaTotal! > 0) {
            detalles.add(
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '• Dañadas: ${detalle.cantidadDaniadaTotal} unidades',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
      }*/
    } else if (devolucion is DevolucionEvento) {
      fechaDevolucion = devolucion.fechaDevolucion ?? 'N/A';
      cantidadDevuelta = devolucion.cantidadTotalDevuelta?.toString() ?? '0';
      montoGarantia = devolucion.montoGarantiaDevueltaTotal ?? '0.00';

      // Calcular sumatoria por tipo de prestable
      final sumatoriaPorTipo = _calcularSumatoriaPorTipo(devolucion);
      if (sumatoriaPorTipo.isNotEmpty) {
        sumatorias.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Resumen por Tipo:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.colorScheme.secondary,
              ),
            ),
          ),
        );

        sumatoriaPorTipo.forEach((key, stats) {
          final tipoPrestable = key.split('|')[0];
          final nombrePrestable = key.split('|')[1];
          final prestado = stats['prestado'] ?? 0;
          final devueltoBuenEstado = stats['devuelto_buen_estado'] ?? 0;
          final devueltoDanado = stats['devuelto_danado'] ?? 0;
          final faltante = prestado - (devueltoBuenEstado + devueltoDanado);

          print('📋 [MOSTRAR] $tipoPrestable - $nombrePrestable: Prestado=$prestado, BuenEstado=$devueltoBuenEstado, Dañado=$devueltoDanado, Faltante=$faltante');

          sumatorias.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$tipoPrestable - $nombrePrestable',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Prestado: $prestado',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Devuelto (Buen Estado): $devueltoBuenEstado',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (devueltoDanado > 0)
                    Text(
                      'Devuelto (Dañado): $devueltoDanado',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Faltante: $faltante',
                    style: TextStyle(
                      color: faltante > 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      }

      if (devolucion.detalles != null && devolucion.detalles!.isNotEmpty) {
        for (var detalle in devolucion.detalles!) {
          detalles.add(
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '• Devuelto: ${detalle.cantidadDevuelta} unidades',
                    ),
                  ),
                ],
              ),
            ),
          );
          if (detalle.cantidadDaniadaTotal != null &&
              detalle.cantidadDaniadaTotal! > 0) {
            detalles.add(
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '• Dañadas: ${detalle.cantidadDaniadaTotal} unidades',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
      }
    } else if (devolucion is DevolucionProveedor) {
      fechaDevolucion = devolucion.fechaDevolucion ?? 'N/A';
      cantidadDevuelta = devolucion.cantidadTotalDevuelta?.toString() ?? '0';
      montoGarantia = devolucion.montoGarantiaDevueltaTotal ?? '0.00';

      // Calcular sumatoria por tipo de prestable
      final sumatoriaPorTipo = _calcularSumatoriaPorTipo(devolucion);
      if (sumatoriaPorTipo.isNotEmpty) {
        sumatorias.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Resumen por Tipo:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
          ),
        );

        sumatoriaPorTipo.forEach((key, stats) {
          final tipoPrestable = key.split('|')[0];
          final nombrePrestable = key.split('|')[1];
          final prestado = stats['prestado'] ?? 0;
          final devueltoBuenEstado = stats['devuelto_buen_estado'] ?? 0;
          final devueltoDanado = stats['devuelto_danado'] ?? 0;
          final faltante = prestado - (devueltoBuenEstado + devueltoDanado);

          print('📋 [MOSTRAR] $tipoPrestable - $nombrePrestable: Prestado=$prestado, BuenEstado=$devueltoBuenEstado, Dañado=$devueltoDanado, Faltante=$faltante');

          sumatorias.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$tipoPrestable - $nombrePrestable',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Prestado: $prestado',
                    style: const TextStyle(fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Devuelto (Buen Estado): $devueltoBuenEstado',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (devueltoDanado > 0)
                    Text(
                      'Devuelto (Dañado): $devueltoDanado',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Faltante: $faltante',
                    style: TextStyle(
                      fontSize: 10,
                      color: faltante > 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      }

      if (devolucion.detalles != null && devolucion.detalles!.isNotEmpty) {
        for (var detalle in devolucion.detalles!) {
          detalles.add(
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '• Devuelto: ${detalle.cantidadDevuelta} unidades',
                    ),
                  ),
                ],
              ),
            ),
          );
          if (detalle.cantidadDaniadaTotal != null &&
              detalle.cantidadDaniadaTotal! > 0) {
            detalles.add(
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '• Dañadas: ${detalle.cantidadDaniadaTotal} unidades',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Número de devolución
        Text(
          'Devolución #$numero',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: context.colorScheme.secondary,
          ),
        ),
        // Fecha
        _buildItem(context, 'Fecha', _formatearFecha(fechaDevolucion)),
        // Monto garantía
        _buildItem(context, 'Monto Garantía Devuelto', 'Bs $montoGarantia'),
        // Sumatorias por tipo
        if (sumatorias.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(height: 8),
          const SizedBox(height: 8),
          ...sumatorias,
        ],
        // Detalles
        if (detalles.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Detalle por Almacén:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ...detalles,
        ],
      ],
    );
  }

  Widget _buildDetallesItems(BuildContext context) {
    final detalles = prestamo.detalles ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (detalles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Items Prestados',
                style: TextStyle(
                  color: context.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...detalles.map((detalle) {
                final cantidadPrestada = detalle.cantidadPrestada;
                final prestableName = detalle.prestable?.nombre ?? 'N/A';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prestableName,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Prestado: $cantidadPrestada unidades',
                              style: TextStyle(color: Colors.green.shade700),
                            ),
                            // ✅ NUEVO: Obtener devoluciones según tipo de préstamo
                            if (_obtenerDevoluciones(detalle).isNotEmpty)
                              Text(
                                'Devuelto: ${_calcularTotalDevuelto(detalle)} unidades',
                                style: TextStyle(color: Colors.green.shade600),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                RegistrarDevolucionScreen(prestamo: prestamo, tipo: tipo),
          ),
        );
      },
      icon: const Icon(Icons.check_circle),
      label: const Text('Registrar Devolución'),
      backgroundColor: Colors.green,
    );
  }

  // ✅ NUEVO: Abrir ubicación en mapa interactivo
  Future<void> _abrirMapa(dynamic ubicacion) async {
    try {
      if (mounted) {
        final ubicacionMapa = MapLocation(
          latitude: ubicacion.direccionCliente?.latitud ?? 0.0,
          longitude: ubicacion.direccionCliente?.longitud ?? 0.0,
          title: _getTituloPrestamo(),
          subtitle: 'Préstamo #${prestamo.id}',
          isSelected: false,
          markerColor: 'blue',
        );

        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return Scaffold(
              body: MapLocationSelector(
                initialLatitude: ubicacion.direccionCliente!.latitud!,
                initialLongitude: ubicacion.direccionCliente!.longitud!,
                additionalLocations: [ubicacionMapa],
                onLocationSelected: (lat, lng, address) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('📍 ${address ?? "Ubicación: $lat, $lng"}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            );
          },
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error abriendo mapa interactivo: $e');
      if (ubicacion.direccionCliente?.latitud != null &&
          ubicacion.direccionCliente?.longitud != null) {
        _abrirGoogleMaps(
          double.parse(ubicacion.direccionCliente!.latitud!),
          double.parse(ubicacion.direccionCliente!.longitud!),
        );
      }
    }
  }

  // ✅ NUEVO: Fallback a Google Maps externo
  Future<void> _abrirGoogleMaps(double latitud, double longitud) async {
    try {
      final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitud,$longitud',
      );

      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('No se pudo abrir Google Maps');
      }
    } catch (e) {
      debugPrint('Error abriendo Google Maps: $e');
    }
  }

  // ✅ NUEVO: Obtener título descriptivo del préstamo
  String _getTituloPrestamo() {
    switch (tipo) {
      case 'cliente':
        return prestamo.cliente?.nombre ?? 'Préstamo Cliente';
      case 'evento':
        return prestamo.nombreEvento ?? 'Préstamo Evento';
      case 'proveedor':
        return prestamo.proveedor?.nombre ?? 'Préstamo Proveedor';
      default:
        return 'Préstamo';
    }
  }
}
