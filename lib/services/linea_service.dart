import '../models/linea_articulo.dart';
import 'api_service.dart';

class LineaService {
  final ApiService _apiService;

  LineaService(this._apiService);

  Future<List<LineaArticulo>> getLineas() async {
    try {
      final response = await _apiService.dio.get('/AdminPanel/Inventarios/Lineas');

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

      return items.whereType<Map<String, dynamic>>().map(LineaArticulo.fromJson).toList();
    } catch (e) {
      throw Exception('Error al cargar líneas: $e');
    }
  }
}
