import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Utilidades para llamadas telefónicas y WhatsApp
class PhoneUtils {
  /// Llamar a un teléfono usando la app nativa
  static Future<void> llamarCliente(
    BuildContext context,
    String? telefono,
  ) async {
    if (telefono == null || telefono.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay teléfono disponible'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: telefono);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        debugPrint('No se pudo abrir teléfono');
      }
    } catch (e) {
      debugPrint('Error al llamar: $e');
    }
  }

  /// Enviar WhatsApp a un número
  static Future<void> enviarWhatsApp(
    BuildContext context,
    String? telefono,
  ) async {
    if (telefono == null || telefono.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay teléfono disponible'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Limpiar teléfono (remover espacios, caracteres especiales)
    final telefonoLimpio = telefono.replaceAll(RegExp(r'[^\d+]'), '');

    final Uri whatsappUri = Uri.parse('https://wa.me/$telefonoLimpio');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('WhatsApp no disponible');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp no está instalado'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al enviar WhatsApp: $e');
    }
  }
}
