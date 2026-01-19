import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../config/config.dart';
import 'registrar_gasto_screen.dart';
import 'historial_gastos_screen.dart';
import 'cierre_caja_screen.dart';

class CajaScreen extends StatefulWidget {
  const CajaScreen({Key? key}) : super(key: key);

  @override
  State<CajaScreen> createState() => _CajaScreenState();
}

class _CajaScreenState extends State<CajaScreen> {
  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final cajaProvider = context.read<CajaProvider>();
    await cajaProvider.cargarEstadoCaja();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Consumer<CajaProvider>(
        builder: (context, cajaProvider, _) {
          if (cajaProvider.isLoading && cajaProvider.cajaActual == null) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  colorScheme.primary,
                ),
              ),
            );
          }

          // Si no hay caja abierta
          if (cajaProvider.cajaActual == null) {
            return _buildSinCajaAbierta(context, cajaProvider);
          }

          // Si hay caja abierta
          return _buildCajaAbierta(context, cajaProvider, isDarkMode, colorScheme);
        },
      ),
    );
  }

  Widget _buildSinCajaAbierta(
    BuildContext context,
    CajaProvider cajaProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.lock_open_rounded,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '¡Abre tu Caja!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'No tienes una caja abierta.\nAbre una para comenzar a registrar tus movimientos.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _mostrarDialogoAbrirCaja(context, cajaProvider),
              icon: const Icon(Icons.add),
              label: const Text('Abrir Caja'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                backgroundColor: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCajaAbierta(
    BuildContext context,
    CajaProvider cajaProvider,
    bool isDarkMode,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tarjeta de estado de caja
          _buildTarjetaEstadoCaja(context, cajaProvider, colorScheme),
          const SizedBox(height: 20),

          // Resumen de movimientos
          _buildResumenMovimientos(context, cajaProvider, colorScheme),
          const SizedBox(height: 20),

          // Acciones rápidas
          _buildAccionesRapidas(context, cajaProvider, colorScheme),
          const SizedBox(height: 20),

          // Últimos movimientos
          _buildUltimosMovimientos(context, cajaProvider, colorScheme),
        ],
      ),
    );
  }

  Widget _buildTarjetaEstadoCaja(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Caja Abierta',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Activa',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Tiempo abierta',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
              ),
            ),
            Text(
              caja.tiempoTranscurrido,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monto de apertura',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                      ),
                    ),
                    Text(
                      '${caja.montoApertura.toStringAsFixed(2)} Bs',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenMovimientos(
    BuildContext context,
    CajaProvider cajaProvider,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildTarjetaMovimiento(
            context,
            '💰 Ingresos',
            '${cajaProvider.totalIngresos.toStringAsFixed(2)} Bs',
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTarjetaMovimiento(
            context,
            '📉 Gastos',
            '-${cajaProvider.totalEgresos.abs().toStringAsFixed(2)} Bs',
            Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTarjetaMovimiento(
            context,
            '✅ Saldo',
            '${cajaProvider.saldoActual.toStringAsFixed(2)} Bs',
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildTarjetaMovimiento(
    BuildContext context,
    String label,
    String monto,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              monto,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccionesRapidas(
    BuildContext context,
    CajaProvider cajaProvider,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RegistrarGastoScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_circle),
            label: const Text('Registrar Gasto'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const HistorialGastosScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.history),
                label: const Text('Gastos'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CierreCajaScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.lock),
                label: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUltimosMovimientos(
    BuildContext context,
    CajaProvider cajaProvider,
    ColorScheme colorScheme,
  ) {
    if (cajaProvider.movimientos.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Sin movimientos aún',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Últimos Movimientos',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cajaProvider.movimientos.take(5).length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final movimiento = cajaProvider.movimientos[index];
              return ListTile(
                leading: Icon(
                  movimiento.tipoIcono,
                  color: movimiento.tipoColor,
                ),
                title: Text(
                  movimiento.descripcion,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  movimiento.tipoLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                trailing: Text(
                  movimiento.montoFormato,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: movimiento.tipoColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _mostrarDialogoAbrirCaja(
    BuildContext context,
    CajaProvider cajaProvider,
  ) {
    final montoController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abrir Caja'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ingresa el monto inicial para abrir la caja',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: montoController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0.00',
                labelText: 'Monto Inicial (Bs)',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final monto = double.tryParse(montoController.text) ?? 0.0;
              final exito = await cajaProvider.abrirCaja(
                montoApertura: monto,
              );

              if (!mounted) return;

              if (exito) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Caja abierta correctamente'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '❌ Error: ${cajaProvider.errorMessage}',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
            ),
            child: const Text('Abrir'),
          ),
        ],
      ),
    );
  }
}
