import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificacionesService {
  NotificacionesService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _iniciado = false;

  static const _idProgramado = 1;
  static const _idAhora = 2;
  static const _claveUltimoAviso = 'ultimo_aviso_vencimiento';
  static const _zona = 'America/Merida';

  static const _detalles = NotificationDetails(
    android: AndroidNotificationDetails(
      'vencimiento',
      'Vencimiento de suscripción',
      channelDescription: 'Avisa cuando tu plan está por vencer',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  static Future<void> iniciar() async {
    if (_iniciado) return;
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    final implementacion = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await implementacion?.requestNotificationsPermission();
    await implementacion?.requestExactAlarmsPermission();
    _iniciado = true;
  }

  /// Llamar cuando hay una suscripción activa. Si el plan ya está dentro de
  /// los 3 días, muestra el aviso ahora (una vez al día). Si todavía no,
  /// programa el aviso para las 9:00 am de tres días antes del vencimiento.
  static Future<void> programarVencimiento(DateTime fechaFin) async {
    try {
      await iniciar();
      await _plugin.cancel(_idProgramado);

      final dias = _diasHasta(fechaFin);
      if (dias <= 3) {
        await _mostrarAhora(dias);
        return;
      }

      final loc = tz.getLocation(_zona);
      final dia = DateTime(fechaFin.year, fechaFin.month, fechaFin.day - 3);
      final cuando = tz.TZDateTime(loc, dia.year, dia.month, dia.day, 9);

      if (cuando.isAfter(tz.TZDateTime.now(loc))) {
        await _plugin.zonedSchedule(
          _idProgramado,
          'Gymred',
          'Tu suscripción vence en 3 días. Renuévala para no perder el acceso.',
          cuando,
          _detalles,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        debugPrint('Aviso programado para $cuando');
      }
    } catch (e) {
      debugPrint('No se programó el aviso: $e');
    }
  }

  static Future<void> cancelar() async {
    try {
      await _plugin.cancel(_idProgramado);
      await _plugin.cancel(_idAhora);
    } catch (e) {
      debugPrint('No se canceló el aviso: $e');
    }
  }

  static Future<void> _mostrarAhora(int dias) async {
    final prefs = await SharedPreferences.getInstance();
    final hoy = _claveDia(DateTime.now());
    if (prefs.getString(_claveUltimoAviso) == hoy) return;

    final cuando = dias <= 0
        ? 'vence hoy'
        : dias == 1
            ? 'vence mañana'
            : 'vence en $dias días';

    await _plugin.show(
      _idAhora,
      'Gymred',
      'Tu suscripción $cuando. Renuévala para no perder el acceso.',
      _detalles,
    );
    await prefs.setString(_claveUltimoAviso, hoy);
  }

  static int _diasHasta(DateTime fecha) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final fin = DateTime(fecha.year, fecha.month, fecha.day);
    return fin.difference(hoy).inDays;
  }

  static String _claveDia(DateTime d) => '${d.year}-${d.month}-${d.day}';
}