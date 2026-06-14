import 'package:flutter/material.dart';
import '../../../config/app_text_styles.dart';

class GaleriaImagenesWidget extends StatelessWidget {
  final Map<String, dynamic>? entregaData;
  final Function(BuildContext, List<String>, int) mostrarVisorImagenes;

  const GaleriaImagenesWidget({
    Key? key,
    required this.entregaData,
    required this.mostrarVisorImagenes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extraer fotos de las confirmaciones
    List<String> imagenes = [];

    if (entregaData != null) {
      // Obtener fotos de confirmaciones
      if (entregaData?['confirmacionesVentas'] != null) {
        for (var confirmacion in entregaData?['confirmacionesVentas'] as List) {
          final conf = confirmacion as Map;

          // Fotos de la entrega
          if (conf['fotos'] != null) {
            final fotos = conf['fotos'];
            if (fotos is List) {
              imagenes.addAll(fotos.cast<String>());
            } else if (fotos is String) {
              imagenes.add(fotos);
            }
          }

          // Firma digital
          if (conf['firma_digital_url'] != null &&
              conf['firma_digital_url'].toString().isNotEmpty) {
            imagenes.add(conf['firma_digital_url'].toString());
          }
        }
      }
    }

    // Si no hay imágenes, mostrar mensaje
    if (imagenes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Text(
          'No hay imágenes de esta entrega',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Galería de miniaturas
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📸 Imágenes de la Entrega',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: imagenes.asMap().entries.map((entry) {
                final index = entry.key;
                final imagenUrl = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => mostrarVisorImagenes(context, imagenes, index),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imagenUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
