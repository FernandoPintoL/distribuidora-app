import 'package:flutter/material.dart';
import '../../../config/app_urls.dart';

class ProductoAvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String? nombreProducto;
  final double radius;

  const ProductoAvatarWidget({
    Key? key,
    required this.imageUrl,
    this.nombreProducto,
    this.radius = 32,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tieneImagen = imageUrl != null && imageUrl!.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).primaryColor,
      backgroundImage: tieneImagen ? NetworkImage(imageUrl!) : null,
      child: !tieneImagen
          ? Icon(
              Icons.image_not_supported_outlined,
              color: Colors.white,
              size: radius * 0.8,
            )
          : null,
    );
  }
}
