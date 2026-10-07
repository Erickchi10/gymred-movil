import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda el token (JWT) cifrado en el celular.
/// Así el socio no tiene que iniciar sesión cada vez que abre la app.
class TokenStorage {
  static const _clave = 'gymred_token';
  final _storage = const FlutterSecureStorage();

  Future<void> guardar(String token) => _storage.write(key: _clave, value: token);

  Future<String?> leer() => _storage.read(key: _clave);

  Future<void> borrar() => _storage.delete(key: _clave);
}
