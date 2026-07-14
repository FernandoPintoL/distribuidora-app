import 'package:flutter/material.dart';
import '../../../config/app_text_styles.dart';

class FabAddDireccionWidget extends StatelessWidget {
  final int tabIndex;
  final VoidCallback onPressed;

  const FabAddDireccionWidget({
    super.key,
    required this.tabIndex,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (tabIndex != 1) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: Icon(Icons.add_location, size: 24, color: colorScheme.onPrimary),
        label: Text(
          'Agregar Dirección',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: AppTextStyles.bodyLarge(context).fontSize!,
            color: colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
