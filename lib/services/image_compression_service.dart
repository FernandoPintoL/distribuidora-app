import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageCompressionService {
  // Limite de tamano en bytes (1MB = 1048576 bytes)
  static const int maxImageSizeBytes = 1048576; // 1 MB

  /// Comprime una imagen y valida que pese menos de 1MB
  /// Retorna la imagen comprimida si es valida
  /// Lanza una excepcion si excede el limite de tamano
  static Future<File> comprimirYValidarImagen(
    File imagenOriginal, {
    int quality = 85, // Calidad inicial de compresion (0-100)
  }) async {
    try {
      // Obtener el tamano original
      final sizeOriginal = await imagenOriginal.length();
      debugPrint(
        '📸 [COMPRESSION] Imagen original: ${(sizeOriginal / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      // Si ya esta bajo el limite, retornar tal cual
      if (sizeOriginal <= maxImageSizeBytes) {
        debugPrint('✅ [COMPRESSION] Imagen dentro del limite, no requiere compresion');
        return imagenOriginal;
      }

      // Comprimir de forma progresiva si es necesario
      File? imagenComprimida = await _comprimirImagen(
        imagenOriginal,
        quality: quality,
      );

      if (imagenComprimida == null) {
        throw Exception('No se pudo comprimir la imagen');
      }

      final sizeComprimida = await imagenComprimida.length();
      debugPrint(
        '📸 [COMPRESSION] Imagen comprimida: ${(sizeComprimida / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      // Si aun excede, intentar comprimiendo mas agresivamente
      if (sizeComprimida > maxImageSizeBytes && quality > 50) {
        return await comprimirYValidarImagen(
          imagenOriginal,
          quality: quality - 10,
        );
      }

      // Validar que no exceda el limite
      if (sizeComprimida > maxImageSizeBytes) {
        throw ImageTooLargeException(
          'La imagen supera el limite de 1MB incluso despues de la compresion. '
          'Tamano final: ${(sizeComprimida / 1024 / 1024).toStringAsFixed(2)} MB',
        );
      }

      debugPrint('✅ [COMPRESSION] Imagen valida despues de compresion');
      return imagenComprimida;
    } catch (e) {
      debugPrint('❌ [COMPRESSION] Error: $e');
      rethrow;
    }
  }

  /// Comprime una imagen usando flutter_image_compress
  static Future<File?> _comprimirImagen(
    File imagenOriginal, {
    required int quality,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        imagenOriginal.absolute.path,
        targetPath,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      debugPrint('❌ [_COMPRIMIR_IMAGEN] Error: $e');
      return null;
    }
  }

  /// Valida que una imagen no exceda el limite de tamano
  static Future<bool> validarTamano(File imagen) async {
    final size = await imagen.length();
    return size <= maxImageSizeBytes;
  }

  /// Obtiene el tamano de una imagen en MB
  static Future<double> obtenerTamanoEnMB(File imagen) async {
    final bytes = await imagen.length();
    return bytes / 1024 / 1024;
  }

  /// Obtiene un mensaje de error legible para el usuario
  static String obtenerMensajeError(dynamic exception) {
    if (exception is ImageTooLargeException) {
      return exception.message;
    }
    return 'Error al procesar la imagen. Por favor, intenta de nuevo.';
  }
}

/// Excepcion personalizada para imagenes que exceden el limite
class ImageTooLargeException implements Exception {
  final String message;

  ImageTooLargeException(this.message);

  @override
  String toString() => message;
}
