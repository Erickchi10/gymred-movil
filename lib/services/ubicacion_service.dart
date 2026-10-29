import 'package:geolocator/geolocator.dart';

/// Pide permiso de ubicación y regresa la posición actual.
/// Regresa null si el GPS está apagado, no hay permiso o tarda demasiado.
class UbicacionService {
  Future<Position?> posicionActual() async {
    try {
      final activo = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 15));
      if (!activo) return null;

      var permiso = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 15));
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        return null;
      }

      final ultima = await Geolocator.getLastKnownPosition();
      if (ultima != null) return ultima;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      return null;
    }
  }
}