import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../utils/utils.dart';
import 'image_with_fallback.dart';

class ClientListItem extends StatelessWidget {
  final Client client;
  final VoidCallback onTap;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onEdit;
  final VoidCallback? onMarcarVisita;
  final VoidCallback? onViewMap;

  const ClientListItem({
    super.key,
    required this.client,
    required this.onTap,
    this.onCall,
    this.onWhatsApp,
    this.onEdit,
    this.onMarcarVisita,
    this.onViewMap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileAvatar(context, colorScheme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_buildClientInfo(colorScheme)],
                  ),
                ),
                _buildActionsAndStatus(colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, ColorScheme colorScheme) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.secondary,
            colorScheme.secondary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.secondary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: client.fotoPerfil != null && client.fotoPerfil!.isNotEmpty
                ? _buildProfileImage(context, client.fotoPerfil!)
                : Container(
                    color: colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.person,
                      color: colorScheme.onSecondaryContainer,
                      size: 32,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildClientInfo(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          client.nombre,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        if (client.razonSocial != null && client.razonSocial!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              client.razonSocial!,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        Row(
          children: [
            if (client.telefono != null && client.telefono!.isNotEmpty) ...[
              Icon(Icons.phone, size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  client.telefono!,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ],
        ),
        if (client.email != null && client.email!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(
                  Icons.email,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    client.email!,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        if (client.localidad != null ||
            (client.codigoCliente != null && client.codigoCliente!.isNotEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                if (client.localidad != null) ...[
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _getLocalidadName(client.localidad),
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (client.codigoCliente != null &&
                      client.codigoCliente!.isNotEmpty)
                    const SizedBox(width: 8),
                ],
                if (client.codigoCliente != null &&
                    client.codigoCliente!.isNotEmpty)
                  Flexible(
                    child: Text(
                      'Cód: ${client.codigoCliente}',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        if (client.categorias != null && client.categorias!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: client.categorias!
                  .take(2)
                  .map(
                    (c) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.secondary,
                            colorScheme.secondary.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        c.nombre ?? c.clave ?? 'Cat',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildActionsAndStatus(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: client.activo
                  ? [
                      colorScheme.secondary,
                      colorScheme.secondary.withOpacity(0.8),
                    ]
                  : [colorScheme.error, colorScheme.error.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color:
                    (client.activo ? colorScheme.secondary : colorScheme.error)
                        .withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            client.activo ? 'Activo' : 'Inactivo',
            style: TextStyle(
              color: client.activo
                  ? colorScheme.onPrimary
                  : colorScheme.onError,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
          offset: const Offset(-100, 0),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit?.call();
                break;
              case 'map':
                onViewMap?.call();
                break;
              case 'visita':
                onMarcarVisita?.call();
                break;
              case 'call':
                onCall?.call();
                break;
              case 'whatsapp':
                onWhatsApp?.call();
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18, color: colorScheme.tertiary),
                  const SizedBox(width: 12),
                  const Text('Editar'),
                ],
              ),
            ),
            if (onViewMap != null)
              PopupMenuItem(
                value: 'map',
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: Colors.green),
                    const SizedBox(width: 12),
                    const Text('Ver Mapa'),
                  ],
                ),
              ),
            if (onMarcarVisita != null)
              PopupMenuItem(
                value: 'visita',
                child: Row(
                  children: [
                    Icon(
                      Icons.assignment_turned_in,
                      size: 18,
                      color: Colors.purple,
                    ),
                    const SizedBox(width: 12),
                    const Text('Marcar Visita'),
                  ],
                ),
              ),
            if (onCall != null &&
                client.telefono != null &&
                client.telefono!.isNotEmpty)
              PopupMenuItem(
                value: 'call',
                child: Row(
                  children: [
                    Icon(Icons.call, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    const Text('Llamar'),
                  ],
                ),
              ),
            if (onWhatsApp != null &&
                client.telefono != null &&
                client.telefono!.isNotEmpty)
              PopupMenuItem(
                value: 'whatsapp',
                child: Row(
                  children: [
                    Icon(Icons.message, size: 18, color: Colors.green),
                    const SizedBox(width: 12),
                    const Text('WhatsApp'),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileImage(BuildContext context, String imagePath) {
    if (imagePath.isEmpty) {
      debugPrint('⚠️ ImagePath está vacío, mostrando fallback');
      return _buildFallbackIcon(context);
    }

    final urls = ImageUtils.buildMultipleImageUrls(imagePath);

    if (urls.isEmpty) {
      debugPrint('⚠️ No se pudieron generar URLs para la imagen: $imagePath');
      return _buildFallbackIcon(context);
    }

    debugPrint('🔍 Intentando cargar imagen de perfil desde URLs: $urls');

    final colorScheme = Theme.of(context).colorScheme;
    return ImageWithFallback(
      urls: urls,
      width: 50,
      height: 50,
      fit: BoxFit.cover,
      fallbackWidget: _buildFallbackIcon(context),
      loadingWidget: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        Icons.person_outline,
        color: colorScheme.onSecondaryContainer,
        size: 28,
      ),
    );
  }

  String _getLocalidadName(dynamic localidad) {
    if (localidad == null) return '';

    if (localidad is String) {
      return localidad;
    }

    if (localidad is Map<String, dynamic>) {
      return localidad['nombre'] ?? localidad.toString();
    }

    try {
      return localidad.nombre ?? '';
    } catch (e) {
      return localidad.toString();
    }
  }
}
