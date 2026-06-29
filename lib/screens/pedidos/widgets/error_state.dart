import 'package:flutter/material.dart';
import '../../../config/app_text_styles.dart';

class ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback? onReintentar;

  const ErrorState({
    required this.error,
    this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 70,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar pedidos',
                style: AppTextStyles.titleMedium(
                  context,
                ).copyWith(color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  error,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium(
                    context,
                  ).copyWith(color: colorScheme.onSurface),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onReintentar,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
