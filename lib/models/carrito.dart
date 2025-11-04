import 'carrito_item.dart';

class Carrito {
  final int? id;                    // ID en la base de datos
  final int? usuarioId;              // ID del usuario propietario
  final List<CarritoItem> items;
  final String estado;               // 'activo', 'guardado', 'convertido'
  final DateTime? fechaCreacion;
  final DateTime? fechaUltimaActualizacion;
  final DateTime? fechaAbandono;

  Carrito({
    this.id,
    this.usuarioId,
    this.items = const [],
    this.estado = 'activo',
    this.fechaCreacion,
    this.fechaUltimaActualizacion,
    this.fechaAbandono,
  });

  // Cálculos
  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  double get impuesto {
    // 13% de impuesto (ajustar según tu país)
    return subtotal * 0.13;
  }

  double get total {
    return subtotal + impuesto;
  }

  int get cantidadItems {
    return items.length;
  }

  int get cantidadProductos {
    return items.fold(0, (sum, item) => sum + item.cantidad.toInt());
  }

  bool get isEmpty {
    return items.isEmpty;
  }

  bool get isNotEmpty {
    return items.isNotEmpty;
  }

  // Métodos auxiliares
  CarritoItem? getItemByProductoId(int productoId) {
    try {
      return items.firstWhere((item) => item.producto.id == productoId);
    } catch (e) {
      return null;
    }
  }

  bool tieneProducto(int productoId) {
    return items.any((item) => item.producto.id == productoId);
  }

  // Crear copia con cambios
  Carrito copyWith({
    int? id,
    int? usuarioId,
    List<CarritoItem>? items,
    String? estado,
    DateTime? fechaCreacion,
    DateTime? fechaUltimaActualizacion,
    DateTime? fechaAbandono,
  }) {
    return Carrito(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      items: items ?? this.items,
      estado: estado ?? this.estado,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaUltimaActualizacion: fechaUltimaActualizacion ?? this.fechaUltimaActualizacion,
      fechaAbandono: fechaAbandono ?? this.fechaAbandono,
    );
  }

  // Convertir a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'items': items.map((item) => item.toJson()).toList(),
      'estado': estado,
      'subtotal': subtotal,
      'impuesto': impuesto,
      'total': total,
      'fecha_creacion': fechaCreacion?.toIso8601String(),
      'fecha_ultima_actualizacion': fechaUltimaActualizacion?.toIso8601String(),
      'fecha_abandono': fechaAbandono?.toIso8601String(),
    };
  }

  // Crear desde JSON (para recuperar de la BD)
  factory Carrito.fromJson(Map<String, dynamic> json) {
    return Carrito(
      id: json['id'],
      usuarioId: json['usuario_id'],
      items: json['items'] != null
          ? (json['items'] as List).map((item) => CarritoItem.fromJson(item)).toList()
          : [],
      estado: json['estado'] ?? 'activo',
      fechaCreacion: json['fecha_creacion'] != null ? DateTime.parse(json['fecha_creacion']) : null,
      fechaUltimaActualizacion: json['fecha_ultima_actualizacion'] != null ? DateTime.parse(json['fecha_ultima_actualizacion']) : null,
      fechaAbandono: json['fecha_abandono'] != null ? DateTime.parse(json['fecha_abandono']) : null,
    );
  }

  // Convertir items para crear pedido (formato API)
  List<Map<String, dynamic>> toItemsForPedido() {
    return items.map((item) => {
      'producto_id': item.producto.id,
      'cantidad': item.cantidad,
      'precio_unitario': item.precioUnitario,
    }).toList();
  }
}
