import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Ajusta esta URL a la IP de tu servidor donde corre MicrosipAPI
  // Si usas emulador Android: 10.0.2.2
  // Si usas dispositivo real: La IP de tu PC (ej. 192.168.1.x)
  static const String baseUrl = 'http://ferlomi.sytes.net:5200/api'; 
  
  late Dio _dio;
  late SharedPreferences _prefs;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      // Permitir leer respuestas con códigos 4xx (como 409) para poder
      // inspeccionar el cuerpo en Flutter durante la depuración.
      validateStatus: (status) {
        return status != null && status < 500;
      },
    ));

    // Interceptor para agregar Token o ID de usuario si es necesario
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Dio get dio => _dio;
}
