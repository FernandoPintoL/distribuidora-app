import 'package:flutter/foundation.dart';

class Product {
  final int id;
  final String nombre;
  final String codigo;
  final String? sku;
  final String? descripcion;
  final Category? categoria;
  final Brand? marca;
  final Supplier? proveedor;
  final UnitMeasure? unidadMedida;
  final bool activo;
  final double? precioCompra;
  final double? precioVenta;
  final int? stockMinimo;
  final int? stockMaximo;
  final int? cantidadMinima;
  final int? limiteVenta;
  final List<ProductImage>? imagenes;
  final List<String>? codigosBarra;
  final StockWarehouse? stockPrincipal;
  final List<StockWarehouse>? stockPorAlmacenes;
  final List<Precio>? precios;  // ✅ NUEVO: Array de precios

  // ✅ CAMPOS PARA COMBOS
  final bool esCombo;
  final List<ComboItem>? comboItems;
  final List<ComboGrupo>? comboGrupos;
  final int? capacidad;

  // ✅ CAMPOS DE PRECIOS RECOMENDADOS
  final int? tipoPrecioIdRecomendado;
  final String? tipoPrecioNombreRecomendado;

  Product({
    required this.id,
    required this.nombre,
    required this.codigo,
    this.sku,
    this.descripcion,
    this.categoria,
    this.marca,
    this.proveedor,
    this.unidadMedida,
    required this.activo,
    this.precioCompra,
    this.precioVenta,
    this.stockMinimo,
    this.stockMaximo,
    this.cantidadMinima,
    this.limiteVenta,
    this.imagenes,
    this.codigosBarra,
    this.stockPrincipal,
    this.stockPorAlmacenes,
    this.precios,  // ✅ NUEVO: Parámetro de precios
    this.esCombo = false,  // ✅ NUEVO: Es combo
    this.comboItems,  // ✅ NUEVO: Items del combo
    this.comboGrupos,  // ✅ NUEVO: Grupos opcionales
    this.capacidad,  // ✅ NUEVO: Capacidad de combos
    this.tipoPrecioIdRecomendado,  // ✅ NUEVO: ID del tipo de precio recomendado
    this.tipoPrecioNombreRecomendado,  // ✅ NUEVO: Nombre del tipo de precio recomendado
  });

  /// Obtener la imagen principal (es_principal == true) o la primera imagen
  ProductImage? get imagenPrincipal {
    if (imagenes == null || imagenes!.isEmpty) return null;
    // Buscar la imagen principal
    try {
      return imagenes!.firstWhere((img) => img.esPrincipal == true);
    } catch (e) {
      // Si no hay imagen principal, retornar la primera
      return imagenes!.isNotEmpty ? imagenes!.first : null;
    }
  }

  /// Obtener cantidad total de stock (desde stockPrincipal)
  num get cantidadStock {
    return stockPrincipal?.cantidad ?? 0;
  }

  /// Obtener cantidad disponible (no reservada)
  num get cantidadDisponible {
    return stockPrincipal?.cantidadDisponible ?? 0;
  }

  /// Obtener cantidad reservada
  num get cantidadReservada {
    return stockPrincipal?.cantidadReservada ?? 0;
  }

