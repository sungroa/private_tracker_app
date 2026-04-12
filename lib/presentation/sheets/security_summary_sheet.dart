import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../../core/services/preferences_service.dart';

class SecuritySummarySheet extends StatelessWidget {
  const SecuritySummarySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SecuritySummarySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;

    return Container(
      padding: const EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, -10),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          Icon(Icons.security_rounded, size: 48, color: primary),
          const SizedBox(height: 16),
          Text(
            "Privacy Snapshot",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your health data is a fortress.",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 32),
          _buildSecurityInfoTile(
            context,
            icon: Icons.enhanced_encryption_rounded,
            title: "AES-256-GCM Encryption",
            subtitle: "On-device authenticated encryption verified.",
          ),
          _buildSecurityInfoTile(
            context,
            icon: Icons.cloud_off_rounded,
            title: "Local Sovereignty",
            subtitle: "No cloud sync. Your data never leaves this phone.",
          ),
          FutureBuilder<bool>(
            future: context.read<PreferencesService>().isBiometricEnabled(),
            builder: (context, snapshot) {
              final enabled = snapshot.data ?? false;
              return _buildSecurityInfoTile(
                context,
                icon: enabled ? Icons.fingerprint_rounded : Icons.lock_open_rounded,
                title: "App Lock Protection",
                subtitle: enabled ? "Biometric authentication is active." : "App lock is currently disabled.",
                color: enabled ? primary : Colors.orangeAccent,
              );
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _showPrivacyPolicy(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary.withValues(alpha: 0.1),
                foregroundColor: primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                "Read Full Privacy Policy",
                style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Color? color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (color ?? primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color ?? primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Zero-Knowledge Privacy Policy"),
        content: const SingleChildScrollView(
          child: Text(
            "This app is designed with a zero-knowledge approach. We literally cannot see your data.\n\n"
            "1. NO DATA COLLECTION: We don't have servers. We don't have accounts. We don't have your name, email, or cycle info.\n\n"
            "2. LOCAL ENCRYPTION: Everything is encrypted using AES-256-GCM before it hits your phone's disk. The keys stay in your device's secure hardware.\n\n"
            "3. NO THIRD PARTIES: No analytics, no ads, no trackers. Your privacy is total.\n\n"
            "For the full legal document, please refer to the PRIVACY_POLICY.md file in the app bundle.",
            style: TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
          ),
        ],
      ),
    );
  }
}
