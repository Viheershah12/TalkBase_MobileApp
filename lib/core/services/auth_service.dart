import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants.dart';

class AuthService {
  static const String tokenEndpoint = AuthenticationConstants.authServerBaseUrl;
  static const String clientId = AuthenticationConstants.clientId;
  static const String clientSecret = AuthenticationConstants.clientSecret;
  static const String scope = AuthenticationConstants.scope;

  Future<Map<String, dynamic>?> login({
    required String username,
    required String password,
    required String tenant
  }) async {
    try {
      var url = Uri.parse(tokenEndpoint);
      print('Requesting token at: $url');
      final response = await http.post(
        Uri.parse(tokenEndpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          '__tenant': tenant,
        },
        body: {
          'grant_type': 'password',
          'username': username,
          'password': password,
          'client_id': clientId,
          'client_secret': clientSecret,
          'scope': scope,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final accessToken = data["access_token"];
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Login failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Login exception: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> checkTenant({
    required String tenant
  }) async {
    try{
      var url = Uri.parse(AppConstants.tenantCheck + tenant);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        return null;
      }
    }
    catch (e){
      print('Login exception: $e');
      return null;
    }
  }
}
