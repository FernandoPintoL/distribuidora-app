import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../config/config.dart';

class RegistrarGastoScreen extends StatefulWidget {
  const RegistrarGastoScreen({Key? key}) : super(key: key);

  @override
  State<RegistrarGastoScreen> createState() => _RegistrarGastoScreenState();
}

class _RegistrarGastoScreenState extends State<RegistrarGastoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _numeroComprobanteController = TextEditingController();
  final _proveedorController = TextEditingController();
  final _observacionesController = TextEditingController();

  String _categoriaSeleccionada = 'VARIOS';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    _numeroComprobanteController.dispose();
    _proveedorController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Gasto'),
        elevation: 0,
      ),
      body: Consumer<CajaProvider>(
        builder: (context, cajaProvider, _) {
          if (!cajaProvider.estaCajaAbierta) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Debe abrir una caja primero',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tarjeta de información
                  Card(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Registra tus gastos durante el día',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Monto
                  TextFormField(
                    controller: _montoController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Monto (Bs) *',
                      prefixIcon: const Icon(Icons.attach_money),
                      hintText: '0.00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El monto es obligatorio';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Ingresa un monto válido';
                      }
                      if (double.parse(value) <= 0) {
                        return 'El monto debe ser mayor a 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Categoría
                  DropdownButtonFormField<String>(
                    value: _categoriaSeleccionada,
                    decoration: InputDecoration(
                      labelText: 'Categoría *',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: Gasto.categorias
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(_getLabelCategoria(cat)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _categoriaSeleccionada = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Descripción
                  TextFormField(
                    controller: _descripcionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Descripción *',
                      hintText: 'Ej: Gasolina, Comida, Mantenimiento',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La descripción es obligatoria';
                      }
                      if (value.length < 3) {
                        return 'La descripción debe tener al menos 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Número de Comprobante (opcional)
                  TextFormField(
                    controller: _numeroComprobanteController,
                    decoration: InputDecoration(
                      labelText: 'Número de Comprobante',
                      hintText: 'Ej: 0000123456789',
                      prefixIcon: const Icon(Icons.receipt),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Proveedor (opcional)
                  TextFormField(
                    controller: _proveedorController,
                    decoration: InputDecoration(
                      labelText: 'Proveedor/Negocio',
                      hintText: 'Ej: Gasolinera del Centro',
                      prefixIcon: const Icon(Icons.business),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Observaciones (opcional)
                  TextFormField(
                    controller: _observacionesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Observaciones',
                      hintText: 'Notas adicionales (opcional)',
                      prefixIcon: const Icon(Icons.note),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botón de envío
                  Consumer<GastoProvider>(
                    builder: (context, gastoProvider, _) {
                      return ElevatedButton(
                        onPressed: _isSubmitting || gastoProvider.isLoading
                            ? null
                            : () => _registrarGasto(gastoProvider),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: colorScheme.primary,
                        ),
                        child: _isSubmitting || gastoProvider.isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : const Text('Registrar Gasto'),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _registrarGasto(GastoProvider gastoProvider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final exito = await gastoProvider.registrarGasto(
      monto: double.parse(_montoController.text),
      descripcion: _descripcionController.text,
      categoria: _categoriaSeleccionada,
      numeroComprobante: _numeroComprobanteController.text.isNotEmpty
          ? _numeroComprobanteController.text
          : null,
      proveedor: _proveedorController.text.isNotEmpty
          ? _proveedorController.text
          : null,
      observaciones: _observacionesController.text.isNotEmpty
          ? _observacionesController.text
          : null,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Gasto registrado correctamente'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    } else {
      final errorMsg = gastoProvider.errorMessage?.toString() ?? 'Error desconocido';
      debugPrint('❌ Error registrando gasto: $errorMsg');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $errorMsg'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _getLabelCategoria(String categoria) {
    final labels = {
      'TRANSPORTE': '🚗 Transporte',
      'LIMPIEZA': '🧹 Limpieza',
      'MANTENIMIENTO': '🔧 Mantenimiento',
      'SERVICIOS': '⚙️ Servicios',
      'VARIOS': '📋 Varios',
    };
    return labels[categoria] ?? categoria;
  }
}
