import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import 'entregas_asignadas_screen.dart';
import '../perfil/perfil_screen.dart';
import '../notifications_screen.dart';

/// Pantalla principal para usuarios con rol CHOFER
///
/// Muestra:
/// - Listado de entregas asignadas
/// - Acceso rápido a perfil
class HomeChoferScreen extends StatefulWidget {
  const HomeChoferScreen({super.key});

  @override
  State<HomeChoferScreen> createState() => _HomeChoferScreenState();
}

class _HomeChoferScreenState extends State<HomeChoferScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: const EntregasAsignadasScreen(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Mis Entregas Asignadas'),
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade600,
              Colors.blue.shade400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        // Notificaciones
        Consumer<NotificationProvider>(
          builder: (context, notifProvider, _) {
            final unreadCount = notifProvider.unreadCount;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        // Menú de usuario (Perfil y Logout)
        PopupMenuButton<String>(
          icon: const Icon(Icons.account_circle),
          onSelected: (value) async {
            if (value == 'perfil') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PerfilScreen(),
                ),
              );
            } else if (value == 'logout') {
              _mostrarDialogoConfirmarLogout();
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'perfil',
              child: Row(
                children: [
                  Icon(Icons.person, size: 20),
                  SizedBox(width: 12),
                  Text('Mi Perfil'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _mostrarDialogoConfirmarLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (!mounted) return;
                final authProvider = context.read<AuthProvider>();
                Navigator.of(context).pop();
                await authProvider.logout();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
