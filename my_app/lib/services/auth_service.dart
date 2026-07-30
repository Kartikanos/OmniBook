import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _client = SupabaseConfig.client;

  User? _user;
  Session? _session;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _user ?? _client.auth.currentUser;
  Session? get currentSession => _session ?? _client.auth.currentSession;
  bool get isAuthenticated => currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  late final StreamSubscription<AuthState> _authStateSubscription;

  AuthService() {
    _user = _client.auth.currentUser;
    _session = _client.auth.currentSession;

    _authStateSubscription = _client.auth.onAuthStateChange.listen((data) {
      _session = data.session;
      _user = data.session?.user;
      notifyListeners();
    });
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Sign up with email & password
  Future<AuthResponse?> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: fullName != null && fullName.isNotEmpty ? {'full_name': fullName.trim()} : null,
      );

      _user = response.user;
      _session = response.session;
      return response;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      rethrow;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during registration.';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with email & password
  Future<AuthResponse?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      _user = response.user;
      _session = response.session;
      return response;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      rethrow;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during sign in.';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _client.auth.signOut();
      _user = null;
      _session = null;
    } catch (e) {
      _errorMessage = 'Failed to sign out.';
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }
}
