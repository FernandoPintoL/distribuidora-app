import 'package:flutter/material.dart';
import '../../../providers/providers.dart';
import 'dialogs/change_password_dialog.dart';

class PerfilSecurityCardWidget extends StatefulWidget {
  final BuildContext parentContext;
  final AuthProvider authProvider;

  const PerfilSecurityCardWidget({
    super.key,
    required this.parentContext,
    required this.authProvider,
  });

  @override
  State<PerfilSecurityCardWidget> createState() =>
      _PerfilSecurityCardWidgetState();
}

class _PerfilSecurityCardWidgetState extends State<PerfilSecurityCardWidget> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: widget.authProvider.isBiometricLoginEnabled(),
      builder: (context, snapshot) {
        return Card(
          elevation: 2,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lock, color: Colors.blue),
                title: const Text('Cambiar Contraseña'),
                subtitle: const Text('Actualizar contraseña de acceso'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => ChangePasswordDialog.show(
                  context,
                  onSuccess: () {
                    (widget.parentContext as Element).markNeedsBuild();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
