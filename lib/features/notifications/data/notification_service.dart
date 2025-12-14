import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:developer';

/// Manejador para mensajes en segundo plano (Background)
/// Debe ser una función top-level o estática.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log('Mensaje en segundo plano recibido: ${message.messageId}');
}

class NotificationService {
  // Singleton para acceder fácilmente desde cualquier lugar
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Inicializa el servicio de notificaciones
  Future<void> initialize() async {
    // 1. Solicitar permisos (Crítico para iOS y Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('Permiso de notificaciones concedido');
    } else {
      log('Permiso de notificaciones denegado');
      return; // No continuamos si no hay permisos
    }

    // 2. Configurar notificaciones locales (para mostrar alertas cuando la app está abierta)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración para iOS (Darwin)
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _localNotifications.initialize(initializationSettings);

    // 3. Manejador de Background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Manejador de Foreground (App abierta)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Mensaje en primer plano recibido: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // 5. Obtener el Token FCM para pruebas
    String? token = await _messaging.getToken();
    log('FCM TOKEN: $token');
    // En una app real, aquí enviarías el token a tu backend
  }

  /// Muestra una notificación local cuando llega un mensaje push y la app está abierta
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // channelId
            'Notificaciones Importantes', // channelName
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    }
  }
}
