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
  final List<ProductImage>? imagenes;
  final List<String>? codigosBarra;
  final StockWarehouse? stockPrincipal;
  final List<StockWarehouse>? stockPorAlmacenes;

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
    this.imagenes,
    this.codigosBarra,
    this.stockPrincipal,
    this.stockPorAlmacenes,
  });

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
            ? Category.fromJson(json['categoria'])
            : null,
        marca: json['marca'] != null ? Brand.fromJson(json['marca']) : null,
        proveedor: json['proveedor'] != null
            ? Supplier.fromJson(json['proveedor'])
            : null,
        // Backend sends 'unidad', not 'unidad_medida'
        unidadMedida: json['unidad'] != null
            ? UnitMeasure.fromJson(json['unidad'])
            : (json['unidad_medida'] != null
                  ? UnitMeasure.fromJson(json['unidad_medida'])
                  : null),
        activo: json['activo'] ?? true,
        precioCompra: json['precio_compra']?.toDouble(),
        // Map both 'precio_venta' and 'precio' (from list endpoint)
        precioVenta: (json['precio_venta'] ?? json['precio'])?.toDouble(),
        stockMinimo: json['stock_minimo'],
        stockMaximo: json['stock_maximo'],
        cantidadMinima: json['cantidad_minima'],
        imagenes: json['imagenes'] != null
            ? (json['imagenes'] as List)
                  .map((i) => ProductImage.fromJson(i))
                  .toList()
            : null,
        codigosBarra:
            json['codigos_barra'] != null && json['codigos_barra'] is List
            ? List<String>.from(json['codigos_barra'])
            : null,
        // Map stock_principal or create one from cantidad_disponible at root level
        stockPrincipal: json['stock_principal'] != null
            ? StockWarehouse.fromJson(json['stock_principal'])
            : (json['cantidad_disponible'] != null
                  ? StockWarehouse(
                      almacenId: 3, // Default to almacén 3 (main warehouse)
                      almacenNombre: 'Principal',
                      cantidad:
                          (json['cantidad_disponible'] as num?)?.toInt() ?? 0,
                      cantidadDisponible: json['cantidad_disponible'],
                    )
                  : null),
        stockPorAlmacenes: json['stock_por_almacenes'] != null
            ? (json['stock_por_almacenes'] as List)
                  .map((i) => StockWarehouse.fromJson(i))
                  .toList()
            : null,
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
      'imagenes': imagenes?.map((i) => i.toJson()).toList(),
      'codigos_barra': codigosBarra,
    };
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
  final String url;
  final int orden;

  ProductImage({required this.url, required this.orden});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(url: json['url'], orden: json['orden']);
  }

  Map<String, dynamic> toJson() {
    return {'url': url, 'orden': orden};
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
