import 'package:flutter/material.dart';
import '../../../config/app_urls.dart';

class ClienteAvatarWidget extends StatelessWidget {
  final String? clienteNombre;
  final String? clienteFotoPerfil;
  final String? clienteLocalidad;

  const ClienteAvatarWidget({
    Key? key,
    required this.clienteNombre,
    required this.clienteFotoPerfil,
    this.clienteLocalidad,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tieneImagen =
        clienteFotoPerfil != null && clienteFotoPerfil!.isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;

    debugPrint("🎯 ClienteAvatarWidget - nombre: $clienteNombre, localidad: $clienteLocalidad");

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 32,
          backgroundImage: tieneImagen
              ? NetworkImage('${AppUrls.baseUrlImg}$clienteFotoPerfil')
              : null,
          child: !tieneImagen
              ? Text(
                  (clienteNombre ?? 'C').substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : null,
        ),
        if (clienteLocalidad != null && clienteLocalidad!.isNotEmpty) ...[
          const SizedBox(height: 6),
          SizedBox(
            width: 72,
            child: Text(
              clienteLocalidad!,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
