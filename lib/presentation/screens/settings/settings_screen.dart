import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_avatar.dart';
// Notifications removed from UI

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final settings = settingsState.settings;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Тохиргоо'),
      ),
      body: settingsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Profile section
                if (user != null)
                  ListTile(
                    leading: AppAvatar(
                      imageUrl: user.avatarUrl,
                      name: user.displayName,
                      size: 48,
                    ),
                    title: Text(user.displayName),
                    subtitle: Text(user.email),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).pushNamed('/edit-profile');
                    },
                  ),
                const Divider(),
                // Notifications removed
                // Appearance section
                _buildSectionHeader(context, 'Харагдах байдал'),
                ListTile(
                  title: const Text('Сэдэв'),
                  subtitle: Text(_getThemeName(settings?.theme ?? 'system')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showThemeDialog(context, ref, settings?.theme ?? 'system');
                  },
                ),
                const Divider(),
                // About section
                _buildSectionHeader(context, 'Тухай'),
                ListTile(
                  title: const Text('Хувилбар'),
                  subtitle: const Text('1.0.0'),
                  trailing: const Icon(Icons.info_outline),
                  onTap: () {
                    Navigator.pushNamed(context, '/credits');
                  },
                ),
                const SizedBox(height: 24),
                // Notification debug and tests removed
                // Logout button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton(
                    onPressed: () => _showLogoutDialog(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Гарах'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  String _getThemeName(String theme) {
    switch (theme) {
      case 'light':
        return 'Цайвар';
      case 'dark':
        return 'Бараан';
      default:
        return 'Системийн';
    }
  }

  void _showThemeDialog(
      BuildContext context, WidgetRef ref, String currentTheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сэдэв сонгох'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Системийн'),
              value: 'system',
              groupValue: currentTheme,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setTheme(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Цайвар'),
              value: 'light',
              groupValue: currentTheme,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setTheme(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Бараан'),
              value: 'dark',
              groupValue: currentTheme,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setTheme(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Гарах'),
        content: const Text('Та гарахдаа итгэлтэй байна уу?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Үгүй'),
          ),
          TextButton(
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
            },
            child: const Text(
              'Тийм',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

}