  /// Verificar si hay stock disponible
  bool get tieneStock {
    return cantidadDisponible > 0;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      final product = Product(
        id: json['id'],
        nombre: json['nombre'],
        // Backend sends 'sku', not 'codigo'
        codigo: json['sku'] ?? json['codigo'] ?? '',
        sku: json['sku'],
        descripcion: json['descripcion'],
        categoria: json['categoria'] != null
            ? (json['categoria'] is Map
                ? Category.fromJson(json['categoria'])
                : Category(id: json['categoria_id'] ?? 0, nombre: json['categoria'].toString()))
            : null,
        marca: json['marca'] != null
            ? (json['marca'] is Map
                ? Brand.fromJson(json['marca'])
                : Brand(id: json['marca_id'] ?? 0, nombre: json['marca'].toString()))
            : null,
        proveedor: json['proveedor'] != null
            ? (json['proveedor'] is Map
                ? Supplier.fromJson(json['proveedor'])
                : Supplier(id: json['proveedor_id'] ?? 0, nombre: json['proveedor'].toString()))
            : null,
        // Backend sends 'unidad', not 'unidad_medida'
        unidadMedida: json['unidad'] != null
            ? UnitMeasure.fromJson(json['unidad'])
            : (json['unidad_medida'] != null
                  ? UnitMeasure.fromJson(json['unidad_medida'])
                  : null),
        activo: json['activo'] ?? true,
        precioCompra: _parseDouble(json['precio_compra']),
        // Map both 'precio_venta' and 'precio' (from list endpoint)
        precioVenta: _parseDouble(json['precio_venta'] ?? json['precio']),
        stockMinimo: json['stock_minimo'],
        stockMaximo: json['stock_maximo'],
        cantidadMinima: json['cantidad_minima'],
        limiteVenta: json['limite_venta'],
        imagenes: json['imagenes'] != null
            ? (json['imagenes'] as List)
                  .map((i) => ProductImage.fromJson(i))
                  .toList()
            : null,
        codigosBarra:
            json['codigos_barra'] != null && json['codigos_barra'] is List
            ? List<String>.from(json['codigos_barra'])
            : null,
        // Map stock_principal or create one from root-level stock fields
        stockPrincipal: json['stock_principal'] != null
            ? StockWarehouse.fromJson(json['stock_principal'])
            : (json['stock'] != null || json['stock_disponible'] != null || json['cantidad_disponible'] != null
                  ? StockWarehouse(
                      almacenId: 3, // Default to almacén 3 (main warehouse)
                      almacenNombre: 'Principal',
                      cantidad: (json['stock'] ?? json['cantidad_disponible'] as num?)?.toInt() ?? 0,
                      cantidadDisponible: json['stock_disponible'] ?? json['cantidad_disponible'],
                      cantidadReservada: json['stock_reservado'],
                    )
                  : null),
        stockPorAlmacenes: json['stock_por_almacenes'] != null
            ? (json['stock_por_almacenes'] as List)
                  .map((i) => StockWarehouse.fromJson(i))
                  .toList()
            : null,
        precios: json['precios'] != null
            ? (json['precios'] as List)
                  .map((i) => Precio.fromJson(i))
                  .toList()
            : null,
        // ✅ NUEVO: Campos de combos
        esCombo: json['es_combo'] ?? false,
        comboItems: json['combo_items'] != null
            ? (json['combo_items'] as List)
                  .map((i) => ComboItem.fromJson(i))
                  .toList()
            : null,
        comboGrupos: json['combo_grupos'] != null
            ? (json['combo_grupos'] as List)
                  .map((i) => ComboGrupo.fromJson(i))
                  .toList()
            : null,
        capacidad: json['capacidad'],
        // ✅ NUEVO: Campos de precios recomendados
        tipoPrecioIdRecomendado: json['tipo_precio_id_recomendado'],
        tipoPrecioNombreRecomendado: json['tipo_precio_nombre_recomendado'],
      );

      // debugPrint('✅ Product.fromJson - ${product.nombre} (stock: ${product.stockPrincipal?.cantidad})');
      return product;
    } catch (e) {
      debugPrint('❌ Error parsing Product.fromJson: $e');
      debugPrint('   JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'codigo': codigo,
      'descripcion': descripcion,
      'categoria': categoria?.toJson(),
      'marca': marca?.toJson(),
      'proveedor': proveedor?.toJson(),
      'unidad_medida': unidadMedida?.toJson(),
      'activo': activo,
      'precio_compra': precioCompra,
      'precio_venta': precioVenta,
      'stock_minimo': stockMinimo,
      'stock_maximo': stockMaximo,
      'cantidad_minima': cantidadMinima,
      'limite_venta': limiteVenta,
      'imagenes': imagenes?.map((i) => i.toJson()).toList(),
      'codigos_barra': codigosBarra,
      'precios': precios?.map((p) => p.toJson()).toList(),
      'tipo_precio_id_recomendado': tipoPrecioIdRecomendado,
      'tipo_precio_nombre_recomendado': tipoPrecioNombreRecomendado,
    };
  }

  /// Helper para parsear doubles desde JSON (pueden venir como string o num)
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    if (value is num) return value.toDouble();
    return null;
  }
}

class Category {
  final int id;
  final String nombre;

  Category({required this.id, required this.nombre});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(id: json['id'], nombre: json['nombre']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nombre': nombre};
  }
}

class Brand {
  final int id;
  final String nombre;

  Brand({required this.id, required this.nombre});

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(id: json['id'], nombre: json['nombre']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nombre': nombre};
  }
}

class Supplier {
  final int id;
  final String nombre;
  final String? razonSocial;

  Supplier({required this.id, required this.nombre, this.razonSocial});

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'],
      nombre: json['nombre'],
      razonSocial: json['razon_social'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nombre': nombre, 'razon_social': razonSocial};
  }
}

