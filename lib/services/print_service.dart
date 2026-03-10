import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'api_service.dart';

/// Formatos de impresión disponibles
enum PrintFormat {
  ticket58("TICKET_58", "Ticket 58mm (Compacto)"),
  ticket80("TICKET_80", "Ticket 80mm (Recomendado)"),
  a4("A4", "A4 (Factura Completa)");

  final String code;
  final String label;

  const PrintFormat(this.code, this.label);
}

/// Tipos de documentos que se pueden imprimir
enum PrintDocumentType {
  venta("ventas"),
  entrega("entregas"),
  proforma("proformas"),
  envio("envios");

  final String endpoint;

  const PrintDocumentType(this.endpoint);
}

/// Servicio para gestionar impresión de tickets y facturas
///
/// Proporciona funcionalidades para:
/// - Generar URLs de previsualizacion/impresión
/// - Abrir tickets en navegador o app PDF
/// - Soportar múltiples formatos de impresión
class PrintService {
  final ApiService _apiService = ApiService();
  static const platform = MethodChannel('com.distribuidora.paucara/files');
  static const String tokenKey = 'auth_token';

  /// Obtener token almacenado con formato Bearer
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(tokenKey);
      if (token != null) {
        debugPrint('✅ Token cargado de SharedPreferences');
        return 'Bearer $token';
      }
    } catch (e) {
      debugPrint('⚠️ Error cargando token: $e');
    }
    return null;
  }

  /// Obtener URL de impresión/preview para una venta (método específico por compatibilidad)
  ///
  /// Parámetros:
  /// - ventaId: ID de la venta a imprimir
  /// - format: Formato de impresión (default: TICKET_80)
  /// - download: Si es true, retorna URL de descarga; si es false, retorna URL de preview
  ///
  /// Retorna:
  /// - URL completa de impresión/preview
  @Deprecated('Usar getPrintUrl() con PrintDocumentType.venta')
  String getPrintUrlForVenta({
    required int ventaId,
    PrintFormat format = PrintFormat.ticket80,
    bool download = false,
  }) {
    return getPrintUrl(
      documentoId: ventaId,
      documentType: PrintDocumentType.venta,
      format: format,
      download: download,
    );
  }

  /// Abrir preview de ticket en navegador
  ///
  /// Parámetros:
  /// - ventaId: ID de la venta
  /// - format: Formato de impresión (default: TICKET_80)
  ///
  /// Retorna:
  /// - true si se logró abrir el navegador
  /// - false si hubo error
  Future<bool> previewTicket({
    required int ventaId,
    PrintFormat format = PrintFormat.ticket80,
  }) async {
    try {
      final url = getPrintUrl(
        documentoId: ventaId,
        documentType: PrintDocumentType.venta,
        format: format,
        download: false,
      );

      debugPrint('🖨️ Abriendo preview: $url');

      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('✅ Preview abierto exitosamente');
        return true;
      } else {
        debugPrint('❌ No se pudo abrir la URL: $url');
        return false;
      }
    } catch (e) {
      debugPrint('Error opening preview: $e');
      return false;
    }
  }

  /// Descargar ticket
  ///
  /// Parámetros:
  /// - ventaId: ID de la venta
  /// - format: Formato de impresión (default: TICKET_80)
  ///
  /// Retorna:
  /// - true si se logró iniciar descarga
  /// - false si hubo error
  Future<bool> downloadTicket({
    required int ventaId,
    PrintFormat format = PrintFormat.ticket80,
  }) async {
    try {
      final url = getPrintUrl(
        documentoId: ventaId,
        documentType: PrintDocumentType.venta,
        format: format,
        download: true,
      );

      debugPrint('📥 Descargando ticket: $url');

      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('✅ Descarga iniciada exitosamente');
        return true;
      } else {
        debugPrint('❌ No se pudo abrir la URL de descarga: $url');
        return false;
      }
    } catch (e) {
      debugPrint('Error downloading ticket: $e');
      return false;
    }
  }

  /// Alias para printTicket - abre preview en navegador
  Future<bool> printTicket({
    required int ventaId,
    PrintFormat format = PrintFormat.ticket80,
  }) async {
    return previewTicket(
      ventaId: ventaId,
      format: format,
    );
  }

  /// Obtener URL de impresión genérica para cualquier documento
  ///
  /// Parámetros:
  /// - documentoId: ID del documento a imprimir
  /// - documentType: Tipo de documento (venta, entrega, proforma, envio)
  /// - format: Formato de impresión (default: TICKET_80)
  /// - download: Si es true, retorna URL de descarga; si es false, retorna URL de preview
  ///
  /// Retorna:
  /// - URL completa de impresión/preview
  String getPrintUrl({
    required int documentoId,
    required PrintDocumentType documentType,
    PrintFormat format = PrintFormat.ticket80,
    bool download = false,
  }) {
    final apiService = ApiService();
    final baseUrl = apiService.getBaseUrl();

    // ✅ ACTUALIZADO: Ahora todos usan /api (rutas creadas en api.php)
    // baseUrl = "http://192.168.100.22:8000/api"
    // Entregas: /api/entregas/{id}/descargar
    // Ventas: /api/ventas/{id}/imprimir
    // Proformas: /api/proformas/{id}/imprimir (futuro)
    // Envios: /api/envios/{id}/imprimir (futuro)

    late String fullUrl;

    if (documentType == PrintDocumentType.entrega) {
      // Entregas usa /api/entregas/{id}/descargar
      // Ejemplo: http://192.168.100.22:8000/api/entregas/1/descargar?formato=TICKET_80&accion=download
      final endpoint = 'descargar';
      if (download) {
        fullUrl = '$baseUrl/${documentType.endpoint}/$documentoId/$endpoint'
            '?formato=${format.code}&accion=download';
      } else {
        fullUrl = '$baseUrl/${documentType.endpoint}/$documentoId/preview'
            '?formato=${format.code}';
      }
    } else if (documentType == PrintDocumentType.venta) {
      // Ventas usa /api/ventas/{id}/imprimir
      // Ejemplo: http://192.168.100.22:8000/api/ventas/1/imprimir?formato=TICKET_80&accion=download
      final endpoint = 'imprimir';

      if (download) {
        fullUrl = '$baseUrl/${documentType.endpoint}/$documentoId/$endpoint'
            '?formato=${format.code}&accion=download';
      } else {
        fullUrl = '$baseUrl/${documentType.endpoint}/$documentoId/preview'
            '?formato=${format.code}';
      }
    } else {
      // Proformas, Envios, etc. - usar /api (futuro)
      final endpoint = 'imprimir';

      if (download) {
        fullUrl = '$baseUrl/${documentType.endpoint}/$documentoId/$endpoint'
            '?formato=${format.code}&accion=download';
      } else {
        fullUrl = '$baseUrl/${documentType.endpoint}/$documentoId/preview'
            '?formato=${format.code}';
      }
    }

    debugPrint('🔗 [getPrintUrl] URL generada: $fullUrl');
    return fullUrl;
  }

  /// Obtener URL de impresión/preview para una entrega (método específico por compatibilidad)
  @Deprecated('Usar getPrintUrl() con PrintDocumentType.entrega')
  String getEntregaPrintUrl({
    required int entregaId,
    PrintFormat format = PrintFormat.ticket80,
    bool download = false,
  }) {
    return getPrintUrl(
      documentoId: entregaId,
      documentType: PrintDocumentType.entrega,
      format: format,
      download: download,
    );
  }

  /// Descargar documento genérico directamente con autenticación
  ///
  /// Parámetros:
  /// - documentoId: ID del documento
  /// - documentType: Tipo de documento (venta, entrega, proforma, envio)
  /// - format: Formato de impresión (default: TICKET_80)
  ///
  /// Retorna:
  /// - true si se logró descargar y abrir el archivo
  /// - false si hubo error
  Future<bool> downloadDocument({
    required int documentoId,
    required PrintDocumentType documentType,
    PrintFormat format = PrintFormat.ticket80,
  }) async {
    try {
      // ✅ CORREGIDO: Obtener URL completa correctamente según tipo de documento
      final fullUrl = getPrintUrl(
        documentoId: documentoId,
        documentType: documentType,
        format: format,
        download: true,
      );

      debugPrint('📥 Descargando ${documentType.endpoint} con autenticación: $fullUrl');

      // ✅ CORREGIDO: Crear nuevo Dio SIN baseUrl para evitar que agregue /api
      // El Dio del _apiService tiene baseUrl configurado, así que lo agrega siempre
      final dio = Dio();

      // ✅ CORREGIDO: Cargar token del almacenamiento con formato Bearer
      final authToken = await _getAuthToken();
      if (authToken != null) {
        dio.options.headers['Authorization'] = authToken;
        debugPrint('✅ Auth token set on new Dio instance');
      } else {
        debugPrint('⚠️ WARNING: No auth token found in storage!');
      }
      dio.options.headers['Accept'] = 'application/json';

      debugPrint('📋 Headers being sent: ${dio.options.headers}');

      final response = await dio.get(
        fullUrl,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode != 200) {
        debugPrint('❌ Error en descarga: ${response.statusCode}');
        debugPrint('📄 Response data: ${response.statusMessage}');
        return false;
      }

      // ✅ Obtener directorio de caché de la app (accesible sin permisos especiales)
      final Directory? cacheDir = await getDownloadsDirectory();
      if (cacheDir == null) {
        debugPrint('❌ No se pudo acceder al directorio de descargas');
        return false;
      }

      // Generar nombre de archivo
      final fileName =
          '${documentType.endpoint}_${documentoId}_${format.code}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${cacheDir.path}/$fileName';

      // Guardar archivo
      final file = File(filePath);
      await file.writeAsBytes(response.data);

      debugPrint('✅ PDF descargado exitosamente');
      debugPrint('📁 Ubicación: $filePath');

      // ✅ Intentar abrir el PDF usando MethodChannel (con FileProvider)
      try {
        final bool opened = await platform.invokeMethod(
          'openFile',
          {'path': filePath},
        );

        if (opened) {
          debugPrint('✅ PDF abierto automáticamente');
        } else {
          debugPrint('⚠️ No hay app para abrir PDFs, pero el archivo se descargó correctamente');
          debugPrint('📁 El archivo está guardado en: $filePath');
        }
      } catch (e) {
        debugPrint('⚠️ Error abriendo PDF: $e');
        debugPrint('📁 El archivo está guardado en: $filePath');
      }

      // Consideramos éxito si el archivo se descargó correctamente
      return true;
    } catch (e) {
      debugPrint('❌ Error downloading document: $e');
      return false;
    }
  }

  /// Descargar ticket de entrega en formato 58mm (método específico por compatibilidad)
  @Deprecated('Usar downloadDocument() con PrintDocumentType.entrega')
  Future<bool> downloadEntregaTicket({
    required int entregaId,
    PrintFormat format = PrintFormat.ticket58,
  }) async {
    return downloadDocument(
      documentoId: entregaId,
      documentType: PrintDocumentType.entrega,
      format: format,
    );
  }

  /// Preview de documento genérico (venta, entrega, proforma, envio)
  ///
  /// Parámetros:
  /// - documentoId: ID del documento
  /// - documentType: Tipo de documento (venta, entrega, proforma, envio)
  /// - format: Formato de impresión (default: TICKET_80)
  ///
  /// Retorna:
  /// - true si se logró abrir el navegador
  /// - false si hubo error
  Future<bool> previewDocument({
    required int documentoId,
    required PrintDocumentType documentType,
    PrintFormat format = PrintFormat.ticket80,
  }) async {
    try {
      final url = getPrintUrl(
        documentoId: documentoId,
        documentType: documentType,
        format: format,
        download: false,
      );

      debugPrint('🖨️ Abriendo preview: $url');

      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('✅ Preview abierto exitosamente');
        return true;
      } else {
        debugPrint('❌ No se pudo abrir la URL: $url');
        return false;
      }
    } catch (e) {
      debugPrint('Error opening preview: $e');
      return false;
    }
  }

  /// Preview de ticket de entrega (método específico por compatibilidad)
  @Deprecated('Usar previewDocument() con PrintDocumentType.entrega')
  Future<bool> previewEntregaTicket({
    required int entregaId,
    PrintFormat format = PrintFormat.ticket80,
  }) async {
    return previewDocument(
      documentoId: entregaId,
      documentType: PrintDocumentType.entrega,
      format: format,
    );
  }

  /// ✅ NUEVO: Abrir PDF desde bytes (para descargas de API)
  ///
  /// Parámetros:
  /// - pdfBytes: Bytes del PDF a abrir
  /// - nombreArchivo: Nombre del archivo a guardar
  ///
  /// Retorna:
  /// - true si se abrió exitosamente
  /// - false si hubo error
  Future<bool> abrirPdfDesdeBytes({
    required List<int> pdfBytes,
    required String nombreArchivo,
  }) async {
    try {
      // Obtener directorio cache
      final cacheDir = await getTemporaryDirectory();
      final filePath = '${cacheDir.path}/$nombreArchivo';

      // Guardar archivo
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      debugPrint('✅ PDF guardado correctamente');
      debugPrint('📁 Ubicación: $filePath');

      // Intentar abrir el PDF usando MethodChannel (con FileProvider)
      try {
        final bool opened = await platform.invokeMethod(
          'openFile',
          {'path': filePath},
        );

        if (opened) {
          debugPrint('✅ PDF abierto automáticamente');
          return true;
        } else {
          debugPrint('⚠️ No hay app para abrir PDFs, pero el archivo se descargó correctamente');
          debugPrint('📁 El archivo está guardado en: $filePath');
          return true; // Consideramos éxito si el archivo se guardó
        }
      } catch (e) {
        debugPrint('⚠️ Error abriendo PDF: $e');
        debugPrint('📁 El archivo está guardado en: $filePath');
        return true; // Consideramos éxito si el archivo se guardó
      }
    } catch (e) {
      debugPrint('❌ Error procesando PDF: $e');
      return false;
    }
  }

  /// ✅ NUEVO: Guardar imagen en carpeta visible del dispositivo
  ///
  /// Parámetros:
  /// - imageBytes: Bytes de la imagen a guardar
  /// - nombreArchivo: Nombre del archivo a guardar
  ///
  /// Guarda en: /storage/emulated/0/Download/ (carpeta pública visible)
  Future<bool> guardarImageenEnDescargas({
    required List<int> imageBytes,
    required String nombreArchivo,
  }) async {
    try {
      // ✅ Intentar guardar en /storage/emulated/0/Download/ (público y visible)
      final downloadDir = Directory('/storage/emulated/0/Download');

      // Crear directorio si no existe
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final filePath = '${downloadDir.path}/$nombreArchivo';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      debugPrint('✅ Imagen guardada exitosamente');
      debugPrint('📁 Ubicación: $filePath');
      debugPrint('📱 Accesible desde: Archivo > Download');

      return true;

    } catch (e) {
      debugPrint('❌ Error guardando imagen en Download: $e');
      debugPrint('⏮️ Intentando guardar en Downloads estándar...');

      try {
        // Fallback a Downloads estándar
        final Directory? downloadsDir = await getDownloadsDirectory();

        if (downloadsDir != null) {
          final filePath = '${downloadsDir.path}/$nombreArchivo';
          final file = File(filePath);
          await file.writeAsBytes(imageBytes);

          debugPrint('✅ Imagen guardada en Downloads');
          debugPrint('📁 Ubicación: $filePath');
          return true;
        }

        return false;
      } catch (fallbackError) {
        debugPrint('❌ Error en fallback: $fallbackError');
        return false;
      }
    }
  }
}

/// Extensión para ApiService para obtener baseUrl
extension ApiServiceExt on ApiService {
  String getBaseUrl() {
    // ✅ CORREGIDO: Obtener baseUrl dinámico del ApiService
    return baseUrl;
  }
}
