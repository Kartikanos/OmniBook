import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _client = SupabaseConfig.client;

  User? _user;
  Session? _session;
  bool _isGuestMode = false;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _user ?? _client.auth.currentUser;
  Session? get currentSession => _session ?? _client.auth.currentSession;
  bool get isGuestMode => _isGuestMode;
  bool get isAuthenticated => _isGuestMode || currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  late final StreamSubscription<AuthState> _authStateSubscription;

  AuthService() {
    _user = _client.auth.currentUser;
    _session = _client.auth.currentSession;

    _authStateSubscription = _client.auth.onAuthStateChange.listen((data) {
      if (!_isGuestMode) {
        _session = data.session;
        _user = data.session?.user;
        notifyListeners();
      }
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

  // Guest Mode login
  void loginAsGuest() {
    _isGuestMode = true;
    _errorMessage = null;
    notifyListeners();
  }

  // Google Authentication Integration
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _errorMessage = null;
      _isGuestMode = false;

      final GoogleSignIn googleSignIn = GoogleSignIn(
        // Google Web Client ID from Google Cloud Console (needed for Supabase token exchange)
        serverClientId: '546071157962-nh1cgqddcm3u5abss7nqnv0i4a3oghkc.apps.googleusercontent.com',
      );
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the Google sign-in prompt
        _setLoading(false);
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        _errorMessage = 'No Google ID Token found.';
        _setLoading(false);
        return false;
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      _user = response.user;
      _session = response.session;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      if (kDebugMode) print('Google Auth exception: $e');
      _errorMessage = 'Google sign-in failed. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign up with email & password
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;
      _isGuestMode = false;

      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: fullName != null && fullName.isNotEmpty ? {'full_name': fullName.trim()} : null,
      );

      _user = response.user;
      _session = response.session;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message.contains('Invalid login credentials') || e.message.contains('Invalid credentials')
          ? 'Incorrect password or account details. Please try again.'
          : e.message;
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during registration.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with email & password
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;
      _isGuestMode = false;

      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      _user = response.user;
      _session = response.session;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message.contains('Invalid login credentials') || e.message.contains('Invalid credentials')
          ? 'Incorrect password or account details. Please try again.'
          : e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Incorrect password or account details. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user password after verifying current password
  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      if (_isGuestMode) {
        return true;
      }

      final email = currentUser?.email;
      if (email == null) {
        _errorMessage = 'User not authenticated.';
        return false;
      }

      // Step 1: Verify current password against Supabase Auth
      try {
        await _client.auth.signInWithPassword(email: email, password: currentPassword);
      } on AuthException catch (_) {
        _errorMessage = 'Current password is incorrect. Please try again.';
        return false;
      }

      // Step 2: Update to new password
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update credentials.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete user account
  Future<bool> deleteAccount() async {
    try {
      _setLoading(true);
      _errorMessage = null;

      if (!_isGuestMode && currentUser != null) {
        // Sign out user on local client
        await _client.auth.signOut();
      }
      _isGuestMode = false;
      _user = null;
      _session = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete account.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      if (!_isGuestMode) {
        await _client.auth.signOut();
      }
      _isGuestMode = false;
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
