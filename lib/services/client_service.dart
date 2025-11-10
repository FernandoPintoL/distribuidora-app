import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import '../models/models.dart';
import 'api_service.dart';

// NOTA IMPORTANTE SOBRE BOOLEANOS:
// Cuando se envían datos sin archivo (JSON), los booleanos se mantienen como true/false
// Cuando se envían datos con archivo (FormData), los booleanos se convierten a strings "true"/"false"
// El backend debe interpretar correctamente ambos formatos

class ClientService {
  final ApiService _apiService = ApiService();

  ClientService();

  Future<PaginatedResponse<Client>> getClients({
    int page = 1,
    int perPage = 20,
    String? search,
    bool? active,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};

      if (search != null && search.isNotEmpty) {
        queryParams['q'] = search;
      }
      if (active != null) {
        queryParams['activo'] = active;
      }

      final response = await _apiService.get(
        '/clientes',
        queryParameters: queryParams,
      );

      debugPrint('📥 Response data type: ${response.data.runtimeType}');
      debugPrint('📥 Response data: ${response.data}');

      return PaginatedResponse<Client>.fromJson(
        response.data,
        (json) => Client.fromJson(json),
      );
    } on DioException catch (e) {
      return PaginatedResponse<Client>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      debugPrint('❌ Error en getClients: $e');
      return PaginatedResponse<Client>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<ApiResponse<List<Client>>> searchClients(
    String query, {
    int limit = 10,
  }) async {
    try {
      final response = await _apiService.get(
        '/clientes/buscar',
        queryParameters: {'q': query, 'limite': limit},
      );

      final apiResponse = ApiResponse<List<Client>>.fromJson(
        response.data,
        Client.fromJson,
      );

      return apiResponse;
    } on DioException catch (e) {
      return ApiResponse<List<Client>>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<List<Client>>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<ApiResponse<Client>> getClient(int id) async {
    try {
      final response = await _apiService.get('/clientes/$id');

      return ApiResponse<Client>.fromJson(
        response.data,
        (data) => Client.fromJson(
          data.containsKey('cliente') ? data['cliente'] : data,
        ),
      );
    } on DioException catch (e) {
      return ApiResponse<Client>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<Client>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<ApiResponse<Client>> createClient({
    required String nombre,
    String? razonSocial,
    String? nit,
    String? email,
    String? telefono,
    double? limiteCredito,
    int? localidadId,
    double? latitud,
    double? longitud,
    bool activo = true,
    String? observaciones,
    List<ClientAddress>? direcciones,
    List<VentanaEntregaCliente>? ventanasEntrega,
    List<int>? categoriasIds,
    bool? crearUsuario,
    File? fotoPerfil,
    File? ciAnverso,
    File? ciReverso,
  }) async {
    try {
      final data = {
        'nombre': nombre,
        'razon_social': razonSocial,
        'nit': nit,
        'email': email,
        'telefono': telefono,
        'limite_credito': limiteCredito,
        'localidad_id': localidadId,
        // Solo enviar coordenadas en nivel principal si NO hay direcciones con coordenadas
        'latitud':
            (direcciones != null &&
                direcciones.isNotEmpty &&
                direcciones.any((d) => d.latitud != null && d.longitud != null))
            ? null
            : latitud,
        'longitud':
            (direcciones != null &&
                direcciones.isNotEmpty &&
                direcciones.any((d) => d.latitud != null && d.longitud != null))
            ? null
            : longitud,
        'activo': activo,
        'observaciones': observaciones,
        'direcciones': direcciones?.map((d) => d.toJson()).toList(),
        if (ventanasEntrega != null)
          'ventanas_entrega': ventanasEntrega
              .map(
                (v) => {
                  'dia_semana': v.diaSemana,
                  'hora_inicio': v.horaInicio,
                  'hora_fin': v.horaFin,
                  'activo': v.activo,
                },
              )
              .toList(),
        if (categoriasIds != null) 'categorias_ids': categoriasIds,
        if (crearUsuario != null) 'crear_usuario': crearUsuario,
      };

      dynamic requestData = data;

      // Si hay archivos (foto_perfil, ci_anverso, ci_reverso), usar FormData para mantener tipos de datos
      if (fotoPerfil != null || ciAnverso != null || ciReverso != null) {
        final formData = FormData();

        // Agregar campos de texto
        formData.fields.add(MapEntry('nombre', nombre));
        formData.fields.add(MapEntry('razon_social', razonSocial ?? ''));
        if (nit != null) formData.fields.add(MapEntry('nit', nit));
        if (email != null) formData.fields.add(MapEntry('email', email));
        if (telefono != null) {
          formData.fields.add(MapEntry('telefono', telefono));
        }
        if (limiteCredito != null) {
          formData.fields.add(
            MapEntry('limite_credito', limiteCredito.toString()),
          );
        }
        if (localidadId != null) {
          formData.fields.add(MapEntry('localidad_id', localidadId.toString()));
        }
        if (latitud != null) {
          formData.fields.add(MapEntry('latitud', latitud.toString()));
        }
        if (longitud != null) {
          formData.fields.add(MapEntry('longitud', longitud.toString()));
        }
        if (observaciones != null) {
          formData.fields.add(MapEntry('observaciones', observaciones));
        }
        if (crearUsuario != null) {
          formData.fields.add(
            MapEntry('crear_usuario', crearUsuario ? '1' : '0'),
          );
        }

        // Booleans en multipart: enviar como '1'/'0' para compatibilidad con Laravel boolean
        formData.fields.add(MapEntry('activo', activo ? '1' : '0'));
        print('📤 Enviando activo como string (1/0): ${(activo ? '1' : '0')}');

        // Solo enviar coordenadas en nivel principal si NO hay direcciones con coordenadas
        final hasAddressCoords =
            direcciones != null &&
            direcciones.isNotEmpty &&
            direcciones.any((d) => d.latitud != null && d.longitud != null);

        if (latitud != null && !hasAddressCoords) {
          formData.fields.add(MapEntry('latitud', latitud.toString()));
        }
        if (longitud != null && !hasAddressCoords) {
          formData.fields.add(MapEntry('longitud', longitud.toString()));
        }

        // Agregar direcciones como campos separados con índices
        if (direcciones != null && direcciones.isNotEmpty) {
          for (int i = 0; i < direcciones.length; i++) {
            final dir = direcciones[i];
            formData.fields.add(
              MapEntry('direcciones[$i][direccion]', dir.direccion),
            );
            if (dir.ciudad != null) {
              formData.fields.add(
                MapEntry('direcciones[$i][ciudad]', dir.ciudad!),
              );
            }
            if (dir.departamento != null) {
              formData.fields.add(
                MapEntry('direcciones[$i][departamento]', dir.departamento!),
              );
            }
            if (dir.codigoPostal != null) {
              formData.fields.add(
                MapEntry('direcciones[$i][codigo_postal]', dir.codigoPostal!),
              );
            }
            formData.fields.add(
              MapEntry(
                'direcciones[$i][es_principal]',
                dir.esPrincipal ? '1' : '0',
              ),
            );
            formData.fields.add(
              MapEntry(
                'direcciones[$i][activa]',
                (dir.activa ?? true) ? '1' : '0',
              ),
            );
            if (dir.observaciones != null) {
              formData.fields.add(
                MapEntry('direcciones[$i][observaciones]', dir.observaciones!),
              );
            }
            if (dir.latitud != null) {
              formData.fields.add(
                MapEntry('direcciones[$i][latitud]', dir.latitud!.toString()),
              );
            }
            if (dir.longitud != null) {
              formData.fields.add(
                MapEntry('direcciones[$i][longitud]', dir.longitud!.toString()),
              );
            }
          }
          print(
            '📤 Enviando ${direcciones.length} direcciones como campos separados',
          );
        }

        // Agregar archivo de foto (si existe)
        if (fotoPerfil != null) {
          formData.files.add(
            MapEntry(
              'foto_perfil',
              await MultipartFile.fromFile(
                fotoPerfil.path,
                filename: 'profile_photo.jpg',
              ),
            ),
          );
        }
        // Agregar archivos de CI (si existen)
        if (ciAnverso != null) {
          formData.files.add(
            MapEntry(
              'ci_anverso',
              await MultipartFile.fromFile(
                ciAnverso.path,
                filename: 'ci_anverso.jpg',
              ),
            ),
          );
        }
        if (ciReverso != null) {
          formData.files.add(
            MapEntry(
              'ci_reverso',
              await MultipartFile.fromFile(
                ciReverso.path,
                filename: 'ci_reverso.jpg',
              ),
            ),
          );
        }

        // Agregar ventanas_entrega como campos con índices si vienen
        if (ventanasEntrega != null && ventanasEntrega.isNotEmpty) {
          for (int i = 0; i < ventanasEntrega.length; i++) {
            final v = ventanasEntrega[i];
            formData.fields.add(
              MapEntry(
                'ventanas_entrega[$i][dia_semana]',
                v.diaSemana.toString(),
              ),
            );
            formData.fields.add(
              MapEntry('ventanas_entrega[$i][hora_inicio]', v.horaInicio),
            );
            formData.fields.add(
              MapEntry('ventanas_entrega[$i][hora_fin]', v.horaFin),
            );
            formData.fields.add(
              MapEntry('ventanas_entrega[$i][activo]', v.activo ? '1' : '0'),
            );
          }
        }
        // Agregar categorias_ids[] si vienen
        if (categoriasIds != null && categoriasIds.isNotEmpty) {
          for (final idCat in categoriasIds) {
            formData.fields.add(MapEntry('categorias_ids[]', idCat.toString()));
          }
        }

        requestData = formData;
      }

      final response = await _apiService.post(
        '/clientes',
        data: requestData,
        isFormData: requestData is FormData,
      );
      print('📤 Enviando datos al backend: $requestData');

      return ApiResponse<Client>.fromJson(response.data, (data) {
        // Handle nested structure: {cliente: {...}}
        if (data.containsKey('cliente')) {
          return Client.fromJson(data['cliente']);
        }
        // Handle direct structure: {...}
        return Client.fromJson(data);
      });
    } on DioException catch (e) {
      return ApiResponse<Client>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<Client>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<ApiResponse<Client>> updateClient(
    int id, {
    String? nombre,
    String? razonSocial,
    String? nit,
    String? email,
    String? telefono,
    double? limiteCredito,
    int? localidadId,
    double? latitud,
    double? longitud,
    bool? activo,
    String? observaciones,
    List<ClientAddress>? direcciones,
    List<VentanaEntregaCliente>? ventanasEntrega,
    List<int>? categoriasIds,
    bool? crearUsuario,
    File? fotoPerfil,
    File? ciAnverso,
    File? ciReverso,
  }) async {
    try {
      /*final data = <String, dynamic>{};
      if (nombre != null) data['nombre'] = nombre;
      if (razonSocial != null) data['razon_social'] = razonSocial;
      if (nit != null) data['nit'] = nit;
      if (email != null) data['email'] = email;
      if (telefono != null) data['telefono'] = telefono;
      if (limiteCredito != null) data['limite_credito'] = limiteCredito;
      if (localidadId != null) data['localidad_id'] = localidadId;
      if (latitud != null) data['latitud'] = latitud;
      if (longitud != null) data['longitud'] = longitud;
      if (activo != null) data['activo'] = activo;
      if (observaciones != null) data['observaciones'] = observaciones;
      if (ventanasEntrega != null)
        data['ventanas_entrega'] = ventanasEntrega
            .map((v) => {
                  'dia_semana': v.diaSemana,
                  'hora_inicio': v.horaInicio,
                  'hora_fin': v.horaFin,
                  'activo': v.activo,
                })
            .toList();
      if (categoriasIds != null) data['categorias_ids'] = categoriasIds;
      if (crearUsuario != null) data['crear_usuario'] = crearUsuario;
      if (direcciones != null)
        data['direcciones'] = direcciones.map((d) => d.toJson()).toList();

      dynamic requestData = data;*/

      // Construir el mapa de datos sólo con campos no nulos para evitar enviar claves con valor null
      final Map<String, dynamic> data = {};
      if (nombre != null) data['nombre'] = nombre;
      if (razonSocial != null) data['razon_social'] = razonSocial;
      if (nit != null) data['nit'] = nit;
      if (email != null) data['email'] = email;
      if (telefono != null) data['telefono'] = telefono;
      if (limiteCredito != null) data['limite_credito'] = limiteCredito;
      if (localidadId != null) data['localidad_id'] = localidadId;

      // Solo enviar coordenadas en nivel principal si NO hay direcciones con coordenadas
      final hasAddressCoords =
          direcciones != null &&
          direcciones.isNotEmpty &&
          direcciones.any((d) => d.latitud != null && d.longitud != null);
      if (latitud != null && !hasAddressCoords) data['latitud'] = latitud;
      if (longitud != null && !hasAddressCoords) data['longitud'] = longitud;

      if (activo != null) data['activo'] = activo;
      if (observaciones != null) data['observaciones'] = observaciones;
      if (direcciones != null) {
        data['direcciones'] = direcciones.map((d) => d.toJson()).toList();
      }
      if (ventanasEntrega != null) {
        data['ventanas_entrega'] = ventanasEntrega
            .map(
              (v) => {
                'dia_semana': v.diaSemana,
                'hora_inicio': v.horaInicio,
                'hora_fin': v.horaFin,
                'activo': v.activo,
              },
            )
            .toList();
      }
      if (categoriasIds != null) data['categorias_ids'] = categoriasIds;
      if (crearUsuario != null) data['crear_usuario'] = crearUsuario;

      dynamic requestData = data;

      debugPrint(
        fotoPerfil != null ? 'Foto perfil presente' : 'Foto perfil nula',
      );

      // Si hay archivos (foto_perfil, ci_anverso, ci_reverso), usar FormData para mantener tipos de datos
      if (fotoPerfil != null || ciAnverso != null || ciReverso != null) {
        final formData = FormData();

        // Agregar campos de texto
        debugPrint(
          'Agregando campos de texto al FormData..................??$nombre',
        );
        if (nombre != null) formData.fields.add(MapEntry('nombre', nombre));
        if (razonSocial != null) {
          formData.fields.add(MapEntry('razon_social', razonSocial));
        }
        if (nit != null) formData.fields.add(MapEntry('nit', nit));
        if (email != null) formData.fields.add(MapEntry('email', email));
        if (telefono != null) {
          formData.fields.add(MapEntry('telefono', telefono));
        }
        if (limiteCredito != null) {
          formData.fields.add(
            MapEntry('limite_credito', limiteCredito.toString()),
          );
        }
        if (localidadId != null) {
          formData.fields.add(MapEntry('localidad_id', localidadId.toString()));
        }
        if (latitud != null) {
          formData.fields.add(MapEntry('latitud', latitud.toString()));
        }
        if (longitud != null) {
          formData.fields.add(MapEntry('longitud', longitud.toString()));
        }
        if (observaciones != null) {
          formData.fields.add(MapEntry('observaciones', observaciones));
        }
        if (crearUsuario != null) {
          formData.fields.add(
            MapEntry('crear_usuario', crearUsuario ? '1' : '0'),
          );
        }

        // Booleans en multipart: enviar como '1'/'0' para compatibilidad con Laravel boolean
        if (activo != null) {
          formData.fields.add(MapEntry('activo', activo ? '1' : '0'));
        }
        print(
          '📤 Enviando activo como string (1/0): ${activo == true ? '1' : '0'}',
        );

        // Solo enviar coordenadas en nivel principal si NO hay direcciones con coordenadas
        final hasAddressCoords =
            direcciones != null &&
            direcciones.isNotEmpty &&
            direcciones.any((d) => d.latitud != null && d.longitud != null);

        if (latitud != null && !hasAddressCoords) {
          formData.fields.add(MapEntry('latitud', latitud.toString()));
        }
        if (longitud != null && !hasAddressCoords) {
          formData.fields.add(MapEntry('longitud', longitud.toString()));
        }

        // Agregar direcciones como campos separados con índices
        if (direcciones != null && direcciones.isNotEmpty) {
          for (int i = 0; i < direcciones.length; i++) {
            final dir = direcciones[i];
            formData.fields.add(
              MapEntry('direcciones[$i][direccion]', dir.direccion),
            );
            if (dir.ciudad != null) {
              formData.fields.add(
                MapEntry('direcciones[$i][ciudad]', dir.ciudad!),
              );
            }
            if (dir.departamento != null) {
              formData.fields.add(
                MapEntry('direcciones[$i][departamento]', dir.departamento!),
              );
            }
            if (dir.codigoPostal != null) {
              formData.fields.add(
                MapEntry('direcciones[$i][codigo_postal]', dir.codigoPostal!),
              );
            }
            formData.fields.add(
              MapEntry(
                'direcciones[$i][es_principal]',
                dir.esPrincipal ? '1' : '0',
              ),
            );
            formData.fields.add(
              MapEntry(
                'direcciones[$i][activa]',
                (dir.activa ?? true) ? '1' : '0',
              ),
            );
            if (dir.observaciones != null) {
              formData.fields.add(
                MapEntry('direcciones[$i][observaciones]', dir.observaciones!),
              );
            }
            if (dir.latitud != null) {
              formData.fields.add(
                MapEntry('direcciones[$i][latitud]', dir.latitud!.toString()),
              );
            }
            if (dir.longitud != null) {
              formData.fields.add(
                MapEntry('direcciones[$i][longitud]', dir.longitud!.toString()),
              );
            }
          }
          print(
            '📤 Enviando ${direcciones.length} direcciones como campos separados',
          );
        }

        // Agregar archivo de foto (si existe)
        if (fotoPerfil != null) {
          debugPrint(
            'Agregando foto de perfil al FormData..................🤢',
          );
          formData.files.add(
            MapEntry(
              'foto_perfil',
              await MultipartFile.fromFile(
                fotoPerfil.path,
                filename: 'profile_photo.jpg',
              ),
            ),
          );
        }
        // Agregar archivos de CI (si existen)
        if (ciAnverso != null) {
          formData.files.add(
            MapEntry(
              'ci_anverso',
              await MultipartFile.fromFile(
                ciAnverso.path,
                filename: 'ci_anverso.jpg',
              ),
            ),
          );
        }
        if (ciReverso != null) {
          formData.files.add(
            MapEntry(
              'ci_reverso',
              await MultipartFile.fromFile(
                ciReverso.path,
                filename: 'ci_reverso.jpg',
              ),
            ),
          );
        }

        // Agregar ventanas_entrega como campos con índices si vienen
        if (ventanasEntrega != null && ventanasEntrega.isNotEmpty) {
          for (int i = 0; i < ventanasEntrega.length; i++) {
            final v = ventanasEntrega[i];
            formData.fields.add(
              MapEntry(
                'ventanas_entrega[$i][dia_semana]',
                v.diaSemana.toString(),
              ),
            );
            formData.fields.add(
              MapEntry('ventanas_entrega[$i][hora_inicio]', v.horaInicio),
            );
            formData.fields.add(
              MapEntry('ventanas_entrega[$i][hora_fin]', v.horaFin),
            );
            formData.fields.add(
              MapEntry('ventanas_entrega[$i][activo]', v.activo ? '1' : '0'),
            );
          }
        }
        // Agregar categorias_ids[] si vienen
        if (categoriasIds != null && categoriasIds.isNotEmpty) {
          for (final idCat in categoriasIds) {
            formData.fields.add(MapEntry('categorias_ids[]', idCat.toString()));
          }
        }

        // Agregar override _method=PUT para que Laravel interprete la petición correctamente
        formData.fields.add(MapEntry('_method', 'PUT'));
        requestData = formData;
        debugPrint(
          '📤 Enviando FormData con archivos y campos (override _method=PUT)',
        );
      }
      // Si estamos enviando FormData, usar POST con _method=PUT (multipart + PUT puede fallar en algunos servidores)
      final Response response;
      if (requestData is FormData) {
        response = await _apiService.post(
          '/clientes/$id',
          data: requestData,
          isFormData: true,
        );
      } else {
        response = await _apiService.put(
          '/clientes/$id',
          data: requestData,
          isFormData: false,
        );
      }
      print('📤 Enviando datos al backend (update): $requestData');

      return ApiResponse<Client>.fromJson(response.data, (data) {
        // Handle nested structure: {cliente: {...}}
        if (data.containsKey('cliente')) {
          return Client.fromJson(data['cliente']);
        }
        // Handle direct structure: {...}
        return Client.fromJson(data);
      });
    } on DioException catch (e) {
      return ApiResponse<Client>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<Client>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<ApiResponse<Null>> deleteClient(int id) async {
    try {
      final response = await _apiService.delete('/clientes/$id');

      return ApiResponse<Null>.fromJson(response.data);
    } on DioException catch (e) {
      return ApiResponse<Null>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<Null>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  // Gestión de direcciones
  Future<ApiResponse<List<ClientAddress>>> getClientAddresses(
    int clientId,
  ) async {
    try {
      final response = await _apiService.get('/clientes/$clientId/direcciones');

      final apiResponse = ApiResponse<List<ClientAddress>>.fromJson(
        response.data,
        ClientAddress.fromJson,
      );

      return apiResponse;
    } on DioException catch (e) {
      return ApiResponse<List<ClientAddress>>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<List<ClientAddress>>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<ApiResponse<ClientAddress>> createClientAddress(
    int clientId, {
    required String direccion,
    String? observaciones,
    String? ciudad,
    String? departamento,
    String? codigoPostal,
    double? latitud,
    double? longitud,
    int? localidadId,
    bool esPrincipal = false,
    bool activa = true,
  }) async {
    try {
      final data = {
        'direccion': direccion,
        'observaciones': observaciones,
        'ciudad': ciudad,
        'departamento': departamento,
        'codigo_postal': codigoPostal,
        'latitud': latitud,
        'longitud': longitud,
        'localidad_id': localidadId,
        'es_principal': esPrincipal,
        'activa': activa,
      };

      final response = await _apiService.post(
        '/clientes/$clientId/direcciones',
        data: data,
      );

      return ApiResponse<ClientAddress>.fromJson(
        response.data,
        ClientAddress.fromJson,
      );
    } on DioException catch (e) {
      return ApiResponse<ClientAddress>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<ClientAddress>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<ApiResponse<ClientAddress>> updateClientAddress(
    int clientId,
    int addressId, {
    String? direccion,
    String? observaciones,
    String? ciudad,
    String? departamento,
    String? codigoPostal,
    double? latitud,
    double? longitud,
    int? localidadId,
    bool? esPrincipal,
    bool? activa,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (direccion != null) data['direccion'] = direccion;
      if (observaciones != null) data['observaciones'] = observaciones;
      if (ciudad != null) data['ciudad'] = ciudad;
      if (departamento != null) data['departamento'] = departamento;
      if (codigoPostal != null) data['codigo_postal'] = codigoPostal;
      if (latitud != null) data['latitud'] = latitud;
      if (longitud != null) data['longitud'] = longitud;
      if (localidadId != null) data['localidad_id'] = localidadId;
      if (esPrincipal != null) data['es_principal'] = esPrincipal;
      if (activa != null) data['activa'] = activa;

      final response = await _apiService.put(
        '/clientes/$clientId/direcciones/$addressId',
        data: data,
      );

      return ApiResponse<ClientAddress>.fromJson(
        response.data,
        ClientAddress.fromJson,
      );
    } on DioException catch (e) {
      return ApiResponse<ClientAddress>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<ClientAddress>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<ApiResponse<Null>> deleteClientAddress(
    int clientId,
    int addressId,
  ) async {
    try {
      final response = await _apiService.delete(
        '/clientes/$clientId/direcciones/$addressId',
      );

      return ApiResponse<Null>.fromJson(response.data);
    } on DioException catch (e) {
      return ApiResponse<Null>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<Null>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<ApiResponse<ClientAddress>> setPrincipalAddress(
    int clientId,
    int addressId,
  ) async {
    try {
      final response = await _apiService.patch(
        '/clientes/$clientId/direcciones/$addressId/principal',
      );

      return ApiResponse<ClientAddress>.fromJson(
        response.data,
        ClientAddress.fromJson,
      );
    } on DioException catch (e) {
      return ApiResponse<ClientAddress>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<ClientAddress>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getClientBalance(
    int clientId,
  ) async {
    try {
      final response = await _apiService.get(
        '/clientes/$clientId/saldo-cuentas',
      );

      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (data) => data,
      );
    } on DioException catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getClientSalesHistory(
    int clientId,
  ) async {
    try {
      final response = await _apiService.get(
        '/clientes/$clientId/historial-ventas',
      );

      final apiResponse = ApiResponse<List<Map<String, dynamic>>>.fromJson(
        response.data,
        (item) => item,
      );

      return apiResponse;
    } on DioException catch (e) {
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  // Gestión de localidades
  Future<ApiResponse<List<Localidad>>> getLocalidades() async {
    try {
      final response = await _apiService.get('/localidades');

      final apiResponse = ApiResponse<List<Localidad>>.fromJson(
        response.data,
        Localidad.fromJson,
      );

      return apiResponse;
    } on DioException catch (e) {
      return ApiResponse<List<Localidad>>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<List<Localidad>>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<ApiResponse<Localidad>> getLocalidad(int id) async {
    try {
      final response = await _apiService.get('/localidades/$id');

      return ApiResponse<Localidad>.fromJson(
        response.data,
        (data) => Localidad.fromJson(data),
      );
    } on DioException catch (e) {
      return ApiResponse<Localidad>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<Localidad>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<ApiResponse<Localidad>> createLocalidad({
    required String nombre,
    required String codigo,
    bool activo = true,
  }) async {
    try {
      final data = {'nombre': nombre, 'codigo': codigo, 'activo': activo};

      final response = await _apiService.post('/localidades', data: data);

      return ApiResponse<Localidad>.fromJson(
        response.data,
        (data) => Localidad.fromJson(data),
      );
    } on DioException catch (e) {
      return ApiResponse<Localidad>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<Localidad>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<ApiResponse<Localidad>> updateLocalidad(
    int id, {
    String? nombre,
    String? codigo,
    bool? activo,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (nombre != null) data['nombre'] = nombre;
      if (codigo != null) data['codigo'] = codigo;
      if (activo != null) data['activo'] = activo;

      final response = await _apiService.put('/localidades/$id', data: data);

      return ApiResponse<Localidad>.fromJson(
        response.data,
        (data) => Localidad.fromJson(data),
      );
    } on DioException catch (e) {
      return ApiResponse<Localidad>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<Localidad>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<ApiResponse<Null>> deleteLocalidad(int id) async {
    try {
      final response = await _apiService.delete('/localidades/$id');

      return ApiResponse<Null>.fromJson(response.data);
    } on DioException catch (e) {
      return ApiResponse<Null>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<Null>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  String _getErrorMessage(DioException e) {
    if (e.response?.data != null) {
      try {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic>) {
          if (errorData.containsKey('message')) {
            return errorData['message'];
          }
          if (errorData.containsKey('error')) {
            return errorData['error'];
          }
        }
      } catch (_) {}
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Tiempo de conexión agotado';
      case DioExceptionType.sendTimeout:
        return 'Tiempo de envío agotado';
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de recepción agotado';
      case DioExceptionType.badResponse:
        return 'Error del servidor: ${e.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'Solicitud cancelada';
      default:
        return 'Error de conexión';
    }
  }

  /// Obtener perfil del cliente autenticado con todas sus direcciones, categorías y ventanas de entrega
  /// GET /clientes/mi-perfil (baseUrl ya incluye /api)
  /// Usa autenticación Bearer token (no requiere permisos especiales)
  Future<ApiResponse<Client>> getClientPerfil() async {
    try {
      final response = await _apiService.get('/clientes/mi-perfil');

      debugPrint('✅ Perfil del cliente obtenido exitosamente');

      return ApiResponse<Client>.fromJson(
        response.data,
        (data) => Client.fromJson(
          data.containsKey('cliente') ? data['cliente'] : data,
        ),
      );
    } on DioException catch (e) {
      debugPrint('❌ Error al obtener perfil: ${_getErrorMessage(e)}');
      return ApiResponse<Client>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      debugPrint('❌ Error inesperado: $e');
      return ApiResponse<Client>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  // Catálogo de categorías de cliente
  Future<ApiResponse<List<CategoriaCliente>>> getCategoriasCliente() async {
    try {
      final response = await _apiService.get('/categorias-cliente');
      final raw = response.data;

      try {
        final success =
            (raw is Map &&
                (raw['success'] == true ||
                    raw['success'] == 1 ||
                    raw['success']?.toString() == 'true'))
            ? true
            : true; // default true if not provided
        final message = (raw is Map && raw['message'] != null)
            ? raw['message'].toString()
            : 'Operación exitosa';
        dynamic payload = (raw is Map) ? raw['data'] : raw;

        List<dynamic>? items;
        if (payload is Map && payload['data'] is List) {
          // Estructura paginada: data: { current_page: 1, data: [...] }
          items = payload['data'] as List;
        } else if (payload is List) {
          // Estructura simple: data: [...]
          items = payload;
        } else {
          items = null;
        }

        final list = items
            ?.whereType<dynamic>()
            .map(
              (e) =>
                  CategoriaCliente.fromJson((e as Map).cast<String, dynamic>()),
            )
            .toList();

        return ApiResponse<List<CategoriaCliente>>(
          success: success,
          message: message,
          data: list,
        );
      } catch (parseError) {
        // Si el parseo manual falla, intentar el genérico como fallback
        try {
          return ApiResponse<List<CategoriaCliente>>.fromJson(
            raw,
            CategoriaCliente.fromJson,
          );
        } catch (_) {
          return ApiResponse<List<CategoriaCliente>>(
            success: false,
            message: 'Error al parsear categorías: ${parseError.toString()}',
            data: null,
          );
        }
      }
    } on DioException catch (e) {
      return ApiResponse<List<CategoriaCliente>>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<List<CategoriaCliente>>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }
}
