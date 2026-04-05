import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../domain/services/partner_sharing_service.dart';
import '../../domain/models/shared_phase_data.dart';
import '../../data/storage/partner_storage_service.dart';
import '../theme/app_theme.dart';

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
    await PartnerStorageService.initialize();
    
    // 1. Process initial payload if provided (from deep link)
    if (widget.initialPayload != null && widget.initialKey != null) {
      _processPayload(widget.initialPayload!, widget.initialKey!);
    } else {
      // 2. Load from storage
      final storedData = PartnerStorageService.getPartnerData();
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
      final decrypted = PartnerSharingService.decryptPayload(payload, key);
      PartnerStorageService.savePartnerData(decrypted, key);
      setState(() {
        _data = decrypted;
        _isScanning = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to process data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Partner Mode?'),
        content: const Text('This will clear the current shared partner data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await PartnerStorageService.clearPartnerData();
              setState(() {
                _data = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear Data', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                colors: [Color(0xFFE8F5E9), Color(0xFFE0F2F1)], // Greenish tint for Partner Mode
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.black54),
                      ),
                      if (_data != null)
                        IconButton(
                          onPressed: _resetApp,
                          icon: const Icon(Icons.refresh, color: Colors.black54),
                        ),
                    ],
                  ),
                  
                  if (_data == null && !_isScanning) 
                    _buildEmptyState()
                  else if (_isScanning)
                    _buildScanner()
                  else if (_data != null)
                    _buildDashboard(),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border, size: 80, color: Colors.green),
          const SizedBox(height: 24),
          const Text(
            "Partner Mode",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Scan your partner's QR code or use a shared link to see their cycle predictions.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: () => setState(() => _isScanning = true),
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            label: const Text("Scan QR Code", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanner() {
    return Expanded(
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            "Scan Partner's QR",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
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
                            final result = PartnerSharingService.parseDeepLink(uri);
                            if (result != null) {
                              _processPayload(result['data']!, result['key']!);
                              break;
                            }
                          }
                        }
                      }
                    },
                  ),
                  _buildScannerOverlay(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          TextButton(
            onPressed: () => setState(() => _isScanning = false),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final now = DateTime.now();
    final nextPeriod = _data!.nextPeriodDate;
    final daysUntil = nextPeriod.difference(now).inDays;
    
    final inWindow = now.isAfter(_data!.fertilityWindowStart) && now.isBefore(_data!.fertilityWindowEnd);
    final daysUntilWindow = _data!.fertilityWindowStart.difference(now).inDays;

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Privacy First: This is a read-only view. No logs are shared.",
              style: TextStyle(fontSize: 12, color: Colors.black45, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
            const Text(
              "Partner's Cycle",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            
            // Period Countdown
            _InfoCard(
              title: "Next Period",
              value: daysUntil > 0 ? "in $daysUntil days" : "Today",
              subValue: DateFormat('MMMM d, yyyy').format(nextPeriod),
              icon: Icons.calendar_today,
              color: AppTheme.primaryColor,
            ),
            
            const SizedBox(height: 16),
            
            // Fertility Window
            _InfoCard(
              title: "Fertility Window",
              value: inWindow 
                  ? "Active Now" 
                  : (daysUntilWindow > 0 ? "in $daysUntilWindow days" : "Passed"),
              subValue: "${DateFormat('MMM d').format(_data!.fertilityWindowStart)} - ${DateFormat('MMM d').format(_data!.fertilityWindowEnd)}",
              icon: Icons.bubble_chart,
              color: Colors.green,
              isActive: inWindow,
            ),
            
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Note",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Predictions are based on previous cycles and are for informational purposes only. Data was last updated:",
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, h:mm a').format(_data!.generatedAt),
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
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

  const _InfoCard({
    required this.title,
    required this.value,
    required this.subValue,
    required this.icon,
    required this.color,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(
        color: isActive ? color.withOpacity(0.2) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isActive ? color : Colors.black87,
                ),
              ),
              Text(
                subValue,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
