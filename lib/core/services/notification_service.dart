import 'dart:ui' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Servicio de notificaciones locales — KETORA
/// Maneja: ayuno intermitente, agua, motivación diaria
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // IDs únicos por tipo de notificación
  static const int _idAyuno12h     = 100;
  static const int _idAyuno14h     = 101;
  static const int _idAyuno16h     = 102;
  static const int _idAyuno18h     = 103;
  static const int _idAyuno24h     = 104;
  static const int _idAgua         = 200;
  static const int _idMotiDiaria   = 300;

  Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotifTap,
    );

    // Solicitar permisos Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void _onNotifTap(NotificationResponse response) {
    // TODO: navegar a pantalla relevante según payload
  }

  // ── Configuraciones de canal Android ──────────────────────────────────────

  static const _canalAyuno = AndroidNotificationDetails(
    'ketora_ayuno',
    'Ayuno intermitente',
    channelDescription: 'Notificaciones de hitos del ayuno',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    color: Color(0xFF16A34A),
  );

  static const _canalAgua = AndroidNotificationDetails(
    'ketora_agua',
    'Recordatorio de agua',
    channelDescription: 'Recordatorios para hidratarse',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    icon: '@mipmap/ic_launcher',
  );

  static const _canalMoti = AndroidNotificationDetails(
    'ketora_motivacion',
    'Motivación diaria',
    channelDescription: 'Mensajes motivacionales de GEM',
    importance: Importance.low,
    priority: Priority.low,
    icon: '@mipmap/ic_launcher',
  );

  // ── Notificaciones de hitos de ayuno ──────────────────────────────────────

  /// Programa todas las notificaciones del ayuno cuando el usuario lo inicia
  Future<void> programarAyuno(DateTime inicio) async {
    await cancelarAyuno(); // Limpiar anteriores

    final milestones = [
      _AyunoMilestone(
        id: _idAyuno12h,
        horas: 12,
        titulo: '⚡ ¡Cetosis iniciando!',
        cuerpo: 'Tu cuerpo lleva 12 horas en ayuno — la cetosis está comenzando. ¡Vas increíble!',
      ),
      _AyunoMilestone(
        id: _idAyuno14h,
        horas: 14,
        titulo: '🔥 ¡Cetosis óptima!',
        cuerpo: '14 horas de ayuno. Tu cuerpo está quemando grasa de manera eficiente. ¡Sigue así!',
      ),
      _AyunoMilestone(
        id: _idAyuno16h,
        horas: 16,
        titulo: '🏆 ¡META ALCANZADA! Ayuno 16:8',
        cuerpo: '¡Completaste tu ayuno de 16 horas! Ya puedes romper el ayuno cuando quieras. 🥑',
      ),
      _AyunoMilestone(
        id: _idAyuno18h,
        horas: 18,
        titulo: '💪 ¡18 horas! Nivel élite',
        cuerpo: 'Superaste tu meta. 18 horas en ayuno potencia la autofagia. Tu cuerpo se está renovando.',
      ),
      _AyunoMilestone(
        id: _idAyuno24h,
        horas: 24,
        titulo: '🌟 ¡24 horas! Eres imparable',
        cuerpo: 'Un día completo de ayuno. La autofagia está al máximo. Recuerda hidratarte bien.',
      ),
    ];

    for (final m in milestones) {
      final horaNotif = inicio.add(Duration(hours: m.horas));
      if (horaNotif.isAfter(DateTime.now())) {
        await _plugin.zonedSchedule(
          m.id,
          m.titulo,
          m.cuerpo,
          tz.TZDateTime.from(horaNotif, tz.local),
          NotificationDetails(android: _canalAyuno),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'ayuno_${m.horas}h',
        );
      }
    }
  }

  /// Cancela todas las notificaciones de ayuno activas
  Future<void> cancelarAyuno() async {
    for (final id in [_idAyuno12h, _idAyuno14h, _idAyuno16h, _idAyuno18h, _idAyuno24h]) {
      await _plugin.cancel(id);
    }
  }

  // ── Recordatorio de agua ───────────────────────────────────────────────────

  /// Programa recordatorios de agua cada 2 horas entre 8am y 8pm
  Future<void> programarRecordatoriosAgua() async {
    await _plugin.cancel(_idAgua);

    // Usamos notificación periódica (cada 2h aprox usando scheduled)
    final List<String> mensajes = [
      '💧 ¿Ya tomaste agua? Recuerda hidratarte cada 2 horas en keto.',
      '💧 El agua ayuda a eliminar los cuerpos cetónicos. ¡Bebe un vaso!',
      '💧 Hidratación keto: 2.5L diarios. ¿Cómo vas?',
      '💧 Electrolitos + agua = clave del éxito keto. ¡Toma un vaso ahora!',
    ];

    final now = DateTime.now();
    int counter = 0;
    for (int hora = 8; hora <= 20; hora += 2) {
      final notifTime = DateTime(now.year, now.month, now.day, hora);
      if (notifTime.isAfter(now)) {
        await _plugin.zonedSchedule(
          _idAgua + counter,
          'KETORA · Hidratación',
          mensajes[counter % mensajes.length],
          tz.TZDateTime.from(notifTime, tz.local),
          NotificationDetails(android: _canalAgua),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'agua',
        );
        counter++;
      }
    }
  }

  // ── Motivación diaria ──────────────────────────────────────────────────────

  static const List<String> _frasesDiarias = [
    'Tu cuerpo tiene un superpoder que aún no conoce — tú lo estás activando. 🔥',
    'Cada día keto es un paso hacia la mejor versión de ti. 💪',
    'La keto gripe ya pasó (o pasará). Al otro lado está la energía real. ⚡',
    'Tu hígado está convirtiendo grasa en combustible ahora mismo. ¡Mágico! 🥑',
    'Los primeros 21 días son los más difíciles. Después, keto se vuelve tu estilo de vida.',
    'Cada día que mantienes la keto te acerca más a tu meta. ¡Sigue adelante! 🎯',
    'Un plato keto bien hecho es el mejor regalo que le puedes dar a tu cuerpo.',
    'La cetosis no se toma días libres. Tú tampoco. 🏆',
  ];

  Future<void> programarMotivacionDiaria({int hora = 8, int minuto = 30}) async {
    await _plugin.cancel(_idMotiDiaria);

    final now = DateTime.now();
    var notifTime = DateTime(now.year, now.month, now.day, hora, minuto);
    if (notifTime.isBefore(now)) {
      notifTime = notifTime.add(const Duration(days: 1));
    }

    final fraseIdx = notifTime.day % _frasesDiarias.length;

    await _plugin.zonedSchedule(
      _idMotiDiaria,
      'GEM dice: ¡Buenos días! 🌿',
      _frasesDiarias[fraseIdx],
      tz.TZDateTime.from(notifTime, tz.local),
      NotificationDetails(android: _canalMoti),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'motivacion',
    );
  }

  // ── Utilitario: mostrar notificación inmediata (para testing) ──────────────

  Future<void> mostrarInmediata({
    required String titulo,
    required String cuerpo,
    String payload = '',
  }) async {
    await _plugin.show(
      999,
      titulo,
      cuerpo,
      NotificationDetails(android: _canalAyuno),
      payload: payload,
    );
  }

  Future<void> cancelarTodas() async {
    await _plugin.cancelAll();
  }
}

class _AyunoMilestone {
  final int id;
  final int horas;
  final String titulo;
  final String cuerpo;
  const _AyunoMilestone({
    required this.id,
    required this.horas,
    required this.titulo,
    required this.cuerpo,
  });
}
