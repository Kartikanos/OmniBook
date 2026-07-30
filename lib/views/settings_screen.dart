// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/theme_service.dart';
import '../services/biometric_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Modal dialog to edit user profile
  void _showEditProfileDialog(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserModel = dbService.currentUserModel;

    final nameController = TextEditingController(
      text: currentUserModel?.fullName ?? (authService.isGuestMode ? 'Guest Manager' : ''),
    );
    final avatarController = TextEditingController(
      text: currentUserModel?.avatarUrl ?? '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Account Profile'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: avatarController,
                decoration: const InputDecoration(
                  labelText: 'Avatar Image URL (Optional)',
                  prefixIcon: Icon(Icons.image_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final updatedModel = UserModel(
                  id: authService.currentUser?.id ?? 'guest_id',
                  email: authService.currentUser?.email ?? 'guest@omnibook.app',
                  fullName: nameController.text.trim(),
                  avatarUrl: avatarController.text.trim(),
                );
                await dbService.upsertUserProfile(updatedModel);
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully!')),
                  );
                }
              }
            },
            child: const Text('Save Profile'),
          ),
        ],
      ),
    );
  }

  // Dialog to change user password / credentials with current password verification
  void _showChangePasswordDialog(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Credentials'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Verify current password to set a new password:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.lock_clock_outlined),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Enter current password' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                validator: (val) =>
                    val == null || val.length < 6 ? 'Min 6 characters' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final success = await authService.updatePassword(
                  currentPasswordController.text,
                  newPasswordController.text,
                );
                if (ctx.mounted) {
                  if (success) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password updated successfully!'),
                        backgroundColor: AppConstants.cashInColor,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(authService.errorMessage ?? 'Current password verification failed.'),
                        backgroundColor: AppConstants.accentColor,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Save Password'),
          ),
        ],
      ),
    );
  }

  // Dialog to confirm account deletion
  void _showDeleteAccountDialog(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppConstants.accentColor),
            SizedBox(width: 8),
            Text('Delete Account?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and will erase your local session data.',
          style: TextStyle(fontSize: 14),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final dbService = Provider.of<DatabaseService>(context, listen: false);
              await dbService.clearUserData();
              await authService.deleteAccount();
            },
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final dbService = Provider.of<DatabaseService>(context);
    final themeService = Provider.of<ThemeService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userName = dbService.currentUserModel?.fullName ?? '';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings & Preferences',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Account controls, theme options & security',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppConstants.textMutedDark : AppConstants.textMutedLight,
                ),
              ),
              const SizedBox(height: 24),

              // Profile Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: isDark
                      ? const BorderSide(color: Color(0xFF334155), width: 0.8)
                      : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppConstants.primaryColor,
                            child: Text(
                              authService.isGuestMode
                                  ? 'G'
                                  : (userName.isNotEmpty
                                      ? userName[0].toUpperCase()
                                      : 'U'),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authService.isGuestMode
                                      ? 'Guest Mode User'
                                      : (userName.isNotEmpty
                                          ? userName
                                          : 'Manager Account'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  authService.isGuestMode
                                      ? 'Testing session (Local Sandbox)'
                                      : (authService.currentUser?.email ?? 'Connected user'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppConstants.textMutedDark
                                        : AppConstants.textMutedLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppConstants.primaryAccent,
                            side: const BorderSide(color: AppConstants.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _showEditProfileDialog(context),
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: const Text('Edit Profile Details'),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fade().slideY(begin: 0.1, end: 0),

              const SizedBox(height: 24),

              // Appearance Section
              const Text(
                'Appearance & Theme',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: isDark
                      ? const BorderSide(color: Color(0xFF334155), width: 0.8)
                      : BorderSide.none,
                ),
                child: SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: Text(
                    themeService.isDarkMode ? 'Dark glass theme active' : 'Light clean theme active',
                  ),
                  secondary: Icon(
                    themeService.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: AppConstants.primaryAccent,
                  ),
                  value: themeService.isDarkMode,
                  activeColor: AppConstants.primaryColor,
                  onChanged: (val) {
                    themeService.toggleTheme(val);
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Security & Credentials Section
              const Text(
                'Security & App Lock',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: isDark
                      ? const BorderSide(color: Color(0xFF334155), width: 0.8)
                      : BorderSide.none,
                ),
                child: Column(
                  children: [
                    Consumer<BiometricService>(
                      builder: (context, bioService, child) {
                        return SwitchListTile(
                          title: const Text('Enable Fingerprint / App Lock'),
                          subtitle: Text(
                            bioService.isBiometricEnabled
                                ? 'App Lock enabled (Fingerprint/PIN required to unlock)'
                                : 'Protect OmniBook with device Fingerprint or PIN',
                          ),
                          secondary: const Icon(
                            Icons.fingerprint_rounded,
                            color: AppConstants.primaryAccent,
                          ),
                          value: bioService.isBiometricEnabled,
                          activeColor: AppConstants.primaryColor,
                          onChanged: (val) async {
                            final success = await bioService.setBiometricEnabled(val);
                            if (!success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Biometric verification failed or cancelled.'),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.key_rounded, color: AppConstants.secondaryColor),
                      title: const Text('Change Credentials'),
                      subtitle: const Text('Update login password'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showChangePasswordDialog(context),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.delete_outline_rounded, color: AppConstants.accentColor),
                      title: const Text('Delete Account'),
                      subtitle: const Text('Permanently remove account and data'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showDeleteAccountDialog(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Sign Out CTA
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConstants.accentColor,
                    side: const BorderSide(color: AppConstants.accentColor, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    await dbService.clearUserData();
                    await authService.signOut();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(
                    'Sign Out / Exit Session',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ).animate().fade().scale(delay: 100.ms),
            ],
          ),
        ),
      ),
    );
  }
}
