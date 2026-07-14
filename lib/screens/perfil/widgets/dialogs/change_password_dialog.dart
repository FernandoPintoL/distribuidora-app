import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../config/app_text_styles.dart';
import '../../../../extensions/theme_extension.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/api_service.dart';

class ChangePasswordDialog {
  static void show(BuildContext context, {required VoidCallback? onSuccess}) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    bool showCurrentPassword = false;
    bool showNewPassword = false;
    bool showConfirmPassword = false;
    bool isDark = context.isDark;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: context.colorScheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Cambiar Contraseña',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Por favor ingresa tu contraseña actual y la nueva contraseña.',
                      style: TextStyle(color: Colors.grey),
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
                            setState(() => showNewPassword = !showNewPassword);
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
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
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
                              context,
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
                                  backgroundColor: success
                                      ? Colors.green
                                      : Colors.red,
                                  duration: const Duration(seconds: 3),
                                ),
                              );

                              if (success) {
                                onSuccess?.call();
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLoading
                        ? Colors.grey
                        : context.colorScheme.secondary,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
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

  static Future<bool> _changePassword(
    String currentPassword,
    String newPassword,
    BuildContext context,
  ) async {
    try {
      final authService = AuthService();
      final apiService = ApiService();
      final token = await authService.getToken();

      if (token == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Sesión expirada. Por favor inicia sesión nuevamente.',
              ),
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
        if (context.mounted) {
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
        if (context.mounted) {
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error al actualizar contraseña: ${response.statusCode}',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (context.mounted) {
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
}
