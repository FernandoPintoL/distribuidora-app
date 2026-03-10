import 'package:flutter/foundation.dart';
import 'localidad.dart';
import 'client.dart';
import 'product.dart';

class PaginatedResponse<T> {
  final bool success;
  final String message;
  final PaginatedData<T>? data;

  PaginatedResponse({required this.success, required this.message, this.data});

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    /* debugPrint('📦 PaginatedResponse.fromJson - json type: ${json.runtimeType}');
    debugPrint('📦 PaginatedResponse.fromJson - json keys: ${json.keys}');
    debugPrint('📦 PaginatedResponse.fromJson - data type: ${json['data']?.runtimeType}'); */

    PaginatedData<T>? paginatedData;

    if (json['data'] != null) {
      if (json['data'] is Map<String, dynamic>) {
        // Formato estándar paginado
        paginatedData = PaginatedData.fromJson(json['data'], fromJson);
      } else if (json['data'] is List) {
        // ✅ ACTUALIZADO: Buscar 'meta' para obtener el total real
        final dataList = json['data'] as List;

        // Buscar paginación en 'meta' si existe
        Map<String, dynamic>? meta = json['meta'] is Map<String, dynamic>
          ? json['meta'] as Map<String, dynamic>
          : null;

        if (meta != null) {
          debugPrint('📊 Detected list with meta: total=${meta['total']}');
        }

        paginatedData = PaginatedData(
          currentPage: meta?['current_page'] ?? 1,
          data: dataList.map((item) {
            if (item is Map<String, dynamic>) {
              return fromJson(item);
            } else if (item is Map) {
              return fromJson(item.cast<String, dynamic>());
            } else {
              throw Exception('Invalid item type: ${item.runtimeType}');
            }
          }).toList(),
          perPage: meta?['per_page'] ?? dataList.length,
          total: meta?['total'] ?? dataList.length,
          lastPage: meta?['last_page'],
        );
      }
    }

    return PaginatedResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: paginatedData,
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message, 'data': data?.toJson()};
  }
}

class PaginatedData<T> {
  final int currentPage;
  final List<T> data;
  final int perPage;
  final int total;
  final int? lastPage;

  PaginatedData({
    required this.currentPage,
    required this.data,
    required this.perPage,
    required this.total,
    this.lastPage,
  });

  // Getter para calcular si hay más páginas
  bool get hasMorePages => currentPage * perPage < total;

  // Getter para obtener el número total de páginas
  // Prioriza lastPage del API si está disponible
  int get totalPages => lastPage ?? (total / perPage).ceil();

  factory PaginatedData.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    /* debugPrint('📊 PaginatedData.fromJson - json type: ${json.runtimeType}');
    debugPrint('📊 PaginatedData.fromJson - json keys: ${json.keys}');
    debugPrint(
      '📊 PaginatedData.fromJson - data type: ${json['data']?.runtimeType}',
    ); */

    // Check if this is the custom pedidos format with 'pedidos' and 'paginacion'
    if (json.containsKey('pedidos') && json.containsKey('paginacion')) {
      debugPrint('📊 Detected custom pedidos format');
      final pedidosData = json['pedidos'];
      final paginacion = json['paginacion'] as Map<String, dynamic>;

      // Handle null or non-list pedidos
      final List dataList = (pedidosData is List) ? pedidosData : [];
      debugPrint('📊 Pedidos list length: ${dataList.length}');

      return PaginatedData(
        currentPage: paginacion['pagina_actual'] ?? 1,
        data: dataList.map((item) {
          if (item is Map<String, dynamic>) {
            return fromJson(item);
          } else if (item is Map) {
            return fromJson(item.cast<String, dynamic>());
          } else {
            throw Exception('Invalid item type: ${item.runtimeType}');
          }
        }).toList(),
        perPage: paginacion['por_pagina'] ?? 20,
        total: paginacion['total'] ?? 0,
        lastPage: paginacion['ultima_pagina'],
      );
    }

    // Standard Laravel pagination format
    final rawData = json['data'];
    final List dataList = (rawData is List) ? rawData : [];

    debugPrint('📊 PaginatedData.fromJson - list length: ${dataList.length}');
    if (dataList.isNotEmpty) {
      debugPrint(
        '📊 PaginatedData.fromJson - first item type: ${dataList.first.runtimeType}',
      );
    }

