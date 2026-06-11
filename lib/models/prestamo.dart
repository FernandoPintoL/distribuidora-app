import 'package:flutter/material.dart';

class Prestamo {
  final int id;
  final String? estado;
  final String? fechaPrestamo;
  final String? fechaEsperadaDevolucion;
  final double? montoGarantia;

  // Cliente
  final Map<String, dynamic>? cliente;

  // Evento
  final String? nombreEvento;
  final String? encargadoEvento;
  final String? direccionEvento;

  // Proveedor
  final Map<String, dynamic>? proveedor;

  // Detalles
  final List<dynamic>? detalles;

  Prestamo({
    required this.id,
    this.estado,
    this.fechaPrestamo,
    this.fechaEsperadaDevolucion,
    this.montoGarantia,
    this.cliente,
    this.nombreEvento,
    this.encargadoEvento,
    this.direccionEvento,
    this.proveedor,
    this.detalles,
  });

  factory Prestamo.fromJson(Map<String, dynamic> json) {
    // ✅ CORREGIDO: monto_garantia puede venir como String
    double? parseMontoGarantia(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return Prestamo(
      id: json['id'] as int? ?? 0,
      estado: json['estado'] as String?,
      fechaPrestamo: json['fecha_prestamo'] as String?,
      fechaEsperadaDevolucion: json['fecha_esperada_devolucion'] as String?,
      montoGarantia: parseMontoGarantia(json['monto_garantia']),
      cliente: json['cliente'] as Map<String, dynamic>?,
      nombreEvento: json['nombre_evento'] as String?,
      encargadoEvento: json['encargado_evento'] as String?,
      direccionEvento: json['direccion_evento'] as String?,
      proveedor: json['proveedor'] as Map<String, dynamic>?,
      detalles: json['detalles'] as List?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'estado': estado,
      'fecha_prestamo': fechaPrestamo,
      'fecha_esperada_devolucion': fechaEsperadaDevolucion,
      'monto_garantia': montoGarantia,
      'cliente': cliente,
      'nombre_evento': nombreEvento,
      'encargado_evento': encargadoEvento,
      'direccion_evento': direccionEvento,
      'proveedor': proveedor,
      'detalles': detalles,
    };
  }
}
