class Vehiculo {
  final int id;
  final String placa;
  final String marca;
  final String modelo;
  final int? anho;
  final String? capacidadKg;
  final String? capacidadVolumen;
  final String estado;
  final int? choferAsignadoId;
  final bool activo;
  final String? observaciones;

  Vehiculo({
    required this.id,
    required this.placa,
    required this.marca,
    required this.modelo,
    this.anho,
    this.capacidadKg,
    this.capacidadVolumen,
    this.estado = 'DISPONIBLE',
    this.choferAsignadoId,
    this.activo = true,
    this.observaciones,
  });

  factory Vehiculo.fromJson(Map<String, dynamic> json) {
    return Vehiculo(
      id: json['id'] as int,
      placa: json['placa'] as String,
      marca: json['marca'] as String,
      modelo: json['modelo'] as String,
      anho: json['anho'] as int? ?? json['año'] as int?,
      capacidadKg: json['capacidad_kg'] as String?,
      capacidadVolumen: json['capacidad_volumen'] as String?,
      estado: json['estado'] as String? ?? 'DISPONIBLE',
      choferAsignadoId: json['chofer_asignado_id'] as int?,
      activo: json['activo'] as bool? ?? true,
      observaciones: json['observaciones'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'placa': placa,
      'marca': marca,
      'modelo': modelo,
      'anho': anho,
      'capacidad_kg': capacidadKg,
      'capacidad_volumen': capacidadVolumen,
      'estado': estado,
      'chofer_asignado_id': choferAsignadoId,
      'activo': activo,
      'observaciones': observaciones,
    };
  }

  String get placaFormato => placa.toUpperCase();
  String get descripcion => '$marca $modelo $anho';
  String get infoCompleta => '$placaFormato - $descripcion ($capacidadKg kg)';
}
