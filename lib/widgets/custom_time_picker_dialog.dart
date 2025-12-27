import 'package:flutter/material.dart';

/// Widget personalizado para seleccionar hora sin problemas de constraints
/// Soluciona el error "BoxConstraints has non-normalized height constraints"
Future<TimeOfDay?> showCustomTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  String? helpText,
  String? cancelText,
  String? confirmText,
}) async {
  try {
    // Esperar a que el frame actual termine
    await Future.delayed(const Duration(milliseconds: 100));

    if (!context.mounted) return null;

    // Usar Navigator.of con rootNavigator para evitar constraints issues
    return await showDialog<TimeOfDay>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (BuildContext context) {
        TimeOfDay selectedTime = initialTime;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (helpText != null)
                            Text(
                              helpText,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Time picker
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        height: 200,
                        child: Row(
                          children: [
                            // Horas
                            Expanded(
                              child: ListWheelScrollView(
                                itemExtent: 40,
                                diameterRatio: 1.2,
                                onSelectedItemChanged: (index) {
                                  setState(() {
                                    selectedTime = selectedTime.replacing(hour: index);
                                  });
                                },
                                children: List<Widget>.generate(
                                  24,
                                  (index) => Center(
                                    child: Text(
                                      index.toString().padLeft(2, '0'),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: selectedTime.hour == index
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: selectedTime.hour == index
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(':', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            // Minutos
                            Expanded(
                              child: ListWheelScrollView(
                                itemExtent: 40,
                                diameterRatio: 1.2,
                                onSelectedItemChanged: (index) {
                                  setState(() {
                                    selectedTime =
                                        selectedTime.replacing(minute: index);
                                  });
                                },
                                children: List<Widget>.generate(
                                  60,
                                  (index) => Center(
                                    child: Text(
                                      index.toString().padLeft(2, '0'),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: selectedTime.minute == index
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: selectedTime.minute == index
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(cancelText ?? 'Cancelar'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(context, selectedTime),
                            child: Text(confirmText ?? 'Aceptar'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  } catch (e) {
    debugPrint('Error en custom time picker: $e');
    return null;
  }
}
