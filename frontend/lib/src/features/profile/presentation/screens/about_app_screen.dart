import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/strings.dart';

/// Синхронизируйте с `pubspec.yaml` -> version при релизе.
const String _kAppVersion = '1.0.1';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.aboutApp),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Text(
            'canDo!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.appVersion(_kAppVersion),
            style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.aboutDescription,
            style: TextStyle(
              fontSize: 16,
              height: 1.45,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 20),
          _bullet(AppStrings.aboutBullet1),
          _bullet(AppStrings.aboutBullet2),
          _bullet(AppStrings.aboutBullet3),
          const SizedBox(height: 24),
          Text(
            AppStrings.aboutPaymentNote,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.telegramSection,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.telegramChannelNote,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final uri = Uri.parse('https://t.me/canDomobileapp');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '@canDomobileapp',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('* ',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade800)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 15, height: 1.4, color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }
}