class UnitMeasure {
  final int id;
  final String nombre;

  UnitMeasure({required this.id, required this.nombre});

  factory UnitMeasure.fromJson(Map<String, dynamic> json) {
    return UnitMeasure(id: json['id'], nombre: json['nombre']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nombre': nombre};
  }
}

class ProductImage {
  final int id;
  final int productoId;
  final String _url; // Almacenar URL sin procesar
  final bool esPrincipal;
  final int orden;

  ProductImage({
    required this.id,
    required this.productoId,
    required String url,
    required this.esPrincipal,
    required this.orden,
  }) : _url = url;

  /// Getter que retorna URL formateada correctamente
  /// Si ya tiene protocolo http, retorna como está
  /// Si no, agrega /storage/ prefix
  String get url {
    if (_url.isEmpty) return '';
    if (_url.startsWith('http')) return _url;
    return '/storage/$_url';
  }

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] ?? 0,
      productoId: json['producto_id'] ?? 0,
      url: json['url'] ?? '',
      esPrincipal: json['es_principal'] ?? false,
      orden: json['orden'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'producto_id': productoId,
      'url': _url,
      'es_principal': esPrincipal,
      'orden': orden,
    };
  }
}

/// Información de stock por almacén
class StockWarehouse {
  final int almacenId;
  final String? almacenNombre;
  final num cantidad;
  final num? cantidadDisponible;
  final num? cantidadReservada;
  final String? lote;
  final String? fechaVencimiento;

  StockWarehouse({
    required this.almacenId,
    this.almacenNombre,
    required this.cantidad,
    this.cantidadDisponible,
    this.cantidadReservada,
    this.lote,
    this.fechaVencimiento,
  });

  factory StockWarehouse.fromJson(Map<String, dynamic> json) {
    return StockWarehouse(
      almacenId: json['almacen_id'],
      almacenNombre: json['almacen_nombre'],
      cantidad: json['cantidad'] ?? 0,
      cantidadDisponible: json['cantidad_disponible'],
      cantidadReservada: json['cantidad_reservada'],
      lote: json['lote'],
      fechaVencimiento: json['fecha_vencimiento'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'almacen_id': almacenId,
      'almacen_nombre': almacenNombre,
      'cantidad': cantidad,
      'cantidad_disponible': cantidadDisponible,
      'cantidad_reservada': cantidadReservada,
      'lote': lote,
      'fecha_vencimiento': fechaVencimiento,
    };
  }
}

/// Información de precios por tipo
class Precio {
  final int id;
  final int productoId;
  final int tipoPrecioId;
  final String nombre;
  final double precio;
  final bool esPrecioBase;
  final double margenGanancia;
  final double porcentajeGanancia;
  final Map<String, dynamic>? tipoPrecio;

  Precio({
    required this.id,
    required this.productoId,
    required this.tipoPrecioId,
    required this.nombre,
    required this.precio,
    required this.esPrecioBase,
    required this.margenGanancia,
    required this.porcentajeGanancia,
    this.tipoPrecio,
  });

