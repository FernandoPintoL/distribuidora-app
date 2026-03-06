import 'package:flutter/material.dart';
import '../../../../config/app_text_styles.dart';

// ✅ WIDGET: Sugerencia Inteligente de Pago
class SugerenciaPagoWidget extends StatelessWidget {
  final Map<String, dynamic> sugerencia;
  final bool isDarkMode;
  final TextEditingController montoController;
  final VoidCallback onUsarSugerencia;

  const SugerenciaPagoWidget({
    Key? key,
    required this.sugerencia,
    required this.isDarkMode,
    required this.montoController,
    required this.onUsarSugerencia,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tipoPago = sugerencia['tipo'] as Map<String, dynamic>;
    final saldoPendiente = sugerencia['saldo'] as double;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [Colors.blue[900]!, Colors.blue[800]!]
              : [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.blue[700]! : Colors.blue[300]!,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Sugerencia Inteligente',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? Colors.blue[100]
                            : Colors.blue[900],
                        fontSize:
                            AppTextStyles.bodyMedium(context).fontSize!,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Te quedan Bs. ${saldoPendiente.toStringAsFixed(2)} por recibir',
                      style: TextStyle(
                        fontSize: AppTextStyles.bodySmall(context).fontSize!,
                        color: isDarkMode
                            ? Colors.blue[300]
                            : Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tipo de pago sugerido
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.blue[700]!
                          : Colors.blue[200]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tipo de Pago Sugerido',
                        style: TextStyle(
                          fontSize:
                              AppTextStyles.labelSmall(context).fontSize!,
                          color: isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (tipoPago['nombre'] as String?) ??
                            'Tipo de Pago',
                        style: TextStyle(
                          fontSize:
                              AppTextStyles.bodyMedium(context).fontSize!,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? Colors.blue[300]
                              : Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Monto: Bs. ${saldoPendiente.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize:
                              AppTextStyles.bodySmall(context).fontSize!,
                          color: isDarkMode
                              ? Colors.blue[400]
                              : Colors.blue[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 80,
                child: ElevatedButton.icon(
                  onPressed: onUsarSugerencia,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? Colors.blue[700]
                        : Colors.blue[600],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text(
                    'Usar\nSugerencia',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
