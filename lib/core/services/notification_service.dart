import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

/// FCM + Yerel Bildirim Servisi
/// Singleton — main() içinde await NotificationService.instance.init()
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _fcm   = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  // Bildirim tıklandığında navigator için
  /// Bildirime dokunulduğunda gidilecek rota. [consumePendingRoute] ile
  /// okunur; okunduktan sonra temizlenir ki uygulama her açılışta aynı
  /// ekrana zıplamasın.
  String? _pendingRoute;
  String? get pendingRoute => _pendingRoute;

  /// Bekleyen rotayı alır ve temizler.
  String? consumePendingRoute() {
    final route = _pendingRoute;
    _pendingRoute = null;
    return route;
  }

  void clearPendingRoute() => _pendingRoute = null;

  /// Yeni bir rota geldiğinde tetiklenir — uygulama açıkken bildirime
  /// dokunulursa anında yönlendirme yapılabilsin diye.
  void Function(String route)? onRouteRequested;

  void _setPendingRoute(String? route) {
    if (route == null || route.isEmpty) return;
    _pendingRoute = route;
    onRouteRequested?.call(route);
  }

  // Android bildirim kanalı
  static const _channel = AndroidNotificationChannel(
    'finans_asistan_channel',
    'Liqra',
    description: 'Portföy uyarıları, bütçe bildirimleri ve aylık raporlar',
    importance: Importance.high,
    playSound: true,
  );

  /// Başlat — main() içinde çağrılır
  Future<void> init() async {
    // İzin iste (iOS + Android 13+)
    await _fcm.requestPermission(
      alert:      true,
      badge:      true,
      sound:      true,
      provisional: false,
    );

    // Android kanalı oluştur
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Flutter Local Notifications başlat
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit     = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Ön plan mesajı
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Arka plandan açılış
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Uygulama kapalıyken açıldıysa — hem FCM hem yerel bildirim.
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _handleMessageOpenedApp(initial);

    // Yerel bildirime dokunularak açıldıysa payload'u yakala. Bu kontrol
    // olmadan, uygulama tamamen kapalıyken gönderilen bildirime dokunmak
    // uygulamayı açıyor ama hedef ekrana götürmüyordu.
    final launch = await _local.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _pendingRoute = launch?.notificationResponse?.payload;
    }

    // Arka plan handler (top-level fonksiyon olmalı)
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

    // Token'ı al ve Firestore'a kaydet
    final token = await getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
      debugPrint('[FCM] Token: $token');
    }

    // Token yenilenince Firestore'u güncelle
    _fcm.onTokenRefresh.listen(_saveTokenToFirestore);
  }

  // ── Token ─────────────────────────────────────────────────────────────────

  Future<String?> getToken() => _fcm.getToken();

  Future<void> _saveTokenToFirestore(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[FCM] Token Firestore kaydı başarısız: $e');
    }
  }

  /// Token değişince callback çalıştır (isteğe bağlı ek listener)
  void onTokenRefresh(void Function(String token) callback) {
    _fcm.onTokenRefresh.listen(callback);
  }

  // ── Yerel Bildirim Göster ─────────────────────────────────────────────────

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority:   Priority.high,
          icon:       '@mipmap/ic_launcher',
          color:      AppColors.accentGreen, // Liqra teal
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  // ── Handlers ─────────────────────────────────────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    final notif = message.notification;
    if (notif == null) return;
    showLocalNotification(
      title:   notif.title ?? 'Liqra',
      body:    notif.body  ?? '',
      payload: message.data['route'] as String?,
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    _setPendingRoute(message.data['route'] as String?);
  }

  void _onNotificationTapped(NotificationResponse response) {
    _setPendingRoute(response.payload);
  }
}

/// Arka plan bildirim handler — top-level (sınıf dışı) olmalı
@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Background] ${message.messageId}');
}
