import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  User? _user;
  bool _isLoading = false;

  AuthProvider(this._apiService);

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  ApiService get apiService => _apiService;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.dio.post('/auth/login', data: {
        'username': username,
        'password': password
      });

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['token'];

        // Guardar token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        // El backend devuelve "usuario" como objeto UsuarioDb con propiedades:
        // apiUsuarioId, usuario, passwordHash, rol, activo, clienteId
        final usuarioData = data['usuario'] as Map<String, dynamic>;

        _user = User(
          id: usuarioData['apiUsuarioId'] as int,
          username: (usuarioData['usuario'] ?? usuarioData['nombreUsuario'] ?? '').toString(),
          clienteId: (usuarioData['clienteId'] ?? 0) as int,
        );
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint("Login error: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
