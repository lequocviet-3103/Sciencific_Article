import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _kUserId = 'auth_user_id';
  static const _kFirebaseUid = 'auth_firebase_uid';
  static const _kEmail = 'auth_email';
  static const _kFullName = 'auth_full_name';
  static const _kRoleId = 'auth_role_id';
  static const _kRoleName = 'auth_role_name';

  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      final firebaseUid = prefs.getString(_kFirebaseUid);

      if (firebaseUser == null) {
        _user = null;
        await _clearPrefs(prefs);
        return;
      }

      final userId = prefs.getString(_kUserId);
      final email = prefs.getString(_kEmail);
      final fullName = prefs.getString(_kFullName);
      final roleId = prefs.getString(_kRoleId);
      final roleName = prefs.getString(_kRoleName);

      if (firebaseUid == firebaseUser.uid &&
          userId != null &&
          email != null &&
          fullName != null &&
          roleId != null &&
          roleName != null) {
        _user = User(
          userId: userId,
          firebaseUid: firebaseUid!,
          email: email,
          fullName: fullName,
          roleId: roleId,
          roleName: roleName,
        );
      } else {
        final token = await firebaseUser.getIdToken();
        if (token != null) {
          await setUser(await AuthService().verifyIdToken(token));
        }
      }
    } catch (error) {
      // A valid cached session remains usable when the backend is temporarily
      // unavailable. Firebase itself is still the source of truth for logout.
      debugPrint('Could not refresh authentication session: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setUser(User user) async {
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserId, user.userId);
    await prefs.setString(_kFirebaseUid, user.firebaseUid);
    await prefs.setString(_kEmail, user.email);
    await prefs.setString(_kFullName, user.fullName);
    await prefs.setString(_kRoleId, user.roleId);
    await prefs.setString(_kRoleName, user.roleName);
    notifyListeners();
  }

  Future<void> clear() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await _clearPrefs(prefs);
    notifyListeners();
  }

  Future<void> _clearPrefs(SharedPreferences prefs) async {
    await prefs.remove(_kUserId);
    await prefs.remove(_kFirebaseUid);
    await prefs.remove(_kEmail);
    await prefs.remove(_kFullName);
    await prefs.remove(_kRoleId);
    await prefs.remove(_kRoleName);
  }
}
