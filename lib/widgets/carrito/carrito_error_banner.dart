import 'package:flutter/material.dart';
import '../../extensions/carrito_theme_extension.dart';

/// Widget que muestra banner de error en el carrito
class CarritoErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const CarritoErrorBanner({
    super.key,
    required this.message,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.carritoWarningBg,
        border: Border(
          bottom: BorderSide(color: context.carritoWarningBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.warning_rounded,
            color: context.carritoWarningIcon,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: context.carritoWarningText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClose,
            child: Icon(
              Icons.close,
              color: context.carritoWarningIcon,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
