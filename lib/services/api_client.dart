import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'token_storage.dart';

/// Error con un mensaje listo para mostrarle al usuario.
class ApiException implements Exception {
  final String mensaje;
  final int? status; // código HTTP: 401, 404, etc.
  ApiException(this.mensaje, {this.status});

  @override
  String toString() => mensaje;
}

/// Cliente HTTP que usan todos los servicios.
class ApiClient {
  final TokenStorage tokenStorage;
  late final Dio dio;

  /// Se llama cuando la API responde 401 (token vencido).
  /// Lo vamos a usar para regresar al login automáticamente.
  void Function()? alExpirarSesion;

  ApiClient(this.tokenStorage) {
    dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      sendTimeout: ApiConfig.timeout,
      contentType: 'application/json',
    ));

    dio.interceptors.add(InterceptorsWrapper(
      // Antes de cada petición: pega el token si hay sesión.
      onRequest: (options, handler) async {
        final token = await tokenStorage.leer();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      // Si algo falla con 401 (y no es el login), la sesión ya no sirve.
      onError: (error, handler) {
        final esLogin = error.requestOptions.path.contains('/auth/login');
        if (error.response?.statusCode == 401 && !esLogin) {
          alExpirarSesion?.call();
        }
        handler.next(error);
      },
    ));
  }

  /// Convierte cualquier error en un mensaje claro.
  /// La API (NestJS) responde los errores así:
  /// { "statusCode": 401, "message": "Correo o contrasena incorrectos" }
  /// y a veces "message" es una lista de varios mensajes.
  static ApiException traducirError(Object error) {
    if (error is ApiException) return error;

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return ApiException(
              'El servidor tardó demasiado. Puede estar despertando, intenta de nuevo.');
        case DioExceptionType.connectionError:
          return ApiException('No hay conexión. Revisa tu internet.');
        default:
          break;
      }

      final status = error.response?.statusCode;
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        final m = data['message'];
        final texto = m is List ? m.join('\n') : m.toString();
        return ApiException(texto, status: status);
      }
      return ApiException('Error del servidor (${status ?? 'sin respuesta'}).',
          status: status);
    }

    return ApiException('Ocurrió un error inesperado.');
  }
}
