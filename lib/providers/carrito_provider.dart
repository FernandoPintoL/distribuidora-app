import 'dart:async';
import 'package:flutter/widgets.dart';
import '../models/carrito.dart';
import '../models/carrito_item.dart';
import '../models/carrito_con_rangos.dart';
import '../models/detalle_carrito_con_rango.dart';
import '../models/product.dart';
import '../models/client.dart'; // ✅ NUEVO: Importar Client
import '../models/pedido.dart'; // ✅ NUEVO: Importar Pedido para editar proformas
import '../services/carrito_service.dart';
import '../services/api_service.dart';
import '../services/proforma_service.dart'; // ✅ NUEVO: Para actualizar proformas
import '../services/product_service.dart'; // ✅ NUEVO: Para obtener stocks actualizados

class CarritoProvider with ChangeNotifier {
  Carrito _carrito = Carrito(items: []);
  bool _isLoading = false;
  String? _errorMessage;
  double _costoEnvio = 0;
  String? _direccionId;
  bool _calculandoEnvio = false;

  // ✅ NUEVO: Cliente seleccionado para pedidos del preventista
  Client? _clienteSeleccionado;

  // ✅ NUEVO: Proforma siendo editada (null si es creación nueva)
  Pedido? _proformaEditando;

  // Descuentos
  String? _codigoDescuento;
  double _porcentajeDescuento = 0;
  double _montoDescuento = 0;
  bool _validandoDescuento = false;

  // Persistencia
  late CarritoService _carritoService;
  late ProformaService _proformaService; // ✅ NUEVO: Para actualizar proformas
  late ProductService _productService; // ✅ NUEVO: Para obtener stocks actualizados
  bool _guardandoCarrito = false;
  bool _recuperandoCarrito = false;
  int? _usuarioId;

  // Rangos de precio
  CarritoConRangos? _carritoConRangos;
  bool _calculandoRangos = false;
  Map<int, DetalleCarritoConRango> _detallesConRango = {};

  // 🔑 FASE 3: Debounce para cálculo de rangos
  Timer? _detalleDebounce;
  static const Duration _detalleDebounceDelay = Duration(milliseconds: 500);

  CarritoProvider() {
    _carritoService = CarritoService(ApiService());
    _proformaService = ProformaService(); // ✅ NUEVO: Inicializar servicio de proformas
    _productService = ProductService(); // ✅ NUEVO: Inicializar servicio de productos
  }

