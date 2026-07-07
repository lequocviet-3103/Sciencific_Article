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

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications(String userId, {int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _service.getNotifications(userId: userId, page: page);
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
      final idx = _notifications.indexWhere((n) => n.notificationId == notificationId);
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

  /// Subscribes to the "new_papers" FCM topic and starts listening for
  /// foreground push messages, prepending them to the in-app list so the
  /// bell badge updates immediately without waiting for the next REST poll.
  /// Safe to call multiple times — only initializes once.
  Future<void> initPush() async {
    if (_pushInitialized) return;
    _pushInitialized = true;
    await _service.initialize(onForegroundMessage: _handlePush);
  }

  void _handlePush(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _notifications = [
      NotificationModel(
        notificationId: message.messageId ?? DateTime.now().toIso8601String(),
        title: notification.title ?? 'New notification',
        content: notification.body ?? '',
        isRead: false,
        createdAt: DateTime.now(),
      ),
      ..._notifications,
    ];
    notifyListeners();
  }
}
