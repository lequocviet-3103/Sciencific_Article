import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// FCM topic the backend broadcasts "new paper published" alerts to (see
/// OpenAlexSyncService.NewPapersTopic on the backend — keep these in sync).
const String newPapersTopic = 'new_papers';

class NotificationService {
  NotificationService({ApiService? api}) : _api = api ?? ApiService();
  final ApiService _api;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize({void Function(RemoteMessage)? onForegroundMessage}) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await registerToken();
    }

    // Subscribing means the backend can broadcast to every device without
    // tracking per-user FCM tokens. Not supported on web (firebase_messaging_web
    // throws UnimplementedError) — web users still get foreground messages
    // and the in-app inbox, just not the topic push.
    try {
      await _messaging.subscribeToTopic(newPapersTopic);
    } catch (e) {
      debugPrint('subscribeToTopic unsupported on this platform: $e');
    }

    FirebaseMessaging.onMessage.listen((message) {
      _onForegroundMessage(message);
      onForegroundMessage?.call(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
  }

  Future<void> registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
      }
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.data}');
  }

  Future<List<NotificationModel>> getNotifications({String? userId, int page = 1, int pageSize = 20}) async {
    final params = {
      if (userId != null) 'userId': userId,
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    final data = await _api.get('/api/notifications', params: params);
    final list = data['items'] as List<dynamic>? ?? [];
    return list.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
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
      notificationId: json['notificationId']?.toString() ?? json['notification_id']?.toString() ?? '',
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
