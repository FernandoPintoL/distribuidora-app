import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../config/config.dart';

class CierreCajaScreen extends StatefulWidget {
  const CierreCajaScreen({Key? key}) : super(key: key);

  @override
  State<CierreCajaScreen> createState() => _CierreCajaScreenState();
}

class _CierreCajaScreenState extends State<CierreCajaScreen> {
  final _montosCierreController = TextEditingController();
  final _observacionesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _montosCierreController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cierre de Caja'),
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
                    'No hay caja abierta',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tarjeta de resumen
                _buildTarjetaResumen(context, cajaProvider, colorScheme),
                const SizedBox(height: 24),

                // Tarjeta de información
                Card(
                  color: Colors.orange[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Verifica que el dinero físico coincida con el saldo calculado',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Formulario de cierre
                _buildFormularioCierre(context, cajaProvider, colorScheme),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTarjetaResumen(
    BuildContext context,
    CajaProvider cajaProvider,
    ColorScheme colorScheme,
  ) {
    final caja = cajaProvider.cajaActual!;

    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Resumen de Caja',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildResumenRow(
              'Monto de Apertura',
              '${caja.montoApertura.toStringAsFixed(2)} Bs',
              Colors.white,
              context,
            ),
            const SizedBox(height: 12),
            _buildResumenRow(
              'Ingresos (Ventas)',
              '+${cajaProvider.totalIngresos.toStringAsFixed(2)} Bs',
              Colors.green[300] ?? Colors.green,
              context,
            ),
            const SizedBox(height: 12),
            _buildResumenRow(
              'Egresos (Gastos)',
              '-${cajaProvider.totalEgresos.abs().toStringAsFixed(2)} Bs',
              Colors.pink[200] ?? Colors.red,
              context,
            ),
            const Divider(color: Colors.white30),
            const SizedBox(height: 12),
            _buildResumenRow(
              'Saldo Esperado',
              '${cajaProvider.saldoActual.toStringAsFixed(2)} Bs',
              Colors.white,
              context,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenRow(
    String label,
    String valor,
    Color color,
    BuildContext context, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
        ),
        Text(
          valor,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
        ),
      ],
    );
  }

  Widget _buildFormularioCierre(
    BuildContext context,
    CajaProvider cajaProvider,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Confirmación de Cierre',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // Monto físico contado
        TextFormField(
          controller: _montosCierreController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Dinero Físico Contado (Bs)',
            hintText: cajaProvider.saldoActual.toStringAsFixed(2),
            prefixIcon: const Icon(Icons.attach_money),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            helperText:
                'Ingresa cuánto dinero contaste en tu caja',
          ),
        ),
        const SizedBox(height: 16),

        // Comparación
        if (_montosCierreController.text.isNotEmpty)
          _buildComparacion(context, cajaProvider),

        const SizedBox(height: 16),

        // Observaciones
        TextFormField(
          controller: _observacionesController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Observaciones',
            hintText:
                'Si hay diferencias, explica qué sucedió (opcional)',
            prefixIcon: const Icon(Icons.note),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Botón de cierre
        Consumer<CajaProvider>(
          builder: (context, cajaProvider, _) {
            return ElevatedButton.icon(
              onPressed: _isSubmitting || cajaProvider.isLoading
                  ? null
                  : () => _confirmarCierre(cajaProvider),
              icon: const Icon(Icons.lock),
              label: const Text('Confirmar Cierre'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: colorScheme.primary,
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Botón de cancelar
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  Widget _buildComparacion(
    BuildContext context,
    CajaProvider cajaProvider,
  ) {
    final saldoEsperado = cajaProvider.saldoActual;
    final montoContado = double.tryParse(_montosCierreController.text) ?? 0.0;
    final diferencia = montoContado - saldoEsperado;
    final hayDiferencia = diferencia.abs() > 0.01;

    Color colorDiferencia = Colors.green;
    String mensajeDiferencia = '✅ Cierre OK';

    if (hayDiferencia) {
      if (diferencia > 0) {
        colorDiferencia = Colors.blue;
        mensajeDiferencia = '+${diferencia.toStringAsFixed(2)} Bs (Exceso)';
      } else {
        colorDiferencia = Colors.red;
        mensajeDiferencia =
            '${diferencia.toStringAsFixed(2)} Bs (Faltante)';
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorDiferencia.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorDiferencia.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saldo Esperado:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${saldoEsperado.toStringAsFixed(2)} Bs',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dinero Contado:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${montoContado.toStringAsFixed(2)} Bs',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Diferencia:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                mensajeDiferencia,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorDiferencia,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarCierre(CajaProvider cajaProvider) async {
    if (_montosCierreController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa el dinero contado'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final montosCierre = double.tryParse(_montosCierreController.text) ?? 0.0;
    final exito = await cajaProvider.cerrarCaja(
      montosCierre: montosCierre,
      observaciones: _observacionesController.text.isNotEmpty
          ? _observacionesController.text
          : null,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Caja cerrada correctamente'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
      Navigator.pop(context); // Volver a caja_screen también
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${cajaProvider.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
