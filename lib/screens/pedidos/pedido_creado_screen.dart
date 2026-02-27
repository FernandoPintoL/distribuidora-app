import 'package:flutter/material.dart';
import '../../config/app_text_styles.dart';
import '../../models/models.dart';
import '../../services/estados_helpers.dart'; // ✅ AGREGADO para estados dinámicos
import '../../extensions/theme_extension.dart';
import '../../services/api_service.dart';
import '../../services/print_service.dart'; // ✅ Para descargar PDFs
import 'dart:io' show Platform;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class PedidoCreadoScreen extends StatelessWidget {
  final Pedido pedido;
  // ✅ NUEVO: Parámetro para detectar si es creación o actualización
  final bool esActualizacion;

  const PedidoCreadoScreen({
    super.key,
    required this.pedido,
    this.esActualizacion = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animación de éxito
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF4CAF50).withOpacity(isDark ? 0.15 : 0.1),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 120,
                    color: Color(0xFF4CAF50),
                  ),
                ),

                const SizedBox(height: 32),

                // ✅ NUEVO: Título dinámico según sea creación o actualización
                Text(
                  esActualizacion ? 'Proforma Actualizada' : 'Proforma Creada',
                  style: TextStyle(
                    fontSize: AppTextStyles.displayMedium(context).fontSize!,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // ✅ NUEVO: Mensaje dinámico según sea creación o actualización
                Text(
                  esActualizacion
                      ? 'Los cambios han sido guardados exitosamente'
                      : 'Tu pedido ha sido registrado exitosamente',
                  style: TextStyle(
                    fontSize: AppTextStyles.bodyLarge(context).fontSize!,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Card con información del pedido
                Card(
                  elevation: 2,
                  color: colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Número de pedido con botón de impresión
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Número de Proforma',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: AppTextStyles.bodyMedium(
                                  context,
                                ).fontSize!,
                              ),
                            ),
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    fit: FlexFit.loose,
                                    child: Text(
                                      pedido.numero,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: AppTextStyles.bodyLarge(
                                          context,
                                        ).fontSize!,
                                        color: colorScheme.onSurface,
                                      ),
                                      textAlign: TextAlign.right,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // ✅ Botón de descargar/compartir impresión
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      // ✅ Usar ApiService para obtener baseUrl dinámicamente
                                      final apiService = ApiService();
                                      final baseUrl = apiService
                                          .baseUrl; // http://localhost:8000/api
                                      final impresionUrl =
                                          '$baseUrl/proformas/${pedido.id}/imprimir?formato=TICKET_80&accion=$value';

                                      _manejarAccionImpresion(
                                        context,
                                        value,
                                        impresionUrl,
                                        pedido.numero,
                                        colorScheme,
                                        pedido.id,
                                      );
                                    },
                                    itemBuilder: (BuildContext context) => [
                                      PopupMenuItem<String>(
                                        value: 'download',
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.download,
                                              size: 18,
                                              color: colorScheme.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('Descargar PDF'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'stream',
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.preview,
                                              size: 18,
                                              color: colorScheme.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('Ver en navegador'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'compartir',
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.share,
                                              size: 18,
                                              color: colorScheme.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('Compartir'),
                                          ],
                                        ),
                                      ),
                                    ],
                                    icon: Icon(
                                      Icons.more_vert,
                                      size: 20,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
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

                        // Estado
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Estado',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: AppTextStyles.bodyMedium(
                                  context,
                                ).fontSize!,
                              ),
                            ),
                            // ✅ ACTUALIZADO: Badge dinámico usando datos del estado
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  // ✅ CORREGIDO: Convertir hex string a Color
                                  color: _hexToColor(
                                    EstadosHelper.getEstadoColor(
                                      pedido.estadoCategoria,
                                      pedido.estadoCodigo,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      EstadosHelper.getEstadoIcon(
                                        pedido.estadoCategoria,
                                        pedido.estadoCodigo,
                                      ),
                                      style: TextStyle(
                                        fontSize: AppTextStyles.bodyLarge(
                                          context,
                                        ).fontSize!,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        pedido.estadoNombre,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
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

                        // Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: AppTextStyles.headlineSmall(
                                  context,
                                ).fontSize!,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                'Bs. ${pedido.total.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: AppTextStyles.headlineMedium(
                                    context,
                                  ).fontSize!,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4CAF50),
                                ),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ✅ NUEVO: Información adicional dinámica según sea creación o actualización
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(
                      isDark ? 0.15 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          esActualizacion
                              ? 'Tu proforma ha sido actualizada correctamente. Los cambios serán revisados por nuestro equipo.'
                              : 'Tu proforma está pendiente de aprobación. Te notificaremos cuando sea aprobada y esté lista para entrega.',
                          style: TextStyle(
                            fontSize: AppTextStyles.bodyMedium(
                              context,
                            ).fontSize!,
                            color: colorScheme.onSurface,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Botones
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/mis-pedidos',
                            (route) => route.isFirst,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Ver Mis Pedidos',
                          style: TextStyle(
                            fontSize: AppTextStyles.bodyLarge(
                              context,
                            ).fontSize!,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/',
                            (route) => false,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Volver al Inicio',
                          style: TextStyle(
                            fontSize: AppTextStyles.bodyLarge(
                              context,
                            ).fontSize!,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ Manejar acciones de impresión/descarga
  static void _manejarAccionImpresion(
    BuildContext context,
    String accion,
    String impresionUrl,
    String numeroPedido,
    ColorScheme colorScheme,
    int proformaId,
  ) async {
    try {
      switch (accion) {
        case 'download':
          // ✅ Descargar PDF usando PrintService (como en pedidos_historial_screen)
          final printService = PrintService();
          final success = await printService.downloadDocument(
            documentoId: proformaId,
            documentType: PrintDocumentType.proforma,
            format: PrintFormat.ticket80,
          );

          if (!success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo descargar el PDF'),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.red,
              ),
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Abriendo PDF...'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
          break;

        case 'stream':
          // ✅ Ver en navegador
          final streamUrl = impresionUrl.replaceAll(
            'accion=stream',
            'accion=stream',
          );
          if (await canLaunchUrl(Uri.parse(streamUrl))) {
            await launchUrl(
              Uri.parse(streamUrl),
              mode: LaunchMode.externalApplication,
            );
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('No se pudo abrir el navegador'),
                  backgroundColor: colorScheme.error,
                ),
              );
            }
          }
          break;

        case 'compartir':
          // ✅ Compartir
          await Share.share(
            'Proforma: $numeroPedido\n\nDescargar PDF: $impresionUrl',
            subject: 'Proforma $numeroPedido',
          );
          break;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  /// ✅ HELPER: Convertir hex string (#RRGGBB) a Color
  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) {
      buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
    } else if (hexString.length == 8 || hexString.length == 9) {
      buffer.write(hexString.replaceFirst('#', ''));
    } else {
      return Colors.grey; // Fallback
    }
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
