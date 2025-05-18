import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ovarian_cyst_support_app/constants.dart';
import 'package:ovarian_cyst_support_app/screens/auth/login_screen.dart';
import 'package:ovarian_cyst_support_app/services/auth_service.dart';
import 'package:ovarian_cyst_support_app/services/sync_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
    // TODO: Load actual preferences from SharedPreferences or user profile
    setState(() {
      // Default values for now
      _notificationsEnabled = true;
      _reminderNotificationsEnabled = true;
      _communityNotificationsEnabled = true;
      _syncOnCellular = false;
      _darkModeEnabled = false;
      _selectedLanguage = 'English';
    });
  }

  Future<void> _savePreferences() async {
    // TODO: Save preferences to SharedPreferences or user profile
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings saved')));
  }

  Future<void> _syncNow() async {
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

      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data synchronized successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync error: $e')));
      }
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
              onPressed: () {
                // TODO: Implement account deletion
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Account deletion feature not yet implemented',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
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
            onChanged:
                _notificationsEnabled
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
            onChanged:
                _notificationsEnabled
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
              // TODO: Implement cache clearing
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Cache cleared')));
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
              // TODO: Implement dark mode toggling
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
                    children:
                        _languages.map((language) {
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
              // TODO: Navigate to privacy policy screen
            },
          ),
          ListTile(
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to terms of service screen
            },
          ),
          ListTile(
            title: const Text('Log Out'),
            trailing:
                _isLoggingOut
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
