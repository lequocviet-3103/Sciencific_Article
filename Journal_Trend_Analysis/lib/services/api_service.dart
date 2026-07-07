import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../config/app_config.dart';
import '../models/api_error.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? params}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$endpoint').replace(queryParameters: params);
    final response = await _client.get(uri, headers: await _headers());
    return _handleResponse(response);
  }

  /// Like [get] but expects the server to return a JSON array instead of an object.
  Future<List<dynamic>> getList(String endpoint, {Map<String, String>? params}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$endpoint').replace(queryParameters: params);
    final response = await _client.get(uri, headers: await _headers());

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};
      final message = body['message'] ?? body['error'] ?? 'API error: ${response.statusCode}';
      throw ApiError(message, statusCode: response.statusCode);
    }

    return response.body.isNotEmpty
        ? jsonDecode(response.body) as List<dynamic>
        : <dynamic>[];
  }

  Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
    final response = await _client.post(
      uri,
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> patch(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
    final response = await _client.patch(
      uri,
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
    final response = await _client.delete(uri, headers: await _headers());
    return _handleResponse(response);
  }

  Future<Map<String, String>> _headers() async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = user != null ? await user.getIdToken() : null;

    return {
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body['message'] ?? body['error'] ?? 'API error: ${response.statusCode}';
    throw ApiError(message, statusCode: response.statusCode);
  }
}
