import 'package:flutter/widgets.dart';
import '../models/carrito.dart';
import '../models/carrito_item.dart';
import '../models/product.dart';
import '../services/carrito_service.dart';
import '../services/api_service.dart';

class CarritoProvider with ChangeNotifier {
  Carrito _carrito = Carrito(items: []);
  bool _isLoading = false;
  String? _errorMessage;
  double _costoEnvio = 0;
  String? _direccionId;
  bool _calculandoEnvio = false;

  // Descuentos
  String? _codigoDescuento;
  double _porcentajeDescuento = 0;
  double _montoDescuento = 0;
  bool _validandoDescuento = false;

  // Persistencia
  late CarritoService _carritoService;
  bool _guardandoCarrito = false;
  bool _recuperandoCarrito = false;
  int? _usuarioId;

  CarritoProvider() {
    _carritoService = CarritoService(ApiService());
  }

  // Getters
  Carrito get carrito => _carrito;
  List<CarritoItem> get items => _carrito.items;
  int get cantidadItems => _carrito.cantidadItems;
  int get cantidadProductos => _carrito.cantidadProductos;
  double get subtotal => _carrito.subtotal;
  double get impuesto => _carrito.impuesto;
  double get total => _carrito.total;
  double get costoEnvio => _costoEnvio;
  double get totalConEnvio => subtotal + impuesto + _costoEnvio;

  // Descuentos getters
  String? get codigoDescuento => _codigoDescuento;
  double get porcentajeDescuento => _porcentajeDescuento;
  double get montoDescuento => _montoDescuento;
  bool get tieneDescuento => _montoDescuento > 0;
  bool get validandoDescuento => _validandoDescuento;

  // Total con descuento e impuesto
  double get subtotalConDescuento => subtotal - _montoDescuento;
  double get totalConDescuento => subtotalConDescuento + impuesto + _costoEnvio;

  bool get isEmpty => _carrito.isEmpty;
  bool get isNotEmpty => _carrito.isNotEmpty;
  bool get isLoading => _isLoading;
  bool get calculandoEnvio => _calculandoEnvio;
  bool get guardandoCarrito => _guardandoCarrito;
  bool get recuperandoCarrito => _recuperandoCarrito;
  String? get errorMessage => _errorMessage;

  // Método para inicializar el usuario (llamar al crear el provider)
  void inicializarUsuario(int usuarioId) {
    _usuarioId = usuarioId;
    debugPrint('👤 CarritoProvider inicializado para usuario: $usuarioId');
  }

