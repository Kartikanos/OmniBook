import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _avatarUrlController;

  @override
  void initState() {
    super.initState();
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final userModel = dbService.currentUserModel;

    _nameController = TextEditingController(text: userModel?.fullName ?? '');
    _avatarUrlController = TextEditingController(text: userModel?.avatarUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    final currentUser = authService.currentUser;
    if (currentUser == null) return;

    final updatedModel = UserModel(
      id: currentUser.id,
      email: currentUser.email ?? '',
      fullName: _nameController.text.trim(),
      avatarUrl: _avatarUrlController.text.trim(),
      createdAt: dbService.currentUserModel?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await dbService.upsertUserProfile(updatedModel);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile successfully updated in Supabase database!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dbService.errorMessage ?? 'Failed to update profile.'),
          backgroundColor: AppConstants.accentColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                UserAvatar(
                  avatarUrl: _avatarUrlController.text,
                  displayName: _nameController.text.isNotEmpty ? _nameController.text : 'User',
                  radius: 50,
                ),
                const SizedBox(height: 28),

                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  prefixIcon: Icons.person_outline,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  controller: _avatarUrlController,
                  label: 'Avatar Image URL (Optional)',
                  hint: 'https://example.com/avatar.png',
                  prefixIcon: Icons.image_outlined,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 20),

                // Read-only Email display
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email Address (Read-only)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Text(
                        authService.currentUser?.email ?? 'N/A',
                        style: const TextStyle(fontSize: 16, color: AppConstants.textMutedDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                CustomButton(
                  text: 'Save Changes',
                  isLoading: dbService.isLoading,
                  onPressed: _saveProfile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
