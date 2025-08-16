import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/theme_provider.dart';
import '../../widgets/app_bar.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  // This variable holds the user's in-app preference.
  bool _inAppNotificationsEnabled = false;
  // This variable tracks if we can show the switch at all (i.e., system permission is granted)
  bool _hasSystemPermission = false;

  @override
  void initState() {
    super.initState();
    // When the page loads, check permissions and load the user's preference.
    _initializeNotificationSettings();
  }

  /// Checks system permission and loads the user's saved preference.
  Future<void> _initializeNotificationSettings() async {
    // 1. Check the system notification permission status
    final status = await Permission.notification.status;
    setState(() {
      _hasSystemPermission = status.isGranted;
    });

    // 2. If permission is granted, load the user's in-app setting
    if (_hasSystemPermission) {
      final prefs = await SharedPreferences.getInstance();
      // Default to true if no preference has been saved before.
      setState(() {
        _inAppNotificationsEnabled = prefs.getBool('inAppNotifications') ?? true;
      });
    }
  }

  /// Handles the logic when the user toggles the switch.
  Future<void> _onNotificationSwitchChanged(bool value) async {
    final status = await Permission.notification.status;

    if (status.isGranted) {
      // If we have system permission, just save the in-app preference.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('inAppNotifications', value);
      setState(() {
        _inAppNotificationsEnabled = value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('In-app notifications ${value ? "enabled" : "disabled"}')),
      );
    } else if (status.isDenied) {
      // If permission was denied previously, prompt the user to grant it again.
      final newStatus = await Permission.notification.request();
      if (newStatus.isGranted) {
        // If granted, enable the in-app setting as well.
        await _onNotificationSwitchChanged(true);
      }
    } else if (status.isPermanentlyDenied) {
      // If permanently denied, we can't request again.
      // Guide the user to the app settings.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Notification permission is required.'),
          action: SnackBarAction(
            label: 'Open Settings',
            onPressed: openAppSettings,
          ),
        ),
      );
    }

    // Refresh the state after any of the above actions
    _initializeNotificationSettings();
  }

  /// Shows a more attractive dialog to select the app theme.
  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Use a Consumer to access and rebuild on theme changes within the dialog
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
              title: const Center(
                child: Text(
                  'Choose Theme',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Use a helper to build each theme choice
                  _buildThemeChoice(
                    context: context,
                    title: 'Light',
                    icon: Icons.wb_sunny_rounded,
                    mode: ThemeMode.light,
                    provider: themeProvider,
                  ),
                  const SizedBox(width: 16),
                  _buildThemeChoice(
                    context: context,
                    title: 'Dark',
                    icon: Icons.nightlight_round,
                    mode: ThemeMode.dark,
                    provider: themeProvider,
                  ),
                  const SizedBox(width: 16),
                  _buildThemeChoice(
                    context: context,
                    title: 'System',
                    icon: Icons.settings_system_daydream_rounded,
                    mode: ThemeMode.system,
                    provider: themeProvider,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Helper method to build a single theme choice widget.
  Widget _buildThemeChoice({
    required BuildContext context,
    required String title,
    required IconData icon,
    required ThemeMode mode,
    required ThemeProvider provider,
  }) {
    // Check if this choice is the currently selected theme
    final bool isSelected = provider.themeMode == mode;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        // Set the theme and close the dialog on tap
        provider.setTheme(mode);
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(12), // For the splash effect
      child: Container(
        width: 80, // Give a fixed width for uniform layout
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          // Highlight with a border and a light background color if selected
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2.5 : 1.5,
          ),
          color: isSelected ? colorScheme.primary.withOpacity(0.1) : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              // Use the primary theme color for the icon when selected
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // A helper function to capitalize the first letter of a string
  String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    // Use a Consumer here to rebuild the subtitle when the theme changes
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: MyAwesomeAppBar(title: 'Settings', hasBackButton: false),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Your notification switch tile
              SwitchListTile(
                title: const Text('Enable Notifications'),
                subtitle: Text(_hasSystemPermission ? 'Receive alerts and updates' : 'Permission needed'),
                value: _inAppNotificationsEnabled && _hasSystemPermission,
                onChanged: _onNotificationSwitchChanged,
                secondary: const Icon(Icons.notifications_outlined),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.color_lens_outlined),
                title: const Text('Theme'),
                // Update the subtitle dynamically
                subtitle: Text(capitalize(themeProvider.themeMode.name)),
                onTap: () {
                  // Call the function to show the dialog
                  _showThemeDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}