import 'package:flutter/material.dart';
import '../../../../config/app_text_styles.dart';
import '../../../../models/venta.dart';
import 'models.dart';

// ✅ WIDGET: Formulario para Registro de Novedad
class FormularioNovedadWidget extends StatelessWidget {
  final BuildContext screenContext;
  final bool isDarkMode;
  final String? tipoNovedad;
  final List<Map<String, String>> tiposNovedad;
  final Venta venta;
  final TextEditingController observacionesController;
  final List<dynamic> fotosCapturadas;
  final Function(int index) eliminarFoto;
  final VoidCallback capturarFoto;
  final Function(dynamic foto) construirImagenFoto;
  final Function(BuildContext context, bool isDarkMode) buildTablaProductosRechazados;
  final Function(double totalVenta) buildResumenMontos;
  final Function(BuildContext context, bool isDarkMode) buildPagoForm;
  final List<PagoEntrega> pagos;
  final List<Map<String, dynamic>> tiposPago;
  final Function(String value) onTipoNovedadChanged;

  const FormularioNovedadWidget({
    Key? key,
    required this.screenContext,
    required this.isDarkMode,
    required this.tipoNovedad,
    required this.tiposNovedad,
    required this.venta,
    required this.observacionesController,
    required this.fotosCapturadas,
    required this.eliminarFoto,
    required this.capturarFoto,
    required this.construirImagenFoto,
    required this.buildTablaProductosRechazados,
    required this.buildResumenMontos,
    required this.buildPagoForm,
    required this.pagos,
    required this.tiposPago,
    required this.onTipoNovedadChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final esNovedadSimple = tipoNovedad == 'CLIENTE_CERRADO' || tipoNovedad == 'RECHAZADO';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tipo de Novedad
                  Text(
                    'Tipo de Novedad',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._buildTiposNovedadOptions(context),
                  const SizedBox(height: 24),
                  // Mostrar tabla y resumen SOLO si NO es novedad simple
                  if (!esNovedadSimple) ...[
                    if (tipoNovedad == 'DEVOLUCION_PARCIAL')
                      Column(
                        children: [
                          buildTablaProductosRechazados(context, isDarkMode),
                          const SizedBox(height: 24),
                        ],
                      ),
                    // Resumen de montos
                    buildResumenMontos(venta.total),
                    const SizedBox(height: 24),
                  ],
                  // Campo de Observaciones
                  Text(
                    'Observaciones',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Detalla lo sucedido para mejor seguimiento',
                    style: TextStyle(
                      fontSize: AppTextStyles.bodySmall(context).fontSize!,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: observacionesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'Ej: Cliente no está en la dirección, volveré a intentar...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Sección de Fotos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Fotos de la Novedad',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${fotosCapturadas.length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Captura fotos como evidencia de la novedad',
                    style: TextStyle(
                      fontSize: AppTextStyles.bodySmall(context).fontSize!,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Galería de fotos
                  if (fotosCapturadas.isNotEmpty)
                    Column(
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: fotosCapturadas.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: construirImagenFoto(
                                    fotosCapturadas[index],
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => eliminarFoto(index),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  // Botón para capturar foto
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: capturarFoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Capturar Foto'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Sección de pagos SOLO para devolución parcial
                  if (tipoNovedad == 'DEVOLUCION_PARCIAL' &&
                      venta.estadoPago != 'CREDITO') ...[
                    buildPagoForm(context, isDarkMode),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTiposNovedadOptions(BuildContext context) {
    return tiposNovedad.map((tipo) {
      final isSelected = tipoNovedad == tipo['value'];
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: isSelected
              ? isDarkMode
                  ? Colors.orange[900]!.withOpacity(0.3)
                  : Colors.orange.withOpacity(0.15)
              : isDarkMode
              ? Colors.grey.withOpacity(0.1)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              onTipoNovedadChanged(tipo['value']!);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? isDarkMode
                          ? Colors.orange[600]!
                          : Colors.orange
                      : isDarkMode
                      ? Colors.grey.withOpacity(0.4)
                      : Colors.grey.withOpacity(0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: tipo['value']!,
                    groupValue: tipoNovedad,
                    onChanged: (value) {
                      if (value != null) {
                        onTipoNovedadChanged(value);
                      }
                    },
                    activeColor: isDarkMode
                        ? Colors.orange[400]
                        : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tipo['label']!,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tipo['description']!,
                          style: TextStyle(
                            fontSize: AppTextStyles.bodySmall(context).fontSize!,
                            color: Colors.grey[600],
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
}

