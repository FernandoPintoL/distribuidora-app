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
    debugPrint('📦 PaginatedResponse.fromJson - json type: ${json.runtimeType}');
    debugPrint('📦 PaginatedResponse.fromJson - json keys: ${json.keys}');
    debugPrint('📦 PaginatedResponse.fromJson - data type: ${json['data']?.runtimeType}');
    
    PaginatedData<T>? paginatedData;
    
    if (json['data'] != null) {
      if (json['data'] is Map<String, dynamic>) {
        // Formato estándar paginado
        paginatedData = PaginatedData.fromJson(json['data'], fromJson);
      } else if (json['data'] is List) {
        // Formato de lista directa (sin paginación)
        debugPrint('⚠️ Data es una lista directa, creando PaginatedData simple');
        final dataList = json['data'] as List;
        paginatedData = PaginatedData(
          currentPage: 1,
          data: dataList.map((item) {
            if (item is Map<String, dynamic>) {
              return fromJson(item);
            } else if (item is Map) {
              return fromJson(item.cast<String, dynamic>());
            } else {
              throw Exception('Invalid item type: ${item.runtimeType}');
            }
          }).toList(),
          perPage: dataList.length,
          total: dataList.length,
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

  PaginatedData({
    required this.currentPage,
    required this.data,
    required this.perPage,
    required this.total,
  });

  // Getter para calcular si hay más páginas
  bool get hasMorePages => currentPage * perPage < total;

  // Getter para obtener el número total de páginas
  int get totalPages => (total / perPage).ceil();

  factory PaginatedData.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    debugPrint('📊 PaginatedData.fromJson - json type: ${json.runtimeType}');
    debugPrint('📊 PaginatedData.fromJson - json keys: ${json.keys}');
    debugPrint('📊 PaginatedData.fromJson - data type: ${json['data']?.runtimeType}');

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
      );
    }

    // Standard Laravel pagination format
    final rawData = json['data'];
    final List dataList = (rawData is List) ? rawData : [];

    debugPrint('📊 PaginatedData.fromJson - list length: ${dataList.length}');
    if (dataList.isNotEmpty) {
      debugPrint('📊 PaginatedData.fromJson - first item type: ${dataList.first.runtimeType}');
    }

    try {
      return PaginatedData(
        currentPage: json['current_page'] ?? 1,
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
        perPage: json['per_page'] ?? 20,
        total: json['total'] ?? 0,
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
        return ApiResponse<T>(
          success: false,
          message: message,
          data: null,
        );
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
