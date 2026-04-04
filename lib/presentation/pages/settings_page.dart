import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../data/storage/encrypted_storage_service.dart';
import '../../data/services/export_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notification_service.dart';
import '../theme/app_theme.dart';

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
    setState(() => _isExporting = true);
    try {
      final csvString = await EncryptedStorageService.instance.exportDataToCsv();
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
    // Require authentication to change this setting for security
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
    if (value) {
      // Request permissions first
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
      
      // Schedule the reminder
      await _scheduleReminder();
    } else {
      // Cancel all notifications
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
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
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
    final password = await _showPasswordDialog(
      title: 'Create Backup',
      message: 'Enter a password to encrypt your backup. You will need this password to restore your data later.',
      isCreate: true,
    );

    if (password != null && password.isNotEmpty) {
      setState(() => _isExporting = true);
      try {
        final file = await EncryptedStorageService.instance.exportEncryptedBackup(password);
        final xFile = XFile(file.path);
        await Share.shareXFiles([xFile], text: 'Private Tracker Encrypted Backup');
        
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
    // 1. Pick file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['enc'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      
      // 2. Warning prompt
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore Backup?'),
          content: const Text('This will COMPLETELY OVERWRITE your current local data. This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Overwrite & Restore'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        // 3. Password prompt
        final password = await _showPasswordDialog(
          title: 'Restore Backup',
          message: 'Enter the password used to encrypt this backup.',
          isCreate: false,
        );

        if (password != null && password.isNotEmpty) {
          setState(() => _isExporting = true);
          try {
            await EncryptedStorageService.instance.importEncryptedBackup(file, password);
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
                SnackBar(
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

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: const TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Continue', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _scheduleReminder() async {
    await NotificationService.instance.scheduleDailyReminder(
      id: 100, // Fixed ID for daily reminder
      time: _reminderTime,
      title: 'Time to log',
      body: 'Don\'t forget to record your symptoms and cycle data today.',
    );
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
          
          // Security Section
          if (_hardwareSupported) ...[
            const Text(
              "Security",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: AppTheme.glassDecoration(),
              child: ListTile(
                leading: const Icon(Icons.fingerprint, color: AppTheme.primaryColor),
                title: const Text(
                  "Biometric Lock",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                subtitle: const Text(
                  "Lock the app with FaceID, TouchID, or PIN.",
                  style: TextStyle(color: Colors.black54),
                ),
                trailing: Switch(
                  value: _biometricEnabled,
                  onChanged: _toggleBiometric,
                  activeThumbColor: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          const Text(
            "Reminders",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: AppTheme.glassDecoration(),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_active, color: AppTheme.primaryColor),
                  title: const Text(
                    "Daily Reminders",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: const Text(
                    "Get a daily reminder to log your data.",
                    style: TextStyle(color: Colors.black54),
                  ),
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: _toggleNotifications,
                    activeThumbColor: AppTheme.primaryColor,
                  ),
                ),
                if (_notificationsEnabled) ...[
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.access_time, color: AppTheme.primaryColor),
                    title: const Text(
                      "Reminder Time",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      _reminderTime.format(context),
                      style: const TextStyle(color: Colors.black54),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.black54),
                    onTap: _selectTime,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            "Data Management",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: AppTheme.glassDecoration(),
            child: Column(
              children: [
                ListTile(
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
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.backup, color: AppTheme.primaryColor),
                  title: const Text(
                    "Create Encrypted Backup",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: const Text(
                    "Export a password-protected .enc file.",
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
                  onTap: _isExporting ? null : _handleCreateBackup,
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.settings_backup_restore, color: AppTheme.primaryColor),
                  title: const Text(
                    "Restore from Backup",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: const Text(
                    "Overwrite local data with a backup file.",
                    style: TextStyle(color: Colors.black54),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.black54),
                  onTap: _isExporting ? null : _handleRestoreBackup,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