  @override
  void dispose() {
    // 🔑 Cancelar debounce si existe
    _detalleDebounce?.cancel();
    super.dispose();
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
  double get totalConEnvio => subtotal + _costoEnvio;

  // Descuentos getters
  String? get codigoDescuento => _codigoDescuento;
  double get porcentajeDescuento => _porcentajeDescuento;
  double get montoDescuento => _montoDescuento;
  bool get tieneDescuento => _montoDescuento > 0;
  bool get validandoDescuento => _validandoDescuento;

  // ✅ NUEVO: Cliente seleccionado getters y setter
  Client? get clienteSeleccionado => _clienteSeleccionado;
  bool get tieneClienteSeleccionado => _clienteSeleccionado != null;

  /// ✅ NUEVO: Establecer cliente seleccionado
  void setClienteSeleccionado(Client? cliente) {
    _clienteSeleccionado = cliente;
    debugPrint('👤 [CarritoProvider] Cliente seleccionado: ${cliente?.nombre}');
    notifyListeners();
  }

  getClienteSeleccionado() {
    return _clienteSeleccionado;
  }

  getClienteSeleccionadoId() {
    return _clienteSeleccionado?.id;
  }

  /// ✅ NUEVO: Limpiar cliente seleccionado
  void limpiarClienteSeleccionado() {
    _clienteSeleccionado = null;
    debugPrint('👤 [CarritoProvider] Cliente seleccionado limpiado');
    notifyListeners();
  }

  // ✅ NUEVO: Getters para proforma siendo editada
  Pedido? get proformaEditando => _proformaEditando;
  bool get editandoProforma => _proformaEditando != null;
  int? get proformaEditandoId => _proformaEditando?.id;

  /// ✅ NUEVO: Cargar una proforma pendiente en el carrito para editar (CON STOCKS ACTUALIZADOS)
  ///
  /// Este método:
  /// 1. Limpia el carrito actual
  /// 2. Carga datos del cliente
  /// 3. OBTIENE STOCKS ACTUALIZADOS de cada producto
  /// 4. Agrega todos los items al carrito con stocks correctos
  /// 5. Guarda la referencia a la proforma para actualizar después
  ///
  /// Parámetros:
  /// - proforma: La proforma a editar (debe estar en estado PENDIENTE)
  ///
  /// Retorna: Future<bool> - true si se cargó exitosamente
  Future<bool> cargarProformaEnCarrito(Pedido proforma) async {
    if (proforma.estadoCodigo != 'PENDIENTE') {
      _errorMessage = 'Solo se pueden editar proformas pendientes';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _proformaEditando = proforma;
      limpiarCarrito();

      // ✅ NUEVO: Establecer el cliente de la proforma
      if (proforma.cliente != null) {
        setClienteSeleccionado(proforma.cliente);
      }

      // ✅ NUEVO: Obtener datos actualizados de cada producto (INCLUYENDO STOCKS)
      debugPrint('📦 Obteniendo datos actualizados de ${proforma.items.length} productos...');

      for (final item in proforma.items) {
        if (item.producto != null) {
          // Obtener producto actualizado del servidor (con stock correcto)
          final response = await _productService.getProduct(item.producto!.id);

          Product productoActualizado = item.producto!;

          if (response.success && response.data != null) {
            productoActualizado = response.data!;
            debugPrint('✅ Stock obtenido para ${productoActualizado.nombre}: ${productoActualizado.stockPrincipal?.cantidad}');
          } else {
            debugPrint('⚠️ No se pudo obtener stock para ${item.producto!.nombre}, usando datos de proforma');
          }

          // Agregar al carrito con producto actualizado
          final carritoItem = CarritoItem(
            producto: productoActualizado,
            cantidad: item.cantidad,
            observaciones: item.observaciones ?? '',
          );

          final index = _carrito.items.indexWhere(
            (i) => i.producto.id == productoActualizado.id,
          );

          if (index != -1) {
            _carrito.items[index] = _carrito.items[index].copyWith(
              cantidad: _carrito.items[index].cantidad + item.cantidad,
            );
          } else {
            _carrito.items.add(carritoItem);
          }
        }
      }

      _calcularTotales();
      _isLoading = false;
      debugPrint('📦 [CarritoProvider] Proforma #${proforma.numero} cargada con stocks actualizados (${proforma.items.length} productos)');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al cargar proforma: ${e.toString()}';
      _isLoading = false;
      debugPrint('❌ Error: $e');
      notifyListeners();
      return false;
    }
  }

  /// ✅ NUEVO: Limpiar proforma siendo editada (al cancelar edición)
  void limpiarProformaEditando() {
    _proformaEditando = null;
    debugPrint('📦 [CarritoProvider] Edición de proforma cancelada');
    notifyListeners();
  }

  // Total con descuento (sin impuesto)
  double get subtotalConDescuento => subtotal - _montoDescuento;
  double get totalConDescuento => subtotalConDescuento + _costoEnvio;

  // Rangos getters
  CarritoConRangos? get carritoConRangos => _carritoConRangos;
  bool get calculandoRangos => _calculandoRangos;
  Map<int, DetalleCarritoConRango> get detallesConRango => _detallesConRango;

  /// Obtener detalle con rango de un producto específico
  DetalleCarritoConRango? obtenerDetalleConRango(int productoId) {
    return _detallesConRango[productoId];
  }

  /// 🔑 NUEVO: Obtener cantidad de un producto en el carrito
  /// Utilizado en ProductGridItem para sincronizar cantidad
  int obtenerCantidadProducto(int productoId) {
    try {
      final item = _carrito.items.firstWhere(
        (item) => item.producto.id == productoId,
      );
      return item.cantidad;
    } catch (e) {
      return 0;
    }
  }

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
    int cantidad = 1,
    String? observaciones,
    List<Map<String, dynamic>>? comboItemsSeleccionados,
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
    final cantidadMinima = producto.cantidadMinima ?? 1;
    if (cantidad < cantidadMinima) {
      final unidad = producto.unidadMedida?.nombre ?? 'unidades';
      _errorMessage =
          'Cantidad mínima: $cantidadMinima $unidad (solicitaste: $cantidad)';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      debugPrint(
        '❌ Error: Cantidad mínima no cumplida para ${producto.nombre}',
      );
      return;
    }

    // Validar stock disponible
    final stockDisponible = producto.stockPrincipal?.cantidadDisponible ?? 0;
    final stockDispInt = (stockDisponible as num).toInt();

    if (cantidad > stockDispInt) {
      _errorMessage =
          'Stock insuficiente. Disponible: $stockDispInt ${producto.unidadMedida?.nombre ?? 'unidades'}';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      debugPrint(
        '❌ Error al agregar $cantidad de ${producto.nombre}: $_errorMessage',
      );
      return;
    }

    List<CarritoItem> nuevosItems = List.from(_carrito.items);

    // ✅ NUEVO: Buscar item existente considerando también comboItemsSeleccionados
    // Para combos: buscar item con MISMO producto ID + MISMOS combo items seleccionados
    CarritoItem? itemExistente;
    try {
      itemExistente = nuevosItems.firstWhere((item) {
      if (item.producto.id != producto.id) return false;

      // Para combos, comparar también los items seleccionados
      if (producto.esCombo) {
        // Si ambos son null o ambos tienen los mismos items
        if (item.comboItemsSeleccionados == null && comboItemsSeleccionados == null) {
          return true;
        }
        if (item.comboItemsSeleccionados == null || comboItemsSeleccionados == null) {
          return false;
        }
        // Comparar si tienen los mismos combo_item_ids
        if (item.comboItemsSeleccionados!.length != comboItemsSeleccionados!.length) {
          return false;
        }
        for (int i = 0; i < item.comboItemsSeleccionados!.length; i++) {
          if (item.comboItemsSeleccionados![i]['combo_item_id'] !=
              comboItemsSeleccionados![i]['combo_item_id']) {
            return false;
          }
        }
        return true;
      }

      // Para productos normales, solo comparar producto.id
      return true;
      });
    } catch (e) {
      itemExistente = null;
    }

    if (itemExistente != null) {
      // Si ya existe, validar que la nueva cantidad total no exceda el stock
      final nuevaCantidadTotal = itemExistente.cantidad + cantidad;
      if (nuevaCantidadTotal > stockDispInt) {
        _errorMessage =
            'Cantidad total excede el stock disponible. Máximo disponible: $stockDispInt, actualmente en carrito: ${itemExistente.cantidad}';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        debugPrint(
          '❌ Error al agregar más de ${producto.nombre}: $_errorMessage',
        );
        return;
      }

      // Si pasa la validación, actualizar la cantidad
      final index = nuevosItems.indexWhere((item) => item == itemExistente);
      // ✅ NUEVO: Actualizar también comboItemsSeleccionados si existen
      nuevosItems[index] = itemExistente.copyWith(
        cantidad: nuevaCantidadTotal,
        comboItemsSeleccionados: comboItemsSeleccionados ?? itemExistente.comboItemsSeleccionados,
      );
      debugPrint(
        '✅ Cantidad de ${producto.nombre} aumentada a $nuevaCantidadTotal',
      );
    } else {
      // Si no existe, agregarlo
      nuevosItems.add(
        CarritoItem(
          producto: producto,
          cantidad: cantidad,
          observaciones: observaciones,
          comboItemsSeleccionados: comboItemsSeleccionados,
        ),
      );
      debugPrint(
        '✅ ${producto.nombre} agregado al carrito con cantidad: $cantidad',
      );
      if (comboItemsSeleccionados != null) {
        debugPrint('   📦 Combo items guardados: $comboItemsSeleccionados');
      } else {
        debugPrint('   ⚠️ SIN combo items seleccionados');
      }

      // ✅ DEBUG: Mostrar item guardado en carrito
      final itemGuardado = nuevosItems.lastWhere(
        (i) => i.producto.id == producto.id,
      );
      debugPrint('   🔍 Item en carrito - comboItemsSeleccionados: ${itemGuardado.comboItemsSeleccionados}');
    }

    _carrito = _carrito.copyWith(items: nuevosItems);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Actualizar cantidad de un producto con validación de stock
  void actualizarCantidad(int productoId, int nuevaCantidad) {
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
    final stockDispInt = (stockDisponible as num).toInt();

    if (nuevaCantidad > stockDispInt) {
      _errorMessage =
          'Cantidad excede el stock disponible. Máximo: $stockDispInt ${producto.unidadMedida?.nombre ?? 'unidades'}';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      debugPrint(
        '❌ Error al actualizar ${producto.nombre} a $nuevaCantidad: $_errorMessage',
      );
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
  void incrementarCantidad(int productoId, {int incremento = 1}) {
    _errorMessage = null;

    final itemExistente = _carrito.getItemByProductoId(productoId);
    if (itemExistente == null) return;

    final producto = itemExistente.producto;
    final stockDisponible = producto.stockPrincipal?.cantidadDisponible ?? 0;
    final stockDispInt = (stockDisponible as num).toInt();
    final nuevaCantidadTotal = itemExistente.cantidad + incremento;

    // ✅ VALIDAR LÍMITE DE VENTA
    if (producto.limiteVenta != null && nuevaCantidadTotal > producto.limiteVenta!) {
      _errorMessage = 'El producto "${producto.nombre}" tiene un límite máximo de venta de ${producto.limiteVenta} unidades.';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      debugPrint('⛔ Límite de venta excedido: $_errorMessage');
      return;
    }

    // ✅ VALIDAR STOCK
    if (nuevaCantidadTotal > stockDispInt) {
      _errorMessage =
          'No hay stock suficiente para agregar más. Disponible: $stockDispInt, en carrito: ${itemExistente.cantidad}';
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
  void decrementarCantidad(int productoId, {int decremento = 1}) {
    final itemExistente = _carrito.getItemByProductoId(productoId);
    if (itemExistente == null) return;

    final producto = itemExistente.producto;
    final nuevaCantidad = itemExistente.cantidad - decremento;

    if (nuevaCantidad <= 0) {
      debugPrint('🗑️ Eliminando ${producto.nombre} del carrito');
      eliminarProducto(productoId);
    } else {
      debugPrint(
        '⬇️ Decrementando ${producto.nombre} por $decremento unidades',
      );
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

  /// ✅ NUEVO: Actualizar items opcionales de un combo existente en el carrito
  void actualizarComboItems(
    int productoId,
    List<Map<String, dynamic>>? comboItemsSeleccionados,
  ) {
    final itemExistente = _carrito.getItemByProductoId(productoId);
    if (itemExistente == null) {
      debugPrint('⚠️ Item no encontrado en carrito: $productoId');
      return;
    }

    List<CarritoItem> nuevosItems = List.from(_carrito.items);
    final index = nuevosItems.indexWhere(
      (item) => item.producto.id == productoId,
    );

    nuevosItems[index] = itemExistente.copyWith(
      comboItemsSeleccionados: comboItemsSeleccionados,
    );

    _carrito = _carrito.copyWith(items: nuevosItems);

    debugPrint('✅ Items opcionales del combo actualizados');
    if (comboItemsSeleccionados != null) {
      debugPrint('   📦 Nuevos combo items: $comboItemsSeleccionados');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Limpiar carrito
  void limpiarCarrito() {
    debugPrint(
      '🗑️ Carrito limpiado (${_carrito.items.length} productos eliminados)',
    );
    _carrito = Carrito(items: []);
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Verificar si hay stock suficiente para un producto antes de operaciones
  bool tieneStockDisponible(int productoId, int cantidadSolicitada) {
    final item = _carrito.getItemByProductoId(productoId);
    if (item == null) return false;

    final stockDisponible =
        item.producto.stockPrincipal?.cantidadDisponible ?? 0;
    final stockDispInt = (stockDisponible as num).toInt();

    return cantidadSolicitada <= stockDispInt;
  }

  // Obtener la cantidad máxima disponible de un producto
  int obtenerMaximaDisponible(int productoId) {
    final item = _carrito.getItemByProductoId(productoId);
    if (item == null) return 0;

    final stockDisponible =
        item.producto.stockPrincipal?.cantidadDisponible ?? 0;
    return (stockDisponible as num).toInt();
  }

  // Verificar si un producto está en el carrito
  bool tieneProducto(int productoId) {
    return _carrito.tieneProducto(productoId);
  }

  // Obtener cantidad de un producto en el carrito
  int getCantidadProducto(int productoId) {
    final item = _carrito.getItemByProductoId(productoId);
    return item?.cantidad ?? 0;
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
        debugPrint(
          '✅ Descuento en envío aplicado (>Bs200): ${(_costoEnvio).toStringAsFixed(2)} Bs',
        );
      }

      debugPrint(
        '✅ Costo de envío calculado: ${_costoEnvio.toStringAsFixed(2)} Bs',
      );
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
        debugPrint(
          '   Monto descuento: ${_montoDescuento.toStringAsFixed(2)} Bs',
        );
      } else if (codigoData.containsKey('monto')) {
        _montoDescuento = (codigoData['monto'] as num).toDouble();
        _porcentajeDescuento = ((100 * _montoDescuento) / subtotal);
        debugPrint(
          '✅ Descuento fijo aplicado: ${_montoDescuento.toStringAsFixed(2)} Bs',
        );
      }

      _codigoDescuento = codigoUpper;
      _validandoDescuento = false;

      debugPrint('✅ Código "$codigoUpper" aplicado correctamente');
      debugPrint(
        '📊 Total con descuento: ${totalConDescuento.toStringAsFixed(2)} Bs',
      );

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
      final carritoRecuperado = await _carritoService.recuperarUltimoCarrito(
        _usuarioId!,
      );

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
        _carrito.items, // ← IMPORTANTE: Pasar los items
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

  /// ✅ NUEVO: Guardar o actualizar proforma (detecta automáticamente)
  ///
  /// Si se está editando una proforma pendiente:
  /// - Actualiza la proforma existente con los nuevos items
  ///
  /// Si es creación nueva:
  /// - Crea una nueva proforma
  ///
  /// Retorna:
  /// - Map con la proforma guardada/actualizada (ej: {'numero': '001', 'id': 123})
  /// - null si hay error
  Future<Map<String, dynamic>?> guardarProformaOActualizar() async {
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

    if (!tieneClienteSeleccionado) {
      _errorMessage = 'No hay cliente seleccionado';
      debugPrint('❌ Error: Cliente no seleccionado');
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // ✅ NUEVO: Si se está editando una proforma, actualizar en lugar de crear
      if (editandoProforma && _proformaEditando != null) {
        debugPrint('📝 Actualizando proforma #${_proformaEditando!.numero}');

        // Convertir items del carrito al formato esperado por la API
        final itemsData = _carrito.items
            .map((item) => {
                  'producto_id': item.producto.id,
                  'cantidad': item.cantidad,
                  'precio_unitario': item.producto.precioVenta,
                  'observaciones': item.observaciones,
                })
            .toList();

        final response = await _proformaService.actualizarProforma(
          proformaId: _proformaEditando!.id,
          clienteId: _clienteSeleccionado!.id,
          items: itemsData,
          observaciones: null,
        );

        if (response.success && response.data != null) {
          debugPrint('✅ Proforma actualizada: ${response.data!.numero}');

          // Limpiar estado de edición
          limpiarProformaEditando();
          limpiarCarrito();

          _isLoading = false;
          notifyListeners();

          return {
            'numero': response.data!.numero,
            'id': response.data!.id,
            'estado': response.data!.estadoCodigo,
          };
        } else {
          _errorMessage = response.message;
          _isLoading = false;
          notifyListeners();
          return null;
        }
      } else {
        // ✅ ORIGINAL: Crear nueva proforma
        debugPrint('📋 Creando nueva proforma');
        return await convertirAProforma();
      }
    } catch (e) {
      _errorMessage = 'Error al guardar proforma: ${e.toString()}';
      _isLoading = false;
      debugPrint('❌ Error: $e');
      notifyListeners();
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
      debugPrint(
        '📜 Obteniendo carritos abandonados para usuario $_usuarioId...',
      );
      final carritos = await _carritoService.obtenerCarritosAbandonados(
        _usuarioId!,
      );
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
      debugPrint(
        '📂 Recuperando carrito abandonado ID: ${carritoAbandonado.id}...',
      );

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

    return DateTime.now().difference(carrito.fechaAbandono!).inDays;
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

  /// 🔑 FASE 3: Calcular carrito CON DEBOUNCE
  ///
  /// Implementa debounce para evitar múltiples llamadas API:
  /// - Si se llama múltiples veces rápidamente (ej: incrementar cantidad 5 veces)
  /// - Solo hace 1 llamada API después de 500ms sin cambios
  /// - Cancela el timer anterior si existe
  ///
  /// Ejemplo:
  /// ```
  /// incrementarCantidad(prod_id);           // Timer inicia
  /// incrementarCantidad(prod_id);           // Timer se cancela y reinicia
  /// incrementarCantidad(prod_id);           // Timer se cancela y reinicia
  /// // (después de 500ms sin cambios)
  /// // → Realiza UN SOLO llamado API ✨
  /// ```
  Future<bool> calcularCarritoConRangos({Duration? delay}) async {
    // Cancelar timer anterior si existe
    _detalleDebounce?.cancel();

    // Usar delay personalizado o default
    final finalDelay = delay ?? _detalleDebounceDelay;

    debugPrint(
      '⏱️  Debounce iniciado: esperando ${finalDelay.inMilliseconds}ms...',
    );

    // Crear nuevo timer
    _detalleDebounce = Timer(finalDelay, () {
      debugPrint('⏱️  Debounce completado - ejecutando cálculo...');
      _ejecutarCalculoRangos();
    });

    return true;
  }

  /// Ejecutar el cálculo real (sin debounce)
  /// Llamado después del debounce delay
  Future<bool> _ejecutarCalculoRangos() async {
    try {
      _calculandoRangos = true;
      notifyListeners();

      debugPrint('🔄 Calculando carrito con rangos de precio...');

      final carritoConRangos = await _carritoService.calcularCarritoConRangos(
        _carrito.items,
      );

      if (carritoConRangos != null) {
        _carritoConRangos = carritoConRangos;

        // Mapear detalles por ID de producto para acceso rápido
        _detallesConRango.clear();
        for (final detalle in carritoConRangos.detalles) {
          _detallesConRango[detalle.productoId] = detalle;
        }

        debugPrint('✅ Carrito calculado con éxito');
        debugPrint(
          '   Ahorro disponible: ${carritoConRangos.ahorroDisponible.toStringAsFixed(2)} Bs',
        );
        debugPrint('   Items con rango: ${carritoConRangos.detalles.length}');

        _errorMessage = null; // Limpiar error anterior si el cálculo fue exitoso
        notifyListeners();
        return true;
      }

      // ✅ Usar el mensaje de error del servicio (incluye límite de venta)
      _errorMessage = _carritoService.lastErrorMessage ?? 'No fue posible calcular los precios con rangos';
      debugPrint('⚠️  Error en cálculo de carrito: $_errorMessage');

      // ✅ DETECTAR Y MANEJAR LÍMITE DE VENTA
      if (_errorMessage!.contains('límite máximo de venta')) {
        _revertirCantidadPorLimiteVenta(_errorMessage!);
      }

      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ Error al calcular carrito con rangos: $e');
      _errorMessage = 'Error al calcular precios: $e';
      notifyListeners();
      return false;
    } finally {
      _calculandoRangos = false;
      notifyListeners();
    }
  }

  /// Revertir cantidad de un producto cuando se excede el límite de venta
  void _revertirCantidadPorLimiteVenta(String mensajeError) {
    try {
      // Extraer el límite del mensaje: "...límite máximo de venta de X unidades..."
      final regexLimit = RegExp(r'límite máximo de venta de (\d+) unidades');
      final matchLimit = regexLimit.firstMatch(mensajeError);

      if (matchLimit != null) {
        final limiteMax = int.parse(matchLimit.group(1)!);

        // Encontrar cuál producto excede el límite
        for (final item in _carrito.items) {
          if (item.cantidad > limiteMax && item.producto.limiteVenta == limiteMax) {
            debugPrint('🔄 Revirtiendo cantidad de "${item.producto.nombre}" a $limiteMax');
            actualizarCantidad(item.producto.id, limiteMax);
            _errorMessage = 'Cantidad revertida al límite máximo: $limiteMax unidades';
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error al revertir cantidad: $e');
    }
  }

  /// Calcular carrito INMEDIATAMENTE (sin debounce)
  /// Útil para cuando necesitas el resultado ahora mismo
  /// (ej: al finalizar la compra)
  Future<bool> calcularCarritoConRangosAhora() async {
    _detalleDebounce?.cancel(); // Cancelar debounce si hay uno pendiente
    return _ejecutarCalculoRangos();
  }

  /// Agregar cantidad a un producto para alcanzar el próximo rango
  /// Valida stock y actualiza la cantidad
  void agregarParaAhorrar(int productoId, int cantidadAgregar) {
    try {
      final detalle = obtenerDetalleConRango(productoId);
      if (detalle == null) {
        debugPrint(
          '❌ No hay información de rango para el producto $productoId',
        );
        return;
      }

      final item = _carrito.getItemByProductoId(productoId);
      if (item == null) {
        debugPrint('❌ El producto $productoId no está en el carrito');
        return;
      }

      final nuevaCantidad = item.cantidad + cantidadAgregar;

      // Validar stock
      final stockDisponible = item.cantidadDisponible;
      if (nuevaCantidad > stockDisponible) {
        _errorMessage =
            'Stock insuficiente. Disponible: ${stockDisponible.toStringAsFixed(1)}';
        notifyListeners();
        return;
      }

      // Actualizar cantidad
      actualizarCantidad(productoId, nuevaCantidad);

      // Recalcular con rangos
      calcularCarritoConRangos();
    } catch (e) {
      debugPrint('❌ Error al agregar para ahorrar: $e');
      _errorMessage = 'Error al actualizar cantidad: $e';
      notifyListeners();
    }
  }
}
