import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Avisos del sistema para el vencimiento de la suscripción.
class NotificacionesService {
  NotificacionesService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _iniciado = false;
  static const _claveUltimoAviso = 'ultimo_aviso_vencimiento';

  /// Prepara las notificaciones y pide el permiso (Android 13 o superior).
  static Future<void> iniciar() async {
    if (_iniciado) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _iniciado = true;
  }

  /// Muestra el aviso como máximo una vez al día.
  /// Si el permiso se niega o algo falla, la app sigue funcionando.
  static Future<void> avisarVencimiento(int dias) async {
    try {
      await iniciar();
      final prefs = await SharedPreferences.getInstance();
      final hoy = _claveDia(DateTime.now());
      if (prefs.getString(_claveUltimoAviso) == hoy) return;

      final cuando = dias <= 0
          ? 'Tu suscripción vence hoy.'
          : 'Tu suscripción vence en $dias ${dias == 1 ? 'día' : 'días'}.';

      await _plugin.show(
        1,
        'Gymred',
        '$cuando Renuévala para no perder el acceso.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'vencimiento',
            'Vencimiento de suscripción',
            channelDescription: 'Avisa cuando tu plan está por vencer',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
      await prefs.setString(_claveUltimoAviso, hoy);
    } catch (_) {
      // Sin permiso o con error del sistema: no se muestra el aviso.
    }
  }

  static String _claveDia(DateTime f) => '${f.year}-${f.month}-${f.day}';
}
