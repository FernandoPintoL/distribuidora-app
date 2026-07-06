import 'prestamo_cliente.dart';

class PrestamosClienteResponse {
  final bool success;
  final PrestamosClienteData data;

  PrestamosClienteResponse({required this.success, required this.data});

  factory PrestamosClienteResponse.fromJson(Map<String, dynamic> json) {
    return PrestamosClienteResponse(
      success: json['success'] as bool? ?? false,
      data: PrestamosClienteData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class PrestamosClienteData {
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
  final List<PrestamoCliente> prestamos;

  PrestamosClienteData({
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

  factory PrestamosClienteData.fromJson(Map<String, dynamic> json) {
    return PrestamosClienteData(
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
      prestamos:
          (json['data'] as List?)
              ?.map((p) => PrestamoCliente.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
