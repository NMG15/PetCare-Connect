import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Maneja mensajes FCM recibidos en segundo plano.
@pragma('vm:entry-point')
Future<void> petCareFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp();
}

/// Registra el manejador global de mensajes en segundo plano.
void registerPetCareCloudBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(
    petCareFirebaseMessagingBackgroundHandler,
  );
}

/// Gestión de notificaciones push mediante Firebase Cloud Messaging.
class PetCareCloudMessaging {
  PetCareCloudMessaging._();
  static final PetCareCloudMessaging instance = PetCareCloudMessaging._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  bool _initialized = false;

  static const AndroidNotificationChannel _cloudChannel =
      AndroidNotificationChannel(
    'petcare_cloud_v1',
    'Avisos en la nube',
    description: 'Notificaciones push de PetCare Connect mediante Firebase',
    importance: Importance.high,
  );

  static const NotificationDetails _cloudDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'petcare_cloud_v1',
      'Avisos en la nube',
      channelDescription:
          'Notificaciones push de PetCare Connect mediante Firebase',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_petcare',
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  /// Prepara el canal y escucha los mensajes recibidos con la app abierta.
  Future<void> init() async {
    if (_initialized || (!Platform.isAndroid && !Platform.isIOS)) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_petcare'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _localNotifications.initialize(settings);

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_cloudChannel);
    }

    _messageSubscription = FirebaseMessaging.onMessage.listen((message) {
      _showForegroundMessage(message);
    });

    await _messaging.setAutoInitEnabled(true);
    _initialized = true;
  }

  /// Registra el dispositivo para recibir notificaciones push.
  Future<void> registerForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await init();

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    final allowed =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcmEnabled': allowed,
      'fcmPermission': settings.authorizationStatus.name,
      'fcmUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!allowed) return;

    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _saveToken(user.uid, token);
    }

    await _tokenSubscription?.cancel();
    _tokenSubscription = _messaging.onTokenRefresh.listen((newToken) async {
      final current = FirebaseAuth.instance.currentUser;
      if (current == null || current.uid != user.uid) return;
      await _saveToken(current.uid, newToken);
    });
  }

  Future<void> _saveToken(String uid, String token) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': token,
      'fcmEnabled': true,
      'fcmUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _showForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ??
        message.data['title']?.toString() ??
        'PetCare Connect 🐾';
    final body = notification?.body ??
        message.data['body']?.toString() ??
        'Tienes un nuevo aviso de PetCare.';

    final id = (message.messageId ?? DateTime.now().microsecondsSinceEpoch)
            .hashCode &
        0x7FFFFFFF;

    await _localNotifications.show(
      id,
      title,
      body,
      _cloudDetails,
      payload: message.data['route']?.toString(),
    );
  }

  /// Desvincula el token FCM de la sesión actual.
  Future<void> unregisterCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;

    await _tokenSubscription?.cancel();
    _tokenSubscription = null;

    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': FieldValue.delete(),
          'fcmEnabled': false,
          'fcmUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {
        // El cierre de sesión puede continuar aunque no haya conexión.
      }
    }

    try {
      await _messaging.deleteToken();
    } catch (_) {
      // Firebase generará un token nuevo en el siguiente inicio de sesión.
    }
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
  }
}
