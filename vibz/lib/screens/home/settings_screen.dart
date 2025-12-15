// lib/screens/home/settings_screen.dart
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoplay = true;
  bool _cachePreviews = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Autoplay next track'),
            value: _autoplay,
            onChanged: (v) => setState(() => _autoplay = v),
          ),
          SwitchListTile(
            title: const Text('Cache 30s previews for offline'),
            value: _cachePreviews,
            onChanged: (v) => setState(() => _cachePreviews = v),
          ),
          ListTile(
            title: const Text('About'),
            subtitle: const Text('Vibz — collaborative music rooms'),
          )
        ],
      ),
    );
  }
}