  // Agregar producto al carrito con validación de stock
  void agregarProducto(
    Product producto, {
    double cantidad = 1.0,
    String? observaciones,
  }) {
    _errorMessage = null;

    // Validar cantidad positiva
    if (cantidad <= 0) {
      _errorMessage = 'La cantidad debe ser mayor a 0';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return;
    }

    // Validar cantidad mínima
    final cantidadMinima = (producto.cantidadMinima ?? 1).toDouble();
    if (cantidad < cantidadMinima) {
      final unidad = producto.unidadMedida?.nombre ?? 'unidades';
      _errorMessage = 'Cantidad mínima: ${cantidadMinima.toStringAsFixed(1)} $unidad (solicitaste: ${cantidad.toStringAsFixed(1)})';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      debugPrint('❌ Error: Cantidad mínima no cumplida para ${producto.nombre}');
      return;
    }

    // Validar stock disponible
    final stockDisponible = producto.stockPrincipal?.cantidadDisponible ?? 0;
    final stockDispDouble = (stockDisponible as num).toDouble();

    if (cantidad > stockDispDouble) {
      _errorMessage = 'Stock insuficiente. Disponible: ${stockDispDouble.toStringAsFixed(1)} ${producto.unidadMedida?.nombre ?? 'unidades'}';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      debugPrint('❌ Error al agregar $cantidad de ${producto.nombre}: $_errorMessage');
      return;
    }

    // Verificar si el producto ya está en el carrito
    final itemExistente = _carrito.getItemByProductoId(producto.id);

    List<CarritoItem> nuevosItems = List.from(_carrito.items);

    if (itemExistente != null) {
      // Si ya existe, validar que la nueva cantidad total no exceda el stock
      final nuevaCantidadTotal = itemExistente.cantidad + cantidad;
      if (nuevaCantidadTotal > stockDispDouble) {
        _errorMessage = 'Cantidad total excede el stock disponible. Máximo disponible: ${stockDispDouble.toStringAsFixed(1)}, actualmente en carrito: ${itemExistente.cantidad.toStringAsFixed(1)}';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        debugPrint('❌ Error al agregar más de ${producto.nombre}: $_errorMessage');
        return;
      }

      // Si pasa la validación, actualizar la cantidad
      final index = nuevosItems.indexWhere(
        (item) => item.producto.id == producto.id,
      );
      nuevosItems[index] = itemExistente.copyWith(
        cantidad: nuevaCantidadTotal,
      );
      debugPrint('✅ Cantidad de ${producto.nombre} aumentada a $nuevaCantidadTotal');
    } else {
      // Si no existe, agregarlo
      nuevosItems.add(
        CarritoItem(
          producto: producto,
          cantidad: cantidad,
          observaciones: observaciones,
        ),
      );
      debugPrint('✅ ${producto.nombre} agregado al carrito con cantidad: $cantidad');
    }

    _carrito = _carrito.copyWith(items: nuevosItems);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Actualizar cantidad de un producto con validación de stock
  void actualizarCantidad(int productoId, double nuevaCantidad) {
    _errorMessage = null;

    if (nuevaCantidad <= 0) {
      eliminarProducto(productoId);
      return;
    }

    final itemExistente = _carrito.getItemByProductoId(productoId);
    if (itemExistente == null) return;

    // Validar stock disponible
    final producto = itemExistente.producto;
    final stockDisponible = producto.stockPrincipal?.cantidadDisponible ?? 0;
    final stockDispDouble = (stockDisponible as num).toDouble();

    if (nuevaCantidad > stockDispDouble) {
      _errorMessage = 'Cantidad excede el stock disponible. Máximo: ${stockDispDouble.toStringAsFixed(1)} ${producto.unidadMedida?.nombre ?? 'unidades'}';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      debugPrint('❌ Error al actualizar ${producto.nombre} a $nuevaCantidad: $_errorMessage');
      return;
    }

    List<CarritoItem> nuevosItems = List.from(_carrito.items);
    final index = nuevosItems.indexWhere(
      (item) => item.producto.id == productoId,
    );

    nuevosItems[index] = itemExistente.copyWith(cantidad: nuevaCantidad);

    _carrito = _carrito.copyWith(items: nuevosItems);

    debugPrint('✅ Cantidad de ${producto.nombre} actualizada a $nuevaCantidad');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Incrementar cantidad de un producto con validación de stock
  void incrementarCantidad(int productoId, {double incremento = 1.0}) {
    _errorMessage = null;

    final itemExistente = _carrito.getItemByProductoId(productoId);
    if (itemExistente == null) return;

    final producto = itemExistente.producto;
    final stockDisponible = producto.stockPrincipal?.cantidadDisponible ?? 0;
    final stockDispDouble = (stockDisponible as num).toDouble();
    final nuevaCantidadTotal = itemExistente.cantidad + incremento;

    if (nuevaCantidadTotal > stockDispDouble) {
      _errorMessage = 'No hay stock suficiente para agregar más. Disponible: ${stockDispDouble.toStringAsFixed(1)}, en carrito: ${itemExistente.cantidad.toStringAsFixed(1)}';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      debugPrint('❌ Error al incrementar ${producto.nombre}: $_errorMessage');
      return;
    }

    debugPrint('⬆️ Incrementando ${producto.nombre} por $incremento unidades');
    actualizarCantidad(productoId, nuevaCantidadTotal);
  }

  // Decrementar cantidad de un producto
  void decrementarCantidad(int productoId, {double decremento = 1.0}) {
    final itemExistente = _carrito.getItemByProductoId(productoId);
    if (itemExistente == null) return;

    final producto = itemExistente.producto;
    final nuevaCantidad = itemExistente.cantidad - decremento;

    if (nuevaCantidad <= 0) {
      debugPrint('🗑️ Eliminando ${producto.nombre} del carrito');
      eliminarProducto(productoId);
    } else {
      debugPrint('⬇️ Decrementando ${producto.nombre} por $decremento unidades');
      actualizarCantidad(productoId, nuevaCantidad);
    }
  }

  // Eliminar producto del carrito
  void eliminarProducto(int productoId) {
    final itemAEliminar = _carrito.getItemByProductoId(productoId);

    List<CarritoItem> nuevosItems = _carrito.items
        .where((item) => item.producto.id != productoId)
        .toList();

    _carrito = _carrito.copyWith(items: nuevosItems);

    if (itemAEliminar != null) {
      debugPrint('🗑️ ${itemAEliminar.producto.nombre} eliminado del carrito');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Actualizar observaciones de un item
  void actualizarObservaciones(int productoId, String observaciones) {
    final itemExistente = _carrito.getItemByProductoId(productoId);
    if (itemExistente == null) return;

    List<CarritoItem> nuevosItems = List.from(_carrito.items);
    final index = nuevosItems.indexWhere(
      (item) => item.producto.id == productoId,
    );

    nuevosItems[index] = itemExistente.copyWith(observaciones: observaciones);

    _carrito = _carrito.copyWith(items: nuevosItems);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Limpiar carrito
  void limpiarCarrito() {
    debugPrint('🗑️ Carrito limpiado (${_carrito.items.length} productos eliminados)');
    _carrito = Carrito(items: []);
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Verificar si hay stock suficiente para un producto antes de operaciones
  bool tieneStockDisponible(int productoId, double cantidadSolicitada) {
    final item = _carrito.getItemByProductoId(productoId);
    if (item == null) return false;

    final stockDisponible = item.producto.stockPrincipal?.cantidadDisponible ?? 0;
    final stockDispDouble = (stockDisponible as num).toDouble();

    return cantidadSolicitada <= stockDispDouble;
  }

  // Obtener la cantidad máxima disponible de un producto
  double obtenerMaximaDisponible(int productoId) {
    final item = _carrito.getItemByProductoId(productoId);
    if (item == null) return 0.0;

    final stockDisponible = item.producto.stockPrincipal?.cantidadDisponible ?? 0;
    return (stockDisponible as num).toDouble();
  }

  // Verificar si un producto está en el carrito
  bool tieneProducto(int productoId) {
    return _carrito.tieneProducto(productoId);
  }

  // Obtener cantidad de un producto en el carrito
  double getCantidadProducto(int productoId) {
    final item = _carrito.getItemByProductoId(productoId);
    return item?.cantidad ?? 0.0;
  }

  // Calcular costo de envío basado en dirección y cantidad de items
  Future<void> calcularEnvio(String direccionId) async {
    _calculandoEnvio = true;
    _direccionId = direccionId;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      // Simular cálculo de envío
      // En producción, hacer llamada a API:
      // POST /api/envios/calcular
      // { items_count, subtotal, direccion_id }

      debugPrint('📦 Calculando costo de envío para dirección: $direccionId');
      debugPrint('   Items en carrito: ${_carrito.items.length}');
      debugPrint('   Subtotal: ${subtotal.toStringAsFixed(2)} Bs');

      // Simular delay de API (500ms)
      await Future.delayed(const Duration(milliseconds: 500));

      // Cálculo simple: Bs 5 base + Bs 2.50 por item
      final costoBase = 5.0;
      final costoXItem = _carrito.items.length * 2.5;
      _costoEnvio = costoBase + costoXItem;

      // Aplicar descuento si subtotal > 200
      if (subtotal > 200) {
        _costoEnvio = (_costoEnvio * 0.7); // 30% descuento en envío
        debugPrint('✅ Descuento en envío aplicado (>Bs200): ${(_costoEnvio).toStringAsFixed(2)} Bs');
      }

      debugPrint('✅ Costo de envío calculado: ${_costoEnvio.toStringAsFixed(2)} Bs');
      debugPrint('📊 Total con envío: ${totalConEnvio.toStringAsFixed(2)} Bs');

      _calculandoEnvio = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = 'Error al calcular envío: ${e.toString()}';
      _costoEnvio = 0;
      _calculandoEnvio = false;

      debugPrint('❌ Error calculando envío: $e');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // Resetear costo de envío
  void resetearEnvio() {
    _costoEnvio = 0;
    _direccionId = null;
    debugPrint('🔄 Costo de envío reseteado');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Aplicar código de descuento
  Future<bool> aplicarDescuento(String codigo) async {
    if (codigo.isEmpty) {
      _errorMessage = 'Ingresa un código de descuento';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    }

    _validandoDescuento = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      debugPrint('🎟️  Validando código de descuento: $codigo');
      debugPrint('   Subtotal: ${subtotal.toStringAsFixed(2)} Bs');

      // Simular delay de API (500ms)
      await Future.delayed(const Duration(milliseconds: 500));

      // Simulación de validación de códigos
      Map<String, Map<String, dynamic>> codigosValidos = {
        'PROMO10': {'porcentaje': 10, 'descripcion': '10% descuento'},
        'PROMO20': {'porcentaje': 20, 'descripcion': '20% descuento'},
        'GRATIS': {'monto': 50, 'descripcion': 'Bs 50 de descuento'},
        'REGALO50': {'monto': 50, 'descripcion': 'Bs 50 regalo'},
      };

      final codigoUpper = codigo.toUpperCase();

      if (!codigosValidos.containsKey(codigoUpper)) {
        _errorMessage = 'Código "$codigo" no es válido o ya expiró';
        _validandoDescuento = false;
        debugPrint('❌ Código inválido: $codigo');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return false;
      }

      final codigoData = codigosValidos[codigoUpper]!;

      // Calcular descuento
      if (codigoData.containsKey('porcentaje')) {
        final porcentaje = codigoData['porcentaje'] as int;
        _porcentajeDescuento = porcentaje.toDouble();
        _montoDescuento = (subtotal * porcentaje / 100);
        debugPrint('✅ Descuento porcentual aplicado: $porcentaje%');
        debugPrint('   Monto descuento: ${_montoDescuento.toStringAsFixed(2)} Bs');
      } else if (codigoData.containsKey('monto')) {
        _montoDescuento = (codigoData['monto'] as num).toDouble();
        _porcentajeDescuento = ((100 * _montoDescuento) / subtotal);
        debugPrint('✅ Descuento fijo aplicado: ${_montoDescuento.toStringAsFixed(2)} Bs');
      }

      _codigoDescuento = codigoUpper;
      _validandoDescuento = false;

      debugPrint('✅ Código "$codigoUpper" aplicado correctamente');
      debugPrint('📊 Total con descuento: ${totalConDescuento.toStringAsFixed(2)} Bs');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return true;
    } catch (e) {
      _errorMessage = 'Error al validar descuento: ${e.toString()}';
      _validandoDescuento = false;
      _codigoDescuento = null;

      debugPrint('❌ Error validando descuento: $e');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    }
  }

  // Remover código de descuento
  void removerDescuento() {
    _codigoDescuento = null;
    _porcentajeDescuento = 0;
    _montoDescuento = 0;

    debugPrint('🗑️  Descuento removido');
    debugPrint('📊 Nuevo total: ${total.toStringAsFixed(2)} Bs');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Verificar stock disponible antes de crear pedido
  Future<bool> verificarStock() async {
    if (_carrito.isEmpty) {
      _errorMessage = 'El carrito está vacío';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    }

    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      // Preparar items para verificación
      final itemsParaVerificar = _carrito.items
          .map(
            (item) => {
              'producto_id': item.producto.id,
              'cantidad': item.cantidad,
            },
          )
          .toList();

      // TODO: Implementar cuando el endpoint de verificación esté disponible
      // final response = await _productService.verificarStock(itemsParaVerificar);

      // Por ahora retornamos true
      debugPrint(
        'Verificando stock para ${itemsParaVerificar.length} productos...',
      );

      // Simulamos una verificación exitosa
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return true;
    } catch (e) {
      _errorMessage = 'Error al verificar stock: ${e.toString()}';
      _isLoading = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    }
  }

  // Limpiar mensaje de error
  void limpiarError() {
    _errorMessage = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Obtener items formateados para crear pedido
  List<Map<String, dynamic>> getItemsParaPedido() {
    return _carrito.toItemsForPedido();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE PERSISTENCIA - Guardar y Recuperar Carrito
  // ═══════════════════════════════════════════════════════════════════════════

  /// Guardar carrito en base de datos
  Future<bool> guardarCarrito() async {
    if (_usuarioId == null) {
      _errorMessage = 'Usuario no inicializado';
      debugPrint('❌ Error: Usuario no inicializado');
      return false;
    }

    if (isEmpty) {
      _errorMessage = 'No hay productos en el carrito para guardar';
      debugPrint('ℹ️  Carrito vacío, no se guarda');
      return false;
    }

    _guardandoCarrito = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      debugPrint('💾 Iniciando guardado de carrito...');
      final carritoGuardado = await _carritoService.guardarCarrito(
        _carrito,
        _usuarioId!,
      );

      if (carritoGuardado != null) {
        _carrito = carritoGuardado;
        _guardandoCarrito = false;
        debugPrint('✅ Carrito guardado exitosamente en BD');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return true;
      } else {
        _errorMessage = 'Error al guardar el carrito';
        _guardandoCarrito = false;
        debugPrint('❌ Error: No se pudo guardar el carrito');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error al guardar carrito: ${e.toString()}';
      _guardandoCarrito = false;

      debugPrint('❌ Excepción al guardar: $e');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    }
  }

  /// Recuperar último carrito guardado del usuario
  Future<bool> recuperarCarrito() async {
    if (_usuarioId == null) {
      _errorMessage = 'Usuario no inicializado';
      debugPrint('❌ Error: Usuario no inicializado');
      return false;
    }

    _recuperandoCarrito = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      debugPrint('📂 Recuperando carrito guardado...');
      final carritoRecuperado = await _carritoService.recuperarUltimoCarrito(_usuarioId!);

      if (carritoRecuperado != null) {
        _carrito = carritoRecuperado;
        _recuperandoCarrito = false;
        debugPrint('✅ Carrito recuperado exitosamente');
        debugPrint('   Items: ${_carrito.items.length}');
        debugPrint('   Subtotal: ${_carrito.subtotal.toStringAsFixed(2)} Bs');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return true;
      } else {
        _recuperandoCarrito = false;
        debugPrint('ℹ️  No hay carrito guardado para recuperar');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error al recuperar carrito: ${e.toString()}';
      _recuperandoCarrito = false;

      debugPrint('❌ Excepción al recuperar: $e');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    }
  }

  /// Convertir carrito a proforma (pedido cotizado)
  Future<Map<String, dynamic>?> convertirAProforma() async {
    if (_usuarioId == null) {
      _errorMessage = 'Usuario no inicializado';
      debugPrint('❌ Error: Usuario no inicializado');
      return null;
    }

    if (isEmpty) {
      _errorMessage = 'No hay productos en el carrito';
      debugPrint('❌ Error: Carrito vacío');
      return null;
    }

    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      debugPrint('📋 Convirtiendo carrito a proforma...');

      // Pasar los items al servicio
      final proforma = await _carritoService.convertirAProforma(
        _carrito.id ?? 0,
        _usuarioId!,
        _carrito.items,  // ← IMPORTANTE: Pasar los items
      );

      if (proforma != null) {
        // Actualizar estado del carrito si tiene ID
        if (_carrito.id != null) {
          await _carritoService.actualizarEstadoCarrito(
            _carrito.id!,
            'convertido',
          );
        }

        _carrito = _carrito.copyWith(estado: 'convertido');
        _isLoading = false;

        debugPrint('✅ Proforma creada: ${proforma['numero']}');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return proforma;
      } else {
        _errorMessage = 'Error al crear proforma';
        _isLoading = false;

        debugPrint('❌ Error: No se pudo crear proforma');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error al convertir a proforma: ${e.toString()}';
      _isLoading = false;

      debugPrint('❌ Excepción: $e');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return null;
    }
  }

  /// Auto-guardar carrito (llamar cuando usuario sale de la app)
  Future<void> autoGuardarCarrito() async {
    if (_usuarioId == null || isEmpty) {
      return;
    }

    debugPrint('⏱️  Auto-guardando carrito...');
    await guardarCarrito();
  }

  /// Obtener lista de carritos abandonados del usuario
  Future<List<Carrito>> obtenerCarritosAbandonados() async {
    if (_usuarioId == null) {
      debugPrint('❌ Error: Usuario no inicializado');
      return [];
    }

    try {
      debugPrint('📜 Obteniendo carritos abandonados para usuario $_usuarioId...');
      final carritos = await _carritoService.obtenerCarritosAbandonados(_usuarioId!);
      debugPrint('✅ ${carritos.length} carritos abandonados encontrados');
      return carritos;
    } catch (e) {
      debugPrint('❌ Error al obtener carritos abandonados: $e');
      return [];
    }
  }

  /// Recuperar un carrito específico del historial de abandonados
  Future<bool> recuperarCarritoAbandonado(Carrito carritoAbandonado) async {
    try {
      debugPrint('📂 Recuperando carrito abandonado ID: ${carritoAbandonado.id}...');

      // Limpiar carrito actual
      _carrito = Carrito(items: []);

      // Cargar items del carrito abandonado
      for (var item in carritoAbandonado.items) {
        _carrito.items.add(item);
      }

      // Actualizar estado del carrito
      if (carritoAbandonado.id != null) {
        await _carritoService.actualizarEstadoCarrito(
          carritoAbandonado.id!,
          'activo',
        );
      }

      // Recalcular totales
      _calcularTotales();

      debugPrint('✅ Carrito abandonado recuperado exitosamente');
      debugPrint('   Items: ${_carrito.items.length}');
      debugPrint('   Subtotal: ${_carrito.subtotal.toStringAsFixed(2)} Bs');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      return true;
    } catch (e) {
      _errorMessage = 'Error al recuperar carrito: ${e.toString()}';
      debugPrint('❌ Error: $e');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      return false;
    }
  }

  /// Eliminar un carrito del historial
  Future<bool> eliminarCarritoAbandonado(int carritoId) async {
    try {
      debugPrint('🗑️  Eliminando carrito abandonado ID: $carritoId...');
      final success = await _carritoService.eliminarCarrito(carritoId);

      if (success) {
        debugPrint('✅ Carrito eliminado correctamente');
      } else {
        debugPrint('❌ No se pudo eliminar el carrito');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error al eliminar: $e');
      return false;
    }
  }

  /// Obtener días desde que se abandonó un carrito
  int obtenerDiasAbandonado(Carrito carrito) {
    if (carrito.fechaAbandono == null) {
      return 0;
    }

    return DateTime.now()
        .difference(carrito.fechaAbandono!)
        .inDays;
  }

  /// Verificar si un carrito está por expirar (< 3 días antes del límite de 30)
  bool debeAlertarExpiracion(Carrito carrito) {
    if (carrito.estado != 'guardado' || carrito.fechaAbandono == null) {
      return false;
    }

    final diasAbandonado = obtenerDiasAbandonado(carrito);
    return diasAbandonado >= 27; // 30 - 3
  }

  /// Renovar carrito abandonado (reseta la fecha de abandono)
  Future<bool> renovarCarritoAbandonado(int carritoId) async {
    try {
      debugPrint('🔄 Renovando carrito ID: $carritoId...');

      // En una implementación real, llamaría al backend
      // Para ahora, simplemente confirmar en logs

      debugPrint('✅ Carrito renovado - nueva fecha de expiración en 30 días');
      return true;
    } catch (e) {
      debugPrint('❌ Error al renovar: $e');
      return false;
    }
  }

  /// Ayuda privada para recalcular totales
  void _calcularTotales() {
    // Esto se puede mejorar, pero por ahora es suficiente
    // El cálculo real se hace en los getters de _carrito
  }
}

