import '../models/product.dart';
import 'api_service.dart';

class ProductService {
  final ApiService _apiService;

  ProductService(this._apiService);

  Future<List<Product>> getProducts({int? lineaArticuloId}) async {
    try {
      // Endpoint dedicado que ya devuelve precio + existencia.
      // El backend acepta cualquier almacén vía query param; aquí usamos 19.
      // GET /api/Inventarios/PreciosConExistencia?almacenId=19
      final queryParameters = <String, dynamic>{
        'almacenId': 19,
      };

      final String path;
      if (lineaArticuloId != null) {
        path = '/Inventarios/PreciosConExistenciaPorLinea';
        queryParameters['lineaArticuloId'] = lineaArticuloId;
      } else {
        path = '/Inventarios/PreciosConExistencia';
      }

      final response = await _apiService.dio.get(
        path,
        queryParameters: queryParameters,
      );

      if (response.statusCode != 200) {
        return [];
      }

      final dynamic data = response.data;
      List<dynamic> items;

      if (data is List) {
        items = data;
      } else if (data is Map<String, dynamic> && data['items'] is List) {
        items = data['items'] as List<dynamic>;
      } else {
        items = const [];
      }

      return items
          .whereType<Map<String, dynamic>>()
          .map((json) {
            final id = json['articuloId'] ?? json['ArticuloId'];
            final name = json['descripcion'] ?? json['Descripcion'] ?? '';
            final price = json['precio'] ?? json['Precio'] ?? 0;
            final existencia = json['existencia'] ?? json['Existencia'] ?? 0;
            final lineaArticuloId = json['lineaArticuloId'] ?? json['LineaArticuloId'];

            return Product(
              id: id is int ? id : int.tryParse(id.toString()) ?? 0,
              name: name.toString(),
              price: (price is num) ? price.toDouble() : 0.0,
              stock: (existencia is num) ? existencia.toInt() : 0,
              lineaArticuloId: lineaArticuloId is int
                  ? lineaArticuloId
                  : int.tryParse(lineaArticuloId?.toString() ?? ''),
            );
          })
          .toList();
    } catch (e) {
      throw Exception('Error al cargar productos: $e');
    }
  }
}
