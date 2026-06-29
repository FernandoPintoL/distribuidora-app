import 'package:flutter/material.dart';
import '../../../config/app_urls.dart';

class ClienteAvatarWidget extends StatelessWidget {
  final String? clienteNombre;
  final String? clienteFotoPerfil;

  const ClienteAvatarWidget({
    Key? key,
    required this.clienteNombre,
    required this.clienteFotoPerfil,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tieneImagen =
        clienteFotoPerfil != null && clienteFotoPerfil!.isNotEmpty;

    return CircleAvatar(
      radius: 32,
      // backgroundColor: Theme.of(context).primaryColor,
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
    );
  }
}
