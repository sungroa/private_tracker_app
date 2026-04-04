import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../theme/app_theme.dart';

class AuthenticationOverlay extends StatelessWidget {
  final VoidCallback onUnlockSuccess;

  const AuthenticationOverlay({
    super.key,
    required this.onUnlockSuccess,
  });

  Future<void> _handleUnlock(BuildContext context) async {
    final bool success = await AuthService.instance.authenticate();
    if (success) {
      onUnlockSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blur effect for the content behind
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(32),
              decoration: AppTheme.glassDecoration(
                color: Colors.white.withValues(alpha: 0.7),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_person_rounded,
                    size: 80,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "App Locked",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Please authenticate to access your private data",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _handleUnlock(context),
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: const Text("Unlock Now"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
