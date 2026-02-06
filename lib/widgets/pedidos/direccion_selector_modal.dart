import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../extensions/theme_extension.dart';

/// Modal para seleccionar una dirección de entrega
/// Se abre como ModalBottomSheet y retorna ClientAddress seleccionada
class DireccionSelectorModal extends StatefulWidget {
  final Client cliente;
  final ClientAddress? direccionInicial;

  const DireccionSelectorModal({
    super.key,
    required this.cliente,
    this.direccionInicial,
  });

  @override
  State<DireccionSelectorModal> createState() => _DireccionSelectorModalState();
}

class _DireccionSelectorModalState extends State<DireccionSelectorModal> {
  late ClientAddress? _direccionSeleccionada;
  bool _esPreventista = false;

  @override
  void initState() {
    super.initState();
    _direccionSeleccionada = widget.direccionInicial;

    // Detectar si es preventista
    final authProvider = context.read<AuthProvider>();
    final roles = authProvider.user?.roles ?? [];
    _esPreventista = roles.any((role) => role.toLowerCase().contains('preventista'));
  }

  void _seleccionar() {
    if (_direccionSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una dirección'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Navigator.pop(context, _direccionSeleccionada);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;
    final direcciones = widget.cliente.direcciones ?? [];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(isDark ? 0.15 : 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Indicador de drag
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.outline.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Título
                    Text(
                      'Seleccionar Dirección de Entrega',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Subtitle
                    Text(
                      _esPreventista
                          ? 'Dirección para ${widget.cliente.nombre}'
                          : 'Elige una de tus direcciones',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de direcciones
              if (direcciones.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 48,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No hay direcciones registradas',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: direcciones.length,
                    itemBuilder: (context, index) {
                      final direccion = direcciones[index];
                      final isSelected = _direccionSeleccionada?.id == direccion.id;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Card(
                          color: isSelected
                              ? colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1)
                              : colorScheme.surfaceVariant,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outline.withOpacity(isDark ? 0.3 : 0.2),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _direccionSeleccionada = direccion;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Icono de ubicación
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary
                                          .withOpacity(isDark ? 0.2 : 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.location_on,
                                      color: colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Información de dirección
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          direccion.direccion,
                                          style: context.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (direccion.ciudad != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Ciudad: ${direccion.ciudad}',
                                            style: context.textTheme.bodySmall
                                                ?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                        if (direccion.observaciones != null &&
                                            direccion.observaciones!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Obs: ${direccion.observaciones}',
                                            style: context.textTheme.bodySmall
                                                ?.copyWith(
                                              color: colorScheme.primary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Indicador de selección
                                  Radio<ClientAddress?>(
                                    value: direccion,
                                    groupValue: _direccionSeleccionada,
                                    onChanged: (value) {
                                      setState(() {
                                        _direccionSeleccionada = value;
                                      });
                                    },
                                    activeColor: colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Botones de acción
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outline.withOpacity(isDark ? 0.3 : 0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _seleccionar,
                        child: const Text('Seleccionar'),
                      ),
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
}
