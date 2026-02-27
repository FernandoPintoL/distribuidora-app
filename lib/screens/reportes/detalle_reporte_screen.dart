import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../../config/config.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

class DetalleReporteScreen extends StatefulWidget {
  final int reporteId;

  const DetalleReporteScreen({
    super.key,
    required this.reporteId,
  });

  @override
  State<DetalleReporteScreen> createState() => _DetalleReporteScreenState();
}

class _DetalleReporteScreenState extends State<DetalleReporteScreen> {
  final TextEditingController _notasRespuestaController =
      TextEditingController();
  String? _estadoSeleccionado;
  bool _isEditingNotes = false;

  @override
  void initState() {
    super.initState();
    // ✅ Posponer la carga después de la construcción para evitar setState durante build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _cargarReporte();
    });
  }

  @override
  void dispose() {
    _notasRespuestaController.dispose();
    super.dispose();
  }

  Future<void> _cargarReporte() async {
    final provider =
        Provider.of<ReporteProductoDanadoProvider>(context, listen: false);
    await provider.cargarReporte(widget.reporteId);

    if (mounted && provider.reporteSeleccionado != null) {
      setState(() {
        _estadoSeleccionado = provider.reporteSeleccionado!.estado;
        _notasRespuestaController.text =
            provider.reporteSeleccionado!.notasRespuesta ?? '';
      });
    }
  }

  Future<void> _actualizarReporte() async {
    if (_estadoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un estado')),
      );
      return;
    }

    final provider =
        Provider.of<ReporteProductoDanadoProvider>(context, listen: false);

    final exito = await provider.actualizarReporte(
      reporteId: widget.reporteId,
      estado: _estadoSeleccionado!,
      notasRespuesta: _notasRespuestaController.text.isEmpty
          ? null
          : _notasRespuestaController.text,
    );

    if (!mounted) return;

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte actualizado exitosamente')),
      );
      setState(() => _isEditingNotes = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${provider.errorMessage}')),
      );
    }
  }

  Future<void> _eliminarImagen(int imagenId) async {
    final provider =
        Provider.of<ReporteProductoDanadoProvider>(context, listen: false);

    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar imagen'),
        content: const Text('¿Estás seguro que deseas eliminar esta imagen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmacion == true) {
      final exito = await provider.eliminarImagen(imagenId);

      if (!mounted) return;

      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen eliminada exitosamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${provider.errorMessage}')),
        );
      }
    }
  }

  Future<void> _eliminarReporte() async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar reporte'),
        content:
            const Text('¿Estás seguro que deseas eliminar este reporte?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmacion == true) {
      final provider =
          Provider.of<ReporteProductoDanadoProvider>(context, listen: false);

      final exito = await provider.eliminarReporte(widget.reporteId);

      if (!mounted) return;

      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte eliminado exitosamente')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${provider.errorMessage}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Reporte'),
        elevation: 0,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: _eliminarReporte,
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text('Eliminar reporte', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<ReporteProductoDanadoProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.reporteSeleccionado == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null &&
              provider.reporteSeleccionado == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar reporte',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.errorMessage ?? 'Error desconocido',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _cargarReporte,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final reporte = provider.reporteSeleccionado;
          if (reporte == null) {
            return const Center(child: Text('No se encontró el reporte'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con venta y cliente
                _buildHeader(reporte),
                const SizedBox(height: 24),

                // Observaciones
                _buildObservacionesSection(reporte),
                const SizedBox(height: 24),

                // Imagenes
                if (reporte.imagenes.isNotEmpty) ...[
                  _buildImagenesSection(reporte),
                  const SizedBox(height: 24),
                ],

                // Estado y notas (solo si hay permisos de administrador)
                _buildEstadoYNotasSection(reporte),
                const SizedBox(height: 24),

                // Informacion adicional
                _buildInformacionAdicional(reporte),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ReporteProductoDanado reporte) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _getStatusColor(reporte.estado);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Venta #${reporte.numeroVenta}',
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reporte.nombreCliente,
                        style: AppTextStyles.bodySmall(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor, width: 1.5),
                  ),
                  child: Text(
                    reporte.estadoDescripcion,
                    style: AppTextStyles.labelSmall(context).copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObservacionesSection(ReporteProductoDanado reporte) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descripcion del defecto',
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
          child: Text(
            reporte.observaciones,
            style: AppTextStyles.bodyMedium(context),
          ),
        ),
      ],
    );
  }

  Widget _buildImagenesSection(ReporteProductoDanado reporte) {
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
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${reporte.imagenes.length}',
                style: AppTextStyles.labelSmall(context).copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: reporte.imagenes.length,
          itemBuilder: (context, index) {
            final imagen = reporte.imagenes[index];
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
                    child: Image.network(
                      imagen.urlImagen,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    ),
                  ),
                ),
                // Boton eliminar
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _eliminarImagen(imagen.id),
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
        ),
      ],
    );
  }

  Widget _buildEstadoYNotasSection(ReporteProductoDanado reporte) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado y respuesta',
          style: AppTextStyles.titleSmall(context).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        // Estados
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildEstadoButton('Pendiente', 'pendiente', Colors.orange),
              const SizedBox(width: 8),
              _buildEstadoButton('En Revision', 'en_revision', Colors.blue),
              const SizedBox(width: 8),
              _buildEstadoButton('Aprobado', 'aprobado', Colors.green),
              const SizedBox(width: 8),
              _buildEstadoButton('Rechazado', 'rechazado', Colors.red),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Notas de respuesta
        if (!_isEditingNotes)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (reporte.notasRespuesta != null &&
                  reporte.notasRespuesta!.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Respuesta',
                        style: AppTextStyles.labelSmall(context).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reporte.notasRespuesta!,
                        style: AppTextStyles.bodySmall(context),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  'Sin respuesta aun',
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _isEditingNotes = true),
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar respuesta'),
                ),
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _notasRespuestaController,
                maxLines: 4,
                minLines: 3,
                decoration: InputDecoration(
                  hintText: 'Agrega una respuesta o notas sobre el reporte',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          setState(() => _isEditingNotes = false),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _actualizarReporte,
                      child: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildEstadoButton(String label, String value, Color color) {
    final isSelected = _estadoSeleccionado == value;
    return ElevatedButton(
      onPressed: () => setState(() => _estadoSeleccionado = value),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }

  Widget _buildInformacionAdicional(ReporteProductoDanado reporte) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Creado', _formatearFecha(reporte.createdAt)),
          const SizedBox(height: 8),
          _buildInfoRow('Actualizado', _formatearFecha(reporte.updatedAt)),
          if (reporte.fechaReporte != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Fecha del reporte', reporte.fechaReporte ?? ''),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall(context).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodySmall(context),
        ),
      ],
    );
  }

  String _formatearFecha(DateTime fecha) {
    final hoy = DateTime.now();
    final diferencia = hoy.difference(fecha).inDays;

    if (diferencia == 0) {
      return 'Hoy a las ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    } else if (diferencia == 1) {
      return 'Ayer a las ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    } else if (diferencia < 7) {
      return 'hace $diferencia dias';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }

  Color _getStatusColor(String estado) {
    return switch (estado) {
      'pendiente' => Colors.orange,
      'en_revision' => Colors.blue,
      'aprobado' => Colors.green,
      'rechazado' => Colors.red,
      _ => Colors.grey,
    };
  }
}
