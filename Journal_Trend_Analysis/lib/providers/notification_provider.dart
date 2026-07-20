import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({NotificationService? service})
    : _service = service ?? NotificationService();

  final NotificationService _service;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  bool _pushInitialized = false;
  String? _fcmToken;
  bool _isSending = false;
  final Set<String> _outboundPushes = <String>{};

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  String? get fcmToken => _fcmToken;
  bool get isSending => _isSending;

  Future<void> loadNotifications(String userId, {int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _service.getNotifications(
        userId: userId,
        page: page,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _service.markAsRead(notificationId);
      final idx = _notifications.indexWhere(
        (n) => n.notificationId == notificationId,
      );
      if (idx >= 0) {
        final n = _notifications[idx];
        _notifications[idx] = NotificationModel(
          notificationId: n.notificationId,
          userId: n.userId,
          title: n.title,
          content: n.content,
          isRead: true,
          createdAt: n.createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('markAsRead failed: $e');
    }
  }

  Future<void> refresh(String userId) async {
    await loadNotifications(userId);
  }

  /// Subscribes to the app's FCM topics and starts listening for
  /// foreground push messages, prepending them to the in-app list so the
  /// bell badge updates immediately without waiting for the next REST poll.
  /// Safe to call multiple times — only initializes once.
  Future<void> initPush() async {
    if (_pushInitialized) return;
    _pushInitialized = true;
    await _service.initialize(onForegroundMessage: _handlePush);
    _fcmToken = await _service.getToken();
    notifyListeners();
  }

  Future<void> refreshToken() async {
    _fcmToken = await _service.getToken();
    notifyListeners();
  }

  Future<Map<String, dynamic>> sendTestNotification({
    required String userId,
    required String token,
    required String title,
    required String body,
  }) async {
    _isSending = true;
    _error = null;
    final pushKey = _pushKey(title, body);
    _outboundPushes.add(pushKey);
    notifyListeners();
    try {
      final result = await _service.sendToToken(
        token: token,
        title: title,
        body: body,
      );
      await loadNotifications(userId);
      return result;
    } catch (error) {
      _outboundPushes.remove(pushKey);
      _error = error.toString();
      rethrow;
    } finally {
      Future<void>.delayed(const Duration(seconds: 30), () {
        _outboundPushes.remove(pushKey);
      });
      _isSending = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> broadcast({
    required String userId,
    required String title,
    required String body,
  }) async {
    _isSending = true;
    _error = null;
    final pushKey = _pushKey(title, body);
    _outboundPushes.add(pushKey);
    notifyListeners();
    try {
      final result = await _service.broadcast(title: title, body: body);
      await loadNotifications(userId);
      return result;
    } catch (error) {
      _outboundPushes.remove(pushKey);
      _error = error.toString();
      rethrow;
    } finally {
      Future<void>.delayed(const Duration(seconds: 30), () {
        _outboundPushes.remove(pushKey);
      });
      _isSending = false;
      notifyListeners();
    }
  }

  void _handlePush(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    final title = notification.title ?? 'New notification';
    final body = notification.body ?? '';
    if (_outboundPushes.contains(_pushKey(title, body))) return;
    _notifications = [
      NotificationModel(
        notificationId: message.messageId ?? DateTime.now().toIso8601String(),
        title: title,
        content: body,
        isRead: false,
        createdAt: DateTime.now(),
      ),
      ..._notifications,
    ];
    notifyListeners();
  }

  static String _pushKey(String title, String body) => '$title\u0000$body';
}
