import 'package:flutter/material.dart';
import '../../../../providers/entrega_provider.dart';

class ErrorContentWidget extends StatelessWidget {
  final EntregaProvider provider;
  final Function(EntregaProvider) onRetry;

  const ErrorContentWidget({
    Key? key,
    required this.provider,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('❌ [BUILD_ERROR] ErrorContentWidget está siendo renderizada');
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: isDarkMode ? Colors.red[400] : Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text('Error al cargar entrega'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => onRetry(provider),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
