import 'package:flutter/material.dart';

import '../../widgets/app_bar.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAwesomeAppBar(title: 'Settings', hasBackButton: true),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Example of a settings option
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: true, // You would manage this with a state variable
            onChanged: (bool value) {
              // TODO: Update notification settings
            },
            secondary: const Icon(Icons.notifications_outlined),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            title: const Text('Theme'),
            subtitle: const Text('Light / Dark Mode'),
            onTap: () {
              // TODO: Implement theme switching
            },
          )
        ],
      ),
    );
  }
}