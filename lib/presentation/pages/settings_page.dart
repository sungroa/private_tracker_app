import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../data/storage/encrypted_storage_service.dart';
import '../../data/services/export_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notification_service.dart';
import '../theme/app_theme.dart';
import 'share_prediction_page.dart';
import 'partner_mode_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isExporting = false;
  bool _biometricEnabled = false;
  bool _hardwareSupported = false;
  bool _notificationsEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final supported = await AuthService.instance.isHardwareSupported();
    final biometric = await AuthService.instance.isBiometricEnabled();
    final notifications = await AuthService.instance.isNotificationsEnabled();
    final time = await AuthService.instance.getNotificationTime();
    
    if (mounted) {
      setState(() {
        _hardwareSupported = supported;
        _biometricEnabled = biometric;
        _notificationsEnabled = notifications;
        _reminderTime = time;
      });
    }
  }

  Future<void> _handleExportData() async {
    HapticFeedback.mediumImpact();
    setState(() => _isExporting = true);
    final storage = context.read<EncryptedStorageService>();
    try {
      final csvString = await storage.exportDataToCsv();
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

  Future<void> _toggleBiometric(bool value) async {
    HapticFeedback.selectionClick();
    final success = await AuthService.instance.authenticate();
    if (success) {
      await AuthService.instance.setBiometricEnabled(value);
      setState(() => _biometricEnabled = value);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'Biometric lock enabled' : 'Biometric lock disabled'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    HapticFeedback.selectionClick();
    if (value) {
      final granted = await NotificationService.instance.requestPermissions();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification permissions are required for reminders.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      await _scheduleReminder();
    } else {
      await NotificationService.instance.cancelAllNotifications();
    }

    await AuthService.instance.setNotificationsEnabled(value);
    setState(() => _notificationsEnabled = value);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Daily reminders enabled' : 'Daily reminders disabled'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
  }

  Future<void> _selectTime() async {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark 
                ? ColorScheme.dark(primary: primary, onPrimary: AppTheme.backgroundDarkColor, surface: AppTheme.backgroundDarkColor)
                : ColorScheme.light(primary: primary, onPrimary: Colors.white, onSurface: primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _reminderTime) {
      setState(() => _reminderTime = picked);
      await AuthService.instance.setNotificationTime(picked);
      if (_notificationsEnabled) {
        await _scheduleReminder();
      }
    }
  }

  Future<void> _handleCreateBackup() async {
    HapticFeedback.mediumImpact();
    final storage = context.read<EncryptedStorageService>();
    final password = await _showPasswordDialog(
      title: 'Create Backup',
      message: 'Enter a password to encrypt your backup. You will need this password to restore your data later.',
      isCreate: true,
    );

    if (password != null && password.isNotEmpty) {
      if (!mounted) return;
      setState(() => _isExporting = true);
      try {
        final file = await storage.exportEncryptedBackup(password);
        final xFile = XFile(file.path);
        await SharePlus.instance.share(
          ShareParams(
            files: [xFile],
            text: 'Private Tracker Encrypted Backup',
          ),
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Backup created and ready to share'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create backup: $e'),
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
  }

  Future<void> _handleRestoreBackup() async {
    HapticFeedback.mediumImpact();
    
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
    } on PlatformException catch (e) {
      debugPrint('File picker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to open file picker. Please check storage permissions.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      if (!path.toLowerCase().endsWith('.enc')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid file type. Please select a .enc backup file.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final storage = context.read<EncryptedStorageService>();
      final file = File(path);
      
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore Backup?', style: TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.bold)),
          content: const Text('This will COMPLETELY OVERWRITE your current local data. This action cannot be undone.', style: TextStyle(fontFamily: AppTheme.fontFamily)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Overwrite & Restore', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        final password = await _showPasswordDialog(
          title: 'Restore Backup',
          message: 'Enter the password used to encrypt this backup.',
          isCreate: false,
        );
        if (password != null && password.isNotEmpty) {
          setState(() => _isExporting = true);
          try {
            await storage.importEncryptedBackup(file, password);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data restored successfully!'),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to restore backup: Incorrect password or corrupted file'),
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
      }
    }
  }

  Future<String?> _showPasswordDialog({
    required String title,
    required String message,
    required bool isCreate,
  }) async {
    final controller = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: TextStyle(fontSize: 14, color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black54, fontFamily: AppTheme.fontFamily)),
              const SizedBox(height: 20),
              TextFormField(
                controller: controller,
                obscureText: true,
                style: const TextStyle(fontFamily: AppTheme.fontFamily),
                decoration: InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Password is required';
                  if (isCreate && value.length < 8) return 'Minimum 8 characters';
                  return null;
                },
              ),
              if (isCreate) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmController,
                  obscureText: true,
                  style: const TextStyle(fontFamily: AppTheme.fontFamily),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (value) {
                    if (value != controller.text) return 'Passwords do not match';
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Continue', style: TextStyle(color: isDark ? AppTheme.backgroundDarkColor : Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _scheduleReminder() async {
    await NotificationService.instance.scheduleDailyReminder(
      id: 100, 
      time: _reminderTime,
      title: 'Time to log',
      body: 'Don\'t forget to record your symptoms and cycle data today.',
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 12.0, top: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor,
          letterSpacing: 1.2,
          fontFamily: AppTheme.fontFamily,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isDark = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
          fontFamily: AppTheme.fontFamily,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black54,
          fontFamily: AppTheme.fontFamily,
          fontSize: 13,
        ),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black26),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            "Settings",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: primary,
              fontFamily: AppTheme.fontFamily,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 32),
          
          // Security Section
          if (_hardwareSupported) ...[
            _buildSectionHeader("Security", isDark),
            Container(
              decoration: AppTheme.glassDecoration(isDark: isDark, borderRadius: 24),
              child: _buildSettingsItem(
                icon: Icons.fingerprint_rounded,
                iconColor: primary,
                title: "Biometric Lock",
                subtitle: "FaceID, TouchID, or PIN",
                isDark: isDark,
                trailing: Switch.adaptive(
                  value: _biometricEnabled,
                  onChanged: _toggleBiometric,
                  activeThumbColor: primary,
                  activeTrackColor: primary.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],

          _buildSectionHeader("Reminders", isDark),
          Container(
            decoration: AppTheme.glassDecoration(isDark: isDark, borderRadius: 24),
            child: Column(
              children: [
                _buildSettingsItem(
                  icon: Icons.notifications_active_rounded,
                  iconColor: primary,
                  title: "Daily Reminders",
                  subtitle: "Never miss a log",
                  isDark: isDark,
                  trailing: Switch.adaptive(
                    value: _notificationsEnabled,
                    onChanged: _toggleNotifications,
                    activeThumbColor: primary,
                    activeTrackColor: primary.withValues(alpha: 0.5),
                  ),
                ),
                if (_notificationsEnabled) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 64),
                    child: Divider(height: 1, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                  ),
                  _buildSettingsItem(
                    icon: Icons.access_time_rounded,
                    iconColor: primary,
                    title: "Reminder Time",
                    subtitle: _reminderTime.format(context),
                    isDark: isDark,
                    onTap: _selectTime,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          _buildSectionHeader("Data Management", isDark),
          Container(
            decoration: AppTheme.glassDecoration(isDark: isDark, borderRadius: 24),
            child: Column(
              children: [
                _buildSettingsItem(
                  icon: Icons.ios_share_rounded,
                  iconColor: primary,
                  title: "Export Data",
                  subtitle: "Save as CSV file",
                  isDark: isDark,
                  trailing: _isExporting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : null,
                  onTap: _isExporting ? null : _handleExportData,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 64),
                  child: Divider(height: 1, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                ),
                _buildSettingsItem(
                  icon: Icons.cloud_upload_rounded,
                  iconColor: primary,
                  title: "Create Backup",
                  subtitle: "Export encrypted .enc file",
                  isDark: isDark,
                  onTap: _isExporting ? null : _handleCreateBackup,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 64),
                  child: Divider(height: 1, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                ),
                _buildSettingsItem(
                  icon: Icons.restart_alt_rounded,
                  iconColor: primary,
                  title: "Restore Backup",
                  subtitle: "Overwrite from file",
                  isDark: isDark,
                  onTap: _isExporting ? null : _handleRestoreBackup,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          _buildSectionHeader("Partner Sharing", isDark),
          Container(
            decoration: AppTheme.glassDecoration(isDark: isDark, borderRadius: 24),
            child: Column(
              children: [
                _buildSettingsItem(
                  icon: Icons.qr_code_2_rounded,
                  iconColor: AppTheme.accentColor,
                  title: "Generate Share QR",
                  subtitle: "Securely share predictions",
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SharePredictionPage()),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 64),
                  child: Divider(height: 1, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                ),
                _buildSettingsItem(
                  icon: Icons.favorite_rounded,
                  iconColor: Colors.redAccent,
                  title: "Partner Mode",
                  subtitle: "View shared predictions",
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PartnerModePage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
