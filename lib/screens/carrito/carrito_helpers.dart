import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';

/// Muestra un mensaje de error si existe en el CarritoProvider
void mostrarErrorSiExiste(
  BuildContext context,
  CarritoProvider carritoProvider, {
  int duracion = 3,
}) {
  if (carritoProvider.errorMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(carritoProvider.errorMessage!),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: duracion),
      ),
    );
  }
}

/// Muestra un diálogo de confirmación para vaciar el carrito
void mostrarDialogoVaciarCarrito(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Vaciar Carrito'),
        content: const Text('¿Estás seguro de que quieres eliminar todos los productos del carrito?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<CarritoProvider>().limpiarCarrito();
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Carrito vaciado'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Vaciar', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
}

/// Navega a la pantalla de selección de tipo de entrega (DELIVERY o PICKUP)
/// ✅ ACTUALIZADO: Carga información del cliente antes de navegar
void continuarCompra(BuildContext context) async {
  // Verificar que el carrito no esté vacío
  final carritoProvider = context.read<CarritoProvider>();

  if (carritoProvider.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('El carrito está vacío'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // ✅ ACTUALIZADO: Validar cantidad mínima considerando componentes de combos
  // Combos: Suma la cantidad de todos sus componentes
  // Productos simples: Cuenta su cantidad
  int cantidadItemsValidacion = 0;
  for (final item in carritoProvider.items) {
    if (item.producto.esCombo && item.comboItemsSeleccionados != null && item.comboItemsSeleccionados!.isNotEmpty) {
      // Combo: Sumar cantidad de todos sus componentes
      for (final comboItem in item.comboItemsSeleccionados!) {
        final comboItemCantidad = comboItem['cantidad'] ?? 1;
        final cantidad = comboItemCantidad is int
          ? comboItemCantidad
          : (comboItemCantidad as num).toInt();
        cantidadItemsValidacion += cantidad;
      }
    } else {
      // Producto simple o combo sin componentes seleccionados: contar su cantidad
      cantidadItemsValidacion += item.cantidad.toInt();
    }
  }

  if (cantidadItemsValidacion < 5) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Debes tener mínimo 5 productos en el carrito (tienes $cantidadItemsValidacion)',
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
    return;
  }

  // Obtener providers necesarios
  final authProvider = context.read<AuthProvider>();
  final clientProvider = context.read<ClientProvider>();

  // Variables para almacenar información del cliente
  int? clienteId;
  bool isPreventista = false;

  // ✅ ACTUALIZADO: Obtener clienteId según el tipo de usuario
  try {
    final userRoles = authProvider.user?.roles ?? [];
    isPreventista = userRoles.any((role) =>
        role.toLowerCase() == 'preventista');

    if (isPreventista) {
      // Preventista: debe tener cliente seleccionado en carritoProvider
      if (!carritoProvider.tieneClienteSeleccionado) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes seleccionar un cliente para continuar'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      clienteId = carritoProvider.getClienteSeleccionadoId();
    } else {
      // Cliente logueado: usar su clienteId del user
      clienteId = authProvider.user?.clienteId;
      if (clienteId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No se encontró información de cliente'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
  } catch (e) {
    debugPrint('❌ Error verificando rol de usuario: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error al validar usuario'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // ✅ NUEVO: Mostrar loading mientras se carga la información del cliente
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Cargando información del cliente...'),
      duration: Duration(seconds: 1),
    ),
  );

  try {
    // ✅ NUEVO: Cargar datos completos del cliente desde la API
    debugPrint('👤 [CarritoScreen] Cargando cliente ID: $clienteId');
    final cliente = await clientProvider.getClient(clienteId!);

    if (!context.mounted) return;

    if (cliente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se pudo cargar la información del cliente'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ NUEVO: Guardar cliente en carritoProvider para reutilizar en pantallas siguientes
    carritoProvider.setClienteSeleccionado(cliente);
    debugPrint('✅ [CarritoScreen] Cliente cargado en provider: ${cliente.nombre}');

    // ✅ ACTUALIZADO: Navegar según tipo de usuario
    // - Preventista: Navega a /proforma-creacion (nuevo flujo con combos)
    // - Cliente: Navega a /resumen-pedido (flujo tradicional)
    if (context.mounted) {
      if (isPreventista) {
        debugPrint('🎯 Preventista detectado, navegando a pantalla de creación de proforma');
        Navigator.pushNamed(context, '/proforma-creacion');
      } else {
        debugPrint('🎯 Cliente detectado, navegando a resumen de pedido');
        Navigator.pushNamed(context, '/resumen-pedido');
      }
    }
  } catch (e) {
    debugPrint('❌ Error al cargar cliente en continuarCompra: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar cliente: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
