import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants.dart';
import 'core/supabase_config.dart';
import 'core/theme.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/theme_service.dart';
import 'services/biometric_service.dart';
import 'views/auth_wrapper.dart';
import 'views/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Custom Error Widget Fallback to catch raw red screens
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppConstants.accentColor, size: 36),
              SizedBox(height: 8),
              Text(
                'Section load error. Please refresh.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  };

  // Initialize Supabase SDK with Dotenv configuration
  await SupabaseConfig.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<DatabaseService>(create: (_) => DatabaseService()),
        ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
        ChangeNotifierProvider<BiometricService>(create: (_) => BiometricService()),
      ],
      child: Consumer2<ThemeService, BiometricService>(
        builder: (context, themeService, bioService, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,
            home: bioService.isAppLocked
                ? const LockScreen()
                : const AuthWrapper(),
          );
        },
      ),
    );
  }
}
