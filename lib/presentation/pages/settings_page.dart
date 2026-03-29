import 'package:flutter/material.dart';
import '../../data/storage/encrypted_storage_service.dart';
import '../../data/services/export_service.dart';
import '../theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isExporting = false;

  Future<void> _handleExportData() async {
    setState(() => _isExporting = true);
    try {
      final csvString = await EncryptedStorageService.exportDataToCsv();
      await ExportService.shareCsvFile(csvString);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60), // Space for AppBar
          const Text(
            "Settings",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: AppTheme.glassDecoration(),
            child: ListTile(
              leading: const Icon(Icons.download, color: AppTheme.primaryColor),
              title: const Text(
                "Export Data",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              subtitle: const Text(
                "Save your cycle and symptom logs to a CSV file.",
                style: TextStyle(color: Colors.black54),
              ),
              trailing: _isExporting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    )
                  : const Icon(Icons.chevron_right, color: Colors.black54),
              onTap: _isExporting ? null : _handleExportData,
            ),
          ),
        ],
      ),
    );
  }
}
