import 'package:flutter/material.dart';
import '../../config/config.dart';
import '../../providers/providers.dart';

class CarritoEditandoProformaBanner extends StatelessWidget {
  final CarritoProvider carritoProvider;

  const CarritoEditandoProformaBanner({
    super.key,
    required this.carritoProvider,
  });

  @override
  Widget build(BuildContext context) {
    if (!carritoProvider.editandoProforma) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3).withOpacity(0.1),
        border: Border(
          left: BorderSide(
            color: const Color(0xFF2196F3),
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.edit_document,
            color: const Color(0xFF2196F3),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editando Proforma',
                  style: TextStyle(
                    fontSize: AppTextStyles.bodySmall(context).fontSize!,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '#${carritoProvider.proformaEditando?.numero ?? 'N/A'} (ID: ${carritoProvider.proformaEditandoId ?? 'N/A'})',
                  style: TextStyle(
                    fontSize: AppTextStyles.bodySmall(context).fontSize!,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
