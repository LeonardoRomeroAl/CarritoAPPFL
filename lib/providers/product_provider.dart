import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../models/product.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService;
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  ProductProvider(this._productService);

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProducts({int? lineaArticuloId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _productService.getProducts(lineaArticuloId: lineaArticuloId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
