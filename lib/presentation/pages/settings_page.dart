import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/notification_orchestrator.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/preferences_service.dart';
import '../../core/utils/security_logger.dart';
import '../../data/services/export_service.dart';
import '../../data/storage/backup_orchestrator.dart';
import '../../data/storage/encrypted_storage_service.dart';
import '../providers/cloud_sync_provider.dart';
import '../providers/cycle_provider.dart';
import '../theme/app_theme.dart';
import 'partner_mode_page.dart';
import 'share_prediction_page.dart';

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

  bool _periodReminderEnabled = false;
  int _periodReminderOffset = 1;
  TimeOfDay _periodReminderTime = const TimeOfDay(hour: 9, minute: 0);

  bool _fertilityReminderEnabled = false;
  int _fertilityReminderOffset = 1;
  TimeOfDay _fertilityReminderTime = const TimeOfDay(hour: 9, minute: 0);

  CloudSyncProvider? _syncProvider;

  @override
  void initState() {
    super.initState();
    _loadSettings();

    // (C6) Listen to sync errors outside of the build method
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncProvider = context.read<CloudSyncProvider>();
      _syncProvider?.addListener(_syncErrorListener);
    });
  }

  @override
  void dispose() {
    _syncProvider?.removeListener(_syncErrorListener);
    super.dispose();
  }

  void _syncErrorListener() {
    if (!mounted || _syncProvider == null) return;

    // (W10) Prioritize recovery UI: Hide technical sync errors if the recovery prompt is active
    if (_syncProvider!.requiresRecoveryPrompt) {
      _syncProvider?.clearError();
      return;
    }

    if (_syncProvider!.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync Error: ${_sanitizeError(_syncProvider!.lastError!)}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'DISMISS',
            textColor: Colors.white,
            onPressed: () => _syncProvider?.clearError(),
          ),
        ),
      );
      _syncProvider?.clearError();
    }
  }

  String _sanitizeError(Object error) {
    // (W10) Error Sanitization: Prevent information leakage in UI
    final errorStr = error.toString();
    final lowerError = errorStr.toLowerCase();

    if (lowerError.contains('password') || lowerError.contains('key')) {
      return 'Authentication failed. Please verify your credentials.';
    }
    if (lowerError.contains('notfound') || lowerError.contains('404')) {
      return 'Backup not found on cloud.';
    }
    if (lowerError.contains('network') ||
        lowerError.contains('socket') ||
        lowerError.contains('timeout')) {
      return 'Connection timed out. Please check your internet.';
    }

    // Check if it's a CloudSyncException and extract its message
    if (errorStr.contains('CloudSyncException:')) {
      final parts = errorStr.split('CloudSyncException:');
      if (parts.length > 1) {
        // Return the standardized message part
        return parts[1].split('(Original error:')[0].trim();
      }
    }

    return 'An unexpected error occurred. Please try again later.';
  }

  Future<void> _loadSettings() async {
    final authService = context.read<AuthService>();
    final prefs = context.read<PreferencesService>();
    final supported = await authService.isHardwareSupported();
    final biometric = await prefs.isBiometricEnabled();
    final notifications = await prefs.isNotificationsEnabled();
    final time = await prefs.getNotificationTime();

    final periodEnabled = await prefs.isPeriodReminderEnabled();
    final periodOffset = await prefs.getPeriodReminderOffset();
    final periodTime = await prefs.getPeriodReminderTime();

    final fertilityEnabled = await prefs.isFertilityReminderEnabled();
    final fertilityOffset = await prefs.getFertilityReminderOffset();
    final fertilityTime = await prefs.getFertilityReminderTime();

    if (mounted) {
      setState(() {
        _hardwareSupported = supported;
        _biometricEnabled = biometric;
        _notificationsEnabled = notifications;
        _reminderTime = time;
        _periodReminderEnabled = periodEnabled;
        _periodReminderOffset = periodOffset;
        _periodReminderTime = periodTime;
        _fertilityReminderEnabled = fertilityEnabled;
        _fertilityReminderOffset = fertilityOffset;
        _fertilityReminderTime = fertilityTime;
      });
    }
  }

  Future<void> _handleExportData() async {
    unawaited(HapticFeedback.mediumImpact());
    setState(() => _isExporting = true);
    final storage = context.read<EncryptedStorageService>();
    try {
      final csvString = await storage.exportDataToCsv();
      await ExportService.shareCsvFile(csvString);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    unawaited(HapticFeedback.selectionClick());
    final authService = context.read<AuthService>();
    final prefs = context.read<PreferencesService>();
    final success = await authService.authenticate();
    if (success) {
      await prefs.setBiometricEnabled(value);
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
    unawaited(HapticFeedback.selectionClick());
    final notificationService = context.read<NotificationService>();
    if (value) {
      final granted = await notificationService.requestPermissions();
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
      await _triggerOrchestrator();
    } else {
      await notificationService.cancelNotification(NotificationService.dailyReminderId);
    }

    if (!mounted) return;
    final prefs = context.read<PreferencesService>();
    await prefs.setNotificationsEnabled(value);
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
    final TimeOfDay? picked = await _showTimePicker(_reminderTime);
    if (picked != null && picked != _reminderTime) {
      if (!mounted) return;
      setState(() => _reminderTime = picked);
      await context.read<PreferencesService>().setNotificationTime(picked);
      if (_notificationsEnabled) {
        await _scheduleReminder();
      }
    }
  }

  Future<void> _updatePeriodOffset(int value) async {
    final prefs = context.read<PreferencesService>();
    await prefs.setPeriodReminderOffset(value);
    setState(() => _periodReminderOffset = value);
    await _triggerOrchestrator();
  }

  Future<void> _updateFertilityOffset(int value) async {
    final prefs = context.read<PreferencesService>();
    await prefs.setFertilityReminderOffset(value);
    setState(() => _fertilityReminderOffset = value);
    await _triggerOrchestrator();
  }

  Future<void> _togglePeriodReminder(bool value) async {
    unawaited(HapticFeedback.selectionClick());
    final prefs = context.read<PreferencesService>();
    await prefs.setPeriodReminderEnabled(value);
    setState(() => _periodReminderEnabled = value);
    await _triggerOrchestrator();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Period reminders enabled' : 'Period reminders disabled'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
  }

  Future<void> _toggleFertilityReminder(bool value) async {
    unawaited(HapticFeedback.selectionClick());
    final prefs = context.read<PreferencesService>();
    await prefs.setFertilityReminderEnabled(value);
    setState(() => _fertilityReminderEnabled = value);
    await _triggerOrchestrator();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Fertility reminders enabled' : 'Fertility reminders disabled'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
  }

  Future<void> _selectPeriodTime() async {
    final TimeOfDay? picked = await _showTimePicker(_periodReminderTime);
    if (picked != null && picked != _periodReminderTime) {
      if (!mounted) return;
      setState(() => _periodReminderTime = picked);
      await context.read<PreferencesService>().setPeriodReminderTime(picked);
      await _triggerOrchestrator();
    }
  }

  Future<void> _selectFertilityTime() async {
    final TimeOfDay? picked = await _showTimePicker(_fertilityReminderTime);
    if (picked != null && picked != _fertilityReminderTime) {
      if (!mounted) return;
      setState(() => _fertilityReminderTime = picked);
      await context.read<PreferencesService>().setFertilityReminderTime(picked);
      await _triggerOrchestrator();
    }
  }

  Future<TimeOfDay?> _showTimePicker(TimeOfDay initialTime) async {
    unawaited(HapticFeedback.lightImpact());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;

    return await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: primary,
                    onPrimary: AppTheme.backgroundDarkColor,
                    surface: AppTheme.backgroundDarkColor,
                  )
                : ColorScheme.light(primary: primary, onPrimary: Colors.white, onSurface: primary),
          ),
          child: child!,
        );
      },
    );
  }

  Future<void> _triggerOrchestrator() async {
    final orchestrator = context.read<NotificationOrchestrator>();
    final trends = context.read<CycleProvider>().trends;
    await orchestrator.updateScheduledReminders(trends);
  }

  Future<void> _handleCreateBackup() async {
    unawaited(HapticFeedback.mediumImpact());
    final backupOrchestrator = context.read<BackupOrchestrator>();
    final password = await _showPasswordDialog(
      title: 'Create Backup',
      message:
          'Enter a password to encrypt your backup. You will need this password to restore your data later.',
      isCreate: true,
    );

    if (password != null && password.isNotEmpty) {
      if (!mounted) return;
      setState(() => _isExporting = true);
      try {
        final file = await backupOrchestrator.exportEncryptedBackup(password);
        final xFile = XFile(file.path);
        await SharePlus.instance.share(
          ShareParams(files: [xFile], text: 'Private Tracker Encrypted Backup'),
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
            SnackBar(content: Text('Failed to create backup: $e'), backgroundColor: Colors.red),
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
    unawaited(HapticFeedback.mediumImpact());

    FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(type: FileType.any);
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

      final backupOrchestrator = context.read<BackupOrchestrator>();
      final file = File(path);

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Restore Backup?',
            style: TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'This will COMPLETELY OVERWRITE your current local data. This action cannot be undone.',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text(
                'Overwrite & Restore',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
            await backupOrchestrator.importEncryptedBackup(file, password);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data restored successfully!'),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            }
          } catch (e, stack) {
            debugPrint('Failed to restore backup: $e\n$stack');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to restore backup: $e'),
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
        scrollable: true,
        title: Text(
          title,
          style: const TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black54,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: controller,
                obscureText: true,
                style: const TextStyle(fontFamily: AppTheme.fontFamily),
                decoration: InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
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
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
            child: Text(
              'Continue',
              style: TextStyle(
                color: isDark ? AppTheme.backgroundDarkColor : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scheduleReminder() async {
    await context.read<NotificationService>().scheduleDailyReminder(
      id: 100,
      time: _reminderTime,
      title: 'Time to log',
      body: 'Don\'t forget to record your symptoms and cycle data today.',
    );
  }

  Widget _buildCloudProviderCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;
    return Container(
      decoration: AppTheme.glassDecoration(isDark: isDark, borderRadius: 24),
      child: _buildSettingsItem(
        icon: icon,
        iconColor: primary,
        title: title,
        subtitle: subtitle,
        isDark: isDark,
        trailing: Switch.adaptive(
          value: enabled,
          onChanged: (val) {
            unawaited(HapticFeedback.selectionClick());
            onChanged(val);
          },
          activeThumbColor: primary,
        ),
      ),
    );
  }

  Widget _buildRecoverySecurityCard(
    BuildContext context,
    CloudSyncProvider syncProvider,
    bool isDark,
    Color primary,
  ) {
    // --- Orphan Key: cloud backup encrypted with a lost machine key ---
    if (syncProvider.isOrphanKey) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.glassDecoration(
          isDark: isDark,
          borderRadius: 24,
          borderColor: Colors.redAccent.withValues(alpha: 0.3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_reset_rounded, color: Colors.redAccent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Cloud Backup Unrecoverable",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "The encryption key for your cloud backup was lost (e.g. during an OS security event). Your local data is safe. You can overwrite the cloud with your current local data to restore sync.",
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: syncProvider.isSyncing
                    ? null
                    : () => _handleOverwriteCloudWithLocal(syncProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: isDark ? Colors.black87 : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: syncProvider.isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text("USE LOCAL DATA", style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _handleResetCloudSync(syncProvider),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.white38 : Colors.black38,
              ),
              child: const Text(
                "RESET & START OVER",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
              ),
            ),
          ],
        ),
      );
    }

    // --- Recovery Passphrase Required ---
    if (syncProvider.requiresRecoveryPrompt) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.glassDecoration(
          isDark: isDark,
          borderRadius: 24,
          borderColor: Colors.orange.withValues(alpha: 0.3),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Action Required",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "An encrypted backup was found in the cloud. Enter your recovery passphrase to restore access to your data.",
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _handleRestoreWithPassphrase(syncProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  "RECOVER CLOUD DATA",
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _handleResetCloudSync(syncProvider),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.white38 : Colors.black38,
              ),
              child: const Text(
                "RESET & START OVER",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
              ),
            ),
          ],
        ),
      );
    }

    // --- Migration Required: machine-key user must set a passphrase ---
    if (syncProvider.needsPassphraseMigration) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.glassDecoration(
          isDark: isDark,
          borderRadius: 24,
          borderColor: Colors.deepPurple.withValues(alpha: 0.3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security_update_good_rounded, color: Colors.deepPurple, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Security Upgrade Required",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Cloud sync now requires a recovery passphrase to protect your data. "
              "Without one, your backup cannot be restored if you switch devices or reinstall the app. "
              "Set a passphrase to continue syncing.",
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: syncProvider.isSyncing
                    ? null
                    : () => _handlePassphraseMigration(syncProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: syncProvider.isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        "SET RECOVERY PASSPHRASE",
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ),
      );
    }

    // --- Initial Setup Required: first-time user must set passphrase ---
    if (syncProvider.needsInitialSetup) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.glassDecoration(
          isDark: isDark,
          borderRadius: 24,
          borderColor: primary.withValues(alpha: 0.3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.enhanced_encryption_rounded, color: primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Set Recovery Passphrase",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "A recovery passphrase is required to encrypt your cloud backup. "
              "You'll need it to restore your data on a new device.",
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: syncProvider.isSyncing
                    ? null
                    : () => _handleInitialCloudSetup(syncProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: isDark ? Colors.black87 : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  "CREATE PASSPHRASE",
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => syncProvider.cancelCloudSetup(),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? Colors.white38 : Colors.black38,
                ),
                child: const Text(
                  "CANCEL SETUP",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: AppTheme.glassDecoration(isDark: isDark, borderRadius: 24),
      child: _buildSettingsItem(
        icon: syncProvider.isRecoveryEnabled
            ? Icons.verified_user_rounded
            : Icons.gpp_maybe_rounded,
        iconColor: syncProvider.isRecoveryEnabled ? Colors.green : Colors.orange,
        title: "Recovery Security",
        subtitle: syncProvider.isRecoveryEnabled
            ? "Tap to change passphrase"
            : "Required for new device restore",
        isDark: isDark,
        onTap: () => _handleSetupRecovery(syncProvider),
        trailing: syncProvider.isRecoveryEnabled
            ? const Text(
                "CHANGE",
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
              )
            : const Text(
                "SET UP",
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
              ),
      ),
    );
  }

  Future<void> _handleSetupRecovery(CloudSyncProvider provider) async {
    unawaited(HapticFeedback.mediumImpact());

    // Branch: if recovery is already enabled, route to the change passphrase flow.
    if (provider.isRecoveryEnabled) {
      await _handleChangePassphrase(provider);
      return;
    }

    final passphrase = await _showPasswordDialog(
      title: 'Set Recovery Passphrase',
      message:
          'This passphrase encrypts your cloud backups. You will need it to restore your data on a new device. Keep it somewhere safe — it can be changed later from this screen.',
      isCreate: true,
    );

    if (passphrase != null && mounted) {
      await provider.setupRecovery(passphrase);
      if (mounted && provider.lastError == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recovery security enabled!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// Shows an enhanced passphrase creation dialog with full security warnings.
  ///
  /// Used for both initial cloud sync setup and machine-key migration.
  /// Includes: explanation, irrecoverability warning, and password manager suggestion.
  Future<String?> _showCloudPassphraseSetupDialog({required String title}) async {
    final controller = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Row(
          children: [
            Icon(Icons.enhanced_encryption_rounded, color: primary, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Explanation
              Text(
                'Your cloud backup is encrypted end-to-end. This passphrase is the '
                'only way to decrypt and restore your data on a new device.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black54,
                  fontFamily: AppTheme.fontFamily,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              // Warning box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'If you forget this passphrase, your cloud backup cannot be recovered. '
                        'There is no reset option. We recommend saving it in a password manager '
                        'or writing it down somewhere safe.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.red.shade200 : Colors.red.shade700,
                          fontFamily: AppTheme.fontFamily,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: controller,
                obscureText: true,
                style: const TextStyle(fontFamily: AppTheme.fontFamily),
                decoration: InputDecoration(
                  labelText: 'Recovery Passphrase',
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Passphrase is required';
                  if (value.length < 8) return 'Minimum 8 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                style: const TextStyle(fontFamily: AppTheme.fontFamily),
                decoration: InputDecoration(
                  labelText: 'Confirm Passphrase',
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value != controller.text) return 'Passphrases do not match';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Password manager suggestion
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tip: Use a password manager like Bitwarden or Google Passwords.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Encrypt & Sync',
              style: TextStyle(
                color: isDark ? AppTheme.backgroundDarkColor : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handles first-time cloud sync setup: passphrase creation before first upload.
  Future<void> _handleInitialCloudSetup(CloudSyncProvider provider) async {
    unawaited(HapticFeedback.mediumImpact());
    final passphrase = await _showCloudPassphraseSetupDialog(title: 'Create Recovery Passphrase');

    if (passphrase != null && mounted) {
      await provider.setupRecovery(passphrase);
      if (mounted && provider.lastError == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cloud sync enabled with passphrase protection!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (mounted) {
      // User cancelled — revert the toggle
      await provider.cancelCloudSetup();
    }
  }

  /// Handles machine-key → passphrase migration for existing users.
  Future<void> _handlePassphraseMigration(CloudSyncProvider provider) async {
    unawaited(HapticFeedback.mediumImpact());
    final passphrase = await _showCloudPassphraseSetupDialog(title: 'Security Upgrade');

    if (passphrase != null && mounted) {
      await provider.migrateToPassphrase(passphrase);
      if (mounted && provider.lastError == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup upgraded to passphrase protection!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted && provider.lastError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.lastError!), backgroundColor: Colors.redAccent),
        );
        provider.clearError();
      }
    }
  }

  /// Shows the change-passphrase dialog and calls [provider.changePassphrase].
  ///
  /// Collects: old passphrase (for proof-of-knowledge), new passphrase, confirm new.
  /// The old passphrase verification happens server-side via a cloud decrypt round-trip.
  Future<void> _handleChangePassphrase(CloudSyncProvider provider) async {
    unawaited(HapticFeedback.mediumImpact());

    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Change Passphrase',
          style: TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your current passphrase to verify identity, then set a new one. This will re-encrypt your cloud backup.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black54,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: oldController,
                obscureText: true,
                style: const TextStyle(fontFamily: AppTheme.fontFamily),
                decoration: InputDecoration(
                  labelText: 'Current Passphrase',
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newController,
                obscureText: true,
                style: const TextStyle(fontFamily: AppTheme.fontFamily),
                decoration: InputDecoration(
                  labelText: 'New Passphrase',
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length < 8) return 'Minimum 8 characters';
                  if (v == oldController.text) return 'New passphrase must differ from current';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                style: const TextStyle(fontFamily: AppTheme.fontFamily),
                decoration: InputDecoration(
                  labelText: 'Confirm New Passphrase',
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) => (v != newController.text) ? 'Passphrases do not match' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, {'old': oldController.text, 'new': newController.text});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Change',
              style: TextStyle(
                color: isDark ? AppTheme.backgroundDarkColor : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      await provider.changePassphrase(result['old']!, result['new']!);
      if (mounted) {
        if (provider.lastError == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Passphrase changed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(provider.lastError!), backgroundColor: Colors.redAccent),
          );
          provider.clearError();
        }
      }
    }
  }

  /// Handles the "USE LOCAL DATA" action from the orphan key card.
  ///
  /// Shows a confirmation dialog (the action overwrites cloud data), then
  /// proceeds with biometric auth before calling [provider.overwriteCloudWithLocal].
  Future<void> _handleOverwriteCloudWithLocal(CloudSyncProvider provider) async {
    unawaited(HapticFeedback.heavyImpact());

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Overwrite Cloud Backup?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'This will replace the cloud backup with your current local data. The old cloud backup will be permanently deleted. Your local data will NOT be affected.',
          style: TextStyle(fontFamily: AppTheme.fontFamily),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text(
              'Yes, Overwrite Cloud',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await provider.overwriteCloudWithLocal();
      if (mounted) {
        if (provider.lastError == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cloud backup restored from local data.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(provider.lastError!), backgroundColor: Colors.redAccent),
          );
          provider.clearError();
        }
      }
    }
  }

  Future<void> _handleRestoreWithPassphrase(CloudSyncProvider provider) async {
    unawaited(HapticFeedback.mediumImpact());
    final passphrase = await _showPasswordDialog(
      title: 'Enter Recovery Passphrase',
      message: 'Enter the passphrase you set on your other device to decrypt the cloud backup.',
      isCreate: false,
    );

    if (passphrase != null && mounted) {
      await provider.restoreRecovery(passphrase);
      if (mounted && provider.lastError == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cloud data recovered successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _handleResetCloudSync(CloudSyncProvider provider) async {
    unawaited(HapticFeedback.heavyImpact());

    SecurityLogger.logInfo("UI: [WIPE-DIAG-1] Opening wipe confirmation dialog...");
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible:
          false, // (W11) Prevent accidental tap-out silently cancelling a destructive operation
      builder: (context) => AlertDialog(
        title: const Text(
          'Reset Cloud Sync?',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: const Text(
          'This will PERMANENTLY DELETE all your data from the cloud. Local data stays safe. You should only do this if you lost your password.',
          style: TextStyle(fontFamily: AppTheme.fontFamily),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Yes, Wipe Cloud Data',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    SecurityLogger.logInfo(
      "UI: [WIPE-DIAG-2] Confirmation dialog closed. Result: $confirm, mounted: $mounted",
    );

    if (confirm == true && mounted) {
      SecurityLogger.logInfo("UI: [WIPE-DIAG-3] User confirmed wipe. Requesting biometric auth...");
      final authService = context.read<AuthService>();
      SecurityLogger.logInfo("UI: [WIPE-DIAG-4] AuthService acquired. Calling authenticate()...");
      final authenticated = await authService.authenticate();
      SecurityLogger.logInfo("UI: [WIPE-DIAG-5] authenticate() returned. Result: $authenticated");

      if (authenticated && mounted) {
        SecurityLogger.logInfo(
          "UI: [WIPE-DIAG-6] Auth success. Calling provider.resetCloudData()...",
        );
        await provider.resetCloudData();
        if (mounted && provider.lastError == null) {
          SecurityLogger.logInfo("UI: [WIPE-DIAG-7] Wipe complete. No errors reported.");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cloud sync reset successfully.'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        } else if (mounted) {
          SecurityLogger.logInfo(
            "UI: [WIPE-DIAG-7] Wipe completed with error: ${provider.lastError}",
          );
        }
      } else if (mounted) {
        SecurityLogger.logInfo(
          "UI: [WIPE-DIAG-6] Biometric auth failed or cancelled. Aborting wipe.",
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Authentication failed. Reset aborted.")));
      }
    } else {
      SecurityLogger.logInfo("UI: [WIPE-DIAG-3] Wipe aborted. confirm=$confirm, mounted=$mounted");
    }
  }

  String _formatRelativeTime(DateTime? time) {
    if (time == null) return "Never";
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
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
    return Material(
      color: Colors.transparent,
      child: ListTile(
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
        trailing:
            trailing ??
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black26,
            ),
      ),
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
                    child: Divider(
                      height: 1,
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    ),
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

          const SizedBox(height: 16),
          Container(
            decoration: AppTheme.glassDecoration(isDark: isDark, borderRadius: 24),
            child: Column(
              children: [
                _buildSettingsItem(
                  icon: Icons.calendar_month_rounded,
                  iconColor: primary,
                  title: "Period Reminder",
                  subtitle: "Warning before period starts",
                  isDark: isDark,
                  trailing: Switch.adaptive(
                    value: _periodReminderEnabled,
                    onChanged: _togglePeriodReminder,
                    activeThumbColor: primary,
                    activeTrackColor: primary.withValues(alpha: 0.5),
                  ),
                ),
                if (_periodReminderEnabled) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 64),
                    child: Divider(
                      height: 1,
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  _buildSettingsItem(
                    icon: Icons.history_rounded,
                    iconColor: primary,
                    title: "Advance Warning",
                    subtitle:
                        "$_periodReminderOffset day${_periodReminderOffset > 1 ? 's' : ''} before",
                    isDark: isDark,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                          onPressed: _periodReminderOffset > 0
                              ? () => _updatePeriodOffset(_periodReminderOffset - 1)
                              : null,
                          color: primary,
                        ),
                        Text(
                          "$_periodReminderOffset",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                          onPressed: _periodReminderOffset < 7
                              ? () => _updatePeriodOffset(_periodReminderOffset + 1)
                              : null,
                          color: primary,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 64),
                    child: Divider(
                      height: 1,
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  _buildSettingsItem(
                    icon: Icons.access_time_rounded,
                    iconColor: primary,
                    title: "Reminder Time",
                    subtitle: "At ${_periodReminderTime.format(context)}",
                    isDark: isDark,
                    onTap: _selectPeriodTime,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: AppTheme.glassDecoration(isDark: isDark, borderRadius: 24),
            child: Column(
              children: [
                _buildSettingsItem(
                  icon: Icons.spa_rounded,
                  iconColor: primary,
                  title: "Fertility Reminder",
                  subtitle: "Warning before fertile window",
                  isDark: isDark,
                  trailing: Switch.adaptive(
                    value: _fertilityReminderEnabled,
                    onChanged: _toggleFertilityReminder,
                    activeThumbColor: primary,
                    activeTrackColor: primary.withValues(alpha: 0.5),
                  ),
                ),
                if (_fertilityReminderEnabled) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 64),
                    child: Divider(
                      height: 1,
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  _buildSettingsItem(
                    icon: Icons.history_rounded,
                    iconColor: primary,
                    title: "Advance Warning",
                    subtitle:
                        "$_fertilityReminderOffset day${_fertilityReminderOffset > 1 ? 's' : ''} before",
                    isDark: isDark,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                          onPressed: _fertilityReminderOffset > 0
                              ? () => _updateFertilityOffset(_fertilityReminderOffset - 1)
                              : null,
                          color: primary,
                        ),
                        Text(
                          "$_fertilityReminderOffset",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                          onPressed: _fertilityReminderOffset < 7
                              ? () => _updateFertilityOffset(_fertilityReminderOffset + 1)
                              : null,
                          color: primary,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 64),
                    child: Divider(
                      height: 1,
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  _buildSettingsItem(
                    icon: Icons.access_time_rounded,
                    iconColor: primary,
                    title: "Reminder Time",
                    subtitle: "At ${_fertilityReminderTime.format(context)}",
                    isDark: isDark,
                    onTap: _selectFertilityTime,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          _buildSectionHeader("Cloud Synchronization", isDark),
          Consumer<CloudSyncProvider>(
            builder: (context, syncProvider, _) {
              return Column(
                children: [
                  _buildCloudProviderCard(
                    context: context,
                    isDark: isDark,
                    title: "Google Drive",
                    subtitle: "Personal hidden storage",
                    icon: Icons.add_to_drive_rounded,
                    enabled: syncProvider.isGoogleDriveEnabled,
                    onChanged: (val) async {
                      await syncProvider.toggleGoogleDrive(val);
                      if (!mounted || !val) return;
                      // After toggle-on, check if any setup dialog is needed
                      if (syncProvider.needsInitialSetup) {
                        await _handleInitialCloudSetup(syncProvider);
                      } else if (syncProvider.needsPassphraseMigration) {
                        await _handlePassphraseMigration(syncProvider);
                      } else if (syncProvider.requiresRecoveryPrompt) {
                        await _handleRestoreWithPassphrase(syncProvider);
                      }
                    },
                  ),
                  if (Platform.isIOS) ...[
                    const SizedBox(height: 12),
                    _buildCloudProviderCard(
                      context: context,
                      isDark: isDark,
                      title: "iCloud",
                      subtitle: "Native Apple sync",
                      icon: Icons.cloud_queue_rounded,
                      enabled: syncProvider.isiCloudEnabled,
                      onChanged: (val) => syncProvider.toggleICloud(val),
                    ),
                  ],
                  if (syncProvider.isCloudEnabled) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.glassDecoration(isDark: isDark, borderRadius: 24),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Cloud Status",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    syncProvider.isSyncing
                                        ? "Syncing in background..."
                                        : "Last sync: ${_formatRelativeTime(syncProvider.lastSyncTime)}",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              if (syncProvider.isSyncing)
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 3),
                                )
                              else
                                Icon(Icons.check_circle_rounded, color: primary, size: 28),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed:
                                      (syncProvider.isSyncing ||
                                          syncProvider.requiresRecoveryPrompt ||
                                          syncProvider.isOrphanKey)
                                      ? null
                                      : () => syncProvider.sync(),
                                  icon: const Icon(Icons.sync_rounded, size: 18),
                                  label: const Text(
                                    "SYNC NOW",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: primary,
                                    side: BorderSide(color: primary.withValues(alpha: 0.5)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: () => _handleResetCloudSync(syncProvider),
                                icon: const Icon(
                                  Icons.delete_sweep_rounded,
                                  color: Colors.redAccent,
                                ),
                                tooltip: "Reset Cloud Data",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRecoverySecurityCard(context, syncProvider, isDark, primary),
                  ],
                ],
              );
            },
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
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: _isExporting ? null : _handleExportData,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 64),
                  child: Divider(
                    height: 1,
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  ),
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
                  child: Divider(
                    height: 1,
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  ),
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
                    unawaited(HapticFeedback.lightImpact());
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SharePredictionPage()),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 64),
                  child: Divider(
                    height: 1,
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                _buildSettingsItem(
                  icon: Icons.favorite_rounded,
                  iconColor: Colors.redAccent,
                  title: "Partner Mode",
                  subtitle: "View shared predictions",
                  isDark: isDark,
                  onTap: () {
                    unawaited(HapticFeedback.lightImpact());
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
