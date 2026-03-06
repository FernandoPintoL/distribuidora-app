import 'package:flutter/material.dart';

/// Widget para mostrar información en un contenedor coloreado
class InfoBox extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;

  const InfoBox({
    Key? key,
    required this.child,
    required this.backgroundColor,
    required this.borderColor,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius,
  }) : super(key: key);

  /// Factory para info box azul
  factory InfoBox.blue({
    Key? key,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(12),
  }) {
    return InfoBox(
      key: key,
      child: child,
      backgroundColor: Colors.blue[50]!,
      borderColor: Colors.blue[400]!,
      padding: padding,
    );
  }

  /// Factory para info box rojo (devoluciones)
  factory InfoBox.red({
    Key? key,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(12),
  }) {
    return InfoBox(
      key: key,
      child: child,
      backgroundColor: Colors.red[50]!,
      borderColor: Colors.red[300]!,
      padding: padding,
    );
  }

  /// Factory para info box verde
  factory InfoBox.green({
    Key? key,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(12),
  }) {
    return InfoBox(
      key: key,
      child: child,
      backgroundColor: Colors.green[50]!,
      borderColor: Colors.green[300]!,
      padding: padding,
    );
  }

  /// Factory para info box naranja
  factory InfoBox.orange({
    Key? key,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(12),
  }) {
    return InfoBox(
      key: key,
      child: child,
      backgroundColor: Colors.orange[50]!,
      borderColor: Colors.orange[300]!,
      padding: padding,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
