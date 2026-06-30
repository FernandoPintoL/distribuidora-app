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
              ? Column(
                  children: [
                    Text(
                      (clienteNombre ?? 'C').substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (clienteLocalidad != null &&
                        clienteLocalidad!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 85,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                clienteLocalidad!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                )
              : null,
        ),
      ],
    );
  }
}
