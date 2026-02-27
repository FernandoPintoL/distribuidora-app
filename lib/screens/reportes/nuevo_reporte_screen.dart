import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/config.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

class NuevoReporteScreen extends StatefulWidget {
  final int? ventaId;
  final Venta? ventaPredeterminada;

  const NuevoReporteScreen({
    super.key,
    this.ventaId,
    this.ventaPredeterminada,
  });

  @override
  State<NuevoReporteScreen> createState() => _NuevoReporteScreenState();
}

class _NuevoReporteScreenState extends State<NuevoReporteScreen> {
  final TextEditingController _observacionesController =
      TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  Venta? _ventaSeleccionada;
  final List<File> _imagenesSeleccionadas = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ventaSeleccionada = widget.ventaPredeterminada;
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  /// Seleccionar imagen de galeria o camara
  Future<void> _seleccionarImagen(ImageSource source) async {
    try {
      final XFile? imagen = await _imagePicker.pickImage(source: source);

      if (imagen != null) {
        setState(() {
          _imagenesSeleccionadas.add(File(imagen.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  /// Eliminar imagen seleccionada
  void _eliminarImagen(int index) {
    setState(() {
      _imagenesSeleccionadas.removeAt(index);
    });
  }

  /// Crear reporte
  Future<void> _crearReporte() async {
    if (_ventaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar una venta')),
      );
      return;
    }

    if (_observacionesController.text.isEmpty ||
        _observacionesController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Las observaciones deben tener al menos 10 caracteres')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider =
        Provider.of<ReporteProductoDanadoProvider>(context, listen: false);

    // Crear reporte
    final exito = await provider.crearReporte(
      ventaId: _ventaSeleccionada!.id,
      observaciones: _observacionesController.text,
    );

    if (!mounted) return;

    if (exito && provider.reporteSeleccionado != null) {
      // Subir imagenes
      for (final imagen in _imagenesSeleccionadas) {
        await provider.subirImagen(
          reporteId: provider.reporteSeleccionado!.id,
          rutaArchivo: imagen.path,
          descripcion: null,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte creado exitosamente')),
      );

      // Volver a pantalla anterior
      Navigator.pop(context, provider.reporteSeleccionado);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Error al crear reporte: ${provider.errorMessage}')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar Producto Danado'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seleccionar venta
            _buildVentaSelector(),
            const SizedBox(height: 24),

            // Campo de observaciones
            _buildObservacionesField(),
            const SizedBox(height: 24),

            // Imagenes
            _buildImagenesSection(),
            const SizedBox(height: 24),

            // Botones de accion
            _buildBotonesAccion(),
          ],
        ),
      ),
    );
  }

  /// Selector de venta
  Widget _buildVentaSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Venta relacionada *',
          style: AppTextStyles.titleSmall(context).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _ventaSeleccionada == null
              ? GestureDetector(
                  onTap: () => _abrirSelectorVentas(),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shopping_cart,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seleccionar venta',
                            style: AppTextStyles.bodyMedium(context),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                )
              : GestureDetector(
                  onTap: () => _abrirSelectorVentas(),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shopping_cart,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Venta #${_ventaSeleccionada!.numero}',
                              style: AppTextStyles.bodyMedium(context)
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _ventaSeleccionada!.clienteNombre ?? 'Cliente',
                              style: AppTextStyles.bodySmall(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  /// Campo de observaciones
  Widget _buildObservacionesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descripcion del defecto *',
          style: AppTextStyles.titleSmall(context).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _observacionesController,
          maxLines: 5,
          minLines: 3,
          decoration: InputDecoration(
            hintText:
                'Describe detalladamente el problema (minimo 10 caracteres)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(12),
            counterText:
                '${_observacionesController.text.length} caracteres',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 4),
        if (_observacionesController.text.length < 10)
          Text(
            'Minimo 10 caracteres requeridos',
            style: AppTextStyles.labelSmall(context).copyWith(
              color: Colors.red,
            ),
          ),
      ],
    );
  }

  /// Seccion de imagenes
  Widget _buildImagenesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Fotos del defecto',
              style: AppTextStyles.titleSmall(context).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${_imagenesSeleccionadas.length}',
                style: AppTextStyles.labelSmall(context).copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Botones para agregar imagenes
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _seleccionarImagen(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camara'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    _seleccionarImagen(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galeria'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Grid de imagenes
        if (_imagenesSeleccionadas.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _imagenesSeleccionadas.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  // Imagen
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _imagenesSeleccionadas[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Boton eliminar
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _eliminarImagen(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
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
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported,
                  size: 48,
                  color:
                      Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  'Sin imagenes anadidas',
                  style: AppTextStyles.bodySmall(context),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Botones de accion
  Widget _buildBotonesAccion() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading || _ventaSeleccionada == null
                ? null
                : _crearReporte,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Reportar'),
          ),
        ),
      ],
    );
  }

  /// Abrir selector de ventas
  void _abrirSelectorVentas() {
    showDialog(
      context: context,
      builder: (context) => _SelectorVentasDialog(
        onVentaSeleccionada: (venta) {
          setState(() {
            _ventaSeleccionada = venta;
          });
        },
      ),
    );
  }
}

/// Dialog para seleccionar venta
class _SelectorVentasDialog extends StatefulWidget {
  final Function(Venta) onVentaSeleccionada;

  const _SelectorVentasDialog({
    required this.onVentaSeleccionada,
  });

  @override
  State<_SelectorVentasDialog> createState() => _SelectorVentasDialogState();
}

class _SelectorVentasDialogState extends State<_SelectorVentasDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Venta> _ventasDisponibles = [];
  List<Venta> _ventasFiltradas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // ✅ Posponer la carga después de la construcción para evitar setState durante build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _cargarVentas();
    });
  }

  Future<void> _cargarVentas() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Reemplazar con llamada a API real para obtener ventas disponibles
      // Por ahora, mostrar lista vacía con mensaje
      _ventasDisponibles = [];
      _ventasFiltradas = [];
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar ventas: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filtrarVentas(String query) {
    setState(() {
      if (query.isEmpty) {
        _ventasFiltradas = _ventasDisponibles;
      } else {
        _ventasFiltradas = _ventasDisponibles
            .where((v) =>
                v.numero.toLowerCase().contains(query.toLowerCase()) ||
                (v.clienteNombre?.toLowerCase().contains(query.toLowerCase()) ??
                    false))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar Venta'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por numero o cliente...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _filtrarVentas,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_ventasFiltradas.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'No hay ventas disponibles'
                              : 'No se encontraron resultados',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _ventasFiltradas.length,
                  itemBuilder: (context, index) {
                    final venta = _ventasFiltradas[index];
                    return ListTile(
                      title: Text('Venta #${venta.numero}'),
                      subtitle: Text(venta.clienteNombre ?? 'Cliente'),
                      trailing: Text('\$${venta.total.toStringAsFixed(2)}'),
                      onTap: () {
                        widget.onVentaSeleccionada(venta);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
