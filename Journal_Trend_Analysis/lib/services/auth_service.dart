import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/api_error.dart';
import '../models/user.dart';
import '../models/role.dart';

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<User> verifyIdToken(String idToken, [String? roleId]) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/auth/verify-token');
    final body = <String, dynamic>{'idToken': idToken};
    if (roleId != null && roleId.trim().isNotEmpty) {
      body['roleId'] = roleId.trim();
    }

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw ApiError(
        'Verify token failed',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final success = decoded['success'] == true;
    final userJson = decoded['user'];

    if (!success || userJson == null) {
      throw const ApiError('Invalid Firebase token response');
    }

    return User.fromJson(userJson as Map<String, dynamic>);
  }

  Future<List<Role>> getAvailableRoles() async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/auth/roles');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw ApiError('Failed to load roles', statusCode: response.statusCode);
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.map((e) => Role.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<User>> getAllUsers() async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/auth/users');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw ApiError('Failed to load users', statusCode: response.statusCode);
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> assignRole(String userId, String roleId) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/auth/assign-role');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'roleId': roleId}),
    );

    if (response.statusCode != 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
      throw ApiError(
        decoded?['message']?.toString() ?? 'Failed to assign role',
        statusCode: response.statusCode,
      );
    }
  }
}
