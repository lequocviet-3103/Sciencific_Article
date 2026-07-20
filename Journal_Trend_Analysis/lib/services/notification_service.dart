import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import 'api_service.dart';

const String newPapersTopic = 'new_papers';
const String allUsersTopic = 'all_users';
const String notificationChannelId = 'researchhub_high_importance';

const AndroidNotificationChannel _notificationChannel =
    AndroidNotificationChannel(
      notificationChannelId,
      'ResearchHub notifications',
      description: 'New publications and ResearchHub alerts',
      importance: Importance.high,
    );

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Notification payloads are displayed by Android automatically in the
  // background. Data-only payloads need a local notification.
  if (message.notification == null) {
    await NotificationService.showMessage(message);
  }
}

class NotificationService {
  NotificationService({ApiService? api}) : _api = api ?? ApiService();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final ApiService _api;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;
  void Function(RemoteMessage)? _foregroundCallback;

  Future<void> initialize({
    void Function(RemoteMessage)? onForegroundMessage,
  }) async {
    if (onForegroundMessage != null) {
      _foregroundCallback = onForegroundMessage;
    }
    if (_initialized) return;
    _initialized = true;

    try {
      await _initializeLocalNotifications();
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await registerToken();
      }

      if (!kIsWeb) {
        await _messaging.subscribeToTopic(newPapersTopic);
        await _messaging.subscribeToTopic(allUsersTopic);
      }

      _messaging.onTokenRefresh.listen(
        (token) => debugPrint('FCM Token refreshed: $token'),
        onError: (Object error, StackTrace stackTrace) =>
            _recordNonFatal(error, stackTrace, 'FCM token refresh failed'),
      );

      FirebaseMessaging.onMessage.listen((message) async {
        await showMessage(message);
        _foregroundCallback?.call(message);
      });
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _onMessageOpenedApp(initialMessage);
      }
    } catch (error, stackTrace) {
      _initialized = false;
      await _recordNonFatal(error, stackTrace, 'FCM initialization failed');
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(settings: initializationSettings);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_notificationChannel);
  }

  static Future<void> showMessage(RemoteMessage message) async {
    await _initializeLocalNotifications();
    final title =
        message.notification?.title ??
        message.data['title']?.toString() ??
        'ResearchHub';
    final body =
        message.notification?.body ??
        message.data['body']?.toString() ??
        message.data['message']?.toString() ??
        'You have a new research update.';

    await _localNotifications.show(
      id:
          message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          notificationChannelId,
          'ResearchHub notifications',
          channelDescription: 'New publications and ResearchHub alerts',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
      }
      return token;
    } catch (error, stackTrace) {
      await _recordNonFatal(error, stackTrace, 'Failed to retrieve FCM token');
      return null;
    }
  }

  Future<void> registerToken() async {
    await getToken();
  }

  Future<Map<String, dynamic>> sendToToken({
    required String token,
    required String title,
    required String body,
  }) {
    return _api.post(
      '/api/notifications/send-to-token',
      body: {'token': token, 'title': title, 'body': body},
    );
  }

  Future<Map<String, dynamic>> broadcast({
    required String title,
    required String body,
  }) {
    return _api.post(
      '/api/notifications/broadcast',
      body: {'title': title, 'body': body},
    );
  }

  static void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.data}');
  }

  static Future<void> _recordNonFatal(
    Object error,
    StackTrace stackTrace,
    String reason,
  ) async {
    debugPrint('$reason: $error');
    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: false,
    );
  }

  Future<List<NotificationModel>> getNotifications({
    String? userId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = {
      'userId': ?userId,
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    final data = await _api.get('/api/notifications', params: params);
    final list = data['items'] as List<dynamic>? ?? [];
    return list
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await _api.patch('/api/notifications/$notificationId/read');
  }
}

class NotificationModel {
  final String notificationId;
  final String? userId;
  final String title;
  final String content;
  final bool isRead;
  final DateTime? createdAt;

  NotificationModel({
    required this.notificationId,
    this.userId,
    required this.title,
    required this.content,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId:
          json['notificationId']?.toString() ??
          json['notification_id']?.toString() ??
          '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString(),
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      isRead: json['isRead'] == true || json['is_read'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
