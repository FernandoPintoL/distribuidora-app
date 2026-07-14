import 'package:flutter/material.dart';
import '../../../config/app_text_styles.dart';
import '../../../services/role_based_router.dart';
import '../helpers/perfil_helpers.dart';

class PerfilHeaderWidget extends StatelessWidget {
  final dynamic user;
  final String primaryRole;

  const PerfilHeaderWidget({
    super.key,
    required this.user,
    required this.primaryRole,
  });

  @override
  Widget build(BuildContext context) {
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
                      color: getRoleColor(primaryRole),
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
                user?.name.toUpperCase() ?? 'Usuario',
                style: TextStyle(
                  fontSize: 18,
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
                    getRolePrimaryIcon(primaryRole),
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      RoleBasedRouter.getRoleDescription(user),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
}
