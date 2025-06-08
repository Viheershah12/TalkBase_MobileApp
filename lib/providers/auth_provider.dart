import 'package:flutter/cupertino.dart';

import '../core/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  String? _token;
  String? _tenant;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  String? get tenant => _tenant;

  Future<bool> login(String username, String password, String tenant) async {
    _tenant = tenant;
    final authService = AuthService();  // no longer needs to be initialized with tenant
    final result = await authService.login(
      username: username,
      password: password,
      tenant: tenant,
    );

    if (result != null && result['access_token'] != null) {
      _token = result['access_token'];
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }

    return false;
  }

  Future<bool> checkTenant(String name) async {
    // Replace with real API call
    final authService = AuthService();
    final result = await authService.checkTenant(tenant: name);

    // Add Extra Logic
    if (result != null) {
      return true;
    }
    else {
      return false;
    }
  }

  void logout() {
    _isLoggedIn = false;
    _token = null;
    _tenant = null;
    notifyListeners();
  }
}
