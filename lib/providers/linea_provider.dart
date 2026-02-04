import 'package:flutter/material.dart';

import '../models/linea_articulo.dart';
import '../services/linea_service.dart';

class LineaProvider with ChangeNotifier {
  final LineaService _lineaService;

  List<LineaArticulo> _lineas = [];
  bool _isLoading = false;
  String? _error;

  LineaProvider(this._lineaService);

  List<LineaArticulo> get lineas => _lineas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchLineas() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _lineas = await _lineaService.getLineas();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
