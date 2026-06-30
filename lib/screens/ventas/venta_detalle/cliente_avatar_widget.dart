import 'package:flutter/material.dart';
import '../../../config/app_urls.dart';

class ClienteAvatarWidget extends StatelessWidget {
  final String? clienteNombre;
  final String? clienteFotoPerfil;
  final String? clienteLocalidad;
  final String? clienteObservaciones;

  const ClienteAvatarWidget({
    Key? key,
    required this.clienteNombre,
    required this.clienteFotoPerfil,
    this.clienteLocalidad,
    this.clienteObservaciones,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tieneImagen =
        clienteFotoPerfil != null && clienteFotoPerfil!.isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // Avatar
        CircleAvatar(
          radius: 28,
          backgroundImage: tieneImagen
              ? NetworkImage('${AppUrls.baseUrlImg}$clienteFotoPerfil')
              : null,
          child: !tieneImagen
              ? Icon(Icons.person, size: 28, color: colorScheme.onSurface)
              : null,
        ),
        const SizedBox(width: 6),
        // Nombre
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                clienteNombre ?? 'Cliente',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            // Localidad
            if (clienteLocalidad != null && clienteLocalidad!.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.location_on, size: 11, color: Colors.red),
                  Text(
                    clienteLocalidad!,
                    style: TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
            if (clienteObservaciones != null &&
                clienteObservaciones!.isNotEmpty) ...[
              Text(
                "📍 ${clienteObservaciones!}",
                style: TextStyle(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        ),
      ],
    );
  }
}
