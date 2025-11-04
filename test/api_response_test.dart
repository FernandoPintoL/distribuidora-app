import 'package:flutter_test/flutter_test.dart';
import '../lib/models/api_response.dart';
import '../lib/models/localidad.dart';
import '../lib/models/client.dart';

void main() {
  test('ApiResponse should parse localidades list correctly', () {
    // Simular respuesta de la API
    final jsonResponse = {
      'success': true,
      'message': 'Operación exitosa',
      'data': [
        {
          'id': 3,
          'nombre': 'Arroyo Concepción',
          'codigo': 'AC',
          'activo': true,
        },
        {
          'id': 7,
          'nombre': 'Carmen Rivero Tórrez',
          'codigo': 'CRT',
          'activo': true,
        },
        {'id': 4, 'nombre': 'Paradero', 'codigo': 'PRD', 'activo': true},
      ],
    };

    // Parsear la respuesta
    final apiResponse = ApiResponse<List<Localidad>>.fromJson(
      jsonResponse,
      (item) => Localidad.fromJson(item),
    );

    // Verificar que se parseó correctamente
    expect(apiResponse.success, true);
    expect(apiResponse.message, 'Operación exitosa');
    expect(apiResponse.data, isNotNull);
    expect(apiResponse.data!.length, 3);

    // Verificar el primer elemento
    final firstLocalidad = apiResponse.data![0];
    expect(firstLocalidad.id, 3);
    expect(firstLocalidad.nombre, 'Arroyo Concepción');
    expect(firstLocalidad.codigo, 'AC');
    expect(firstLocalidad.activo, true);

    print('✅ Test passed: ApiResponse parsed localidades correctly');
  });

  test('ApiResponse should parse clients list correctly', () {
    final jsonResponse = {
      'success': true,
      'message': 'Operación exitosa',
      'data': [
        {
          'id': 1,
          'nombre': 'Juan Pérez',
          'nit': '12345678',
          'telefono': '0987654321',
          'email': 'juan@example.com',
          'activo': true,
        },
        {
          'id': 2,
          'nombre': 'María García',
          'nit': '87654321',
          'telefono': '0987654322',
          'email': 'maria@example.com',
          'activo': true,
        },
      ],
    };

    final apiResponse = ApiResponse<List<Client>>.fromJson(
      jsonResponse,
      (item) => Client.fromJson(item),
    );

    expect(apiResponse.success, true);
    expect(apiResponse.message, 'Operación exitosa');
    expect(apiResponse.data, isNotNull);
    expect(apiResponse.data!.length, 2);

    final firstClient = apiResponse.data![0];
    expect(firstClient.id, 1);
    expect(firstClient.nombre, 'Juan Pérez');
    expect(firstClient.nit, '12345678');

    print('✅ Test passed: ApiResponse parsed clients correctly');
  });
}
