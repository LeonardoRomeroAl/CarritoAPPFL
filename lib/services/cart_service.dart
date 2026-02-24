import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/cart_item.dart';

class CartService {
  final ApiService _apiService;

  CartService(this._apiService);

  Future<int> createCart(int clienteId, int usuarioId) async {
    try {
      final response = await _apiService.dio.post('/carrito/crear', data: {
        'ClienteId': clienteId,
        'Usuario': 'leo',
      });
      return response.data['id'];
    } catch (e) {
      throw Exception('Error creando carrito: $e');
    }
  }

  Future<void> addItem(int cartId, int articuloId, double quantity, double price) async {
    try {
      await _apiService.dio.post('/carrito/$cartId/items', data: {
        'ArticuloId': articuloId,
        'Unidades': quantity,
        'PrecioUnitario': price,
        'PctjeDscto': 0,
        'PrecioTotalNeto': price * quantity,
      });
    } catch (e) {
      throw Exception('Error agregando item: $e');
    }
  }

  Future<List<CartItem>> getCartItems(String usuario) async {
    try {
      final response = await _apiService.dio.get('/carrito/$usuario');
      final List<dynamic> data = response.data;
      return data.map((json) => CartItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error obteniendo carrito: $e');
    }
  }

  Future<void> confirmCart(String usuario) async {
    try {
      await _apiService.dio.post('/carrito/confirmar/$usuario');
    } catch (e) {
      throw Exception('Error confirmando carrito: $e');
    }
  }
  
  
  Future<Map<String, dynamic>> checkout(int clienteId, List<Map<String, dynamic>> items) async {
       try {
        final response = await _apiService.dio.post('/ventasdirectas/crear', data: {
            'ClienteId': clienteId,
            'Usuario': 'leo',
            'Items': items,
        });
        return response.data;
       } catch (e) {
         throw Exception('Error en checkout: $e');
       }
  }

  /// Checkout usando el nuevo flujo de venta directa.
  ///
  /// 1) Crea una venta directa en AdminPanel Ventas
  Future<Map<String, dynamic>> checkoutSimulado(
    int clienteId,
    List<Map<String, dynamic>> items,
    {
      String destino = 'R', // 'R' o 'F'
      int? sucursalId,
      String? rfc,
      String? usoCfdi,
      String? regimenFiscal,
    }
  ) async {
    try {
      final tipo = destino.toUpperCase() == 'F' ? 'FAC' : 'REM';
      final data = <String, dynamic>{
        'tipo': tipo,
        'clienteId': clienteId,
        'sucursalId': sucursalId ?? 384,
        'almacenId': 19,
        'ivaPct': 16.0,
        'detalle': items,
      };

      if (tipo == 'FAC') {
        if (rfc != null && rfc.isNotEmpty) {
          data['rfc'] = rfc;
        }
        if (usoCfdi != null && usoCfdi.isNotEmpty) {
          data['usoCfdi'] = usoCfdi;
        }
        // El backend requiere siempre un régimen fiscal cuando tipo es FAC.
        // Si no se envía explícito desde la app, usamos un código por defecto.
        final String regimen =
            (regimenFiscal != null && regimenFiscal.isNotEmpty) ? regimenFiscal : '612';
        data['regimenFiscal'] = regimen;
      }

      // Log del payload que se envía al endpoint de ventas para depuración.
      debugPrint('CheckoutSimulado - payload /AdminPanel/Ventas:');
      debugPrint(data.toString());

      final ventaResponse = await _apiService.dio.post(
        '/AdminPanel/Ventas',
        data: data,
      );

      if (ventaResponse.statusCode != 200 && ventaResponse.statusCode != 201) {
        debugPrint('CheckoutSimulado - error creando venta directa:');
        debugPrint('  Status code: ${ventaResponse.statusCode}');
        debugPrint('  Data: ${ventaResponse.data}');
        throw Exception('Error creando venta: ${ventaResponse.data}');
      }

      final ventaData = ventaResponse.data as Map<String, dynamic>;

      return {
        'venta': ventaData,
      };
    } catch (e) {
      if (e is DioException) {
        debugPrint('CheckoutSimulado DioException:');
        debugPrint('  Status code: ${e.response?.statusCode}');
        debugPrint('  Data: ${e.response?.data}');
      } else {
        debugPrint('CheckoutSimulado error no-Dio: $e');
      }

      throw Exception('Error en checkout simulado: $e');
    }
  }
  
  Future<List<dynamic>> getHistorial(int clienteId) async {
    try {
      final response = await _apiService.dio.get('/ventasdirectas/historial/$clienteId');

      if (response.statusCode != null && response.statusCode! >= 400) {
        throw Exception('Error HTTP ${response.statusCode}: ${response.data}');
      }

      final data = response.data;

      // La API puede devolver directamente una lista o un objeto que contiene la lista.
      if (data is List) {
        return data;
      }

      if (data is Map<String, dynamic>) {
        // Intenta encontrar alguna propiedad tipo lista común (items, resultado, data, historial, etc.)
        for (final key in ['items', 'resultado', 'data', 'historial']) {
          final value = data[key];
          if (value is List) {
            return value;
          }
        }

        // Como último recurso, devolvemos una lista con el propio mapa
        return [data];
      }

      // Si no es ni lista ni mapa, lo envolvemos en una lista para no romper la UI
      return [data];
    } catch (e) {
      throw Exception('Error obteniendo historial: $e');
    }
  }
 
  Future<List<dynamic>> getDetalleVenta(int ventaId) async {
    try {
      final response = await _apiService.dio.get('/ventasdirectas/detalle/$ventaId');
      final data = response.data;

      if (data is List) {
        return data;
      }

      if (data is Map<String, dynamic>) {
        // Si por alguna razón viene envuelto en un objeto, intentamos extraer una lista
        for (final key in ['items', 'detalle', 'data']) {
          final value = data[key];
          if (value is List) return value;
        }
        return [data];
      }

      return [data];
    } catch (e) {
      throw Exception('Error obteniendo detalle de venta: $e');
    }
  }
  
  Future<void> confirmPayment(String reference) async {
       // Ya no es necesario con el nuevo endpoint
       return;
  }

  Future<Map<String, dynamic>> crearCotizacionCarritoCheckout(
    int clienteId,
    List<Map<String, dynamic>> items,
    {
      int? sucursalId,
      int? almacenId,
      String? usuario,
      String? descripcion,
    }
  ) async {
    try {
      final data = <String, dynamic>{
        'clienteId': clienteId,
        if (sucursalId != null) 'sucursalId': sucursalId,
        if (almacenId != null) 'almacenId': almacenId,
        if (usuario != null) 'usuario': usuario,
        if (descripcion != null) 'descripcion': descripcion,
        'items': items,
      };

      final response = await _apiService.dio.post(
        '/carrito-checkout/cotizaciones',
        data: data,
      );

      if (response.statusCode != 200) {
        throw Exception('Error creando cotización: ${response.data}');
      }

      final body = response.data;
      if (body is Map<String, dynamic>) return body;
      return Map<String, dynamic>.from(body as Map);
    } catch (e) {
      throw Exception('Error creando cotización: $e');
    }
  }

  Future<Map<String, dynamic>> crearPreferenceMercadoPago({
    required int cotizacionId,
    required String destino,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/carrito-checkout/pagos/mercadopago/preference',
        data: {
          'cotizacionId': cotizacionId,
          'destino': destino,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Error creando preference: ${response.data}');
      }

      final body = response.data;
      if (body is Map<String, dynamic>) return body;
      return Map<String, dynamic>.from(body as Map);
    } catch (e) {
      throw Exception('Error creando preference: $e');
    }
  }

  Future<Map<String, dynamic>> obtenerResultadoMercadoPago(int cotizacionId) async {
    try {
      final response = await _apiService.dio.get(
        '/carrito-checkout/pagos/mercadopago/resultado/$cotizacionId',
      );

      if (response.statusCode != 200) {
        throw Exception('Error consultando resultado: ${response.data}');
      }

      final body = response.data;
      if (body is Map<String, dynamic>) return body;
      return Map<String, dynamic>.from(body as Map);
    } catch (e) {
      throw Exception('Error consultando resultado: $e');
    }
  }

  Future<Map<String, dynamic>> crearCargoOpenpayTarjeta({
    required int cotizacionId,
    required String destino,
    required String tokenId,
    required String deviceSessionId,
    String? customerEmail,
    String? customerPhone,
    String? description,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/carrito-checkout/pagos/openpay/cargo/tarjeta',
        data: {
          'cotizacionId': cotizacionId,
          'destino': destino,
          'tokenId': tokenId,
          'deviceSessionId': deviceSessionId,
          if (customerEmail != null) 'customerEmail': customerEmail,
          if (customerPhone != null) 'customerPhone': customerPhone,
          if (description != null) 'description': description,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Error creando cargo Openpay (tarjeta): ${response.data}');
      }

      final body = response.data;
      if (body is Map<String, dynamic>) return body;
      return Map<String, dynamic>.from(body as Map);
    } catch (e) {
      throw Exception('Error creando cargo Openpay (tarjeta): $e');
    }
  }

  Future<Map<String, dynamic>> crearCargoOpenpaySpei({
    required int cotizacionId,
    required String destino,
    String? customerEmail,
    String? customerPhone,
    String? description,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/carrito-checkout/pagos/openpay/cargo/spei',
        data: {
          'cotizacionId': cotizacionId,
          'destino': destino,
          if (customerEmail != null) 'customerEmail': customerEmail,
          if (customerPhone != null) 'customerPhone': customerPhone,
          if (description != null) 'description': description,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Error creando cargo Openpay (SPEI): ${response.data}');
      }

      final body = response.data;
      if (body is Map<String, dynamic>) return body;
      return Map<String, dynamic>.from(body as Map);
    } catch (e) {
      throw Exception('Error creando cargo Openpay (SPEI): $e');
    }
  }

  Future<Map<String, dynamic>> obtenerResultadoOpenpay(int cotizacionId) async {
    try {
      final response = await _apiService.dio.get(
        '/carrito-checkout/pagos/openpay/resultado/$cotizacionId',
      );

      if (response.statusCode != 200) {
        throw Exception('Error consultando resultado Openpay: ${response.data}');
      }

      final body = response.data;
      if (body is Map<String, dynamic>) return body;
      return Map<String, dynamic>.from(body as Map);
    } catch (e) {
      throw Exception('Error consultando resultado Openpay: $e');
    }
  }
}
