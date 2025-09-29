import 'package:flutter/foundation.dart';
import '../data/mock_data.dart';
import '../models/user_profile.dart';

class AuthProvider with ChangeNotifier {
  UserProfile? _user;
  bool get isLoggedIn => _user != null;
  UserProfile? get user => _user;

  // Mock login
  void login() {
    _user = mockUser1; // Using mockUser1 as the logged-in user
    notifyListeners();
  }

  // Mock logout
  void logout() {
    _user = null;
    notifyListeners();
    // In a real app, you would also clear any stored tokens here.
  }
}
