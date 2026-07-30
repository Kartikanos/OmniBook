import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../core/supabase_config.dart';
import '../models/user_model.dart';

class DatabaseService extends ChangeNotifier {
  final SupabaseClient _client = SupabaseConfig.client;

  UserModel? _currentUserModel;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUserModel => _currentUserModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Fetch profile for a given user ID
  Future<UserModel?> getUserProfile(String userId, {String? email}) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final data = await _client
          .from(AppConstants.profilesTable)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        _currentUserModel = UserModel.fromJson(data);
      } else {
        // Create initial profile if none exists
        final newModel = UserModel(
          id: userId,
          email: email ?? '',
          fullName: '',
          createdAt: DateTime.now(),
        );
        await upsertUserProfile(newModel);
        _currentUserModel = newModel;
      }
      return _currentUserModel;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching profile: $e');
      }
      _errorMessage = 'Could not load profile data.';
      // Fallback model if DB table is not yet set up
      _currentUserModel = UserModel(
        id: userId,
        email: email ?? '',
      );
      return _currentUserModel;
    } finally {
      _setLoading(false);
    }
  }

  // Upsert (insert or update) profile to Supabase database
  Future<bool> upsertUserProfile(UserModel profile) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _client
          .from(AppConstants.profilesTable)
          .upsert(profile.toJson());

      _currentUserModel = profile;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error upserting profile: $e');
      }
      _errorMessage = 'Failed to save profile updates to database.';
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
