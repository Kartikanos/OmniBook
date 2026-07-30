import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService extends ChangeNotifier {
  static const String _prefKeyBiometricEnabled = 'app_lock_enabled';

  final LocalAuthentication _auth = LocalAuthentication();
  
  bool _isBiometricEnabled = false;
  bool _isAppLocked = false;
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];

  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isAppLocked => _isAppLocked;
  bool get canCheckBiometrics => _canCheckBiometrics;
  List<BiometricType> get availableBiometrics => List.unmodifiable(_availableBiometrics);

  BiometricService() {
    init();
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isBiometricEnabled = prefs.getBool(_prefKeyBiometricEnabled) ?? false;

      final canCheck = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      _canCheckBiometrics = canCheck;

      if (canCheck) {
        _availableBiometrics = await _auth.getAvailableBiometrics();
      }

      if (_isBiometricEnabled) {
        _isAppLocked = true;
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('BiometricService init note: $e');
    }
  }

  // Trigger device fingerprint / face / PIN prompt
  Future<bool> authenticateOwner({String reason = 'Authenticate to access OmniBook ledger'}) async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allows device PIN/Pattern fallback gracefully
        ),
      );
      return authenticated;
    } on PlatformException catch (e) {
      if (kDebugMode) print('Biometric authentication error: $e');
      return false;
    } catch (e) {
      return false;
    }
  }

  // Toggle biometric app lock setting in Settings screen
  Future<bool> setBiometricEnabled(bool enable) async {
    if (enable) {
      final success = await authenticateOwner(reason: 'Verify fingerprint to enable App Lock');
      if (!success) return false;
    } else {
      final success = await authenticateOwner(reason: 'Verify fingerprint to disable App Lock');
      if (!success) return false;
    }

    _isBiometricEnabled = enable;
    if (enable) {
      _isAppLocked = false; // Don't lock immediately inside settings
    } else {
      _isAppLocked = false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyBiometricEnabled, enable);
    notifyListeners();
    return true;
  }

  // Lock App (e.g. when app goes to background or manual lock)
  void lockApp() {
    if (_isBiometricEnabled) {
      _isAppLocked = true;
      notifyListeners();
    }
  }

  // Unlock App from LockScreen
  Future<bool> unlockApp() async {
    if (!_isBiometricEnabled) {
      _isAppLocked = false;
      notifyListeners();
      return true;
    }

    final success = await authenticateOwner(reason: 'Verify fingerprint to unlock OmniBook');
    if (success) {
      _isAppLocked = false;
      notifyListeners();
    }
    return success;
  }
}
