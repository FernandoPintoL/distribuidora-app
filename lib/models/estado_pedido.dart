import 'package:flutter/material.dart';

enum EstadoPedido {
  PENDIENTE,
  APROBADA,
  RECHAZADA,
  PREPARANDO,
  EN_CAMION,
  EN_RUTA,
  LLEGO,
  ENTREGADO,
  NOVEDAD,
  VENCIDA,
}

class EstadoInfo {
  final EstadoPedido codigo;
  final String nombre;
  final String descripcion;
  final Color color;
  final IconData icono;
  final bool puedeCancel;

  const EstadoInfo({
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.color,
    required this.icono,
    this.puedeCancel = false,
  });

  static EstadoInfo getInfo(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.PENDIENTE:
        return EstadoInfo(
          codigo: EstadoPedido.PENDIENTE,
          nombre: 'Pendiente',
          descripcion: 'Esperando aprobación',
          color: Colors.orange,
          icono: Icons.schedule,
          puedeCancel: true,
        );
      case EstadoPedido.APROBADA:
        return EstadoInfo(
          codigo: EstadoPedido.APROBADA,
          nombre: 'Aprobada',
          descripcion: 'Proforma aprobada',
          color: Colors.blue,
          icono: Icons.check_circle,
        );
      case EstadoPedido.RECHAZADA:
        return EstadoInfo(
          codigo: EstadoPedido.RECHAZADA,
          nombre: 'Rechazada',
          descripcion: 'Proforma rechazada',
          color: Colors.red,
          icono: Icons.cancel,
        );
      case EstadoPedido.PREPARANDO:
        return EstadoInfo(
          codigo: EstadoPedido.PREPARANDO,
          nombre: 'Preparando',
          descripcion: 'Armando el pedido',
          color: Colors.purple,
          icono: Icons.inventory,
        );
      case EstadoPedido.EN_CAMION:
        return EstadoInfo(
          codigo: EstadoPedido.EN_CAMION,
          nombre: 'En Camión',
          descripcion: 'Cargado en el camión',
          color: Colors.indigo,
          icono: Icons.local_shipping,
        );
      case EstadoPedido.EN_RUTA:
        return EstadoInfo(
          codigo: EstadoPedido.EN_RUTA,
          nombre: 'En Ruta',
          descripcion: 'Camión en camino',
          color: Colors.blue,
          icono: Icons.near_me,
        );
      case EstadoPedido.LLEGO:
        return EstadoInfo(
          codigo: EstadoPedido.LLEGO,
          nombre: 'Llegó',
          descripcion: 'Camión llegó al destino',
          color: Colors.teal,
          icono: Icons.location_on,
        );
      case EstadoPedido.ENTREGADO:
        return EstadoInfo(
          codigo: EstadoPedido.ENTREGADO,
          nombre: 'Entregado',
          descripcion: 'Pedido entregado',
          color: Colors.green,
          icono: Icons.check_circle_outline,
        );
      case EstadoPedido.NOVEDAD:
        return EstadoInfo(
          codigo: EstadoPedido.NOVEDAD,
          nombre: 'Novedad',
          descripcion: 'Hubo un problema',
          color: Colors.deepOrange,
          icono: Icons.warning,
        );
      case EstadoPedido.VENCIDA:
        return EstadoInfo(
          codigo: EstadoPedido.VENCIDA,
          nombre: 'Vencida',
          descripcion: 'Venció el tiempo de reserva',
          color: Colors.grey,
          icono: Icons.event_busy,
        );
    }
  }

  // Helper para convertir string a enum
  static EstadoPedido fromString(String estado) {
    return EstadoPedido.values.firstWhere(
      (e) => e.name == estado,
      orElse: () => EstadoPedido.PENDIENTE,
    );
  }

  // Helper para convertir enum a string
  static String enumToString(EstadoPedido estado) {
    return estado.name;
  }
}
