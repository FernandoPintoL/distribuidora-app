import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/api_service.dart';
import '../../services/print_service.dart';

/// Servicio para descargar y compartir stock disponible
class StockDownloadService {
  final BuildContext context;

  StockDownloadService(this.context);

  void mostrarOpcionesDescargar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Stock y Lista de Precios Disponibles',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: const Text('Descargar Lista de Precios como PDF'),
                  subtitle: const Text('Para compartir o guardar'),
                  onTap: () {
                    Navigator.pop(context);
                    descargarStockPdf();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.hd, color: Colors.deepOrange),
                  title: const Text('Descargar Lista de Precios como Imagen'),
                  subtitle: const Text('Para compartir'),
                  onTap: () {
                    Navigator.pop(context);
                    descargarStockImagen(conStock: false);
                  },
                ),
                const Divider(height: 1),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Lista de precios con Stock disponible',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: const Text(
                    'Lista de precios con Stock disponible como PDF',
                  ),
                  subtitle: const Text('Incluye columna de stock disponible'),
                  onTap: () {
                    Navigator.pop(context);
                    descargarStockPdfConStock();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.hd, color: Colors.deepOrange),
                  title: const Text(
                    'Lista de precios con Stock disponible como Imagen',
                  ),
                  subtitle: const Text('Incluye columna de stock disponible'),
                  onTap: () {
                    Navigator.pop(context);
                    descargarStockImagen(conStock: true);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> descargarStockPdf() async {
    _mostrarSnackBar('Descargando PDF...');

    try {
      final bytes = await ApiService().descargarStockDisponiblePdf();

      if (context.mounted) {
        await PrintService().abrirPdfDesdeBytes(
          pdfBytes: bytes,
          nombreArchivo: 'stock-disponible.pdf',
        );
      }
    } catch (e) {
      _mostrarError('Error al descargar: ${e.toString()}');
      debugPrint('❌ Error descargando PDF: $e');
    }
  }

  Future<void> descargarStockPdfConStock() async {
    _mostrarSnackBar('Descargando PDF con stock...');

    try {
      final bytes = await ApiService().descargarStockDisponiblePdfConStock();

      if (context.mounted) {
        await PrintService().abrirPdfDesdeBytes(
          pdfBytes: bytes,
          nombreArchivo: 'stock-disponible-con-stock.pdf',
        );
      }
    } catch (e) {
      _mostrarError('Error al descargar: ${e.toString()}');
      debugPrint('❌ Error descargando PDF con stock: $e');
    }
  }

  Future<void> descargarStockImagen({bool conStock = false}) async {
    final titulo = conStock ? 'imagen HD con stock' : 'imagen HD';
    _mostrarSnackBar('Descargando $titulo con servicio Python 🐍...');

    try {
      debugPrint(
        '🐍 Iniciando descarga de imagen Python (conStock: $conStock)',
      );
      final bytes = await ApiService().descargarStockDisponibleImagenPython(
        conStock: conStock,
      );

      if (context.mounted) {
        debugPrint(
          '✅ Imagen Python recibida: ${(bytes.length / 1024).toStringAsFixed(2)} KB',
        );
        _mostrarImagenConOpciones(bytes);
      }
    } catch (e) {
      _mostrarError('Error al descargar: ${e.toString()}');
      debugPrint('❌ Error descargando imagen Python: $e');
    }
  }

  void _mostrarImagenConOpciones(List<int> imageBytes) {
    final fileName = 'stock-disponible.jpg';
    final isImage = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                Uint8List.fromList(imageBytes),
                fit: BoxFit.contain,
                height: 400,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (isImage)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _compartirImagenWhatsApp(imageBytes);
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (isImage) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _compartirImagen(imageBytes, fileName: fileName);
                    },
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Compartir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
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

  Future<void> _compartirImagenWhatsApp(List<int> imageBytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/stock-disponible.png');
      await file.writeAsBytes(imageBytes);
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      _mostrarError('Error: $e');
    }
  }

  Future<void> _compartirImagen(
    List<int> imageBytes, {
    String fileName = 'stock-disponible.jpg',
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      _mostrarError('Error: $e');
    }
  }

  void _mostrarSnackBar(String mensaje) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }

  void _mostrarError(String mensaje) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
