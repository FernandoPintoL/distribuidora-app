import 'prestamo_proveedor.dart';

class PrestamosProveedorResponse {
  final bool success;
  final PrestamosProveedorData data;

  PrestamosProveedorResponse({
    required this.success,
    required this.data,
  });

  factory PrestamosProveedorResponse.fromJson(Map<String, dynamic> json) {
    return PrestamosProveedorResponse(
      success: json['success'] as bool? ?? false,
      data: PrestamosProveedorData.fromJson(
          json['data'] as Map<String, dynamic>),
    );
  }
}

class PrestamosProveedorData {
  final int currentPage;
  final int? from;
  final int lastPage;
  final int perPage;
  final int? to;
  final int total;
  final String path;
  final String? firstPageUrl;
  final String? lastPageUrl;
  final String? nextPageUrl;
  final String? prevPageUrl;
  final List<PrestamoProveedor> prestamos;

  PrestamosProveedorData({
    required this.currentPage,
    this.from,
    required this.lastPage,
    required this.perPage,
    this.to,
    required this.total,
    required this.path,
    this.firstPageUrl,
    this.lastPageUrl,
    this.nextPageUrl,
    this.prevPageUrl,
    required this.prestamos,
  });

  factory PrestamosProveedorData.fromJson(Map<String, dynamic> json) {
    return PrestamosProveedorData(
      currentPage: json['current_page'] as int? ?? 1,
      from: json['from'] as int?,
      lastPage: json['last_page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 10,
      to: json['to'] as int?,
      total: json['total'] as int? ?? 0,
      path: json['path'] as String? ?? '',
      firstPageUrl: json['first_page_url'] as String?,
      lastPageUrl: json['last_page_url'] as String?,
      nextPageUrl: json['next_page_url'] as String?,
      prevPageUrl: json['prev_page_url'] as String?,
      prestamos: (json['data'] as List?)
              ?.map((p) =>
                  PrestamoProveedor.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
