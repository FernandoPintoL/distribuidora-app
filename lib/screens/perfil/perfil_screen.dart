import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import 'helpers/perfil_helpers.dart';
import 'widgets/perfil_header_widget.dart';
import 'widgets/perfil_section_title_widget.dart';
import 'widgets/perfil_info_card_widget.dart';
import 'widgets/perfil_roles_card_widget.dart';
import 'widgets/perfil_status_card_widget.dart';
import 'widgets/perfil_security_card_widget.dart';
import 'widgets/perfil_appearance_card_widget.dart';
import 'widgets/perfil_logout_button_widget.dart';
import 'widgets/perfil_stats_widgets.dart';
import 'widgets/perfil_options_card_widget.dart';

/// Pantalla de perfil compartida para todos los roles
/// - Cliente
/// - Chofer
/// - Preventista
/// - Admin
///
/// Versión moderna con diseño adaptable según el rol del usuario
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final primaryRole = getPrimaryRole(user);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar con gradiente moderno
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: getRoleGradient(primaryRole),
                ),
                child: SafeArea(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: PerfilHeaderWidget(
                      user: user,
                      primaryRole: primaryRole,
                    ),
                  ),
                ),
              ),
            ),
            backgroundColor: getRoleColor(primaryRole),
          ),

          // Contenido principal
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Estadísticas específicas por rol
                      /*PerfilRoleSpecificStatsWidget(
                        user: user,
                        primaryRole: primaryRole,
                      ),*/
                      // const SizedBox(height: 24),

                      // Información personal
                      PerfilSectionTitleWidget(
                        title: 'Información Personal',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 12),
                      PerfilInfoCardWidget(
                        context: context,
                        icon: Icons.person_outline,
                        title: 'Nombre Completo',
                        value: user?.name ?? 'No disponible',
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      PerfilInfoCardWidget(
                        context: context,
                        icon: Icons.email_outlined,
                        title: 'Correo Electrónico',
                        value: user?.email ?? 'No disponible',
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade400,
                            Colors.purple.shade600,
                          ],
                        ),
                      ),
                      if (user?.usernick != null) ...[
                        const SizedBox(height: 12),
                        PerfilInfoCardWidget(
                          context: context,
                          icon: Icons.account_circle_outlined,
                          title: 'Usuario',
                          value: '@${user?.usernick}',
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade400,
                              Colors.orange.shade600,
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Roles y permisos
                      /*PerfilSectionTitleWidget(
                        title: 'Roles y Permisos',
                        icon: Icons.admin_panel_settings_outlined,
                      ),*/
                      // const SizedBox(height: 12),
                      // PerfilRolesCardWidget(user: user),
                      // const SizedBox(height: 24),

                      // Estado del usuario
                      PerfilSectionTitleWidget(
                        title: 'Estado de Cuenta',
                        icon: Icons.verified_user_outlined,
                      ),
                      const SizedBox(height: 12),
                      PerfilStatusCardWidget(user: user),
                      const SizedBox(height: 24),

                      // Seguridad y Autenticación
                      PerfilSectionTitleWidget(
                        title: 'Seguridad',
                        icon: Icons.security_outlined,
                      ),
                      const SizedBox(height: 12),
                      PerfilSecurityCardWidget(
                        parentContext: context,
                        authProvider: authProvider,
                      ),
                      const SizedBox(height: 24),

                      // Apariencia
                      PerfilSectionTitleWidget(
                        title: 'Apariencia',
                        icon: Icons.palette_outlined,
                      ),
                      const SizedBox(height: 12),
                      const PerfilAppearanceCardWidget(),
                      const SizedBox(height: 24),

                      // Opciones específicas por rol
                      PerfilRoleSpecificOptionsWidget(
                        user: user,
                        primaryRole: primaryRole,
                      ),

                      // Botón de cerrar sesión moderno
                      const SizedBox(height: 8),
                      const PerfilLogoutButtonWidget(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
