import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

class UrlLauncherService {
  /// Realizar una llamada telefónica con reintentos
  /// Android solicita automáticamente el permiso CALL_PHONE cuando es necesario
  static Future<bool> makePhoneCall(String phoneNumber) async {
    try {
      // Validar que el número no esté vacío
      if (phoneNumber.isEmpty) {
        debugPrint('❌ Número de teléfono vacío');
        return false;
      }

      // Limpiar el número (remover espacios, guiones, etc.)
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      debugPrint('📞 Iniciando llamada a: $cleanNumber');

      final Uri launchUri = Uri(
        scheme: 'tel',
        path: cleanNumber,
      );

      // Reintentar hasta 3 veces en caso de error de canal
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          final bool canLaunch = await canLaunchUrl(launchUri);

          if (canLaunch) {
            await launchUrl(launchUri);
            debugPrint('✅ Llamada iniciada correctamente');
            return true;
          } else {
            debugPrint('❌ No se puede iniciar llamada (intento $attempt/3)');

            // Si es el último intento, retornar false
            if (attempt == 3) {
              return false;
            }

            // Esperar antes de reintentar
            await Future.delayed(Duration(milliseconds: 500));
          }
        } on Exception catch (e) {
          debugPrint('⚠️ Error en intento $attempt: $e');

          // Si es el último intento, retornar false
          if (attempt == 3) {
            debugPrint('❌ Error al realizar llamada después de 3 intentos: $e');
            return false;
          }

          // Esperar antes de reintentar
          await Future.delayed(Duration(milliseconds: 500));
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error inesperado en makePhoneCall: $e');
      return false;
    }
  }

  /// Abrir WhatsApp con un número específico
  static Future<bool> openWhatsApp(String phoneNumber) async {
    try {
      // Validar que el número no esté vacío
      if (phoneNumber.isEmpty) {
        debugPrint('❌ Número de teléfono vacío para WhatsApp');
        return false;
      }

      // Limpiar el número
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      // Si no comienza con +, agregar el código de país
      final whatsappNumber = cleanNumber.startsWith('+')
          ? cleanNumber
          : '+591$cleanNumber'; // Cambiar 591 al código de tu país si es necesario

      debugPrint('💬 Abriendo WhatsApp a: $whatsappNumber');

      // URLs para WhatsApp
      final Uri whatsappUri = Uri.parse('https://wa.me/$whatsappNumber');
      final Uri whatsappUriAlternative = Uri(
        scheme: 'whatsapp',
        path: '/send',
        queryParameters: {'phone': whatsappNumber},
      );

      // Reintentar hasta 3 veces
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          // Intentar con la URL estándar de WhatsApp primero
          if (await canLaunchUrl(whatsappUri)) {
            await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
            debugPrint('✅ WhatsApp abierto correctamente');
            return true;
          }

          // Si falla, intentar con la URI alternativa
          if (await canLaunchUrl(whatsappUriAlternative)) {
            await launchUrl(whatsappUriAlternative);
            debugPrint('✅ WhatsApp abierto correctamente (URI alternativa)');
            return true;
          }

          debugPrint('⚠️ No se puede abrir WhatsApp (intento $attempt/3)');

          if (attempt == 3) {
            return false;
          }

          await Future.delayed(Duration(milliseconds: 500));
        } on Exception catch (e) {
          debugPrint('⚠️ Error en intento $attempt: $e');

          if (attempt == 3) {
            debugPrint('❌ Error al abrir WhatsApp después de 3 intentos: $e');
            return false;
          }

          await Future.delayed(Duration(milliseconds: 500));
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error inesperado en openWhatsApp: $e');
      return false;
    }
  }

  /// Abrir URL en navegador
  static Future<bool> launchBrowser(String url) async {
    try {
      if (url.isEmpty) {
        debugPrint('❌ URL vacía');
        return false;
      }

      // Validar que la URL tenga scheme
      final Uri uri = Uri.parse(url);
      final Uri validUri = uri.scheme.isEmpty
          ? Uri.parse('https://$url')
          : uri;

      debugPrint('🌐 Abriendo URL: $validUri');

      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          if (await canLaunchUrl(validUri)) {
            await launchUrl(validUri, mode: LaunchMode.externalApplication);
            debugPrint('✅ URL abierta correctamente');
            return true;
          }

          debugPrint('⚠️ No se puede abrir URL (intento $attempt/3)');

          if (attempt == 3) {
            return false;
          }

          await Future.delayed(Duration(milliseconds: 500));
        } on Exception catch (e) {
          debugPrint('⚠️ Error en intento $attempt: $e');

          if (attempt == 3) {
            debugPrint('❌ Error al abrir URL después de 3 intentos: $e');
            return false;
          }

          await Future.delayed(Duration(milliseconds: 500));
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error inesperado en launchBrowser: $e');
      return false;
    }
  }

  /// Enviar email
  static Future<bool> sendEmail(String email, {String? subject, String? body}) async {
    try {
      if (email.isEmpty) {
        debugPrint('❌ Email vacío');
        return false;
      }

      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: {
          if (subject != null) 'subject': subject,
          if (body != null) 'body': body,
        },
      );

      debugPrint('📧 Abriendo email: $email');

      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          if (await canLaunchUrl(emailUri)) {
            await launchUrl(emailUri);
            debugPrint('✅ Email abierto correctamente');
            return true;
          }

          debugPrint('⚠️ No se puede abrir email (intento $attempt/3)');

          if (attempt == 3) {
            return false;
          }

          await Future.delayed(Duration(milliseconds: 500));
        } on Exception catch (e) {
          debugPrint('⚠️ Error en intento $attempt: $e');

          if (attempt == 3) {
            debugPrint('❌ Error al abrir email después de 3 intentos: $e');
            return false;
          }

          await Future.delayed(Duration(milliseconds: 500));
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error inesperado en sendEmail: $e');
      return false;
    }
  }
}
