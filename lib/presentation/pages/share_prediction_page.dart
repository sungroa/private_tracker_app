import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/services/partner_sharing_service.dart';
import '../providers/cycle_provider.dart';
import '../providers/symptom_provider.dart';
import '../theme/app_theme.dart';

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

    final link = PartnerSharingService.generateShareableLink(
      cycleEvents,
      symptomLogs,
    );

    setState(() {
      _deepLink = link;
    });
  }

  void _copyToClipboard() {
    if (_deepLink != null) {
      Clipboard.setData(ClipboardData(text: _deepLink!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied to clipboard'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
  }

  void _shareLink() {
    if (_deepLink != null) {
      Share.share('Check out my cycle predictions: $_deepLink');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFDEEF4), Color(0xFFF3E5F5)],
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Share with Partner",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Secure, read-only access to your predictions.",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 40),
                  
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: AppTheme.glassDecoration(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_deepLink != null)
                            QrImageView(
                              data: _deepLink!,
                              version: QrVersions.auto,
                              size: 240.0,
                              foregroundColor: AppTheme.primaryColor,
                              gapless: false,
                            )
                          else
                            const SizedBox(
                              width: 200,
                              height: 200,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          const SizedBox(height: 24),
                          const Text(
                            "Scan this QR code with the tracker app.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
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
                          icon: Icons.copy,
                          label: "Copy Link",
                          onTap: _copyToClipboard,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.share,
                          label: "Share Link",
                          onTap: _shareLink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: AppTheme.glassDecoration(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
