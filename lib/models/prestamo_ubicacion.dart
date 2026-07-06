import 'direccion_cliente.dart';
import 'localidad.dart';

class PrestamoUbicacion {
  final int id;
  final int? prestamoClienteId;
  final int? prestamoEventoId;
  final int? direccionClienteId;
  final int? localidadId;
  final bool esUbicacionManual;
  final String? direccion;
  final String? createdAt;
  final String? updatedAt;
  final DireccionCliente? direccionCliente;
  final Localidad? localidad;
  final String? latitud;
  final String? longitud;

  PrestamoUbicacion({
    required this.id,
    this.prestamoClienteId,
    this.prestamoEventoId,
    this.direccionClienteId,
    this.localidadId,
    this.esUbicacionManual = false,
    this.direccion,
    this.createdAt,
    this.updatedAt,
    this.direccionCliente,
    this.localidad,
    this.latitud,
    this.longitud,
  });

  // ✅ NUEVO: Getter para obtener observaciones
  String? get observaciones => direccionCliente?.observaciones ?? direccion;

  factory PrestamoUbicacion.fromJson(Map<String, dynamic> json) {
    return PrestamoUbicacion(
      id: json['id'] as int? ?? 0,
      prestamoClienteId: json['prestamo_cliente_id'] as int?,
      prestamoEventoId: json['prestamo_evento_id'] as int?,
      direccionClienteId: json['direccion_cliente_id'] as int?,
      localidadId: json['localidad_id'] as int?,
      esUbicacionManual: json['es_ubicacion_manual'] as bool? ?? false,
      direccion: json['direccion'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      direccionCliente: json['direccion_cliente'] != null
          ? DireccionCliente.fromJson(
              json['direccion_cliente'] as Map<String, dynamic>,
            )
          : null,
      localidad: json['localidad'] != null
          ? Localidad.fromJson(json['localidad'] as Map<String, dynamic>)
          : null,
      latitud: json['latitud'] as String?,
      longitud: json['longitud'] as String?,
    );
  }
}
