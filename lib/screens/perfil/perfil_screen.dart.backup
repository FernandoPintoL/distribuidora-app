import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../providers/providers.dart';
import '../../providers/theme_provider.dart';
import '../../services/role_based_router.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../extensions/theme_extension.dart';

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
    final primaryRole = _getPrimaryRole(user);

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
                  gradient: _getRoleGradient(primaryRole),
                ),
                child: SafeArea(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildProfileHeader(context, user, primaryRole),
                  ),
                ),
              ),
            ),
            backgroundColor: _getRoleColor(primaryRole),
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
                      _buildRoleSpecificStats(context, user, primaryRole),
                      const SizedBox(height: 24),

                      // Información personal
                      _buildModernSectionTitle(
                        'Información Personal',
                        Icons.person_outline,
                      ),
                      const SizedBox(height: 12),
                      _buildModernInfoCard(
                        context: context,
                        icon: Icons.person_outline,
                        title: 'Nombre Completo',
                        value: user?.name ?? 'No disponible',
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildModernInfoCard(
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
                        _buildModernInfoCard(
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
                      _buildModernSectionTitle(
                        'Roles y Permisos',
                        Icons.admin_panel_settings_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildModernRolesCard(user),
                      const SizedBox(height: 24),

                      // Estado del usuario
                      _buildModernSectionTitle(
                        'Estado de Cuenta',
                        Icons.verified_user_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildModernStatusCard(user),
                      const SizedBox(height: 24),

                      // Seguridad y Autenticación
                      _buildModernSectionTitle(
                        'Seguridad',
                        Icons.security_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildSecurityCard(context, authProvider),
                      const SizedBox(height: 24),

                      // Apariencia
                      _buildModernSectionTitle(
                        'Apariencia',
                        Icons.palette_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildAppearanceCard(context),
                      const SizedBox(height: 24),

                      // Opciones específicas por rol
                      _buildRoleSpecificOptions(context, user, primaryRole),

                      // Botón de cerrar sesión moderno
                      const SizedBox(height: 8),
                      _buildModernLogoutButton(context),
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

  // Obtener rol principal del usuario
  String _getPrimaryRole(dynamic user) {
    final roles = user?.roles ?? [];
    if (roles.isEmpty) return 'Usuario';

    // Prioridad: Admin > Preventista > Chofer > Cliente
    if (roles.contains('Admin')) return 'Admin';
    if (roles.contains('Preventista')) return 'Preventista';
    if (roles.contains('Chofer')) return 'Chofer';
    if (roles.contains('Cliente')) return 'Cliente';

    return roles.first.toString();
  }

  // Gradiente específico por rol
  LinearGradient _getRoleGradient(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red.shade700, Colors.red.shade900],
        );
      case 'preventista':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.orange.shade600, Colors.deepOrange.shade800],
        );
      case 'cliente':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.teal.shade600, Colors.teal.shade900],
        );
      case 'chofer':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade600, Colors.green.shade900],
        );
      default:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade700, Colors.grey.shade900],
        );
    }
  }

  Widget _buildProfileHeader(
    BuildContext context,
    dynamic user,
    String primaryRole,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 30, bottom: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar moderno con borde y sombra
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: Text(
                    (user?.name ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 36,
                      color: _getRoleColor(primaryRole),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Nombre del usuario
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                user?.name ?? 'Usuario',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            // Descripción del rol con badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getRolePrimaryIcon(primaryRole),
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    RoleBasedRouter.getRoleDescription(user),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRolePrimaryIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.security;
      case 'preventista':
        return Icons.business_center;
      case 'cliente':
        return Icons.shopping_bag;
      case 'chofer':
        return Icons.local_shipping;
      default:
        return Icons.person;
    }
  }

  // Título de sección moderno
  Widget _buildModernSectionTitle(String title, IconData icon) {
    return Builder(
      builder: (context) {
        final colorScheme = context.colorScheme;
        final isDark = context.isDark;

        return Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.primary.withOpacity(0.2)
                    : colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textTheme.titleLarge?.color,
              ),
            ),
          ],
        );
      },
    );
  }

  // Tarjeta de información moderna con gradiente
  Widget _buildModernInfoCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Gradient gradient,
  }) {
    final colorScheme = context.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.textTheme.titleMedium?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tarjeta de roles moderna
  Widget _buildModernRolesCard(dynamic user) {
    final roles = user?.roles ?? [];

    return Builder(
      builder: (context) {
        final colorScheme = context.colorScheme;
        final isDark = context.isDark;

        if (roles.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHighest
                  : colorScheme.surfaceContainerHighest.withAlpha(100),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outline.withAlpha(50),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  'Sin roles asignados',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surfaceContainerHighest.withAlpha(100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: (roles as List<dynamic>).map((role) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getRoleColor(role.toString()),
                      _getRoleColor(role.toString()).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _getRoleColor(role.toString()).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getRolePrimaryIcon(role.toString()),
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getRoleLabel(role.toString()),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // Tarjeta de estado moderna
  Widget _buildModernStatusCard(dynamic user) {
    final isActive = user?.activo ?? false;

    return Builder(
      builder: (context) {
        final statusColor = isActive ? Colors.green : Colors.red;
        final colorScheme = context.colorScheme;
        final isDark = context.isDark;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark
                ? statusColor.withOpacity(0.1)
                : statusColor.withOpacity(0.05),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  isActive ? Icons.check_circle : Icons.cancel,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado de Cuenta',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isActive ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSecurityCard(BuildContext context, AuthProvider authProvider) {
    return FutureBuilder<bool>(
      future: authProvider.isBiometricLoginEnabled(),
      builder: (context, snapshot) {
        final biometricEnabled = snapshot.data ?? false;

        return Card(
          elevation: 2,
          child: Column(
            children: [
              // Autenticación Biométrica
              Builder(
                builder: (context) {
                  final biometricAvailable = authProvider.biometricAvailable;

                  if (!biometricAvailable) {
                    return ListTile(
                      leading: Icon(
                        Icons.fingerprint,
                        color: Colors.grey.shade400,
                      ),
                      title: const Text('Autenticación Biométrica'),
                      subtitle: const Text('No disponible en este dispositivo'),
                      enabled: false,
                    );
                  }

                  return FutureBuilder<String>(
                    future: authProvider.getBiometricTypeMessage(),
                    builder: (context, typeSnapshot) {
                      final biometricType = typeSnapshot.data ?? 'Biometría';

                      return SwitchListTile(
                        secondary: Icon(
                          biometricType.contains('Face')
                              ? Icons.face
                              : Icons.fingerprint,
                          color: biometricEnabled
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                        ),
                        title: Text('Usar $biometricType'),
                        subtitle: Text(
                          biometricEnabled
                              ? 'Habilitado para inicio rápido'
                              : 'Habilitar para inicio rápido',
                        ),
                        value: biometricEnabled,
                        onChanged: (bool value) async {
                          if (value) {
                            // Mostrar diálogo para habilitar
                            _showEnableBiometricDialog(context, authProvider);
                          } else {
                            // Deshabilitar directamente
                            final success = await authProvider
                                .disableBiometricLogin();
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$biometricType deshabilitado'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              // Forzar reconstrucción del widget
                              (context as Element).markNeedsBuild();
                            }
                          }
                        },
                      );
                    },
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock, color: Colors.blue),
                title: const Text('Cambiar Contraseña'),
                subtitle: const Text('Actualizar contraseña de acceso'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showChangePasswordDialog(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEnableBiometricDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Habilitar Autenticación Biométrica'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ingresa tus credenciales para habilitar el acceso biométrico.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Usuario o Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su usuario';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su contraseña';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final success = await authProvider.enableBiometricLogin(
                    usernameController.text.trim(),
                    passwordController.text,
                  );

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Autenticación biométrica habilitada'
                              : 'Error al habilitar autenticación biométrica',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );

                    if (success) {
                      // Forzar reconstrucción del widget
                      (context as Element).markNeedsBuild();
                    }
                  }
                }
              },
              child: const Text('Habilitar'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    bool showCurrentPassword = false;
    bool showNewPassword = false;
    bool showConfirmPassword = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.lock_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('Cambiar Contraseña'),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Por favor ingresa tu contraseña actual y la nueva contraseña.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: !showCurrentPassword,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Contraseña Actual',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        hintText: 'Ingresa tu contraseña actual',
                        suffixIcon: IconButton(
                          icon: Icon(
                            showCurrentPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(
                              () => showCurrentPassword = !showCurrentPassword,
                            );
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu contraseña actual';
                        }
                        if (value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: !showNewPassword,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Nueva Contraseña',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        hintText: 'Ingresa tu nueva contraseña',
                        suffixIcon: IconButton(
                          icon: Icon(
                            showNewPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(
                              () => showNewPassword = !showNewPassword,
                            );
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa una nueva contraseña';
                        }
                        if (value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        if (value == currentPasswordController.text) {
                          return 'La nueva contraseña debe ser diferente';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: !showConfirmPassword,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Confirmar Contraseña',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        hintText: 'Confirma tu nueva contraseña',
                        suffixIcon: IconButton(
                          icon: Icon(
                            showConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(
                              () => showConfirmPassword = !showConfirmPassword,
                            );
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor confirma tu contraseña';
                        }
                        if (value != newPasswordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (formKey.currentState?.validate() ?? false) {
                            setState(() => isLoading = true);

                            final success = await _changePassword(
                              currentPasswordController.text,
                              newPasswordController.text,
                            );

                            setState(() => isLoading = false);

                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Contraseña actualizada correctamente'
                                        : 'Error al actualizar la contraseña',
                                  ),
                                  backgroundColor:
                                      success ? Colors.green : Colors.red,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isLoading ? Colors.grey : Colors.blue,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Actualizar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _changePassword(String currentPassword, String newPassword) async {
    try {
      final authService = AuthService();
      final apiService = ApiService();
      final token = await authService.getToken();

      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesión expirada. Por favor inicia sesión nuevamente.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return false;
      }

      final response = await http.put(
        Uri.parse('${apiService.baseUrl}/settings/password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorData['message'] ??
                    'Error de validación. Verifica tus datos.',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return false;
      } else if (response.statusCode == 401) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contraseña actual incorrecta'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return false;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar contraseña: ${response.statusCode}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }

  String _getRoleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrador';
      case 'preventista':
        return 'Preventista';
      case 'cliente':
        return 'Cliente';
      case 'chofer':
        return 'Chofer';
      default:
        return role;
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'preventista':
        return Colors.orange;
      case 'cliente':
        return Colors.teal;
      case 'chofer':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Está seguro de que desea cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
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

  // Estadísticas específicas por rol
  Widget _buildRoleSpecificStats(
    BuildContext context,
    dynamic user,
    String primaryRole,
  ) {
    switch (primaryRole.toLowerCase()) {
      case 'cliente':
        return _buildClientStats(context);
      case 'preventista':
        return _buildPreventistaStats(context);
      case 'chofer':
        return _buildChoferStats(context);
      case 'admin':
        return _buildAdminStats(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildClientStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.teal.shade600],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade600.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shopping_cart, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'Resumen de Compras',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Pedidos', '0', Icons.receipt_long),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem('Direcciones', '0', Icons.location_on),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreventistaStats(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final stats = authProvider.preventistaStats;
        final totalClientes = stats?.totalClientes ?? 0;
        final clientesActivos = stats?.clientesActivos ?? 0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.orange.shade700],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.business_center, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Panel de Ventas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total Clientes',
                      totalClientes.toString(),
                      Icons.people,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      'Clientes Activos',
                      clientesActivos.toString(),
                      Icons.person_add,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChoferStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade700],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_shipping, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'Panel de Entregas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildStatItem('Entregas', '0', Icons.inventory)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatItem('Rutas', '0', Icons.map)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade700],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.dashboard, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'Panel de Administración',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildStatItem('Usuarios', '0', Icons.people)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatItem('Sistema', 'OK', Icons.settings)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Opciones específicas por rol
  Widget _buildRoleSpecificOptions(
    BuildContext context,
    dynamic user,
    String primaryRole,
  ) {
    switch (primaryRole.toLowerCase()) {
      case 'cliente':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModernSectionTitle('Mis Opciones', Icons.tune),
            const SizedBox(height: 12),
            _buildClientOptionsCard(context),
            const SizedBox(height: 24),
          ],
        );
      case 'preventista':
      case 'chofer':
      case 'admin':
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildClientOptionsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            _buildModernOptionTile(
              context: context,
              icon: Icons.location_on_outlined,
              title: 'Mis Direcciones',
              subtitle: 'Gestionar direcciones de entrega',
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
              onTap: () => Navigator.pushNamed(context, '/mis-direcciones'),
            ),
            const Divider(height: 1, indent: 72),
            _buildModernOptionTile(
              context: context,
              icon: Icons.shopping_bag_outlined,
              title: 'Mis Pedidos',
              subtitle: 'Ver historial de pedidos',
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidad en desarrollo'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    final colorScheme = context.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: context.textTheme.titleMedium?.color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 13,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }

  // Tarjeta de apariencia con switch de tema
  Widget _buildAppearanceCard(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDarkMode = themeProvider.isDarkMode;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surfaceContainerHighest.withAlpha(100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          size: 20,
                          color: isDarkMode
                              ? Colors.amber
                              : Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Modo ${isDarkMode ? 'Oscuro' : 'Claro'}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.textTheme.titleMedium?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isDarkMode
                          ? 'Interfaz oscura para menos luz'
                          : 'Interfaz clara para mejor visibilidad',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Switch(
                  key: ValueKey(isDarkMode),
                  value: isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                  activeColor: Colors.amber,
                  activeTrackColor: Colors.amber.shade200,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Botón de cerrar sesión moderno
  Widget _buildModernLogoutButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: const Icon(Icons.logout, size: 22),
        label: const Text(
          'Cerrar Sesión',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
