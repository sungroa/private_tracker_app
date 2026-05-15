import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../domain/services/partner_sharing_service.dart';
import '../../domain/models/shared_phase_data.dart';
import '../../data/storage/partner_storage_service.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../widgets/glass_background.dart';

class PartnerModePage extends StatefulWidget {
  final String? initialPayload;
  final String? initialKey;

  const PartnerModePage({
    super.key,
    this.initialPayload,
    this.initialKey,
  });

  @override
  State<PartnerModePage> createState() => _PartnerModePageState();
}

class _PartnerModePageState extends State<PartnerModePage> {
  bool _isScanning = false;
  SharedPhaseData? _data;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialization is now handled by LocalDatabaseManager via MultiProvider
    final storage = context.read<PartnerStorageService>();
    
    if (widget.initialPayload != null && widget.initialKey != null) {
      _processPayload(widget.initialPayload!, widget.initialKey!);
    } else {
      final storedData = storage.getPartnerData();
      if (storedData != null) {
        setState(() {
          _data = storedData;
        });
      }
    }

    setState(() {
      _isInitialized = true;
    });
  }

  void _processPayload(String payload, String key) {
    try {
      final decrypted = context.read<PartnerSharingService>().decryptPayload(payload, key);
      context.read<PartnerStorageService>().savePartnerData(decrypted, key);
      setState(() {
        _data = decrypted;
        _isScanning = false;
      });
      HapticFeedback.heavyImpact();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to process data: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _resetApp() async {
    HapticFeedback.mediumImpact();
    final partnerService = context.read<PartnerStorageService>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Partner Mode?', style: TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.bold)),
        content: const Text('This will clear the current shared partner data. You will need a new link or QR to see it again.', style: TextStyle(fontFamily: AppTheme.fontFamily)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear Data', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await partnerService.clearPartnerData();
      if (mounted) {
        setState(() {
          _data = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, color: primary),
          ),
          actions: [
            if (_data != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  onPressed: _resetApp,
                  icon: Icon(Icons.refresh_rounded, color: primary.withValues(alpha: 0.6)),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_data == null && !_isScanning) 
                  _buildEmptyState(isDark, primary)
                else if (_isScanning)
                  _buildScanner(isDark, primary)
                else if (_data != null)
                  _buildDashboard(isDark, primary),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color primary) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite_rounded, size: 80, color: primary),
          ),
          const SizedBox(height: 32),
          Text(
            "Partner Mode",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: primary,
              fontFamily: AppTheme.fontFamily,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Scan your partner's QR code or use a shared link to see their cycle predictions securely.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16, 
              color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black54,
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w500,
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
              onPressed: () {
                HapticFeedback.mediumImpact();
                setState(() => _isScanning = true);
              },
              icon: Icon(Icons.qr_code_scanner_rounded, color: isDark ? AppTheme.backgroundDarkColor : Colors.white),
              label: Text(
                "SCAN QR CODE", 
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
    );
  }

  Widget _buildScanner(bool isDark, Color primary) {
    return Expanded(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            "Scan Partner's QR",
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.w800,
              color: primary,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 48),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: primary.withValues(alpha: 0.2), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(38),
                child: Stack(
                  children: [
                    MobileScanner(
                      onDetect: (capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          final rawValue = barcode.rawValue;
                          if (rawValue != null) {
                            final uri = Uri.tryParse(rawValue);
                            if (uri != null) {
                              final result = context.read<PartnerSharingService>().parseDeepLink(uri);
                              if (result != null) {
                                _processPayload(result['data']!, result['key']!);
                                break;
                              }
                            }
                          }
                        }
                      },
                    ),
                    _buildScannerOverlay(primary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
          TextButton(
            onPressed: () => setState(() => _isScanning = false),
            child: Text(
              "CANCEL SCAN", 
              style: TextStyle(
                color: primary, 
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                fontSize: 14,
              )
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay(Color primary) {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0, left: 0,
              child: Container(width: 40, height: 40, decoration: BoxDecoration(border: Border(top: BorderSide(color: primary, width: 6), left: BorderSide(color: primary, width: 6)), borderRadius: const BorderRadius.only(topLeft: Radius.circular(32)))),
            ),
            Positioned(
              top: 0, right: 0,
              child: Container(width: 40, height: 40, decoration: BoxDecoration(border: Border(top: BorderSide(color: primary, width: 6), right: BorderSide(color: primary, width: 6)), borderRadius: const BorderRadius.only(topRight: Radius.circular(32)))),
            ),
            Positioned(
              bottom: 0, left: 0,
              child: Container(width: 40, height: 40, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: primary, width: 6), left: BorderSide(color: primary, width: 6)), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32)))),
            ),
            Positioned(
              bottom: 0, right: 0,
              child: Container(width: 40, height: 40, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: primary, width: 6), right: BorderSide(color: primary, width: 6)), borderRadius: const BorderRadius.only(bottomRight: Radius.circular(32)))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(bool isDark, Color primary) {
    final now = DateTime.now();
    final nextPeriod = _data!.nextPeriodDate;
    final daysUntil = nextPeriod.difference(now).inDays;
    
    final inWindow = now.isAfter(_data!.fertilityWindowStart) && now.isBefore(_data!.fertilityWindowEnd);
    final daysUntilWindow = _data!.fertilityWindowStart.difference(now).inDays;

    return Expanded(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              "Partner's Hub",
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: primary,
                fontFamily: AppTheme.fontFamily,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Read-only view of shared predictions.",
              style: TextStyle(
                fontSize: 16, 
                color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black38,
                fontFamily: AppTheme.fontFamily,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 48),
            
            // Period Countdown
            _InfoCard(
              title: "NEXT PERIOD",
              value: daysUntil > 0 ? "In $daysUntil days" : (daysUntil == 0 ? "Today" : "${daysUntil.abs()} days ago"),
              subValue: DateFormat('MMMM d, yyyy').format(nextPeriod),
              icon: Icons.water_drop_rounded,
              color: Colors.redAccent,
              isDark: isDark,
            ),
            
            const SizedBox(height: 20),
            
            // Fertility Window
            _InfoCard(
              title: "FERTILITY WINDOW",
              value: inWindow 
                  ? "Active Now" 
                  : (daysUntilWindow > 0 ? "In $daysUntilWindow days" : "Window Over"),
              subValue: "${DateFormat('MMM d').format(_data!.fertilityWindowStart)} - ${DateFormat('MMM d').format(_data!.fertilityWindowEnd)}",
              icon: Icons.bubble_chart_rounded,
              color: Colors.greenAccent,
              isActive: inWindow,
              isDark: isDark,
            ),
            
            const SizedBox(height: 48),
            
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.glassDecoration(isDark: isDark, borderRadius: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock_rounded, size: 16, color: primary),
                      const SizedBox(width: 8),
                      Text(
                        "PRIVACY NOTICE",
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: primary, letterSpacing: 1.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Predictions are based on historical cycle patterns. This data is stored only on your device and is not shared with any servers.",
                    style: TextStyle(
                      color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black54, 
                      fontSize: 14, 
                      height: 1.5,
                      fontFamily: AppTheme.fontFamily
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Last synced:",
                        style: TextStyle(
                          color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black38,
                          fontSize: 12,
                          fontFamily: AppTheme.fontFamily
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, h:mm a').format(_data!.generatedAt),
                        style: TextStyle(
                          fontWeight: FontWeight.w700, 
                          color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black45,
                          fontSize: 12,
                          fontFamily: AppTheme.fontFamily
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String subValue;
  final IconData icon;
  final Color color;
  final bool isActive;
  final bool isDark;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.subValue,
    required this.icon,
    required this.color,
    required this.isDark,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: AppTheme.glassDecoration(isDark: isDark, borderRadius: 32).copyWith(
        boxShadow: isActive ? [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ] : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11, 
                    fontWeight: FontWeight.w900, 
                    color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black38,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isActive ? color : (isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87),
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subValue,
                  style: TextStyle(
                    fontSize: 14, 
                    color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black45,
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
