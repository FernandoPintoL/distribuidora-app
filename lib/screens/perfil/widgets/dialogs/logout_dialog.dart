import 'package:flutter/material.dart';
import '../../../../extensions/theme_extension.dart';
import '../../../../providers/providers.dart';
import 'package:provider/provider.dart';

class LogoutDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isDark = context.isDark;
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Está seguro de que desea cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthProvider>().logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }
}