  factory Precio.fromJson(Map<String, dynamic> json) {
    return Precio(
      id: json['id'] ?? 0,
      productoId: json['producto_id'] ?? 0,
      tipoPrecioId: json['tipo_precio_id'] ?? 0,
      nombre: json['nombre'] ?? '',
      precio: _parseDouble(json['precio']) ?? 0.0,
      esPrecioBase: json['es_precio_base'] ?? false,
      margenGanancia: _parseDouble(json['margen_ganancia']) ?? 0.0,
      porcentajeGanancia: _parseDouble(json['porcentaje_ganancia']) ?? 0.0,
      tipoPrecio: json['tipo_precio'] is Map ? json['tipo_precio'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'producto_id': productoId,
      'tipo_precio_id': tipoPrecioId,
      'nombre': nombre,
      'precio': precio,
      'es_precio_base': esPrecioBase,
      'margen_ganancia': margenGanancia,
      'porcentaje_ganancia': porcentajeGanancia,
      'tipo_precio': tipoPrecio,
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    if (value is num) return value.toDouble();
    return null;
  }
}

/// Representa un producto que forma parte de un combo
class ComboItem {
  final int id;
  final int comboId;
  final int productoId;
  final String? productoNombre;
  final String? productoSku;
  final double cantidad;
  final double? precioUnitario;
  final int? tipoPrecioId;
  final String? tipoPrecioNombre;
  final num? stockDisponible;
  final num? stockTotal;
  final bool esObligatorio;
  final bool? esCuelloBotella;
  final int? combosPosibles;
  final int? unidadMedidaId;
  final String? unidadMedidaNombre;

  ComboItem({
    required this.id,
    required this.comboId,
    required this.productoId,
    this.productoNombre,
    this.productoSku,
    required this.cantidad,
    this.precioUnitario,
    this.tipoPrecioId,
    this.tipoPrecioNombre,
    this.stockDisponible,
    this.stockTotal,
    this.esObligatorio = true,
    this.esCuelloBotella,
    this.combosPosibles,
    this.unidadMedidaId,
    this.unidadMedidaNombre,
  });

  factory ComboItem.fromJson(Map<String, dynamic> json) {
    return ComboItem(
      id: json['id'] ?? 0,
      comboId: json['combo_id'] ?? 0,
      productoId: json['producto_id'] ?? 0,
      productoNombre: json['producto_nombre'],
      productoSku: json['producto_sku'],
      cantidad: _parseDouble(json['cantidad']) ?? 0.0,
      precioUnitario: _parseDouble(json['precio_unitario']),
      tipoPrecioId: json['tipo_precio_id'],
      tipoPrecioNombre: json['tipo_precio_nombre'],
      stockDisponible: json['stock_disponible'],
      stockTotal: json['stock_total'],
      esObligatorio: json['es_obligatorio'] ?? true,
      esCuelloBotella: json['es_cuello_botella'],
      combosPosibles: json['combos_posibles'],
      unidadMedidaId: json['unidad_medida_id'],
      unidadMedidaNombre: json['unidad_medida_nombre'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'combo_id': comboId,
      'producto_id': productoId,
      'producto_nombre': productoNombre,
      'producto_sku': productoSku,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'tipo_precio_id': tipoPrecioId,
      'tipo_precio_nombre': tipoPrecioNombre,
      'stock_disponible': stockDisponible,
      'stock_total': stockTotal,
      'es_obligatorio': esObligatorio,
      'es_cuello_botella': esCuelloBotella,
      'combos_posibles': combosPosibles,
      'unidad_medida_id': unidadMedidaId,
      'unidad_medida_nombre': unidadMedidaNombre,
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    if (value is num) return value.toDouble();
    return null;
  }
}

/// Representa un grupo opcional dentro de un combo
class ComboGrupo {
  final int id;
  final int comboId;
  final String nombreGrupo;
  final int cantidadALlevar;
  final double? precioGrupo;
  final List<int>? productos;
  final List<ComboGrupoItem>? productosDetalle;

  ComboGrupo({
    required this.id,
    required this.comboId,
    required this.nombreGrupo,
    this.cantidadALlevar = 1,
    this.precioGrupo,
    this.productos,
    this.productosDetalle,
  });

  factory ComboGrupo.fromJson(Map<String, dynamic> json) {
    return ComboGrupo(
      id: json['id'] ?? 0,
      comboId: json['combo_id'] ?? 0,
      nombreGrupo: json['nombre_grupo'] ?? 'Grupo',
      cantidadALlevar: json['cantidad_a_llevar'] ?? 1,
      precioGrupo: _parseDouble(json['precio_grupo']),
      productos: json['productos'] != null
          ? List<int>.from(json['productos'])
          : null,
      productosDetalle: json['productos_detalle'] != null
          ? (json['productos_detalle'] as List)
                .map((i) => ComboGrupoItem.fromJson(i))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'combo_id': comboId,
      'nombre_grupo': nombreGrupo,
      'cantidad_a_llevar': cantidadALlevar,
      'precio_grupo': precioGrupo,
      'productos': productos,
      'productos_detalle':
          productosDetalle?.map((p) => p.toJson()).toList(),
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    if (value is num) return value.toDouble();
    return null;
  }
}

/// Representa un producto dentro de un grupo opcional del combo
class ComboGrupoItem {
  final int productoId;
  final String? productoNombre;
  final String? productoSku;

  ComboGrupoItem({
    required this.productoId,
    this.productoNombre,
    this.productoSku,
  });

  factory ComboGrupoItem.fromJson(Map<String, dynamic> json) {
    return ComboGrupoItem(
      productoId: json['producto_id'] ?? 0,
      productoNombre: json['producto_nombre'],
      productoSku: json['producto_sku'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'producto_id': productoId,
      'producto_nombre': productoNombre,
      'producto_sku': productoSku,
    };
  }
}
