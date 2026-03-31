import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/strings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const String _notificationsKey = 'app_notifications_enabled';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsOn = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsOn =
          prefs.getBool(SettingsScreen._notificationsKey) ?? true;
      _loaded = true;
    });
  }

  Future<void> _setNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsScreen._notificationsKey, value);
    if (mounted) setState(() => _notificationsOn = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.settings),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: Text(AppStrings.notifications),
                  value: _notificationsOn,
                  onChanged: _setNotifications,
                ),
              ],
            ),
    );
  }
}
