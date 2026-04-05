import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/auth_service.dart';
import '../theme/app_theme.dart';

class AuthenticationOverlay extends StatelessWidget {
  final VoidCallback onUnlockSuccess;

  const AuthenticationOverlay({
    super.key,
    required this.onUnlockSuccess,
  });

  Future<void> _handleUnlock(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final bool success = await AuthService.instance.authenticate();
    if (success) {
      onUnlockSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blur effect for the content behind
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.2),
            ),
          ),
          
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(40),
              decoration: AppTheme.glassDecoration(isDark: isDark, borderRadius: 40).copyWith(
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.1),
                    blurRadius: 50,
                    offset: const Offset(0, 20),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_person_rounded,
                      size: 64,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    "APP LOCKED",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: primary,
                      letterSpacing: 2,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Please authenticate to access your private data",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black87,
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Container(
                    width: double.infinity,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: isDark ? [AppTheme.primaryDarkColor, AppTheme.accentDarkColor] : [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
                      ),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _handleUnlock(context),
                      icon: Icon(Icons.fingerprint_rounded, color: isDark ? AppTheme.backgroundDarkColor : Colors.white),
                      label: Text(
                        "UNLOCK NOW", 
                        style: TextStyle(
                          color: isDark ? AppTheme.backgroundDarkColor : Colors.white, 
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontSize: 15,
                        )
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
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
