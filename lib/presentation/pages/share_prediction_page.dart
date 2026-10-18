import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/services/partner_sharing_service.dart';
import '../providers/cycle_provider.dart';
import '../providers/symptom_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_background.dart';

class SharePredictionPage extends StatefulWidget {
  const SharePredictionPage({super.key});

  @override
  State<SharePredictionPage> createState() => _SharePredictionPageState();
}

class _SharePredictionPageState extends State<SharePredictionPage> {
  String? _deepLink;

  @override
  void initState() {
    super.initState();
    _generateShareData();
  }

  void _generateShareData() {
    final cycleEvents = context.read<CycleProvider>().cycleEvents;
    final symptomLogs = context.read<SymptomProvider>().symptomLogs;

    final partnerService = context.read<PartnerSharingService>();
    final link = partnerService.generateShareableLink(cycleEvents, symptomLogs);

    setState(() {
      _deepLink = link;
    });
  }

  void _copyToClipboard() {
    if (_deepLink != null) {
      HapticFeedback.mediumImpact();
      Clipboard.setData(ClipboardData(text: _deepLink!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Link copied to clipboard',
            style: TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.primaryDarkColor
              : AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _shareLink() {
    if (_deepLink != null) {
      HapticFeedback.mediumImpact();
      SharePlus.instance.share(ShareParams(text: 'Check out my cycle predictions: $_deepLink'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: primary),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  "Share with Partner",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: primary,
                    fontFamily: AppTheme.fontFamily,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Secure, read-only access to your predictions and logs.",
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black54,
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 48),

                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    padding: const EdgeInsets.all(32),
                    decoration: AppTheme.glassDecoration(isDark: isDark, borderRadius: 40).copyWith(
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.1),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_deepLink != null)
                          Semantics(
                            label:
                                "QR Code containing encrypted cycle predictions. Have your partner scan this to connect.",
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: QrImageView(
                                data: _deepLink!,
                                version: QrVersions.auto,
                                size: 200.0,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Colors.black87,
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Colors.black87,
                                ),
                                gapless: false,
                              ),
                            ),
                          )
                        else
                          const SizedBox(
                            width: 200,
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        const SizedBox(height: 32),
                        Text(
                          "SCAN QR CODE",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: primary,
                            fontFamily: AppTheme.fontFamily,
                            letterSpacing: 2,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                Row(
                  children: [
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.copy_rounded,
                        label: "Copy Link",
                        onTap: _copyToClipboard,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.ios_share_rounded,
                        label: "Share Link",
                        onTap: _shareLink,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 110,
          decoration: AppTheme.glassDecoration(isDark: isDark, borderRadius: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primary, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
