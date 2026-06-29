import 'package:flutter/material.dart';
import '../../../../models/models.dart';
import '../../../../config/app_text_styles.dart';

class TrackingSection extends StatelessWidget {
  final Pedido pedido;
  final BuildContext parentContext;

  const TrackingSection({
    super.key,
    required this.pedido,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(parentContext).pushNamed('/pedido-tracking', arguments: pedido);
        },
        icon: const Icon(Icons.location_on, size: 28),
        label: Text(
          'Ver Tracking en Tiempo Real',
          style: TextStyle(
            fontSize: AppTextStyles.bodyLarge(parentContext).fontSize!,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
