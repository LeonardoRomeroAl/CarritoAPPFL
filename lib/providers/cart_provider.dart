import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/cart_service.dart';
import '../models/product.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService;
  final List<CartItemLocal> _items = [];
  bool _isLoading = false;

  CartProvider(this._cartService) {
    _initFromPrefs();
  }

  Future<void> _initFromPrefs() async {
    await _loadFromPrefs();
    notifyListeners();
  }

  List<CartItemLocal> get items => _items;
  bool get isLoading => _isLoading;

  // -------------------------------------------------
  // Añadir producto al carrito local
  // -------------------------------------------------
  void addToCart(Product product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItemLocal(product: product, quantity: quantity));
    }

    _saveToPrefs();
    notifyListeners();
  }

  // -------------------------------------------------
  // Remover producto
  // -------------------------------------------------
  void removeItem(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _saveToPrefs();
    notifyListeners();
  }

  // -------------------------------------------------
  // Actualizar cantidad
  // -------------------------------------------------
  void updateQuantity(int productId, int newQuantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (newQuantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = newQuantity;
      }
      _saveToPrefs();
      notifyListeners();
    }
  }

  // -------------------------------------------------
  // Calcular total
  // -------------------------------------------------
  double get total {
    return _items.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
  }

  // -------------------------------------------------
  // Checkout directo (crea venta en Microsip)
  // -------------------------------------------------
  Future<Map<String, dynamic>> checkout(int clienteId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Convertir items locales a formato API
      final itemsApi = _items.map((item) => {
        'ArticuloId': item.product.id,
        'Cantidad': item.quantity,
        'PrecioUnitario': item.product.price,
      }).toList();

      final result = await _cartService.checkout(clienteId, itemsApi);
      
      // Limpiar carrito después de venta exitosa
      _items.clear();
      _saveToPrefs();
      
      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // -------------------------------------------------
  // Checkout nuevo: cotización + pago simulado
  // -------------------------------------------------
  Future<Map<String, dynamic>> checkoutSimulado(
    int clienteId, {
    String destino = 'R',
    String? rfc,
    String? usoCfdi,
    String? regimenFiscal,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final itemsApi = _items.map((item) => {
        'articuloId': item.product.id,
        'unidades': item.quantity.toDouble(),
        'precioUnitario': item.product.price,
        'descuentoPct': 0.0,
      }).toList();

      final result = await _cartService.checkoutSimulado(
        clienteId,
        itemsApi,
        destino: destino,
        rfc: rfc,
        usoCfdi: usoCfdi,
        regimenFiscal: regimenFiscal,
      );

      _items.clear();
      _saveToPrefs();

      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // -------------------------------------------------
  // Obtener historial de compras
  // -------------------------------------------------
  Future<List<dynamic>> getHistorial(int clienteId) async {
    return await _cartService.getHistorial(clienteId);
  }

  // -------------------------------------------------
  // Obtener detalle de una venta
  // -------------------------------------------------
  Future<List<dynamic>> getDetalleVenta(int ventaId) async {
    return await _cartService.getDetalleVenta(ventaId);
  }

  // -------------------------------------------------
  // Limpiar carrito
  // -------------------------------------------------
  void clear() {
    _items.clear();
    _saveToPrefs();
    notifyListeners();
  }
}

// Modelo local simple para items del carrito
class CartItemLocal {
  final Product product;
  int quantity;

  CartItemLocal({required this.product, required this.quantity});

  Map<String, dynamic> toMap() {
    return {
      'product': {
        'id': product.id,
        'name': product.name,
        'price': product.price,
        'stock': product.stock,
        'lineaArticuloId': product.lineaArticuloId,
      },
      'quantity': quantity,
    };
  }

  factory CartItemLocal.fromMap(Map<String, dynamic> map) {
    final productMap = map['product'] as Map<String, dynamic>;
    return CartItemLocal(
      product: Product(
        id: productMap['id'] as int,
        name: productMap['name'] as String,
        price: (productMap['price'] as num).toDouble(),
        stock: (productMap['stock'] as num).toInt(),
        lineaArticuloId: (productMap['lineaArticuloId'] is int)
            ? productMap['lineaArticuloId'] as int
            : int.tryParse(productMap['lineaArticuloId']?.toString() ?? ''),
      ),
      quantity: (map['quantity'] as num).toInt(),
    );
  }
}

// -------------------------------------------------
// Persistencia local del carrito
// -------------------------------------------------
extension _CartPersistence on CartProvider {
  static const _prefsKey = 'cart_items_v1';

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return;
      }

      final List<dynamic> list = json.decode(jsonString) as List<dynamic>;
      _items
        ..clear()
        ..addAll(
          list
              .whereType<Map<String, dynamic>>()
              .map((m) => CartItemLocal.fromMap(m))
              .toList(),
        );
    } catch (_) {
      // Si hay algún error de parseo, simplemente empezamos con carrito vacío.
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _items.map((e) => e.toMap()).toList();
      final jsonString = json.encode(list);
      await prefs.setString(_prefsKey, jsonString);
    } catch (_) {
      // No bloquear la app si falla el guardado local.
    }
  }
}
