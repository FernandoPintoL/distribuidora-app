import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert' show base64Encode;
import 'package:flutter/services.dart';
import '../../../models/entrega.dart';
import '../../../models/venta.dart';
import '../../../providers/entrega_provider.dart';
import '../../../services/image_compression_service.dart';  // ✅ NUEVO: Para comprimir imágenes

class ConfirmarEntregaVentaScreen extends StatefulWidget {
  final Entrega entrega;
  final Venta venta;
  final EntregaProvider provider;

  const ConfirmarEntregaVentaScreen({
    Key? key,
    required this.entrega,
    required this.venta,
    required this.provider,
  }) : super(key: key);

  @override
  State<ConfirmarEntregaVentaScreen> createState() =>
      _ConfirmarEntregaVentaScreenState();
}

class _ConfirmarEntregaVentaScreenState
    extends State<ConfirmarEntregaVentaScreen> {
  // Estados de la pantalla
  int _paso = 1; // 1: Seleccionar tipo, 2: Detalles de novedad, 3: Confirmación

  // Datos capturados
  String? _tipoEntrega; // COMPLETA o NOVEDAD
  String? _tipoNovedad; // CLIENTE_CERRADO, DEVOLUCION_PARCIAL, RECHAZADO
  final TextEditingController _observacionesController = TextEditingController();
  List<File> _fotosCapturadas = [];

  final ImagePicker _imagePicker = ImagePicker();

  final List<Map<String, String>> _tiposNovedad = [
    {
      'value': 'CLIENTE_CERRADO',
      'label': '🔒 Cliente Cerrado/No Disponible',
      'description': 'El cliente no estaba disponible para recibir',
    },
    {
      'value': 'DEVOLUCION_PARCIAL',
      'label': '↩️ Devolución Parcial',
      'description': 'El cliente rechazó parte de la mercancía',
    },
    {
      'value': 'RECHAZADO',
      'label': '❌ Rechazo Total',
      'description': 'El cliente rechazó toda la mercancía',
    },
  ];

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  /// Capturar foto con cámara y comprimir
  Future<void> _capturarFoto() async {
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (photo != null && mounted) {
        // ✅ NUEVO: Mostrar loading mientras se comprime
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        try {
          // ✅ NUEVO: Comprimir la imagen (asegura que pese < 1MB)
          final imagenComprimida =
              await ImageCompressionService.comprimirYValidarImagen(
            File(photo.path),
          );

          if (mounted) {
            Navigator.pop(context); // Cerrar loading

            setState(() {
              _fotosCapturadas.add(imagenComprimida);
            });

            // Mostrar tamaño de la imagen comprimida
            final tamanMB =
                await ImageCompressionService.obtenerTamanoEnMB(imagenComprimida);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '📸 Foto capturada (${_fotosCapturadas.length}) - ${tamanMB.toStringAsFixed(2)} MB',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); // Cerrar loading
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ImageCompressionService.obtenerMensajeError(e),
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } on PlatformException catch (e) {
      debugPrint('❌ Error al capturar foto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al acceder a la cámara'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Eliminar foto capturada
  void _eliminarFoto(int index) {
    setState(() {
      _fotosCapturadas.removeAt(index);
    });
  }

  /// Construir observaciones finales
  String _construirObservacionesFinales() {
    if (_tipoEntrega == 'COMPLETA') {
      return 'Entrega completa';
    } else {
      final observaciones = _observacionesController.text.trim();
      final tipoLabel = _tiposNovedad
          .firstWhere((t) => t['value'] == _tipoNovedad)['label']!;

      return observaciones.isEmpty
          ? tipoLabel
          : '$tipoLabel - $observaciones';
    }
  }

  /// Confirmar entrega
  Future<void> _confirmarEntrega() async {
    try {
      // Mostrar loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Convertir fotos a base64 si existen
      List<String>? fotosBase64;
      if (_fotosCapturadas.isNotEmpty) {
        fotosBase64 = [];
        for (final foto in _fotosCapturadas) {
          final bytes = await foto.readAsBytes();
          final base64 = _bytesToBase64(bytes);
          fotosBase64.add(base64);
        }
      }

      final observacionesFinales = _construirObservacionesFinales();

      debugPrint('📤 Confirmando entrega:');
      debugPrint('   - Tipo: $_tipoEntrega');
      debugPrint('   - Tipo Novedad: $_tipoNovedad');
      debugPrint('   - Observaciones: $observacionesFinales');
      debugPrint('   - Fotos: ${_fotosCapturadas.length}');

      final success = await widget.provider.confirmarVentaEntregada(
        widget.entrega.id,
        widget.venta.id,
        onSuccess: (mensaje) {
          debugPrint('✅ Venta entregada: $mensaje');
        },
        onError: (error) {
          debugPrint('❌ Error: $error');
        },
        fotosBase64: fotosBase64,
        observacionesLogistica: observacionesFinales,
      );

      if (mounted) {
        Navigator.pop(context); // Cerrar loading

        if (success) {
          debugPrint('✅ Entrega confirmada correctamente');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Entrega confirmada correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          // Cerrar la pantalla después de 1.5s
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted) {
            Navigator.pop(context);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${widget.provider.errorMessage ?? 'Error desconocido'}',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Excepción: $e');
      if (mounted) {
        Navigator.pop(context); // Cerrar loading si está abierto
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        if (_paso > 1) {
          setState(() => _paso--);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_paso == 1
              ? 'Confirmar Entrega'
              : _tipoEntrega == 'NOVEDAD'
                  ? 'Registrar Novedad'
                  : 'Confirmar Entrega'),
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_paso > 1) {
                setState(() => _paso--);
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: SafeArea(
          child: _paso == 1
              ? _buildPasoSeleccionar()
              : _tipoEntrega == 'COMPLETA'
                  ? _buildPasoConfirmacionCompleta()
                  : _buildPasoNovedad(),
        ),
      ),
    );
  }

  // PASO 1: Seleccionar tipo de entrega
  Widget _buildPasoSeleccionar() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Información de la venta
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Venta a Entregar',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Número:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              widget.venta.numero,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cliente:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              widget.venta.clienteNombre ?? 'Sin nombre',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Instrucción
            Text(
              '¿Cómo fue la entrega?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Selecciona el estado de la entrega para registrar los detalles',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Botón Entrega Completa
            SizedBox(
              width: double.infinity,
              height: 120,
              child: Material(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _tipoEntrega = 'COMPLETA';
                      _paso = 2;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 40,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Entrega Completa',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Botón Entrega con Novedad
            SizedBox(
              width: double.infinity,
              height: 120,
              child: Material(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _tipoEntrega = 'NOVEDAD';
                      _paso = 2;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        size: 40,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Entrega con Novedad',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // PASO 2: Confirmación de Entrega Completa
  Widget _buildPasoConfirmacionCompleta() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  const Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Entrega Completa',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalles de la Venta',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Número:',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Text(
                              widget.venta.numero,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Cliente:',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Text(
                              widget.venta.clienteNombre ?? 'Sin nombre',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total:',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Text(
                              'Bs. ${widget.venta.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '✅ La entrega será registrada como completa',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _paso = 1);
                  },
                  child: const Text('Atrás'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: _confirmarEntrega,
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // PASO 2: Registro de Novedad
  Widget _buildPasoNovedad() {
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
                  ..._tiposNovedad.map((tipo) {
                    final isSelected = _tipoNovedad == tipo['value'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: isSelected
                            ? Colors.orange.withOpacity(0.15)
                            : Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _tipoNovedad = tipo['value'];
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.orange
                                    : Colors.grey.withOpacity(0.3),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: tipo['value']!,
                                  groupValue: _tipoNovedad,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _tipoNovedad = value;
                                      });
                                    }
                                  },
                                  activeColor: Colors.orange,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tipo['label']!,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        tipo['description']!,
                                        style: TextStyle(
                                          fontSize: 12,
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
                  }).toList(),

                  const SizedBox(height: 24),

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
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _observacionesController,
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
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
                          '${_fotosCapturadas.length}',
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
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Galería de fotos capturadas
                  if (_fotosCapturadas.isNotEmpty)
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
                          itemCount: _fotosCapturadas.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _fotosCapturadas[index],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _eliminarFoto(index),
                                    child: Container(
                                      decoration: BoxDecoration(
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
                      onPressed: _capturarFoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Capturar Foto'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _paso = 1);
                  },
                  child: const Text('Atrás'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  onPressed: _tipoNovedad == null
                      ? null
                      : _confirmarEntrega,
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Convertir bytes a base64
  String _bytesToBase64(List<int> bytes) {
    return base64Encode(bytes);
  }
}
