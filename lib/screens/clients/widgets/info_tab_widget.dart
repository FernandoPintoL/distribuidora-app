import 'package:flutter/material.dart';
import '../../../config/app_text_styles.dart';
import '../../../models/models.dart';
import '../../../utils/utils.dart';
import 'client_image_with_fallback.dart';

class InfoTabWidget extends StatelessWidget {
  final Client? client;
  final VoidCallback onImageTap;
  final VoidCallback? onEdit;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;

  const InfoTabWidget({
    super.key,
    required this.client,
    required this.onImageTap,
    this.onEdit,
    this.onCall,
    this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: GestureDetector(
                  onTap: onImageTap,
                  child: _buildProfileImageStack(context),
                ),
              ),
            ),
            _InfoCardWidget('Información Básica', [
              _InfoRowWidget(label: 'Nombre', value: client?.nombre ?? ''),
              if (client?.razonSocial != null)
                _InfoRowWidget(
                  label: 'Razón Social',
                  value: client!.razonSocial!,
                ),
              if (client?.nit != null)
                _InfoRowWidget(label: 'NIT', value: client!.nit!),
              if (client?.email != null)
                _InfoRowWidget(label: 'Email', value: client!.email!),
              if (client?.telefono != null)
                _ContactRowWidget(
                  label: 'Teléfono',
                  value: client!.telefono!,
                  onCall: onCall,
                  onWhatsApp: onWhatsApp,
                ),
              if (client?.localidad != null)
                _InfoRowWidget(label: 'Localidad', value: _getLocalidadName()),
              if (client?.codigoCliente != null &&
                  client!.codigoCliente!.isNotEmpty)
                _InfoRowWidget(
                  label: 'Código Cliente',
                  value: client!.codigoCliente!,
                ),
              _InfoRowWidget(
                label: 'Activo',
                value: client?.activo == true ? 'Sí' : 'No',
              ),
            ]),
            const SizedBox(height: 16),
            if (client?.categorias != null && client!.categorias!.isNotEmpty)
              _InfoCardWidget('Categorías', [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: client!.categorias!
                      .map(
                        (c) => Chip(
                          label: Text(c.nombre ?? c.clave ?? 'Categoría'),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ]),
            if (client?.ventanasEntrega != null &&
                client!.ventanasEntrega!.isNotEmpty)
              _InfoCardWidget('Días de visitas', [
                Column(
                  children: client!.ventanasEntrega!
                      .map((v) => _DeliveryWindowRowWidget(ventana: v))
                      .toList(),
                ),
              ]),
            const SizedBox(height: 16),
            if (client?.observaciones != null)
              _InfoCardWidget('Observaciones', [Text(client!.observaciones!)]),
          ],
        ),
      ),
      floatingActionButton: onEdit != null
          ? FloatingActionButton.extended(
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
              label: const Text('Editar'),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            )
          : null,
    );
  }

  Widget _buildProfileImageStack(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
        ),
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  radius: 58,
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  child: _buildProfileImage(context),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImage(BuildContext context) {
    if (client?.fotoPerfil == null || client!.fotoPerfil!.isEmpty) {
      return const Icon(Icons.person, size: 58, color: Colors.white);
    }

    final imagePath = client!.fotoPerfil!;
    final urls = ImageUtils.buildMultipleImageUrls(imagePath);

    if (urls.isEmpty) {
      debugPrint('⚠️ No se pudieron generar URLs para la imagen: $imagePath');
      return const Icon(Icons.person, size: 58, color: Colors.white);
    }

    debugPrint('🔍 Intentando cargar imagen de perfil desde URLs: $urls');

    return ClipOval(
      child: ClientImageWithFallback(
        urls: urls,
        width: 112,
        height: 112,
        fit: BoxFit.cover,
        fallbackWidget: const Icon(Icons.person, size: 58, color: Colors.white),
        loadingWidget: Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getLocalidadName() {
    if (client?.localidad != null) {
      if (client!.localidad is Map<String, dynamic>) {
        final localidadMap = client!.localidad as Map<String, dynamic>;
        return localidadMap['nombre'] ?? 'Localidad desconocida';
      } else if (client!.localidad is Localidad) {
        return (client!.localidad as Localidad).nombre;
      }
    }
    return 'Sin localidad';
  }
}

class _InfoCardWidget extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCardWidget(this.title, this.children);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRowWidget extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRowWidget({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ContactRowWidget extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;

  const _ContactRowWidget({
    required this.label,
    required this.value,
    this.onCall,
    this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Text(value),
                const Spacer(),
                if (onCall != null)
                  IconButton(
                    icon: const Icon(Icons.call, color: Colors.green),
                    onPressed: onCall,
                    tooltip: 'Llamar',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                if (onWhatsApp != null)
                  IconButton(
                    icon: const Icon(Icons.message, color: Colors.green),
                    onPressed: onWhatsApp,
                    tooltip: 'WhatsApp',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryWindowRowWidget extends StatelessWidget {
  final VentanaEntregaCliente ventana;

  const _DeliveryWindowRowWidget({required this.ventana});

  @override
  Widget build(BuildContext context) {
    final days = [
      'Domingo',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
    ];
    final day = (ventana.diaSemana >= 0 && ventana.diaSemana <= 6)
        ? days[ventana.diaSemana]
        : 'Día ${ventana.diaSemana}';
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(
        Icons.access_time,
        color: ventana.activo ? Colors.green : Colors.grey,
      ),
      title: Text('$day: ${ventana.horaInicio} - ${ventana.horaFin}'),
      subtitle: ventana.activo
          ? null
          : const Text('Inactivo', style: TextStyle(color: Colors.grey)),
    );
  }
}
