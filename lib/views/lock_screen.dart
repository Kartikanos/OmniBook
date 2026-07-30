// ignore_for_file: deprecated_member_use
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants.dart';
import '../services/biometric_service.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerBiometricUnlock();
    });
  }

  Future<void> _triggerBiometricUnlock() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    final bioService = Provider.of<BiometricService>(context, listen: false);
    await bioService.unlockApp();

    if (mounted) {
      setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bioService = Provider.of<BiometricService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient / Image
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E1B4B),
                  Color(0xFF312E81),
                  Color(0xFF4338CA),
                ],
              ),
            ),
          ),

          // Frosted Glass Blur Overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              color: Colors.black.withOpacity(0.35),
            ),
          ),

          // Main Lock UI
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Container
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.primaryColor.withOpacity(0.5),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 54,
                        color: Colors.white,
                      ),
                    ).animate().scale(duration: 450.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 24),

                    Text(
                      AppConstants.appName,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ).animate().fade().slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 6),

                    const Text(
                      'Utensil & Hardware Ledger Locked',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Card Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF1E293B) : Colors.white).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.fingerprint_rounded,
                            size: 50,
                            color: AppConstants.primaryAccent,
                          ),
                          const SizedBox(height: 14),

                          const Text(
                            'Touch Fingerprint Sensor to Unlock',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),

                          const Text(
                            'Or use device PIN / Pattern fallback',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: bioService.unlockApp,
                              icon: const Icon(Icons.fingerprint_rounded),
                              label: const Text(
                                'Unlock with Fingerprint',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fade().slideY(begin: 0.1, end: 0, delay: 100.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
