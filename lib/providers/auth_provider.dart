import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';

/// Los tres estados posibles de la sesión.
enum EstadoSesion { revisando, sinSesion, conSesion }

/// Controla la sesión del socio. Las pantallas lo "escuchan"
/// y se redibujan solas cuando algo cambia (notifyListeners).
class AuthProvider extends ChangeNotifier {
  final AuthService _auth;
  final TokenStorage _storage;

  EstadoSesion estado = EstadoSesion.revisando;
  Usuario? usuario;
  bool cargando = false;
  String? error;

  AuthProvider(this._auth, this._storage, ApiClient api) {
    // Si la API responde 401 en cualquier pantalla, regresamos al login.
    api.alExpirarSesion = cerrarSesion;
  }

  /// Al abrir la app: si hay un token guardado, revisa que siga sirviendo.
  Future<void> revisarSesion() async {
    final token = await _storage.leer();
    if (token == null) {
      estado = EstadoSesion.sinSesion;
      notifyListeners();
      return;
    }
    try {
      final u = await _auth.perfil();
      if (u.esCliente) {
        usuario = u;
        estado = EstadoSesion.conSesion;
      } else {
        await _storage.borrar();
        estado = EstadoSesion.sinSesion;
      }
    } on ApiException catch (e) {
      if (e.status == 401) await _storage.borrar(); // token vencido
      estado = EstadoSesion.sinSesion;
    }
    notifyListeners();
  }

  /// Inicia sesión. Regresa true si salió bien.
  Future<bool> login(String email, String password) async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      final r = await _auth.login(email, password);
      // La API también deja entrar a dueños; esta app es solo para socios.
      if (!r.usuario.esCliente) {
        error = 'Esta app es para socios. Los dueños usan el panel web.';
        return false;
      }
      await _storage.guardar(r.token);
      usuario = r.usuario;
      estado = EstadoSesion.conSesion;
      return true;
    } on ApiException catch (e) {
      error = e.mensaje;
      return false;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> cerrarSesion() async {
    await _storage.borrar();
    usuario = null;
    estado = EstadoSesion.sinSesion;
    notifyListeners();
  }
}