    // ✅ ACTUALIZADO: Buscar paginación en 'meta' primero, luego en nivel superior
    Map<String, dynamic> paginationSource = {};
    if (json.containsKey('meta') && json['meta'] is Map<String, dynamic>) {
      paginationSource = json['meta'] as Map<String, dynamic>;
      debugPrint('📊 Paginación encontrada en "meta": total=${paginationSource['total']}, current_page=${paginationSource['current_page']}');
    } else if (json.containsKey('current_page')) {
      paginationSource = json;
      debugPrint('📊 Paginación encontrada en nivel superior');
    } else {
      debugPrint('⚠️ No se encontró información de paginación');
    }

    try {
      final currentPage = paginationSource['current_page'] ?? 1;
      final perPage = paginationSource['per_page'] ?? 20;
      final total = paginationSource['total'] ?? 0;
      final lastPage = paginationSource['last_page'];

      debugPrint('📊 Valores extraídos: currentPage=$currentPage, perPage=$perPage, total=$total, lastPage=$lastPage');

      return PaginatedData(
        currentPage: currentPage,
        data: dataList.map((item) {
          try {
            if (item is Map<String, dynamic>) {
              return fromJson(item);
            } else if (item is Map) {
              return fromJson(item.cast<String, dynamic>());
            } else {
              throw Exception('Invalid item type: ${item.runtimeType}');
            }
          } catch (e) {
            debugPrint('❌ Error parsing item in list: $e');
            debugPrint('   Item: $item');
            rethrow;
          }
        }).toList(),
        perPage: perPage,
        total: total,
        lastPage: lastPage,
      );
    } catch (e) {
      debugPrint('❌ Error in PaginatedData.fromJson: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'data': data,
      'per_page': perPage,
      'total': total,
      'last_page': lastPage,
    };
  }
}

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  String? code; // Código de error específico (ej: RESERVAS_EXPIRADAS)
  Map<String, dynamic>? additionalData; // Datos adicionales del error

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.code,
    this.additionalData,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, [
    dynamic Function(Map<String, dynamic>)? fromJson,
  ]) {
    try {
      final success = json['success'] ?? false;
      final message = json['message'] ?? '';

      // Si la respuesta no fue exitosa, retornar sin intentar parsear data
      if (!success) {
        return ApiResponse<T>(success: false, message: message, data: null);
      }

      if (json.containsKey('data')) {
        // Wrapped format: {success: true, message: ..., data: ...}
        dynamic rawData = json['data'];

        dynamic processedData;
        if (rawData != null && fromJson != null) {
          // Check if data is a list and we need to process each item
          if (rawData is List) {
            // For List<T>, apply fromJson to each item
            // The result will be List<dynamic> but containing correctly typed objects
            final List<dynamic> rawList = rawData;
            final List<dynamic> processedList = rawList
                .map((item) => fromJson(item))
                .toList();
            // Try to cast the list to the correct type based on T
            if (T.toString() == 'List<Localidad>') {
              processedData = processedList.cast<Localidad>().toList();
            } else if (T.toString() == 'List<Client>') {
              processedData = processedList.cast<Client>().toList();
            } else if (T.toString() == 'List<ClientAddress>') {
              processedData = processedList.cast<ClientAddress>().toList();
            } else if (T.toString() == 'List<Product>') {
              processedData = processedList.cast<Product>().toList();
            } else {
              processedData = processedList;
            }
          } else if (rawData is Map<String, dynamic> &&
              rawData.containsKey('data') &&
              rawData['data'] is List) {
            // Es una respuesta paginada
            final List<dynamic> rawList = rawData['data'];
            final List<dynamic> processedList = rawList
                .map((item) => fromJson(item))
                .toList();
            // Try to cast the list to the correct type based on T
            if (T.toString() == 'List<Map<String, dynamic>>') {
              processedData = processedList
                  .cast<Map<String, dynamic>>()
                  .toList();
            } else {
              processedData = processedList;
            }
          } else if (rawData is Map<String, dynamic>) {
            // For single object, apply fromJson directly
            processedData = fromJson(rawData);
          } else {
            // For other types, use as is
            processedData = rawData;
          }
        } else {
          processedData = rawData;
        }

        // Assign processedData directly without casting
        return ApiResponse<T>(
          success: success,
          message: message,
          data: processedData,
        );
      } else {
        // Direct format: the data itself
        return ApiResponse<T>(
          success: true,
          message: '',
          data: fromJson != null ? fromJson(json) : null,
        );
      }
    } catch (e) {
      debugPrint('❌ Error parsing ApiResponse: $e, json: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message, 'data': data};
  }
}
