import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:ovarian_cyst_support_app/constants.dart';
import 'package:ovarian_cyst_support_app/screens/auth/login_screen.dart';
import 'package:ovarian_cyst_support_app/services/auth_service.dart';
import 'package:ovarian_cyst_support_app/services/sync_service.dart';
import 'package:ovarian_cyst_support_app/services/theme_service.dart';
import 'package:ovarian_cyst_support_app/screens/privacy_policy_screen.dart';
import 'package:ovarian_cyst_support_app/screens/terms_of_service_screen.dart';
import 'package:ovarian_cyst_support_app/screens/barcode_scanner_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _logger = Logger();
  bool _notificationsEnabled = true;
  bool _reminderNotificationsEnabled = true;
  bool _communityNotificationsEnabled = true;
  bool _syncOnCellular = false;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'English';
  bool _isLoggingOut = false;

  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'Arabic',
    'Swahili',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _reminderNotificationsEnabled =
          prefs.getBool('reminder_notifications_enabled') ?? true;
      _communityNotificationsEnabled =
          prefs.getBool('community_notifications_enabled') ?? true;
      _syncOnCellular = prefs.getBool('sync_on_cellular') ?? false;
      _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
      _selectedLanguage = prefs.getString('selected_language') ?? 'English';
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool(
      'reminder_notifications_enabled',
      _reminderNotificationsEnabled,
    );
    await prefs.setBool(
      'community_notifications_enabled',
      _communityNotificationsEnabled,
    );
    await prefs.setBool('sync_on_cellular', _syncOnCellular);
    await prefs.setBool('dark_mode_enabled', _darkModeEnabled);
    await prefs.setString('selected_language', _selectedLanguage);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings saved')));
    }
  }

  Future<void> _performAccountDeletion() async {
    if (!mounted) return;

    // Capture all context-dependent objects before async operations
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      // Delete user account
      await authService.deleteAccount();

      // Check if widget is still mounted before navigation
      if (mounted) {
        // Use captured navigator for navigation
        navigator.pushReplacementNamed('/login');
      }
    } catch (e) {
      _logger.e('Error deleting account: $e');

      // Check if widget is still mounted before showing error
      if (mounted) {
        // Use captured scaffoldMessenger for showing error
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to delete account. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _clearCache() async {
    if (!mounted) return;

    // Capture navigator and scaffold messenger before async operations
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Track dialog state
    bool isLoading = true;

    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return PopScope(
              canPop: false,
              child: const Center(child: CircularProgressIndicator()),
            );
          },
        );
      }

      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Dismiss loading dialog if still showing
      if (isLoading && mounted) {
        navigator.pop(); // Remove loading dialog
        isLoading = false;
      }

      // Reload preferences with default values
      await _loadPreferences();

      // Show success message if still mounted
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Cache cleared')),
        );
      }
    } catch (e) {
      // Dismiss loading dialog if still showing
      if (isLoading && mounted) {
        navigator.pop(); // Remove loading dialog
        isLoading = false;
      }

      // Show error message if still mounted
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error clearing cache: $e')),
        );
      }
    }
  }

  Future<void> _syncNow() async {
    if (!mounted) return;

    // Capture navigator and scaffold messenger before async operations
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final syncService = Provider.of<SyncService>(context, listen: false);

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      await syncService.syncAll();

      // Check if widget is still mounted after async operation
      if (!mounted) return;

      // Close loading dialog
      navigator.pop();

      // Show success message
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Data synchronized successfully')),
      );
    } catch (e) {
      // Check if widget is still mounted after async operation
      if (!mounted) return;

      // Close loading dialog
      navigator.pop();

      // Show error message
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Sync error: $e')),
      );
    }
  }

  Future<void> _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await authService.signOut();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account?'),
          content: const Text(
            'This action cannot be undone. All your data will be permanently deleted.',
            style: TextStyle(color: Colors.red),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                // Close the confirmation dialog
                Navigator.of(context).pop();

                // Perform account deletion in a separate function
                _performAccountDeletion();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Method to handle barcode scanning
  Future<void> _scanBarcode(BuildContext context) async {
    // Capture the ScaffoldMessenger context before the async gap
    final scaffoldMessengerContext = ScaffoldMessenger.of(context);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    // After the async gap, check if widget is still in the tree
    if (!mounted) return;

    // Now it's safe to use the captured scaffoldMessengerContext
    if (result != null) {
      scaffoldMessengerContext.showSnackBar(
        SnackBar(content: Text('Scanned code: $result')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Get important updates and reminders'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Appointment Reminders'),
            subtitle: const Text('Notifications for upcoming appointments'),
            value: _reminderNotificationsEnabled,
            onChanged: _notificationsEnabled
                ? (value) {
                    setState(() {
                      _reminderNotificationsEnabled = value;
                    });
                  }
                : null,
          ),
          SwitchListTile(
            title: const Text('Community Updates'),
            subtitle: const Text('Notifications from the community'),
            value: _communityNotificationsEnabled,
            onChanged: _notificationsEnabled
                ? (value) {
                    setState(() {
                      _communityNotificationsEnabled = value;
                    });
                  }
                : null,
          ),

          const Divider(),

          // Data Syncing Section
          _buildSectionHeader('Data & Syncing'),
          SwitchListTile(
            title: const Text('Sync on Mobile Data'),
            subtitle: const Text('Sync your data when on cellular connection'),
            value: _syncOnCellular,
            onChanged: (value) {
              setState(() {
                _syncOnCellular = value;
              });
            },
          ),
          ListTile(
            title: const Text('Sync Now'),
            subtitle: const Text('Force sync all data with the server'),
            trailing: const Icon(Icons.sync),
            onTap: _syncNow,
          ),
          ListTile(
            title: const Text('Clear Cache'),
            subtitle: const Text('Free up storage space'),
            trailing: const Icon(Icons.cleaning_services_outlined),
            onTap: () {
              _clearCache();
            },
          ),
          ListTile(
            title: const Text('Scan QR Code'),
            subtitle: const Text('Scan QR codes for health information'),
            trailing: const Icon(Icons.qr_code_scanner),
            onTap: () {
              _scanBarcode(context);
            },
          ),

          const Divider(),

          // Appearance Section
          _buildSectionHeader('Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Switch between light and dark theme'),
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
              });

              // Apply the theme change
              final theme = Provider.of<ThemeNotifier>(context, listen: false);
              theme.setTheme(value ? ThemeMode.dark : ThemeMode.light);

              // Save the preference
              SharedPreferences.getInstance().then((prefs) {
                prefs.setBool('dark_mode_enabled', value);
              });
            },
          ),
          ListTile(
            title: const Text('Language'),
            subtitle: Text(_selectedLanguage),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return SimpleDialog(
                    title: const Text('Select Language'),
                    children: _languages.map((language) {
                      return SimpleDialogOption(
                        onPressed: () {
                          setState(() {
                            _selectedLanguage = language;
                          });
                          Navigator.pop(context);
                        },
                        child: Text(language),
                      );
                    }).toList(),
                  );
                },
              );
            },
          ),

          const Divider(),

          // Account Section
          _buildSectionHeader('Account'),
          ListTile(
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsOfServiceScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Log Out'),
            trailing: _isLoggingOut
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            onTap: _isLoggingOut ? null : _logout,
          ),
          ListTile(
            title: const Text('Delete Account'),
            textColor: Colors.red,
            trailing: const Icon(Icons.delete_forever, color: Colors.red),
            onTap: _showDeleteAccountConfirmation,
          ),

          const SizedBox(height: 24),

          // Save button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: _savePreferences,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save Settings'),
            ),
          ),

          const SizedBox(height: 24),

          // App version
          const Center(
            child: Text(
              'OvaCare v1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
