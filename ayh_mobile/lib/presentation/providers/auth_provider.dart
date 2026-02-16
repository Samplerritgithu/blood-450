import 'package:flutter/foundation.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user.dart';
import '../../data/models/donor_profile.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  User? _user;
  DonorProfile? _donorProfile;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  DonorProfile? get donorProfile => _donorProfile;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAdmin => _user?.isStaff ?? false;
  bool get hasDonorProfile => _donorProfile != null;

  Future<void> checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isLoggedIn = await _authRepository.isLoggedIn();
      if (_isLoggedIn) {
        _user = await _authRepository.getCachedUser();
        _donorProfile = await _authRepository.getCachedDonorProfile();
        
        // Fetch fresh data if logged in
        final result = await _authRepository.getCurrentUser();
        if (result['success']) {
          _user = result['user'];
          _donorProfile = result['donor_profile'];
        }
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authRepository.login(username, password);
      
      if (result['success']) {
        _user = result['user'];
        _donorProfile = result['donor_profile'];
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    String? firstName,
    String? lastName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authRepository.register(
        username: username,
        email: email,
        password: password,
        passwordConfirm: passwordConfirm,
        firstName: firstName,
        lastName: lastName,
      );
      
      if (result['success']) {
        _user = result['user'];
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
    _donorProfile = null;
    _isLoggedIn = false;
    _error = null;
    notifyListeners();
  }

  void updateDonorProfile(DonorProfile profile) {
    _donorProfile = profile;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
