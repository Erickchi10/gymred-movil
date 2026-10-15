import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Pide permiso de ubicación y regresa la posición actual.
/// Regresa null si el GPS está apagado, no hay permiso o tarda demasiado.
class UbicacionService {
  Future<Position?> posicionActual() async {
    try {
      final activo = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 15));
      debugPrint('UBICACION 1 - servicio activo: $activo');
      if (!activo) return null;

      var permiso = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 15));
      debugPrint('UBICACION 2 - permiso: $permiso');
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        debugPrint('UBICACION 3 - permiso tras pedirlo: $permiso');
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        return null;
      }

      final ultima = await Geolocator.getLastKnownPosition();
      debugPrint('UBICACION 4 - ultima conocida: $ultima');
      if (ultima != null) return ultima;

      final actual = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 8));
      debugPrint('UBICACION 5 - posicion actual: $actual');
      return actual;
    } catch (e) {
      debugPrint('UBICACION ERROR: $e');
      return null;
    }
  }
}

